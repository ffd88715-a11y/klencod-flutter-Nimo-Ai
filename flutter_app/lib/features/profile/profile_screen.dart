import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final ai = ref.watch(aiSettingsProvider);
    final s = ref.watch(appStringsProvider);
    final isAr = s.isArabic;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('nav_profile')),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.gear_alt_fill),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // iOS Apple-ID Style Profile Header Card
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'T',
                  style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              title: Text(profile.displayName, style: theme.textTheme.titleLarge),
              subtitle: Text('${profile.englishLevel} • ${profile.preferredAccent} • ${profile.xpPoints} XP'),
              trailing: TextButton(
                onPressed: () => context.push('/onboarding'),
                child: Text(isAr ? 'تعديل' : 'Edit'),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Universal AI Keys Shortcut Section
          IosGroupedSection(
            header: isAr ? 'محرك الذكاء الاصطناعي ومفاتيح API' : 'AI ENGINE & API KEYS',
            children: [
              IosSettingsRow(
                icon: CupertinoIcons.lock_shield_fill,
                iconColor: TalkoraColors.iosIndigo,
                title: isAr ? 'إعدادات مفاتيح API والنماذج' : 'AI API Keys & Models',
                subtitle: '${ai.activePreset.name} • ${ai.activeModel}',
                trailingValue: ai.isConfigured ? (isAr ? 'نشط' : 'Ready') : (isAr ? 'إعداد' : 'Setup'),
                onTap: () => context.push('/settings'),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.chart_bar_fill,
                iconColor: TalkoraColors.iosGreen,
                title: isAr ? 'إحصائيات التقدم الأسبوعي' : 'Progress & Analytics',
                trailingValue: '${profile.streakDays}d',
                onTap: () => context.push('/progress'),
              ),
            ],
          ),

          // Appearance & Language
          IosGroupedSection(
            header: isAr ? 'المظهر واللغة' : 'APPEARANCE & LANGUAGE',
            children: [
              IosSettingsRow(
                icon: CupertinoIcons.globe,
                iconColor: TalkoraColors.iosBlue,
                title: isAr ? 'الواجهة العربية (RTL)' : 'Arabic Interface (العربية)',
                trailing: CupertinoSwitch(
                  value: isAr,
                  activeTrackColor: TalkoraColors.iosGreen,
                  onChanged: (v) => ref.read(learnerProfileProvider.notifier).setLocale(v ? 'ar' : 'en'),
                ),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.moon_fill,
                iconColor: TalkoraColors.iosPurple,
                title: isAr ? 'الوضع الداكن الهادئ' : 'Dark Mode',
                trailing: CupertinoSwitch(
                  value: profile.themeMode == ThemeMode.dark,
                  activeTrackColor: TalkoraColors.iosGreen,
                  onChanged: (v) => ref
                      .read(learnerProfileProvider.notifier)
                      .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
            ],
          ),

          // Privacy Controls
          IosGroupedSection(
            header: s.t('privacy_controls'),
            children: [
              IosSettingsRow(
                icon: CupertinoIcons.sparkles,
                iconColor: TalkoraColors.iosTeal,
                title: s.t('enable_memory'),
                trailing: CupertinoSwitch(
                  value: profile.memoryEnabled,
                  activeTrackColor: TalkoraColors.iosGreen,
                  onChanged: (v) => ref.read(learnerProfileProvider.notifier).setMemoryEnabled(v),
                ),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.arrow_down_doc_fill,
                iconColor: TalkoraColors.iosOrange,
                title: s.t('export_history'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'تم تجهيز ملف سجل التعلم.' : 'Learning history export prepared.')),
                  );
                },
              ),
              IosSettingsRow(
                icon: CupertinoIcons.trash_fill,
                iconColor: TalkoraColors.iosRed,
                title: s.t('reset_progress'),
                destructive: true,
                onTap: () {
                  ref.read(learnerProfileProvider.notifier).resetProgress();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'تمت إعادة تعيين التقدم.' : 'Learning progress reset.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
