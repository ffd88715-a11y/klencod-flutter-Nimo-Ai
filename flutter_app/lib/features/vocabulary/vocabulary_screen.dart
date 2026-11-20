import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class VocabCardItem {
  final String word;
  final String ipa;
  final String arabic;
  final String definition;
  final String example;
  final String level;
  bool isFavorite;
  int intervalDays;

  VocabCardItem({
    required this.word,
    required this.ipa,
    required this.arabic,
    required this.definition,
    required this.example,
    required this.level,
    this.isFavorite = false,
    this.intervalDays = 1,
  });
}

class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  String _selectedLevel = 'All';
  final List<VocabCardItem> _items = [
    VocabCardItem(
      word: 'articulate',
      ipa: '/ɑːrˈtɪk.jə.lət/',
      arabic: 'فصيح / يُعبّر بوضوح',
      definition: 'Able to express ideas and feelings clearly in speech.',
      example: 'She is very articulate when explaining complex architectures.',
      level: 'B2',
    ),
    VocabCardItem(
      word: 'commute',
      ipa: '/kəˈmjuːt/',
      arabic: 'يتنقل يومياً للعمل أو الدراسة',
      definition: 'To travel regularly between home and work.',
      example: 'My morning commute takes thirty minutes by metro.',
      level: 'B1',
    ),
    VocabCardItem(
      word: 'resilient',
      ipa: '/rɪˈzɪl.jənt/',
      arabic: 'مرن / قادر على التعافي',
      definition: 'Able to recover quickly from difficulties.',
      example: 'Resilient learners stay consistent even on busy weeks.',
      level: 'C1',
    ),
    VocabCardItem(
      word: 'break the ice',
      ipa: '/breɪk ði aɪs/',
      arabic: 'يكسر الجمود في بداية الحديث',
      definition: 'To say or do something to make people feel relaxed.',
      example: 'A friendly question helps break the ice at meetings.',
      level: 'B1',
    ),
  ];

  void _review(VocabCardItem item, int quality) {
    setState(() {
      item.intervalDays = quality >= 4 ? item.intervalDays * 2 : 1;
    });
    ref.read(learnerProfileProvider.notifier).incrementVocabLearned();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scheduled "${item.word}" for review in ${item.intervalDays} day(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final filtered = _selectedLevel == 'All' ? _items : _items.where((i) => i.level == _selectedLevel).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.t('nav_vocab'))),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: ['All', 'A2', 'B1', 'B2', 'C1']
                  .map(
                    (lvl) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(lvl),
                        selected: _selectedLevel == lvl,
                        onSelected: (_) => setState(() => _selectedLevel = lvl),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, idx) {
                final item = filtered[idx];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(item.word, style: theme.textTheme.titleLarge),
                            ),
                            Chip(label: Text(item.level)),
                            IconButton(
                              icon: Icon(
                                item.isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: item.isFavorite ? TalkoraColors.primaryAccent : null,
                              ),
                              onPressed: () => setState(() => item.isFavorite = !item.isFavorite),
                            ),
                          ],
                        ),
                        Text(item.ipa, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 6),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(item.arabic, style: theme.textTheme.titleMedium),
                        ),
                        const SizedBox(height: 8),
                        Text(item.definition, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 6),
                        Text('"${item.example}"', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => _review(item, 2),
                              child: const Text('Again'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _review(item, 5),
                              child: const Text('Easy (SRS)'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
