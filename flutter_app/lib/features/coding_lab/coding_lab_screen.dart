import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/knowledge/nimo_local_db_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/nimo_clipboard_bar.dart';

/// Shared draft holder so any chat code block can open directly inside Nimo Coding Lab.
final codingLabDraftProvider = StateProvider<({String code, String language})?>((ref) => null);

/// Nimo v4.0 Ultra — Professional Coding Lab Pro (مختبر البرمجة الاحترافي).
/// Features: 9 languages, line numbers, syntax-highlighted preview, one-tap copy/paste,
/// auto-indent formatter, starter templates, and AI Generate / Fix / Explain / Optimize / Convert.
class CodingLabScreen extends ConsumerStatefulWidget {
  const CodingLabScreen({super.key});

  @override
  ConsumerState<CodingLabScreen> createState() => _CodingLabScreenState();
}

class _CodingLabScreenState extends ConsumerState<CodingLabScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _promptCtrl = TextEditingController();
  String _selectedLang = 'Dart / Flutter';
  double _fontSize = 13.5;
  bool _isWorking = false;
  bool _showHighlightedView = false;
  String? _aiOutput;
  String? _aiExtractedCode;

  static const List<String> _languages = [
    'Dart / Flutter',
    'Python',
    'JavaScript',
    'TypeScript',
    'HTML / CSS',
    'Kotlin',
    'SQL',
    'C++',
    'PHP',
  ];

  static const Map<String, String> _starterTemplates = {
    'Dart / Flutter': '''import 'package:flutter/material.dart';

class NimoCard extends StatelessWidget {
  final String title;
  const NimoCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}''',
    'Python': '''def search_records(records: list[dict], query: str) -> list[dict]:
    q = query.strip().lower()
    return [r for r in records if q in r.get("title", "").lower()]

if __name__ == "__main__":
    data = [{"title": "Nimo AI"}, {"title": "Flutter Pro"}]
    print(search_records(data, "nimo"))''',
    'JavaScript': '''async function fetchNimoData(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP \${res.status}`);
  return await res.json();
}''',
    'TypeScript': '''interface NimoTask {
  id: string;
  title: string;
  completed: boolean;
}

export function toggleTask(tasks: NimoTask[], id: string): NimoTask[] {
  return tasks.map(t => (t.id === id ? { ...t, completed: !t.completed } : t));
}''',
    'HTML / CSS': '''<div class="glass-card">
  <h2>Nimo Ultra</h2>
  <p>Clean matte glass component.</p>
</div>
<style>
  .glass-card { padding: 20px; border-radius: 18px; backdrop-filter: blur(14px); }
</style>''',
    'Kotlin': '''fun formatGreeting(name: String): String {
    return "Hello, \$name from Nimo Android!"
}''',
    'SQL': '''SELECT id, title, category
FROM nimo_knowledge
WHERE title LIKE '%flutter%'
ORDER BY id DESC
LIMIT 25;''',
    'C++': '''#include <iostream>
#include <vector>

int main() {
    std::cout << "Nimo Coding Lab C++" << std::endl;
    return 0;
}''',
    'PHP': '''<?php
header('Content-Type: application/json; charset=utf-8');
echo json_encode(['app' => 'Nimo', 'status' => 'online']);
''',
  };

  @override
  void initState() {
    super.initState();
    final draft = ref.read(codingLabDraftProvider);
    if (draft != null && draft.code.isNotEmpty) {
      _codeCtrl.text = draft.code;
      _selectedLang = _matchLanguage(draft.language);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(codingLabDraftProvider.notifier).state = null;
      });
    } else {
      _codeCtrl.text = _starterTemplates[_selectedLang]!;
    }
  }

  String _matchLanguage(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('py')) return 'Python';
    if (l.contains('ts') || l.contains('typescript')) return 'TypeScript';
    if (l.contains('js') || l.contains('javascript')) return 'JavaScript';
    if (l.contains('html') || l.contains('css')) return 'HTML / CSS';
    if (l.contains('kt') || l.contains('kotlin')) return 'Kotlin';
    if (l.contains('sql')) return 'SQL';
    if (l.contains('cpp') || l.contains('c++')) return 'C++';
    if (l.contains('php')) return 'PHP';
    return 'Dart / Flutter';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  void _autoFormatCode() {
    NimoSoundFx.click();
    final lines = _codeCtrl.text.split('\n');
    int indent = 0;
    final out = <String>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.startsWith('}') || line.startsWith(']') || line.startsWith(')')) {
        indent = (indent - 1).clamp(0, 12);
      }
      out.add('${'  ' * indent}$line');
      if (line.endsWith('{') || line.endsWith('[') || line.endsWith('(') || line.endsWith(':')) {
        indent = (indent + 1).clamp(0, 12);
      }
    }
    setState(() => _codeCtrl.text = out.join('\n'));
  }

  Future<void> _runAiCodeAction(String action) async {
    if (_isWorking) return;
    NimoSoundFx.click();
    final code = _codeCtrl.text.trim();
    final idea = _promptCtrl.text.trim();
    if (action == 'generate' && idea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(learnerProfileProvider).uiLocale == 'ar'
                ? 'اكتب وصف الكود المطلوب أولاً في خانة الأمر'
                : 'Enter what you want to build first',
          ),
        ),
      );
      return;
    }
    if (action != 'generate' && code.isEmpty) return;

    setState(() {
      _isWorking = true;
      _aiOutput = null;
      _aiExtractedCode = null;
    });

    final ai = ref.read(aiSettingsProvider);
    final service = ref.read(universalAiServiceProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
    final rag = ref.read(nimoLocalDbProvider.notifier).buildOfflineRagContext('$_selectedLang $idea $action');

    String instruction;
    switch (action) {
      case 'generate':
        instruction = 'Write clean, complete, production-ready $_selectedLang code for: $idea. '
            'Put the final code inside one fenced code block and add a short ${isAr ? 'Arabic' : 'English'} explanation.';
        break;
      case 'fix':
        instruction = 'Find all bugs, edge cases, and syntax issues in this $_selectedLang code, '
            'fix them cleanly, return the full fixed code in one fenced code block, and explain fixes in ${isAr ? 'Arabic' : 'English'}.';
        break;
      case 'optimize':
        instruction = 'Optimize this $_selectedLang code for speed, readability, and clean architecture. '
            'Return the optimized code in one fenced code block and summarize improvements in ${isAr ? 'Arabic' : 'English'}.';
        break;
      default:
        instruction = 'Explain this $_selectedLang code clearly line-by-line in ${isAr ? 'Arabic' : 'English'} with practical tips.';
        break;
    }

    final userMsg = action == 'generate' ? idea : '$instruction\n\n```$_selectedLang\n$code\n```';
    final res = await service.sendChat(
      settings: ai,
      systemPromptOverride:
          'You are Nimo Coding Lab Pro — Principal Software Architect. Deliver clean, bug-free, copy-ready code.',
      ragContext: rag,
      messages: [AiChatMessage(role: 'user', content: userMsg, timestamp: DateTime.now())],
    );

    if (!mounted) return;
    String? extracted;
    if (res.success) {
      final match = RegExp(r"""```[a-zA-Z0-9_+-]*\n?([\s\S]*?)```""").firstMatch(res.text);
      extracted = match?.group(1)?.trim();
      ref.read(learnerProfileProvider.notifier).addXp(25);
    }

    setState(() {
      _isWorking = false;
      _aiOutput = res.success ? res.text : (res.error ?? 'Connection error');
      _aiExtractedCode = extracted;
    });
  }

  TextSpan _highlightCode(String source) {
    final spans = <TextSpan>[];
    final tokenRegex = RegExp(
      r"""(//[^\n]*|#[^\n]*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b(?:import|export|class|extends|implements|const|final|var|let|function|def|return|async|await|if|else|for|while|switch|case|try|catch|new|void|int|double|bool|String|Widget|override|super|true|false|null|SELECT|FROM|WHERE|ORDER|BY|LIMIT|JOIN|INSERT|UPDATE)\b|\b\d+(?:\.\d+)?\b)""",
    );
    int last = 0;
    for (final m in tokenRegex.allMatches(source)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: source.substring(last, m.start),
          style: const TextStyle(color: Color(0xFFE6EDF3)),
        ));
      }
      final tok = m.group(0)!;
      Color color = const Color(0xFFE6EDF3);
      if (tok.startsWith('//') || tok.startsWith('#')) {
        color = const Color(0xFF7D8590);
      } else if (tok.startsWith('"') || tok.startsWith("'")) {
        color = const Color(0xFFA5D6FF);
      } else if (RegExp(r"""^\d""").hasMatch(tok)) {
        color = const Color(0xFFFFB86C);
      } else {
        color = const Color(0xFFFF7B72);
      }
      spans.add(TextSpan(text: tok, style: TextStyle(color: color)));
      last = m.end;
    }
    if (last < source.length) {
      spans.add(TextSpan(
        text: source.substring(last),
        style: const TextStyle(color: Color(0xFFE6EDF3)),
      ));
    }
    return TextSpan(
      style: GoogleFonts.jetBrainsMono(fontSize: _fontSize, height: 1.55),
      children: spans,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final ai = ref.watch(aiSettingsProvider);
    final theme = Theme.of(context);
    final lineCount = '\n'.allMatches(_codeCtrl.text).length + 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(isAr ? 'مختبر البرمجة Pro' : 'Nimo Coding Lab Pro', style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            IosStatusPill(
              label: '$_selectedLang • ${ai.activePreset.shortName}',
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'مصحح الكتابة' : 'Writing Lab',
            icon: const Icon(CupertinoIcons.doc_text, size: 20),
            onPressed: () {
              NimoSoundFx.click();
              context.push('/writing');
            },
          ),
          IconButton(
            tooltip: isAr ? 'تبديل العرض الملون' : 'Toggle Syntax Preview',
            icon: Icon(
              _showHighlightedView ? CupertinoIcons.pencil : CupertinoIcons.eye_fill,
              size: 20,
            ),
            onPressed: () {
              NimoSoundFx.click();
              setState(() => _showHighlightedView = !_showHighlightedView);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        children: [
          // Language Selector Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final lang = _languages[i];
                final sel = lang == _selectedLang;
                return ChoiceChip(
                  label: Text(lang, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  selected: sel,
                  onSelected: (_) {
                    NimoSoundFx.click();
                    setState(() => _selectedLang = lang);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Quick AI Prompt Generator Bar (with Paste button!)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptCtrl,
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'اكتب فكرة الكود ليولده Nimo فوراً...'
                        : 'Describe the code you want Nimo to generate...',
                    prefixIcon: const Icon(CupertinoIcons.sparkles, size: 18),
                    suffixIcon: IconButton(
                      tooltip: isAr ? 'لصق' : 'Paste',
                      icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                      onPressed: () => NimoClipboardHelper.pasteIntoController(
                        context,
                        _promptCtrl,
                        isAr: isAr,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isWorking ? null : () => _runAiCodeAction('generate'),
                  child: _isWorking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CupertinoActivityIndicator(color: Colors.white),
                        )
                      : Text(isAr ? 'توليد' : 'Build'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Professional Code Editor Card with Toolbar & Line Numbers
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101319),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.9),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Editor Toolbar (Copy, Paste, Format, Template, Clear, Zoom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: const Color(0xFF1A1E28),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        NimoCopyChip(
                          textToCopy: _codeCtrl.text,
                          isAr: isAr,
                          label: isAr ? 'نسخ الكود' : 'Copy Code',
                          compact: true,
                        ),
                        const SizedBox(width: 6),
                        _EditorToolBtn(
                          icon: CupertinoIcons.doc_on_clipboard_fill,
                          label: isAr ? 'لصق' : 'Paste',
                          color: TalkoraColors.iosTeal,
                          onTap: () async {
                            await NimoClipboardHelper.pasteIntoController(
                              context,
                              _codeCtrl,
                              isAr: isAr,
                            );
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 6),
                        _EditorToolBtn(
                          icon: CupertinoIcons.text_alignleft,
                          label: isAr ? 'تنسيق' : 'Format',
                          color: TalkoraColors.iosBlue,
                          onTap: _autoFormatCode,
                        ),
                        const SizedBox(width: 6),
                        _EditorToolBtn(
                          icon: CupertinoIcons.square_grid_2x2,
                          label: isAr ? 'قالب' : 'Template',
                          color: TalkoraColors.iosPurple,
                          onTap: () {
                            NimoSoundFx.click();
                            setState(() {
                              _codeCtrl.text = _starterTemplates[_selectedLang] ?? '';
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _EditorToolBtn(
                          icon: CupertinoIcons.trash,
                          label: isAr ? 'مسح' : 'Clear',
                          color: TalkoraColors.iosRed,
                          onTap: () {
                            NimoSoundFx.click();
                            setState(() => _codeCtrl.clear());
                          },
                        ),
                        const SizedBox(width: 6),
                        _EditorToolBtn(
                          icon: CupertinoIcons.textformat_size,
                          label: '${_fontSize.toInt()}pt',
                          color: TalkoraColors.iosOrange,
                          onTap: () {
                            NimoSoundFx.click();
                            setState(() {
                              _fontSize = _fontSize >= 17 ? 12.0 : _fontSize + 1.5;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Code Body (LTR forced so code always reads cleanly even in Arabic UI!)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 240, maxHeight: 390),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line Numbers Gutter
                          Container(
                            width: 40,
                            padding: const EdgeInsets.only(right: 8, left: 6, top: 2),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (int i = 1; i <= lineCount; i++)
                                  Text(
                                    '$i',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: _fontSize - 1,
                                      height: 1.55,
                                      color: const Color(0xFF6E7681),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: _showHighlightedView
                                  ? SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SelectableText.rich(_highlightCode(_codeCtrl.text)),
                                    )
                                  : TextField(
                                      controller: _codeCtrl,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: _fontSize,
                                        height: 1.55,
                                        color: const Color(0xFFE6EDF3),
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: '// Write or paste your code here...',
                                        hintStyle: TextStyle(color: Color(0xFF6E7681)),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: const Color(0xFF161922),
                  child: Row(
                    children: [
                      Text(
                        '$_selectedLang  •  $lineCount ${isAr ? 'سطر' : 'lines'}  •  ${_codeCtrl.text.length} ${isAr ? 'حرف' : 'chars'}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF8B949E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // AI Code Intelligence Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _isWorking ? null : () => _runAiCodeAction('fix'),
                icon: const Icon(CupertinoIcons.wrench_fill, size: 16),
                label: Text(isAr ? 'تصحيح الأخطاء' : 'Fix Bugs'),
              ),
              FilledButton.tonalIcon(
                onPressed: _isWorking ? null : () => _runAiCodeAction('optimize'),
                icon: const Icon(CupertinoIcons.bolt_fill, size: 16),
                label: Text(isAr ? 'تحسين الأداء' : 'Optimize'),
              ),
              FilledButton.tonalIcon(
                onPressed: _isWorking ? null : () => _runAiCodeAction('explain'),
                icon: const Icon(CupertinoIcons.book_fill, size: 16),
                label: Text(isAr ? 'شرح بالعربي' : 'Explain'),
              ),
            ],
          ),

          // AI Output Card
          if (_aiOutput != null) ...[
            const SizedBox(height: 16),
            IosGroupedSection(
              header: isAr ? 'نتيجة مختبر Nimo الذكي' : 'NIMO AI CODE OUTPUT',
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(_aiOutput!, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          NimoCopyChip(
                            textToCopy: _aiExtractedCode ?? _aiOutput!,
                            isAr: isAr,
                            label: _aiExtractedCode != null
                                ? (isAr ? 'نسخ الكود الناتج' : 'Copy Code')
                                : (isAr ? 'نسخ النتيجة' : 'Copy Result'),
                          ),
                          if (_aiExtractedCode != null)
                            FilledButton.tonalIcon(
                              onPressed: () {
                                NimoSoundFx.pop();
                                setState(() => _codeCtrl.text = _aiExtractedCode!);
                              },
                              icon: const Icon(CupertinoIcons.arrow_up_doc_fill, size: 16),
                              label: Text(isAr ? 'تطبيق في المحرر' : 'Apply to Editor'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EditorToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EditorToolBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.5, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
