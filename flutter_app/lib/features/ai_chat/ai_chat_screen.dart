import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/ai/ai_tool_executor.dart';
import 'package:talkora_ai/core/audio/realistic_tts_service.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/knowledge/nimo_local_db_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/nimo_chat_bubble.dart';
import 'package:talkora_ai/core/widgets/nimo_clipboard_bar.dart';
import 'package:talkora_ai/features/coding_lab/coding_lab_screen.dart';

class _TutorPersona {
  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;
  final Color color;
  final String prompt;

  const _TutorPersona({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.color,
    required this.prompt,
  });
}

/// Nimo v4.0 Ultra — Supercharged AI Chat Studio with NimoChatBubble, One-Tap Copy/Paste,
/// Coding Lab Handoff, Realistic Human Voice TTS, 4,300+ Offline DB + GitHub RAG & Phone Control.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  static const _kHistoryKey = 'nimo_ai_chat_history_v4';

  static const List<_TutorPersona> _personas = [
    _TutorPersona(
      id: 'general',
      nameEn: 'Nimo Ultra',
      nameAr: 'نيمو الخارق',
      icon: CupertinoIcons.sparkles,
      color: TalkoraColors.iosBlue,
      prompt:
          'You are Nimo v4.0 Ultra developed by YOSSEF JOO. You are an ultra-intelligent, fast, accurate assistant. Answer deeply and clearly in the user language (Arabic or English). Format code in fenced code blocks.',
    ),
    _TutorPersona(
      id: 'coder',
      nameEn: 'Senior Coder',
      nameAr: 'مبرمج خبير',
      icon: CupertinoIcons.chevron_left_slash_chevron_right,
      color: TalkoraColors.iosIndigo,
      prompt:
          'You are Nimo Principal Software Architect (Flutter, Dart, Python, Kotlin, JS/TS, SQL, Web, AI). Write clean, complete, copy-ready code inside fenced code blocks with clear explanations.',
    ),
    _TutorPersona(
      id: 'commander',
      nameEn: 'Phone Commander',
      nameAr: 'مدير الهاتف',
      icon: CupertinoIcons.device_phone_portrait,
      color: TalkoraColors.iosGreen,
      prompt:
          'You are Nimo Phone Commander. Help the user manage their Android phone, open apps, send WhatsApp, set alarms/timers, control flashlight, navigate Maps, and search YouTube.',
    ),
    _TutorPersona(
      id: 'coach',
      nameEn: 'English Coach',
      nameAr: 'مدرب الإنجليزية',
      icon: CupertinoIcons.chat_bubble_2_fill,
      color: TalkoraColors.iosTeal,
      prompt:
          'You are Nimo English Coach. Reply naturally in English, gently correct any grammar mistake, and include a concise Arabic translation when helpful.',
    ),
    _TutorPersona(
      id: 'ielts',
      nameEn: 'IELTS Examiner',
      nameAr: 'ممتحن IELTS',
      icon: CupertinoIcons.rosette,
      color: TalkoraColors.iosPurple,
      prompt:
          'You are an official IELTS Speaking & Writing Examiner. Evaluate the user message with an estimated Band score (1-9), highlight vocabulary upgrades, and ask the next follow-up question.',
    ),
    _TutorPersona(
      id: 'business',
      nameEn: 'Business Pro',
      nameAr: 'خبير أعمال',
      icon: CupertinoIcons.briefcase_fill,
      color: TalkoraColors.iosOrange,
      prompt:
          'You are an executive business strategist, marketing director, and startup advisor. Provide actionable, sharp strategies.',
    ),
    _TutorPersona(
      id: 'creative',
      nameEn: 'Creative Studio',
      nameAr: 'كاتب ومبدع',
      icon: CupertinoIcons.paintbrush_fill,
      color: TalkoraColors.iosRed,
      prompt:
          'You are a master creative writer, storyteller, and AI image prompt designer. Craft vivid stories, scripts, and image prompts.',
    ),
  ];

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<AiChatMessage> _messages = [];
  String _personaId = 'general';
  bool _isSending = false;

  _TutorPersona get _activePersona =>
      _personas.firstWhere((p) => p.id == _personaId, orElse: () => _personas.first);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _messages.clear();
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              _messages.add(AiChatMessage.fromJson(item));
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = _messages.length > 60 ? _messages.sublist(_messages.length - 60) : _messages;
      await prefs.setString(_kHistoryKey, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isSending) return;

    NimoSoundFx.pop();
    _inputCtrl.clear();
    final userMsg = AiChatMessage(role: 'user', content: text, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });
    _scrollToBottom();

    final aiSettings = ref.read(aiSettingsProvider);
    final aiService = ref.read(universalAiServiceProvider);
    final bridge = ref.read(nativeBridgeProvider);
    final executor = AiToolExecutor(bridge);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';

    // 1. Instant local phone command / direct image command
    if (aiSettings.deviceControlEnabled) {
      final instant = await executor.tryInstantLocalCommand(text, isArabic: isAr);
      if (instant != null && mounted) {
        setState(() {
          _messages.add(
            AiChatMessage(
              role: 'assistant',
              content: instant.cleanReply,
              timestamp: DateTime.now(),
              modelUsed: 'Nimo Instant Engine',
              actionBadge: instant.actionBadge,
              imageUrl: instant.generatedImageUrl,
            ),
          );
          _isSending = false;
        });
        await _saveHistory();
        _scrollToBottom();
        return;
      }
    }

    // 2. Build combined RAG context from Nimo 4,300+ Offline DB + GitHub Datasets
    final localRag = ref.read(nimoLocalDbProvider.notifier).buildOfflineRagContext(text, limit: 4);
    final ghRag = ref.read(githubKnowledgeProvider.notifier).buildRagContext(text);
    final combinedRag = '$localRag$ghRag';

    final sysPrompt = StringBuffer(_activePersona.prompt);
    if (aiSettings.deviceControlEnabled) {
      sysPrompt.writeln('\n${AiToolExecutor.systemToolPrompt}');
    }

    final recentContext = _messages.length > 16 ? _messages.sublist(_messages.length - 16) : _messages;
    final result = await aiService.sendChat(
      settings: aiSettings,
      messages: recentContext,
      systemPromptOverride: sysPrompt.toString(),
      ragContext: combinedRag,
    );

    if (!mounted) return;

    String replyText;
    String? actionBadge;
    String? imageUrl;
    String? modelBadge;

    if (result.success) {
      final outcome = aiSettings.deviceControlEnabled
          ? await executor.executeAiTags(result.text, isArabic: isAr)
          : ToolExecutionOutcome(cleanReply: result.text);
      replyText = outcome.cleanReply;
      actionBadge = outcome.actionBadge ?? (localRag.isNotEmpty ? (isAr ? 'مدعوم بقاعدة Nimo' : 'Nimo DB RAG') : null);
      imageUrl = outcome.generatedImageUrl;
      modelBadge = '${result.providerName} • ${result.modelName}';
      ref.read(learnerProfileProvider.notifier).addXp(10);
    } else {
      // Offline intelligence fallback: answer directly from the 4,300+ local Nimo DB!
      final offlineHits = ref.read(nimoLocalDbProvider.notifier).search(text, limit: 4);
      if (offlineHits.isNotEmpty) {
        final buf = StringBuffer(
          isAr
              ? 'إجابة فورية من قاعدة بيانات Nimo المحلية (${ref.read(nimoLocalDbProvider).totalRecords} سجل):\n\n'
              : 'Instant answer from Nimo Offline Mega-DB:\n\n',
        );
        for (final h in offlineHits) {
          buf.writeln('**${h.title}**\n${h.body}\n');
        }
        replyText = buf.toString().trim();
        actionBadge = isAr ? 'ذكاء محلي فوري (أوفلاين)' : 'Instant Offline DB';
        modelBadge = 'Nimo Local Engine';
      } else if (result.error == 'MISSING_API_KEY') {
        replyText = isAr
            ? 'لم تقم بإضافة مفتاح API لـ ${aiSettings.activePreset.name} بعد. يمكنك تفعيل "التحويل الذكي التلقائي" أو اختيار Nimo Free Cloud AI من الإعدادات للعمل مجاناً فوراً!'
            : 'No API key for ${aiSettings.activePreset.name}. Enable Smart Fallback or pick Nimo Free Cloud AI in Settings!';
      } else {
        replyText = isAr
            ? 'تعذّر الاتصال بالنموذج (${result.providerName}):\n${result.error}'
            : 'Could not reach ${result.providerName}:\n${result.error}';
      }
    }

    setState(() {
      _messages.add(
        AiChatMessage(
          role: 'assistant',
          content: replyText,
          timestamp: DateTime.now(),
          modelUsed: modelBadge,
          actionBadge: actionBadge,
          imageUrl: imageUrl,
        ),
      );
      _isSending = false;
    });
    await _saveHistory();
    _scrollToBottom();
  }

  void _regenerateAt(int assistantIdx) {
    if (_isSending || assistantIdx <= 0) return;
    // Find preceding user message
    for (int i = assistantIdx - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        final prompt = _messages[i].content;
        setState(() {
          _messages.removeRange(i, _messages.length);
        });
        _sendMessage(prompt);
        return;
      }
    }
  }

  void _exportChat() {
    if (_messages.isEmpty) return;
    NimoSoundFx.click();
    final buf = StringBuffer('=== Nimo v4.0 Ultra Chat Export ===\n\n');
    for (final m in _messages) {
      buf.writeln('${m.role == 'user' ? 'User' : 'Nimo'}: ${m.content}\n');
    }
    ref.read(nativeBridgeProvider).shareText(buf.toString(), subject: 'Nimo Conversation');
  }

  void _showQuickModelSwitcher() {
    NimoSoundFx.click();
    final ai = ref.read(aiSettingsProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'أحدث موديلات 2026 — تبديل سريع' : 'Latest 2026 AI Models',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      NimoSoundFx.click();
                      Navigator.pop(ctx);
                      context.push('/settings');
                    },
                    child: Text(isAr ? 'إدارة المفاتيح' : 'Manage Keys'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...AiProviderCatalog.all.map((p) {
                final active = p.id == ai.activeProviderId;
                final hasKey = !p.requiresApiKey ||
                    (ai.credentials[p.id]?.apiKey.trim().isNotEmpty ?? false);
                final model = ai.credentialFor(p.id).model;

                return ListTile(
                  leading: IosIconBadge(icon: p.icon, color: p.badgeColor),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(model),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasKey)
                        const Icon(CupertinoIcons.checkmark_circle_fill,
                            color: TalkoraColors.iosGreen, size: 18),
                      if (active) ...[
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.check_mark,
                            color: Theme.of(context).colorScheme.primary, size: 20),
                      ],
                    ],
                  ),
                  onTap: () {
                    NimoSoundFx.click();
                    ref.read(aiSettingsProvider.notifier).selectProvider(p.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiSettingsProvider);
    final gh = ref.watch(githubKnowledgeProvider);
    final localDb = ref.watch(nimoLocalDbProvider);
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalRecords = localDb.totalRecords + gh.totalEntries;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showQuickModelSwitcher,
          child: Column(
            children: [
              Text(isAr ? 'محادثة Nimo الذكية' : 'Nimo AI Studio', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              IosStatusPill(
                label: '${ai.activePreset.shortName} • ${ai.activeModel}',
                color: ai.isConfigured ? theme.colorScheme.primary : TalkoraColors.iosOrange,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'مشاركة المحادثة' : 'Export Chat',
            icon: const Icon(CupertinoIcons.share, size: 20),
            onPressed: _exportChat,
          ),
          IconButton(
            tooltip: isAr ? 'مسح المحادثة' : 'Clear Chat',
            icon: const Icon(CupertinoIcons.trash, size: 20),
            onPressed: () {
              NimoSoundFx.click();
              setState(() => _messages.clear());
              _saveHistory();
            },
          ),
          IconButton(
            tooltip: isAr ? 'إعدادات API' : 'API Settings',
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 20),
            onPressed: () {
              NimoSoundFx.click();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Persona Selector Bar
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              scrollDirection: Axis.horizontal,
              itemCount: _personas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _personas[i];
                final selected = p.id == _personaId;
                return ChoiceChip(
                  avatar: Icon(p.icon, size: 15, color: selected ? Colors.white : p.color),
                  label: Text(isAr ? p.nameAr : p.nameEn),
                  selected: selected,
                  selectedColor: p.color,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : null,
                  ),
                  onSelected: (_) {
                    NimoSoundFx.click();
                    setState(() => _personaId = p.id);
                  },
                );
              },
            ),
          ),

          // Power Feature Toggles Strip
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: Text(isAr ? 'تفكير عميق' : 'Deep Think', style: const TextStyle(fontSize: 11.5)),
                  selected: ai.deepThinkingEnabled,
                  onSelected: (v) {
                    NimoSoundFx.click();
                    ref.read(aiSettingsProvider.notifier).updateAdvanced(deepThinkingEnabled: v);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(
                    isAr ? 'قاعدة Nimo ($totalRecords)' : 'Nimo DB ($totalRecords)',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  selected: gh.ragEnabled,
                  onSelected: (v) {
                    NimoSoundFx.click();
                    ref.read(githubKnowledgeProvider.notifier).setRagEnabled(v);
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(CupertinoIcons.chevron_left_slash_chevron_right, size: 14),
                  label: Text(isAr ? 'مختبر البرمجة' : 'Code Lab', style: const TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    NimoSoundFx.click();
                    context.push('/coding-lab');
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(CupertinoIcons.photo_fill, size: 14),
                  label: Text(isAr ? 'مولد الصور' : 'Image Studio', style: const TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    NimoSoundFx.click();
                    context.push('/image-studio');
                  },
                ),
              ],
            ),
          ),

          // Messages List with NimoChatBubble
          Expanded(
            child: _messages.isEmpty
                ? _EmptyStudioView(
                    persona: _activePersona,
                    isAr: isAr,
                    totalRecords: totalRecords,
                    onQuickPrompt: _sendMessage,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? TalkoraColors.darkFill : TalkoraColors.lightFill,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CupertinoActivityIndicator(),
                                const SizedBox(width: 10),
                                Text(
                                  isAr ? 'Nimo يفكر...' : 'Nimo is thinking...',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = _messages[index];
                      return NimoChatBubble(
                        message: msg,
                        isAr: isAr,
                        onSpeak: msg.role == 'assistant'
                            ? () => ref.read(realisticTtsProvider).speakHuman(
                                  text: msg.content,
                                  aiSettings: ref.read(aiSettingsProvider),
                                )
                            : null,
                        onRegenerate: msg.role == 'assistant' ? () => _regenerateAt(index) : null,
                        onShare: msg.role == 'assistant'
                            ? () => ref.read(nativeBridgeProvider).shareText(msg.content, subject: 'Nimo')
                            : null,
                        onOpenInCodingLab: (code, lang) {
                          ref.read(codingLabDraftProvider.notifier).state = (code: code, language: lang);
                          context.push('/coding-lab');
                        },
                      );
                    },
                  ),
          ),

          // Upgraded Bottom Input Bar with One-Tap Paste + Live Human Voice + Send
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: BoxDecoration(
                color: isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: (isDark ? TalkoraColors.darkSeparator : TalkoraColors.lightSeparator)
                        .withValues(alpha: 0.45),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: isAr ? 'التحدث الصوتي البشري' : 'Human Live Voice',
                    icon: Icon(CupertinoIcons.mic_circle_fill, color: theme.colorScheme.primary, size: 32),
                    onPressed: () {
                      NimoSoundFx.click();
                      context.push('/voice');
                    },
                  ),
                  IconButton(
                    tooltip: isAr ? 'لصق من الحافظة' : 'Paste',
                    icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 22),
                    onPressed: () => NimoClipboardHelper.pasteIntoController(
                      context,
                      _inputCtrl,
                      isAr: isAr,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'اسأل Nimo أي شيء، أو الصق كوداً، أو اكتب: ارسم لي...'
                            : 'Ask Nimo anything, paste code, or type /image ...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: _isSending ? null : _sendMessage,
                      child: const Icon(CupertinoIcons.arrow_up, size: 20),
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

class _EmptyStudioView extends StatelessWidget {
  final _TutorPersona persona;
  final bool isAr;
  final int totalRecords;
  final ValueChanged<String> onQuickPrompt;

  const _EmptyStudioView({
    required this.persona,
    required this.isAr,
    required this.totalRecords,
    required this.onQuickPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starters = isAr
        ? [
            'اكتب لي كود Flutter احترافي لبطاقة زجاجية مع أنيميشن ناعم',
            'ارسم لي مدينة مستقبلية في القاهرة بتقنية 8K واقعية',
            'افتح واتساب الآن',
            'اشرح لي أحدث موديلات الذكاء الاصطناعي في 2026',
          ]
        : [
            'Write a clean Flutter liquid glass card widget with animation',
            '/image futuristic Cairo skyline at sunset 8k cinematic',
            'Open WhatsApp',
            'Explain the latest 2026 AI models comparison',
          ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Center(child: IosIconBadge(icon: persona.icon, color: persona.color, size: 60)),
        const SizedBox(height: 12),
        Text(
          isAr ? persona.nameAr : persona.nameEn,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          isAr
              ? 'مدعوم بـ $totalRecords سجل معرفي فوري + أحدث موديلات 2026 + مختبر برمجة وصوت بشري'
              : 'Powered by $totalRecords indexed records + 2026 AI models + Coding Lab & Human Voice',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        ...starters.map(
          (prompt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NimoGlassTap(
              onTap: () => onQuickPrompt(prompt),
              child: Card(
                child: ListTile(
                  title: Text(prompt, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5)),
                  trailing: Icon(CupertinoIcons.arrow_up_circle_fill, color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
