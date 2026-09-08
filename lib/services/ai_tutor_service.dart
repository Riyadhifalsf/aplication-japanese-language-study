import '../features/learning/domain/learning_models.dart';
import '../features/curriculum/curriculum_catalog.dart';
import '../features/learning/data/japanese_curriculum.dart';

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

/// Layanan AI Sensei yang memberikan pengalaman belajar interaktif.
///
/// Berbeda dengan `AiAssessmentService` yang hanya memberikan skor,
/// service ini berperilaku seperti tutor:
/// - menjelaskan konsep;
/// - memberi contoh;
/// - memberikan hint bertahap;
/// - melakukan correction;
/// - meminta learner mencoba lagi;
/// - membuat transfer task.
///
/// Semua prompt disesuaikan dengan level learner, mastery, dan error history.
class AiTutorService {
  AiTutorService._();

  /// Dapatkan respons AI untuk pertanyaan grammar.
  ///
  /// [conceptId] merujuri ke GrammarPoint di curriculum.
  /// [learnerLevel] level saat ini pengguna (N5, N4, dst).
  /// [skill] skill yang ditargetkan.
  /// [isCorrect] apakah jawaban sebelumnya benar.
  static AIResponse grammarTutor({
    required String conceptId,
    required String learnerLevel,
    required LearningSkill skill,
    required bool isCorrect,
    Map<String, double>? mastery,
    List<String>? errorHistory,
  }) {
    // Ambil data grammar dari curriculum
    final lesson = CurriculumCatalogData.lessonById(conceptId);
    if (lesson == null) {
      return _fallbackGrammarResponse(learnerLevel, skill);
    }

    final grammarPoint = lesson.contents
        .where((c) => c.skill == LearningSkill.grammar)
        .firstOrNull;

    if (grammarPoint == null) {
      return _fallbackGrammarResponse(learnerLevel, skill);
    }

    // Deterministic response based on mastery and correctness
    final masteryScore = mastery?.values
            .where((s) => s is num && s is! String)
            .map((e) => (e as num).toDouble())
            .reduce((a, b) => a + b) / mastery.length ??
        0;

    String explanation, example, hint, correction, transferTask;

    if (isCorrect) {
      // User menjawab benar - reinforcement & transfer
      explanation = _buildExplanation(
          'Jawabanmu benar! ${grammarPoint.explanation}',
          learnerLevel);
      example = _buildExample(grammarPoint, learnerLevel, 'positive');
      hint = '';
      correction = '';
      transferTask = _buildTransferTask(grammarPoint, learnerLevel);
    } else {
      // User salah - diagnose & correct
      final weakness = errorHistory?.isNotEmpty == true
          ? errorHistory!.first
          : _detectCommonWeakness(skill, masteryScore);

      explanation = _buildExplanation(
          'Jawaban yang tepat adalah: ${grammarPoint.title}. '
          '${grammarPoint.explanation}',
          learnerLevel,
          weakness: weakness);
      example = _buildExample(grammarPoint, learnerLevel, 'withError');
      hint = _buildHint(grammarPoint, skill, learnerLevel);
      correction = _buildCorrection(grammarPoint, skill, learnerLevel);
      transferTask = _buildTransferTask(grammarPoint, learnerLevel,
          focus: 'remediation');
    }

    return AIResponse(
      explanation: explanation,
      example: example,
      hint: hint,
      correction: correction,
      transferTask: transferTask,
      isComplete: true,
    );
  }

  /// Dapatkan respons AI untuk pertanyaan vocabulary.
  static AIResponse vocabularyTutor({
    required String conceptId,
    required String learnerLevel,
    required LearningSkill skill,
    required bool isCorrect,
    Map<String, double>? mastery,
    List<String>? errorHistory,
  }) {
    final lesson = CurriculumCatalogData.lessonById(conceptId);
    if (lesson == null) {
      return _fallbackVocabResponse(learnerLevel, skill);
    }

    final vocabItem = lesson.contents
        .where((c) => c.skill == LearningSkill.vocabulary)
        .firstOrNull;

    if (vocabItem == null) {
      return _fallbackVocabResponse(learnerLevel, skill);
    }

    final isKnown = masteryScore(mastery) >= 80;

    String explanation, example, hint, correction, transferTask;

    if (isCorrect) {
      explanation = _buildExplanation(
          'Bagus! Kamu mengingat ${vocabItem.title} dengan benar. '
          '${vocabItem.explanation}',
          learnerLevel);
      example = _buildExample(vocabItem, learnerLevel, 'positive');
      hint = '';
      correction = '';
      transferTask = _buildTransferTask(vocabItem, learnerLevel);
    } else {
      final currentScore =
          mastery?.entries.fold<double>(0, (sum, e) => sum + (e.value as num).toDouble()) /
              mastery.length ??
              0;

      explanation = _buildExplanation(
          '${vocabItem.title} berarti: ${vocabItem.explanation}. '
          'Catatan: hindari conflation dengan kata mirip.',
          learnerLevel,
          weakness: _detectVocabWeakness(currentScore));
      example = _buildExample(vocabItem, learnerLevel, 'review');
      hint = _buildVocabHint(vocabItem, learnerLevel);
      correction = _buildVocabCorrection(vocabItem);
      transferTask = _buildTransferTask(vocabItem, learnerLevel,
          focus: 'vocab_retention');
    }

    return AIResponse(
      explanation: explanation,
      example: example,
      hint: hint,
      correction: correction,
      transferTask: transferTask,
      isComplete: true,
    );
  }

  /// Dapatkan respons AI untuk pertanyaan kanji.
  static AIResponse kanjiTutor({
    required String character,
    required String learnerLevel,
    required bool isCorrect,
    Map<String, dynamic>? kanjiData,
  }) {
    final onyomi = kanjiData?['onyomi'] ?? '';
    final kunyomi = kanjiData?['kunyomi'] ?? '';
    final meaning = kanjiData?['meaning'] ?? '';

    String explanation, example, hint, correction, transferTask;

    if (isCorrect) {
      explanation = _buildExplanation(
          'Tepat! Kanji $character berarti: $meaning',
          learnerLevel);
      example = _buildKanjiExample(character, onyomi, kunyomi, learnerLevel);
      hint = '';
      correction = '';
      transferTask = 'Gunakan kanji ini dalam kalimat tentang ${_kanjiTopic(character)}';
    } else {
      explanation = _buildExplanation(
          'Kanji $character memiliki makna: $meaning.\n'
          'On-yomi: $onyomi | Kun-yomi: $kunyomi',
          learnerLevel);
      example = _buildKanjiExample(character, onyomi, kunyomi, learnerLevel,
          review: true);
      hint = _buildKanjiHint(character, onyomi, kunyomi, learnerLevel);
      correction = _buildKanjiCorrection(character, onyomi, kunyomi);
      transferTask = 'Latihan menulis goresan kanji $character';
    }

    return AIResponse(
      explanation: explanation,
      example: example,
      hint: hint,
      correction: correction,
      transferTask: transferTask,
      isComplete: true,
    );
  }

  /// Dapatkan respons AI untuk pertanyaan general (contoh kalimat, dll).
  static AIResponse generalTutor({
    required String prompt,
    required String learnerLevel,
    required LearningSkill skill,
  }) {
    // Fallback berdasarkan skill dan level
    final levelLower = learnerLevel.toLowerCase();

    String explanation, example, hint, correction, transferTask;

    switch (skill) {
      case LearningSkill.grammar:
        explanation = _grammarExplanation(prompt, learnerLevel);
        example = _grammarExample(prompt, learnerLevel);
        hint = _grammarHint(prompt, learnerLevel);
        correction = _grammarCorrection(prompt);
        transferTask = 'Coba buat kalimat sendiri dengan pola ini';
        break;
      case LearningSkill.vocabulary:
        explanation = _vocabExplanation(prompt, learnerLevel);
        example = _vocabExample(prompt, learnerLevel);
        hint = _vocabHint(prompt, learnerLevel);
        correction = _vocabCorrection(prompt);
        transferTask = 'Latih kata ini dalam konteks sehari-hari';
        break;
      case LearningSkill.kanji:
        explanation = _kanjiExplanation(prompt, learnerLevel);
        example = _kanjiExample(prompt, learnerLevel);
        hint = _kanjiHint(prompt, learnerLevel);
        correction = _kanjiCorrection(prompt);
        transferTask = 'Latihan membaca/menulis kanji ini';
        break;
      case LearningSkill.listening:
        explanation = _listeningExplanation(prompt, learnerLevel);
        example = _listeningExample(prompt, learnerLevel);
        hint = _listeningHint(prompt, learnerLevel);
        correction = _listeningCorrection(prompt);
        transferTask = 'Dengarkan audio lagi dan fokus pada kata kunci';
        break;
      case LearningSkill.reading:
        explanation = _readingExplanation(prompt, learnerLevel);
        example = _readingExample(prompt, learnerLevel);
        hint = _readingHint(prompt, learnerLevel);
        correction = _readingCorrection(prompt);
        transferTask = 'Baca teks pendek dan temukan ide utama';
        break;
      case LearningSkill.speaking:
        explanation = _speakingExplanation(prompt, learnerLevel);
        example = _speakingExample(prompt, learnerLevel);
        hint = _speakingHint(prompt, learnerLevel);
        correction = _speakingCorrection(prompt);
        transferTask = 'Latih dengan TTS dan bandingkan';
        break;
      case LearningSkill.writing:
        explanation = _writingExplanation(prompt, learnerLevel);
        example = _writingExample(prompt, learnerLevel);
        hint = _writingHint(prompt, learnerLevel);
        correction = _writingCorrection(prompt);
        transferTask = 'Tulis paragraf singkat menggunakan kata kunci';
        break;
      default:
        explanation = 'Maaf, saya sedang memfokuskan pada materi '${learnerLevel}'.';
        example = '';
        hint = '';
        correction = '';
        transferTask = '';
    }

    return AIResponse(
      explanation: explanation,
      example: example,
      hint: hint,
      correction: correction,
      transferTask: transferTask,
      isComplete: true,
    );
  }

  // ---- Helper methods ----

  static double masteryScore(Map<String, double>? mastery) {
    if (mastery == null || mastery.isEmpty) return 0;
    return mastery.entries
        .map((e) => (e.value as num).toDouble())
        .reduce((a, b) => a + b) /
        mastery.length;
  }

  static String _buildExplanation(String base, String level,
      {String? weakness}) {
    final levelSuffix = _levelSuffix(level);
    final wSuffix = weakness != null
        ? ' Masalah umum: $weakness. '
        : ' ';
    return '[$level$levelSuffix] $base$wSuffix';
  }

  static String _levelSuffix(String level) {
    switch (level.toUpperCase()) {
      case 'N5':
        return ' (Fondasi - Fokus pada akurasi)';
      case 'N4':
        return ' (Peningkatan - Fokus pada naturalitas)';
      case 'N3':
        return ' (Mandiri - Fokus pada ragam)';
      case 'N2':
        return ' (Formal - Fokus pada ketelitian)';
      case 'N1':
        return ' (Lanjutan - Fokus pada nuansa)';
      default:
        return '';
    }
  }

  static String _buildExample(CurriculumContent content, String level,
      {required String mode}) {
    final levelLower = level.toLowerCase();
    if (mode == 'positive') {
      return 'Contoh: ${_exampleForLevel(content, levelLower, 'positive')}';
    } else if (mode == 'withError') {
      return 'Contoh kesalahan: ${_exampleForLevel(content, levelLower, 'error')}';
    } else {
      return 'Contoh review: ${_exampleForLevel(content, levelLower, 'review')}';
    }
  }

  static String _exampleForLevel(String content, String level, String mode) {
    // Return example based on content id and level
    // Simplified: return generic appropriate example
    switch (level) {
      case 'n5':
        return _n5Example(content, mode);
      case 'n4':
        return _n4Example(content, mode);
      default:
        return 'Kalimat contoh untuk level $level';
    }
  }

  static String _n5Example(CurriculumContent content, String mode) {
    switch (content.id) {
      case 'vocab_n5_001_watashi':
        return mode == 'positive'
            ? 'Watashi wa Dini desu.'
            : 'Watashi o Dini desu.';
      case 'grammar_n5_001_desu':
        return mode == 'positive'
            ? 'Watashi wa pen-gin desu.'
            : 'Watashi wo pen-gin desu.';
      default:
        return 'Example sentence';
    }
  }

  static String _n4Example(CurriculumContent content, String mode) {
    return 'Example for N4: ${content.title}';
  }

  static String _buildHint(CurriculumContent content, LearningSkill skill,
      String level) {
    final levelLower = level.toLowerCase();
    switch (skill) {
      case LearningSkill.grammar:
        return _grammarHintForLevel(levelLower);
      case LearningSkill.vocabulary:
        return _vocabHintForLevel(levelLower);
      default:
        return 'Coba ingat makna dasarnya.';
    }
  }

  static String _grammarHintForLevel(String level) {
    switch (level) {
      case 'n5':
        return 'Cari partikel yang sesuai dengan topik kalimat';
      case 'n4':
        return 'Perhatikan bentuk kata kerja dan pola seguido-nya';
      default:
        return 'Review aturan utama.';
    }
  }

  static String _vocabHintForLevel(String level) {
    switch (level) {
      case 'n5':
        return 'Latih menelusuri kata dalam konteks kalimat';
      case 'n4':
        return 'Perhatikan pola kamus-kata yang sering muncul bersama';
      default:
        return 'Review artian dan konjungsi.';
    }
  }

  static String _buildCorrection(CurriculumContent content, LearningSkill skill,
      String level) {
    final levelLower = level.toLowerCase();
    switch (skill) {
      case LearningSkill.grammar:
        return _grammarCorrectionForLevel(levelLower, content.id);
      case LearningSkill.vocabulary:
        return _vocabCorrectionForLevel(levelLower, content.id);
      default:
        return 'Cek kembali aturan utama.';
    }
  }

  static String _grammarCorrectionForLevel(String level, String conceptId) {
    switch (level) {
      case 'n5':
        return 'Pastikan menggunakan partikel yang tepat (wa/no/ga/mo) sesuai topik';
      case 'n4':
        return 'Perhatikan bentuk masu/ta dan conjugation rules';
      default:
        return 'Review grammar reference.';
    }
  }

  static String _vocabCorrectionForLevel(String level, String conceptId) {
    switch (level) {
      case 'n5':
        return 'Pastikan benar-benar mengingat bacaan dan artian';
      case 'n4':
        return 'Perhatikan registrasi kata (formal vs informal)';
      default:
        return 'Review vocabulary card.';
    }
  }

  static String _buildTransferTask(CurriculumContent content, String level,
      {String? focus}) {
    final levelLower = level.toLowerCase();
    final topic = _topicForContent(content);

    if (focus == 'remediation') {
      return 'Latihan soal mirip dengan fokus pada area yang kesulitan';
    }

    switch (levelLower) {
      case 'n5':
        return 'Gunakan ${content.title} dalam dialog perkenalan sehari-hari';
      case 'n4':
        return 'Terapkan ${content.title} dalam situasi kerja atau sekolah';
      case 'n3':
      case 'n2':
      case 'n1':
        return 'Gunakan ${content.title} dalam teks formal atau artikel';
      default:
        return 'Latihan praktis dengan ${content.title}';
    }
  }

  static String _topicForContent(CurriculumContent content) {
    switch (content.id) {
      case 'vocab_n5_001_watashi':
        return 'salam perkenalan';
      case 'grammar_n5_001_desu':
        return 'kalimat identitas';
      case 'vocab_n5_002_namae':
        return 'menanyakan nama';
      default:
        return 'penggunaan sehari-hari';
    }
  }

  static String _detectCommonWeakness(LearningSkill skill, double masteryScore) {
    if (masteryScore < 50) return 'Kekuasaan masih rendah - butuh review fundamental';
    if (masteryScore < 70) return 'Kakuan sedang - butuh latihan berkala';
    return 'Kakuan baik - fokus pada transfer ke konteks baru';
  }

  static String _detectVocabWeakness(double currentScore) {
    if (currentScore < 50) return 'Lupa artian sering - pakai flashcard';
    if (currentScore < 70) return 'Konflik dengan kata mirip - catat perbedaan';
    return 'Lupa bacaan - latihan membaca';
  }

  static String _fallbackGrammarResponse(String level, LearningSkill skill) {
    return AIResponse(
      explanation: _levelSuffix(level) +
          'Maaf, saya saat ini tidak memiliki data grammar untuk level ini.',
      example: '',
      hint: 'Coba pertanyaan tentang grammar N5 dasar',
      correction: '',
      transferTask: 'Lakukan kuis grammar N5',
      isComplete: true,
    );
  }

  static AIResponse _fallbackVocabResponse(String level, LearningSkill skill) {
    return AIResponse(
      explanation: _levelSuffix(level) +
          'Maaf, saya saat ini tidak memiliki data kosakata untuk level ini.',
      example: '',
      hint: 'Coba pertanyaan tentang kosakata N5',
      correction: '',
      transferTask: 'Lakukan kosiata N5',
      isComplete: true,
    );
  }

  /// Memberi hint bertahap (bukan jawaban langsung)
  static List<String> progressiveHint(String baseConcept, LearningSkill skill,
      {String? learnerLevel}) {
    final level = learnerLevel ?? 'N5';
    final hints = <String>[];

    switch (skill) {
      case LearningSkill.grammar:
        hints.add('Coba ingat partikel apa yang biasanya accompanying topik kalimat');
        hints.add('Perhatikan kata setelah partikel - apakah subjek atau objek?');
        hints.add('Cek: apakah kalimat menandai topik atau objek?');
        hints.add('Review aturan: wa topik, ga objek, mo juga');
        break;
      case LearningSkill.vocabulary:
        hints.add('Coba baca kata dengan gambaran visual');
        hints.add('Liat cognates atau kata serumpun');
        hints.add('Panggil kata dalam kalimat sederhana');
        hints.add('Review artian dari kamus');
        break;
      default:
        hints.add('Coba heran dengan pertanyaan sederhana');
        hints.add('Review konsep utama');
    }

    return hints;
  }

  /// Validasi apakah response sudah lengkap untuk ditampilkan
  bool get isResponseValid =>
      explanation.isNotEmpty && (example.isNotEmpty || hint.isNotEmpty);
}