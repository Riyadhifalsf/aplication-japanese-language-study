import 'package:flutter/services.dart';

/// Text-to-Speech Jepang (dan Inggris) via MethodChannel milik aplikasi
/// (`japanese_study/tts`, implementasi native di MainActivity memakai mesin
/// TextToSpeech bawaan Android — tanpa dependensi plugin eksternal).
///
/// Dipakai 40+ titik: audio listening lesson, bacaan kosakata/kanji,
/// contoh grammar, dialog. Profil suara dibuat "anime-like" dengan
/// voice Jepang yang tersedia di perangkat + pitch/rate yang sesuai.
/// Ini bukan cloning seiyuu/karakter berlisensi.
class TtsService {
  static const bool enabled = true;

  static const MethodChannel _channel = MethodChannel('japanese_study/tts');

  String _gender = 'auto';

  Future<void> setGender(String gender) async {
    if ({'auto', 'female', 'male'}.contains(gender)) {
      _gender = gender;
    }
  }

  Future<void> speak(String text, {String language = 'ja-JP'}) async {
    final input = text.trim();
    if (input.isEmpty) return;
    try {
      final isJapanese = language.toLowerCase().startsWith('ja');
      final profile = isJapanese ? _gender : 'auto';
      await _channel.invokeMethod<void>('speak', {
        'text': input,
        'language': language,
        'profile': profile,
        'rate': 0.45,
      });
    } catch (_) {
      // Native tidak tersedia: diam, jangan crash pemanggil.
    }
  }

  Future<void> speakEnglish(String text) =>
      speak(text, language: 'en-US');

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }

  String get gender => _gender;
}
