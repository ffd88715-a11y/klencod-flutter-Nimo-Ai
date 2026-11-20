import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/ai/ai_tool_executor.dart';
import 'package:talkora_ai/core/audio/voice_socket_service.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/permissions/mic_permission_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

/// LISORA AI v3.0 — Real-Time Live Voice Conversation Engine.
/// Powered by Native Android SpeechRecognizer + TextToSpeech + Universal Smart AI +
/// GitHub RAG + Phone Control + Hands-Free Continuous Loop + Instant Barge-In.
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
          setState(() {
            _livePartialTranscript = event.text;
          });
          break;
        case 'speech_end':
          setState(() {
            _engineState = VoiceEngineState.understanding;
          });
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
          // Error 6 (speech timeout) or 7 (no match): seamlessly restart in auto-loop mode
          if ((event.code == 6 || event.code == 7) && _sessionActive && _autoLoop && !_isMuted && !_isThinking && !_isSpeaking) {
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
      if (mounted && _sessionActive && _autoLoop && !_isMuted && !_isThinking && !_isSpeaking && !_isListening) {
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
                  ? 'يرجى السماح بصلاحية الميكروفون لتشغيل المحادثة الصوتية اللايف.'
                  : 'Microphone permission is required for Live Voice.',
            ),
          ),
        );
      }
      return;
    }

    final bridge = ref.read(nativeBridgeProvider);
    await bridge.stopSpeaking();

    setState(() {
      _sessionActive = true;
      _isMuted = false;
      _isSpeaking = false;
      _isListening = true;
      _livePartialTranscript = '';
      _statusNote = '';
      _engineState = VoiceEngineState.listening;
    });

    final ok = await bridge.startListening(locale: _voiceLocale);
    if (!ok && mounted) {
      setState(() {
        _isListening = false;
        _statusNote = 'تأكد من تفعيل خدمة Google Speech Services على الهاتف.';
      });
    }
  }

  Future<void> _toggleLiveMic() async {
    final bridge = ref.read(nativeBridgeProvider);

    // If AI is currently speaking -> Instant Barge-In interruption & start listening immediately!
    if (_isSpeaking) {
      await bridge.stopSpeaking();
      await _startListeningNow();
      return;
    }

    // If currently listening -> stop listening and finalize
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

    // Otherwise start live listening
    await _startListeningNow();
  }

  Future<void> _interruptEverything() async {
    _autoRestartTimer?.cancel();
    final bridge = ref.read(nativeBridgeProvider);
    await bridge.stopSpeaking();
    await bridge.cancelListening();
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

    // 1. Instant local phone command execution (zero latency!)
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
              modelUsed: 'LISORA Phone Engine',
            ),
          );
        });
        _scrollToBottom();
        await _speakReply(instant.cleanReply);
        return;
      }
    }

    // 2. Build GitHub RAG context + Voice-optimized System Prompt
    final ragContext = ref.read(githubKnowledgeProvider.notifier).buildRagContext(spokenText);
    final voiceSystemPrompt = StringBuffer()
      ..writeln(
        isAr
            ? 'أنت LISORA AI في وضع المحادثة الصوتية المباشرة اللايف. تحدث بشكل طبيعي وودود ومختصر (2 إلى 4 جمل واضحة بدون رموز ماركداون معقدة) لتكون مناسبة للنطق الصوتي الفوري. أجب بنفس لغة المستخدم.'
            : 'You are LISORA AI in Real-Time Live Voice mode. Reply naturally, warmly, and concisely (2-4 clear sentences without heavy markdown) optimized for spoken conversation.',
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
      ragContext: ragContext,
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
      replyText = isAr
          ? 'حدثت مشكلة مؤقتة في الاتصال بالذكاء الاصطناعي. تأكد من الإنترنت أو راجع مفاتيح API في الإعدادات.'
          : 'Temporary connection issue. Check your internet or AI API keys in Settings.';
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
    await _speakReply(replyText);
  }

  Future<void> _speakReply(String text) async {
    final bridge = ref.read(nativeBridgeProvider);
    final ttsLocale = NativeBridgeService.containsArabic(text)
        ? (_voiceLocale.startsWith('ar') ? _voiceLocale : 'ar-EG')
        : (_voiceLocale.startsWith('en') ? _voiceLocale : 'en-US');
    setState(() {
      _isSpeaking = true;
      _engineState = VoiceEngineState.speaking;
    });
    await bridge.speak(text, locale: ttsLocale, rate: _speechRate);
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
    final ctrl = TextEditingController();
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'اكتب للمساعد الصوتي' : 'Type to Voice AI'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isAr ? 'مثال: افتح واتساب أو اشرح لي الذكاء الاصطناعي...' : 'Ask anything or give a phone command...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          FilledButton(
            onPressed: () {
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

  String _stateHeadline(bool isAr) {
    if (_isListening) return isAr ? 'أستمع إليك الآن... تحدث بحرية' : 'Listening... Speak naturally';
    if (_isThinking) return isAr ? 'جاري التفكير والبحث في قواعد البيانات...' : 'Thinking & querying knowledge...';
    if (_isSpeaking) return isAr ? 'LISORA AI يتحدث الآن (اضغط للمقاطعة)' : 'LISORA AI Speaking (Tap to interrupt)';
    return isAr ? 'اضغط على الميكروفون لبدء المحادثة اللايف' : 'Tap microphone to start Live Voice';
  }

  @override
  void dispose() {
    _autoRestartTimer?.cancel();
    _voiceSub?.cancel();
    _transcriptScrollCtrl.dispose();
    final bridge = ref.read(nativeBridgeProvider);
    bridge.cancelListening();
    bridge.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiSettingsProvider);
    final gh = ref.watch(githubKnowledgeProvider);
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(isAr ? 'المحادثة الصوتية اللايف' : 'Live Voice AI', style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            IosStatusPill(
              label: '${ai.activePreset.shortName} • ${_localeLabels[_voiceLocale] ?? _voiceLocale}',
              color: _isListening
                  ? TalkoraColors.iosGreen
                  : (_isSpeaking ? TalkoraColors.iosBlue : TalkoraColors.iosIndigo),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'إرسال نص سريع' : 'Quick Type',
            icon: const Icon(CupertinoIcons.keyboard, size: 21),
            onPressed: _openQuickTypeDialog,
          ),
          IconButton(
            tooltip: isAr ? 'إعدادات النماذج' : 'AI Settings',
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 21),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(
            children: [
              // Voice Language & Auto-Loop Controls Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._localeLabels.entries.map((entry) {
                      final selected = _voiceLocale == entry.key;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) {
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
                      label: Text(isAr ? 'استماع تلقائي مستمر' : 'Hands-Free Loop',
                          style: const TextStyle(fontSize: 12)),
                      selected: _autoLoop,
                      onSelected: (v) {
                        setState(() => _autoLoop = v);
                        ref.read(aiSettingsProvider.notifier).updateAdvanced(voiceAutoLoopEnabled: v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Interactive Live Voice Orb (Tap to talk / Tap to interrupt)
              GestureDetector(
                onTap: _toggleLiveMic,
                child: TalkoraVoiceOrb(
                  state: _engineState,
                  audioLevel: _isSpeaking ? 0.45 : _currentLevel,
                  size: 148,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _stateHeadline(isAr),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (gh.totalEntries > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isAr
                        ? 'مرتبط بـ ${gh.totalEntries} سجل معرفي من GitHub + تحكم كامل بالهاتف'
                        : 'Connected to ${gh.totalEntries} GitHub records + Full Phone Control',
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

              // Live Audio Waveform
              TalkoraWaveform(
                amplitudeHistory: _amplitudes,
                height: 44,
                color: _isSpeaking ? TalkoraColors.iosGreen : theme.colorScheme.primary,
              ),

              // Live Partial Speech Preview Banner
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

              // Live Conversation Transcript Feed
              Expanded(
                child: _turns.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isAr
                                    ? 'جرّب قول: "افتح واتساب" أو "شغل الكشاف" أو "ابحث في يوتيوب عن فلاتر" أو اسأل أي سؤال علمي أو برمجي!'
                                    : 'Try saying: "Open WhatsApp", "Turn on flashlight", "Search YouTube for Flutter", or ask any question!',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
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
                                maxWidth: MediaQuery.of(context).size.width * 0.82,
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
                                  Text(
                                    msg.content,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: isUser ? Colors.white : null,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        msg.imageUrl!,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
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

              const SizedBox(height: 10),
              // Speech Speed Compact Slider
              Row(
                children: [
                  Icon(CupertinoIcons.speedometer, size: 17, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(isAr ? 'سرعة الصوت' : 'Speed', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: CupertinoSlider(
                      value: _speechRate.clamp(0.6, 1.6),
                      min: 0.6,
                      max: 1.6,
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

              // Bottom Voice Controls Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                      if (_isMuted) {
                        ref.read(nativeBridgeProvider).cancelListening();
                      }
                    },
                    icon: Icon(_isMuted ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill),
                    tooltip: _isMuted ? (isAr ? 'إلغاء الكتم' : 'Unmute') : (isAr ? 'كتم' : 'Mute'),
                  ),
                  IconButton.filledTonal(
                    onPressed: _interruptEverything,
                    icon: const Icon(CupertinoIcons.stop_fill),
                    tooltip: isAr ? 'إيقاف فوري' : 'Stop',
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
                    tooltip: isAr ? 'إنهاء المكالمة' : 'End Call',
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
