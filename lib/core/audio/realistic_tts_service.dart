import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

/// Human-realistic voice profile options for Nimo Realistic Voice Engine.
class RealisticVoicePreset {
  final String id;
  final String labelAr;
  final String labelEn;
  final String provider; // 'auto' | 'openai' | 'elevenlabs' | 'native_neural'
  final String voiceId;

  const RealisticVoicePreset({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.provider,
    required this.voiceId,
  });
}

/// Nimo Realistic Human Voice TTS Engine:
/// 1. ElevenLabs Ultra-Human Multilingual v2 (when ElevenLabs key is set)
/// 2. OpenAI Realistic Neural TTS (`gpt-4o-mini-tts` / `tts-1-hd`, voices: coral/ash/nova/onyx) when OpenAI key is set
/// 3. Native Android High-Quality Neural/Wavenet Voice auto-selector with natural human prosody (zero-key offline)
class RealisticTtsService {
  static const List<RealisticVoicePreset> presets = [
    RealisticVoicePreset(
      id: 'auto_human',
      labelAr: 'تلقائي ذكي (أعلى صوت بشري متاح)',
      labelEn: 'Smart Auto (Best Human Voice)',
      provider: 'auto',
      voiceId: 'coral',
    ),
    RealisticVoicePreset(
      id: 'openai_coral',
      labelAr: 'صوت بشري دافئ — Coral (OpenAI HD)',
      labelEn: 'Warm Human — Coral (OpenAI HD)',
      provider: 'openai',
      voiceId: 'coral',
    ),
    RealisticVoicePreset(
      id: 'openai_ash',
      labelAr: 'صوت رجالي واقعي — Ash (OpenAI HD)',
      labelEn: 'Natural Male — Ash (OpenAI HD)',
      provider: 'openai',
      voiceId: 'ash',
    ),
    RealisticVoicePreset(
      id: 'openai_nova',
      labelAr: 'صوت نسائي طبيعي — Nova (OpenAI HD)',
      labelEn: 'Natural Female — Nova (OpenAI HD)',
      provider: 'openai',
      voiceId: 'nova',
    ),
    RealisticVoicePreset(
      id: 'openai_onyx',
      labelAr: 'صوت إذاعي عميق — Onyx (OpenAI HD)',
      labelEn: 'Deep Studio — Onyx (OpenAI HD)',
      provider: 'openai',
      voiceId: 'onyx',
    ),
    RealisticVoicePreset(
      id: 'elevenlabs_human',
      labelAr: 'صوت فائق الواقعية — ElevenLabs',
      labelEn: 'Ultra-Realistic — ElevenLabs',
      provider: 'elevenlabs',
      voiceId: '21m00Tcm4TlvDq8ikWAM', // Rachel multilingual human voice
    ),
    RealisticVoicePreset(
      id: 'native_neural',
      labelAr: 'صوت Neural المحلي (بدون مفتاح)',
      labelEn: 'Device Neural Voice (Free Offline)',
      provider: 'native_neural',
      voiceId: '',
    ),
  ];

  final NativeBridgeService _bridge;
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 40),
    ),
  );

  bool _isCloudPlaying = false;
  bool get isCloudPlaying => _isCloudPlaying;

  RealisticTtsService(this._bridge);

  /// Cleans markdown symbols so the voice reads naturally like a real human.
  static String prepareNaturalSpeechText(String raw) {
    var s = raw
        .replaceAll(RegExp(r"""```[\s\S]*?```"""), ' ')
        .replaceAll(RegExp(r"""`[^`]*`"""), ' ')
        .replaceAll(RegExp(r"""[*#_~>\[\]]"""), ' ')
        .replaceAll(RegExp(r"""https?://\S+"""), ' ')
        .replaceAll(RegExp(r"""\s+"""), ' ')
        .trim();
    if (s.length > 2400) {
      s = s.substring(0, 2400);
    }
    return s;
  }

  Future<void> stop() async {
    _isCloudPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
    await _bridge.stopSpeaking();
  }

  /// Speaks text using the most realistic human voice available for the user's configuration.
  Future<String> speakHuman({
    required String text,
    required AiSettingsState aiSettings,
    String? locale,
    double? rate,
    VoidCallback? onStart,
    VoidCallback? onDone,
  }) async {
    final clean = prepareNaturalSpeechText(text);
    if (clean.isEmpty) {
      onDone?.call();
      return 'Empty';
    }

    await stop();
    final preset = presets.firstWhere(
      (p) => p.id == aiSettings.voicePresetId,
      orElse: () => presets.first,
    );
    final speed = (rate ?? aiSettings.voiceSpeechRate).clamp(0.65, 1.5);
    final openAiKey = aiSettings.credentialFor('openai').apiKey.trim();
    final elevenKey = aiSettings.elevenLabsApiKey.trim();

    // 1. Try ElevenLabs if explicitly chosen or in auto mode with key
    if ((preset.provider == 'elevenlabs' || preset.provider == 'auto') && elevenKey.isNotEmpty) {
      final ok = await _speakElevenLabs(
        text: clean,
        apiKey: elevenKey,
        voiceId: aiSettings.elevenLabsVoiceId.trim().isNotEmpty
            ? aiSettings.elevenLabsVoiceId.trim()
            : preset.voiceId,
        onStart: onStart,
        onDone: onDone,
      );
      if (ok) return 'ElevenLabs Human Voice';
    }

    // 2. Try OpenAI Realistic Neural TTS (gpt-4o-mini-tts -> tts-1-hd) if key is available
    if ((preset.provider == 'openai' || preset.provider == 'auto') && openAiKey.isNotEmpty) {
      final ok = await _speakOpenAiHuman(
        text: clean,
        apiKey: openAiKey,
        voice: preset.provider == 'openai' ? preset.voiceId : 'coral',
        speed: speed,
        onStart: onStart,
        onDone: onDone,
      );
      if (ok) return 'OpenAI Human HD Voice';
    }

    // 3. Best Native Android Neural / Wavenet Human Voice (tuned natural prosody)
    final detectedLocale = locale ??
        (NativeBridgeService.containsArabic(clean)
            ? (aiSettings.voiceLocale.startsWith('ar') ? aiSettings.voiceLocale : 'ar-EG')
            : (aiSettings.voiceLocale.startsWith('en') ? aiSettings.voiceLocale : 'en-US'));
    onStart?.call();
    await _bridge.speak(
      clean,
      locale: detectedLocale,
      rate: (speed * 0.96).clamp(0.65, 1.45),
      pitch: 0.97,
      voiceName: aiSettings.nativeVoiceName.isNotEmpty ? aiSettings.nativeVoiceName : null,
    );
    return 'Neural Device Voice';
  }

  Future<bool> _speakOpenAiHuman({
    required String text,
    required String apiKey,
    required String voice,
    required double speed,
    VoidCallback? onStart,
    VoidCallback? onDone,
  }) async {
    try {
      final res = await _dio.post<List<int>>(
        'https://api.openai.com/v1/audio/speech',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4o-mini-tts',
          'voice': voice,
          'input': text,
          'speed': speed.clamp(0.7, 1.5),
          'instructions': 'Speak naturally, warmly, and expressively like a real human conversation.',
        },
      );
      final bytes = Uint8List.fromList(res.data ?? const <int>[]);
      if (bytes.length < 256) return false;
      return await _playAudioBytes(bytes, 'mp3', onStart: onStart, onDone: onDone);
    } catch (_) {
      // Fallback to tts-1-hd if gpt-4o-mini-tts is unavailable on account
      try {
        final res = await _dio.post<List<int>>(
          'https://api.openai.com/v1/audio/speech',
          options: Options(
            responseType: ResponseType.bytes,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'tts-1-hd',
            'voice': voice == 'coral' ? 'nova' : voice,
            'input': text,
            'speed': speed.clamp(0.7, 1.5),
          },
        );
        final bytes = Uint8List.fromList(res.data ?? const <int>[]);
        if (bytes.length < 256) return false;
        return await _playAudioBytes(bytes, 'mp3', onStart: onStart, onDone: onDone);
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> _speakElevenLabs({
    required String text,
    required String apiKey,
    required String voiceId,
    VoidCallback? onStart,
    VoidCallback? onDone,
  }) async {
    try {
      final res = await _dio.post<List<int>>(
        'https://api.elevenlabs.io/v1/text-to-speech/$voiceId',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'xi-api-key': apiKey,
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
          },
        ),
        data: {
          'text': text,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.45,
            'similarity_boost': 0.82,
            'style': 0.35,
            'use_speaker_boost': true,
          },
        },
      );
      final bytes = Uint8List.fromList(res.data ?? const <int>[]);
      if (bytes.length < 256) return false;
      return await _playAudioBytes(bytes, 'mp3', onStart: onStart, onDone: onDone);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _playAudioBytes(
    Uint8List bytes,
    String ext, {
    VoidCallback? onStart,
    VoidCallback? onDone,
  }) async {
    try {
      final tmpFile = File('${Directory.systemTemp.path}/nimo_tts_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tmpFile.writeAsBytes(bytes, flush: true);
      _isCloudPlaying = true;
      onStart?.call();
      await _player.setFilePath(tmpFile.path);
      final completer = Completer<void>();
      late final StreamSubscription<PlayerState> sub;
      sub = _player.playerStateStream.listen((st) {
        if (st.processingState == ProcessingState.completed) {
          if (!completer.isCompleted) completer.complete();
        }
      });
      await _player.play();
      await completer.future.timeout(const Duration(seconds: 90), onTimeout: () {});
      await sub.cancel();
      _isCloudPlaying = false;
      onDone?.call();
      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
      return true;
    } catch (_) {
      _isCloudPlaying = false;
      return false;
    }
  }
}

final realisticTtsProvider = Provider<RealisticTtsService>((ref) {
  return RealisticTtsService(ref.read(nativeBridgeProvider));
});
