import 'package:flutter/material.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  String? _selected;
  bool _checked = false;

  static const _correct = 'has lived';
  static const _options = ['lived', 'has lived', 'is living', 'lives'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Studio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Present Perfect vs. Past Simple', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Use Past Simple for finished actions at a specific time. Use Present Perfect for actions that started in the past and continue now.',
                  ),
                  const SizedBox(height: 10),
                  const Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'نستخدم الماضي البسيط للأحداث المنتهية في وقت محدد، والمضارع التام للأحداث الممتدة حتى الحاضر.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Practice Question', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text('She ___ in Cairo since 2021.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ..._options.map(
                    (opt) => RadioListTile<String>(
                      title: Text(opt),
                      value: opt,
                      groupValue: _selected,
                      onChanged: (v) => setState(() {
                        _selected = v;
                        _checked = false;
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _selected == null ? null : () => setState(() => _checked = true),
                    child: const Text('Check Answer'),
                  ),
                  if (_checked) ...[
                    const SizedBox(height: 12),
                    Text(
                      _selected == _correct
                          ? 'Correct! Use Present Perfect with "since" + a starting point.'
                          : 'Not quite — the correct answer is "$_correct".',
                      style: TextStyle(
                        color: _selected == _correct ? TalkoraColors.success : TalkoraColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
