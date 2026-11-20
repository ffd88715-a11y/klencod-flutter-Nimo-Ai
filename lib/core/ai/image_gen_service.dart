import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class GeneratedImageItem {
  final String id;
  final String prompt;
  final String style;
  final String engine;
  final String imageUrl;
  final String? base64Bytes;
  final DateTime createdAt;

  const GeneratedImageItem({
    required this.id,
    required this.prompt,
    required this.style,
    required this.engine,
    required this.imageUrl,
    this.base64Bytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'style': style,
        'engine': engine,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeneratedImageItem.fromJson(Map<String, dynamic> json) {
    return GeneratedImageItem(
      id: (json['id'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      style: (json['style'] ?? 'Realistic').toString(),
      engine: (json['engine'] ?? 'Nimo Image Engine').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class ImageGenResult {
  final bool success;
  final GeneratedImageItem? item;
  final Uint8List? bytes;
  final String? error;

  const ImageGenResult({
    required this.success,
    this.item,
    this.bytes,
    this.error,
  });
}

/// Nimo v4.0 Key-Aware Multi-Model AI Image Generator:
/// Automatically routes to the image model matching the user's configured API Key:
/// - Google Gemini Key -> Gemini Nano Banana 2.1 (`gemini-nano-banana-2.1`) / `gemini-3.1-flash-image` / custom Gemini image model
/// - OpenAI Key -> `gpt-image-2.5-flare` / `gpt-image-2` / `dall-e-3`
/// - xAI Key -> `grok-2-image-1212`
/// - OpenRouter Key -> Image-capable OpenRouter model
/// - HuggingFace Key -> `black-forest-labs/FLUX.1-schnell`
/// - Custom API Key -> `<baseUrl>/images/generations` with configured model
/// - Zero-Key Free Fallback -> Pollinations Flux / Turbo
class ImageGenService {
  static const _kHistoryKey = 'nimo_generated_images_v4';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 85),
    ),
  );

  static const Map<String, String> styleSuffixes = {
    'realistic': 'ultra realistic 8k photography, natural cinematic lighting, sharp focus, DSLR',
    'cinematic': 'cinematic movie still, dramatic lighting, anamorphic lens, 8k',
    'anime': 'high quality Japanese anime illustration, crisp cel shading, vibrant atmosphere',
    '3d': '3D Unreal Engine 5 render, volumetric lighting, octane render, crisp details',
    'logo': 'minimalist modern vector logo design, clean geometric icon, studio background',
    'cyberpunk': 'futuristic cyberpunk art, subtle glass reflections, rainy night city, high detail',
    'digital_art': 'masterpiece digital concept art, painterly brush strokes, artstation quality',
  };

  /// Describes which provider + model will be used in `auto_key` mode.
  static String describeActiveKeyRoute(AiSettingsState? aiSettings, {bool isAr = true}) {
    if (aiSettings == null) {
      return isAr ? 'Nimo Free Flux (بدون مفتاح)' : 'Nimo Free Flux (No Key)';
    }
    final activeId = aiSettings.activeProviderId;
    final activeKey = aiSettings.credentialFor(activeId).apiKey.trim();
    final activePreset = AiProviderCatalog.byId(activeId);
    final customImgModel = aiSettings.customImageModel.trim();

    if (activeKey.isNotEmpty && activePreset.supportsImageGen) {
      final m = customImgModel.isNotEmpty ? customImgModel : activePreset.defaultImageModel;
      return '${activePreset.shortName} • $m';
    }

    // Check if user has any image-capable key saved (Gemini -> OpenAI -> xAI -> HF -> OpenRouter)
    for (final pid in ['gemini', 'openai', 'xai', 'huggingface', 'openrouter', 'custom']) {
      final k = aiSettings.credentialFor(pid).apiKey.trim();
      if (k.isNotEmpty) {
        final p = AiProviderCatalog.byId(pid);
        final m = customImgModel.isNotEmpty ? customImgModel : p.defaultImageModel;
        return '${p.shortName} • $m';
      }
    }
    return isAr ? 'Nimo Free Flux (مجاني)' : 'Nimo Free Flux (Free)';
  }

  /// Generates an AI image based on the configured key/model or explicit engine selection.
  Future<ImageGenResult> generateImage({
    required String prompt,
    required String styleKey,
    required String engine, // 'auto_key' | 'gemini_key' | 'openai_key' | 'xai_key' | 'hf_flux' | 'pollinations_flux' | 'pollinations_turbo'
    int width = 1024,
    int height = 1024,
    AiSettingsState? aiSettings,
    String? modelOverride,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return const ImageGenResult(success: false, error: 'Prompt is empty');
    }

    final styleBoost = styleSuffixes[styleKey] ?? styleSuffixes['realistic']!;
    final finalPrompt = '$cleanPrompt, $styleBoost';
    final override = (modelOverride ?? aiSettings?.customImageModel ?? '').trim();

    try {
      // 1. AUTO MODE: Strictly follows the model/provider configured in the user's API key!
      if (engine == 'auto_key' && aiSettings != null) {
        final targetProvider = _resolveProviderForAutoKey(aiSettings);
        if (targetProvider == 'gemini') {
          final cred = aiSettings.credentialFor('gemini');
          final model = override.isNotEmpty
              ? override
              : (_looksLikeGeminiImageModel(cred.model) ? cred.model : 'gemini-nano-banana-2.1');
          return await _generateGemini(
            prompt: finalPrompt,
            displayPrompt: cleanPrompt,
            styleKey: styleKey,
            apiKey: cred.apiKey.trim(),
            baseUrl: cred.baseUrl.trim(),
            model: model,
          );
        }
        if (targetProvider == 'openai') {
          final cred = aiSettings.credentialFor('openai');
          final model = override.isNotEmpty
              ? override
              : (_looksLikeOpenAiImageModel(cred.model) ? cred.model : 'gpt-image-2.5-flare');
          return await _generateOpenAiCompatible(
            prompt: finalPrompt,
            displayPrompt: cleanPrompt,
            styleKey: styleKey,
            apiKey: cred.apiKey.trim(),
            baseUrl: cred.baseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : cred.baseUrl.trim(),
            model: model,
            providerLabel: 'OpenAI',
            width: width,
            height: height,
          );
        }
        if (targetProvider == 'xai') {
          final cred = aiSettings.credentialFor('xai');
          final model = override.isNotEmpty ? override : 'grok-2-image-1212';
          return await _generateOpenAiCompatible(
            prompt: finalPrompt,
            displayPrompt: cleanPrompt,
            styleKey: styleKey,
            apiKey: cred.apiKey.trim(),
            baseUrl: cred.baseUrl.trim().isEmpty ? 'https://api.x.ai/v1' : cred.baseUrl.trim(),
            model: model,
            providerLabel: 'xAI Grok',
            width: width,
            height: height,
          );
        }
        if (targetProvider == 'huggingface') {
          final cred = aiSettings.credentialFor('huggingface');
          final model = override.isNotEmpty ? override : 'black-forest-labs/FLUX.1-schnell';
          return await _generateHuggingFace(finalPrompt, cleanPrompt, styleKey, cred.apiKey.trim(), model);
        }
        if (targetProvider == 'custom') {
          final cred = aiSettings.credentialFor('custom');
          final model = override.isNotEmpty ? override : cred.model;
          return await _generateOpenAiCompatible(
            prompt: finalPrompt,
            displayPrompt: cleanPrompt,
            styleKey: styleKey,
            apiKey: cred.apiKey.trim(),
            baseUrl: cred.baseUrl.trim(),
            model: model,
            providerLabel: 'Custom API',
            width: width,
            height: height,
          );
        }
      }

      // 2. Explicit Provider Selections
      if (engine == 'gemini_key') {
        final cred = aiSettings?.credentialFor('gemini');
        final key = cred?.apiKey.trim() ?? '';
        if (key.isEmpty) {
          return const ImageGenResult(
            success: false,
            error: 'يرجى إضافة مفتاح Google Gemini في الإعدادات لاستخدام نموذج Nano Banana 2.1.',
          );
        }
        final model = override.isNotEmpty ? override : 'gemini-nano-banana-2.1';
        return await _generateGemini(
          prompt: finalPrompt,
          displayPrompt: cleanPrompt,
          styleKey: styleKey,
          apiKey: key,
          baseUrl: cred?.baseUrl.trim() ?? 'https://generativelanguage.googleapis.com/v1beta',
          model: model,
        );
      }

      if (engine == 'openai_key' || engine == 'openai_dalle3') {
        final cred = aiSettings?.credentialFor('openai');
        final key = cred?.apiKey.trim() ?? '';
        if (key.isEmpty) {
          return const ImageGenResult(
            success: false,
            error: 'يرجى إضافة مفتاح OpenAI في الإعدادات أو اختيار الوضع التلقائي/المجاني.',
          );
        }
        final model = override.isNotEmpty ? override : 'gpt-image-2.5-flare';
        return await _generateOpenAiCompatible(
          prompt: finalPrompt,
          displayPrompt: cleanPrompt,
          styleKey: styleKey,
          apiKey: key,
          baseUrl: 'https://api.openai.com/v1',
          model: model,
          providerLabel: 'OpenAI',
          width: width,
          height: height,
        );
      }

      if (engine == 'xai_key') {
        final key = aiSettings?.credentialFor('xai').apiKey.trim() ?? '';
        if (key.isEmpty) {
          return const ImageGenResult(
            success: false,
            error: 'يرجى إضافة مفتاح xAI Grok في الإعدادات أولاً.',
          );
        }
        return await _generateOpenAiCompatible(
          prompt: finalPrompt,
          displayPrompt: cleanPrompt,
          styleKey: styleKey,
          apiKey: key,
          baseUrl: 'https://api.x.ai/v1',
          model: override.isNotEmpty ? override : 'grok-2-image-1212',
          providerLabel: 'xAI Grok',
          width: width,
          height: height,
        );
      }

      if (engine == 'hf_flux') {
        final key = aiSettings?.credentialFor('huggingface').apiKey.trim() ?? '';
        if (key.isEmpty) {
          return const ImageGenResult(
            success: false,
            error: 'يرجى إضافة مفتاح HuggingFace في الإعدادات أو اختيار الوضع المجاني.',
          );
        }
        return await _generateHuggingFace(
          finalPrompt,
          cleanPrompt,
          styleKey,
          key,
          override.isNotEmpty ? override : 'black-forest-labs/FLUX.1-schnell',
        );
      }

      // 3. Free Pollinations Fallback
      final model = engine == 'pollinations_turbo' ? 'turbo' : 'flux';
      final seed = Random().nextInt(999999);
      final encoded = Uri.encodeComponent(finalPrompt);
      final url =
          'https://image.pollinations.ai/prompt/$encoded?width=$width&height=$height&model=$model&seed=$seed&nologo=true';

      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const <int>[]);
      if (bytes.length < 500) {
        throw Exception('Image server returned an invalid image.');
      }

      final item = GeneratedImageItem(
        id: 'img_${DateTime.now().millisecondsSinceEpoch}',
        prompt: cleanPrompt,
        style: styleKey,
        engine: model == 'turbo' ? 'Nimo Free Turbo' : 'Nimo Free Flux',
        imageUrl: url,
        createdAt: DateTime.now(),
      );
      await saveToHistory(item);
      return ImageGenResult(success: true, item: item, bytes: bytes);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final detail = e.response?.data?.toString() ?? e.message ?? 'Network error';
      return ImageGenResult(
        success: false,
        error: code != null ? 'HTTP $code: $detail' : detail,
      );
    } catch (e) {
      return ImageGenResult(success: false, error: e.toString());
    }
  }

  String _resolveProviderForAutoKey(AiSettingsState ai) {
    final activeId = ai.activeProviderId;
    final activeKey = ai.credentialFor(activeId).apiKey.trim();
    if (activeKey.isNotEmpty &&
        const {'gemini', 'openai', 'xai', 'huggingface', 'custom'}.contains(activeId)) {
      return activeId;
    }
    for (final pid in ['gemini', 'openai', 'xai', 'huggingface', 'custom']) {
      if (ai.credentialFor(pid).apiKey.trim().isNotEmpty) return pid;
    }
    return 'pollinations';
  }

  bool _looksLikeGeminiImageModel(String m) {
    final l = m.toLowerCase();
    return l.contains('image') || l.contains('banana') || l.contains('imagen');
  }

  bool _looksLikeOpenAiImageModel(String m) {
    final l = m.toLowerCase();
    return l.contains('image') || l.contains('dall-e');
  }

  /// Google Gemini Native Image Generation (Nano Banana 2.1 / Gemini 3.1 Flash Image / 2.5 Flash Image).
  Future<ImageGenResult> _generateGemini({
    required String prompt,
    required String displayPrompt,
    required String styleKey,
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    final cleanBase = (baseUrl.isEmpty ? 'https://generativelanguage.googleapis.com/v1beta' : baseUrl)
        .replaceAll(RegExp(r"""/+$"""), '');
    final modelsToTry = <String>[
      model,
      if (model != 'gemini-nano-banana-2.1') 'gemini-nano-banana-2.1',
      if (model != 'gemini-2.5-flash-image') 'gemini-2.5-flash-image',
    ];

    Object? lastErr;
    for (final m in modelsToTry) {
      try {
        final cleanModel = m.startsWith('models/') ? m.substring(7) : m;
        final res = await _dio.post<Map<String, dynamic>>(
          '$cleanBase/models/$cleanModel:generateContent',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
          ),
          data: {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt}
                ],
              }
            ],
            'generationConfig': {
              'responseModalities': ['TEXT', 'IMAGE'],
            },
          },
        );
        final candidates = res.data?['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = ((candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?)?['parts'] as List<dynamic>?;
          if (parts != null) {
            for (final p in parts) {
              if (p is Map<String, dynamic>) {
                final inlineData = (p['inlineData'] ?? p['inline_data']) as Map<String, dynamic>?;
                final b64 = inlineData?['data']?.toString() ?? '';
                if (b64.isNotEmpty) {
                  final bytes = base64Decode(b64);
                  final item = GeneratedImageItem(
                    id: 'gem_${DateTime.now().millisecondsSinceEpoch}',
                    prompt: displayPrompt,
                    style: styleKey,
                    engine: 'Gemini • $cleanModel',
                    imageUrl: '',
                    base64Bytes: b64,
                    createdAt: DateTime.now(),
                  );
                  await saveToHistory(item);
                  return ImageGenResult(success: true, item: item, bytes: bytes);
                }
              }
            }
          }
        }
      } catch (e) {
        lastErr = e;
      }
    }
    throw Exception('Gemini Image Generation failed: $lastErr');
  }

  /// OpenAI / xAI / Custom OpenAI-Compatible `/images/generations` supporting both `b64_json` and `url`.
  Future<ImageGenResult> _generateOpenAiCompatible({
    required String prompt,
    required String displayPrompt,
    required String styleKey,
    required String apiKey,
    required String baseUrl,
    required String model,
    required String providerLabel,
    required int width,
    required int height,
  }) async {
    final cleanBase = baseUrl.replaceAll(RegExp(r"""/+$"""), '');
    final endpoint = cleanBase.endsWith('/images/generations')
        ? cleanBase
        : '$cleanBase/images/generations';

    final sizeStr = width > height
        ? '1536x1024'
        : (height > width ? '1024x1536' : '1024x1024');

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': model,
        'prompt': prompt,
        'n': 1,
        if (providerLabel == 'OpenAI') 'size': sizeStr,
      },
    );

    final dataList = res.data?['data'] as List<dynamic>?;
    final first = dataList?.first as Map<String, dynamic>?;
    final b64 = first?['b64_json']?.toString() ?? '';
    final url = first?['url']?.toString() ?? '';

    Uint8List bytes;
    if (b64.isNotEmpty) {
      bytes = base64Decode(b64);
    } else if (url.isNotEmpty) {
      final imgRes = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
      bytes = Uint8List.fromList(imgRes.data ?? const <int>[]);
    } else {
      throw Exception('No image returned by $providerLabel ($model)');
    }

    final item = GeneratedImageItem(
      id: 'oai_${DateTime.now().millisecondsSinceEpoch}',
      prompt: displayPrompt,
      style: styleKey,
      engine: '$providerLabel • $model',
      imageUrl: url,
      base64Bytes: b64.isNotEmpty ? b64 : null,
      createdAt: DateTime.now(),
    );
    await saveToHistory(item);
    return ImageGenResult(success: true, item: item, bytes: bytes);
  }

  Future<ImageGenResult> _generateHuggingFace(
    String prompt,
    String displayPrompt,
    String styleKey,
    String token,
    String model,
  ) async {
    final res = await _dio.post<List<int>>(
      'https://api-inference.huggingface.co/models/$model',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
      data: {'inputs': prompt},
    );
    final bytes = Uint8List.fromList(res.data ?? const <int>[]);
    if (bytes.length < 500) throw Exception('HuggingFace returned invalid image data.');

    final item = GeneratedImageItem(
      id: 'hf_${DateTime.now().millisecondsSinceEpoch}',
      prompt: displayPrompt,
      style: styleKey,
      engine: 'HuggingFace • $model',
      imageUrl: '',
      base64Bytes: base64Encode(bytes),
      createdAt: DateTime.now(),
    );
    await saveToHistory(item);
    return ImageGenResult(success: true, item: item, bytes: bytes);
  }

  Future<List<GeneratedImageItem>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHistoryKey);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(GeneratedImageItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveToHistory(GeneratedImageItem item) async {
    try {
      final existing = await loadHistory();
      final updated = [item, ...existing];
      final trimmed = updated.length > 24 ? updated.sublist(0, 24) : updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHistoryKey, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kHistoryKey);
    } catch (_) {}
  }
}

final imageGenServiceProvider = Provider<ImageGenService>((ref) => ImageGenService());
