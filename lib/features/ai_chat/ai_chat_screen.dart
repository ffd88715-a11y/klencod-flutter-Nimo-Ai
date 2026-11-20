import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/ai/ai_tool_executor.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

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

/// LISORA AI v3.0 — Supercharged AI Chat Studio with GitHub RAG, Phone Control,
/// Inline Image Generation, Deep Thinking, Read-Aloud TTS & 8 Specialist Personas.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  static const _kHistoryKey = 'talkora_ai_chat_history_v2';

  static const List<_TutorPersona> _personas = [
    _TutorPersona(
      id: 'general',
      nameEn: 'Super AI',
      nameAr: 'الذكاء الخارق',
      icon: CupertinoIcons.sparkles,
      color: TalkoraColors.iosBlue,
      prompt:
          'You are LISORA Super AI v3.0 developed by YOSSEF JOO. You are an ultra-intelligent, accurate, helpful assistant. Answer deeply and clearly in the user language (Arabic or English).',
    ),
    _TutorPersona(
      id: 'commander',
      nameEn: 'Phone Commander',
      nameAr: 'مدير الهاتف',
      icon: CupertinoIcons.device_phone_portrait,
      color: TalkoraColors.iosGreen,
      prompt:
          'You are LISORA Phone Commander. Help the user manage their Android phone, open apps, send WhatsApp, set alarms/timers, control flashlight, navigate Maps, and search YouTube.',
    ),
    _TutorPersona(
      id: 'coder',
      nameEn: 'Senior Coder',
      nameAr: 'مبرمج خبير',
      icon: CupertinoIcons.chevron_left_slash_chevron_right,
      color: TalkoraColors.iosIndigo,
      prompt:
          'You are a Principal Software Architect (Flutter, Dart, Python, Kotlin, Web, AI). Write clean, production-ready code with clear explanations.',
    ),
    _TutorPersona(
      id: 'coach',
      nameEn: 'English Coach',
      nameAr: 'مدرب الإنجليزية',
      icon: CupertinoIcons.chat_bubble_2_fill,
      color: TalkoraColors.iosTeal,
      prompt:
          'You are LISORA AI English Coach. Reply naturally in English, gently correct any grammar mistake, and include a concise Arabic translation when helpful.',
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
      id: 'grammar',
      nameEn: 'Grammar Surgeon',
      nameAr: 'خبير القواعد',
      icon: CupertinoIcons.doc_text_search,
      color: TalkoraColors.iosPink,
      prompt:
          'You are an expert English grammar teacher for Arabic speakers. Explain grammar rules clearly with bilingual Arabic/English examples.',
    ),
    _TutorPersona(
      id: 'creative',
      nameEn: 'Creative Studio',
      nameAr: 'كاتب ومبدع',
      icon: CupertinoIcons.paintbrush_fill,
      color: TalkoraColors.iosRed,
      prompt:
          'You are a master creative writer, storyteller, and prompt designer. Craft vivid stories, scripts, and image prompts.',
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
      final trimmed = _messages.length > 50 ? _messages.sublist(_messages.length - 50) : _messages;
      await prefs.setString(_kHistoryKey, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isSending) return;

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
              modelUsed: 'LISORA Instant Engine',
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

    // 2. Build GitHub RAG context + Device Control instructions
    final ragContext = ref.read(githubKnowledgeProvider.notifier).buildRagContext(text);
    final sysPrompt = StringBuffer(_activePersona.prompt);
    if (aiSettings.deviceControlEnabled) {
      sysPrompt.writeln('\n${AiToolExecutor.systemToolPrompt}');
    }

    final recentContext = _messages.length > 16 ? _messages.sublist(_messages.length - 16) : _messages;
    final result = await aiService.sendChat(
      settings: aiSettings,
      messages: recentContext,
      systemPromptOverride: sysPrompt.toString(),
      ragContext: ragContext,
    );

    if (!mounted) return;

    String replyText;
    String? actionBadge;
    String? imageUrl;

    if (result.success) {
      final outcome = aiSettings.deviceControlEnabled
          ? await executor.executeAiTags(result.text, isArabic: isAr)
          : ToolExecutionOutcome(cleanReply: result.text);
      replyText = outcome.cleanReply;
      actionBadge = outcome.actionBadge;
      imageUrl = outcome.generatedImageUrl;
      ref.read(learnerProfileProvider.notifier).addXp(10);
    } else if (result.error == 'MISSING_API_KEY') {
      replyText = isAr
          ? 'لم تقم بإضافة مفتاح API لـ ${aiSettings.activePreset.name} بعد. يمكنك تفعيل "الاتصال الذكي التلقائي" أو اختيار LISORA Free Cloud AI من الإعدادات للعمل مجاناً فوراً!'
          : 'No API key for ${aiSettings.activePreset.name}. Enable Smart Fallback or pick LISORA Free Cloud AI in Settings!';
    } else {
      replyText = isAr
          ? 'تعذّر الاتصال بالنموذج (${result.providerName}):\n${result.error}'
          : 'Could not reach ${result.providerName}:\n${result.error}';
    }

    setState(() {
      _messages.add(
        AiChatMessage(
          role: 'assistant',
          content: replyText,
          timestamp: DateTime.now(),
          modelUsed: result.success ? '${result.providerName} • ${result.modelName}' : null,
          actionBadge: actionBadge,
          imageUrl: imageUrl,
        ),
      );
      _isSending = false;
    });
    await _saveHistory();
    _scrollToBottom();
  }

  void _exportChat() {
    if (_messages.isEmpty) return;
    final buf = StringBuffer('=== LISORA AI v3.0 Chat Export ===\n\n');
    for (final m in _messages) {
      buf.writeln('${m.role == 'user' ? 'User' : 'LISORA AI'}: ${m.content}\n');
    }
    ref.read(nativeBridgeProvider).shareText(buf.toString(), subject: 'LISORA AI Conversation');
  }

  void _showQuickModelSwitcher() {
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
                    isAr ? 'التبديل السريع بين نماذج AI' : 'Quick Switch AI Model',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
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
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final bridge = ref.read(nativeBridgeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showQuickModelSwitcher,
          child: Column(
            children: [
              Text(isAr ? 'استوديو LISORA AI' : 'LISORA AI Studio', style: theme.textTheme.titleMedium),
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
              setState(() => _messages.clear());
              _saveHistory();
            },
          ),
          IconButton(
            tooltip: isAr ? 'إعدادات API' : 'API Settings',
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 20),
            onPressed: () => context.push('/settings'),
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
                  onSelected: (_) => setState(() => _personaId = p.id),
                );
              },
            ),
          ),

          // Power Feature Toggles Strip (Deep Think + GitHub RAG + Phone Control)
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: Text(isAr ? 'تفكير عميق' : 'Deep Think', style: const TextStyle(fontSize: 11.5)),
                  selected: ai.deepThinkingEnabled,
                  onSelected: (v) =>
                      ref.read(aiSettingsProvider.notifier).updateAdvanced(deepThinkingEnabled: v),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(
                    isAr ? 'بيانات GitHub (${gh.totalEntries})' : 'GitHub DB (${gh.totalEntries})',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  selected: gh.ragEnabled,
                  onSelected: (v) => ref.read(githubKnowledgeProvider.notifier).setRagEnabled(v),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(isAr ? 'تحكم بالهاتف' : 'Phone Control', style: const TextStyle(fontSize: 11.5)),
                  selected: ai.deviceControlEnabled,
                  onSelected: (v) =>
                      ref.read(aiSettingsProvider.notifier).updateAdvanced(deviceControlEnabled: v),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(CupertinoIcons.photo_fill, size: 14),
                  label: Text(isAr ? 'توليد صور' : 'Image Studio', style: const TextStyle(fontSize: 11.5)),
                  onPressed: () => context.push('/image-studio'),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _EmptyStudioView(
                    persona: _activePersona,
                    isAr: isAr,
                    onQuickPrompt: _sendMessage,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
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
                            child: const CupertinoActivityIndicator(),
                          ),
                        );
                      }

                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      final bubbleColor = isUser
                          ? theme.colorScheme.primary
                          : (isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface);
                      final textColor = isUser
                          ? Colors.white
                          : (isDark ? TalkoraColors.darkText : TalkoraColors.lightMainText);

                      return Align(
                        alignment: isUser
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.84,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isUser ? 18 : 5),
                              bottomRight: Radius.circular(isUser ? 5 : 18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg.actionBadge != null) ...[
                                IosStatusPill(
                                  label: msg.actionBadge!,
                                  color: TalkoraColors.iosGreen,
                                  icon: CupertinoIcons.checkmark_seal_fill,
                                ),
                                const SizedBox(height: 6),
                              ],
                              SelectableText(
                                msg.content,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: textColor,
                                  fontSize: 15.2,
                                  height: 1.42,
                                ),
                              ),
                              if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    msg.imageUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (c, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 180,
                                        child: Center(child: CupertinoActivityIndicator()),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              if (!isUser) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (msg.modelUsed != null)
                                      Expanded(
                                        child: Text(
                                          msg.modelUsed!,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? TalkoraColors.darkSecondaryText
                                                : TalkoraColors.lightSecondaryText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    InkWell(
                                      onTap: () => bridge.speak(msg.content),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Icon(CupertinoIcons.volume_up, size: 16),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: msg.content));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isAr ? 'تم النسخ' : 'Copied'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Icon(CupertinoIcons.doc_on_clipboard, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Input Bar with Live Voice Shortcut
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                    tooltip: isAr ? 'المحادثة الصوتية اللايف' : 'Live Voice',
                    icon: Icon(CupertinoIcons.mic_circle_fill, color: theme.colorScheme.primary, size: 32),
                    onPressed: () => context.push('/voice'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'اسأل أي شيء، أو اكتب: ارسم لي... / افتح واتساب...'
                            : 'Ask anything, or try: /image ..., open WhatsApp...',
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
  final ValueChanged<String> onQuickPrompt;

  const _EmptyStudioView({
    required this.persona,
    required this.isAr,
    required this.onQuickPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starters = isAr
        ? [
            'ارسم لي مدينة مستقبلية في مصر بتقنية 8K واقعية',
            'افتح واتساب الآن',
            'حالة البطارية وجهاز الهاتف',
            'اكتب لي كود Flutter احترافي لتطبيق مهام كامل',
          ]
        : [
            '/image futuristic Cairo skyline at sunset 8k cinematic',
            'Open WhatsApp',
            'Check battery status',
            'Write a clean Flutter Riverpod counter & API example',
          ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Center(child: IosIconBadge(icon: persona.icon, color: persona.color, size: 58)),
        const SizedBox(height: 12),
        Text(
          isAr ? persona.nameAr : persona.nameEn,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          isAr
              ? 'مدعوم بقواعد بيانات GitHub العملاقة، توليد الصور، والتحكم الكامل بالهاتف'
              : 'Powered by GitHub Mega-Datasets, AI Image Gen & Full Phone Control',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        ...starters.map(
          (prompt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                title: Text(prompt, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5)),
                trailing: Icon(CupertinoIcons.arrow_up_circle_fill, color: theme.colorScheme.primary),
                onTap: () => onQuickPrompt(prompt),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
