import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';

/// Nimo Tactile Sound Effects Engine — crisp click, pop & welcome chime.
/// Uses pre-loaded local WAV assets via just_audio with zero-latency native fallback.
class NimoSoundFx {
  NimoSoundFx._();

  static bool enabled = true;
  static final AudioPlayer _clickPlayer = AudioPlayer();
  static final AudioPlayer _popPlayer = AudioPlayer();
  static final AudioPlayer _chimePlayer = AudioPlayer();
  static bool _initialized = false;
  static final NativeBridgeService _bridge = NativeBridgeService();

  static Future<void> warmUp() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _clickPlayer.setAsset('assets/audio/nimo_click.wav');
      await _clickPlayer.setVolume(0.55);
      await _popPlayer.setAsset('assets/audio/nimo_pop.wav');
      await _popPlayer.setVolume(0.60);
      await _chimePlayer.setAsset('assets/audio/nimo_chime.wav');
      await _chimePlayer.setVolume(0.48);
    } catch (_) {
      // Safe fallback in headless/test environments
    }
  }

  /// Crisp glass-tap click for buttons, icons, tabs, and chips.
  static void click() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
    _playAssetOrNative(_clickPlayer, fallbackNative: true);
  }

  /// Soft confirmation pop for copy, paste, send, and save actions.
  static void pop() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    _playAssetOrNative(_popPlayer, fallbackNative: true);
  }

  /// Subtle harmonic glass chime on Nimo splash screen reveal.
  static void chime() {
    if (!enabled) return;
    _playAssetOrNative(_chimePlayer, fallbackNative: false);
  }

  static Future<void> _playAssetOrNative(AudioPlayer player, {required bool fallbackNative}) async {
    try {
      if (!_initialized) {
        await warmUp();
      }
      await player.seek(Duration.zero);
      await player.play();
    } catch (_) {
      if (fallbackNative) {
        try {
          await _bridge.playClickSound();
        } catch (_) {
          SystemSound.play(SystemSoundType.click);
        }
      }
    }
  }
}
