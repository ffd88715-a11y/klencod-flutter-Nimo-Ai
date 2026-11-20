import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

class _RoleplayScenario {
  final String titleEn;
  final String titleAr;
  final String level;
  final String roleEn;
  final String openingLine;
  final String goalAr;
  final String goalEn;
  final IconData icon;
  final Color color;

  const _RoleplayScenario({
    required this.titleEn,
    required this.titleAr,
    required this.level,
    required this.roleEn,
    required this.openingLine,
    required this.goalAr,
    required this.goalEn,
    required this.icon,
    required this.color,
  });
}

/// Interactive AI Roleplay Scenarios Arena with 8 curated real-life missions.
class RoleplayScreen extends ConsumerWidget {
  const RoleplayScreen({super.key});

  static const List<_RoleplayScenario> _scenarios = [
    _RoleplayScenario(
      titleEn: 'Coffee Shop Order',
      titleAr: 'طلب قهوة في كافيه',
      level: 'A2',
      roleEn: 'a friendly barista at a specialty coffee shop in New York',
      openingLine: 'Hey there! Welcome to Roast & Bean. What can I get started for you today?',
      goalAr: 'اطلب مشروبك المفضل واسأل عن الحجم والحليب النباتي.',
      goalEn: 'Order a customized drink and ask about milk options.',
      icon: CupertinoIcons.flame_fill,
      color: TalkoraColors.iosOrange,
    ),
    _RoleplayScenario(
      titleEn: 'Tech Job Interview',
      titleAr: 'مقابلة عمل تقنية',
      level: 'B2',
      roleEn: 'a senior engineering manager interviewing a Flutter developer',
      openingLine: 'Thanks for joining us today! To kick things off, tell me about a challenging app you built recently.',
      goalAr: 'عرّف نفسك واشرح مشروعاً تقنياً وتحدياً تغلبت عليه.',
      goalEn: 'Introduce yourself and explain a technical challenge you solved.',
      icon: CupertinoIcons.briefcase_fill,
      color: TalkoraColors.iosBlue,
    ),
    _RoleplayScenario(
      titleEn: 'Airport Immigration',
      titleAr: 'جوازات المطار والسفر',
      level: 'B1',
      roleEn: 'an airport immigration officer at London Heathrow',
      openingLine: 'Good afternoon. May I see your passport please? What is the purpose of your visit?',
      goalAr: 'أجب بثقة عن سبب السفر ومدة الإقامة ومكان السكن.',
      goalEn: 'Answer clearly about your trip purpose, duration, and stay.',
      icon: CupertinoIcons.airplane,
      color: TalkoraColors.iosIndigo,
    ),
    _RoleplayScenario(
      titleEn: 'Hotel Check-In',
      titleAr: 'تسجيل الدخول في فندق',
      level: 'A2',
      roleEn: 'a polite hotel receptionist at a 5-star resort',
      openingLine: 'Good evening and welcome! Do you have a reservation under your name?',
      goalAr: 'أكّد حجزك واطلب غرفة بإطلالة هادئة وتأخر في المغادرة.',
      goalEn: 'Confirm your booking and request a quiet room with late checkout.',
      icon: CupertinoIcons.bed_double_fill,
      color: TalkoraColors.iosTeal,
    ),
    _RoleplayScenario(
      titleEn: 'Doctor Appointment',
      titleAr: 'زيارة الطبيب',
      level: 'B1',
      roleEn: 'a calm, attentive clinic doctor',
      openingLine: 'Hello! Please have a seat. What symptoms have been bothering you lately?',
      goalAr: 'صف الأعراض ومتى بدأت واسأل عن خطة العلاج.',
      goalEn: 'Describe your symptoms, duration, and ask about treatment.',
      icon: CupertinoIcons.heart_fill,
      color: TalkoraColors.iosRed,
    ),
    _RoleplayScenario(
      titleEn: 'Salary Negotiation',
      titleAr: 'التفاوض على الراتب',
      level: 'C1',
      roleEn: 'an HR director extending a job offer',
      openingLine: 'We loved your interviews and want to offer you the role! How do you feel about the proposed package?',
      goalAr: 'تفاوض باحترافية على راتب أعلى ومزايا العمل عن بُعد.',
      goalEn: 'Negotiate compensation and remote flexibility professionally.',
      icon: CupertinoIcons.money_dollar_circle_fill,
      color: TalkoraColors.iosGreen,
    ),
    _RoleplayScenario(
      titleEn: 'Daily Tech Stand-Up',
      titleAr: 'اجتماع الفريق اليومي',
      level: 'B2',
      roleEn: 'a Scrum Master leading a 10-minute morning stand-up',
      openingLine: 'Morning team! You are up next — what did you finish yesterday and any blockers today?',
      goalAr: 'لخّص إنجاز أمس وخطة اليوم وأي عوائق تقنية.',
      goalEn: 'Share yesterday progress, today plan, and blockers concisely.',
      icon: CupertinoIcons.person_3_fill,
      color: TalkoraColors.iosPurple,
    ),
    _RoleplayScenario(
      titleEn: 'Making Friends Abroad',
      titleAr: 'تعارف وصداقة جديدة',
      level: 'A2',
      roleEn: 'a friendly local student sitting at a coworking lounge',
      openingLine: 'Hey! Mind if I sit here? I noticed your laptop — are you visiting the city or living here?',
      goalAr: 'تحدث عن هواياتك وبلدك وتبادل توصيات الأماكن.',
      goalEn: 'Chat naturally about hobbies, travel, and local spots.',
      icon: CupertinoIcons.smiley_fill,
      color: TalkoraColors.iosPink,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'ساحة المواقف التفاعلية' : 'Roleplay Arena'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              isAr
                  ? 'اختر موقفاً واقعياً وتدرّب مع الذكاء الاصطناعي خطوة بخطوة مع تصحيح فوري.'
                  : 'Pick a real-world scenario and practice live with instant AI coaching.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scenarios.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.96,
            ),
            itemBuilder: (context, i) {
              final sc = _scenarios[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => _RoleplaySessionScreen(scenario: sc),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IosIconBadge(icon: sc.icon, color: sc.color, size: 38),
                            IosStatusPill(label: sc.level, color: sc.color),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          isAr ? sc.titleAr : sc.titleEn,
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr ? sc.goalAr : sc.goalEn,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoleplaySessionScreen extends ConsumerStatefulWidget {
  final _RoleplayScenario scenario;
  const _RoleplaySessionScreen({required this.scenario});

  @override
  ConsumerState<_RoleplaySessionScreen> createState() => _RoleplaySessionScreenState();
}

class _RoleplaySessionScreenState extends ConsumerState<_RoleplaySessionScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final List<AiChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      AiChatMessage(
        role: 'assistant',
        content: widget.scenario.openingLine,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add(AiChatMessage(role: 'user', content: txt, timestamp: DateTime.now()));
      _loading = true;
    });

    final settings = ref.read(aiSettingsProvider);
    final service = ref.read(universalAiServiceProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';

    final res = await service.sendChat(
      settings: settings,
      messages: _messages,
      systemPromptOverride:
          'Act strictly in character as ${widget.scenario.roleEn}. Keep replies realistic (2-3 sentences), '
          'and at the end add a short line starting with "Tip:" giving 1 tiny English improvement tip.',
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _messages.add(AiChatMessage(role: 'assistant', content: res.text, timestamp: DateTime.now()));
        ref.read(learnerProfileProvider.notifier).addXp(15);
      } else {
        _messages.add(
          AiChatMessage(
            role: 'assistant',
            content: res.error == 'MISSING_API_KEY'
                ? (isAr
                    ? 'يرجى إضافة مفتاح API من الإعدادات لتشغيل المحادثة الحية في هذا الموقف.'
                    : 'Please add an AI API key in Settings to run live roleplay.')
                : (res.error ?? 'Error'),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? widget.scenario.titleAr : widget.scenario.titleEn),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.scenario.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAr ? 'الهدف: ${widget.scenario.goalAr}' : 'Mission: ${widget.scenario.goalEn}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.scenario.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_loading && i == _messages.length) {
                  return const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(padding: EdgeInsets.all(8), child: CupertinoActivityIndicator()),
                  );
                }
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primary
                          : (isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isUser ? Colors.white : null,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: isAr ? 'اكتب ردك بالإنجليزية...' : 'Type your response...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: _loading ? null : _send,
                      child: const Icon(CupertinoIcons.arrow_up, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
