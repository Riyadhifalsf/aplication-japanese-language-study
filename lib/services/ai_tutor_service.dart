import '../features/learning/domain/learning_models.dart';

/// Response dari AI Tutor (Sensei) untuk UI.
class AIResponse {
  const AIResponse({
    required this.explanation,
    required this.example,
    required this.hint,
    required this.correction,
    required this.transferTask,
    required this.isComplete,
  });

  final String explanation;
  final String example;
  final String hint;
  final String correction;
  final String transferTask;
  final bool isComplete;
}

/// Layanan AI Sensei — DINONAKTIFKAN sementara.
///
/// Fokus aplikasi sekarang: CONTENT + LEARNING PATH + PRACTICE + REVIEW.
/// File ini dipertahankan sebagai struktur internal agar bisa dikembangkan
/// kembali tanpa dependensi LLM/API baru. Semua entry point mengembalikan
/// respons "disabled" dan tidak memanggil jaringan.
///
/// Jangan menampilkan AI Sensei / AI Tutor / Chat AI di UI.
class AiTutorService {
  AiTutorService._();

  /// Selalu false sampai fitur diaktifkan kembali secara resmi.
  static bool get enabled => false;

  static const _disabled = AIResponse(
    explanation: 'AI Sensei sedang nonaktif.',
    example: '',
    hint: 'Ikuti materi lesson dan latihan yang tersedia.',
    correction: '',
    transferTask: '',
    isComplete: true,
  );

  static AIResponse grammarTutor({
    required String conceptId,
    required String learnerLevel,
    required LearningSkill skill,
    required bool isCorrect,
    Map<String, double>? mastery,
    List<String>? errorHistory,
  }) =>
      _disabled;

  static AIResponse vocabularyTutor({
    required String conceptId,
    required String learnerLevel,
    required LearningSkill skill,
    required bool isCorrect,
    Map<String, double>? mastery,
    List<String>? errorHistory,
  }) =>
      _disabled;

  static AIResponse kanjiTutor({
    required String conceptId,
    required String learnerLevel,
    required LearningSkill skill,
    required bool isCorrect,
    Map<String, double>? mastery,
    List<String>? errorHistory,
  }) =>
      _disabled;

  static AIResponse generalTutor({
    required String prompt,
    required String learnerLevel,
    required LearningSkill skill,
  }) =>
      _disabled;
}
