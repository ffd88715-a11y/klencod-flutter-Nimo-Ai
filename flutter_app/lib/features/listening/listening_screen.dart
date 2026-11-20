import 'package:flutter/material.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  bool _showTranscript = false;
  bool _isPlaying = false;
  String? _answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Listening Lab')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ordering Coffee in London', style: theme.textTheme.titleLarge),
                      const Chip(label: Text('British • A2')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => setState(() => _isPlaying = !_isPlaying),
                        icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: Text(_isPlaying ? 'Pause' : 'Play Lesson'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _showTranscript = !_showTranscript),
                        child: Text(_showTranscript ? 'Hide Transcript' : 'Show Transcript'),
                      ),
                    ],
                  ),
                  if (_showTranscript) ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Barista: Good morning! What can I get started for you today?\n"
                      "Customer: Hi there, could I have a medium flat white with oat milk, please?\n"
                      "Barista: Of course. To have here or to take away?\n"
                      "Customer: To take away, thanks.",
                    ),
                  ],
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
                  Text('Comprehension Check', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('What kind of milk does the customer order?'),
                  ...['Whole milk', 'Oat milk', 'Soy milk'].map(
                    (opt) => RadioListTile<String>(
                      title: Text(opt),
                      value: opt,
                      groupValue: _answer,
                      onChanged: (v) => setState(() => _answer = v),
                    ),
                  ),
                  if (_answer != null)
                    Text(
                      _answer == 'Oat milk' ? 'Correct! The customer asked for oat milk.' : 'Listen again for the milk choice.',
                      style: theme.textTheme.bodyMedium,
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
