import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  String _nativeLang = 'Arabic';
  String _level = 'B1';
  String _goal = 'Fluency';
  String _accent = 'American';
  int _dailyMinutes = 15;
  String _explanationLang = 'Arabic';

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _goals = [
    'Daily conversations',
    'Travel',
    'Work',
    'Education',
    'Pronunciation',
    'Fluency',
    'General English',
  ];
  static const _accents = ['American', 'British', 'Australian', 'Canadian'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(learnerProfileProvider.notifier).saveOnboarding(
          displayName: _nameCtrl.text.trim().isEmpty ? 'Learner' : _nameCtrl.text.trim(),
          nativeLanguage: _nativeLang,
          englishLevel: _level,
          learningGoal: _goal,
          preferredAccent: _accent,
          dailyTargetMinutes: _dailyMinutes,
          explanationLanguage: _explanationLang,
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('onboarding_title')),
        actions: [
          TextButton(
            onPressed: () {
              final next = s.isArabic ? 'en' : 'ar';
              ref.read(learnerProfileProvider.notifier).setLocale(next);
            },
            child: Text(s.isArabic ? 'EN' : 'العربية'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Your Display Name', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Yossef',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Text('English Level (CEFR)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _levels
                  .map(
                    (lvl) => ChoiceChip(
                      label: Text(lvl),
                      selected: _level == lvl,
                      onSelected: (_) => setState(() => _level = lvl),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text('Learning Goal', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goals
                  .map(
                    (g) => ChoiceChip(
                      label: Text(g),
                      selected: _goal == g,
                      onSelected: (_) => setState(() => _goal = g),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text('Preferred Accent', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _accents
                  .map(
                    (a) => ChoiceChip(
                      label: Text(a),
                      selected: _accent == a,
                      onSelected: (_) => setState(() => _accent = a),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Target', style: theme.textTheme.titleMedium),
                Text('$_dailyMinutes min / day', style: theme.textTheme.titleMedium),
              ],
            ),
            Slider(
              value: _dailyMinutes.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '$_dailyMinutes min',
              onChanged: (v) => setState(() => _dailyMinutes = v.round()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _explanationLang,
              decoration: InputDecoration(
                labelText: 'Preferred Explanation Language',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'Arabic', child: Text('Arabic (العربية)')),
                DropdownMenuItem(value: 'English', child: Text('English Only')),
              ],
              onChanged: (v) => setState(() => _explanationLang = v ?? 'Arabic'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _finish,
              child: Text(s.t('onboarding_cta')),
            ),
          ],
        ),
      ),
    );
  }
}
