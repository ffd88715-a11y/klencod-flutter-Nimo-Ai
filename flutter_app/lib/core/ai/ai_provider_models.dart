import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';

/// Wire protocol family used to communicate with any AI provider.
enum AiWireFormat {
  openAiCompatible,
  googleGemini,
  anthropicClaude,
  pollinationsFree,
}

/// Built-in + Free Instant Cloud + Custom AI provider catalog (Updated Nov 2026).
enum AiProviderType {
  pollinations,
  gemini,
  openai,
  claude,
  deepseek,
  xai,
  groq,
  openrouter,
  mistral,
  huggingface,
  ollama,
  custom,
}

class AiProviderPreset {
  final AiProviderType type;
  final String id;
  final String name;
  final String shortName;
  final String descriptionEn;
  final String descriptionAr;
  final String defaultBaseUrl;
  final String defaultModel;
  final String defaultImageModel;
  final List<String> suggestedModels;
  final AiWireFormat wireFormat;
  final bool requiresApiKey;
  final bool hasFreeTier;
  final bool supportsImageGen;
  final String apiKeyPlaceholder;
  final String keyConsoleUrl;
  final List<String> keyGuideAr;
  final List<String> keyGuideEn;
  final Color badgeColor;
  final IconData icon;

  const AiProviderPreset({
    required this.type,
    required this.id,
    required this.name,
    required this.shortName,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.defaultBaseUrl,
    required this.defaultModel,
    this.defaultImageModel = '',
    required this.suggestedModels,
    required this.wireFormat,
    this.requiresApiKey = true,
    this.hasFreeTier = false,
    this.supportsImageGen = false,
    required this.apiKeyPlaceholder,
    required this.keyConsoleUrl,
    required this.keyGuideAr,
    required this.keyGuideEn,
    required this.badgeColor,
    required this.icon,
  });
}

class AiProviderCatalog {
  const AiProviderCatalog._();

  static const List<AiProviderPreset> all = [
    AiProviderPreset(
      type: AiProviderType.pollinations,
      id: 'pollinations',
      name: 'Nimo Free Cloud AI',
      shortName: 'Nimo Free',
      descriptionEn: 'Instant free AI cloud — works immediately with ZERO API key!',
      descriptionAr: 'ذكاء Nimo السحابي المجاني يعمل فوراً بدون الحاجة لأي مفتاح API!',
      defaultBaseUrl: 'https://text.pollinations.ai/openai',
      defaultModel: 'openai',
      defaultImageModel: 'flux',
      suggestedModels: ['openai', 'deepseek', 'mistral', 'searchgpt', 'qwen-coder'],
      wireFormat: AiWireFormat.pollinationsFree,
      requiresApiKey: false,
      hasFreeTier: true,
      supportsImageGen: true,
      apiKeyPlaceholder: 'لا يحتاج مفتاح — يعمل مجاناً فوراً',
      keyConsoleUrl: 'https://pollinations.ai',
      keyGuideAr: [
        'هذا المحرك مجاني 100% ولا يحتاج أي مفتاح API أو تسجيل حساب.',
        'يعمل فوراً في الشات والمحادثة الصوتية اللايف وتوليد الصور ومختبر البرمجة.',
        'للحصول على ذكاء 2026 الخارق (Gemini 3.8 / GPT-6.2 / Claude Fable 5.2) أضف مفتاحك من الأعلى.',
      ],
      keyGuideEn: [
        '100% free cloud engine — no API key or sign-up required.',
        'Works immediately for Live Voice, AI Chat, Coding Lab, and automatic fallback.',
        'Add a Gemini, OpenAI, Claude, or Groq key above for flagship 2026 models.',
      ],
      badgeColor: TalkoraColors.iosTeal,
      icon: CupertinoIcons.sparkles,
    ),
    AiProviderPreset(
      type: AiProviderType.gemini,
      id: 'gemini',
      name: 'Google Gemini (2026)',
      shortName: 'Gemini',
      descriptionEn: 'Gemini 3.8 Flash, 3.6 Flash, 3.1 Pro, 4 Argon & Nano Banana 2.1 Images',
      descriptionAr: 'أحدث نماذج جوجل 2026: Gemini 3.8 Flash و 4 Argon + توليد صور Nano Banana 2.1',
      defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      defaultModel: 'gemini-3.8-flash',
      defaultImageModel: 'gemini-nano-banana-2.1',
      suggestedModels: [
        'gemini-3.8-flash',
        'gemini-3.7-flash',
        'gemini-3.6-flash',
        'gemini-3.5-flash-lite',
        'gemini-3.1-pro-preview',
        'gemini-4-argon',
        'gemini-2.5-pro',
        'gemini-2.5-flash',
      ],
      wireFormat: AiWireFormat.googleGemini,
      hasFreeTier: true,
      supportsImageGen: true,
      apiKeyPlaceholder: 'AIzaSy...',
      keyConsoleUrl: 'https://aistudio.google.com/apikey',
      keyGuideAr: [
        'اضغط على "افتح صفحة المفتاح" لفتح Google AI Studio.',
        'سجّل الدخول بحساب Google ثم اضغط Create API key.',
        'انسخ المفتاح (AIzaSy...) والصقه هنا — يدعم الشات والبرمجة وتوليد الصور بـ Nano Banana 2.1!',
      ],
      keyGuideEn: [
        'Tap "Open Key Console" to visit Google AI Studio.',
        'Sign in with Google, click Create API key, and paste AIzaSy... here.',
        'Automatically powers Chat, Coding Lab, and Nano Banana 2.1 Image Generation!',
      ],
      badgeColor: TalkoraColors.iosBlue,
      icon: CupertinoIcons.wand_stars,
    ),
    AiProviderPreset(
      type: AiProviderType.openai,
      id: 'openai',
      name: 'OpenAI (GPT-6.2)',
      shortName: 'OpenAI',
      descriptionEn: 'GPT-6.2 Astra, GPT-6.2 Sol, GPT-6 Luna, GPT-Image-2.5 & Human HD Voice',
      descriptionAr: 'أحدث نماذج OpenAI 2026: GPT-6.2 Astra و Sol و Luna + صور GPT-Image-2.5 وصوت بشري HD',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-6.2-sol',
      defaultImageModel: 'gpt-image-2.5-flare',
      suggestedModels: [
        'gpt-6.2-astra',
        'gpt-6.2-sol',
        'gpt-6-luna',
        'gpt-5-mini',
        'gpt-4o',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      supportsImageGen: true,
      apiKeyPlaceholder: 'sk-proj-...',
      keyConsoleUrl: 'https://platform.openai.com/api-keys',
      keyGuideAr: [
        'افتح platform.openai.com/api-keys وسجّل الدخول.',
        'اضغط "+ Create new secret key" وانسخ المفتاح (sk-proj-...).',
        'الصقه هنا لتفعيل GPT-6.2 وتوليد صور GPT-Image-2.5 والصوت البشري الحقيقي تلقائياً!',
      ],
      keyGuideEn: [
        'Open platform.openai.com/api-keys and create a new secret key.',
        'Paste sk-proj-... here to unlock GPT-6.2, GPT-Image-2.5, and Realistic Human TTS!',
      ],
      badgeColor: TalkoraColors.iosGreen,
      icon: CupertinoIcons.cube_box_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.claude,
      id: 'claude',
      name: 'Anthropic Claude 5',
      shortName: 'Claude',
      descriptionEn: 'Claude Fable 5.2, Mythos 5.2, Opus 5.5 & Sonnet 5.5 (Nov 2026)',
      descriptionAr: 'أقوى نماذج البرمجة والكتابة 2026: Claude Fable 5.2 و Mythos 5.2 و Opus 5.5',
      defaultBaseUrl: 'https://api.anthropic.com/v1',
      defaultModel: 'claude-fable-5-2',
      suggestedModels: [
        'claude-fable-5-2',
        'claude-mythos-5-2',
        'claude-opus-5-5',
        'claude-sonnet-5-5',
      ],
      wireFormat: AiWireFormat.anthropicClaude,
      hasFreeTier: false,
      supportsImageGen: false,
      apiKeyPlaceholder: 'sk-ant-api03-...',
      keyConsoleUrl: 'https://console.anthropic.com/settings/keys',
      keyGuideAr: [
        'افتح console.anthropic.com/settings/keys وسجّل الدخول.',
        'اضغط "+ Create Key" وانسخ المفتاح (sk-ant-...) والصقه هنا.',
      ],
      keyGuideEn: [
        'Open console.anthropic.com/settings/keys and copy your sk-ant-... key.',
      ],
      badgeColor: TalkoraColors.iosOrange,
      icon: CupertinoIcons.chat_bubble_2_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.deepseek,
      id: 'deepseek',
      name: 'DeepSeek V4 (2026)',
      shortName: 'DeepSeek',
      descriptionEn: 'DeepSeek V4 Pro, V4.1 Flash & Thinking Mode (Ultra Affordable)',
      descriptionAr: 'أحدث نماذج DeepSeek V4 Pro و V4.1 Flash بالتفكير العميق بتكلفة رمزية',
      defaultBaseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-v4-flash',
      suggestedModels: ['deepseek-v4-pro', 'deepseek-v4-flash', 'deepseek-flash'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      supportsImageGen: false,
      apiKeyPlaceholder: 'sk-...',
      keyConsoleUrl: 'https://platform.deepseek.com/api_keys',
      keyGuideAr: [
        'افتح platform.deepseek.com/api_keys وأنشئ مفتاحاً جديداً.',
        'اختر deepseek-v4-pro للبرمجة العميقة أو deepseek-v4-flash للسرعة الفائقة.',
      ],
      keyGuideEn: [
        'Visit platform.deepseek.com/api_keys and copy your sk-... key.',
      ],
      badgeColor: TalkoraColors.iosIndigo,
      icon: CupertinoIcons.compass_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.xai,
      id: 'xai',
      name: 'xAI Grok 4.7',
      shortName: 'Grok',
      descriptionEn: 'Grok 4.7 Flagship, Grok 4.6, 4.5, 4.1 Fast & Grok Image',
      descriptionAr: 'أحدث نماذج Grok 4.7 و 4.6 بسياق 500K + توليد صور Grok',
      defaultBaseUrl: 'https://api.x.ai/v1',
      defaultModel: 'grok-4.7',
      defaultImageModel: 'grok-2-image-1212',
      suggestedModels: ['grok-4.7', 'grok-4.6', 'grok-4.5', 'grok-4.1-fast'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      supportsImageGen: true,
      apiKeyPlaceholder: 'xai-...',
      keyConsoleUrl: 'https://console.x.ai',
      keyGuideAr: [
        'افتح console.x.ai واختر API Keys ثم Create API Key.',
        'انسخ المفتاح (xai-...) والصقه هنا — يدعم أيضاً توليد الصور!',
      ],
      keyGuideEn: [
        'Visit console.x.ai -> API Keys -> Create API Key and paste xai-... here.',
      ],
      badgeColor: Color(0xFF48484A),
      icon: CupertinoIcons.flame_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.groq,
      id: 'groq',
      name: 'Groq (Ultra-Fast)',
      shortName: 'Groq',
      descriptionEn: 'Llama 4 Maverick, Qwen3 32B & Llama 3.3 70B — ultra-fast for Live Voice',
      descriptionAr: 'أسرع محرك عالمياً للصوت اللايف: Llama 4 Maverick و Qwen3 32B مجاناً!',
      defaultBaseUrl: 'https://api.groq.com/openai/v1',
      defaultModel: 'meta-llama/llama-4-maverick-17b-128e-instruct',
      suggestedModels: [
        'meta-llama/llama-4-maverick-17b-128e-instruct',
        'llama-3.3-70b-versatile',
        'qwen/qwen3-32b',
        'llama-3.1-8b-instant',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      supportsImageGen: false,
      apiKeyPlaceholder: 'gsk_...',
      keyConsoleUrl: 'https://console.groq.com/keys',
      keyGuideAr: [
        'افتح console.groq.com/keys وأنشئ مفتاحاً باسم Nimo.',
        'انسخ المفتاح (gsk_...) والصقه هنا للردود الصوتية الفورية المجانية!',
      ],
      keyGuideEn: [
        'Open console.groq.com/keys, create a key named Nimo, and paste gsk_... here.',
      ],
      badgeColor: TalkoraColors.iosPink,
      icon: CupertinoIcons.bolt_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.openrouter,
      id: 'openrouter',
      name: 'OpenRouter (300+ Models)',
      shortName: 'OpenRouter',
      descriptionEn: 'One key for DeepSeek V4.1, Gemini 3.8, GPT-6.2, Claude 5.2 & Image models',
      descriptionAr: 'مفتاح واحد لأكثر من 300 نموذج مجاني ومدفوع (DeepSeek V4.1, GPT-6.2, Claude 5.2)',
      defaultBaseUrl: 'https://openrouter.ai/api/v1',
      defaultModel: 'deepseek/deepseek-v4.1-flash:free',
      defaultImageModel: 'google/gemini-2.5-flash-image-preview',
      suggestedModels: [
        'deepseek/deepseek-v4.1-flash:free',
        'meta-llama/llama-4-maverick:free',
        'google/gemini-3.6-flash',
        'openai/gpt-6.2-sol',
        'anthropic/claude-fable-5-2',
        'x-ai/grok-4.7',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      supportsImageGen: true,
      apiKeyPlaceholder: 'sk-or-v1-...',
      keyConsoleUrl: 'https://openrouter.ai/keys',
      keyGuideAr: [
        'افتح openrouter.ai/keys وأنشئ مفتاحاً جديداً.',
        'انسخ المفتاح (sk-or-v1-...) واختر أي نموذج :free مجاني أو رائد!',
      ],
      keyGuideEn: [
        'Visit openrouter.ai/keys, copy sk-or-v1-... and pick any :free or flagship model.',
      ],
      badgeColor: TalkoraColors.iosPurple,
      icon: CupertinoIcons.globe,
    ),
    AiProviderPreset(
      type: AiProviderType.mistral,
      id: 'mistral',
      name: 'Mistral AI (v4)',
      shortName: 'Mistral',
      descriptionEn: 'Mistral Large 4, Mistral Small 4 & Codestral (Free tier!)',
      descriptionAr: 'أحدث نماذج Mistral Large 4 و Small 4 و Codestral للبرمجة',
      defaultBaseUrl: 'https://api.mistral.ai/v1',
      defaultModel: 'mistral-small-4',
      suggestedModels: ['mistral-large-4', 'mistral-small-4', 'codestral-latest'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      supportsImageGen: false,
      apiKeyPlaceholder: 'mistral-...',
      keyConsoleUrl: 'https://console.mistral.ai/api-keys',
      keyGuideAr: [
        'افتح console.mistral.ai/api-keys وفعّل الخطة المجانية ثم انسخ المفتاح.',
      ],
      keyGuideEn: [
        'Open console.mistral.ai/api-keys, enable the free tier, and copy your key.',
      ],
      badgeColor: TalkoraColors.iosTeal,
      icon: CupertinoIcons.wind,
    ),
    AiProviderPreset(
      type: AiProviderType.huggingface,
      id: 'huggingface',
      name: 'HuggingFace Hub',
      shortName: 'HuggingFace',
      descriptionEn: 'Qwen3 235B, Gemma 4 31B, DeepSeek V4 + FLUX.1 Image Generation',
      descriptionAr: 'نماذج Qwen3 و Gemma 4 المفتوحة + توليد صور FLUX.1 مجاناً',
      defaultBaseUrl: 'https://router.huggingface.co/v1',
      defaultModel: 'Qwen/Qwen3-235B-A22B-Instruct',
      defaultImageModel: 'black-forest-labs/FLUX.1-schnell',
      suggestedModels: [
        'Qwen/Qwen3-235B-A22B-Instruct',
        'google/gemma-4-31b-it',
        'meta-llama/Llama-4-Maverick-17B-128E-Instruct',
        'deepseek-ai/DeepSeek-V4',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      supportsImageGen: true,
      apiKeyPlaceholder: 'hf_...',
      keyConsoleUrl: 'https://huggingface.co/settings/tokens',
      keyGuideAr: [
        'افتح huggingface.co/settings/tokens وأنشئ Token بصلاحية Inference Providers.',
        'يدعم المحادثة والبرمجة وتوليد صور FLUX.1 مباشرة!',
      ],
      keyGuideEn: [
        'Visit huggingface.co/settings/tokens, create an Inference token (hf_...), and paste here.',
      ],
      badgeColor: TalkoraColors.iosOrange,
      icon: CupertinoIcons.smiley_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.ollama,
      id: 'ollama',
      name: 'Ollama / LM Studio',
      shortName: 'Local AI',
      descriptionEn: 'Run Gemma 4, Llama 4 & Qwen3 locally on your PC / LAN',
      descriptionAr: 'تشغيل Gemma 4 و Llama 4 و Qwen3 محلياً على جهازك بدون مفاتيح',
      defaultBaseUrl: 'http://10.0.2.2:11434/v1',
      defaultModel: 'gemma4:12b',
      suggestedModels: ['gemma4:12b', 'llama4', 'qwen3:14b', 'deepseek-r1:14b'],
      wireFormat: AiWireFormat.openAiCompatible,
      requiresApiKey: false,
      hasFreeTier: true,
      supportsImageGen: false,
      apiKeyPlaceholder: 'Optional local key',
      keyConsoleUrl: 'https://ollama.com',
      keyGuideAr: [
        'ثبّت Ollama على جهازك وشغّل: ollama run gemma4:12b ثم ضع عنوان IP الشبكة المحلية.',
      ],
      keyGuideEn: [
        'Install Ollama on your PC, run `ollama run gemma4:12b`, and set your LAN Base URL.',
      ],
      badgeColor: Color(0xFF636366),
      icon: CupertinoIcons.desktopcomputer,
    ),
    AiProviderPreset(
      type: AiProviderType.custom,
      id: 'custom',
      name: 'Custom Any AI API',
      shortName: 'Custom API',
      descriptionEn: 'Connect ANY OpenAI-compatible URL, chat/image model ID & API key',
      descriptionAr: 'ربط أي رابط API مخصص وأي اسم نموذج نصي أو صور وأي مفتاح بحرية كاملة',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'custom-model',
      defaultImageModel: 'gpt-image-2.5-flare',
      suggestedModels: ['gpt-6.2-sol', 'gemini-3.8-flash', 'deepseek-v4-flash', 'claude-fable-5-2'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      supportsImageGen: true,
      apiKeyPlaceholder: 'Enter any API key...',
      keyConsoleUrl: 'https://openrouter.ai',
      keyGuideAr: [
        'أدخل Base URL واسم النموذج والمفتاح — ويعمل تلقائياً في الشات والبرمجة واستوديو الصور!',
      ],
      keyGuideEn: [
        'Enter any OpenAI-compatible Base URL, Model ID, and API Key for chat & image generation.',
      ],
      badgeColor: TalkoraColors.iosRed,
      icon: CupertinoIcons.slider_horizontal_3,
    ),
  ];

  static AiProviderPreset byId(String id) {
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => all.first,
    );
  }
}

/// Stored configuration for a single provider.
class ProviderCredential {
  final String apiKey;
  final String model;
  final String baseUrl;

  const ProviderCredential({
    this.apiKey = '',
    this.model = '',
    this.baseUrl = '',
  });

  ProviderCredential copyWith({
    String? apiKey,
    String? model,
    String? baseUrl,
  }) {
    return ProviderCredential(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'model': model,
        'baseUrl': baseUrl,
      };

  factory ProviderCredential.fromJson(Map<String, dynamic> json) {
    return ProviderCredential(
      apiKey: (json['apiKey'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      baseUrl: (json['baseUrl'] as String?) ?? '',
    );
  }
}

/// Chat message model used across Nimo AI Chat Studio, Live Voice & Roleplay Arena.
class AiChatMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;
  final String? modelUsed;
  final String? imageUrl;
  final String? actionBadge;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.modelUsed,
    this.imageUrl,
    this.actionBadge,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'modelUsed': modelUsed,
        'imageUrl': imageUrl,
        'actionBadge': actionBadge,
      };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      role: (json['role'] as String?) ?? 'assistant',
      content: (json['content'] as String?) ?? '',
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ?? DateTime.now(),
      modelUsed: json['modelUsed'] as String?,
      imageUrl: json['imageUrl'] as String?,
      actionBadge: json['actionBadge'] as String?,
    );
  }
}

/// Result of an AI request or connection test.
class AiResponseResult {
  final bool success;
  final String text;
  final String? error;
  final int latencyMs;
  final String providerName;
  final String modelName;
  final bool usedFallback;

  const AiResponseResult({
    required this.success,
    required this.text,
    this.error,
    required this.latencyMs,
    required this.providerName,
    required this.modelName,
    this.usedFallback = false,
  });
}
