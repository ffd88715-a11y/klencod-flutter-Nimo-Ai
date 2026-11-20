import 'dart:math';
import 'package:talkora_ai/core/device/native_bridge_service.dart';

/// Result of parsing and executing autonomous AI / Voice phone actions.
class ToolExecutionOutcome {
  final String cleanReply;
  final String? actionBadge;
  final String? generatedImageUrl;
  final bool handledDirectly;

  const ToolExecutionOutcome({
    required this.cleanReply,
    this.actionBadge,
    this.generatedImageUrl,
    this.handledDirectly = false,
  });
}

/// Autonomous Phone & AI Tool Executor.
/// Executes device management commands directly from Arabic/English voice & chat
/// as well as structured `[ACTION:type|arg1|arg2]` tags emitted by the AI model.
class AiToolExecutor {
  final NativeBridgeService bridge;

  const AiToolExecutor(this.bridge);

  /// Instructions injected into the AI system prompt when Device Control is enabled.
  static const String systemToolPrompt = '''
You are Nimo v4.0 Ultra — an ultra-powerful assistant with FULL phone & app control.
When the user asks you to perform a phone action or generate an image, include ONE exact action tag at the end of your reply:
- Open any app: [ACTION:open_app|app_name]
- Send WhatsApp message: [ACTION:whatsapp|phone_number|message]
- Dial/Call number: [ACTION:call|phone_number]
- Send SMS: [ACTION:sms|phone_number|message]
- Set Alarm (24h): [ACTION:alarm|HH:MM|label]
- Set Timer (seconds): [ACTION:timer|seconds|label]
- Open Google Maps: [ACTION:maps|place_or_address]
- Search YouTube: [ACTION:youtube|search_query]
- Toggle Flashlight: [ACTION:flashlight|on] or [ACTION:flashlight|off]
- Open Phone Settings: [ACTION:settings|wifi|bluetooth|display|battery|sound|location|apps|main]
- Generate an AI Image: [ACTION:generate_image|detailed_english_prompt]
Only include an [ACTION:...] tag when the user actually requests that action. Always confirm naturally in the user's language.
''';

  /// Fast local intent interceptor for instant zero-latency phone commands (great for Live Voice!).
  Future<ToolExecutionOutcome?> tryInstantLocalCommand(
    String userText, {
    required bool isArabic,
  }) async {
    final text = userText.trim();
    final lower = text.toLowerCase();

    // 1. Flashlight ON / OFF
    if (lower.contains('شغل الكشاف') ||
        lower.contains('افتح الكشاف') ||
        lower.contains('نور الكشاف') ||
        lower.contains('turn on flashlight') ||
        lower.contains('flashlight on')) {
      final ok = await bridge.toggleFlashlight(true);
      return ToolExecutionOutcome(
        cleanReply: ok
            ? (isArabic ? 'تم تشغيل الكشاف بنجاح.' : 'Flashlight turned on.')
            : (isArabic ? 'تعذّر تشغيل الكشاف على هذا الجهاز.' : 'Could not enable flashlight.'),
        actionBadge: ok ? (isArabic ? 'تم تشغيل الكشاف' : 'Flashlight ON') : null,
        handledDirectly: true,
      );
    }
    if (lower.contains('اطفي الكشاف') ||
        lower.contains('اقفل الكشاف') ||
        lower.contains('turn off flashlight') ||
        lower.contains('flashlight off')) {
      final ok = await bridge.toggleFlashlight(false);
      return ToolExecutionOutcome(
        cleanReply: ok
            ? (isArabic ? 'تم إطفاء الكشاف.' : 'Flashlight turned off.')
            : (isArabic ? 'تعذّر إطفاء الكشاف.' : 'Could not disable flashlight.'),
        actionBadge: ok ? (isArabic ? 'تم إطفاء الكشاف' : 'Flashlight OFF') : null,
        handledDirectly: true,
      );
    }

    // 2. Device / Battery Status
    if (lower.contains('حالة البطارية') ||
        lower.contains('نسبة الشحن') ||
        lower.contains('شحن الموبايل') ||
        lower.contains('battery status') ||
        lower.contains('battery level')) {
      final info = await bridge.getDeviceStatus();
      final reply = isArabic
          ? 'نسبة البطارية الحالية ${info.batteryLevel}% (${info.isCharging ? 'قيد الشحن' : 'غير متصل بالشاحن'}) على جهاز ${info.manufacturer} ${info.model} (Android ${info.androidVersion}).'
          : 'Battery is at ${info.batteryLevel}% (${info.isCharging ? 'Charging' : 'Discharging'}) on ${info.manufacturer} ${info.model} (Android ${info.androidVersion}).';
      return ToolExecutionOutcome(
        cleanReply: reply,
        actionBadge: isArabic ? 'البطارية: ${info.batteryLevel}%' : 'Battery: ${info.batteryLevel}%',
        handledDirectly: true,
      );
    }

    // 3. Direct Open App ("افتح واتساب" / "open youtube")
    final openAr = RegExp(r"""^(?:افتح|شغل|افتحلي|شغلي)\s+(?:تطبيق\s+)?(.+)$""").firstMatch(text);
    final openEn = RegExp(r"""^(?:open|launch)\s+(.+)$""", caseSensitive: false).firstMatch(text);
    final appTarget = (openAr?.group(1) ?? openEn?.group(1))?.trim();
    if (appTarget != null &&
        appTarget.isNotEmpty &&
        !appTarget.contains('الكشاف') &&
        !appTarget.contains('flashlight') &&
        appTarget.split(' ').length <= 3) {
      // System settings shortcuts
      if (appTarget.contains('واي فاي') || appTarget.toLowerCase().contains('wifi')) {
        await bridge.openSystemSetting('wifi');
        return ToolExecutionOutcome(
          cleanReply: isArabic ? 'فتحت لك إعدادات الواي فاي.' : 'Opened Wi-Fi settings.',
          actionBadge: isArabic ? 'إعدادات Wi-Fi' : 'Wi-Fi Settings',
          handledDirectly: true,
        );
      }
      if (appTarget.contains('بلوتوث') || appTarget.toLowerCase().contains('bluetooth')) {
        await bridge.openSystemSetting('bluetooth');
        return ToolExecutionOutcome(
          cleanReply: isArabic ? 'فتحت لك إعدادات البلوتوث.' : 'Opened Bluetooth settings.',
          actionBadge: isArabic ? 'إعدادات البلوتوث' : 'Bluetooth Settings',
          handledDirectly: true,
        );
      }
      final launched = await bridge.launchApp(appTarget);
      if (launched) {
        return ToolExecutionOutcome(
          cleanReply: isArabic ? 'تم فتح $appTarget الآن.' : 'Opening $appTarget now.',
          actionBadge: isArabic ? 'تم فتح: $appTarget' : 'Opened: $appTarget',
          handledDirectly: true,
        );
      }
    }

    // 4. Direct YouTube Search
    final ytAr = RegExp(r"""(?:ابحث في يوتيوب عن|شغل في يوتيوب|يوتيوب عن)\s+(.+)""").firstMatch(text);
    final ytEn = RegExp(r"""(?:search youtube for|youtube)\s+(.+)""", caseSensitive: false).firstMatch(text);
    final ytQuery = (ytAr?.group(1) ?? ytEn?.group(1))?.trim();
    if (ytQuery != null && ytQuery.isNotEmpty) {
      await bridge.searchYoutube(ytQuery);
      return ToolExecutionOutcome(
        cleanReply: isArabic ? 'جاري البحث في يوتيوب عن: $ytQuery' : 'Searching YouTube for: $ytQuery',
        actionBadge: 'YouTube: $ytQuery',
        handledDirectly: true,
      );
    }

    // 5. Direct Dial Phone Number
    final callMatch = RegExp(r"""(?:اتصل ب|كلم|call|dial)\s*([+0-9][0-9\s\-]{5,})""", caseSensitive: false)
        .firstMatch(text);
    if (callMatch != null) {
      final phone = callMatch.group(1)!.replaceAll(RegExp(r'\s+'), '');
      await bridge.dialPhone(phone);
      return ToolExecutionOutcome(
        cleanReply: isArabic ? 'تم فتح الاتصال بالرقم $phone.' : 'Opening dialer for $phone.',
        actionBadge: isArabic ? 'اتصال: $phone' : 'Dial: $phone',
        handledDirectly: true,
      );
    }

    // 6. Direct Slash Image Command ("/image ..." or "ارسم لي ..." / "ولد صورة ...")
    final imgSlash = RegExp(r"""^/(?:image|img|draw)\s+(.+)$""", caseSensitive: false).firstMatch(text);
    final imgAr = RegExp(r"""^(?:ارسم لي|ارسم|ولد صورة|توليد صورة|اعمل صورة)\s+(.+)$""").firstMatch(text);
    final imgPrompt = (imgSlash?.group(1) ?? imgAr?.group(1))?.trim();
    if (imgPrompt != null && imgPrompt.isNotEmpty) {
      final url = _buildPollinationsImageUrl(imgPrompt);
      return ToolExecutionOutcome(
        cleanReply: isArabic
            ? 'تم توليد الصورة المطلوبة بنجاح! يمكنك أيضاً التعديل والحفظ بجودة أعلى من استوديو الصور.'
            : 'Generated your image! You can also refine and save in HD inside Image Studio.',
        actionBadge: isArabic ? 'توليد صورة AI' : 'AI Image Generated',
        generatedImageUrl: url,
        handledDirectly: true,
      );
    }

    return null;
  }

  /// Parses and executes any `[ACTION:type|arg1|arg2]` tags inside an AI response.
  Future<ToolExecutionOutcome> executeAiTags(
    String rawAiReply, {
    required bool isArabic,
  }) async {
    final regex = RegExp(r"""\[ACTION:([a-zA-Z0-9_]+)\|([^\]]*)\]""");
    final match = regex.firstMatch(rawAiReply);
    if (match == null) {
      return ToolExecutionOutcome(cleanReply: rawAiReply.trim());
    }

    final actionType = (match.group(1) ?? '').trim().toLowerCase();
    final rawArgs = (match.group(2) ?? '').split('|').map((s) => s.trim()).toList();
    final cleanReply = rawAiReply.replaceAll(regex, '').trim();

    String? badge;
    String? imageUrl;

    switch (actionType) {
      case 'open_app':
        final app = rawArgs.isNotEmpty ? rawArgs[0] : '';
        if (app.isNotEmpty) {
          final ok = await bridge.launchApp(app);
          badge = ok
              ? (isArabic ? 'تم فتح التطبيق: $app' : 'Opened App: $app')
              : (isArabic ? 'لم يتم العثور على التطبيق: $app' : 'App not found: $app');
        }
        break;
      case 'whatsapp':
        final phone = rawArgs.isNotEmpty ? rawArgs[0] : '';
        final msg = rawArgs.length > 1 ? rawArgs[1] : '';
        await bridge.openWhatsApp(phone: phone, message: msg);
        badge = isArabic ? 'فتح واتساب: $phone' : 'WhatsApp: $phone';
        break;
      case 'call':
        final phone = rawArgs.isNotEmpty ? rawArgs[0] : '';
        if (phone.isNotEmpty) {
          await bridge.dialPhone(phone);
          badge = isArabic ? 'اتصال: $phone' : 'Dial: $phone';
        }
        break;
      case 'sms':
        final phone = rawArgs.isNotEmpty ? rawArgs[0] : '';
        final msg = rawArgs.length > 1 ? rawArgs[1] : '';
        await bridge.sendSms(phone: phone, message: msg);
        badge = isArabic ? 'رسالة SMS: $phone' : 'SMS: $phone';
        break;
      case 'alarm':
        final timeStr = rawArgs.isNotEmpty ? rawArgs[0] : '07:00';
        final label = rawArgs.length > 1 ? rawArgs[1] : 'Nimo';
        final parts = timeStr.split(':');
        final h = int.tryParse(parts.isNotEmpty ? parts[0] : '7') ?? 7;
        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        await bridge.setAlarm(hour: h, minute: m, message: label);
        badge = isArabic ? 'تم ضبط المنبه: $h:${m.toString().padLeft(2, '0')}' : 'Alarm set: $h:${m.toString().padLeft(2, '0')}';
        break;
      case 'timer':
        final secs = int.tryParse(rawArgs.isNotEmpty ? rawArgs[0] : '60') ?? 60;
        final label = rawArgs.length > 1 ? rawArgs[1] : 'Nimo Timer';
        await bridge.setTimer(seconds: secs, message: label);
        badge = isArabic ? 'تم ضبط مؤقت: $secs ثانية' : 'Timer set: ${secs}s';
        break;
      case 'maps':
        final q = rawArgs.isNotEmpty ? rawArgs[0] : '';
        if (q.isNotEmpty) {
          await bridge.openMaps(q, navigate: false);
          badge = isArabic ? 'خرائط: $q' : 'Maps: $q';
        }
        break;
      case 'youtube':
        final q = rawArgs.isNotEmpty ? rawArgs[0] : '';
        if (q.isNotEmpty) {
          await bridge.searchYoutube(q);
          badge = 'YouTube: $q';
        }
        break;
      case 'flashlight':
        final on = rawArgs.isNotEmpty && rawArgs[0].toLowerCase() == 'on';
        await bridge.toggleFlashlight(on);
        badge = on
            ? (isArabic ? 'الكشاف: تشغيل' : 'Flashlight: ON')
            : (isArabic ? 'الكشاف: إطفاء' : 'Flashlight: OFF');
        break;
      case 'settings':
        final target = rawArgs.isNotEmpty ? rawArgs[0] : 'main';
        await bridge.openSystemSetting(target);
        badge = isArabic ? 'فتح الإعدادات: $target' : 'Settings: $target';
        break;
      case 'generate_image':
        final prompt = rawArgs.isNotEmpty ? rawArgs[0] : '';
        if (prompt.isNotEmpty) {
          imageUrl = _buildPollinationsImageUrl(prompt);
          badge = isArabic ? 'تم توليد الصورة بالذكاء الاصطناعي' : 'AI Image Generated';
        }
        break;
    }

    return ToolExecutionOutcome(
      cleanReply: cleanReply.isEmpty
          ? (badge ?? (isArabic ? 'تم تنفيذ الأمر بنجاح.' : 'Action completed.'))
          : cleanReply,
      actionBadge: badge,
      generatedImageUrl: imageUrl,
    );
  }

  static String _buildPollinationsImageUrl(String prompt) {
    final seed = Random().nextInt(999999);
    final encoded = Uri.encodeComponent('$prompt, ultra high quality, detailed, 8k');
    return 'https://image.pollinations.ai/prompt/$encoded?width=768&height=768&model=flux&seed=$seed&nologo=true';
  }
}
