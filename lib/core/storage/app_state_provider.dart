import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkora_ai/app/localization/app_strings.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/ai/universal_ai_service.dart';
import 'package:talkora_ai/core/constants/api_config.dart';

class LearnerProfileState {
  final bool onboardingCompleted;
  final String displayName;
  final String nativeLanguage;
  final String englishLevel;
  final String learningGoal;
  final String preferredAccent;
  final int dailyTargetMinutes;
  final String explanationLanguage;
  final String uiLocale;
  final ThemeMode themeMode;
  final String accentColorKey;
  final bool memoryEnabled;
  final String serverBaseUrl;
  final int speakingMinutesToday;
  final int vocabularyLearned;
  final int streakDays;
  final int xpPoints;

  const LearnerProfileState({
    this.onboardingCompleted = false,
    this.displayName = 'YOSSEF JOO',
    this.nativeLanguage = 'Arabic',
    this.englishLevel = 'B1',
    this.learningGoal = 'Fluency',
    this.preferredAccent = 'American',
    this.dailyTargetMinutes = 15,
    this.explanationLanguage = 'Arabic',
    this.uiLocale = 'ar',
    this.themeMode = ThemeMode.dark,
    this.accentColorKey = 'blue',
    this.memoryEnabled = true,
    this.serverBaseUrl = ApiConfig.defaultBaseUrl,
    this.speakingMinutesToday = 9,
    this.vocabularyLearned = 24,
    this.streakDays = 5,
    this.xpPoints = 420,
  });

  LearnerProfileState copyWith({
    bool? onboardingCompleted,
    String? displayName,
    String? nativeLanguage,
    String? englishLevel,
    String? learningGoal,
    String? preferredAccent,
    int? dailyTargetMinutes,
    String? explanationLanguage,
    String? uiLocale,
    ThemeMode? themeMode,
    String? accentColorKey,
    bool? memoryEnabled,
    String? serverBaseUrl,
    int? speakingMinutesToday,
    int? vocabularyLearned,
    int? streakDays,
    int? xpPoints,
  }) {
    return LearnerProfileState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      displayName: displayName ?? this.displayName,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      englishLevel: englishLevel ?? this.englishLevel,
      learningGoal: learningGoal ?? this.learningGoal,
      preferredAccent: preferredAccent ?? this.preferredAccent,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      explanationLanguage: explanationLanguage ?? this.explanationLanguage,
      uiLocale: uiLocale ?? this.uiLocale,
      themeMode: themeMode ?? this.themeMode,
      accentColorKey: accentColorKey ?? this.accentColorKey,
      memoryEnabled: memoryEnabled ?? this.memoryEnabled,
      serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
      speakingMinutesToday: speakingMinutesToday ?? this.speakingMinutesToday,
      vocabularyLearned: vocabularyLearned ?? this.vocabularyLearned,
      streakDays: streakDays ?? this.streakDays,
      xpPoints: xpPoints ?? this.xpPoints,
    );
  }
}

class LearnerProfileNotifier extends StateNotifier<LearnerProfileState> {
  LearnerProfileNotifier() : super(const LearnerProfileState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIdx = prefs.getInt('theme_mode') ?? ThemeMode.dark.index;
      state = state.copyWith(
        onboardingCompleted: prefs.getBool('onboarding_completed') ?? false,
        displayName: prefs.getString('display_name') ?? 'YOSSEF JOO',
        nativeLanguage: prefs.getString('native_language') ?? 'Arabic',
        englishLevel: prefs.getString('english_level') ?? 'B1',
        learningGoal: prefs.getString('learning_goal') ?? 'Fluency',
        preferredAccent: prefs.getString('preferred_accent') ?? 'American',
        dailyTargetMinutes: prefs.getInt('daily_target_minutes') ?? 15,
        explanationLanguage: prefs.getString('explanation_language') ?? 'Arabic',
        uiLocale: prefs.getString('ui_locale') ?? 'ar',
        themeMode: ThemeMode.values[themeIdx.clamp(0, 2)],
        accentColorKey: prefs.getString('accent_color_key') ?? 'blue',
        memoryEnabled: prefs.getBool('memory_enabled') ?? true,
        serverBaseUrl: prefs.getString('server_base_url') ?? ApiConfig.defaultBaseUrl,
        xpPoints: prefs.getInt('xp_points') ?? 420,
      );
    } catch (_) {
      // Safe fallback in unit/widget test environments without platform channels
    }
  }

  Future<void> saveOnboarding({
    required String displayName,
    required String nativeLanguage,
    required String englishLevel,
    required String learningGoal,
    required String preferredAccent,
    required int dailyTargetMinutes,
    required String explanationLanguage,
  }) async {
    state = state.copyWith(
      onboardingCompleted: true,
      displayName: displayName.trim().isEmpty ? 'Learner' : displayName.trim(),
      nativeLanguage: nativeLanguage,
      englishLevel: englishLevel,
      learningGoal: learningGoal,
      preferredAccent: preferredAccent,
      dailyTargetMinutes: dailyTargetMinutes,
      explanationLanguage: explanationLanguage,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('display_name', state.displayName);
      await prefs.setString('native_language', state.nativeLanguage);
      await prefs.setString('english_level', state.englishLevel);
      await prefs.setString('learning_goal', state.learningGoal);
      await prefs.setString('preferred_accent', state.preferredAccent);
      await prefs.setInt('daily_target_minutes', state.dailyTargetMinutes);
      await prefs.setString('explanation_language', state.explanationLanguage);
    } catch (_) {}
  }

  Future<void> setLocale(String langCode) async {
    state = state.copyWith(uiLocale: langCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ui_locale', langCode);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
    } catch (_) {}
  }

  Future<void> setAccentColor(String key) async {
    state = state.copyWith(accentColorKey: key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accent_color_key', key);
    } catch (_) {}
  }

  Future<void> setEnglishLevel(String level) async {
    state = state.copyWith(englishLevel: level);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('english_level', level);
    } catch (_) {}
  }

  Future<void> setDailyTargetMinutes(int minutes) async {
    state = state.copyWith(dailyTargetMinutes: minutes);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_target_minutes', minutes);
    } catch (_) {}
  }

  Future<void> setMemoryEnabled(bool enabled) async {
    state = state.copyWith(memoryEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('memory_enabled', enabled);
    } catch (_) {}
  }

  Future<void> setServerUrl(String url) async {
    state = state.copyWith(serverBaseUrl: url.trim());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_base_url', state.serverBaseUrl);
    } catch (_) {}
  }

  void incrementSpeakingMinutes(int delta) {
    state = state.copyWith(
      speakingMinutesToday: state.speakingMinutesToday + delta,
      xpPoints: state.xpPoints + (delta * 10),
    );
  }

  void incrementVocabLearned() {
    state = state.copyWith(
      vocabularyLearned: state.vocabularyLearned + 1,
      xpPoints: state.xpPoints + 15,
    );
  }

  void addXp(int delta) {
    state = state.copyWith(xpPoints: state.xpPoints + delta);
  }

  void resetProgress() {
    state = state.copyWith(speakingMinutesToday: 0, vocabularyLearned: 0, streakDays: 1, xpPoints: 0);
  }
}

/// Persistent Universal Multi-Provider AI Settings State (v3.0 Smart Router).
class AiSettingsState {
  final String activeProviderId;
  final Map<String, ProviderCredential> credentials;
  final double temperature;
  final int maxTokens;
  final String customSystemPrompt;
  final bool smartFallbackEnabled;
  final bool deepThinkingEnabled;
  final bool deviceControlEnabled;
  final bool voiceAutoLoopEnabled;
  final double voiceSpeechRate;
  final String voiceLocale;

  const AiSettingsState({
    this.activeProviderId = 'pollinations',
    this.credentials = const {},
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.customSystemPrompt =
        'You are LISORA AI v3.0 — an ultra-intelligent personal AI assistant, English speaking coach, coder, and smart phone controller developed by YOSSEF JOO. '
        'Answer clearly, accurately, and naturally in the user language (Arabic or English).',
    this.smartFallbackEnabled = true,
    this.deepThinkingEnabled = false,
    this.deviceControlEnabled = true,
    this.voiceAutoLoopEnabled = true,
    this.voiceSpeechRate = 1.0,
    this.voiceLocale = 'ar-EG',
  });

  AiProviderPreset get activePreset => AiProviderCatalog.byId(activeProviderId);

  ProviderCredential credentialFor(String providerId) {
    final preset = AiProviderCatalog.byId(providerId);
    final stored = credentials[providerId];
    return ProviderCredential(
      apiKey: stored?.apiKey ?? '',
      model: (stored?.model.isNotEmpty ?? false) ? stored!.model : preset.defaultModel,
      baseUrl: (stored?.baseUrl.isNotEmpty ?? false) ? stored!.baseUrl : preset.defaultBaseUrl,
    );
  }

  String get activeApiKey => credentialFor(activeProviderId).apiKey;
  String get activeModel => credentialFor(activeProviderId).model;
  String get activeBaseUrl => credentialFor(activeProviderId).baseUrl;

  bool get isConfigured => !activePreset.requiresApiKey || activeApiKey.trim().isNotEmpty;

  int get configuredProvidersCount {
    int count = 0;
    for (final p in AiProviderCatalog.all) {
      if (!p.requiresApiKey || (credentials[p.id]?.apiKey.trim().isNotEmpty ?? false)) {
        count++;
      }
    }
    return count;
  }

  AiSettingsState copyWith({
    String? activeProviderId,
    Map<String, ProviderCredential>? credentials,
    double? temperature,
    int? maxTokens,
    String? customSystemPrompt,
    bool? smartFallbackEnabled,
    bool? deepThinkingEnabled,
    bool? deviceControlEnabled,
    bool? voiceAutoLoopEnabled,
    double? voiceSpeechRate,
    String? voiceLocale,
  }) {
    return AiSettingsState(
      activeProviderId: activeProviderId ?? this.activeProviderId,
      credentials: credentials ?? this.credentials,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
      smartFallbackEnabled: smartFallbackEnabled ?? this.smartFallbackEnabled,
      deepThinkingEnabled: deepThinkingEnabled ?? this.deepThinkingEnabled,
      deviceControlEnabled: deviceControlEnabled ?? this.deviceControlEnabled,
      voiceAutoLoopEnabled: voiceAutoLoopEnabled ?? this.voiceAutoLoopEnabled,
      voiceSpeechRate: voiceSpeechRate ?? this.voiceSpeechRate,
      voiceLocale: voiceLocale ?? this.voiceLocale,
    );
  }
}

class AiSettingsNotifier extends StateNotifier<AiSettingsState> {
  static const _kActiveProvider = 'ai_active_provider_v3';
  static const _kCredentialsMap = 'ai_credentials_map_v2';
  static const _kTemperature = 'ai_temperature_v2';
  static const _kMaxTokens = 'ai_max_tokens_v2';
  static const _kSystemPrompt = 'ai_system_prompt_v3';
  static const _kSmartFallback = 'ai_smart_fallback_v3';
  static const _kDeepThinking = 'ai_deep_thinking_v3';
  static const _kDeviceControl = 'ai_device_control_v3';
  static const _kVoiceAutoLoop = 'ai_voice_auto_loop_v3';
  static const _kVoiceRate = 'ai_voice_rate_v3';
  static const _kVoiceLocale = 'ai_voice_locale_v3';

  AiSettingsNotifier() : super(const AiSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString(_kActiveProvider) ?? 'pollinations';
      final rawJson = prefs.getString(_kCredentialsMap);
      final Map<String, ProviderCredential> map = {};
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            map[k] = ProviderCredential.fromJson(v);
          }
        });
      }
      state = state.copyWith(
        activeProviderId: activeId,
        credentials: map,
        temperature: prefs.getDouble(_kTemperature) ?? 0.7,
        maxTokens: prefs.getInt(_kMaxTokens) ?? 2048,
        customSystemPrompt: prefs.getString(_kSystemPrompt) ?? state.customSystemPrompt,
        smartFallbackEnabled: prefs.getBool(_kSmartFallback) ?? true,
        deepThinkingEnabled: prefs.getBool(_kDeepThinking) ?? false,
        deviceControlEnabled: prefs.getBool(_kDeviceControl) ?? true,
        voiceAutoLoopEnabled: prefs.getBool(_kVoiceAutoLoop) ?? true,
        voiceSpeechRate: prefs.getDouble(_kVoiceRate) ?? 1.0,
        voiceLocale: prefs.getString(_kVoiceLocale) ?? 'ar-EG',
      );
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveProvider, state.activeProviderId);
      final encoded = jsonEncode(
        state.credentials.map((k, v) => MapEntry(k, v.toJson())),
      );
      await prefs.setString(_kCredentialsMap, encoded);
      await prefs.setDouble(_kTemperature, state.temperature);
      await prefs.setInt(_kMaxTokens, state.maxTokens);
      await prefs.setString(_kSystemPrompt, state.customSystemPrompt);
      await prefs.setBool(_kSmartFallback, state.smartFallbackEnabled);
      await prefs.setBool(_kDeepThinking, state.deepThinkingEnabled);
      await prefs.setBool(_kDeviceControl, state.deviceControlEnabled);
      await prefs.setBool(_kVoiceAutoLoop, state.voiceAutoLoopEnabled);
      await prefs.setDouble(_kVoiceRate, state.voiceSpeechRate);
      await prefs.setString(_kVoiceLocale, state.voiceLocale);
    } catch (_) {}
  }

  Future<void> selectProvider(String providerId) async {
    state = state.copyWith(activeProviderId: providerId);
    await _persist();
  }

  Future<void> saveProviderConfig({
    required String providerId,
    required String apiKey,
    required String model,
    required String baseUrl,
  }) async {
    final updated = Map<String, ProviderCredential>.from(state.credentials);
    updated[providerId] = ProviderCredential(
      apiKey: apiKey.trim(),
      model: model.trim(),
      baseUrl: baseUrl.trim(),
    );
    state = state.copyWith(activeProviderId: providerId, credentials: updated);
    await _persist();
  }

  Future<void> updateAdvanced({
    double? temperature,
    int? maxTokens,
    String? customSystemPrompt,
    bool? smartFallbackEnabled,
    bool? deepThinkingEnabled,
    bool? deviceControlEnabled,
    bool? voiceAutoLoopEnabled,
    double? voiceSpeechRate,
    String? voiceLocale,
  }) async {
    state = state.copyWith(
      temperature: temperature,
      maxTokens: maxTokens,
      customSystemPrompt: customSystemPrompt,
      smartFallbackEnabled: smartFallbackEnabled,
      deepThinkingEnabled: deepThinkingEnabled,
      deviceControlEnabled: deviceControlEnabled,
      voiceAutoLoopEnabled: voiceAutoLoopEnabled,
      voiceSpeechRate: voiceSpeechRate,
      voiceLocale: voiceLocale,
    );
    await _persist();
  }

  Future<void> clearApiKey(String providerId) async {
    final current = state.credentialFor(providerId);
    final updated = Map<String, ProviderCredential>.from(state.credentials);
    updated[providerId] = current.copyWith(apiKey: '');
    state = state.copyWith(credentials: updated);
    await _persist();
  }
}

final learnerProfileProvider = StateNotifierProvider<LearnerProfileNotifier, LearnerProfileState>(
  (ref) => LearnerProfileNotifier(),
);

final aiSettingsProvider = StateNotifierProvider<AiSettingsNotifier, AiSettingsState>(
  (ref) => AiSettingsNotifier(),
);

final universalAiServiceProvider = Provider<UniversalAiService>(
  (ref) => UniversalAiService(),
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(learnerProfileProvider.select((s) => s.uiLocale));
  return AppStrings(locale);
});
