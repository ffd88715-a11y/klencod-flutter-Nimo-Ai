import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

/// Nimo v4.0 Ultra — Choreographed Liquid Glass Intro Animation featuring the "Nimo" wordmark.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _sheenCtrl;
  Timer? _navTimer;
  bool _navigated = false;

  static const List<String> _brandLetters = ['N', 'i', 'm', 'o'];

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..forward();

    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Subtle welcome chime on reveal
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) NimoSoundFx.chime();
    });

    _navTimer = Timer(const Duration(milliseconds: 2450), _proceed);
  }

  void _proceed() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final onboarded = ref.read(learnerProfileProvider).onboardingCompleted;
    context.go(onboarded ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _introCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final emblemScale = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.48, curve: Curves.easeOutBack),
    );
    final subtitleFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.62, 1.0, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: isDark ? TalkoraColors.darkBackground : TalkoraColors.lightBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceed,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft matte radial ambiance (eye-friendly, zero harsh neon)
            AnimatedBuilder(
              animation: _sheenCtrl,
              builder: (_, __) {
                final pulse = 0.92 + 0.08 * math.sin(_sheenCtrl.value * 2 * math.pi);
                return Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: isDark ? 0.16 : 0.12),
                          TalkoraColors.iosIndigo.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Liquid Glass Nimo Emblem
                ScaleTransition(
                  scale: emblemScale,
                  child: AnimatedBuilder(
                    animation: _sheenCtrl,
                    builder: (_, __) {
                      final sweep = -1.6 + (_sheenCtrl.value * 3.2);
                      return Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withValues(alpha: 0.92),
                              TalkoraColors.iosIndigo.withValues(alpha: 0.85),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.42),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.28),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: -36,
                              left: -20,
                              right: -20,
                              height: 76,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.40),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Transform.rotate(
                                angle: math.pi / 6,
                                child: FractionallySizedBox(
                                  widthFactor: 0.40,
                                  alignment: Alignment(sweep, 0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.35),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 50),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Staggered Letter-by-Letter "Nimo" Animated Wordmark
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _brandLetters.length; i++)
                        _AnimatedBrandLetter(
                          letter: _brandLetters[i],
                          controller: _introCtrl,
                          start: 0.24 + (i * 0.10),
                          end: (0.58 + (i * 0.10)).clamp(0.0, 1.0),
                          accent: accent,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle & Ultra Badge
                FadeTransition(
                  opacity: subtitleFade,
                  child: Column(
                    children: [
                      Text(
                        s.t('subtitle'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.5),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withValues(alpha: 0.28), width: 0.7),
                        ),
                        child: Text(
                          'Nimo v4.0 Ultra • YOSSEF JOO',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBrandLetter extends StatelessWidget {
  final String letter;
  final AnimationController controller;
  final double start;
  final double end;
  final Color accent;
  final bool isDark;

  const _AnimatedBrandLetter({
    required this.letter,
    required this.controller,
    required this.start,
    required this.end,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final v = anim.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - v) * 26),
            child: Transform.scale(
              scale: 0.72 + (0.28 * v),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.white, accent.withValues(alpha: 0.90)]
                      : [const Color(0xFF141824), accent],
                ).createShader(bounds),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
