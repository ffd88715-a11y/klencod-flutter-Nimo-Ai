package ai.talkora.app

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.view.SoundEffectConstants
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.AlarmClock
import android.provider.MediaStore
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.Locale
import java.util.UUID

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {

    private val methodChannelName = "ai.talkora.app/native_bridge"
    private val voiceEventChannelName = "ai.talkora.app/voice_events"

    private val mainHandler = Handler(Looper.getMainLooper())
    private var voiceEventSink: EventChannel.EventSink? = null

    private var speechRecognizer: SpeechRecognizer? = null
    private var tts: TextToSpeech? = null
    private var ttsReady: Boolean = false
    private var torchEnabled: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        tts = TextToSpeech(this, this)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, voiceEventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    voiceEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    voiceEventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // ==================== LIVE VOICE (STT / TTS) ====================
                    "isSpeechAvailable" -> {
                        result.success(SpeechRecognizer.isRecognitionAvailable(this))
                    }
                    "startListening" -> {
                        val locale = call.argument<String>("locale") ?: "ar-EG"
                        startSpeechListening(locale, result)
                    }
                    "stopListening" -> {
                        mainHandler.post {
                            try {
                                speechRecognizer?.stopListening()
                            } catch (_: Exception) {}
                        }
                        result.success(true)
                    }
                    "cancelListening" -> {
                        mainHandler.post {
                            try {
                                speechRecognizer?.cancel()
                            } catch (_: Exception) {}
                        }
                        result.success(true)
                    }
                    "playClickSound" -> {
                        try {
                            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                            am.playSoundEffect(SoundEffectConstants.CLICK, 0.7f)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    "getAvailableVoices" -> {
                        val prefix = call.argument<String>("localePrefix") ?: ""
                        result.success(listHighQualityVoices(prefix))
                    }
                    "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        val locale = call.argument<String>("locale") ?: "ar-EG"
                        val rate = (call.argument<Double>("rate") ?: 0.98).toFloat()
                        val pitch = (call.argument<Double>("pitch") ?: 0.97).toFloat()
                        val voiceName = call.argument<String>("voiceName")
                        speakText(text, locale, rate, pitch, voiceName, result)
                    }
                    "stopSpeaking" -> {
                        try {
                            tts?.stop()
                        } catch (_: Exception) {}
                        emitVoiceEvent(mapOf("type" to "tts_stopped"))
                        result.success(true)
                    }

                    // ==================== PHONE APPS & FULL DEVICE MANAGEMENT ====================
                    "getInstalledApps" -> {
                        result.success(getInstalledLaunchableApps())
                    }
                    "launchApp" -> {
                        val query = call.argument<String>("query") ?: ""
                        result.success(launchAppByQuery(query))
                    }
                    "openUrl" -> {
                        val url = call.argument<String>("url") ?: ""
                        result.success(openExternalUrl(url))
                    }
                    "openWhatsApp" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        result.success(openWhatsAppChat(phone, message))
                    }
                    "dialPhone" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        result.success(dialNumber(phone))
                    }
                    "sendSms" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        result.success(composeSms(phone, message))
                    }
                    "sendEmail" -> {
                        val to = call.argument<String>("to") ?: ""
                        val subject = call.argument<String>("subject") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        result.success(composeEmail(to, subject, body))
                    }
                    "setAlarm" -> {
                        val hour = call.argument<Int>("hour") ?: 7
                        val minute = call.argument<Int>("minute") ?: 0
                        val message = call.argument<String>("message") ?: "Nimo Alarm"
                        result.success(createAlarm(hour, minute, message))
                    }
                    "setTimer" -> {
                        val seconds = call.argument<Int>("seconds") ?: 60
                        val message = call.argument<String>("message") ?: "Nimo Timer"
                        result.success(createTimer(seconds, message))
                    }
                    "openMaps" -> {
                        val query = call.argument<String>("query") ?: ""
                        val navigate = call.argument<Boolean>("navigate") ?: false
                        result.success(launchMaps(query, navigate))
                    }
                    "searchYoutube" -> {
                        val query = call.argument<String>("query") ?: ""
                        result.success(launchYoutubeSearch(query))
                    }
                    "openSystemSetting" -> {
                        val target = call.argument<String>("target") ?: "main"
                        result.success(openAndroidSettings(target))
                    }
                    "toggleFlashlight" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: !torchEnabled
                        result.success(setFlashlight(enabled))
                    }
                    "getDeviceStatus" -> {
                        result.success(readDeviceStatus())
                    }
                    "shareText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val subject = call.argument<String>("subject") ?: "Nimo"
                        result.success(sharePlainText(text, subject))
                    }
                    "saveImageToGallery" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName") ?: "nimo_${System.currentTimeMillis()}.png"
                        if (bytes != null && bytes.isNotEmpty()) {
                            result.success(saveImageBytesToGallery(bytes, fileName))
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ==================== NATIVE TTS IMPLEMENTATION ====================
    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            ttsReady = true
            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    emitVoiceEvent(mapOf("type" to "tts_start"))
                }

                override fun onDone(utteranceId: String?) {
                    emitVoiceEvent(mapOf("type" to "tts_done"))
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    emitVoiceEvent(mapOf("type" to "tts_error"))
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    emitVoiceEvent(mapOf("type" to "tts_error", "code" to errorCode))
                }
            })
        }
    }

    private fun listHighQualityVoices(localePrefix: String): List<Map<String, Any>> {
        val out = mutableListOf<Map<String, Any>>()
        try {
            val voices = tts?.voices ?: return out
            val pfx = localePrefix.lowercase(Locale.ROOT)
            val filtered = voices.filter { v ->
                val tag = v.locale?.toLanguageTag()?.lowercase(Locale.ROOT) ?: ""
                pfx.isEmpty() || tag.startsWith(pfx)
            }.sortedByDescending { v ->
                var score = v.quality
                val n = v.name.lowercase(Locale.ROOT)
                if (n.contains("neural") || n.contains("wavenet") || n.contains("studio")) score += 300
                if (v.isNetworkConnectionRequired) score += 120
                score
            }
            for (v in filtered.take(25)) {
                out.add(
                    mapOf(
                        "name" to v.name,
                        "locale" to (v.locale?.toLanguageTag() ?: ""),
                        "quality" to v.quality,
                        "isNetwork" to v.isNetworkConnectionRequired
                    )
                )
            }
        } catch (_: Exception) {}
        return out
    }

    private fun pickBestHumanVoice(targetLocale: Locale, requestedVoiceName: String?) {
        try {
            val voices = tts?.voices ?: return
            if (!requestedVoiceName.isNullOrBlank()) {
                val exact = voices.firstOrNull { it.name == requestedVoiceName }
                if (exact != null) {
                    tts?.voice = exact
                    return
                }
            }
            val lang = targetLocale.language.lowercase(Locale.ROOT)
            val country = targetLocale.country.lowercase(Locale.ROOT)
            val best = voices
                .filter { (it.locale?.language ?: "").lowercase(Locale.ROOT) == lang }
                .maxByOrNull { v ->
                    var score = v.quality
                    val n = v.name.lowercase(Locale.ROOT)
                    if (n.contains("neural") || n.contains("wavenet") || n.contains("natural") || n.contains("studio")) score += 400
                    if (n.contains("network") || v.isNetworkConnectionRequired) score += 150
                    if (country.isNotEmpty() && (v.locale?.country ?: "").lowercase(Locale.ROOT) == country) score += 90
                    if (n.contains("local")) score -= 20
                    score
                }
            if (best != null) {
                tts?.voice = best
            }
        } catch (_: Exception) {}
    }

    private fun speakText(
        text: String,
        localeTag: String,
        rate: Float,
        pitch: Float,
        voiceName: String?,
        result: MethodChannel.Result
    ) {
        if (!ttsReady || tts == null || text.isBlank()) {
            emitVoiceEvent(mapOf("type" to "tts_done"))
            result.success(false)
            return
        }
        try {
            val parts = localeTag.replace("_", "-").split("-")
            val targetLocale = if (parts.size >= 2) Locale(parts[0], parts[1]) else Locale(parts[0])
            val langRes = tts?.setLanguage(targetLocale)
            if (langRes == TextToSpeech.LANG_MISSING_DATA || langRes == TextToSpeech.LANG_NOT_SUPPORTED) {
                if (parts[0].equals("ar", ignoreCase = true)) {
                    tts?.setLanguage(Locale("ar"))
                } else {
                    tts?.setLanguage(Locale.US)
                }
            }
            pickBestHumanVoice(targetLocale, voiceName)
            tts?.setSpeechRate(rate.coerceIn(0.55f, 1.8f))
            tts?.setPitch(pitch.coerceIn(0.75f, 1.35f))
            val utteranceId = UUID.randomUUID().toString()
            val cleanText = text.replace(Regex("[*#`_~]"), " ").trim()
            val clipped = if (cleanText.length > 3500) cleanText.substring(0, 3500) else cleanText
            tts?.speak(clipped, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
            result.success(true)
        } catch (e: Exception) {
            emitVoiceEvent(mapOf("type" to "tts_error", "message" to (e.message ?: "TTS error")))
            result.success(false)
        }
    }

    // ==================== NATIVE SPEECH RECOGNIZER IMPLEMENTATION ====================
    private fun startSpeechListening(localeTag: String, result: MethodChannel.Result) {
        mainHandler.post {
            try {
                if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                    result.success(false)
                    emitVoiceEvent(mapOf("type" to "error", "code" to -1, "message" to "Speech recognition service not available on this device."))
                    return@post
                }

                tts?.stop()
                speechRecognizer?.destroy()
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        emitVoiceEvent(mapOf("type" to "ready"))
                    }

                    override fun onBeginningOfSpeech() {
                        emitVoiceEvent(mapOf("type" to "speech_start"))
                    }

                    override fun onRmsChanged(rmsdB: Float) {
                        val normalized = ((rmsdB + 2.0f) / 12.0f).coerceIn(0.06f, 1.0f).toDouble()
                        emitVoiceEvent(mapOf("type" to "rms", "level" to normalized))
                    }

                    override fun onBufferReceived(buffer: ByteArray?) {}

                    override fun onEndOfSpeech() {
                        emitVoiceEvent(mapOf("type" to "speech_end"))
                    }

                    override fun onError(error: Int) {
                        val msg = when (error) {
                            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission required"
                            SpeechRecognizer.ERROR_NETWORK -> "Network error"
                            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                            SpeechRecognizer.ERROR_NO_MATCH -> "No speech matched"
                            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                            SpeechRecognizer.ERROR_SERVER -> "Server error"
                            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                            else -> "Speech error ($error)"
                        }
                        emitVoiceEvent(mapOf("type" to "error", "code" to error, "message" to msg))
                    }

                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val best = matches?.firstOrNull()?.trim() ?: ""
                        emitVoiceEvent(mapOf("type" to "final", "text" to best))
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val partial = matches?.firstOrNull()?.trim() ?: ""
                        if (partial.isNotEmpty()) {
                            emitVoiceEvent(mapOf("type" to "partial", "text" to partial))
                        }
                    }

                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeTag)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, localeTag)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1800L)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1400L)
                }

                speechRecognizer?.startListening(intent)
                result.success(true)
            } catch (e: Exception) {
                emitVoiceEvent(mapOf("type" to "error", "code" to -2, "message" to (e.message ?: "Failed to start recognizer")))
                result.success(false)
            }
        }
    }

    private fun emitVoiceEvent(payload: Map<String, Any>) {
        mainHandler.post {
            try {
                voiceEventSink?.success(payload)
            } catch (_: Exception) {}
        }
    }

    // ==================== PHONE APPS & DEVICE MANAGEMENT ====================
    private fun getInstalledLaunchableApps(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        try {
            val pm = packageManager
            val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(mainIntent, 0)
            }
            val seen = HashSet<String>()
            for (ri in resolved) {
                val pkg = ri.activityInfo?.packageName ?: continue
                if (pkg == packageName || !seen.add(pkg)) continue
                val label = ri.loadLabel(pm)?.toString()?.trim() ?: pkg
                list.add(mapOf("name" to label, "packageName" to pkg))
            }
            list.sortBy { it["name"]?.lowercase(Locale.ROOT) ?: "" }
        } catch (_: Exception) {}
        return list
    }

    private fun launchAppByQuery(rawQuery: String): Boolean {
        val q = rawQuery.trim().lowercase(Locale.ROOT)
        if (q.isEmpty()) return false
        try {
            // 1. Direct package name match
            packageManager.getLaunchIntentForPackage(rawQuery.trim())?.let { intent ->
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            }

            // 2. Common Arabic & English app aliases
            val aliasMap = mapOf(
                "whatsapp" to listOf("com.whatsapp", "com.whatsapp.w4b"),
                "واتساب" to listOf("com.whatsapp", "com.whatsapp.w4b"),
                "واتس" to listOf("com.whatsapp", "com.whatsapp.w4b"),
                "youtube" to listOf("com.google.android.youtube"),
                "يوتيوب" to listOf("com.google.android.youtube"),
                "instagram" to listOf("com.instagram.android"),
                "انستجرام" to listOf("com.instagram.android"),
                "انستا" to listOf("com.instagram.android"),
                "facebook" to listOf("com.facebook.katana", "com.facebook.lite"),
                "فيسبوك" to listOf("com.facebook.katana", "com.facebook.lite"),
                "الفيس" to listOf("com.facebook.katana", "com.facebook.lite"),
                "tiktok" to listOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill"),
                "تيك توك" to listOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill"),
                "telegram" to listOf("org.telegram.messenger", "org.telegram.messenger.web"),
                "تيليجرام" to listOf("org.telegram.messenger"),
                "chrome" to listOf("com.android.chrome"),
                "كروم" to listOf("com.android.chrome"),
                "maps" to listOf("com.google.android.apps.maps"),
                "خرائط" to listOf("com.google.android.apps.maps"),
                "gmail" to listOf("com.google.android.gm"),
                "جيميل" to listOf("com.google.android.gm"),
                "spotify" to listOf("com.spotify.music"),
                "سبوتيفاي" to listOf("com.spotify.music"),
                "calculator" to listOf("com.google.android.calculator", "com.sec.android.app.popupcalculator"),
                "حاسبة" to listOf("com.google.android.calculator", "com.sec.android.app.popupcalculator"),
                "camera" to listOf("com.android.camera", "com.sec.android.app.camera", "com.google.android.GoogleCamera"),
                "كاميرا" to listOf("com.android.camera", "com.sec.android.app.camera", "com.google.android.GoogleCamera"),
                "settings" to listOf("com.android.settings"),
                "اعدادات" to listOf("com.android.settings"),
                "الإعدادات" to listOf("com.android.settings")
            )

            for ((key, pkgs) in aliasMap) {
                if (q.contains(key)) {
                    for (pkg in pkgs) {
                        packageManager.getLaunchIntentForPackage(pkg)?.let { intent ->
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            return true
                        }
                    }
                }
            }

            // 3. Fuzzy search over all installed launchable apps
            val apps = getInstalledLaunchableApps()
            val match = apps.firstOrNull { app ->
                val name = (app["name"] ?: "").lowercase(Locale.ROOT)
                val pkg = (app["packageName"] ?: "").lowercase(Locale.ROOT)
                name.contains(q) || q.contains(name) || pkg.contains(q)
            }
            val pkg = match?.get("packageName") ?: return false
            val launchIntent = packageManager.getLaunchIntentForPackage(pkg) ?: return false
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
            return true
        } catch (_: Exception) {
            return false
        }
    }

    private fun openExternalUrl(url: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url.trim())).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openWhatsAppChat(phone: String, message: String): Boolean {
        return try {
            var clean = phone.replace(Regex("[^0-9+]"), "")
            if (clean.startsWith("0") && clean.length == 11) {
                clean = "2$clean" // Egypt country code helper
            }
            clean = clean.removePrefix("+")
            val encodedMsg = Uri.encode(message)
            val url = if (clean.isNotEmpty()) {
                "https://wa.me/$clean?text=$encodedMsg"
            } else {
                "https://wa.me/?text=$encodedMsg"
            }
            openExternalUrl(url)
        } catch (_: Exception) {
            false
        }
    }

    private fun dialNumber(phone: String): Boolean {
        return try {
            val clean = phone.replace(Regex("[^0-9+*#]"), "")
            val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$clean")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun composeSms(phone: String, message: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$phone")).apply {
                putExtra("sms_body", message)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun composeEmail(to: String, subject: String, body: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$to")).apply {
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun createAlarm(hour: Int, minute: Int, message: String): Boolean {
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, hour.coerceIn(0, 23))
                putExtra(AlarmClock.EXTRA_MINUTES, minute.coerceIn(0, 59))
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun createTimer(seconds: Int, message: String): Boolean {
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, seconds.coerceAtLeast(1))
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun launchMaps(query: String, navigate: Boolean): Boolean {
        return try {
            val uri = if (navigate) {
                Uri.parse("google.navigation:q=${Uri.encode(query)}")
            } else {
                Uri.parse("geo:0,0?q=${Uri.encode(query)}")
            }
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            openExternalUrl("https://www.google.com/maps/search/?api=1&query=${Uri.encode(query)}")
        }
    }

    private fun launchYoutubeSearch(query: String): Boolean {
        return openExternalUrl("https://www.youtube.com/results?search_query=${Uri.encode(query)}")
    }

    private fun openAndroidSettings(target: String): Boolean {
        val action = when (target.lowercase(Locale.ROOT)) {
            "wifi", "واي فاي" -> Settings.ACTION_WIFI_SETTINGS
            "bluetooth", "بلوتوث" -> Settings.ACTION_BLUETOOTH_SETTINGS
            "display", "الشاشة" -> Settings.ACTION_DISPLAY_SETTINGS
            "battery", "البطارية" -> Settings.ACTION_BATTERY_SAVER_SETTINGS
            "sound", "الصوت" -> Settings.ACTION_SOUND_SETTINGS
            "location", "الموقع" -> Settings.ACTION_LOCATION_SOURCE_SETTINGS
            "apps", "التطبيقات" -> Settings.ACTION_APPLICATION_SETTINGS
            else -> Settings.ACTION_SETTINGS
        }
        return try {
            val intent = Intent(action).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                val fallback = Intent(Settings.ACTION_SETTINGS).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                startActivity(fallback)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun setFlashlight(enabled: Boolean): Boolean {
        return try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            } ?: return false
            cameraManager.setTorchMode(cameraId, enabled)
            torchEnabled = enabled
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun readDeviceStatus(): Map<String, Any> {
        var batteryPct = -1
        var isCharging = false
        try {
            val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = registerReceiver(null, ifilter)
            val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level >= 0 && scale > 0) {
                batteryPct = (level * 100) / scale
            }
            val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL
        } catch (_: Exception) {}

        return mapOf(
            "batteryLevel" to batteryPct,
            "isCharging" to isCharging,
            "manufacturer" to (Build.MANUFACTURER ?: "Android"),
            "model" to (Build.MODEL ?: "Device"),
            "androidVersion" to (Build.VERSION.RELEASE ?: ""),
            "sdkInt" to Build.VERSION.SDK_INT,
            "torchEnabled" to torchEnabled
        )
    }

    private fun sharePlainText(text: String, subject: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, text)
            }
            val chooser = Intent.createChooser(intent, subject).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun saveImageBytesToGallery(bytes: ByteArray, fileName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Nimo")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                    ?: return false
                contentResolver.openOutputStream(uri)?.use { out ->
                    out.write(bytes)
                }
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
                true
            } else {
                @Suppress("DEPRECATION")
                val dir = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                    "Nimo"
                )
                if (!dir.exists()) dir.mkdirs()
                val file = File(dir, fileName)
                FileOutputStream(file).use { it.write(bytes) }
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    override fun onDestroy() {
        try {
            speechRecognizer?.destroy()
            tts?.stop()
            tts?.shutdown()
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
