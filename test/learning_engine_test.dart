import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_study/features/learning/data/japanese_curriculum.dart';
import 'package:japanese_study/features/learning/domain/learning_engine.dart';
import 'package:japanese_study/features/learning/domain/learning_models.dart';

void main() {
  final now = DateTime(2026, 9, 7, 9);

  group('LearningEngine curriculum and mastery', () {
    test('main path starts with the first eligible lesson only', () {
      final engine = LearningEngine(catalog: JapaneseCurriculum.catalog);

      expect(engine.currentLesson(level: 'N5')?.id, 'lesson_mnn_001');
      expect(
        engine.isLessonAvailable(
          JapaneseCurriculum.catalog.lessonById('lesson_mnn_002')!,
        ),
        isFalse,
      );
    });

    test(
        'completion requires assessment mastery gate, not merely phase completion',
        () {
      final engine = LearningEngine(catalog: JapaneseCurriculum.catalog);
      final lesson = JapaneseCurriculum.catalog.lessonById('lesson_mnn_001')!;

      engine.advancePhase(lessonId: lesson.id, now: now);
      engine.advancePhase(lessonId: lesson.id, now: now);
      engine.advancePhase(lessonId: lesson.id, now: now);
      engine.advancePhase(lessonId: lesson.id, now: now);
      engine.advancePhase(lessonId: lesson.id, now: now);

      final result = engine.completeAssessment(lesson: lesson, now: now);
      expect(result.passed, isFalse);
      expect(engine.progressFor(lesson.id).completed, isFalse);
    });

    test(
        'passing original assessment unlocks only the next prerequisite lesson',
        () {
      final engine = LearningEngine(catalog: JapaneseCurriculum.catalog);
      final lesson = JapaneseCurriculum.catalog.lessonById('lesson_mnn_001')!;

      for (final question in lesson.questions) {
        engine.answerLessonQuestion(
          question: question,
          selectedIndex: question.correctIndex,
          now: now,
        );
      }

      final result = engine.completeAssessment(lesson: lesson, now: now);
      expect(result.passed, isTrue);
      expect(engine.progressFor(lesson.id).completed, isTrue);
      expect(engine.nextEligibleLesson(level: 'N5')?.id, 'lesson_mnn_002');
      expect(
        engine.isLessonAvailable(
          JapaneseCurriculum.catalog.lessonById('lesson_mnn_002')!,
        ),
        isTrue,
      );
    });
  });

  group('LearningEngine SRS and errors', () {
    test('wrong answer creates a targeted mistake and relearning review', () {
      final engine = LearningEngine(catalog: JapaneseCurriculum.catalog);
      final question = JapaneseCurriculum.catalog
          .lessonById('lesson_mnn_001')!
          .questions
          .first;

      final result = engine.answerLessonQuestion(
        question: question,
        selectedIndex: 1,
        now: now,
      );

      expect(result.correct, isFalse);
      expect(engine.mistakes(), isNotEmpty);
      expect(engine.mistakes().first.conceptId, question.conceptId);
      expect(engine.state.reviewByItemId[question.conceptId]?.phase,
          ReviewPhase.relearning);
      expect(engine.dueReviews(now.add(const Duration(days: 1))), isNotEmpty);
    });

    test('daily plan keeps curriculum as core and adds review when due', () {
      final engine = LearningEngine(catalog: JapaneseCurriculum.catalog);
      final question = JapaneseCurriculum.catalog
          .lessonById('lesson_mnn_001')!
          .questions
          .first;
      engine.answerLessonQuestion(
        question: question,
        selectedIndex: 1,
        now: now,
      );

      final plan = engine.buildDailyPlan(
        level: 'N5',
        dailyMinutes: 30,
        now: now.add(const Duration(days: 1)),
      );

      expect(plan.items.first.kind, DailyPlanKind.continueLesson);
      expect(
          plan.items.any((item) => item.kind == DailyPlanKind.review), isTrue);
      expect(plan.items.any((item) => item.kind == DailyPlanKind.weakness),
          isTrue);
    });
  });
}
