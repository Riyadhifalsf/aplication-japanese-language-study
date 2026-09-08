package com.babeh.japanese_study

import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

/// MethodChannel TTS milik aplikasi (tanpa dependensi plugin eksternal):
/// memakai mesin TextToSpeech bawaan Android. Aman dipanggil kapan saja;
/// bila engine tak tersedia, gagal diam di sisi native.
class MainActivity : FlutterActivity() {
    private val channelName = "japanese_study/tts"
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        val language = call.argument<String>("language") ?: "ja-JP"
                        val rate = (call.argument<Double>("rate") ?: 0.45).toFloat()
                        speak(text, language, rate)
                        result.success(null)
                    }
                    "stop" -> {
                        try {
                            tts?.stop()
                        } catch (_: Exception) {
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun ensureTts(onReady: () -> Unit) {
        val existing = tts
        if (existing != null && ttsReady) {
            onReady()
            return
        }
        try {
            tts = TextToSpeech(this) { status ->
                ttsReady = status == TextToSpeech.SUCCESS
                if (ttsReady) onReady()
            }
        } catch (_: Exception) {
            ttsReady = false
        }
    }

    private fun speak(text: String, language: String, rate: Float) {
        if (text.isBlank()) return
        ensureTts {
            try {
                val engine = tts ?: return@ensureTts
                val locale = Locale.forLanguageTag(language)
                val availability = engine.isLanguageAvailable(locale)
                if (availability != TextToSpeech.LANG_MISSING_DATA &&
                    availability != TextToSpeech.LANG_NOT_SUPPORTED
                ) {
                    engine.language = locale
                }
                engine.setSpeechRate(rate.coerceIn(0.1f, 2.0f))
                engine.speak(
                    text,
                    TextToSpeech.QUEUE_FLUSH,
                    null,
                    UUID.randomUUID().toString()
                )
            } catch (_: Exception) {
            }
        }
    }

    override fun onDestroy() {
        try {
            tts?.stop()
            tts?.shutdown()
        } catch (_: Exception) {
        }
        tts = null
        super.onDestroy()
    }
}
