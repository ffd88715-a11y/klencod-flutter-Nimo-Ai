import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

/// LISORA AI v3.0 — Enterprise Home Hub with Live Voice, Image Studio,
/// GitHub Mega-Datasets, Full Phone Control & YOSSEF JOO Branding.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final ai = ref.watch(aiSettingsProvider);
    final gh = ref.watch(githubKnowledgeProvider);
    final s = ref.watch(appStringsProvider);
    final isAr = s.isArabic;
    final theme = Theme.of(context);
    final progressRatio = (profile.speakingMinutesToday / profile.dailyTargetMinutes).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            // Top Bar + Active AI Model Pill
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                  child: Text(
                    profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'L',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'أهلاً، ${profile.displayName}' : 'Hello, ${profile.displayName}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      IosStatusPill(
                        label: '${ai.activePreset.shortName} • ${ai.activeModel}',
                        color: ai.isConfigured ? TalkoraColors.iosGreen : TalkoraColors.iosOrange,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isAr ? 'مفاتيح API والإعدادات' : 'API Keys & Settings',
                  icon: const Icon(CupertinoIcons.gear_alt_fill),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Voice + AI Studio Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    TalkoraColors.iosIndigo,
                  ],
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/voice'),
                    child: const TalkoraVoiceOrb(
                      state: VoiceEngineState.listening,
                      audioLevel: 0.25,
                      size: 92,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'المحادثة الصوتية اللايف جاهزة الآن' : 'Live Voice AI Ready',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'تحدث بالعربية أو الإنجليزية — تحكم بهاتفك، اسأل قواعد GitHub، وولّد الصور بالصوت'
                        : 'Speak Arabic or English — control your phone, query GitHub DBs & generate art',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                          ),
                          onPressed: () => context.push('/voice'),
                          icon: const Icon(CupertinoIcons.mic_fill, size: 18),
                          label: Text(
                            isAr ? 'صوت لايف مباشر' : 'Live Voice',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => context.go('/chat'),
                          icon: const Icon(CupertinoIcons.sparkles, size: 18),
                          label: Text(
                            isAr ? 'استوديو AI' : 'AI Studio',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // LISORA v3.0 Super Suite Grid (8 Power Modules)
            Text(isAr ? 'قدرات LISORA AI v3.0 العملاقة' : 'LISORA AI v3.0 Super Suite',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.38,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _IosFeatureTile(
                  icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                  color: TalkoraColors.iosPink,
                  title: isAr ? 'استوديو توليد الصور' : 'AI Image Studio',
                  subtitle: isAr ? 'Flux مجاني + DALL-E 3' : 'Free Flux + DALL-E 3',
                  onTap: () => context.push('/image-studio'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.layers_alt_fill,
                  color: TalkoraColors.iosIndigo,
                  title: isAr ? 'قواعد بيانات GitHub' : 'GitHub Mega-DB',
                  subtitle: isAr
                      ? '${gh.totalEntries} سجل • بحث RAG'
                      : '${gh.totalEntries} records • RAG',
                  onTap: () => context.push('/github-db'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.device_phone_portrait,
                  color: TalkoraColors.iosGreen,
                  title: isAr ? 'إدارة الهاتف والتطبيقات' : 'Phone Manager',
                  subtitle: isAr ? 'فتح التطبيقات والأوامر' : 'Apps, Torch & System',
                  onTap: () => context.push('/device-hub'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.lock_shield_fill,
                  color: TalkoraColors.iosBlue,
                  title: isAr ? 'مفاتيح AI والشرح' : 'AI Keys & Guide',
                  subtitle: isAr ? '12 مزود + تحويل ذكي' : '12 Providers + Guide',
                  onTap: () => context.push('/settings'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.person_2_fill,
                  color: TalkoraColors.iosPurple,
                  title: s.t('roleplay'),
                  subtitle: isAr ? '8 مواقف واقعية' : '8 Real Scenarios',
                  onTap: () => context.push('/roleplay'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.globe,
                  color: TalkoraColors.iosTeal,
                  title: s.t('translator'),
                  subtitle: isAr ? 'ترجمة وتعبيرات أصلية' : 'Idioms & Examples',
                  onTap: () => context.push('/translator'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Compact Progress Card
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/progress'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'تقدمك اليومي' : 'Daily Progress', style: theme.textTheme.titleMedium),
                          Text(
                            '${profile.speakingMinutesToday} / ${profile.dailyTargetMinutes} ${isAr ? 'د' : 'min'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: progressRatio, minHeight: 7),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BentoStat(label: isAr ? 'المستوى' : 'Level', value: profile.englishLevel),
                          _BentoStat(label: isAr ? 'المفردات' : 'Words', value: '${profile.vocabularyLearned}'),
                          _BentoStat(label: isAr ? 'السلسلة' : 'Streak', value: '${profile.streakDays}d'),
                          _BentoStat(label: 'XP', value: '${profile.xpPoints}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Developer Contact Banner (YOSSEF JOO • WhatsApp 01029892573)
            Card(
              child: ListTile(
                leading: const IosIconBadge(
                  icon: CupertinoIcons.chat_bubble_fill,
                  color: TalkoraColors.iosGreen,
                  size: 38,
                ),
                title: const Text('YOSSEF JOO', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  isAr ? 'مطور التطبيق • واتساب: 01029892573' : 'Developer • WhatsApp: 01029892573',
                ),
                trailing: Icon(CupertinoIcons.arrow_up_right_circle_fill, color: TalkoraColors.iosGreen),
                onTap: () => ref.read(nativeBridgeProvider).openWhatsApp(
                      phone: '01029892573',
                      message: 'مرحباً مهندس YOSSEF JOO، أتواصل معك من داخل تطبيق LISORA AI v3.0',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoStat extends StatelessWidget {
  final String label;
  final String value;
  const _BentoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _IosFeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _IosFeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IosIconBadge(icon: icon, color: color, size: 34),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
