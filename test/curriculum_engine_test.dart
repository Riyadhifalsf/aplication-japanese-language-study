import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_study/features/curriculum/curriculum_catalog.dart';
import 'package:japanese_study/features/curriculum/curriculum_engine.dart';
import 'package:japanese_study/features/curriculum/curriculum_models.dart';

void main() {
  group('CurriculumEngine Learning Path', () {
    test('N5 has 10 units with varied activities', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      expect(n5.units.length, 10);
      expect(n5.units[0].title, 'Japanese Basics');
      expect(n5.units[9].title, 'N5 Final Test');
      // Variasi: tidak semua lesson punya format sama.
      final firstFormats = n5.units[0].lessons
          .map((l) => l.activities.map((a) => a.type.name).join('+'))
          .toSet();
      expect(firstFormats.length, greaterThan(2));
    });

    test('lessons unlock sequentially, next locked until prev completed', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final progress = <String, UserLessonProgress>{};
      final statuses = CurriculumEngine.statusesForLevel(
          level: n5, progressById: progress);
      final ordered = CurriculumEngine.orderedLessons(n5);
      expect(statuses[ordered.first.id],
          CurriculumLessonStatus.available);
      expect(statuses[ordered[1].id], CurriculumLessonStatus.locked);

      // Selesaikan lesson pertama (semua aktivitas).
      final now = DateTime(2026, 9, 7);
      for (final activity in ordered.first.activities) {
        CurriculumEngine.completeActivity(
          lesson: ordered.first,
          progressById: progress,
          activityId: activity.id,
          now: now,
        );
      }
      final after = CurriculumEngine.statusesForLevel(
          level: n5, progressById: progress);
      expect(progress[ordered.first.id]?.status,
          CurriculumLessonStatus.completed);
      expect(after[ordered[1].id], CurriculumLessonStatus.available);
    });

    test('Menit & skill mengikuti spec (vocab ~10 mnt, listening, unit test)', () {
      expect(CurriculumActivityType.vocabulary.skillKey, isNotEmpty);
      expect(CurriculumActivityType.listening.skillKey, isNotEmpty);
      expect(CurriculumActivityType.unitTest.skillKey, isNotEmpty);
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final first = n5.allLessons.first;
      expect(first.totalMinutes, greaterThan(0));
      expect(first.estimatedMinutes, greaterThan(0));
    });

    test('N4 unlock needs all N5 lessons + final >= 70', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final n4 = CurriculumCatalogData.levelById('N4')!;
      final progress = <String, UserLessonProgress>{};
      final scores = <String, int>{};
      var state = CurriculumEngine.unlockStateFor(
          level: n4, progressById: progress, finalScores: scores);
      expect(state.unlocked, isFalse);

      // Tandai semua N5 selesai kecuali final.
      final now = DateTime(2026, 9, 7);
      for (final lesson in n5.allLessons) {
        if (lesson.isFinalTest) continue;
        progress[lesson.id] = UserLessonProgress(
            lessonId: lesson.id,
            status: CurriculumLessonStatus.completed,
            updatedAt: now);
      }
      state = CurriculumEngine.unlockStateFor(
          level: n4, progressById: progress, finalScores: scores);
      expect(state.unlocked, isFalse);
      expect(state.allLessonsDone, isFalse);

      for (final lesson in n5.allLessons) {
        progress[lesson.id] = UserLessonProgress(
            lessonId: lesson.id,
            status: CurriculumLessonStatus.completed,
            bestScore: lesson.isFinalTest ? 60 : 0,
            updatedAt: now);
      }
      scores['N5'] = 60;
      state = CurriculumEngine.unlockStateFor(
          level: n4, progressById: progress, finalScores: scores);
      expect(state.unlocked, isFalse);
      expect(state.finalPassed, isFalse);

      scores['N5'] = 80;
      for (final lesson in n5.allLessons.where((l) => l.isFinalTest)) {
        progress[lesson.id]!.bestScore = 80;
      }
      state = CurriculumEngine.unlockStateFor(
          level: n4, progressById: progress, finalScores: scores);
      expect(state.unlocked, isTrue);
    });

    test('adaptive recommends kanji review when kanji weak', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final rec = CurriculumEngine.adaptiveRecommendation(
        level: n5,
        progressById: {},
        mistakeBySkill: {'kanji': 5, 'vocabulary': 1},
        masteryBySkill: const {},
      );
      expect(rec, isNotNull);
      expect(rec!.skillKey, 'kanji');
      expect(rec.title, contains('Kanji'));
    });

    test('JFT track reuses N5 lessons without duplication', () {
      final a1 = CurriculumCatalogData.levelById('JFT-A1')!;
      final hasReuse = a1.allLessons.any((l) =>
          l.activities.any((a) => a.reusedLessonId != null));
      expect(hasReuse, isTrue);
      final reusedId = a1.allLessons
          .expand((l) => l.activities)
          .firstWhere((a) => a.reusedLessonId != null)
          .reusedLessonId!;
      expect(CurriculumCatalogData.lessonById(reusedId), isNotNull);
    });

    test('level progress percent computes correctly', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final progress = <String, UserLessonProgress>{};
      var lp = CurriculumEngine.levelProgress(
          level: n5, progressById: progress, unlocked: true);
      expect(lp.percent, 0);
      progress[n5.allLessons.first.id] = UserLessonProgress(
          lessonId: n5.allLessons.first.id,
          status: CurriculumLessonStatus.completed);
      lp = CurriculumEngine.levelProgress(
          level: n5, progressById: progress, unlocked: true);
      expect(lp.completedLessons, 1);
      expect(lp.percent,
          closeTo(1 / n5.totalLessons, 0.001));
    });
  });
}
