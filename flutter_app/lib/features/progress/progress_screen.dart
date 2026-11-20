import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _weeklyMinutes = [12, 18, 10, 22, 15, 25, 9];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('nav_progress'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _MetricCard(title: 'CEFR Level', value: profile.englishLevel)),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(title: 'Speaking Today', value: '${profile.speakingMinutesToday}m')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MetricCard(title: 'Vocab Learned', value: '${profile.vocabularyLearned}')),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(title: 'Active Streak', value: '${profile.streakDays} days')),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Speaking Activity (min)', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_weeklyMinutes.length, (i) {
                        final h = (_weeklyMinutes[i] / 30.0) * 100.0;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 24,
                              height: h.clamp(12.0, 104.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_days[i], style: theme.textTheme.bodySmall),
                          ],
                        );
                      }),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
