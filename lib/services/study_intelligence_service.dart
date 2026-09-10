import '../state/app_controller.dart';

class StudyRecommendation {
  const StudyRecommendation({required this.action, required this.reason, required this.risk});
  final String action;
  final String reason;
  final double risk;
}

/// AI/recommendation layer tanpa halaman AI. Saat backend Python tersedia,
/// hasil service ini dapat diganti dengan response model server.
class StudyIntelligenceService {
  static StudyRecommendation recommend(AppController app) {
    final accuracy = app.quizAccuracy;
    final review = app.dueKanjiReviewCount;
    final studyDays = app.studyDateKeys.length;
    if (review >= 8) return const StudyRecommendation(action: 'review', reason: 'Banyak Kanji sudah jatuh tempo untuk diulang.', risk: .78);
    if (accuracy < .70 && app.quizAnswered >= 10) return const StudyRecommendation(action: 'practice_weak_topics', reason: 'Akurasi kuis masih rendah; ulangi materi sebelum maju.', risk: .72);
    if (studyDays < 3) return const StudyRecommendation(action: 'continue_path', reason: 'Bangun ritme belajar dulu dengan mengikuti lesson berikutnya.', risk: .55);
    return const StudyRecommendation(action: 'advance', reason: 'Progress cukup stabil; lanjutkan path dan review.', risk: .22);
  }
}
