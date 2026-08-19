import 'dart:math';

import '../models/exam_question.dart';
import 'content_repository.dart';

class ExamSimulatorRepository {
  ExamSimulatorRepository(this.content);

  final ContentRepository content;

  static const List<String> jlptLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];
  static const List<String> jftTracks = ['A1', 'A2.1', 'A2.2', 'A2 Kerja', 'A2 Campuran'];
  static const int stageCount = 50;

  static int questionCountFor(ExamType type, String level) {
    if (type == ExamType.jft) return 50;
    switch (level) {
      case 'N1':
        return 110;
      case 'N2':
        return 105;
      case 'N3':
        return 105;
      case 'N4':
        return 100;
      case 'N5':
      default:
        return 95;
    }
  }

  static int minutesFor(ExamType type, String level) {
    if (type == ExamType.jft) return 60;
    switch (level) {
      case 'N1':
        return 165;
      case 'N2':
        return 155;
      case 'N3':
        return 140;
      case 'N4':
        return 115;
      case 'N5':
      default:
        return 90;
    }
  }

  static String formatSummary(ExamType type, String level) {
    final count = questionCountFor(type, level);
    final minutes = minutesFor(type, level);
    return '$count soal · $minutes menit';
  }

  ExamSessionPlan buildSession({
    required ExamType type,
    required String level,
    required int stage,
  }) {
    final safeStage = stage.clamp(1, stageCount).toInt();
    final seed = _seedFor(type, level, safeStage);
    final random = Random(seed);
    final mappedLevel = type == ExamType.jlpt ? level : _mappedJlptLevelForJft(level, safeStage);
    final count = questionCountFor(type, level);

    final questions = <ExamQuestion>[];
    for (var i = 0; i < count; i++) {
      final section = _sectionFor(type, level, i, count);
      questions.add(
        _buildQuestion(
          type: type,
          level: mappedLevel,
          displayLevel: level,
          stage: safeStage,
          index: i,
          section: section,
          random: random,
        ),
      );
    }
    return ExamSessionPlan(
      examType: type,
      level: level,
      stage: safeStage,
      questions: questions,
      minutes: minutesFor(type, level),
    );
  }

  ExamSection _sectionFor(ExamType type, String level, int index, int total) {
    if (type == ExamType.jft) {
      if (index < 12) return ExamSection.mojiGoi;
      if (index < 25) return ExamSection.conversation;
      if (index < 38) return ExamSection.choukai;
      return ExamSection.dokkai;
    }

    // Simulasi penuh JLPT: pembagian dibuat dekat dengan struktur resmi.
    // Jumlah item dapat berubah dari ujian ke ujian, jadi aplikasi memakai estimasi latihan.
    final split = _jlptSplit(level, total);
    if (index < split[0]) return ExamSection.mojiGoi;
    if (index < split[0] + split[1]) return ExamSection.bunpou;
    if (index < split[0] + split[1] + split[2]) return ExamSection.dokkai;
    return ExamSection.choukai;
  }

  List<int> _jlptSplit(String level, int total) {
    switch (level) {
      case 'N1':
        return [34, 30, 28, total - 92];
      case 'N2':
        return [32, 29, 24, total - 85];
      case 'N3':
        return [30, 28, 24, total - 82];
      case 'N4':
        return [32, 27, 20, total - 79];
      case 'N5':
      default:
        return [30, 25, 18, total - 73];
    }
  }

  ExamQuestion _buildQuestion({
    required ExamType type,
    required String level,
    required String displayLevel,
    required int stage,
    required int index,
    required ExamSection section,
    required Random random,
  }) {
    switch (section) {
      case ExamSection.mojiGoi:
        if (index % 3 == 0) {
          return _kanjiReadingQuestion(type, level, displayLevel, stage, index, section, random);
        }
        return index.isEven
            ? _kanjiMeaningQuestion(type, level, displayLevel, stage, index, section, random)
            : _vocabularyMeaningQuestion(type, level, displayLevel, stage, index, section, random);
      case ExamSection.bunpou:
        return index % 2 == 0
            ? _grammarFillQuestion(type, level, displayLevel, stage, index, section, random)
            : _grammarQuestion(type, level, displayLevel, stage, index, section, random);
      case ExamSection.dokkai:
        return _readingQuestion(type, level, displayLevel, stage, index, section, random);
      case ExamSection.choukai:
        return _listeningQuestion(type, level, displayLevel, stage, index, section, random);
      case ExamSection.conversation:
        return _conversationQuestion(type, level, displayLevel, stage, index, section, random);
    }
  }

  ExamQuestion _kanjiReadingQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final pool = _safeKanji(level);
    final item = pool[(stage * 29 + index * 13) % pool.length];
    final reading = item.preferredReading.toString().isEmpty ? item.character.toString() : item.preferredReading.toString();
    final options = _shuffledOptions(
      correct: reading,
      distractors: pool.where((e) => e.id != item.id).map((e) => e.preferredReading.toString()),
      random: random,
    );
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: 'Pilih bacaan yang tepat untuk kanji bergaris: 「${item.character}」',
      audioText: reading,
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: '「${item.character}」 dapat dibaca $reading. Arti utama: ${item.meaning}.',
      point: 9,
    );
  }

  ExamQuestion _kanjiMeaningQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final pool = _safeKanji(level);
    final item = pool[(stage * 31 + index * 7) % pool.length];
    final options = _shuffledOptions(
      correct: item.meaning.toString(),
      distractors: pool.where((e) => e.id != item.id).map((e) => e.meaning.toString()),
      random: random,
    );
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: 'Arti kanji 「${item.character}」 yang paling tepat adalah…',
      audioText: item.preferredReading.toString(),
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: '「${item.character}」 dibaca ${item.preferredReading}; arti utamanya: ${item.meaning}.',
      point: 9,
    );
  }

  ExamQuestion _vocabularyMeaningQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final pool = _safeVocabulary(level);
    final item = pool[(stage * 41 + index * 5) % pool.length];
    final options = _shuffledOptions(
      correct: item.meaning.toString(),
      distractors: pool.where((e) => e.id != item.id).map((e) => e.meaning.toString()),
      random: random,
    );
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: 'Pilih arti dari 「${item.word}」 (${item.reading}).',
      audioText: item.reading.toString().isEmpty ? item.word.toString() : item.reading.toString(),
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: '「${item.word}」 berarti ${item.meaning}.',
      point: 9,
    );
  }

  ExamQuestion _grammarQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final pool = content.grammar.where((item) => item.level == level).toList();
    final source = pool.isEmpty ? content.grammar : pool;
    final item = source[(stage * 17 + index * 11) % source.length];
    final options = _shuffledOptions(
      correct: item.pattern,
      distractors: source.where((e) => e.id != item.id).map((e) => e.pattern),
      random: random,
    );
    final example = item.examples.isNotEmpty ? item.examples.first.japanese : '私は日本語を勉強します。';
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: 'Pola mana yang cocok dengan fungsi ini?\n${item.title}\n例：$example',
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: '${item.pattern}: ${item.explanation}',
      point: 10,
    );
  }

  ExamQuestion _grammarFillQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final pool = content.grammar.where((item) => item.level == level).toList();
    final source = pool.isEmpty ? content.grammar : pool;
    final item = source[(stage * 37 + index * 7) % source.length];
    final example = item.examples.isNotEmpty ? item.examples.first.japanese : '私は日本語を勉強します。';
    final options = _shuffledOptions(
      correct: item.pattern,
      distractors: source.where((e) => e.id != item.id).map((e) => e.pattern),
      random: random,
    );
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: 'Pilih bentuk yang paling tepat untuk melengkapi kalimat.\n$example\n（　　　）',
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: 'Pola yang diminta adalah ${item.pattern}. ${item.explanation}',
      point: 10,
    );
  }

  ExamQuestion _readingQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final pool = content.readings.where((item) => item.level == level).toList();
    final source = pool.isEmpty ? content.readings : pool;
    final item = source[(stage * 13 + index * 3) % source.length];
    final correct = item.meaning.length > 86 ? '${item.meaning.substring(0, 86)}…' : item.meaning;
    final options = _shuffledOptions(
      correct: correct,
      distractors: source.where((e) => e.id != item.id).map((e) {
        final value = e.meaning;
        return value.length > 86 ? '${value.substring(0, 86)}…' : value;
      }),
      random: random,
    );
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: 'Pertanyaan bacaan: isi teks ini paling dekat dengan pilihan mana?',
      passage: '${item.title}\n\n${_trimPassage(item.japanese)}\n\n${_trimPassage(item.reading)}',
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: 'Bacaan 「${item.title}」 membahas: ${item.meaning}',
      point: 12,
    );
  }

  ExamQuestion _listeningQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final pool = _safeVocabulary(level);
    final item = pool[(stage * 19 + index * 9) % pool.length];
    final options = _shuffledOptions(
      correct: item.meaning.toString(),
      distractors: pool.where((e) => e.id != item.id).map((e) => e.meaning.toString()),
      random: random,
    );
    final audio = item.reading.toString().isEmpty ? item.word.toString() : item.reading.toString();
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: '聴解：dengarkan suara, lalu pilih arti atau situasi yang paling tepat.',
      audioText: audio,
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: 'Suara membacakan 「${item.word}」 ($audio), artinya ${item.meaning}.',
      point: 12,
    );
  }

  ExamQuestion _conversationQuestion(
    ExamType type,
    String level,
    String displayLevel,
    int stage,
    int index,
    ExamSection section,
    Random random,
  ) {
    final phrases = content.phrases;
    if (phrases.isEmpty) {
      return _grammarQuestion(type, level, displayLevel, stage, index, ExamSection.bunpou, random);
    }
    final item = phrases[(stage * 23 + index * 4) % phrases.length];
    final options = _shuffledOptions(
      correct: item.meaning,
      distractors: phrases.where((e) => e.id != item.id).map((e) => e.meaning),
      random: random,
    );
    return ExamQuestion(
      id: '${type.name}-$displayLevel-$stage-$index',
      examType: type,
      level: displayLevel,
      stage: stage,
      section: section,
      prompt: 'Ungkapan 「${item.japanese}」 paling tepat dipakai untuk…',
      audioText: item.reading.isEmpty ? item.japanese : item.reading,
      options: options.values,
      correctIndex: options.correctIndex,
      explanation: '${item.politeness}: ${item.note.isEmpty ? item.meaning : item.note}',
      point: 10,
    );
  }

  List<dynamic> _safeKanji(String level) {
    final byLevel = content.kanjiForLevel(level);
    if (byLevel.isNotEmpty) return byLevel;
    if (content.kanji.isNotEmpty) return content.kanji;
    throw StateError('Data kanji belum tersedia.');
  }

  List<dynamic> _safeVocabulary(String level) {
    final byLevel = content.vocabularyForLevel(level);
    if (byLevel.isNotEmpty) return byLevel;
    if (content.vocabulary.isNotEmpty) return content.vocabulary;
    throw StateError('Data kosakata belum tersedia.');
  }

  String _mappedJlptLevelForJft(String level, int stage) {
    if (level == 'A1') return 'N5';
    if (level == 'A2.1' || stage <= 12) return 'N4';
    if (level == 'A2.2' || level == 'A2 Kerja') return 'N3';
    if (stage <= 24) return 'N3';
    return 'N2';
  }

  int _seedFor(ExamType type, String level, int stage) {
    final base = type == ExamType.jlpt ? 107 : 509;
    return base + stage * 1009 + level.codeUnits.fold(0, (a, b) => a + b * 17);
  }

  _Options _shuffledOptions({
    required String correct,
    required Iterable<String> distractors,
    required Random random,
  }) {
    final cleanCorrect = _cleanOption(correct);
    final values = <String>[cleanCorrect];
    for (final raw in distractors) {
      final value = _cleanOption(raw);
      if (value.isNotEmpty && value != cleanCorrect && !values.contains(value)) {
        values.add(value);
      }
      if (values.length >= 4) break;
    }
    while (values.length < 4) {
      values.add('Pilihan latihan ${values.length + 1}');
    }
    values.shuffle(random);
    return _Options(values: values, correctIndex: values.indexOf(cleanCorrect));
  }

  String _cleanOption(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return 'belum ada arti';
    return trimmed.length > 96 ? '${trimmed.substring(0, 96)}…' : trimmed;
  }

  String _trimPassage(String value) {
    final clean = value.trim();
    if (clean.length <= 620) return clean;
    return '${clean.substring(0, 620)}…';
  }
}

class _Options {
  const _Options({required this.values, required this.correctIndex});

  final List<String> values;
  final int correctIndex;
}
