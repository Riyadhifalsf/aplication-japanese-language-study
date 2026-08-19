class TtsService {
  static const bool enabled = false;

  String _gender = 'auto';

  Future<void> setGender(String gender) async {
    if ({'auto', 'female', 'male'}.contains(gender)) _gender = gender;
  }

  Future<void> speak(String text, {String language = 'ja-JP'}) async {}

  Future<void> speakEnglish(String text) async {}

  Future<void> stop() async {}

  String get gender => _gender;
}
