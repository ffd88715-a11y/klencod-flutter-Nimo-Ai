import 'package:dio/dio.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

/// Smart Universal Multi-Provider AI Router v3.0.
/// Features:
/// - Instant Free Cloud AI (Pollinations) out-of-the-box with ZERO API key
/// - 12 Providers (Gemini, Groq, OpenRouter, OpenAI, DeepSeek, Claude, xAI, Mistral, HuggingFace, Ollama, Custom)
/// - Smart Automatic Fallback across configured keys + Free Cloud backup
/// - GitHub Knowledge RAG context injection & Deep Thinking mode
class UniversalAiService {
  final Dio _dio;

  UniversalAiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 22),
                receiveTimeout: const Duration(seconds: 65),
              ),
            );

  /// Sends a multi-turn conversation with Smart Routing & Automatic Fallback.
  Future<AiResponseResult> sendChat({
    required AiSettingsState settings,
    required List<AiChatMessage> messages,
    String? systemPromptOverride,
    String? ragContext,
    bool allowFallback = true,
  }) async {
    final baseSys = (systemPromptOverride ?? settings.customSystemPrompt).trim();
    final thinkingBoost = settings.deepThinkingEnabled
        ? '\n[DEEP THINKING MODE]: Analyze carefully step-by-step, verify logic and accuracy, and deliver a comprehensive, high-intelligence answer.'
        : '';
    final fullSystemPrompt = '$baseSys$thinkingBoost${ragContext ?? ''}'.trim();

    // 1. Try primary active provider first
    final primaryResult = await _sendToSpecificProvider(
      providerId: settings.activeProviderId,
      settings: settings,
      messages: messages,
      systemPrompt: fullSystemPrompt,
    );

    if (primaryResult.success) {
      return primaryResult;
    }

    // 2. Smart Auto-Fallback: try other configured providers, then Free Cloud AI
    if (allowFallback && settings.smartFallbackEnabled) {
      final candidateIds = <String>[];
      // First: other providers where user has saved an API key
      for (final p in AiProviderCatalog.all) {
        if (p.id == settings.activeProviderId) continue;
        if (p.id == 'pollinations' || p.id == 'ollama') continue;
        final key = settings.credentialFor(p.id).apiKey.trim();
        if (key.isNotEmpty) {
          candidateIds.add(p.id);
        }
      }
      // Finally: Free Cloud AI (Pollinations) so the user NEVER gets stuck!
      if (settings.activeProviderId != 'pollinations') {
        candidateIds.add('pollinations');
      }

      for (final fallbackId in candidateIds) {
        final fbResult = await _sendToSpecificProvider(
          providerId: fallbackId,
          settings: settings,
          messages: messages,
          systemPrompt: fullSystemPrompt,
        );
        if (fbResult.success) {
          return AiResponseResult(
            success: true,
            text: fbResult.text,
            latencyMs: fbResult.latencyMs,
            providerName: '${fbResult.providerName} (Auto)',
            modelName: fbResult.modelName,
            usedFallback: true,
          );
        }
      }
    }

    return primaryResult;
  }

  /// Tests a specific provider directly WITHOUT fallback so the user sees the real key status.
  Future<AiResponseResult> testConnection(AiSettingsState settings, {String? providerIdOverride}) {
    final targetId = providerIdOverride ?? settings.activeProviderId;
    return _sendToSpecificProvider(
      providerId: targetId,
      settings: settings,
      systemPrompt: 'Reply with only: OK - Connected!',
      messages: [
        AiChatMessage(
          role: 'user',
          content: 'Ping',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<AiResponseResult> _sendToSpecificProvider({
    required String providerId,
    required AiSettingsState settings,
    required List<AiChatMessage> messages,
    required String systemPrompt,
  }) async {
    final sw = Stopwatch()..start();
    final preset = AiProviderCatalog.byId(providerId);
    final cred = settings.credentialFor(providerId);
    final apiKey = cred.apiKey.trim();
    final model = cred.model.trim().isEmpty ? preset.defaultModel : cred.model.trim();
    final baseUrl = _normalizeBaseUrl(
      cred.baseUrl.trim().isEmpty ? preset.defaultBaseUrl : cred.baseUrl.trim(),
    );

    if (preset.requiresApiKey && apiKey.isEmpty) {
      sw.stop();
      return AiResponseResult(
        success: false,
        text: '',
        error: 'MISSING_API_KEY',
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    }

    try {
      String replyText;
      switch (preset.wireFormat) {
        case AiWireFormat.pollinationsFree:
          replyText = await _callPollinationsFree(
            baseUrl: baseUrl,
            model: model,
            systemPrompt: systemPrompt,
            messages: messages,
            temperature: settings.temperature,
          );
          break;
        case AiWireFormat.googleGemini:
          replyText = await _callGemini(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            messages: messages,
            temperature: settings.temperature,
            maxTokens: settings.maxTokens,
          );
          break;
        case AiWireFormat.anthropicClaude:
          replyText = await _callClaude(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            messages: messages,
            temperature: settings.temperature,
            maxTokens: settings.maxTokens,
          );
          break;
        case AiWireFormat.openAiCompatible:
          replyText = await _callOpenAiCompatible(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            messages: messages,
            temperature: settings.temperature,
            maxTokens: settings.maxTokens,
            isOpenRouter: preset.type == AiProviderType.openrouter,
          );
          break;
      }

      sw.stop();
      return AiResponseResult(
        success: true,
        text: replyText.trim(),
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    } on DioException catch (e) {
      sw.stop();
      final status = e.response?.statusCode;
      final serverMsg = _extractErrorMessage(e.response?.data) ?? e.message ?? 'Network error';
      return AiResponseResult(
        success: false,
        text: '',
        error: status != null ? 'HTTP $status: $serverMsg' : serverMsg,
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    } catch (e) {
      sw.stop();
      return AiResponseResult(
        success: false,
        text: '',
        error: e.toString(),
        latencyMs: sw.elapsedMilliseconds,
        providerName: preset.shortName,
        modelName: model,
      );
    }
  }

  Future<String> _callPollinationsFree({
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<AiChatMessage> messages,
    required double temperature,
  }) async {
    final payloadMessages = <Map<String, String>>[
      if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
      for (final m in messages)
        if (m.role == 'user' || m.role == 'assistant') {'role': m.role, 'content': m.content},
    ];

    try {
      final res = await _dio.post<dynamic>(
        baseUrl,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'model': model,
          'messages': payloadMessages,
          'temperature': temperature,
          'private': true,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final msg = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
          final content = msg?['content'];
          if (content is String && content.trim().isNotEmpty) return content;
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data;
      }
    } catch (_) {
      // Fallback to direct GET endpoint if POST is rate-limited
      final lastUser = messages.lastWhere(
        (m) => m.role == 'user',
        orElse: () => AiChatMessage(role: 'user', content: 'Hello', timestamp: DateTime.now()),
      );
      final encoded = Uri.encodeComponent(lastUser.content);
      final sysEnc = Uri.encodeComponent(
        systemPrompt.length > 400 ? systemPrompt.substring(0, 400) : systemPrompt,
      );
      final res = await _dio.get<String>(
        'https://text.pollinations.ai/$encoded?model=$model&system=$sysEnc',
        options: Options(responseType: ResponseType.plain),
      );
      if (res.data != null && res.data!.trim().isNotEmpty) {
        return res.data!;
      }
    }
    throw Exception('Free Cloud AI did not return a response.');
  }

  Future<String> _callOpenAiCompatible({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<AiChatMessage> messages,
    required double temperature,
    required int maxTokens,
    required bool isOpenRouter,
  }) async {
    final endpoint = baseUrl.endsWith('/chat/completions') ? baseUrl : '$baseUrl/chat/completions';
    final payloadMessages = <Map<String, String>>[
      if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
      for (final m in messages)
        if (m.role == 'user' || m.role == 'assistant') {'role': m.role, 'content': m.content},
    ];

    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      if (isOpenRouter) 'HTTP-Referer': 'https://lisora.ai',
      if (isOpenRouter) 'X-Title': 'LISORA AI v3.0',
    };

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      options: Options(headers: headers),
      data: {
        'model': model,
        'messages': payloadMessages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    );

    final data = res.data ?? <String, dynamic>{};
    final choices = data['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final msg = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = msg?['content'];
      if (content is String && content.isNotEmpty) return content;
    }
    throw Exception('Empty response from OpenAI-compatible API.');
  }

  Future<String> _callGemini({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<AiChatMessage> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final cleanModel = model.startsWith('models/') ? model.substring(7) : model;
    final endpoint = '$baseUrl/models/$cleanModel:generateContent';

    final contents = <Map<String, dynamic>>[
      for (final m in messages)
        if (m.role == 'user' || m.role == 'assistant')
          {
            'role': m.role == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': m.content}
            ],
          },
    ];

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
      if (systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ],
        },
    };

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
      ),
      data: body,
    );

    final data = res.data ?? <String, dynamic>{};
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        final buffer = StringBuffer();
        for (final p in parts) {
          final txt = (p as Map<String, dynamic>)['text'] as String?;
          if (txt != null) buffer.write(txt);
        }
        if (buffer.isNotEmpty) return buffer.toString();
      }
    }
    throw Exception('Empty response from Google Gemini API.');
  }

  Future<String> _callClaude({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<AiChatMessage> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final endpoint = baseUrl.endsWith('/messages') ? baseUrl : '$baseUrl/messages';
    final claudeMessages = <Map<String, String>>[
      for (final m in messages)
        if (m.role == 'user' || m.role == 'assistant') {'role': m.role, 'content': m.content},
    ];

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ),
      data: {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        if (systemPrompt.isNotEmpty) 'system': systemPrompt,
        'messages': claudeMessages,
      },
    );

    final data = res.data ?? <String, dynamic>{};
    final contentList = data['content'] as List<dynamic>?;
    if (contentList != null && contentList.isNotEmpty) {
      final buffer = StringBuffer();
      for (final item in contentList) {
        if (item is Map<String, dynamic> && item['type'] == 'text') {
          buffer.write(item['text'] ?? '');
        }
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }
    throw Exception('Empty response from Anthropic Claude API.');
  }

  String _normalizeBaseUrl(String raw) {
    var clean = raw.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return (err['message'] ?? err['type'] ?? err.toString()).toString();
      }
      if (err is String) return err;
      if (data['message'] is String) return data['message'] as String;
    } else if (data is String && data.isNotEmpty) {
      return data.length > 180 ? '${data.substring(0, 180)}...' : data;
    }
    return null;
  }
}
