import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/features/ai_chat/ai_chat_screen.dart';
import 'package:talkora_ai/features/challenges/daily_challenge_screen.dart';
import 'package:talkora_ai/features/coding_lab/coding_lab_screen.dart';
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
      GoRoute(path: '/coding-lab', builder: (_, __) => const CodingLabScreen()),
      GoRoute(path: '/github-db', builder: (_, __) => const GithubDbScreen()),
      GoRoute(path: '/device-hub', builder: (_, __) => const DeviceHubScreen()),
      GoRoute(path: '/roleplay', builder: (_, __) => const RoleplayScreen()),
      GoRoute(path: '/writing', builder: (_, __) => const WritingLabScreen()),
      GoRoute(path: '/translator', builder: (_, __) => const TranslatorScreen()),
      GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
      GoRoute(path: '/practice-hub', builder: (_, __) => const PracticeHubScreen()),
      GoRoute(path: '/vocabulary-list', builder: (_, __) => const VocabularyScreen()),
      GoRoute(path: '/practice/pronunciation', builder: (_, __) => const PronunciationScreen()),
      GoRoute(path: '/practice/grammar', builder: (_, __) => const GrammarScreen()),
      GoRoute(path: '/practice/listening', builder: (_, __) => const ListeningScreen()),
      GoRoute(path: '/practice/challenge', builder: (_, __) => const DailyChallengeScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _IosMainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (_, __) => const AiChatScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/practice', builder: (_, __) => const CodingLabScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/vocabulary', builder: (_, __) => const GithubDbScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

/// Nimo Liquid Glass Translucent Bottom Tab Bar Shell with click sound & glass active halo.
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

    void switchTab(int idx) {
      NimoSoundFx.click();
      navigationShell.goBranch(idx, initialLocation: navigationShell.currentIndex == idx);
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface)
                  .withValues(alpha: 0.86),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.45),
                  width: 0.6,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
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
                      onTap: () => switchTab(0),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.sparkles,
                      activeIcon: CupertinoIcons.sparkles,
                      label: s.t('nav_chat'),
                      selected: navigationShell.currentIndex == 1,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => switchTab(1),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.chevron_left_slash_chevron_right,
                      activeIcon: CupertinoIcons.chevron_left_slash_chevron_right,
                      label: s.t('nav_practice'),
                      selected: navigationShell.currentIndex == 2,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => switchTab(2),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.layers_alt,
                      activeIcon: CupertinoIcons.layers_alt_fill,
                      label: s.t('nav_vocab'),
                      selected: navigationShell.currentIndex == 3,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => switchTab(3),
                    ),
                    _IosTabItem(
                      icon: CupertinoIcons.person_crop_circle,
                      activeIcon: CupertinoIcons.person_crop_circle_fill,
                      label: s.t('nav_profile'),
                      selected: navigationShell.currentIndex == 4,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => switchTab(4),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? activeColor.withValues(alpha: 0.16) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? activeColor.withValues(alpha: 0.35) : Colors.transparent,
                  width: 0.7,
                ),
              ),
              child: Icon(selected ? activeIcon : icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
