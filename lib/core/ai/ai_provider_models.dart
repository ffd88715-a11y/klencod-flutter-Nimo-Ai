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

/// Built-in + Free Instant Cloud + Custom AI provider catalog.
enum AiProviderType {
  pollinations,
  gemini,
  groq,
  openrouter,
  openai,
  deepseek,
  claude,
  xai,
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
  final List<String> suggestedModels;
  final AiWireFormat wireFormat;
  final bool requiresApiKey;
  final bool hasFreeTier;
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
    required this.suggestedModels,
    required this.wireFormat,
    this.requiresApiKey = true,
    this.hasFreeTier = false,
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
      name: 'LISORA Free Cloud AI',
      shortName: 'Free AI',
      descriptionEn: 'Instant free AI cloud — works immediately with ZERO API key!',
      descriptionAr: 'ذكاء اصطناعي سحابي مجاني يعمل فوراً بدون الحاجة لأي مفتاح API!',
      defaultBaseUrl: 'https://text.pollinations.ai/openai',
      defaultModel: 'openai',
      suggestedModels: ['openai', 'mistral', 'searchgpt', 'deepseek'],
      wireFormat: AiWireFormat.pollinationsFree,
      requiresApiKey: false,
      hasFreeTier: true,
      apiKeyPlaceholder: 'لا يحتاج مفتاح — يعمل مجاناً فوراً',
      keyConsoleUrl: 'https://pollinations.ai',
      keyGuideAr: [
        'هذا المحرك مجاني 100% ولا يحتاج أي مفتاح API أو تسجيل حساب.',
        'يعمل فوراً في الشات والمحادثة الصوتية اللايف وتوليد الصور كخيار أساسي أو احتياطي ذكي.',
        'للحصول على سرعة أعلى وذكاء أقوى، يمكنك إضافة مفتاح Gemini أو Groq المجاني من الأعلى.',
      ],
      keyGuideEn: [
        '100% free cloud engine — no API key or sign-up required.',
        'Works immediately for Live Voice, AI Chat, and automatic fallback.',
        'For higher speed and larger context, add a free Google Gemini or Groq key.',
      ],
      badgeColor: TalkoraColors.iosTeal,
      icon: CupertinoIcons.sparkles,
    ),
    AiProviderPreset(
      type: AiProviderType.gemini,
      id: 'gemini',
      name: 'Google Gemini',
      shortName: 'Gemini',
      descriptionEn: 'Gemini 2.5 Pro, 2.5 Flash & 2.0 Flash via Google AI Studio (Free tier!)',
      descriptionAr: 'نماذج Gemini 2.5 Pro و Flash الأحدث من جوجل (باقة مجانية قوية جداً)',
      defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      defaultModel: 'gemini-2.5-flash',
      suggestedModels: ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash', 'gemini-2.0-flash-lite'],
      wireFormat: AiWireFormat.googleGemini,
      hasFreeTier: true,
      apiKeyPlaceholder: 'AIzaSy...',
      keyConsoleUrl: 'https://aistudio.google.com/apikey',
      keyGuideAr: [
        'اضغط على زر "افتح صفحة المفتاح" بالأسفل لفتح Google AI Studio.',
        'سجّل الدخول بحساب Google (Gmail) الخاص بك.',
        'اضغط على زر "Create API key" ثم اختر مشروعاً أو أنشئ مشروعاً جديداً.',
        'انسخ المفتاح الذي يبدأ بـ AIzaSy... والصقه هنا ثم اضغط "حفظ وتفعيل".',
      ],
      keyGuideEn: [
        'Tap "Open Key Console" below to visit Google AI Studio.',
        'Sign in with your Google account.',
        'Click "Create API key" and select or create a Google Cloud project.',
        'Copy the key starting with AIzaSy... and paste it here.',
      ],
      badgeColor: TalkoraColors.iosBlue,
      icon: CupertinoIcons.wand_stars,
    ),
    AiProviderPreset(
      type: AiProviderType.groq,
      id: 'groq',
      name: 'Groq (Ultra-Fast)',
      shortName: 'Groq',
      descriptionEn: 'Instant Llama 3.3 70B & Qwen inference — best for Live Voice (Free tier!)',
      descriptionAr: 'أسرع محرك عالمياً (مثالي للمحادثة الصوتية اللايف) — مجاني!',
      defaultBaseUrl: 'https://api.groq.com/openai/v1',
      defaultModel: 'llama-3.3-70b-versatile',
      suggestedModels: [
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'deepseek-r1-distill-llama-70b',
        'gemma2-9b-it',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      apiKeyPlaceholder: 'gsk_...',
      keyConsoleUrl: 'https://console.groq.com/keys',
      keyGuideAr: [
        'افتح console.groq.com/keys من الزر بالأسفل وسجّل الدخول بحساب Google أو GitHub.',
        'اضغط على "Create API Key" واكتب أي اسم مثل LISORA.',
        'انسخ المفتاح الذي يبدأ بـ gsk_... فوراً (يظهر مرة واحدة فقط).',
        'الصقه هنا واضغط "اختبار الاتصال" — مجاني وسريع جداً للصوت اللايف!',
      ],
      keyGuideEn: [
        'Open console.groq.com/keys and sign in with Google or GitHub.',
        'Click "Create API Key" and name it LISORA.',
        'Copy the key starting with gsk_... immediately.',
        'Paste it here and tap Test API — ultra-fast and free for Live Voice!',
      ],
      badgeColor: TalkoraColors.iosPink,
      icon: CupertinoIcons.bolt_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.openrouter,
      id: 'openrouter',
      name: 'OpenRouter (200+ Models)',
      shortName: 'OpenRouter',
      descriptionEn: 'Single API key for 200+ free & pro models (GPT, Claude, DeepSeek, Llama)',
      descriptionAr: 'مفتاح واحد لتشغيل أكثر من 200 نموذج مجاني ومدفوع (GPT, Claude, DeepSeek)',
      defaultBaseUrl: 'https://openrouter.ai/api/v1',
      defaultModel: 'meta-llama/llama-3.3-70b-instruct:free',
      suggestedModels: [
        'meta-llama/llama-3.3-70b-instruct:free',
        'deepseek/deepseek-r1:free',
        'google/gemini-2.0-flash-exp:free',
        'openai/gpt-4o-mini',
        'anthropic/claude-3.5-sonnet',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      apiKeyPlaceholder: 'sk-or-v1-...',
      keyConsoleUrl: 'https://openrouter.ai/keys',
      keyGuideAr: [
        'افتح openrouter.ai/keys وسجّل بحساب Google.',
        'اضغط "Create Key" واكتب اسماً للمفتاح واترك الرصيد اختيارياً (يوجد نماذج :free مجانية).',
        'انسخ المفتاح الذي يبدأ بـ sk-or-v1-... والصقه هنا.',
        'اختر أي نموذج ينتهي بـ :free للاستخدام المجاني الكامل!',
      ],
      keyGuideEn: [
        'Visit openrouter.ai/keys and sign in with Google.',
        'Click "Create Key" and name your key.',
        'Copy the key starting with sk-or-v1-... and paste it here.',
        'Pick any model ending with :free for zero-cost usage!',
      ],
      badgeColor: TalkoraColors.iosPurple,
      icon: CupertinoIcons.globe,
    ),
    AiProviderPreset(
      type: AiProviderType.openai,
      id: 'openai',
      name: 'OpenAI (GPT)',
      shortName: 'OpenAI',
      descriptionEn: 'GPT-4o, GPT-4.1, o3-mini & DALL-E 3 image generation',
      descriptionAr: 'نماذج GPT-4o و GPT-4.1 و o3-mini وتوليد صور DALL-E 3',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      suggestedModels: ['gpt-4o-mini', 'gpt-4o', 'gpt-4.1', 'gpt-4.1-mini', 'o3-mini'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      apiKeyPlaceholder: 'sk-proj-...',
      keyConsoleUrl: 'https://platform.openai.com/api-keys',
      keyGuideAr: [
        'افتح platform.openai.com/api-keys وسجّل الدخول لحساب OpenAI.',
        'تأكد من إضافة رصيد في قسم Billing (بدءاً من 5 دولار).',
        'اضغط "+ Create new secret key" وانسخ المفتاح الذي يبدأ بـ sk-proj-...',
        'الصقه هنا — وسيعمل تلقائياً أيضاً لتوليد الصور بدقة DALL-E 3!',
      ],
      keyGuideEn: [
        'Open platform.openai.com/api-keys and sign in.',
        'Ensure billing credits are active in OpenAI Billing.',
        'Click "+ Create new secret key" and copy the sk-proj-... key.',
        'Paste here — also unlocks DALL-E 3 inside Image Studio!',
      ],
      badgeColor: TalkoraColors.iosGreen,
      icon: CupertinoIcons.cube_box_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.deepseek,
      id: 'deepseek',
      name: 'DeepSeek AI',
      shortName: 'DeepSeek',
      descriptionEn: 'DeepSeek V3 Chat & DeepSeek R1 Reasoner (Ultra affordable)',
      descriptionAr: 'نماذج DeepSeek V3 و DeepSeek R1 للتفكير العميق بتكلفة رمزية',
      defaultBaseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
      suggestedModels: ['deepseek-chat', 'deepseek-reasoner'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      apiKeyPlaceholder: 'sk-...',
      keyConsoleUrl: 'https://platform.deepseek.com/api_keys',
      keyGuideAr: [
        'افتح platform.deepseek.com/api_keys وسجّل الدخول.',
        'اضغط على "Create new API key" واختر اسماً للمفتاح.',
        'انسخ المفتاح الذي يبدأ بـ sk-... والصقه هنا.',
        'استخدم deepseek-reasoner للبرمجة والرياضيات المعقدة وdeepseek-chat للمحادثة.',
      ],
      keyGuideEn: [
        'Visit platform.deepseek.com/api_keys and sign in.',
        'Click "Create new API key" and copy your sk-... key.',
        'Use deepseek-reasoner for deep reasoning or deepseek-chat for fast replies.',
      ],
      badgeColor: TalkoraColors.iosIndigo,
      icon: CupertinoIcons.compass_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.claude,
      id: 'claude',
      name: 'Anthropic Claude',
      shortName: 'Claude',
      descriptionEn: 'Claude 3.7 Sonnet, 3.5 Sonnet & 3.5 Haiku',
      descriptionAr: 'نماذج Claude 3.7 Sonnet و 3.5 Haiku الاحترافية في الكتابة والبرمجة',
      defaultBaseUrl: 'https://api.anthropic.com/v1',
      defaultModel: 'claude-3-5-sonnet-latest',
      suggestedModels: [
        'claude-3-7-sonnet-latest',
        'claude-3-5-sonnet-latest',
        'claude-3-5-haiku-latest',
      ],
      wireFormat: AiWireFormat.anthropicClaude,
      hasFreeTier: false,
      apiKeyPlaceholder: 'sk-ant-api03-...',
      keyConsoleUrl: 'https://console.anthropic.com/settings/keys',
      keyGuideAr: [
        'افتح console.anthropic.com/settings/keys وسجّل الدخول.',
        'اضغط "+ Create Key" واكتب اسماً للمفتاح.',
        'انسخ المفتاح الذي يبدأ بـ sk-ant-... والصقه هنا.',
      ],
      keyGuideEn: [
        'Open console.anthropic.com/settings/keys and sign in.',
        'Click "+ Create Key" and copy the sk-ant-... key.',
        'Paste it here and tap Save & Activate.',
      ],
      badgeColor: TalkoraColors.iosOrange,
      icon: CupertinoIcons.chat_bubble_2_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.xai,
      id: 'xai',
      name: 'xAI (Grok)',
      shortName: 'Grok',
      descriptionEn: 'Grok-3 Mini & Grok-2 models from xAI',
      descriptionAr: 'نماذج Grok من شركة xAI',
      defaultBaseUrl: 'https://api.x.ai/v1',
      defaultModel: 'grok-2-latest',
      suggestedModels: ['grok-2-latest', 'grok-3-mini-beta'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      apiKeyPlaceholder: 'xai-...',
      keyConsoleUrl: 'https://console.x.ai',
      keyGuideAr: [
        'افتح console.x.ai وسجّل الدخول بحساب X أو Google.',
        'من القائمة الجانبية اختر API Keys ثم Create API Key.',
        'انسخ المفتاح الذي يبدأ بـ xai-... والصقه هنا.',
      ],
      keyGuideEn: [
        'Visit console.x.ai and sign in.',
        'Go to API Keys -> Create API Key and copy the xai-... token.',
      ],
      badgeColor: Color(0xFF3A3A3C),
      icon: CupertinoIcons.flame_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.mistral,
      id: 'mistral',
      name: 'Mistral AI',
      shortName: 'Mistral',
      descriptionEn: 'Mistral Large, Small & Codestral (Free experiment tier!)',
      descriptionAr: 'نماذج Mistral الأوروبية عالية الدقة (باقة مجانية للتجربة)',
      defaultBaseUrl: 'https://api.mistral.ai/v1',
      defaultModel: 'mistral-small-latest',
      suggestedModels: ['mistral-small-latest', 'mistral-large-latest', 'open-mistral-nemo'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      apiKeyPlaceholder: 'mistral-...',
      keyConsoleUrl: 'https://console.mistral.ai/api-keys',
      keyGuideAr: [
        'افتح console.mistral.ai/api-keys وأنشئ حساباً مجانياً.',
        'فعّل خطة La Plateforme المجانية (Experiment) برقم هاتفك.',
        'اضغط "Create new key" وانسخ المفتاح والصقه هنا.',
      ],
      keyGuideEn: [
        'Open console.mistral.ai/api-keys and create a free account.',
        'Enable the free Experiment tier and click "Create new key".',
      ],
      badgeColor: TalkoraColors.iosTeal,
      icon: CupertinoIcons.wind,
    ),
    AiProviderPreset(
      type: AiProviderType.huggingface,
      id: 'huggingface',
      name: 'HuggingFace Hub',
      shortName: 'HuggingFace',
      descriptionEn: 'Open-source LLMs + FLUX.1-schnell image generation (Free tier!)',
      descriptionAr: 'مفتاح مجاني لتشغيل النماذج المفتوحة وتوليد صور FLUX.1',
      defaultBaseUrl: 'https://router.huggingface.co/v1',
      defaultModel: 'Qwen/Qwen2.5-72B-Instruct',
      suggestedModels: [
        'Qwen/Qwen2.5-72B-Instruct',
        'meta-llama/Llama-3.3-70B-Instruct',
        'mistralai/Mistral-7B-Instruct-v0.3',
      ],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: true,
      apiKeyPlaceholder: 'hf_...',
      keyConsoleUrl: 'https://huggingface.co/settings/tokens',
      keyGuideAr: [
        'افتح huggingface.co/settings/tokens وسجّل الدخول.',
        'اضغط "+ Create new token" واختر نوع "Read" أو "Make calls to Inference Providers".',
        'انسخ المفتاح الذي يبدأ بـ hf_... والصقه هنا (يعمل أيضاً في استوديو الصور!).',
      ],
      keyGuideEn: [
        'Visit huggingface.co/settings/tokens and sign in.',
        'Click "+ Create new token" with Inference permissions.',
        'Copy the hf_... token and paste it here (also unlocks FLUX images!).',
      ],
      badgeColor: TalkoraColors.iosOrange,
      icon: CupertinoIcons.smiley_fill,
    ),
    AiProviderPreset(
      type: AiProviderType.ollama,
      id: 'ollama',
      name: 'Ollama / LM Studio',
      shortName: 'Local AI',
      descriptionEn: 'Run local open-source LLMs on your PC / LAN without keys',
      descriptionAr: 'تشغيل النماذج محلياً على جهازك بدون مفاتيح مدفوعة',
      defaultBaseUrl: 'http://10.0.2.2:11434/v1',
      defaultModel: 'llama3.2',
      suggestedModels: ['llama3.2', 'qwen2.5', 'mistral', 'gemma2'],
      wireFormat: AiWireFormat.openAiCompatible,
      requiresApiKey: false,
      hasFreeTier: true,
      apiKeyPlaceholder: 'Optional local key',
      keyConsoleUrl: 'https://ollama.com',
      keyGuideAr: [
        'ثبّت برنامج Ollama على جهاز الكمبيوتر من ollama.com.',
        'شغّل الأمر: ollama run llama3.2 وتأكد أن الهاتف والكمبيوتر على نفس شبكة Wi-Fi.',
        'ضع عنوان IP الكمبيوتر في Base URL مثل http://192.168.1.5:11434/v1 بدون مفتاح.',
      ],
      keyGuideEn: [
        'Install Ollama on your PC from ollama.com and run `ollama run llama3.2`.',
        'Enter your PC LAN IP in Base URL (e.g. http://192.168.1.5:11434/v1).',
      ],
      badgeColor: Color(0xFF636366),
      icon: CupertinoIcons.desktopcomputer,
    ),
    AiProviderPreset(
      type: AiProviderType.custom,
      id: 'custom',
      name: 'Custom Any AI API',
      shortName: 'Custom API',
      descriptionEn: 'Connect ANY OpenAI-compatible URL, model ID & API key',
      descriptionAr: 'ربط أي رابط API مخصص وأي اسم نموذج وأي مفتاح بحرية كاملة',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'custom-model',
      suggestedModels: ['gpt-4o-mini', 'llama-3.3-70b', 'qwen-2.5-72b'],
      wireFormat: AiWireFormat.openAiCompatible,
      hasFreeTier: false,
      apiKeyPlaceholder: 'Enter any API key...',
      keyConsoleUrl: 'https://openrouter.ai',
      keyGuideAr: [
        'أدخل رابط الخادم Base URL الخاص بأي مزود يدعم بروتوكول OpenAI.',
        'أدخل اسم النموذج Model ID والمفتاح ثم اضغط "اختبار الاتصال".',
      ],
      keyGuideEn: [
        'Enter any OpenAI-compatible Base URL, Model ID, and API Key, then test.',
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

/// Chat message model used across AI Chat Studio, Live Voice & Roleplay Arena.
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
