import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _configuredJa = false;
  bool _configuredEn = false;
  String _gender = 'auto';

  Future<void> setGender(String gender) async {
    if (!{'auto', 'female', 'male'}.contains(gender)) return;
    _gender = gender;
    await _configure('ja-JP');
    await _tts.setPitch(_gender == 'female' ? 1.15 : _gender == 'male' ? .88 : 1.0);
  }

  Future<void> speak(String text, {String language = 'ja-JP'}) async {
    if (text.trim().isEmpty) return;
    await _configure(language);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakEnglish(String text) => speak(text, language: 'en-US');

  Future<void> stop() => _tts.stop();

  Future<void> _configure(String language) async {
    final configured = language.startsWith('en') ? _configuredEn : _configuredJa;
    if (configured) {
      await _tts.setPitch(_gender == 'female' ? 1.15 : _gender == 'male' ? .88 : 1.0);
      return;
    }
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(language.startsWith('en') ? .45 : .42);
    await _tts.setPitch(_gender == 'female' ? 1.15 : _gender == 'male' ? .88 : 1.0);
    if (language.startsWith('en')) {
      _configuredEn = true;
    } else {
      _configuredJa = true;
    }
  }
}
