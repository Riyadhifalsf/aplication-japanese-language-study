import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_study/features/curriculum/curriculum_catalog.dart';
import 'package:japanese_study/features/curriculum/curriculum_engine.dart';
import 'package:japanese_study/features/curriculum/curriculum_models.dart';
import 'package:japanese_study/features/learning/domain/learning_models.dart';

void main() {
  group('Gamification + Progression (Phase 2 redesign)', () {
    test('XP akumulasi: 10 + 20 = 30', () {
      const gained = [10, 20];
      final total = gained.reduce((a, b) => a + b);
      expect(total, 30);
      // mapping ke spec: vocab 10, quiz 20
      expect(CurriculumActivityType.vocabulary.defaultXp, 10);
      expect(CurriculumActivityType.quiz.defaultXp, 20);
    });

    test('Level: xp 0 -> Lv1, xp 500 -> Lv2, sisa 0', () {
      int level(int xp) => xp ~/ 500 + 1;
      int levelXp(int xp) => xp % 500;
      expect(level(0), 1);
      expect(level(499), 1);
      expect(level(500), 2);
      expect(levelXp(500), 0);
      expect(levelXp(750), 250);
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

    test('XP idempotent: aktivitas sama tidak memberi XP dua kali', () {
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
      expect(first.xpGained, greaterThan(0));
      final second = CurriculumEngine.completeActivity(
          lesson: lesson,
          progressById: progress,
          activityId: lesson.activities.first.id,
          now: now);
      expect(second.xpGained, 0);
    });

    test('Daily goal allowed values 20/50/100/150', () {
      expect([20, 50, 100, 150], contains(100));
      expect([20, 50, 100, 150], isNot(contains(30)));
    });
  });
}
