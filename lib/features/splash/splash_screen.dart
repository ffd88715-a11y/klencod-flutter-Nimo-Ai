import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _navTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final onboarded = ref.read(learnerProfileProvider).onboardingCompleted;
      context.go(onboarded ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final pulse = 0.94 + (_controller.value * 0.10);
                return Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [TalkoraColors.primaryAccent, TalkoraColors.secondaryAccent],
                      ),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 44),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(s.t('app_name'), style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(s.t('subtitle'), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
