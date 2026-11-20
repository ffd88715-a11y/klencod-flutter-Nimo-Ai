import 'package:flutter/material.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key});

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  final _targetSentence = 'Practice makes pronunciation very clear and confident.';
  final _spokenCtrl = TextEditingController(text: 'Practice makes pronunciation very clear and confident.');
  double? _score;
  List<String> _tips = [];

  void _evaluate() {
    final targetWords = _targetSentence.toLowerCase().split(RegExp(r"""\s+"""));
    final spokenWords = _spokenCtrl.text.toLowerCase().split(RegExp(r"""\s+"""));
    int matches = 0;
    final foundTips = <String>[];
    for (int i = 0; i < targetWords.length; i++) {
      final tw = targetWords[i].replaceAll(RegExp(r"""[^a-z]"""), '');
      final sw = i < spokenWords.length ? spokenWords[i].replaceAll(RegExp(r"""[^a-z]"""), '') : '';
      if (tw == sw) {
        matches++;
      } else if (tw.contains('p')) {
        foundTips.add('"$tw": Focus on crisp /p/ aspiration rather than /b/.');
      } else if (tw.contains('v')) {
        foundTips.add('"$tw": Vibrate vocal cords on /v/ (distinct from /f/).');
      } else {
        foundTips.add('"$tw": Heard "${sw.isEmpty ? "(omitted)" : sw}" — repeat slowly with clear stress.');
      }
    }
    setState(() {
      _score = (matches / targetWords.length) * 100;
      _tips = foundTips;
    });
  }

  @override
  void dispose() {
    _spokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pronunciation Coach')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target Sentence', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(_targetSentence, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('/ˈpræk.tɪs meɪks prəˌnʌn.siˈeɪ.ʃən ˈver.i klɪr/', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _spokenCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Captured Speech Transcript',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _evaluate,
            icon: const Icon(Icons.graphic_eq_rounded),
            label: const Text('Analyze Pronunciation'),
          ),
          if (_score != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${_score!.toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: _score! >= 80 ? TalkoraColors.success : TalkoraColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_tips.isEmpty)
                      const Text('Clear articulation across every word!')
                    else
                      ..._tips.map((t) => Padding(padding: const EdgeInsets.only(top: 6), child: Text('• $t'))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
