import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a launchable app installed on the user's phone.
class InstalledAppInfo {
  final String name;
  final String packageName;

  const InstalledAppInfo({required this.name, required this.packageName});

  factory InstalledAppInfo.fromMap(Map<dynamic, dynamic> map) {
    return InstalledAppInfo(
      name: (map['name'] ?? '').toString(),
      packageName: (map['packageName'] ?? '').toString(),
    );
  }
}

/// Native Android TTS voice descriptor for realistic voice selection.
class NativeVoiceInfo {
  final String name;
  final String locale;
  final int quality;
  final bool isNetwork;

  const NativeVoiceInfo({
    required this.name,
    required this.locale,
    this.quality = 400,
    this.isNetwork = false,
  });

  factory NativeVoiceInfo.fromMap(Map<dynamic, dynamic> map) {
    return NativeVoiceInfo(
      name: (map['name'] ?? '').toString(),
      locale: (map['locale'] ?? '').toString(),
      quality: (map['quality'] as num?)?.toInt() ?? 400,
      isNetwork: map['isNetwork'] == true,
    );
  }
}

/// Live Android hardware & battery telemetry.
class DeviceStatusInfo {
  final int batteryLevel;
  final bool isCharging;
  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkInt;
  final bool torchEnabled;

  const DeviceStatusInfo({
    this.batteryLevel = -1,
    this.isCharging = false,
    this.manufacturer = 'Android',
    this.model = 'Device',
    this.androidVersion = '',
    this.sdkInt = 0,
    this.torchEnabled = false,
  });

  factory DeviceStatusInfo.fromMap(Map<dynamic, dynamic> map) {
    return DeviceStatusInfo(
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? -1,
      isCharging: map['isCharging'] == true,
      manufacturer: (map['manufacturer'] ?? 'Android').toString(),
      model: (map['model'] ?? 'Device').toString(),
      androidVersion: (map['androidVersion'] ?? '').toString(),
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
      torchEnabled: map['torchEnabled'] == true,
    );
  }
}

/// Real-time event emitted by native Android SpeechRecognizer & TextToSpeech.
class NativeVoiceEvent {
  final String type;
  final String text;
  final double level;
  final int code;
  final String message;

  const NativeVoiceEvent({
    required this.type,
    this.text = '',
    this.level = 0.08,
    this.code = 0,
    this.message = '',
  });

  factory NativeVoiceEvent.fromDynamic(dynamic raw) {
    if (raw is Map) {
      return NativeVoiceEvent(
        type: (raw['type'] ?? '').toString(),
        text: (raw['text'] ?? '').toString(),
        level: (raw['level'] as num?)?.toDouble() ?? 0.08,
        code: (raw['code'] as num?)?.toInt() ?? 0,
        message: (raw['message'] ?? '').toString(),
      );
    }
    return const NativeVoiceEvent(type: 'unknown');
  }
}

/// Unified Flutter <-> Native Android Bridge for Live Voice (STT/TTS), Tactile Sound & Phone Management.
class NativeBridgeService {
  static const MethodChannel _channel = MethodChannel('ai.talkora.app/native_bridge');
  static const EventChannel _voiceEventsChannel = EventChannel('ai.talkora.app/voice_events');

  Stream<NativeVoiceEvent>? _cachedVoiceStream;

  Stream<NativeVoiceEvent> get voiceEvents {
    _cachedVoiceStream ??= _voiceEventsChannel
        .receiveBroadcastStream()
        .map(NativeVoiceEvent.fromDynamic)
        .asBroadcastStream();
    return _cachedVoiceStream!;
  }

  // ==================== TACTILE CLICK SOUND ====================
  Future<void> playClickSound() async {
    try {
      await _channel.invokeMethod<bool>('playClickSound');
    } catch (_) {}
  }

  // ==================== LIVE VOICE (STT / NEURAL TTS) ====================
  Future<bool> isSpeechAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isSpeechAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startListening({String locale = 'ar-EG'}) async {
    try {
      return await _channel.invokeMethod<bool>('startListening', {'locale': locale}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod<bool>('stopListening');
    } catch (_) {}
  }

  Future<void> cancelListening() async {
    try {
      await _channel.invokeMethod<bool>('cancelListening');
    } catch (_) {}
  }

  Future<List<NativeVoiceInfo>> getAvailableVoices({String? localePrefix}) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getAvailableVoices', {
        if (localePrefix != null) 'localePrefix': localePrefix,
      });
      if (raw == null) return const [];
      return raw.whereType<Map<dynamic, dynamic>>().map(NativeVoiceInfo.fromMap).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> speak(
    String text, {
    String? locale,
    double rate = 0.98,
    double pitch = 0.97,
    String? voiceName,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return false;
    final detectedLocale = locale ?? (containsArabic(clean) ? 'ar-EG' : 'en-US');
    try {
      return await _channel.invokeMethod<bool>('speak', {
            'text': clean,
            'locale': detectedLocale,
            'rate': rate,
            'pitch': pitch,
            if (voiceName != null && voiceName.isNotEmpty) 'voiceName': voiceName,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _channel.invokeMethod<bool>('stopSpeaking');
    } catch (_) {}
  }

  static bool containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  // ==================== PHONE APPS & FULL DEVICE MANAGEMENT ====================
  Future<List<InstalledAppInfo>> getInstalledApps() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (raw == null) return const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map(InstalledAppInfo.fromMap)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> launchApp(String query) async {
    try {
      return await _channel.invokeMethod<bool>('launchApp', {'query': query}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openUrl(String url) async {
    try {
      return await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openWhatsApp({required String phone, String message = ''}) async {
    try {
      return await _channel.invokeMethod<bool>('openWhatsApp', {
            'phone': phone,
            'message': message,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dialPhone(String phone) async {
    try {
      return await _channel.invokeMethod<bool>('dialPhone', {'phone': phone}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendSms({required String phone, String message = ''}) async {
    try {
      return await _channel.invokeMethod<bool>('sendSms', {
            'phone': phone,
            'message': message,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendEmail({
    required String to,
    String subject = '',
    String body = '',
  }) async {
    try {
      return await _channel.invokeMethod<bool>('sendEmail', {
            'to': to,
            'subject': subject,
            'body': body,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAlarm({required int hour, required int minute, String message = 'Nimo'}) async {
    try {
      return await _channel.invokeMethod<bool>('setAlarm', {
            'hour': hour,
            'minute': minute,
            'message': message,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setTimer({required int seconds, String message = 'Nimo Timer'}) async {
    try {
      return await _channel.invokeMethod<bool>('setTimer', {
            'seconds': seconds,
            'message': message,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openMaps(String query, {bool navigate = false}) async {
    try {
      return await _channel.invokeMethod<bool>('openMaps', {
            'query': query,
            'navigate': navigate,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> searchYoutube(String query) async {
    try {
      return await _channel.invokeMethod<bool>('searchYoutube', {'query': query}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openSystemSetting(String target) async {
    try {
      return await _channel.invokeMethod<bool>('openSystemSetting', {'target': target}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFlashlight(bool enabled) async {
    try {
      return await _channel.invokeMethod<bool>('toggleFlashlight', {'enabled': enabled}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<DeviceStatusInfo> getDeviceStatus() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceStatus');
      if (raw != null) return DeviceStatusInfo.fromMap(raw);
    } catch (_) {}
    return const DeviceStatusInfo();
  }

  Future<bool> shareText(String text, {String subject = 'Nimo'}) async {
    try {
      return await _channel.invokeMethod<bool>('shareText', {
            'text': text,
            'subject': subject,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveImageToGallery(Uint8List bytes, String fileName) async {
    try {
      return await _channel.invokeMethod<bool>('saveImageToGallery', {
            'bytes': bytes,
            'fileName': fileName,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

final nativeBridgeProvider = Provider<NativeBridgeService>((ref) => NativeBridgeService());
