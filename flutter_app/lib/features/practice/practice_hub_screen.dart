import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final isAr = s.isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('nav_practice'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IosGroupedSection(
            header: isAr ? 'استوديو الذكاء الاصطناعي التفاعلي' : 'AI INTERACTIVE LABS',
            children: [
              IosSettingsRow(
                icon: CupertinoIcons.person_2_fill,
                iconColor: TalkoraColors.iosPurple,
                title: s.t('roleplay'),
                subtitle: isAr ? '8 مواقف واقعية مع محادثة AI حية' : '8 real-life scenarios with live AI coaching',
                onTap: () => context.push('/roleplay'),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.wand_stars,
                iconColor: TalkoraColors.iosGreen,
                title: s.t('writing_lab'),
                subtitle: isAr ? 'تصحيح الكتابة وتغيير الأسلوب وتقييم IELTS' : 'Rewrite, grammar fixes & IELTS band score',
                onTap: () => context.push('/writing'),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.globe,
                iconColor: TalkoraColors.iosTeal,
                title: s.t('translator'),
                subtitle: isAr ? 'ترجمة فورية وشرح التعبيرات الاصطلاحية' : 'Bidirectional translator & idiom decoder',
                onTap: () => context.push('/translator'),
              ),
            ],
          ),
          IosGroupedSection(
            header: isAr ? 'مهارات التحدث والاستماع والقواعد' : 'CORE ENGLISH SKILLS',
            children: [
              IosSettingsRow(
                icon: CupertinoIcons.mic_fill,
                iconColor: TalkoraColors.iosBlue,
                title: s.t('free_conversation'),
                subtitle: isAr ? 'محادثة صوتية مباشرة بموجات صوتية حقيقية' : 'Real-time voice dialogue with instant feedback',
                onTap: () => context.push('/voice'),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.waveform,
                iconColor: TalkoraColors.iosIndigo,
                title: s.t('pronunciation'),
                subtitle: isAr ? 'تحليل النطق ومقارنة الصوتيات IPA' : 'Phoneme feedback & IPA reference',
                onTap: () => context.push('/practice/pronunciation'),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.book_fill,
                iconColor: TalkoraColors.iosOrange,
                title: s.t('grammar'),
                subtitle: isAr ? 'شرح مبسط بالعربية مع تدريبات فورية' : 'Bilingual explanations & instant drills',
                onTap: () => context.push('/practice/grammar'),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.headphones,
                iconColor: TalkoraColors.iosPink,
                title: s.t('listening'),
                subtitle: isAr ? 'دروس استماع بلهجات متعددة مع النص' : 'Multi-accent audio lessons & transcripts',
                onTap: () => context.push('/practice/listening'),
              ),
              IosSettingsRow(
                icon: CupertinoIcons.bolt_fill,
                iconColor: TalkoraColors.iosRed,
                title: s.t('daily_challenge'),
                subtitle: isAr ? 'تحدي التحدث اليومي لمدة 90 ثانية' : 'Focused 90-second speaking sprint',
                onTap: () => context.push('/practice/challenge'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
