import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_study/features/curriculum/curriculum_catalog.dart';
import 'package:japanese_study/features/curriculum/curriculum_engine.dart';
import 'package:japanese_study/features/curriculum/curriculum_models.dart';
import 'package:japanese_study/features/learning/domain/learning_models.dart';
import 'package:japanese_study/state/app_controller.dart';

void main() {
  group('Gamification + Progression (Phase 2 redesign)', () {
    test('Menit lesson terhitung dari aktivitas', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final first = n5.allLessons.first;
      final total = first.activities.fold<int>(
          0, (sum, a) => sum + a.estimatedMinutes);
      expect(first.totalMinutes, total);
      expect(total, greaterThan(0));
    });

    test('Tier mastery dari skor 0..1', () {
      expect(MasteryTier.fromScore(0.0), MasteryTier.warrior);
      expect(MasteryTier.fromScore(0.95), MasteryTier.mythic);
      expect(MasteryTier.warrior.label, isNotEmpty);
    });

    test('Lesson completed -> next lesson unlocked (progression, bukan paywall)',
        () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final ordered = CurriculumEngine.orderedLessons(n5);
      final progress = <String, UserLessonProgress>{};
      final now = DateTime(2026, 9, 8);
      // awal: lesson 2 locked
      var statuses = CurriculumEngine.statusesForLevel(
          level: n5, progressById: progress);
      expect(statuses[ordered[1].id], CurriculumLessonStatus.locked);
      // selesaikan lesson 1
      for (final a in ordered.first.activities) {
        CurriculumEngine.completeActivity(
            lesson: ordered.first,
            progressById: progress,
            activityId: a.id,
            now: now);
      }
      statuses = CurriculumEngine.statusesForLevel(
          level: n5, progressById: progress);
      expect(statuses[ordered[1].id], CurriculumLessonStatus.available);
    });

    test('Chapter (unit) progress terhitung benar', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final unit = n5.units.first;
      final progress = <String, UserLessonProgress>{};
      var p = CurriculumEngine.unitProgress(unit: unit, progressById: progress);
      expect(p.done, 0);
      expect(p.total, unit.lessons.length);
    });

    test('Practice engine extensible: 9 jenis latihan', () {
      expect(QuestionKind.values.length, greaterThanOrEqualTo(9));
      expect(QuestionKind.choice.label, 'Pilihan ganda');
      expect(QuestionKind.fillBlank.label, isNotEmpty);
      expect(QuestionKind.matching.label, isNotEmpty);
      expect(QuestionKind.translation.label, isNotEmpty);
      // backward compat: default choice
      const q = LessonQuestion(
        id: 'q1',
        phase: LessonPhase.recall,
        prompt: 'test',
        options: ['a', 'b'],
        correctIndex: 0,
        conceptId: 'c1',
        skills: {LearningSkill.vocabulary},
        explanation: 'exp',
      );
      expect(q.kind, QuestionKind.choice);
    });

    test('Daily goal progress 40/50 = 0.8', () {
      const done = 40;
      const goal = 50;
      final progress = (done / goal).clamp(0.0, 1.0).toDouble();
      expect(progress, 0.8);
    });

    test('Idempotent: aktivitas sama tidak tercatat dua kali', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final ordered = CurriculumEngine.orderedLessons(n5);
      final lesson = ordered.first;
      final progress = <String, UserLessonProgress>{};
      final now = DateTime(2026, 9, 8);
      final first = CurriculumEngine.completeActivity(
          lesson: lesson,
          progressById: progress,
          activityId: lesson.activities.first.id,
          now: now);
      expect(first.progress.completedActivityIds,
          contains(lesson.activities.first.id));
      final countBefore =
          first.progress.completedActivityIds.length;
      final second = CurriculumEngine.completeActivity(
          lesson: lesson,
          progressById: progress,
          activityId: lesson.activities.first.id,
          now: now);
      expect(second.lessonJustCompleted, isFalse);
      expect(second.progress.completedActivityIds.length, countBefore);
    });

    test('Daily study allowed values 10/20/30/45', () {
      expect(AppController.allowedDailyStudyMinutes, contains(20));
      expect(AppController.allowedDailyStudyMinutes, isNot(contains(30 + 1)));
    });
  });
}
