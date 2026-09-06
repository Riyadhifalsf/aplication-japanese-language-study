import 'dart:math' as math;

import 'learning_models.dart';

/// Hasil jawaban yang bisa dipakai UI tanpa menaruh aturan belajar di widget.
class AnswerEvaluation {
  const AnswerEvaluation({
    required this.correct,
    required this.explanation,
    required this.nextReviewAt,
    required this.masteryBySkill,
  });

  final bool correct;
  final String explanation;
  final DateTime nextReviewAt;
  final Map<LearningSkill, double> masteryBySkill;
}

class GateStatus {
  const GateStatus(
      {required this.passed, required this.scores, required this.minimums});

  final bool passed;
  final Map<LearningSkill, double> scores;
  final Map<LearningSkill, int> minimums;

  List<LearningSkill> get unmetSkills => minimums.entries
      .where((entry) => (scores[entry.key] ?? 0) < entry.value)
      .map((entry) => entry.key)
      .toList();
}

enum DailyPlanKind { continueLesson, review, weakness, application, challenge }

class DailyPlanItem {
  const DailyPlanItem({
    required this.kind,
    required this.title,
    required this.reason,
    required this.estimatedMinutes,
    this.lessonId,
    this.count = 0,
  });

  final DailyPlanKind kind;
  final String title;
  final String reason;
  final int estimatedMinutes;
  final String? lessonId;
  final int count;
}

class DailyPlan {
  const DailyPlan({
    required this.level,
    required this.currentLesson,
    required this.items,
    required this.weaknesses,
  });

  final String level;
  final LessonDefinition? currentLesson;
  final List<DailyPlanItem> items;
  final List<LearningSkill> weaknesses;
}

/// Mesin pembelajaran yang menjaga pemisahan tanggung jawab berikut:
///
/// * Curriculum = lesson mana yang boleh dipelajari.
/// * Adaptive = bentuk latihan yang diprioritaskan.
/// * SRS = kapan item perlu diulang.
/// * Mastery = seberapa baik setiap skill pada konsep sudah dikuasai.
///
/// Semua mutasi berada di sini sehingga UI, API, dan penyimpanan offline dapat
/// menggunakan aturan yang sama.
class LearningEngine {
  LearningEngine({required this.catalog, LearnerState? state})
      : state = state ?? LearnerState();

  final CurriculumCatalog catalog;
  LearnerState state;

  void restore(LearnerState newState) {
    state = newState;
  }

  LessonDefinition? currentLesson({required String level}) {
    final selected = state.currentLessonId;
    final saved = selected == null ? null : catalog.lessonById(selected);
    if (saved != null && saved.level == level && !_isCompleted(saved.id)) {
      return saved;
    }
    final next = nextEligibleLesson(level: level);
    state.currentLessonId = next?.id;
    return next;
  }

  LessonDefinition? nextEligibleLesson({required String level}) {
    for (final lesson in catalog.lessonsForLevel(level)) {
      if (_isCompleted(lesson.id)) continue;
      final prerequisitesMet = lesson.prerequisiteLessonIds.every(_isCompleted);
      if (prerequisitesMet) return lesson;
    }
    return null;
  }

  LessonProgress progressFor(String lessonId) => state.lessonProgressById
      .putIfAbsent(lessonId, () => LessonProgress(lessonId: lessonId));

  bool isLessonAvailable(LessonDefinition lesson) =>
      lesson.prerequisiteLessonIds.every(_isCompleted);

  bool _isCompleted(String lessonId) =>
      state.lessonProgressById[lessonId]?.completed == true;

  LessonPhase advancePhase({required String lessonId, required DateTime now}) {
    final progress = progressFor(lessonId);
    final currentIndex = LessonPhase.values.indexOf(progress.currentPhase);
    progress.completedPhases = {
      ...progress.completedPhases,
      progress.currentPhase
    };
    progress.currentPhase = LessonPhase
        .values[math.min(currentIndex + 1, LessonPhase.values.length - 1)];
    progress.updatedAt = now;
    state.currentLessonId = lessonId;
    return progress.currentPhase;
  }

  AnswerEvaluation answerLessonQuestion({
    required LessonQuestion question,
    required int selectedIndex,
    required DateTime now,
  }) {
    return _answerQuestion(
      question: question,
      selectedIndex: selectedIndex,
      now: now,
      isReview: false,
    );
  }

  AnswerEvaluation answerReviewQuestion({
    required LessonQuestion question,
    required int selectedIndex,
    required DateTime now,
  }) {
    return _answerQuestion(
      question: question,
      selectedIndex: selectedIndex,
      now: now,
      isReview: true,
    );
  }

  AnswerEvaluation _answerQuestion({
    required LessonQuestion question,
    required int selectedIndex,
    required DateTime now,
    required bool isReview,
  }) {
    final correct = selectedIndex == question.correctIndex;
    final currentScores = <LearningSkill, double>{};
    for (final skill in question.skills) {
      final record = _masteryFor(question.conceptId, skill);
      final previousScore = record.score;
      record.attemptCount++;
      if (correct) record.correctCount++;

      // Pembaruan bertahap: satu jawaban benar tidak otomatis berarti mastery
      // sempurna setelah user sebelumnya berkali-kali salah.
      final target = correct ? 100.0 : 0.0;
      final weight = record.attemptCount == 1 ? 1.0 : (correct ? .38 : .42);
      record.score = (previousScore * (1 - weight) + target * weight)
          .clamp(0, 100)
          .toDouble();
      record.updatedAt = now;
      currentScores[skill] = record.score;
    }

    final review = state.reviewByItemId.putIfAbsent(
      question.conceptId,
      () => ReviewState(itemId: question.conceptId),
    );
    _scheduleReview(
        review: review, correct: correct, now: now, isReview: isReview);

    if (!correct) {
      for (final skill in question.skills) {
        final key = '${question.conceptId}:${skill.name}';
        final mistake = state.mistakesByKey.putIfAbsent(
          key,
          () => MistakeRecord(
            conceptId: question.conceptId,
            skill: skill,
            lastPrompt: question.prompt,
            lastAnswer:
                selectedIndex >= 0 && selectedIndex < question.options.length
                    ? question.options[selectedIndex]
                    : '',
            correctAnswer: question.options[question.correctIndex],
          ),
        );
        mistake.mistakeCount++;
        mistake
          ..lastPrompt = question.prompt
          ..lastAnswer =
              selectedIndex >= 0 && selectedIndex < question.options.length
                  ? question.options[selectedIndex]
                  : ''
          ..correctAnswer = question.options[question.correctIndex]
          ..lastOccurredAt = now
          ..updatedAt = now;
      }
    }

    return AnswerEvaluation(
      correct: correct,
      explanation: question.explanation,
      nextReviewAt: review.nextReviewAt ?? now,
      masteryBySkill: currentScores,
    );
  }

  void _scheduleReview({
    required ReviewState review,
    required bool correct,
    required DateTime now,
    required bool isReview,
  }) {
    review.lastReviewAt = now;
    review.reviewCount++;
    if (!correct) {
      review.lapseCount++;
      review
        ..phase = ReviewPhase.relearning
        ..difficulty = (review.difficulty + .8).clamp(1, 10).toDouble()
        ..stabilityDays = math.max(.5, review.stabilityDays * .55)
        ..nextReviewAt = now.add(const Duration(days: 1))
        ..updatedAt = now;
      return;
    }

    final multiplier = isReview ? 1.8 : 1.35;
    final ease = (11 - review.difficulty) / 6;
    review
      ..stabilityDays =
          (review.stabilityDays * multiplier * ease).clamp(1, 3650).toDouble()
      ..difficulty = (review.difficulty - .18).clamp(1, 10).toDouble()
      ..phase = review.reviewCount >= 6
          ? ReviewPhase.mature
          : (review.reviewCount >= 2
              ? ReviewPhase.review
              : ReviewPhase.learning)
      ..nextReviewAt = now.add(Duration(days: review.stabilityDays.ceil()))
      ..updatedAt = now;
  }

  MasteryRecord _masteryFor(String conceptId, LearningSkill skill) {
    final key = '$conceptId:${skill.name}';
    return state.masteryByKey.putIfAbsent(
      key,
      () => MasteryRecord(skill: skill),
    );
  }

  double masteryForConcept(String conceptId, LearningSkill skill) =>
      state.masteryByKey['$conceptId:${skill.name}']?.score ?? 0;

  Map<LearningSkill, double> masteryForLesson(LessonDefinition lesson) {
    final conceptIds = <String>{
      ...lesson.contents.map((content) => content.id),
      ...lesson.questions.map((question) => question.conceptId),
    };
    final result = <LearningSkill, double>{};
    for (final skill in lesson.masteryGate.minimumBySkill.keys) {
      final records = conceptIds
          .map((id) => state.masteryByKey['$id:${skill.name}'])
          .whereType<MasteryRecord>()
          .where((record) => record.attemptCount > 0)
          .toList();
      result[skill] = records.isEmpty
          ? 0
          : records.map((record) => record.score).reduce((a, b) => a + b) /
              records.length;
    }
    return result;
  }

  GateStatus gateStatus(LessonDefinition lesson) {
    final scores = masteryForLesson(lesson);
    final passed = lesson.masteryGate.minimumBySkill.entries.every(
      (entry) => (scores[entry.key] ?? 0) >= entry.value,
    );
    return GateStatus(
      passed: passed,
      scores: scores,
      minimums: lesson.masteryGate.minimumBySkill,
    );
  }

  GateStatus completeAssessment({
    required LessonDefinition lesson,
    required DateTime now,
  }) {
    final gate = gateStatus(lesson);
    final progress = progressFor(lesson.id);
    progress
      ..completedPhases = {...progress.completedPhases, LessonPhase.assessment}
      ..updatedAt = now;
    if (gate.passed) {
      progress.completed = true;
      state.currentLessonId = lesson.nextLessonId;
    }
    return gate;
  }

  List<ReviewState> dueReviews(DateTime now) {
    final due = state.reviewByItemId.values
        .where((review) =>
            review.nextReviewAt != null && !review.nextReviewAt!.isAfter(now))
        .toList();
    due.sort((a, b) {
      final aProbability = retentionProbability(a, now);
      final bProbability = retentionProbability(b, now);
      final risk = aProbability.compareTo(bProbability);
      if (risk != 0) return risk;
      return b.difficulty.compareTo(a.difficulty);
    });
    return due;
  }

  double retentionProbability(ReviewState review, DateTime now) {
    if (review.lastReviewAt == null) return 0;
    final elapsed = now.difference(review.lastReviewAt!).inMinutes / (60 * 24);
    return math
        .exp(-elapsed / math.max(.25, review.stabilityDays))
        .clamp(0, 1)
        .toDouble();
  }

  List<LearningSkill> weaknesses({int limit = 3}) {
    final bySkill = <LearningSkill, List<MasteryRecord>>{};
    for (final record in state.masteryByKey.values) {
      if (record.attemptCount > 0) {
        (bySkill[record.skill] ??= []).add(record);
      }
    }
    final rankings = <MapEntry<LearningSkill, double>>[];
    for (final skill in LearningSkill.values) {
      final records = bySkill[skill] ?? const <MasteryRecord>[];
      final mastery = records.isEmpty
          ? 50.0
          : records.map((record) => record.score).reduce((a, b) => a + b) /
              records.length;
      final mistakes = state.mistakesByKey.values
          .where((mistake) => mistake.skill == skill)
          .fold<int>(0, (total, mistake) => total + mistake.mistakeCount);
      // Kesalahan memiliki dampak kecil agar satu salah jawab tidak membuat
      // learner dianggap lemah secara permanen.
      rankings.add(MapEntry(skill, mastery - math.min(20, mistakes * 2)));
    }
    rankings.sort((a, b) => a.value.compareTo(b.value));
    return rankings.take(limit).map((entry) => entry.key).toList();
  }

  List<MistakeRecord> mistakes({LearningSkill? skill}) {
    final items = state.mistakesByKey.values
        .where((mistake) => skill == null || mistake.skill == skill)
        .toList();
    items.sort((a, b) {
      final frequency = b.mistakeCount.compareTo(a.mistakeCount);
      return frequency != 0
          ? frequency
          : b.lastOccurredAt.compareTo(a.lastOccurredAt);
    });
    return items;
  }

  DailyPlan buildDailyPlan({
    required String level,
    required int dailyMinutes,
    required DateTime now,
  }) {
    final lesson = currentLesson(level: level);
    final due = dueReviews(now);
    final weak = weaknesses();
    final items = <DailyPlanItem>[];
    if (lesson != null) {
      items.add(DailyPlanItem(
        kind: DailyPlanKind.continueLesson,
        title: 'Lanjutkan ${lesson.title}',
        reason: lesson.whyNow,
        estimatedMinutes: dailyMinutes >= 30 ? 15 : 10,
        lessonId: lesson.id,
      ));
    }
    if (due.isNotEmpty) {
      items.add(DailyPlanItem(
        kind: DailyPlanKind.review,
        title: 'Ulangi ${due.length} item yang jatuh tempo',
        reason: 'Review dijadwalkan ketika peluang mengingat mulai menurun.',
        estimatedMinutes: math.min(12, math.max(4, due.length)).toInt(),
        count: due.length,
      ));
    }
    if (weak.isNotEmpty) {
      items.add(DailyPlanItem(
        kind: DailyPlanKind.weakness,
        title: 'Perkuat ${weak.first.label.toLowerCase()}',
        reason: 'Dihasilkan dari jawaban dan error notebook kamu, bukan acak.',
        estimatedMinutes: 6,
      ));
    }
    if (lesson != null) {
      items.add(DailyPlanItem(
        kind: DailyPlanKind.application,
        title: 'Aplikasi singkat',
        reason:
            'Gunakan pola lesson di konteks nyata sebelum masuk assessment.',
        estimatedMinutes: 4,
        lessonId: lesson.id,
      ));
    }
    if (dailyMinutes >= 45) {
      items.add(const DailyPlanItem(
        kind: DailyPlanKind.challenge,
        title: 'Tantangan opsional',
        reason:
            'Tambahan latihan setelah misi inti selesai; tidak membuka lesson secara otomatis.',
        estimatedMinutes: 8,
      ));
    }
    return DailyPlan(
        level: level, currentLesson: lesson, items: items, weaknesses: weak);
  }

  List<LessonQuestion> questionsForReview(DateTime now, {int limit = 10}) {
    final dueIds = dueReviews(now).map((review) => review.itemId).toSet();
    final found = catalog.lessons
        .expand((lesson) => lesson.questions)
        .where((question) => dueIds.contains(question.conceptId))
        .toList();
    return found.take(limit).toList();
  }
}
