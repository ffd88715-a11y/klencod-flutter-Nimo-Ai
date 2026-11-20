import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      engine: (json['engine'] ?? 'Pollinations Flux').toString(),
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

/// Multi-Engine AI Image Generation Service:
/// 1. Pollinations.ai (Flux / Realism / Anime / 3D / Turbo) — 100% FREE, zero key needed
/// 2. OpenAI DALL-E 3 — when OpenAI API key is configured
/// 3. HuggingFace FLUX.1-schnell — when HuggingFace token is configured
class ImageGenService {
  static const _kHistoryKey = 'lisora_generated_images_v3';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 75),
    ),
  );

  static const Map<String, String> styleSuffixes = {
    'realistic': 'ultra realistic 8k photography, cinematic lighting, sharp focus, DSLR',
    'cinematic': 'cinematic movie still, dramatic lighting, anamorphic lens, 8k',
    'anime': 'high quality Japanese anime illustration, vibrant colors, Studio Ghibli style',
    '3d': '3D Pixar Unreal Engine 5 render, volumetric lighting, octane render, crisp details',
    'logo': 'minimalist modern vector logo design, clean geometric icon, flat studio background',
    'cyberpunk': 'futuristic cyberpunk art, neon reflections, rainy night city, high detail',
    'digital_art': 'masterpiece digital concept art, painterly brush strokes, trending on artstation',
  };

  /// Generates an AI image using the requested engine (defaults to free Pollinations Flux).
  Future<ImageGenResult> generateImage({
    required String prompt,
    required String styleKey,
    required String engine, // 'pollinations_flux' | 'pollinations_turbo' | 'openai_dalle3' | 'hf_flux'
    int width = 1024,
    int height = 1024,
    AiSettingsState? aiSettings,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return const ImageGenResult(success: false, error: 'Prompt is empty');
    }

    final styleBoost = styleSuffixes[styleKey] ?? styleSuffixes['realistic']!;
    final finalPrompt = '$cleanPrompt, $styleBoost';

    try {
      if (engine == 'openai_dalle3') {
        final key = aiSettings?.credentialFor('openai').apiKey.trim() ?? '';
        if (key.isEmpty) {
          return const ImageGenResult(
            success: false,
            error: 'يرجى إضافة مفتاح OpenAI في الإعدادات أو اختيار محرك Pollinations المجاني.',
          );
        }
        return await _generateOpenAi(finalPrompt, styleKey, key);
      }

      if (engine == 'hf_flux') {
        final key = aiSettings?.credentialFor('huggingface').apiKey.trim() ?? '';
        if (key.isEmpty) {
          return const ImageGenResult(
            success: false,
            error: 'يرجى إضافة مفتاح HuggingFace في الإعدادات أو اختيار محرك Pollinations المجاني.',
          );
        }
        return await _generateHuggingFace(finalPrompt, styleKey, key);
      }

      // Default: Pollinations.ai FREE instant image generator
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
        engine: model == 'turbo' ? 'Pollinations Turbo (Free)' : 'Pollinations Flux (Free)',
        imageUrl: url,
        createdAt: DateTime.now(),
      );
      await saveToHistory(item);
      return ImageGenResult(success: true, item: item, bytes: bytes);
    } catch (e) {
      return ImageGenResult(success: false, error: e.toString());
    }
  }

  Future<ImageGenResult> _generateOpenAi(String prompt, String styleKey, String apiKey) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/images/generations',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': '1024x1024',
      },
    );
    final dataList = res.data?['data'] as List<dynamic>?;
    final url = (dataList?.first as Map<String, dynamic>?)?['url']?.toString() ?? '';
    if (url.isEmpty) throw Exception('No image URL returned by DALL-E 3');

    final imgRes = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final bytes = Uint8List.fromList(imgRes.data ?? const <int>[]);

    final item = GeneratedImageItem(
      id: 'dalle_${DateTime.now().millisecondsSinceEpoch}',
      prompt: prompt,
      style: styleKey,
      engine: 'OpenAI DALL-E 3',
      imageUrl: url,
      createdAt: DateTime.now(),
    );
    await saveToHistory(item);
    return ImageGenResult(success: true, item: item, bytes: bytes);
  }

  Future<ImageGenResult> _generateHuggingFace(String prompt, String styleKey, String token) async {
    final res = await _dio.post<List<int>>(
      'https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell',
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
      prompt: prompt,
      style: styleKey,
      engine: 'HuggingFace FLUX.1',
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
