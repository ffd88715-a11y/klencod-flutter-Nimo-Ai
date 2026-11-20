import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/features/ai_chat/ai_chat_screen.dart';
import 'package:talkora_ai/features/challenges/daily_challenge_screen.dart';
import 'package:talkora_ai/features/device_hub/device_hub_screen.dart';
import 'package:talkora_ai/features/github_db/github_db_screen.dart';
import 'package:talkora_ai/features/grammar/grammar_screen.dart';
import 'package:talkora_ai/features/home/home_screen.dart';
import 'package:talkora_ai/features/image_studio/image_studio_screen.dart';
import 'package:talkora_ai/features/listening/listening_screen.dart';
import 'package:talkora_ai/features/onboarding/onboarding_screen.dart';
import 'package:talkora_ai/features/practice/practice_hub_screen.dart';
import 'package:talkora_ai/features/profile/profile_screen.dart';
import 'package:talkora_ai/features/progress/progress_screen.dart';
import 'package:talkora_ai/features/pronunciation/pronunciation_screen.dart';
import 'package:talkora_ai/features/roleplay/roleplay_screen.dart';
import 'package:talkora_ai/features/settings/settings_screen.dart';
import 'package:talkora_ai/features/splash/splash_screen.dart';
import 'package:talkora_ai/features/translator/translator_screen.dart';
import 'package:talkora_ai/features/vocabulary/vocabulary_screen.dart';
import 'package:talkora_ai/features/voice/live_voice_screen.dart';
import 'package:talkora_ai/features/writing/writing_lab_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/voice', builder: (_, __) => const LiveVoiceScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/image-studio', builder: (_, __) => const ImageStudioScreen()),
      GoRoute(path: '/github-db', builder: (_, __) => const GithubDbScreen()),
      GoRoute(path: '/device-hub', builder: (_, __) => const DeviceHubScreen()),
      GoRoute(path: '/roleplay', builder: (_, __) => const RoleplayScreen()),
      GoRoute(path: '/writing', builder: (_, __) => const WritingLabScreen()),
      GoRoute(path: '/translator', builder: (_, __) => const TranslatorScreen()),
      GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
      GoRoute(path: '/practice/pronunciation', builder: (_, __) => const PronunciationScreen()),
      GoRoute(path: '/practice/grammar', builder: (_, __) => const GrammarScreen()),
      GoRoute(path: '/practice/listening', builder: (_, __) => const ListeningScreen()),
      GoRoute(path: '/practice/challenge', builder: (_, __) => const DailyChallengeScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _IosMainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (_, __) => const AiChatScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/practice', builder: (_, __) => const PracticeHubScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/vocabulary', builder: (_, __) => const VocabularyScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

/// Authentic iOS 18 Translucent Frosted-Glass Cupertino Tab Bar Shell.
class _IosMainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _IosMainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark ? TalkoraColors.darkSecondaryText : TalkoraColors.lightSecondaryText;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface)
                  .withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: (isDark ? TalkoraColors.darkSeparator : TalkoraColors.lightSeparator)
                      .withValues(alpha: 0.45),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 58,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _IosTabItem(
                      icon: CupertinoIcons.house,
                      activeIcon: CupertinoIcons.house_fill,
                      label: s.t('nav_home'),
                      selected: navigationShell.currentIndex == 0,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => navigationShell.goBranch(0, initialLocation: navigationShell.currentIndex == 0),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.sparkles,
                      activeIcon: CupertinoIcons.sparkles,
                      label: s.t('nav_chat'),
                      selected: navigationShell.currentIndex == 1,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => navigationShell.goBranch(1, initialLocation: navigationShell.currentIndex == 1),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.book,
                      activeIcon: CupertinoIcons.book_fill,
                      label: s.t('nav_practice'),
                      selected: navigationShell.currentIndex == 2,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => navigationShell.goBranch(2, initialLocation: navigationShell.currentIndex == 2),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.rectangle_stack,
                      activeIcon: CupertinoIcons.rectangle_stack_fill,
                      label: s.t('nav_vocab'),
                      selected: navigationShell.currentIndex == 3,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => navigationShell.goBranch(3, initialLocation: navigationShell.currentIndex == 3),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.person_crop_circle,
                      activeIcon: CupertinoIcons.person_crop_circle_fill,
                      label: s.t('nav_profile'),
                      selected: navigationShell.currentIndex == 4,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => navigationShell.goBranch(4, initialLocation: navigationShell.currentIndex == 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosTabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _IosTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
