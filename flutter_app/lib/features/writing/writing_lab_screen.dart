import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

/// AI Writing & Grammar Polisher with 5 tone presets and bilingual Arabic explanations.
class WritingLabScreen extends ConsumerStatefulWidget {
  const WritingLabScreen({super.key});

  @override
  ConsumerState<WritingLabScreen> createState() => _WritingLabScreenState();
}

class _WritingLabScreenState extends ConsumerState<WritingLabScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _selectedTone = 'Professional';
  bool _isAnalyzing = false;
  String? _resultText;
  String? _errorText;

  static const _tones = [
    ('Professional', 'احترافي'),
    ('Casual Native', 'يومي طبيعي'),
    ('Academic', 'أكاديمي'),
    ('IELTS Band 8+', 'مستوى IELTS 8+'),
    ('Concise Email', 'إيميل مختصر'),
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _polishText() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _errorText = null;
      _resultText = null;
    });

    final settings = ref.read(aiSettingsProvider);
    final service = ref.read(universalAiServiceProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';

    final res = await service.sendChat(
      settings: settings,
      systemPromptOverride:
          'You are an expert English editor and coach. Rewrite the user text in a $_selectedTone tone.\n'
          'Format your output clearly in 3 sections:\n'
          '1) Polished Version\n'
          '2) Key Corrections & Upgrades (bullet points)\n'
          '3) Estimated Score (Grammar /10, Fluency /10) + brief Arabic explanation.',
      messages: [
        AiChatMessage(role: 'user', content: text, timestamp: DateTime.now()),
      ],
    );

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      if (res.success) {
        _resultText = res.text;
        ref.read(learnerProfileProvider.notifier).addXp(20);
      } else if (res.error == 'MISSING_API_KEY') {
        _errorText = isAr
            ? 'أضف مفتاح API من الإعدادات أولاً لتفعيل مصحح الكتابة الذكي.'
            : 'Add an AI API key in Settings first to use the AI Writing Polisher.';
      } else {
        _errorText = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final ai = ref.watch(aiSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'مصحح الكتابة AI' : 'AI Writing Polisher'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IosStatusPill(
                label: '${ai.activePreset.shortName} • ${ai.activeModel}',
                color: ai.isConfigured ? theme.colorScheme.primary : TalkoraColors.iosOrange,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IosGroupedSection(
            header: isAr ? 'النص المراد تصحيحه وتحسينه' : 'YOUR ENGLISH TEXT',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _inputCtrl,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'اكتب أو الصق أي فقرة إنجليزية هنا لتصحيحها ورفع مستواها...'
                            : 'Write or paste any English paragraph, email, or essay here...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(isAr ? 'أسلوب إعادة الصياغة:' : 'Target Tone:', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _tones.map((t) {
                        final selected = _selectedTone == t.$1;
                        return ChoiceChip(
                          label: Text(isAr ? t.$2 : t.$1),
                          selected: selected,
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                          onSelected: (_) => setState(() => _selectedTone = t.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isAnalyzing ? null : _polishText,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CupertinoActivityIndicator(color: Colors.white),
                              )
                            : const Icon(CupertinoIcons.wand_stars, size: 19),
                        label: Text(isAr ? 'تصحيح وتحسين بالذكاء الاصطناعي' : 'Polish & Score with AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_errorText != null)
            Card(
              color: TalkoraColors.iosOrange.withValues(alpha: 0.14),
              child: ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_circle_fill, color: TalkoraColors.iosOrange),
                title: Text(_errorText!),
                trailing: TextButton(
                  onPressed: () => context.push('/settings'),
                  child: Text(isAr ? 'الإعدادات' : 'Settings'),
                ),
              ),
            ),
          if (_resultText != null)
            IosGroupedSection(
              header: isAr ? 'النتيجة والتحليل الذكي' : 'AI POLISHED RESULT',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(_resultText!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _resultText!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isAr ? 'تم نسخ النتيجة' : 'Result copied')),
                            );
                          },
                          icon: const Icon(CupertinoIcons.doc_on_doc, size: 17),
                          label: Text(isAr ? 'نسخ' : 'Copy'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
