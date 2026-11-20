import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/ai/ai_tool_executor.dart';
import 'package:talkora_ai/core/audio/realistic_tts_service.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/knowledge/nimo_local_db_service.dart';
import 'package:talkora_ai/core/permissions/mic_permission_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

/// Nimo v4.0 Ultra — Realistic Human Voice Conversation Engine.
/// Routes speech to OpenAI HD Human Voices (`gpt-4o-mini-tts` / `tts-1-hd`), ElevenLabs Ultra-Human,
/// or highest-quality Android Neural/Wavenet voice with natural prosody + 4,300+ Offline DB RAG.
class LiveVoiceScreen extends ConsumerStatefulWidget {
  const LiveVoiceScreen({super.key});

  @override
  ConsumerState<LiveVoiceScreen> createState() => _LiveVoiceScreenState();
}

class _LiveVoiceScreenState extends ConsumerState<LiveVoiceScreen> {
  final _micPermission = const MicPermissionService();
  final ScrollController _transcriptScrollCtrl = ScrollController();

  StreamSubscription<NativeVoiceEvent>? _voiceSub;
  Timer? _autoRestartTimer;

  VoiceEngineState _engineState = VoiceEngineState.listening;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  bool _isMuted = false;
  bool _sessionActive = false;
  bool _autoLoop = true;
  String _voiceLocale = 'ar-EG';
  double _speechRate = 1.0;
  String _activeVoiceEngineLabel = '';

  String _livePartialTranscript = '';
  String _statusNote = '';
  final List<AiChatMessage> _turns = [];

  final List<double> _amplitudes = List<double>.filled(28, 0.08, growable: true);
  double _currentLevel = 0.08;

  static const Map<String, String> _localeLabels = {
    'ar-EG': 'العربية (مصر)',
    'ar-SA': 'العربية (الفصحى)',
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
  };

  @override
  void initState() {
    super.initState();
    final ai = ref.read(aiSettingsProvider);
    _autoLoop = ai.voiceAutoLoopEnabled;
    _voiceLocale = ai.voiceLocale;
    _speechRate = ai.voiceSpeechRate;
    _bindNativeVoiceStream();
  }

  void _bindNativeVoiceStream() {
    final bridge = ref.read(nativeBridgeProvider);
    _voiceSub = bridge.voiceEvents.listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case 'ready':
          setState(() {
            _isListening = true;
            _engineState = VoiceEngineState.listening;
            _statusNote = '';
          });
          break;
        case 'rms':
          if (!_isMuted && _isListening) {
            setState(() => _pushAmplitude(event.level));
          }
          break;
        case 'partial':
          setState(() => _livePartialTranscript = event.text);
          break;
        case 'speech_end':
          setState(() => _engineState = VoiceEngineState.understanding);
          break;
        case 'final':
          final spoken = event.text.trim();
          setState(() {
            _isListening = false;
            _livePartialTranscript = '';
            _pushAmplitude(0.08);
          });
          if (spoken.isNotEmpty) {
            _processUserSpeech(spoken);
          } else if (_sessionActive && _autoLoop && !_isMuted) {
            _scheduleAutoListen(delayMs: 650);
          }
          break;
        case 'error':
          setState(() {
            _isListening = false;
            _pushAmplitude(0.08);
          });
          if ((event.code == 6 || event.code == 7) &&
              _sessionActive &&
              _autoLoop &&
              !_isMuted &&
              !_isThinking &&
              !_isSpeaking) {
            _scheduleAutoListen(delayMs: 700);
          } else if (event.code != 5) {
            setState(() {
              _engineState = VoiceEngineState.listening;
              _statusNote = event.message;
            });
          }
          break;
        case 'tts_start':
          setState(() {
            _isSpeaking = true;
            _engineState = VoiceEngineState.speaking;
          });
          break;
        case 'tts_done':
        case 'tts_stopped':
        case 'tts_error':
          setState(() {
            _isSpeaking = false;
            _pushAmplitude(0.08);
            if (!_isThinking && !_isListening) {
              _engineState = VoiceEngineState.listening;
            }
          });
          if (event.type == 'tts_done' && _sessionActive && _autoLoop && !_isMuted && !_isThinking) {
            _scheduleAutoListen(delayMs: 450);
          }
          break;
      }
    });
  }

  void _pushAmplitude(double normalized) {
    _currentLevel = normalized.clamp(0.06, 1.0);
    _amplitudes.removeAt(0);
    _amplitudes.add(_currentLevel);
  }

  void _scheduleAutoListen({int delayMs = 500}) {
    _autoRestartTimer?.cancel();
    _autoRestartTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted &&
          _sessionActive &&
          _autoLoop &&
          !_isMuted &&
          !_isThinking &&
          !_isSpeaking &&
          !_isListening) {
        _startListeningNow();
      }
    });
  }

  Future<void> _startListeningNow() async {
    final perm = await _micPermission.requestMicrophone();
    if (perm != MicPermissionResult.granted) {
      if (mounted) {
        final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'يرجى السماح بصلاحية الميكروفون لتشغيل المحادثة الصوتية.'
                  : 'Microphone permission is required for Live Voice.',
            ),
          ),
        );
      }
      return;
    }

    await ref.read(realisticTtsProvider).stop();

    setState(() {
      _sessionActive = true;
      _isMuted = false;
      _isSpeaking = false;
      _isListening = true;
      _livePartialTranscript = '';
      _statusNote = '';
      _engineState = VoiceEngineState.listening;
    });

    final ok = await ref.read(nativeBridgeProvider).startListening(locale: _voiceLocale);
    if (!ok && mounted) {
      setState(() {
        _isListening = false;
        _statusNote = 'تأكد من تفعيل خدمة Google Speech Services على الهاتف.';
      });
    }
  }

  Future<void> _toggleLiveMic() async {
    NimoSoundFx.click();
    final bridge = ref.read(nativeBridgeProvider);

    if (_isSpeaking) {
      await ref.read(realisticTtsProvider).stop();
      await _startListeningNow();
      return;
    }

    if (_isListening) {
      _autoRestartTimer?.cancel();
      await bridge.stopListening();
      setState(() {
        _isListening = false;
        _sessionActive = false;
        _pushAmplitude(0.08);
      });
      return;
    }

    await _startListeningNow();
  }

  Future<void> _interruptEverything() async {
    NimoSoundFx.click();
    _autoRestartTimer?.cancel();
    await ref.read(realisticTtsProvider).stop();
    await ref.read(nativeBridgeProvider).cancelListening();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isSpeaking = false;
        _isThinking = false;
        _sessionActive = false;
        _engineState = VoiceEngineState.interrupted;
        _pushAmplitude(0.06);
      });
    }
  }

  Future<void> _processUserSpeech(String spokenText) async {
    final isAr = _voiceLocale.startsWith('ar') || NativeBridgeService.containsArabic(spokenText);
    final bridge = ref.read(nativeBridgeProvider);
    final executor = AiToolExecutor(bridge);

    setState(() {
      _turns.add(AiChatMessage(role: 'user', content: spokenText, timestamp: DateTime.now()));
      _isThinking = true;
      _engineState = VoiceEngineState.thinking;
    });
    _scrollToBottom();

    final aiSettings = ref.read(aiSettingsProvider);
    if (aiSettings.deviceControlEnabled) {
      final instant = await executor.tryInstantLocalCommand(spokenText, isArabic: isAr);
      if (instant != null && mounted) {
        setState(() {
          _isThinking = false;
          _turns.add(
            AiChatMessage(
              role: 'assistant',
              content: instant.cleanReply,
              timestamp: DateTime.now(),
              actionBadge: instant.actionBadge,
              imageUrl: instant.generatedImageUrl,
              modelUsed: 'Nimo Phone Engine',
            ),
          );
        });
        _scrollToBottom();
        await _speakHumanReply(instant.cleanReply);
        return;
      }
    }

    final localRag = ref.read(nimoLocalDbProvider.notifier).buildOfflineRagContext(spokenText, limit: 3);
    final ghRag = ref.read(githubKnowledgeProvider.notifier).buildRagContext(spokenText);

    final voiceSystemPrompt = StringBuffer()
      ..writeln(
        isAr
            ? 'أنت Nimo في وضع المحادثة الصوتية البشرية المباشرة. تحدث كإنسان طبيعي ودود ومختصر (2 إلى 4 جمل واضحة بدون رموز ماركداون أو نجوم) لتكون مثالية للنطق البشري الواقعي. أجب بنفس لغة المستخدم.'
            : 'You are Nimo in Realistic Human Voice mode. Speak like a warm, natural human friend in 2-4 clear spoken sentences with zero markdown symbols.',
      );
    if (aiSettings.deviceControlEnabled) {
      voiceSystemPrompt.writeln(AiToolExecutor.systemToolPrompt);
    }

    final recentContext = _turns.length > 10 ? _turns.sublist(_turns.length - 10) : _turns;
    final aiService = ref.read(universalAiServiceProvider);
    final result = await aiService.sendChat(
      settings: aiSettings,
      messages: recentContext,
      systemPromptOverride: voiceSystemPrompt.toString(),
      ragContext: '$localRag$ghRag',
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
      actionBadge = outcome.actionBadge;
      imageUrl = outcome.generatedImageUrl;
      modelBadge = '${result.providerName} • ${result.modelName}';
      ref.read(learnerProfileProvider.notifier).incrementSpeakingMinutes(1);
    } else {
      final localHits = ref.read(nimoLocalDbProvider.notifier).search(spokenText, limit: 1);
      if (localHits.isNotEmpty) {
        replyText = '${localHits.first.title}. ${localHits.first.body}';
        modelBadge = 'Nimo Offline DB';
      } else {
        replyText = isAr
            ? 'حدثت مشكلة مؤقتة في الاتصال. تأكد من الإنترنت أو راجع مفاتيح API في الإعدادات.'
            : 'Temporary connection issue. Check your internet or AI API keys in Settings.';
      }
    }

    setState(() {
      _isThinking = false;
      _turns.add(
        AiChatMessage(
          role: 'assistant',
          content: replyText,
          timestamp: DateTime.now(),
          modelUsed: modelBadge,
          actionBadge: actionBadge,
          imageUrl: imageUrl,
        ),
      );
    });
    _scrollToBottom();
    await _speakHumanReply(replyText);
  }

  Future<void> _speakHumanReply(String text) async {
    final aiSettings = ref.read(aiSettingsProvider);
    final ttsLocale = NativeBridgeService.containsArabic(text)
        ? (_voiceLocale.startsWith('ar') ? _voiceLocale : 'ar-EG')
        : (_voiceLocale.startsWith('en') ? _voiceLocale : 'en-US');

    final engineUsed = await ref.read(realisticTtsProvider).speakHuman(
          text: text,
          aiSettings: aiSettings,
          locale: ttsLocale,
          rate: _speechRate,
          onStart: () {
            if (!mounted) return;
            setState(() {
              _isSpeaking = true;
              _engineState = VoiceEngineState.speaking;
            });
          },
          onDone: () {
            if (!mounted) return;
            setState(() {
              _isSpeaking = false;
              _pushAmplitude(0.08);
              if (!_isThinking && !_isListening) {
                _engineState = VoiceEngineState.listening;
              }
            });
            if (_sessionActive && _autoLoop && !_isMuted && !_isThinking) {
              _scheduleAutoListen(delayMs: 420);
            }
          },
        );
    if (mounted) {
      setState(() => _activeVoiceEngineLabel = engineUsed);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptScrollCtrl.hasClients) {
        _transcriptScrollCtrl.animateTo(
          _transcriptScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openQuickTypeDialog() {
    NimoSoundFx.click();
    final ctrl = TextEditingController();
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'اكتب لمساعد Nimo الصوتي' : 'Type to Nimo Voice'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isAr
                ? 'مثال: افتح واتساب أو اشرح لي الذكاء الاصطناعي...'
                : 'Ask anything or give a phone command...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          FilledButton(
            onPressed: () {
              NimoSoundFx.pop();
              final txt = ctrl.text.trim();
              Navigator.pop(ctx);
              if (txt.isNotEmpty) _processUserSpeech(txt);
            },
            child: Text(isAr ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
  }

  void _showVoiceProfilePicker() {
    NimoSoundFx.click();
    final ai = ref.read(aiSettingsProvider);
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            Text(
              isAr ? 'اختر الصوت البشري الواقعي' : 'Choose Realistic Human Voice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'يستخدم Nimo تلقائياً OpenAI HD أو ElevenLabs عند إضافة المفتاح، أو أعلى صوت Neural بشري على الهاتف.'
                  : 'Nimo automatically uses OpenAI HD or ElevenLabs when configured, or the highest-quality Neural device voice.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            ...RealisticTtsService.presets.map((p) {
              final sel = ai.voicePresetId == p.id;
              return ListTile(
                leading: IosIconBadge(
                  icon: CupertinoIcons.waveform_circle_fill,
                  color: sel ? TalkoraColors.iosGreen : TalkoraColors.iosBlue,
                ),
                title: Text(isAr ? p.labelAr : p.labelEn, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: sel ? const Icon(CupertinoIcons.checkmark_alt, color: TalkoraColors.iosGreen) : null,
                onTap: () {
                  NimoSoundFx.click();
                  ref.read(aiSettingsProvider.notifier).updateAdvanced(voicePresetId: p.id);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _stateHeadline(bool isAr) {
    if (_isListening) return isAr ? 'أستمع إليك الآن... تحدث بحرية' : 'Listening... Speak naturally';
    if (_isThinking) return isAr ? 'Nimo يفكر ويبحث في القواعد...' : 'Nimo is thinking...';
    if (_isSpeaking) return isAr ? 'Nimo يتحدث بصوت طبيعي (اضغط للمقاطعة)' : 'Nimo Speaking (Tap to interrupt)';
    return isAr ? 'اضغط على الميكروفون للتحدث مع Nimo' : 'Tap microphone to talk with Nimo';
  }

  @override
  void dispose() {
    _autoRestartTimer?.cancel();
    _voiceSub?.cancel();
    _transcriptScrollCtrl.dispose();
    ref.read(nativeBridgeProvider).cancelListening();
    ref.read(realisticTtsProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiSettingsProvider);
    final gh = ref.watch(githubKnowledgeProvider);
    final localDb = ref.watch(nimoLocalDbProvider);
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalKnowledge = localDb.totalRecords + gh.totalEntries;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            NimoSoundFx.click();
            context.pop();
          },
        ),
        title: Column(
          children: [
            Text(isAr ? 'صوت Nimo البشري اللايف' : 'Nimo Realistic Voice', style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            IosStatusPill(
              label: _activeVoiceEngineLabel.isNotEmpty
                  ? _activeVoiceEngineLabel
                  : '${ai.activePreset.shortName} • ${_localeLabels[_voiceLocale] ?? _voiceLocale}',
              color: _isListening
                  ? TalkoraColors.iosGreen
                  : (_isSpeaking ? TalkoraColors.iosBlue : TalkoraColors.iosIndigo),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'اختيار الصوت البشري' : 'Human Voice Profile',
            icon: const Icon(CupertinoIcons.waveform_circle, size: 22),
            onPressed: _showVoiceProfilePicker,
          ),
          IconButton(
            tooltip: isAr ? 'إرسال نص سريع' : 'Quick Type',
            icon: const Icon(CupertinoIcons.keyboard, size: 21),
            onPressed: _openQuickTypeDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(
            children: [
              // Voice Language, Human Voice Profile & Auto-Loop Controls Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ActionChip(
                        avatar: const Icon(CupertinoIcons.person_crop_circle_badge_checkmark, size: 16),
                        label: Text(isAr ? 'الصوت البشري' : 'Human Voice', style: const TextStyle(fontSize: 12)),
                        onPressed: _showVoiceProfilePicker,
                      ),
                    ),
                    ..._localeLabels.entries.map((entry) {
                      final selected = _voiceLocale == entry.key;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) {
                            NimoSoundFx.click();
                            setState(() => _voiceLocale = entry.key);
                            ref.read(aiSettingsProvider.notifier).updateAdvanced(voiceLocale: entry.key);
                          },
                        ),
                      );
                    }),
                    FilterChip(
                      avatar: Icon(
                        CupertinoIcons.repeat,
                        size: 15,
                        color: _autoLoop ? theme.colorScheme.primary : null,
                      ),
                      label: Text(isAr ? 'استماع مستمر' : 'Hands-Free', style: const TextStyle(fontSize: 12)),
                      selected: _autoLoop,
                      onSelected: (v) {
                        NimoSoundFx.click();
                        setState(() => _autoLoop = v);
                        ref.read(aiSettingsProvider.notifier).updateAdvanced(voiceAutoLoopEnabled: v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Interactive Live Voice Orb
              GestureDetector(
                onTap: _toggleLiveMic,
                child: TalkoraVoiceOrb(
                  state: _engineState,
                  audioLevel: _isSpeaking ? 0.45 : _currentLevel,
                  size: 144,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _stateHeadline(isAr),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (totalKnowledge > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isAr
                        ? 'مرتبط بـ $totalKnowledge سجل معرفي + صوت بشري طبيعي'
                        : 'Connected to $totalKnowledge records + Realistic Human Voice',
                    style: theme.textTheme.bodySmall?.copyWith(color: TalkoraColors.iosGreen),
                  ),
                ),
              if (_statusNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _statusNote,
                    style: theme.textTheme.bodySmall?.copyWith(color: TalkoraColors.iosOrange),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),

              TalkoraWaveform(
                amplitudeHistory: _amplitudes,
                height: 44,
                color: _isSpeaking ? TalkoraColors.iosGreen : theme.colorScheme.primary,
              ),

              if (_livePartialTranscript.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _livePartialTranscript,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 10),

              Expanded(
                child: _turns.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            isAr
                                ? 'تحدث مع Nimo بصوت طبيعي واقعي! جرّب: "افتح واتساب" أو "اشرح لي Flutter" أو اسأل أي سؤال.'
                                : 'Speak with Nimo in a natural human voice! Try "Open WhatsApp" or ask anything.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _transcriptScrollCtrl,
                        itemCount: _turns.length,
                        itemBuilder: (context, idx) {
                          final msg = _turns[idx];
                          final isUser = msg.role == 'user';
                          return Align(
                            alignment: isUser
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.84,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? theme.colorScheme.primary
                                    : (isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface),
                                borderRadius: BorderRadius.circular(16),
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
                                      color: isUser ? Colors.white : null,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (!isUser && msg.modelUsed != null) ...[
                                    const SizedBox(height: 4),
                                    Text(msg.modelUsed!, style: theme.textTheme.bodySmall),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.speedometer, size: 17, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(isAr ? 'سرعة الصوت' : 'Speed', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: CupertinoSlider(
                      value: _speechRate.clamp(0.65, 1.5),
                      min: 0.65,
                      max: 1.5,
                      divisions: 10,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) {
                        setState(() => _speechRate = v);
                        ref.read(aiSettingsProvider.notifier).updateAdvanced(voiceSpeechRate: v);
                      },
                    ),
                  ),
                  Text('${_speechRate.toStringAsFixed(1)}x', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      NimoSoundFx.click();
                      setState(() => _isMuted = !_isMuted);
                      if (_isMuted) ref.read(nativeBridgeProvider).cancelListening();
                    },
                    icon: Icon(_isMuted ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill),
                  ),
                  IconButton.filledTonal(
                    onPressed: _interruptEverything,
                    icon: const Icon(CupertinoIcons.stop_fill),
                  ),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: _isListening
                            ? TalkoraColors.iosRed
                            : (_isSpeaking ? TalkoraColors.iosOrange : theme.colorScheme.primary),
                      ),
                      onPressed: _toggleLiveMic,
                      child: Icon(
                        _isListening
                            ? CupertinoIcons.stop_circle
                            : (_isSpeaking ? CupertinoIcons.hand_raised_fill : CupertinoIcons.mic_fill),
                        size: 30,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: TalkoraColors.iosRed.withValues(alpha: 0.14),
                      foregroundColor: TalkoraColors.iosRed,
                    ),
                    onPressed: () {
                      _interruptEverything();
                      context.pop();
                    },
                    icon: const Icon(CupertinoIcons.phone_down_fill),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
