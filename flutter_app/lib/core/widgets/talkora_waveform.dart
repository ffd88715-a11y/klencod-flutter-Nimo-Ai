import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';

/// Custom Flutter audio waveform driven strictly by real audio/microphone amplitude levels (0.0 - 1.0).
class TalkoraWaveform extends StatelessWidget {
  final List<double> amplitudeHistory;
  final Color? color;
  final double height;

  const TalkoraWaveform({
    super.key,
    required this.amplitudeHistory,
    this.color,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: amplitudeHistory,
          color: activeColor,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  const _WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    final barCount = amplitudes.length;
    final spacing = size.width / math.max(barCount, 1);
    final midY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final level = amplitudes[i].clamp(0.06, 1.0);
      final halfHeight = (size.height * 0.44) * level;
      final x = spacing * i + spacing / 2;
      paint.color = color.withValues(alpha: 0.35 + (level * 0.65));
      canvas.drawLine(Offset(x, midY - halfHeight), Offset(x, midY + halfHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

/// Animated TALKORA Voice Orb reflecting live engine state and real audio energy.
class TalkoraVoiceOrb extends StatelessWidget {
  final VoiceEngineState state;
  final double audioLevel;
  final double size;

  const TalkoraVoiceOrb({
    super.key,
    required this.state,
    required this.audioLevel,
    this.size = 168,
  });

  Color _stateColor(BuildContext context) {
    switch (state) {
      case VoiceEngineState.speaking:
        return TalkoraColors.success;
      case VoiceEngineState.interrupted:
      case VoiceEngineState.error:
        return TalkoraColors.error;
      case VoiceEngineState.thinking:
      case VoiceEngineState.understanding:
        return TalkoraColors.secondaryAccent;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _stateIcon() {
    switch (state) {
      case VoiceEngineState.listening:
        return Icons.graphic_eq_rounded;
      case VoiceEngineState.speaking:
        return Icons.volume_up_rounded;
      case VoiceEngineState.thinking:
      case VoiceEngineState.understanding:
        return Icons.auto_awesome_rounded;
      case VoiceEngineState.interrupted:
        return Icons.stop_rounded;
      case VoiceEngineState.error:
        return Icons.wifi_off_rounded;
      default:
        return Icons.mic_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _stateColor(context);
    final scale = 1.0 + (audioLevel.clamp(0.0, 1.0) * 0.16);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              c.withValues(alpha: 0.92),
              c.withValues(alpha: 0.45),
              c.withValues(alpha: 0.12),
            ],
            stops: const [0.35, 0.72, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: size * 0.56,
            height: size * 0.56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
            ),
            child: Icon(_stateIcon(), color: Colors.white, size: size * 0.26),
          ),
        ),
      ),
    );
  }
}
