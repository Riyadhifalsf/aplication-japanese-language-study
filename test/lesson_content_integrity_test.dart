import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_study/features/curriculum/curriculum_catalog.dart';
import 'package:japanese_study/features/curriculum/curriculum_models.dart';
import 'package:japanese_study/services/content_repository.dart';

/// Menjamin lesson kurikulum hanya mereferensikan konten yang BENAR-BENAR
/// ada di bundled data (anti invent mapping). Jika katalog menambah
/// vocabularyIds/grammarIds/kanjiIds/phraseIds baru, test ini memaksa ID
/// tersebut valid + relevan level.
void main() {
  // Bundled JSON adalah raw List (bukan envelope server).
  List<Map<String, dynamic>> loadList(String path) {
    final raw = File(path).readAsStringSync(encoding: utf8);
    return (jsonDecode(raw) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  group('Lesson content integrity (no invented mapping)', () {
    test('n5-u01-l01 punya kurikulum inline nyata', () {
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l01')!;
      expect(lesson.hasInlineContent, true);
      expect(lesson.objectives.length, 6);
      expect(lesson.phraseIds,
          ['ph-0001', 'ph-0002', 'ph-0003', 'ph-0011', 'ph-0012', 'ph-0013']);
      expect(lesson.vocabularyIds, ['123', '124', '313', '377', '405', '93']);
      expect(lesson.grammarIds, ['n5-wa', 'n5-ka']);
      expect(lesson.kanjiIds, ['56', '48', '42', '41', '40', '29']);
    });

    test('phraseIds ada di phrases.json', () {
      final phrases = loadList('assets/data/phrases.json');
      final byId = {for (final p in phrases) '${p['id']}': p};
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l01')!;
      for (final id in lesson.phraseIds) {
        expect(byId.containsKey(id), true, reason: 'phrase $id hilang');
      }
      // Isi pedagogis: salam + catatan penggunaan.
      expect(byId['ph-0001']!['category'], 'Salam');
      expect(byId['ph-0003']!['category'], 'Perkenalan');
    });

    test('vocabularyIds ada di vocabulary.json level N5', () {
      final vocab = loadList('assets/data/vocabulary.json');
      final byId = {for (final v in vocab) '${v['id']}': v};
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l01')!;
      for (final id in lesson.vocabularyIds) {
        expect(byId.containsKey(id), true, reason: 'vocab $id hilang');
        expect(byId[id]!['level'], 'N5', reason: 'vocab $id bukan N5');
      }
    });

    test('grammarIds ada di grammar.json', () {
      final grammar = loadList('assets/data/grammar.json');
      final byId = {for (final g in grammar) '${g['id']}': g};
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l01')!;
      for (final id in lesson.grammarIds) {
        expect(byId.containsKey(id), true, reason: 'grammar $id hilang');
      }
      expect(byId['n5-wa']!['pattern'], '～は～です');
    });

    test('kanjiIds ada di kanji.json level N5', () {
      final kanji = loadList('assets/data/kanji.json');
      final byId = {for (final k in kanji) '${k['id']}': k};
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l01')!;
      for (final id in lesson.kanjiIds) {
        expect(byId.containsKey(id), true, reason: 'kanji $id hilang');
        expect(byId[id]!['level'], 'N5', reason: 'kanji $id bukan N5');
      }
    });

    test('n5-u01-l02 pola desu & wa termapping valid', () {
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l02')!;
      expect(lesson.hasInlineContent, true);
      expect(lesson.objectives.length, 4);
      expect(lesson.grammarIds, ['n5-wa']);
      expect(lesson.vocabularyIds, ['123', '313', '377']);
      expect(lesson.kanjiIds, ['42', '41', '40']);
      final vocab = loadList('assets/data/vocabulary.json');
      final vById = {for (final v in vocab) '${v['id']}': v};
      for (final id in lesson.vocabularyIds) {
        expect(vById.containsKey(id), true, reason: 'vocab $id hilang');
        expect(vById[id]!['level'], 'N5', reason: 'vocab $id bukan N5');
      }
      final kanji = loadList('assets/data/kanji.json');
      final kById = {for (final k in kanji) '${k['id']}': k};
      for (final id in lesson.kanjiIds) {
        expect(kById.containsKey(id), true, reason: 'kanji $id hilang');
        expect(kById[id]!['level'], 'N5', reason: 'kanji $id bukan N5');
      }
      expect(
          lesson.activities
              .where((a) => a.type == CurriculumActivityType.quiz),
          hasLength(1));
    });

    test('n5-u01-l03 orang & profesi termapping valid', () {
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l03')!;
      expect(lesson.hasInlineContent, true);
      expect(lesson.objectives.length, 3);
      expect(lesson.vocabularyIds, ['313', '377', '93', '295']);
      expect(lesson.kanjiIds, ['42', '41', '40', '29', '179', '138']);
      final vocab = loadList('assets/data/vocabulary.json');
      final vById = {for (final v in vocab) '${v['id']}': v};
      for (final id in lesson.vocabularyIds) {
        expect(vById.containsKey(id), true, reason: 'vocab $id hilang');
        expect(vById[id]!['level'], 'N5', reason: 'vocab $id bukan N5');
      }
      expect(
          lesson.activities
              .where((a) => a.type == CurriculumActivityType.quiz),
          hasLength(1));
    });

    test('n5-u01-l04a asal & bahasa: tanpa speaking, ada listening + quiz',
        () {
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l04a')!;
      expect(lesson.grammarIds, ['n5-no']);
      expect(
          lesson.activities
              .where((a) => a.type == CurriculumActivityType.speaking),
          isEmpty);
      expect(
          lesson.activities
              .where((a) => a.type == CurriculumActivityType.listening),
          hasLength(1));
      expect(
          lesson.activities
              .where((a) => a.type == CurriculumActivityType.quiz),
          hasLength(1));
    });

    test('n5-u01-l04 nama & san: notes + soal authored valid', () {
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l04')!;
      expect(lesson.objectives.length, 3);
      expect(lesson.notes.length, 1);
      expect(lesson.notes.first.lines.length, 3);
      for (final line in lesson.notes.first.lines) {
        expect(line.japanese.isNotEmpty, true);
        expect(line.meaning.isNotEmpty, true);
      }
      expect(lesson.authoredQuestions.length, 3);
      for (final q in lesson.authoredQuestions) {
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
      }
      expect(
          lesson.activities
              .where((a) => a.type == CurriculumActivityType.quiz),
          hasLength(1));
    });

    test('l07 じん, l08 listening, l09 reading, l10 speaking template', () {
      final jin = CurriculumCatalogData.lessonById('n5-u01-l07')!;
      expect(jin.objectives.length, 3);
      expect(jin.notes.length, 1);
      expect(jin.authoredQuestions.length, 3);
      final listen = CurriculumCatalogData.lessonById('n5-u01-l08')!;
      expect(
          listen.activities
              .where((a) => a.type == CurriculumActivityType.listening),
          hasLength(1));
      expect(
          listen.authoredQuestions
              .where((q) => q.audio.isNotEmpty),
          hasLength(3));
      final read = CurriculumCatalogData.lessonById('n5-u01-l09')!;
      expect(read.vocabularyIds, ['123', '313']);
      expect(read.authoredQuestions.length, 3);
      final speak = CurriculumCatalogData.lessonById('n5-u01-l10')!;
      expect(
          speak.activities
              .where((a) => a.type == CurriculumActivityType.speaking),
          hasLength(1));
      expect(
          speak.activities
              .where((a) => a.type == CurriculumActivityType.quiz),
          isEmpty);
    });

    test('unit 1 urutan 1..11 unik (11 micro-lesson)', () {
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      final sequences =
          unit.lessons.map((l) => l.sequence).toList()..sort();
      expect(sequences, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    });

    test('n5-u01-l06 tes bab boss skor 70', () {
      final lesson = CurriculumCatalogData.lessonById('n5-u01-l06')!;
      expect(lesson.isBossTest, true);
      expect(lesson.requiredScore, 70);
    });

    test('LessonActivity contentIds round-trip JSON', () {
      const activity = LessonActivity(
        id: 'a1',
        type: CurriculumActivityType.vocabulary,
        title: 'Kosakata salam',
        contentIds: ['313', '377'],
      );
      final restored = LessonActivity.fromJson(
          Map<dynamic, dynamic>.from(activity.toJson()));
      expect(restored.contentIds, ['313', '377']);
      // Default backward compatible: kosong.
      const legacy = LessonActivity(
        id: 'a0',
        type: CurriculumActivityType.quiz,
        title: 'Quiz',
      );
      expect(legacy.contentIds, isEmpty);
    });

    test('grammarById/phraseById null-safe saat repository kosong', () {
      final repo = ContentRepository();
      expect(repo.grammarById('n5-wa'), isNull);
      expect(repo.phraseById('ph-0001'), isNull);
    });
  });
}
