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
