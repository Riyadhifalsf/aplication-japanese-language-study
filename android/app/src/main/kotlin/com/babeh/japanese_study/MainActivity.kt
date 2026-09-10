package com.babeh.japanese_study

import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.Voice
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

/// MethodChannel TTS milik aplikasi (tanpa dependensi plugin eksternal):
/// memakai mesin TextToSpeech bawaan Android. Profil suara dibuat lebih
/// anime-like menggunakan voice Jepang yang tersedia + pitch/rate.
/// Tidak mengkloning suara seiyuu/karakter tertentu.
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
                        val profile = call.argument<String>("profile") ?: "auto"
                        speak(text, language, rate, profile)
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

    private fun chooseJapaneseVoice(engine: TextToSpeech, profile: String): Voice? {
        val voices = try {
            engine.voices?.filter { it.locale.language.equals("ja", ignoreCase = true) }
        } catch (_: Exception) {
            null
        } ?: return null

        if (voices.isEmpty()) return null

        // Prioritaskan voice lokal (tidak membutuhkan network).
        val local = voices.filter { !it.isNetworkConnectionRequired }
        val candidates = if (local.isNotEmpty()) local else voices

        val keywords = when (profile) {
            "female" -> listOf("female", "woman", "girl", "japanese")
            "male" -> listOf("male", "man", "boy", "japanese")
            else -> listOf("japanese")
        }

        return candidates
            .sortedWith(compareByDescending<Voice> { voice ->
                val name = voice.name.lowercase(Locale.US)
                keywords.count { name.contains(it) }
            }.thenByDescending { it.quality }
                .thenBy { it.latency })
            .firstOrNull()
    }

    private fun speak(text: String, language: String, rate: Float, profile: String) {
        if (text.isBlank()) return
        ensureTts {
            try {
                val engine = tts ?: return@ensureTts
                val locale = Locale.forLanguageTag(language)
                val availability = engine.isLanguageAvailable(locale)
                if (availability == TextToSpeech.LANG_MISSING_DATA ||
                    availability == TextToSpeech.LANG_NOT_SUPPORTED
                ) return@ensureTts

                engine.language = locale

                if (locale.language.equals("ja", ignoreCase = true)) {
                    chooseJapaneseVoice(engine, profile)?.let { engine.voice = it }
                }

                val safeRate = when (profile) {
                    // Lebih ringan/ceria untuk pembelajaran sehari-hari.
                    "female" -> (rate * 1.04f).coerceIn(0.35f, 0.62f)
                    // Sedikit tegas dan stabil untuk voice laki-laki.
                    "male" -> (rate * 0.98f).coerceIn(0.35f, 0.60f)
                    else -> rate.coerceIn(0.35f, 0.60f)
                }
                val pitch = when (profile) {
                    "female" -> 1.18f
                    "male" -> 0.92f
                    else -> 1.04f
                }

                engine.setSpeechRate(safeRate)
                engine.setPitch(pitch)
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
