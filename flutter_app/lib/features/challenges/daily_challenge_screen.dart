import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Speaking Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Chip(label: Text('90 Seconds • B1')),
                    const SizedBox(height: 12),
                    Text('Describe Your Ideal Productive Morning', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    const Text(
                      'Objective: Speak naturally for 90 seconds using at least two sequence words (first, after that, finally) and one future plan.',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(learnerProfileProvider.notifier).incrementSpeakingMinutes(2);
                  context.push('/voice');
                },
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Start Speaking Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
