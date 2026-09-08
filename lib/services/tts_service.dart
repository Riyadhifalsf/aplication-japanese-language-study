import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech Jepang (dan Inggris) via mesin TTS perangkat.
///
/// Dipakai 40+ titik: audio listening lesson, bacaan kosakata/kanji,
/// contoh grammar, dialog. Semua pemanggilan aman: bila mesin TTS tidak
/// tersedia (emulator tanpa engine / platform tak didukung), gagal diam
/// tanpa crash — UI tidak boleh mengasumsikan audio selalu berbunyi.
class TtsService {
  static const bool enabled = true;

  FlutterTts? _tts;
  bool _ready = false;

  String _gender = 'auto';

  Future<void> _ensure() async {
    if (_ready && _tts != null) return;
    try {
      final tts = FlutterTts();
      await tts.setLanguage('ja-JP');
      await tts.setSpeechRate(0.45);
      await tts.setPitch(1.0);
      _tts = tts;
      _ready = true;
    } catch (_) {
      _tts = null;
      _ready = false;
    }
  }

  Future<void> setGender(String gender) async {
    if ({'auto', 'female', 'male'}.contains(gender)) _gender = gender;
  }

  Future<void> speak(String text, {String language = 'ja-JP'}) async {
    final input = text.trim();
    if (input.isEmpty) return;
    try {
      await _ensure();
      final tts = _tts;
      if (!_ready || tts == null) return;
      await tts.setLanguage(language);
      await tts.stop();
      await tts.speak(input);
    } catch (_) {
      // Mesin TTS tak tersedia: diam, jangan crash pemanggil.
    }
  }

  Future<void> speakEnglish(String text) =>
      speak(text, language: 'en-US');

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  String get gender => _gender;
}
