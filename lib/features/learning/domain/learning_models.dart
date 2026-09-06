// Domain model untuk learning engine. File ini sengaja tidak mengimpor Flutter
// ataupun storage sehingga aturan kurikulum, mastery, dan review dapat diuji
// tanpa UI atau jaringan.

enum LearningSkill {
  vocabulary,
  grammar,
  kanji,
  listening,
  reading,
  speaking,
  writing;

  String get label => switch (this) {
        LearningSkill.vocabulary => 'Kosakata',
        LearningSkill.grammar => 'Tata bahasa',
        LearningSkill.kanji => 'Kanji',
        LearningSkill.listening => 'Listening',
        LearningSkill.reading => 'Reading',
        LearningSkill.speaking => 'Speaking',
        LearningSkill.writing => 'Writing',
      };

  static LearningSkill? fromName(Object? value) {
    for (final skill in values) {
      if (skill.name == value) return skill;
    }
    return null;
  }
}

enum LessonPhase {
  introduction,
  learn,
  guidedPractice,
  recall,
  application,
  assessment;

  String get label => switch (this) {
        LessonPhase.introduction => 'Pengenalan',
        LessonPhase.learn => 'Pelajari',
        LessonPhase.guidedPractice => 'Latihan terpandu',
        LessonPhase.recall => 'Ingat kembali',
        LessonPhase.application => 'Gunakan dalam konteks',
        LessonPhase.assessment => 'Uji penguasaan',
      };
}

enum ContentTier {
  core,
  extension,
  optional,
  advanced;

  String get label => switch (this) {
        ContentTier.core => 'CORE',
        ContentTier.extension => 'EXTENSION',
        ContentTier.optional => 'OPTIONAL',
        ContentTier.advanced => 'ADVANCED',
      };
}

enum ReviewPhase { newItem, learning, review, mature, relearning }

enum QuestionKind { choice, ordering }

class LearningObjective {
  const LearningObjective({
    required this.id,
    required this.description,
    required this.assessedSkills,
  });

  final String id;
  final String description;
  final Set<LearningSkill> assessedSkills;
}

class CurriculumContent {
  const CurriculumContent({
    required this.id,
    required this.title,
    required this.explanation,
    required this.skill,
    this.tier = ContentTier.core,
    this.relatedIds = const [],
  });

  final String id;
  final String title;
  final String explanation;
  final LearningSkill skill;
  final ContentTier tier;
  final List<String> relatedIds;
}

class MasteryGate {
  const MasteryGate({required this.minimumBySkill});

  /// Nilai 0–100. Hanya skill yang benar-benar dinilai di lesson yang
  /// dimasukkan ke sini; tidak ada skor speaking buatan.
  final Map<LearningSkill, int> minimumBySkill;
}

class LessonQuestion {
  const LessonQuestion({
    required this.id,
    required this.phase,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.conceptId,
    required this.skills,
    required this.explanation,
    this.scenario,
  });

  final String id;
  final LessonPhase phase;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String conceptId;
  final Set<LearningSkill> skills;
  final String explanation;
  final String? scenario;

  QuestionKind get kind => QuestionKind.choice;
}

class LessonDefinition {
  const LessonDefinition({
    required this.id,
    required this.unitId,
    required this.level,
    required this.sequence,
    required this.title,
    required this.summary,
    required this.whyNow,
    required this.objectives,
    required this.contents,
    required this.questions,
    required this.masteryGate,
    this.prerequisiteLessonIds = const [],
    this.nextLessonId,
  });

  final String id;
  final String unitId;
  final String level;
  final int sequence;
  final String title;
  final String summary;
  final String whyNow;
  final List<LearningObjective> objectives;
  final List<CurriculumContent> contents;
  final List<LessonQuestion> questions;
  final MasteryGate masteryGate;
  final List<String> prerequisiteLessonIds;
  final String? nextLessonId;

  List<LessonQuestion> questionsFor(LessonPhase phase) =>
      questions.where((question) => question.phase == phase).toList();
}

class UnitDefinition {
  const UnitDefinition({
    required this.id,
    required this.level,
    required this.sequence,
    required this.title,
    required this.objective,
    required this.lessonIds,
  });

  final String id;
  final String level;
  final int sequence;
  final String title;
  final String objective;
  final List<String> lessonIds;
}

class CurriculumCatalog {
  const CurriculumCatalog({required this.units, required this.lessons});

  final List<UnitDefinition> units;
  final List<LessonDefinition> lessons;

  LessonDefinition? lessonById(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  UnitDefinition? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  List<LessonDefinition> lessonsForLevel(String level) =>
      lessons.where((lesson) => lesson.level == level).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
}

class MasteryRecord {
  MasteryRecord({
    required this.skill,
    this.score = 0,
    this.correctCount = 0,
    this.attemptCount = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final LearningSkill skill;
  double score;
  int correctCount;
  int attemptCount;
  DateTime updatedAt;

  Map<String, Object> toJson() => {
        'skill': skill.name,
        'score': score,
        'correctCount': correctCount,
        'attemptCount': attemptCount,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static MasteryRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final skill = LearningSkill.fromName(raw['skill']);
    if (skill == null) return null;
    return MasteryRecord(
      skill: skill,
      score: ((raw['score'] as num?) ?? 0).toDouble().clamp(0, 100).toDouble(),
      correctCount: ((raw['correctCount'] as num?) ?? 0)
          .toInt()
          .clamp(0, 1000000)
          .toInt(),
      attemptCount: ((raw['attemptCount'] as num?) ?? 0)
          .toInt()
          .clamp(0, 1000000)
          .toInt(),
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ReviewState {
  ReviewState({
    required this.itemId,
    this.phase = ReviewPhase.newItem,
    this.stabilityDays = 1,
    this.difficulty = 5,
    this.reviewCount = 0,
    this.lapseCount = 0,
    this.lastReviewAt,
    this.nextReviewAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String itemId;
  ReviewPhase phase;
  double stabilityDays;
  double difficulty;
  int reviewCount;
  int lapseCount;
  DateTime? lastReviewAt;
  DateTime? nextReviewAt;
  DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'itemId': itemId,
        'phase': phase.name,
        'stabilityDays': stabilityDays,
        'difficulty': difficulty,
        'reviewCount': reviewCount,
        'lapseCount': lapseCount,
        'lastReviewAt': lastReviewAt?.toIso8601String(),
        'nextReviewAt': nextReviewAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static ReviewState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final itemId = '${raw['itemId'] ?? ''}'.trim();
    if (itemId.isEmpty) return null;
    final phase = ReviewPhase.values.where((item) => item.name == raw['phase']);
    return ReviewState(
      itemId: itemId,
      phase: phase.isEmpty ? ReviewPhase.newItem : phase.first,
      stabilityDays: ((raw['stabilityDays'] as num?) ?? 1)
          .toDouble()
          .clamp(.25, 36500)
          .toDouble(),
      difficulty:
          ((raw['difficulty'] as num?) ?? 5).toDouble().clamp(1, 10).toDouble(),
      reviewCount:
          ((raw['reviewCount'] as num?) ?? 0).toInt().clamp(0, 1000000).toInt(),
      lapseCount:
          ((raw['lapseCount'] as num?) ?? 0).toInt().clamp(0, 1000000).toInt(),
      lastReviewAt: DateTime.tryParse('${raw['lastReviewAt'] ?? ''}'),
      nextReviewAt: DateTime.tryParse('${raw['nextReviewAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class MistakeRecord {
  MistakeRecord({
    required this.conceptId,
    required this.skill,
    required this.lastPrompt,
    required this.lastAnswer,
    required this.correctAnswer,
    this.mistakeCount = 0,
    DateTime? lastOccurredAt,
    DateTime? updatedAt,
  })  : lastOccurredAt =
            lastOccurredAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String conceptId;
  final LearningSkill skill;
  String lastPrompt;
  String lastAnswer;
  String correctAnswer;
  int mistakeCount;
  DateTime lastOccurredAt;
  DateTime updatedAt;

  Map<String, Object> toJson() => {
        'conceptId': conceptId,
        'skill': skill.name,
        'lastPrompt': lastPrompt,
        'lastAnswer': lastAnswer,
        'correctAnswer': correctAnswer,
        'mistakeCount': mistakeCount,
        'lastOccurredAt': lastOccurredAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static MistakeRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final conceptId = '${raw['conceptId'] ?? ''}'.trim();
    final skill = LearningSkill.fromName(raw['skill']);
    if (conceptId.isEmpty || skill == null) return null;
    return MistakeRecord(
      conceptId: conceptId,
      skill: skill,
      lastPrompt: '${raw['lastPrompt'] ?? ''}',
      lastAnswer: '${raw['lastAnswer'] ?? ''}',
      correctAnswer: '${raw['correctAnswer'] ?? ''}',
      mistakeCount: ((raw['mistakeCount'] as num?) ?? 0)
          .toInt()
          .clamp(0, 1000000)
          .toInt(),
      lastOccurredAt: DateTime.tryParse('${raw['lastOccurredAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LessonProgress {
  LessonProgress({
    required this.lessonId,
    this.currentPhase = LessonPhase.introduction,
    this.completedPhases = const {},
    this.completed = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String lessonId;
  LessonPhase currentPhase;
  Set<LessonPhase> completedPhases;
  bool completed;
  DateTime updatedAt;

  Map<String, Object> toJson() => {
        'lessonId': lessonId,
        'currentPhase': currentPhase.name,
        'completedPhases': completedPhases.map((item) => item.name).toList(),
        'completed': completed,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static LessonProgress? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lessonId = '${raw['lessonId'] ?? ''}'.trim();
    if (lessonId.isEmpty) return null;
    final phase =
        LessonPhase.values.where((item) => item.name == raw['currentPhase']);
    final completed = <LessonPhase>{};
    for (final rawPhase in raw['completedPhases'] as List? ?? const []) {
      final value = LessonPhase.values.where((item) => item.name == rawPhase);
      if (value.isNotEmpty) completed.add(value.first);
    }
    return LessonProgress(
      lessonId: lessonId,
      currentPhase: phase.isEmpty ? LessonPhase.introduction : phase.first,
      completedPhases: completed,
      completed: raw['completed'] == true,
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LearnerState {
  LearnerState({
    Map<String, MasteryRecord>? masteryByKey,
    Map<String, ReviewState>? reviewByItemId,
    Map<String, MistakeRecord>? mistakesByKey,
    Map<String, LessonProgress>? lessonProgressById,
    this.currentLessonId,
  })  : masteryByKey = masteryByKey ?? {},
        reviewByItemId = reviewByItemId ?? {},
        mistakesByKey = mistakesByKey ?? {},
        lessonProgressById = lessonProgressById ?? {};

  final Map<String, MasteryRecord> masteryByKey;
  final Map<String, ReviewState> reviewByItemId;
  final Map<String, MistakeRecord> mistakesByKey;
  final Map<String, LessonProgress> lessonProgressById;
  String? currentLessonId;

  Map<String, Object?> toJson() => {
        'version': 1,
        'currentLessonId': currentLessonId,
        'mastery':
            masteryByKey.map((key, value) => MapEntry(key, value.toJson())),
        'reviews':
            reviewByItemId.map((key, value) => MapEntry(key, value.toJson())),
        'mistakes':
            mistakesByKey.map((key, value) => MapEntry(key, value.toJson())),
        'lessonProgress': lessonProgressById
            .map((key, value) => MapEntry(key, value.toJson())),
      };

  static LearnerState fromJson(Object? raw) {
    if (raw is! Map) return LearnerState();
    final mastery = <String, MasteryRecord>{};
    final reviews = <String, ReviewState>{};
    final mistakes = <String, MistakeRecord>{};
    final lessons = <String, LessonProgress>{};
    for (final entry in (raw['mastery'] as Map? ?? const {}).entries) {
      final record = MasteryRecord.fromJson(entry.value);
      if (record != null) mastery['${entry.key}'] = record;
    }
    for (final entry in (raw['reviews'] as Map? ?? const {}).entries) {
      final record = ReviewState.fromJson(entry.value);
      if (record != null) reviews['${entry.key}'] = record;
    }
    for (final entry in (raw['mistakes'] as Map? ?? const {}).entries) {
      final record = MistakeRecord.fromJson(entry.value);
      if (record != null) mistakes['${entry.key}'] = record;
    }
    for (final entry in (raw['lessonProgress'] as Map? ?? const {}).entries) {
      final record = LessonProgress.fromJson(entry.value);
      if (record != null) lessons['${entry.key}'] = record;
    }
    return LearnerState(
      masteryByKey: mastery,
      reviewByItemId: reviews,
      mistakesByKey: mistakes,
      lessonProgressById: lessons,
      currentLessonId: raw['currentLessonId'] as String?,
    );
  }
}
