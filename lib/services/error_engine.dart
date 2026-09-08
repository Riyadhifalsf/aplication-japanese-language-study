import '../features/learning/domain/learning_models.dart';

/// Kategori error sesuai rule 17: bukan sekadar wrong=true
///
/// Setiap kategori mewakili alasan kegagalan yang berbeda
/// dan memerlukan remediasi yang berbeda.
enum ErrorCategory {
  recognition,     // User tidak bisa mengenali/menghafal input
  retrieval,       // User tahu tapi tidak bisa mengingat saat dibutuhkan
  production,      // User kesulitan menghasilkan/menyampaikan
  parsing,         // User kesulitan menganalisis/menstruktur input
  listening,       // Error terkait pemahaman mendengar
  lexical,         // Error terkait kata/kosa kata
  pragmatic,       // Error terkait penggunaan sopan/konteks
  transfer,        // User tidak bisa menerapkan knowledge ke konteks baru
  latency;         // Terlalu lambat merespons/waktu habis

  String get label => switch (this) {
        ErrorCategory.recognition => 'Pengenalan',
        ErrorCategory.retrieval => 'Pengingatan',
        ErrorCategory.production => 'Produksi',
        ErrorCategory.parsing => 'Parsing/Struktur',
        ErrorCategory.listening => 'Listening',
        ErrorCategory.lexical => 'Kosakata',
        ErrorCategory.pragmatic => 'Pragmatik',
        ErrorCategory.transfer => 'Transfer',
        ErrorCategory.latency => 'Latency',
      };
}

/// Record kesalahan yang detail untuk engine error dan remediation.
///
/// Menyimpan tidak hanya jawaban salah tapi kategori error,
/// analisis root cause, dan tindakan remediasi yang sesuai.
class ErrorRecord {
  ErrorRecord({
    required this.conceptId,
    required this.skill,
    required this.errorCategory,
    required this.prompt,
    required this.userAnswer,
    required this.correctAnswer,
    this.mistakeCount = 1,
    DateTime? occurredAt,
    this.rootCauseAnalysis,
    this.remediationSuggested,
    this.transferTask,
  }) : occurredAt = occurredAt ?? DateTime.now();

  final String conceptId;
  final LearningSkill skill;
  final ErrorCategory errorCategory;
  final String prompt;
  final String userAnswer;
  final String correctAnswer;
  final int mistakeCount;
  final DateTime occurredAt;
  final String? rootCauseAnalysis;
  final String? remediationSuggested;
  final String? transferTask;

  Map<String, Object> toJson() => {
        'conceptId': conceptId,
        'skill': skill.name,
        'errorCategory': errorCategory.name,
        'prompt': prompt,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'mistakeCount': mistakeCount,
        'occurredAt': occurredAt.toIso8601String(),
        'rootCauseAnalysis': rootCauseAnalysis,
        'remediationSuggested': remediationSuggested,
        'transferTask': transferTask,
      };

  static ErrorRecord fromJson(Object? raw) {
    if (raw is! Map) return ErrorRecord(
      conceptId: '',
      skill: LearningSkill.vocabulary,
      errorCategory: ErrorCategory.recognition,
      prompt: '',
      userAnswer: '',
      correctAnswer: '',
      mistakeCount: 1,
    );

    final category = ErrorCategory.values.where((e) => e.name == raw['errorCategory']);
    final skill = LearningSkill.fromName(raw['skill']);

    return ErrorRecord(
      conceptId: '${raw['conceptId'] ?? ''}'.trim(),
      skill: skill ?? LearningSkill.vocabulary,
      errorCategory: category.isEmpty ? ErrorCategory.recognition : category.first,
      prompt: '${raw['prompt'] ?? ''}'.trim(),
      userAnswer: '${raw['userAnswer'] ?? ''}'.trim(),
      correctAnswer: '${raw['correctAnswer'] ?? ''}'.trim(),
      mistakeCount: ((raw['mistakeCount'] as num?) ?? 1).toInt().clamp(1, 1000000),
      occurredAt: DateTime.tryParse('${raw['occurredAt'] ?? ''}') ??
          DateTime.now(),
      rootCauseAnalysis: raw['rootCauseAnalysis'] as String?,
      remediationSuggested: raw['remediationSuggested'] as String?,
      transferTask: raw['transferTask'] as String?,
    );
  }
}

/// Analisis root cause error berdasarkan kategori dan data mastery.
///
/// Menentukan faktor mengapa learner salah berdasarkan:
/// - skor mastery sebelumnya
/// - jenis soal
/// - pattern kesalahan
String analyzeErrorRootCause(
    ErrorCategory category,
    double masteryScore,
    LearningSkill skill,
    {String? lessonContext}) {
  switch (category) {
    case ErrorCategory.recognition:
      return masteryScore < 50
          ? 'Kemampuan pengenalan masih rendah - butuh flashcard mendasar'
          : 'Kakuan cukup - fokus pada pengenalan konteks';

    case ErrorCategory.retrieval:
      return masteryScore < 60
          ? 'Kata terpelajari tapi suling diingat - praktik retrieval terpadu'
          : 'Penggunaan antre review SRS untuk memperkuat ingatan';

    case ErrorCategory.production:
      return masteryScore < 70
          ? 'Kakuan ada tapi kesulitan menghasilkan - latihan produksi terarah'
          : 'Keterlambatan jawaban - latihan dengan time limit';

    case ErrorCategory.parsing:
      return 'Kesulitan menganalisis struktur kalimat - review aturan grammar'
          'dan pattern parsing';

    case ErrorCategory.listening:
      return 'Kesulitan listening - dengarkan audio lambat berulang kali'
          'dan latihan identifikasi kata kunci';

    case ErrorCategory.lexical:
      return 'Kesulitan kosakata - perbanyak exposure vocabulary dan'
          'flashcard per kata';

    case ErrorCategory.pragmatic:
      return 'Kesulitan penggunaan sopan/konteks - study contoh situasional'
          'dan perbedaan formal/informal';

    case ErrorCategory.transfer:
      return 'Tidak bisa menerapkan knowledge ke konteks baru - berikan'
          'transfer task dengan konteks berbeda namun mirip';

    case ErrorCategory.latency:
      return 'Terlalu lambat merespons - latihan dengan constraint waktu'
          'dan incrementally meningkatkan kecepatan';
  }
}

/// Sarankan remediasi terstruktur berdasarkan kategori error.
///
/// Mengembalikan daftar langkah remediasi yang dapat langsung digunakan
/// oleh UI atau learning engine untuk scheduled remediation.
List<String> suggestRemediation(ErrorCategory category,
    {required double masteryScore,
    required LearningSkill skill,
    required String conceptId}) {
  final suggestions = <String>[];

  switch (category) {
    case ErrorCategory.recognition:
      suggestions.addAll([
        'Lakukan 10 flashcard konsep utama',
        'Review penjelasan grammar/artian',
        'Latih mengenali dalam berbagai konteks',
        'Sulit? Tandai sebagai "learning" ulang',
      ]);
      break;

    case ErrorCategory.retrieval:
      suggestions.addAll([
        'Latihan retrieval terpadu (active recall)',
        'Spaced repetition dengan interval 1-3-7-14 hari',
        'Latih tanpa bantuan pilihan ganda',
        'Review review state yang jatuh tempo',
      ]);
      break;

    case ErrorCategory.production:
      suggestions.addAll([
        'Latih menghasilkan jawaban tanpa opsi',
        'Shadowing untuk speaking',
        'Tulis kalimat menggunakan konsep',
        'Record diri dan bandingkan',
      ]);
      break;

    case ErrorCategory.parsing:
      suggestions.addAll([
        'Review aturan grammar detail',
        'Latihan parsing soal step-by-step',
        'Analisis struktur kalimat soal',
        'Latih dengan soal ordering',
      ]);
      break;

    case ErrorCategory.listening:
      suggestions.addAll([
        'Dengarkan audio berulang kali',
        'Latih identifikasi kata kunci',
        'Gambar mental apa yang dengar',
        'Latihan dengan speaker yang berbeda',
      ]);
      break;

    case ErrorCategory.lexical:
      suggestions.addAll([
        'Flashcard kosakata per hari',
        'Latih menemukan kamus konteks',
        'Review antonyms/synonyms',
        'Latih kata dalam kalimat',
      ]);
      break;

    case ErrorCategory.pragmatic:
      suggestions.addAll([
        'Study contoh situasional',
        'Latih perbedaan formal/informal',
        'Review peraturan etiket komunikasi',
        'Latihan dialog sehari-hari',
      ]);
      break;

    case ErrorCategory.transfer:
      suggestions.addAll([
        'Berikan transfer task konteks baru',
        'Latih konsep dalam situasi berbeda',
        'Hubungkan dengan knowledge sebelumnya',
        'Review prerequisite lesson',
      ]);
      break;

    case ErrorCategory.latency:
      suggestions.addAll([
        'Latih dengan constraint waktu',
        'Incremental speed increase',
        'Latihan soal timed',
        'Tracking latency per soal',
      ]);
      break;
  }

  // Tambahkan general advice berdasarkan mastery
  if (masteryScore < 50) {
    suggestions.insert(0, 'Mastery belum mencapai 50% - butuh review fundamental sebelum lanjut');
  } else if (masteryScore < 70) {
    suggestions.insert(0, 'Mastery 50-70% - butuh interleaving dengan konsep lama');
  }

  return suggestions;
}

/// Dapatkan catatan error terkumpul untuk seorang learner.
/// Mengembalikan list ErrorRecord yang dapat di-analisis untuk pattern dan remediation.
class ErrorEngine {
  ErrorEngine._();

  /// Tambah error record baru ke database/state.
  static ErrorRecord addError({
    required String conceptId,
    required LearningSkill skill,
    required String prompt,
    required String userAnswer,
    required String correctAnswer,
    ErrorCategory? category,
  }) {
    final errorCategory = category ?? _detectCategory(skill, userAnswer, correctAnswer);
    return ErrorRecord(
      conceptId: conceptId,
      skill: skill,
      errorCategory: errorCategory,
      prompt: prompt,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      mistakeCount: 1,
    );
  }

  /// Deteksi kategori error otomatis berdasarkan jawaban user.
  static ErrorCategory _detectCategory(
      LearningSkill skill, String userAnswer, String correctAnswer) {
    // Logika sederhana: bandingkan user answer dengan correct answer
    // dan tentukan kategori berdasarkan pattern

    final answerMatch = userAnswer.toLowerCase().trim() ==
        correctAnswer.toLowerCase().trim();

    if (answerMatch) {
      return ErrorCategory.recognition; // Seharusnya tidak terjadi tapi untuk safety
    }

    // Cek pattern kesalahan umum
    final userLower = userAnswer.toLowerCase();
    final correctLower = correctAnswer.toLowerCase();

    // Jika user menukar partikel (wa/no/ga <-> mo/to/ni)
    final particleSwap = _checkParticleSwap(userLower, correctLower);
    if (particleSwap != null) return ErrorCategory.production;

    // Jika user jawaban benar grammatically tapi salah konteks
    if (_checkContextualError(userLower, correctLower)) {
      return ErrorCategory.pragmatic;
    }

    // Default ke retrieval jika user kemungkinan tahu tapi salah answer
    return ErrorCategory.retrieval;
  }

  /// Cek apakah kesalahan karena tukar partikel
  static bool? _checkParticleSwap(String user, String correct) {
    // Partikel N5 common: wa/no/ga/mo/to
    final particles = {'wa': 'no', 'no': 'wa', 'ga': 'to', 'mo': 'to', 'to': 'mo'};
    for (final p in particles.keys) {
      if (user.contains(p) && correct.contains(particles[p])) return true;
      if (user.contains(particles[p]) && correct.contains(p)) return true;
    }
    return null;
  }

  /// Cek apakah kesalahan kontekstual (sopan/tidak sopan)
  static bool? _checkContextualError(String user, String correct) {
    // Jika user menggunakan form informal di konteks formal atau sebaliknya
    final informalPatterns = {'omu', 'omae', 'kimitte', 'teineigo'};
    final isUserInformal = informalPatterns.any((p) => user.contains(p));
    final isCorrectInformal = informalPatterns.any((p) => correct.contains(p));

    if (isUserInformal != isCorrectInformal) return isUserInformal;
    return null;
  }

  /// Ambil error records untuk sebuah concept
  static List<ErrorRecord> getErrorsForConcept(String conceptId,
      {LearningSkill? skillFilter}) {
    // Di implementasi nyata ini akan membaca dari database/state
    // Untuk sekarang kembalikan list kosong dengan struktur yang benar
    return [];
  }

  /// Analisis pattern error untuk seorang learner
  static Map<String, int> analyzeErrorPatterns(
      {required List<ErrorRecord> errors,
      required LearningSkill skill}) {
    final categoryCounts = <ErrorCategory, int>{};
    for (final error in errors) {
      if (error.skill == skill) {
        categoryCounts[error.errorCategory] =
            (categoryCounts[error.errorCategory] ?? 0) + 1;
      }
    }

    // Return map ErrorCategory -> count
    return categoryCounts..putIfAbsent(ErrorCategory.recognition, (_) => 0);
  }

  /// Dapatkan rekomendasi remediation berdasarkan analyzed errors
  static List<String> getRemediationRecommendations(
      {required List<ErrorRecord> errors,
      required LearningSkill skill,
      required Map<String, int> errorCounts}) {
    final recommendations = <String>[];

    // Urutkan kategori berdasarkan frekuensi
    final sortedCategories = errorCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => errorCounts[b]!.compareTo(errorCounts[a]!));

    for (final category in sortedCategories) {
      final categoryRecs = suggestRemediation(
        category,
        masteryScore: 65.0, // default, akan digantikan oleh mastery aktual
        conceptId: errors.isNotEmpty ? errors.first.conceptId : '',
        skill: skill,
      );
      recommendations.addAll(categoryRecs);
    }

    return recommendations;
  }
}

/// SRS (Spaced Repetition Parameters) berdasarkan error dan mastery.
///
/// Menentukan kapan item perlu diulang berdasarkan:
/// - mastery score
/// - error category frequency
/// - latency (waktu response)
/// - last review date
class SRSEngine {
  SRSEngine._();

  /// Hitung stability days berdasarkan error pattern dan mastery
  static double calculateStability(
      {required double masteryScore,
      required int mistakeCount,
      required ErrorCategory? dominantError,
      required int reviewCount}) {
    // Base stability dari mastery score
    double baseStability = masteryScore / 100.0 * 365; // max 365 days

    // Kurangi stability berdasarkan mistake count
    final mistakePenalty = mistakeCount * 3; // setiap mistake kurangi 3 hari

    // Kurangi berdasarkan error category dominan
    final errorPenalty = dominantError != null
        ? _errorPenaltyByCategory(dominantError)
        : 0;

    final stability = (baseStability - mistakePenalty - errorPenalty)
        .clamp(0.5, 3650)
        .toDouble();

    return stability;
  }

  /// Penalty berdasarkan kategori error dominan
  static double _errorPenaltyByCategory(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.recognition:
        return 30; // kesulitan pengenalan = waktu review lebih sering
      case ErrorCategory.retrieval:
        return 20; // kesulitan mengingat
      case ErrorCategory.production:
        return 15; // kesulitan menghasilkan
      case ErrorCategory.parsing:
        return 25; // kesulitan struktur
      case ErrorCategory.listening:
        return 18; // listening khusus
      case ErrorCategory.lexical:
        return 15; // kosakata
      case ErrorCategory.pragmatic:
        return 20; // pragmatic
      case ErrorCategory.transfer:
        return 10; // transfer
      case ErrorCategory.latency:
        return 25; // latency = review lebih sering
    }
  }

  /// Hitung next review date berdasarkan stability dan review history
  static DateTime calculateNextReview({
    required DateTime lastReviewAt,
    required double stabilityDays,
    required int lapseCount,
    required int reviewCount,
  }) {
    // Jika sudah banyak lapse, kurangi stability
    final lapseFactor = lapseCount > 3 ? 0.5 : 1.0;
    final adjustedStability = stabilityDays * lapseFactor;

    // Jika review count banyak, kemungkinan sudah mature
    final reviewFactor = reviewCount >= 6 ? 0.8 : 1.0;
    final finalStability = adjustedStability * reviewFactor;

    return lastReviewAt.add(Duration(days: finalStability.ceil()));
  }
}