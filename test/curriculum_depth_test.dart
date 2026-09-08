import 'package:flutter_test/flutter_test.dart';

import 'package:japanese_study/features/curriculum/curriculum_catalog.dart';

void main() {
  group('curriculum depth', () {
    for (final level in ['N5', 'N4', 'N3', 'N2', 'N1']) {
      test('$level has a complete chapter/subchapter surface', () {
        final curriculum = CurriculumCatalogData.levelById(level);
        expect(curriculum, isNotNull);
        expect(curriculum!.units.length, greaterThanOrEqualTo(20));
        final lessonCount = curriculum.units
            .fold<int>(0, (sum, unit) => sum + unit.lessons.length);
        expect(lessonCount, greaterThanOrEqualTo(100));
        for (final unit in curriculum.units) {
          expect(unit.title.trim(), isNotEmpty);
          expect(unit.description.trim(), isNotEmpty);
          expect(unit.lessons, isNotEmpty);
        }
      });
    }

    test('N5 starts with the foundational Japanese curriculum', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      expect(n5.units.first.sequence, 1);
      expect(n5.units.first.lessons, isNotEmpty);
    });
  });
}
