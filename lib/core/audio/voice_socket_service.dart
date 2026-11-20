import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum VoiceEngineState {
  connecting,
  listening,
  understanding,
  thinking,
  speaking,
  interrupted,
  reconnecting,
  error,
}

class VoiceTurnEvent {
  final VoiceEngineState? state;
  final String? userTranscript;
  final String? assistantText;
  final String? arabicTranslation;
  final Map<String, dynamic>? correction;
  final String? audioChunkBase64;
  final double? vadLevel;
  final bool stopPlayback;

  const VoiceTurnEvent({
    this.state,
    this.userTranscript,
    this.assistantText,
    this.arabicTranslation,
    this.correction,
    this.audioChunkBase64,
    this.vadLevel,
    this.stopPlayback = false,
  });
}

/// Real-time WebSocket client for TALKORA AI voice pipeline with barge-in interruption & auto-reconnect.
class VoiceSocketService {
  WebSocketChannel? _channel;
  final _eventsController = StreamController<VoiceTurnEvent>.broadcast();
  Stream<VoiceTurnEvent> get events => _eventsController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect({
    required String baseUrl,
    required String sessionId,
    required String displayName,
    required String cefrLevel,
    required String accent,
    required String mode,
  }) async {
    _eventsController.add(const VoiceTurnEvent(state: VoiceEngineState.connecting));
    final wsBase = baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    final uri = Uri.parse(
      '$wsBase/ws/voice/$sessionId?display_name=${Uri.encodeComponent(displayName)}'
      '&cefr_level=$cefrLevel&accent=$accent&mode=$mode',
    );
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(const Duration(seconds: 4));
      _isConnected = true;
      _channel!.stream.listen(
        _handleMessage,
        onError: (_) {
          _isConnected = false;
          _eventsController.add(const VoiceTurnEvent(state: VoiceEngineState.reconnecting));
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (_) {
      _isConnected = false;
      _eventsController.add(const VoiceTurnEvent(state: VoiceEngineState.listening));
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      if (type == 'state') {
        final s = _parseState(data['state'] as String? ?? 'listening');
        _eventsController.add(
          VoiceTurnEvent(state: s, stopPlayback: data['stop_playback'] == true),
        );
      } else if (type == 'vad') {
        final rms = (data['rms_level'] as num?)?.toDouble() ?? 0.0;
        _eventsController.add(VoiceTurnEvent(vadLevel: rms.clamp(0.0, 1.0)));
      } else if (type == 'transcript') {
        _eventsController.add(VoiceTurnEvent(userTranscript: data['text'] as String?));
      } else if (type == 'assistant_text') {
        _eventsController.add(
          VoiceTurnEvent(
            assistantText: data['text'] as String?,
            arabicTranslation: data['arabic_translation'] as String?,
            correction: data['correction'] as Map<String, dynamic>?,
          ),
        );
      } else if (type == 'tts_chunk') {
        _eventsController.add(VoiceTurnEvent(audioChunkBase64: data['audio_base64'] as String?));
      }
    } catch (_) {}
  }

  VoiceEngineState _parseState(String raw) {
    switch (raw) {
      case 'connecting':
        return VoiceEngineState.connecting;
      case 'listening':
        return VoiceEngineState.listening;
      case 'understanding':
        return VoiceEngineState.understanding;
      case 'thinking':
        return VoiceEngineState.thinking;
      case 'speaking':
        return VoiceEngineState.speaking;
      case 'interrupted':
        return VoiceEngineState.interrupted;
      case 'reconnecting':
        return VoiceEngineState.reconnecting;
      default:
        return VoiceEngineState.error;
    }
  }

  void sendAudioChunkBase64(String base64Pcm) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'audio_chunk', 'audio_base64': base64Pcm}));
    }
  }

  void sendEndOfSpeech({String? transcriptOverride, String topic = 'Daily Life'}) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'end_of_speech',
        'transcript_override': transcriptOverride,
        'topic': topic,
      }));
    }
  }

  void sendInterrupt() {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'interrupt'}));
    }
    _eventsController.add(
      const VoiceTurnEvent(state: VoiceEngineState.interrupted, stopPlayback: true),
    );
  }

  void sendMute(bool muted) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'mute', 'muted': muted}));
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _eventsController.close();
  }
}
