import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/image_gen_service.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/knowledge/nimo_local_db_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

/// Nimo v4.0 Ultra — Supercharged Home Hub with Animated Liquid Glass Icons,
/// Realistic Human Voice, Coding Lab Pro, 4,300+ Offline DB, Key-Based Image Studio & YOSSEF JOO Branding.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final ai = ref.watch(aiSettingsProvider);
    final gh = ref.watch(githubKnowledgeProvider);
    final localDb = ref.watch(nimoLocalDbProvider);
    final s = ref.watch(appStringsProvider);
    final isAr = s.isArabic;
    final theme = Theme.of(context);
    final totalKnowledge = localDb.totalRecords + gh.totalEntries;
    final progressRatio = (profile.speakingMinutesToday / profile.dailyTargetMinutes).clamp(0.0, 1.0);
    final imgRoute = ImageGenService.describeActiveKeyRoute(ai, isAr: isAr);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            // Top Bar + Active 2026 AI Model Pill
            Row(
              children: [
                IosIconBadge(
                  icon: CupertinoIcons.sparkles,
                  color: theme.colorScheme.primary,
                  size: 44,
                  animatedGlass: profile.glassIconAnimationEnabled,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'Nimo • أهلاً ${profile.displayName}' : 'Nimo • Hi ${profile.displayName}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontSize: 19.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                NimoGlassTap(
                  onTap: () => context.push('/settings'),
                  child: IosIconBadge(
                    icon: CupertinoIcons.gear_alt_fill,
                    color: TalkoraColors.iosIndigo,
                    size: 38,
                    animatedGlass: profile.glassIconAnimationEnabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Realistic Human Voice + Nimo Studio Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    TalkoraColors.iosIndigo,
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.9),
              ),
              child: Column(
                children: [
                  NimoGlassTap(
                    onTap: () => context.push('/voice'),
                    child: const TalkoraVoiceOrb(
                      state: VoiceEngineState.listening,
                      audioLevel: 0.26,
                      size: 92,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'تحدث مع Nimo بصوت بشري طبيعي' : 'Talk to Nimo with Realistic Voice',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'مرتبط بـ $totalKnowledge سجل معرفي ذكي + أحدث موديلات 2026 + تحكم كامل بالهاتف'
                        : 'Powered by $totalKnowledge knowledge records + 2026 AI models + phone control',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
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
                          onPressed: () {
                            NimoSoundFx.click();
                            context.push('/voice');
                          },
                          icon: const Icon(CupertinoIcons.mic_fill, size: 18),
                          label: Text(
                            isAr ? 'صوت بشري لايف' : 'Human Voice',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.20),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            NimoSoundFx.click();
                            context.go('/chat');
                          },
                          icon: const Icon(CupertinoIcons.sparkles, size: 18),
                          label: Text(
                            isAr ? 'محادثة Nimo' : 'Nimo Chat',
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

            // Nimo v4.0 Ultra Super Suite Grid (8 Power Modules with Liquid Glass Icons)
            Text(
              isAr ? 'قدرات Nimo v4.0 Ultra العملاقة' : 'Nimo v4.0 Ultra Super Suite',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.32,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _IosFeatureTile(
                  icon: CupertinoIcons.chevron_left_slash_chevron_right,
                  color: TalkoraColors.iosTeal,
                  title: isAr ? 'مختبر البرمجة Pro' : 'Coding Lab Pro',
                  subtitle: isAr ? 'تلوين + نسخ + ذكاء AI' : 'Syntax + Copy + AI',
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/coding-lab'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                  color: TalkoraColors.iosPink,
                  title: isAr ? 'مولد الصور الذكي' : 'AI Image Studio',
                  subtitle: imgRoute,
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/image-studio'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.layers_alt_fill,
                  color: TalkoraColors.iosIndigo,
                  title: isAr ? 'قواعد بيانات Nimo' : 'Nimo Mega-DB',
                  subtitle: isAr ? '$totalKnowledge سجل فوري' : '$totalKnowledge fast records',
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/github-db'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.lock_shield_fill,
                  color: TalkoraColors.iosBlue,
                  title: isAr ? 'موديلات 2026 والمفاتيح' : '2026 Models & Keys',
                  subtitle: isAr ? 'GPT-6.2 / Gemini 3.8 / Claude 5' : 'GPT-6.2 • Gemini 3.8',
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/settings'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.device_phone_portrait,
                  color: TalkoraColors.iosGreen,
                  title: isAr ? 'إدارة الهاتف والتطبيقات' : 'Phone Manager',
                  subtitle: isAr ? 'فتح التطبيقات والأوامر' : 'Apps, Torch & System',
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/device-hub'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.globe,
                  color: TalkoraColors.iosOrange,
                  title: s.t('translator'),
                  subtitle: isAr ? 'ترجمة وتعبيرات أصلية' : 'Idioms & Examples',
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/translator'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.person_2_fill,
                  color: TalkoraColors.iosPurple,
                  title: s.t('roleplay'),
                  subtitle: isAr ? '8 مواقف واقعية' : '8 Real Scenarios',
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/roleplay'),
                ),
                _IosFeatureTile(
                  icon: CupertinoIcons.book_fill,
                  color: TalkoraColors.iosRed,
                  title: isAr ? 'التدريب والمفردات' : 'Practice & Vocab',
                  subtitle: isAr ? 'نطق وقواعد وتحديات' : 'Grammar & Challenges',
                  animatedGlass: profile.glassIconAnimationEnabled,
                  onTap: () => context.push('/practice-hub'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Compact Progress Card
            NimoGlassTap(
              onTap: () => context.push('/progress'),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'تقدمك اليومي في Nimo' : 'Nimo Daily Progress',
                              style: theme.textTheme.titleMedium),
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
                          _BentoStat(label: isAr ? 'السجلات' : 'Records', value: '$totalKnowledge'),
                          _BentoStat(label: isAr ? 'المستوى' : 'Level', value: profile.englishLevel),
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
            NimoGlassTap(
              onTap: () => ref.read(nativeBridgeProvider).openWhatsApp(
                    phone: '01029892573',
                    message: 'مرحباً مهندس YOSSEF JOO، أتواصل معك من داخل تطبيق Nimo v4.0 Ultra',
                  ),
              child: Card(
                child: ListTile(
                  leading: IosIconBadge(
                    icon: CupertinoIcons.chat_bubble_fill,
                    color: TalkoraColors.iosGreen,
                    size: 38,
                    animatedGlass: profile.glassIconAnimationEnabled,
                  ),
                  title: const Text('YOSSEF JOO', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    isAr ? 'مطور Nimo • واتساب: 01029892573' : 'Nimo Developer • WhatsApp: 01029892573',
                  ),
                  trailing: const Icon(CupertinoIcons.arrow_up_right_circle_fill, color: TalkoraColors.iosGreen),
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
  final bool animatedGlass;
  final VoidCallback onTap;

  const _IosFeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.animatedGlass,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NimoGlassTap(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IosIconBadge(icon: icon, color: color, size: 36, animatedGlass: animatedGlass),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
