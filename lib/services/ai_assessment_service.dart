import '../state/app_controller.dart';

class AiAssessment {
  const AiAssessment({
    required this.title,
    required this.summary,
    required this.nextSteps,
    required this.score,
  });

  final String title;
  final String summary;
  final List<String> nextSteps;
  final int score;
}

class AiAssessmentService {
  /// Offline coaching engine. It is deterministic and does not pretend to
  /// call an external LLM. A future API adapter can replace this service.
  static AiAssessment assess(AppController app) {
    final accuracy = app.quizAccuracy;
    final mastered = app.masteredVocabularyIds.length;
    final daily = app.dailyProgress;
    final score = ((accuracy * 55) + (daily * 25) + ((mastered.clamp(0, 1000) / 1000) * 20))
        .round()
        .clamp(0, 100)
        .toInt();

    if (accuracy >= .85 && daily >= .8) {
      return AiAssessment(
        title: 'Siap naik level',
        summary: 'Pola belajarmu konsisten dan akurasi kuis sudah kuat. Fokus berikutnya adalah mempertahankan recall tanpa melihat furigana.',
        score: score,
        nextSteps: const [
          'Kerjakan 10–20 soal tanpa furigana.',
          'Tambahkan latihan listening JFT setiap hari.',
          'Mulai simulasi penuh sesuai target level.',
        ],
      );
    }
    if (accuracy >= .65) {
      return AiAssessment(
        title: 'Fondasi bagus, perlu penguatan',
        summary: 'Kamu sudah memahami banyak materi, tetapi recall masih perlu pengulangan terjadwal.',
        score: score,
        nextSteps: const [
          'Ulangi kotoba yang salah hari ini.',
          'Latih perubahan bentuk: kamus → masu → nai → te → ta.',
          'Baca contoh kalimat keras-keras sambil mendengarkan TTS.',
        ],
      );
    }
    return AiAssessment(
      title: 'Bangun fondasi dulu',
      summary: 'Prioritasmu sekarang adalah memperkuat kosakata, partikel dasar, dan pola kalimat sebelum mengejar kecepatan.',
      score: score,
      nextSteps: const [
        'Belajar 15–25 kotoba baru lalu review.',
        'Kuasai は・が・を・に・で・と sebelum menambah pola sulit.',
        'Gunakan kuis pendek berulang daripada satu sesi panjang.',
      ],
    );
  }
}
