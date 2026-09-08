import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_study/features/curriculum/curriculum_catalog.dart';
import 'package:japanese_study/features/curriculum/curriculum_engine.dart';
import 'package:japanese_study/features/curriculum/curriculum_models.dart';
import 'package:japanese_study/features/curriculum/lesson_questions.dart';
import 'package:japanese_study/models/grammar_point.dart';
import 'package:japanese_study/models/kanji.dart';
import 'package:japanese_study/models/phrase_item.dart';
import 'package:japanese_study/models/vocabulary.dart';
import 'package:japanese_study/services/content_repository.dart';
import 'package:japanese_study/services/tts_service.dart';
import 'package:japanese_study/state/app_controller.dart';

// Definition of Done N5 Bab 1 (はじめまして): unlock, isolasi konten,
// listening/reading, review, final test ≥17 soal, XP anti-farm,
// persistence + reset. Tanpa server, tanpa emulator.

class _FakeRepo extends ContentRepository {
  _FakeRepo({
    required Map<String, PhraseItem> phrases,
    required Map<int, Vocabulary> vocabs,
    required Map<String, GrammarPoint> grammars,
    required Map<int, Kanji> kanjis,
  })  : _phrases = phrases,
        _vocabs = vocabs,
        _grammars = grammars,
        _kanjis = kanjis;

  final Map<String, PhraseItem> _phrases;
  final Map<int, Vocabulary> _vocabs;
  final Map<String, GrammarPoint> _grammars;
  final Map<int, Kanji> _kanjis;

  @override
  PhraseItem? phraseById(String id) => _phrases[id];

  @override
  Vocabulary? vocabularyById(int id) => _vocabs[id];

  @override
  GrammarPoint? grammarById(String id) => _grammars[id];

  @override
  Kanji? kanjiById(int id) => _kanjis[id];
}

List<Map<String, dynamic>> _loadList(String path) =>
    (jsonDecode(File(path).readAsStringSync(encoding: utf8)) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

/// Repo dari DATA ASLI yang difilter HANYA ke ID termapping Bab 1.
/// Meniru resolve produksi tanpa memuat seluruh N5.
_FakeRepo _bab1Repo() {
  final unit = CurriculumCatalogData.unitById('n5-u01')!;
  final phraseIds = <String>{};
  final vocabIds = <int>{};
  final grammarIds = <String>{};
  final kanjiIds = <int>{};
  for (final lesson in unit.lessons) {
    phraseIds.addAll(lesson.phraseIds);
    for (final id in lesson.vocabularyIds) {
      final parsed = int.tryParse(id);
      if (parsed != null) vocabIds.add(parsed);
    }
    grammarIds.addAll(lesson.grammarIds);
    for (final id in lesson.kanjiIds) {
      final parsed = int.tryParse(id);
      if (parsed != null) kanjiIds.add(parsed);
    }
  }
  final phrases = {
    for (final e in _loadList('assets/data/phrases.json'))
      if (phraseIds.contains('${e['id']}'))
        '${e['id']}': PhraseItem.fromJson(e),
  };
  final vocabs = {
    for (final e in _loadList('assets/data/vocabulary.json'))
      if (vocabIds.contains((e['id'] as num).toInt()))
        (e['id'] as num).toInt(): Vocabulary.fromJson(e),
  };
  final grammars = {
    for (final e in _loadList('assets/data/grammar.json'))
      if (grammarIds.contains('${e['id']}'))
        '${e['id']}': GrammarPoint.fromJson(e),
  };
  final kanjis = {
    for (final e in _loadList('assets/data/kanji.json'))
      if (kanjiIds.contains((e['id'] as num).toInt()))
        (e['id'] as num).toInt(): Kanji.fromJson(e),
  };
  return _FakeRepo(
      phrases: phrases, vocabs: vocabs, grammars: grammars, kanjis: kanjis);
}

AppController _controller() => AppController(
      repository: ContentRepository(),
      tts: TtsService(),
    );

void main() {
  group('DoD Bab 1: unlock progression', () {
    test('Test 1 fresh user: hanya Lesson 1 unlocked', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      final ordered = CurriculumEngine.orderedLessons(n5)
          .where((l) => l.unitId == unit.id)
          .toList();
      final statuses = CurriculumEngine.statusesForLevel(
          level: n5, progressById: {});
      expect(statuses[ordered.first.id], CurriculumLessonStatus.available);
      for (final lesson in ordered.skip(1)) {
        expect(statuses[lesson.id], CurriculumLessonStatus.locked);
      }
    });

    test('Test 2: Lesson 1 selesai -> Lesson 2 buka, 3 terkunci',
        () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      final ordered = CurriculumEngine.orderedLessons(n5)
          .where((l) => l.unitId == unit.id)
          .toList();
      final progress = <String, UserLessonProgress>{};
      final now = DateTime(2026, 9, 8);
      for (final activity in ordered.first.activities) {
        CurriculumEngine.completeActivity(
            lesson: ordered.first,
            progressById: progress,
            activityId: activity.id,
            now: now);
      }
      final statuses = CurriculumEngine.statusesForLevel(
          level: n5, progressById: progress);
      expect(statuses[ordered[0].id], CurriculumLessonStatus.completed);
      expect(statuses[ordered[1].id], CurriculumLessonStatus.available);
      expect(statuses[ordered[2].id], CurriculumLessonStatus.locked);
    });

    test('Test 8 locked lesson berstatus locked (UI wajib menolak)', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final statuses = CurriculumEngine.statusesForLevel(
          level: n5, progressById: {});
      final l06 = CurriculumCatalogData.lessonById('n5-u01-l06')!;
      expect(
          CurriculumEngine.lessonStatus(
              lesson: l06,
              ordered: CurriculumEngine.orderedLessons(n5),
              progressById: {}),
          CurriculumLessonStatus.locked);
      expect(statuses[l06.id], CurriculumLessonStatus.locked);
    });
  });

  group('DoD Bab 1: isolasi konten', () {
    test('Test 3 setiap lesson resolve penuh dari ID-nya sendiri', () {
      final repo = _bab1Repo();
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      for (final lesson in unit.lessons) {
        final resolved = resolveLessonContent(repo, lesson);
        expect(resolved.phrases.length, lesson.phraseIds.length,
            reason: '${lesson.id} phrases');
        expect(resolved.vocabs.length, lesson.vocabularyIds.length,
            reason: '${lesson.id} vocabs');
        expect(resolved.grammars.length, lesson.grammarIds.length,
            reason: '${lesson.id} grammars');
        expect(resolved.kanjis.length, lesson.kanjiIds.length,
            reason: '${lesson.id} kanjis');
      }
    });

    test('Test 4 pool unit hanya berisi ID Bab 1 (tanpa Bab 2)', () {
      final repo = _bab1Repo();
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      final allowedVocab = <int>{};
      final allowedGrammar = <String>{};
      final allowedKanji = <int>{};
      for (final lesson in unit.lessons) {
        for (final id in lesson.vocabularyIds) {
          allowedVocab.add(int.parse(id));
        }
        allowedGrammar.addAll(lesson.grammarIds);
        for (final id in lesson.kanjiIds) {
          allowedKanji.add(int.parse(id));
        }
      }
      final pool = buildUnitQuestions(repo, unit.lessons);
      expect(pool.length, greaterThanOrEqualTo(17));
      final vocabKeys = pool
          .where((q) => q.masteryKey.startsWith('v:'))
          .map((q) => int.parse(q.masteryKey.substring(2)));
      for (final id in vocabKeys) {
        expect(allowedVocab.contains(id), true, reason: 'vocab $id asing');
      }
      final grammarKeys = pool
          .where((q) => q.masteryKey.startsWith('g:'))
          .map((q) => q.masteryKey.substring(2));
      for (final id in grammarKeys) {
        expect(allowedGrammar.contains(id), true, reason: 'grammar $id asing');
      }
    });
  });

  group('DoD Bab 1: komposisi final test', () {
    late List<PracticeQuestion> pool;

    setUpAll(() {
      final repo = _bab1Repo();
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      pool = buildUnitQuestions(repo, unit.lessons);
    });

    test('Test final: total minimal 17 soal', () {
      expect(pool.length, greaterThanOrEqualTo(17));
    });

    test('Test final: minimal 5 soal grammar', () {
      final grammar = pool
          .where((q) => q.masteryKey.startsWith('g:'))
          .toList();
      expect(grammar.length, greaterThanOrEqualTo(5));
    });

    test('Test final: minimal 3 soal listening ber-audio', () {
      final listening =
          pool.where((q) => q.audio.isNotEmpty).toList();
      expect(listening.length, greaterThanOrEqualTo(3));
    });

    test('Test final: soal reading l09 ikut pool', () {
      final l09 = CurriculumCatalogData.lessonById('n5-u01-l09')!;
      for (final authored in l09.authoredQuestions) {
        expect(pool.any((q) => q.prompt == authored.prompt), true,
            reason: authored.prompt);
      }
    });

    test('Test final: minimal 2 susun-kalimat', () {
      final ordering =
          pool.where((q) => q.tokens.isNotEmpty).toList();
      expect(ordering.length, greaterThanOrEqualTo(2));
      for (final q in ordering) {
        expect(q.tokens.length, greaterThanOrEqualTo(3));
      }
    });

    test('Test final: deterministik (dua build identik)', () {
      final repo = _bab1Repo();
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      final again = buildUnitQuestions(repo, unit.lessons);
      expect(again.length, pool.length);
      for (var i = 0; i < pool.length; i++) {
        expect(again[i].prompt, pool[i].prompt);
        expect(again[i].options, pool[i].options);
      }
    });

    test('Review l05: minimal 10 soal dari Bab 1', () {
      final repo = _bab1Repo();
      final l05 = CurriculumCatalogData.lessonById('n5-u01-l05')!;
      final resolved = resolveLessonContent(repo, l05);
      final questions = buildLessonQuestions(
        phrases: resolved.phrases,
        vocabs: resolved.vocabs,
        grammars: resolved.grammars,
        kanjis: resolved.kanjis,
        listening: true,
        authored: l05.authoredQuestions,
      );
      expect(questions.length, greaterThanOrEqualTo(10));
    });
  });

  group('DoD Bab 1: XP anti-farm + mastery + best', () {
    test('Test 9 XP final: hanya best baru yang lulus dapat XP', () {
      const total = 60;
      expect(
          CurriculumEngine.finalTestXpReward(
              passed: true, score: 80, prevBest: 0, totalXp: total),
          total);
      expect(
          CurriculumEngine.finalTestXpReward(
              passed: true, score: 80, prevBest: 80, totalXp: total),
          0);
      expect(
          CurriculumEngine.finalTestXpReward(
              passed: true, score: 70, prevBest: 80, totalXp: total),
          0);
      expect(
          CurriculumEngine.finalTestXpReward(
              passed: false, score: 60, prevBest: 0, totalXp: total),
          0);
    });

    test('Mastery: +1/-1 clamp -5..+10', () {
      final app = _controller();
      app.recordLessonMastery(
          correctKeys: const ['v:313'], wrongKeys: const []);
      app.recordLessonMastery(
          correctKeys: const ['v:313'], wrongKeys: const []);
      app.recordLessonMastery(
          correctKeys: const ['v:313'], wrongKeys: const []);
      expect(app.lessonMasteryScore('v:313'), 3);
      for (var i = 0; i < 20; i++) {
        app.recordLessonMastery(
            correctKeys: const [], wrongKeys: const ['v:313']);
      }
      expect(app.lessonMasteryScore('v:313'), -5);
      expect(AppController.masteryTier(score: 3, mastered: false), 2);
      expect(AppController.masteryTier(score: 1, mastered: false), 1);
      expect(AppController.masteryTier(score: 0, mastered: false), 0);
      expect(AppController.masteryTier(score: 0, mastered: true), 2);
    });

    test('Best latihan hanya naik', () {
      final app = _controller();
      app.recordPracticeBest('n5-u01-l01', 70);
      app.recordPracticeBest('n5-u01-l01', 60);
      expect(app.practiceBest['n5-u01-l01'], 70);
      app.recordPracticeBest('n5-u01-l01', 90);
      expect(app.practiceBest['n5-u01-l01'], 90);
    });

    test('Test 5/10 persistence: export lalu import utuh', () async {
      final app = _controller();
      app.recordLessonMastery(
          correctKeys: const ['v:313', 'g:n5-wa'], wrongKeys: const ['k:42']);
      app.recordPracticeBest('n5-u01-l01', 80);
      final dumped = app.exportProgress();
      final fresh = _controller();
      final ok = await fresh.importProgress(dumped);
      expect(ok, true);
      expect(fresh.lessonMasteryScore('v:313'), 1);
      expect(fresh.lessonMasteryScore('g:n5-wa'), 1);
      expect(fresh.lessonMasteryScore('k:42'), -1);
      expect(fresh.practiceBest['n5-u01-l01'], 80);
    });

    test('Reset Bab 1: kembali ke awal, unit lain aman', () async {
      final app = _controller();
      final now = DateTime(2026, 9, 8);
      // Selesaikan l01 + catat mastery/best.
      final l01 = CurriculumCatalogData.lessonById('n5-u01-l01')!;
      for (final activity in l01.activities) {
        app.completeCurriculumActivity(l01.id, activity.id);
      }
      app.recordLessonMastery(
          correctKeys: const ['v:313'], wrongKeys: const []);
      app.recordPracticeBest('n5-u01-l01', 80);
      final xpBefore = app.xp;
      expect(xpBefore, greaterThan(0));
      expect(
          app.curriculumProgressById['n5-u01-l01']?.status,
          CurriculumLessonStatus.completed);

      await app.resetUnitProgress('n5-u01');

      // Test O: hanya Lesson 1 unlocked, sisanya locked.
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final statuses = CurriculumEngine.statusesForLevel(
          level: n5, progressById: app.curriculumProgressById);
      final ordered = CurriculumEngine.orderedLessons(n5)
          .where((l) => l.unitId == 'n5-u01')
          .toList();
      expect(statuses[ordered.first.id], CurriculumLessonStatus.available);
      for (final lesson in ordered.skip(1)) {
        expect(statuses[lesson.id], CurriculumLessonStatus.locked);
      }
      // Mastery + best bersih, XP berkurang.
      expect(app.lessonMasteryScore('v:313'), 0);
      expect(app.practiceBest.containsKey('n5-u01-l01'), false);
      expect(app.xp, lessThan(xpBefore));
      expect(app.xp, greaterThanOrEqualTo(0));
    });
  });

  group('DoD §26: blueprint Bab 1', () {
    test('L0 intro ada: sequence 0, intro+quiz, notes, 3 soal', () {
      final l00 = CurriculumCatalogData.lessonById('n5-u01-l00')!;
      expect(l00.sequence, 0);
      expect(l00.objectives.length, 2);
      expect(l00.notes.length, 1);
      expect(l00.notes.first.lines.length, 4);
      expect(l00.authoredQuestions.length, 3);
      expect(
          l00.activities
              .where((a) => a.type == CurriculumActivityType.introduction),
          hasLength(1));
      expect(
          l00.activities
              .where((a) => a.type == CurriculumActivityType.quiz),
          hasLength(1));
    });

    test('Ownership: introducedInLessonId benar per kunci', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final ownership = CurriculumEngine.introducedInLessonId(n5);
      expect(ownership['v:313'], 'n5-u01-l01');
      expect(ownership['v:295'], 'n5-u01-l03');
      expect(ownership['g:n5-no'], 'n5-u01-l04a');
      // n5-wa sudah diperkenalkan di l01 (kartu grammar salam).
      expect(ownership['g:n5-wa'], 'n5-u01-l01');
      expect(ownership['k:179'], 'n5-u01-l03');
      expect(ownership['p:ph-0001'], 'n5-u01-l01');
    });

    test('Caps: vocab baru per lesson ≤7, unit unik ≤30', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final ownership = CurriculumEngine.introducedInLessonId(n5);
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      final seen = <String>{};
      for (final lesson in CurriculumEngine.orderedLessons(n5)
          .where((l) => l.unitId == unit.id)) {
        var fresh = 0;
        for (final id in lesson.vocabularyIds) {
          if (ownership['v:$id'] == lesson.id) fresh++;
        }
        expect(fresh, lessThanOrEqualTo(7),
            reason: '${lesson.id} memperkenalkan $fresh vocab');
      }
      final unique =
          ownership.keys.where((k) => k.startsWith('v:')).toSet();
      final inUnit = <String>{};
      for (final lesson in unit.lessons) {
        for (final id in lesson.vocabularyIds) {
          inUnit.add('v:$id');
        }
      }
      expect(inUnit.length, lessThanOrEqualTo(30));
      expect(unique.containsAll(inUnit), true);
    });

    test('Review l05 tidak memperkenalkan vocab baru', () {
      final n5 = CurriculumCatalogData.levelById('N5')!;
      final ownership = CurriculumEngine.introducedInLessonId(n5);
      final l05 = CurriculumCatalogData.lessonById('n5-u01-l05')!;
      for (final id in l05.vocabularyIds) {
        expect(ownership['v:$id'] == 'n5-u01-l05', false,
            reason: 'v:$id diklaim review');
      }
    });

    test('Gate skor: klaim quiz butuh ≥70', () {
      expect(meetsScoreGate(69), false);
      expect(meetsScoreGate(70), true);
      expect(meetsScoreGate(100), true);
    });

    test('Bonus Bab: pass boss pertama + unit done = +100', () async {
      final app = _controller();
      final unit = CurriculumCatalogData.unitById('n5-u01')!;
      for (final lesson in unit.lessons) {
        if (lesson.id == 'n5-u01-l06') continue;
        for (final activity in lesson.activities) {
          app.completeCurriculumActivity(lesson.id, activity.id);
        }
      }
      final before = app.xp;
      final passed =
          app.recordCurriculumFinalTest('n5-u01-l06', 80);
      expect(passed, true);
      final delta = app.xp - before;
      // 50 XP tes (unitTest) + 80 XP kuis (8 benar) + 100 bonus bab.
      expect(delta, 230);
      final before2 = app.xp;
      app.recordCurriculumFinalTest('n5-u01-l06', 80);
      expect(app.xp - before2, 0);
    });
  });

  group('DoD Bab 1: audio + grade', () {
    test('TTS speak selesai tanpa throw (mesin boleh absen)', () async {
      final tts = TtsService();
      await tts.speak('はじめまして。');
      await tts.stop();
    });

    test('Grade: 90/80/70/<70', () {
      expect(gradeFor(95), 'Excellent');
      expect(gradeFor(90), 'Excellent');
      expect(gradeFor(85), 'Great');
      expect(gradeFor(80), 'Great');
      expect(gradeFor(75), 'Passed');
      expect(gradeFor(70), 'Passed');
      expect(gradeFor(69), 'Review required');
    });
  });
}
