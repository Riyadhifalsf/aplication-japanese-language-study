import 'package:flutter_test/flutter_test.dart';
import 'package:aplication_japanese_language_study/features/curriculum/n5_research_curriculum.dart';

void main() {
  test('N5 has 31 ordered chapters', () {
    expect(N5ResearchCurriculum.chapters.length, 31);
  });

  test('N5 target vocabulary has no duplicate ownership', () {
    expect(N5ResearchCurriculum.duplicateTargetVocabulary, isEmpty);
  });

  test('chapter IDs are unique and sequential', () {
    final ids = N5ResearchCurriculum.chapters.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.first, 'n5-01');
    expect(ids.last, 'n5-31');
  });

  test('final chapter introduces no new vocabulary', () {
    expect(N5ResearchCurriculum.chapters.last.vocabulary, isEmpty);
  });
}
