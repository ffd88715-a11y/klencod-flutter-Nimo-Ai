import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

/// Bidirectional AI Instant Translator & Idiom Decoder (English <-> Arabic).
class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final TextEditingController _srcCtrl = TextEditingController();
  bool _enToAr = true;
  bool _loading = false;
  String? _output;
  String? _error;

  @override
  void dispose() {
    _srcCtrl.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _srcCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
      _output = null;
    });

    final settings = ref.read(aiSettingsProvider);
    final service = ref.read(universalAiServiceProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
    final direction = _enToAr ? 'English to natural Arabic' : 'Arabic to natural native English';

    final res = await service.sendChat(
      settings: settings,
      systemPromptOverride:
          'You are an expert bilingual English-Arabic translator and idiom decoder. '
          'Translate the user input from $direction.\n'
          'Provide:\n'
          '• Natural Translation\n'
          '• Idiom / Nuance Note (if any)\n'
          '• 2 Short Real-Life Example Sentences (English + Arabic).',
      messages: [
        AiChatMessage(role: 'user', content: text, timestamp: DateTime.now()),
      ],
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _output = res.text;
        ref.read(learnerProfileProvider.notifier).addXp(10);
      } else if (res.error == 'MISSING_API_KEY') {
        _error = isAr
            ? 'أضف مفتاح API في الإعدادات لتشغيل المترجم الذكي.'
            : 'Add an AI API key in Settings to use the Smart Translator.';
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'المترجم الذكي ومفسر التعبيرات' : 'Smart AI Translator'),
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
          // Direction Swap Pill
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _enToAr ? 'English' : 'العربية',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setState(() => _enToAr = !_enToAr),
                    icon: const Icon(CupertinoIcons.arrow_right_arrow_left, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      _enToAr ? 'العربية' : 'English',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          IosGroupedSection(
            header: _enToAr ? 'ENGLISH TEXT' : 'النص العربي',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _srcCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _enToAr
                            ? 'Enter any English phrase or idiom (e.g. "Break a leg")...'
                            : 'اكتب أي جملة عربية لترجمتها لإنجليزية طبيعية كأهل اللغة...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _translate,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CupertinoActivityIndicator(color: Colors.white),
                              )
                            : const Icon(CupertinoIcons.globe, size: 19),
                        label: Text(isAr ? 'ترجمة وشرح ذكي' : 'Translate & Decode'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null)
            Card(
              color: TalkoraColors.iosOrange.withValues(alpha: 0.14),
              child: ListTile(
                title: Text(_error!),
                trailing: TextButton(
                  onPressed: () => context.push('/settings'),
                  child: Text(isAr ? 'الإعدادات' : 'Settings'),
                ),
              ),
            ),
          if (_output != null)
            IosGroupedSection(
              header: isAr ? 'الترجمة والأمثلة' : 'TRANSLATION & EXAMPLES',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(_output!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              ref.read(learnerProfileProvider.notifier).incrementVocabLearned();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? 'تمت الإضافة لحصيلة مفرداتك (+15 XP)' : 'Saved to Vocabulary (+15 XP)'),
                                ),
                              );
                            },
                            icon: const Icon(CupertinoIcons.bookmark_fill, size: 17),
                            label: Text(isAr ? 'حفظ للمفردات' : 'Save Word'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _output!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isAr ? 'تم النسخ' : 'Copied')),
                              );
                            },
                            icon: const Icon(CupertinoIcons.doc_on_doc, size: 17),
                            label: Text(isAr ? 'نسخ' : 'Copy'),
                          ),
                        ],
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
