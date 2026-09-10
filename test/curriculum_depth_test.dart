import 'package:flutter_test/flutter_test.dart';

import 'package:japanese_study/features/curriculum/curriculum_catalog.dart';

void main() {
  group('curriculum depth', () {
    const expectedChapters = <String, int>{
      'N5': 30,
      'N4': 25,
      'N3': 20,
      'N2': 20,
      'N1': 21,
    };

    for (final entry in expectedChapters.entries) {
      final level = entry.key;
      final expectedCount = entry.value;

      test('$level has the expected complete chapter surface', () {
        final curriculum = CurriculumCatalogData.levelById(level);
        expect(curriculum, isNotNull);
        expect(curriculum!.units.length, expectedCount);

        final lessonCount = curriculum.units
            .fold<int>(0, (sum, unit) => sum + unit.lessons.length);
        expect(lessonCount, greaterThanOrEqualTo(expectedCount * 3));

        for (final unit in curriculum.units) {
          expect(unit.sequence, greaterThan(0));
          expect(unit.title.trim(), isNotEmpty);
          expect(unit.description.trim(), isNotEmpty);
          expect(unit.lessons, isNotEmpty);
        }
      });

      test('$level deep chapters contain a full six-step learning loop', () {
        final curriculum = CurriculumCatalogData.levelById(level)!;
        final deepUnits = curriculum.units
            .where((unit) => unit.id.contains('-deep-'))
            .toList();

        expect(deepUnits, isNotEmpty);
        for (final unit in deepUnits) {
          expect(unit.lessons.length, 6);
          expect(unit.lessons.map((lesson) => lesson.sequence).toList(),
              [1, 2, 3, 4, 5, 6]);
          for (final lesson in unit.lessons) {
            expect(lesson.title.trim(), isNotEmpty);
            expect(lesson.objectives, isNotEmpty);
            expect(lesson.activities, isNotEmpty);
            expect(lesson.notes, isNotEmpty);
          }
        }
      });
    }

    test('N5 starts with the foundational Japanese curriculum', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      expect(n5.units.first.sequence, 1);
      expect(n5.units.first.id, 'n5-u01');
      expect(n5.units.first.title, 'Japanese Basics');
      expect(n5.units[1].title, 'Hiragana');
      expect(n5.units[2].title, 'Katakana');
      expect(n5.units.first.lessons, isNotEmpty);
    });

    test('N5 and N4 requested chapter counts are exact', () {
      expect(CurriculumCatalogData.levelById('N5')!.units.length, 30);
      expect(CurriculumCatalogData.levelById('N4')!.units.length, 25);
    });
  });
}
