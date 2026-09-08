import '../../models/grammar_point.dart';
import '../../models/kanji.dart';
import '../../models/phrase_item.dart';
import '../../models/vocabulary.dart';
import '../../services/content_repository.dart';
import 'curriculum_models.dart';

// Modul murni (tanpa Flutter): soal deterministik untuk latihan/tes lesson.
// Dipakai UI lesson DAN unit test — logika soal hanya ada di satu tempat.
//
// Aturan:
// - Urutan tetap: mudah → sulit (panduan 0 → mahir, tanpa random global).
// - Hanya memakai item yang ADA (guard panjang); tidak pernah mengarang.
// - [masteryKey]: 'v:<id>' / 'g:<id>' / 'k:<id>' untuk pencatatan mastery;
//   kosong = tidak dicatat (mis. soal salam tanpa ID mastery).
// - Bagian grammar memakai pola Bab 1 terverifikasi (n5-wa/n5-ka/n5-no);
//   contoh kalimat diambil dari data grammar (bukan karangan).

/// Satu soal latihan/tes.
class PracticeQuestion {
  const PracticeQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.reading = '',
    this.meaning = '',
    this.audio = '',
    this.tokens = const [],
    this.masteryKey = '',
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String reading;
  final String meaning;

  /// Bila diisi: soal listening (putar via TTS, teks disembunyikan).
  final String audio;

  /// Bila diisi: soal susun-kalimat dalam URUTAN BENAR.
  final List<String> tokens;
  final String masteryKey;

  bool get isOrdering => tokens.isNotEmpty;
  bool get isListening => audio.isNotEmpty;
}

/// Gerbang skor latihan: quiz activity hanya selesai bila skor ≥70%.
bool meetsScoreGate(int percent) => percent >= 70;

/// Nilai huruf tes bab: 90+ Excellent, 80+ Great, 70+ Passed.
String gradeFor(int percent) => percent >= 90
    ? 'Excellent'
    : percent >= 80
        ? 'Great'
        : percent >= 70
            ? 'Passed'
            : 'Review required';

/// Bangun soal dari konten lesson yang sudah di-resolve.
List<PracticeQuestion> buildLessonQuestions({
  required List<PhraseItem> phrases,
  required List<Vocabulary> vocabs,
  required List<GrammarPoint> grammars,
  required List<Kanji> kanjis,
  bool listening = false,
  List<AuthoredQuestion> authored = const [],
}) {
  final qs = <PracticeQuestion>[];
  // 1-2. Salam: arti + situasi (butuh ≥3).
  if (phrases.length >= 3) {
    qs.add(PracticeQuestion(
      prompt: '「${phrases[0].japanese}」 artinya?',
      options: [phrases[0].meaning, phrases[1].meaning, phrases[2].meaning],
      correctIndex: 0,
      explanation: 'Hafalkan pasangan salam–artinya di Bagian 1.',
      reading: phrases[0].reading,
      meaning: phrases[0].meaning,
    ));
    qs.add(PracticeQuestion(
      prompt: 'Bertemu guru di pagi hari, salam yang tepat?',
      options: [
        phrases[0].japanese,
        phrases[1].japanese,
        phrases[2].japanese
      ],
      correctIndex: 0,
      explanation: phrases[0].note,
      reading: phrases[0].reading,
      meaning: phrases[0].meaning,
    ));
    // 3. Kesopanan (butuh varian Sopan).
    if (phrases.length >= 6) {
      qs.add(PracticeQuestion(
        prompt: 'Menyapa teman dekat dengan santai, pilih yang tepat?',
        options: [
          phrases[3].japanese,
          phrases[0].japanese,
          phrases[1].japanese
        ],
        correctIndex: 0,
        explanation: phrases[3].note,
        reading: phrases[3].reading,
        meaning: phrases[3].meaning,
      ));
    }
  }
  // 4-5. Kotoba (butuh ≥3).
  if (vocabs.length >= 3) {
    qs.add(PracticeQuestion(
      prompt: '「${vocabs[0].word}」 dibaca?',
      options: [vocabs[0].reading, vocabs[1].reading, vocabs[2].reading],
      correctIndex: 0,
      explanation: 'Perhatikan bacaan di Bagian 2.',
      reading: vocabs[0].reading,
      meaning: vocabs[0].meaning,
      masteryKey: 'v:${vocabs[0].id}',
    ));
    qs.add(PracticeQuestion(
      prompt: '「${vocabs[1].word}」 artinya?',
      options: [vocabs[1].meaning, vocabs[0].meaning, vocabs[2].meaning],
      correctIndex: 0,
      explanation: 'Pasangan kata–arti ada di Bagian 2.',
      reading: vocabs[1].reading,
      meaning: vocabs[1].meaning,
      masteryKey: 'v:${vocabs[1].id}',
    ));
  }
  // 6-10. Grammar Bab 1 terverifikasi (n5-wa / n5-no / n5-ka).
  final byId = <String, GrammarPoint>{for (final g in grammars) g.id: g};
  final wa = byId['n5-wa'];
  if (wa != null) {
    qs.add(PracticeQuestion(
      prompt: 'Lengkapi: わたし ___ がくせいです。',
      options: const ['は', 'の', 'か'],
      correctIndex: 0,
      explanation: 'Pola ${wa.pattern}: ${wa.formation}.',
      masteryKey: 'g:n5-wa',
    ));
    qs.add(PracticeQuestion(
      prompt: 'Pilih kalimat yang benar.',
      options: const [
        'わたしは がくせいです',
        'わたしのがくせいです',
        'わたしがくせいです'
      ],
      correctIndex: 0,
      explanation: 'Pola ${wa.pattern}: topik + は.',
      masteryKey: 'g:n5-wa',
    ));
  }
  final no = byId['n5-no'];
  if (no != null) {
    if (no.examples.isNotEmpty) {
      final ex = no.examples.first;
      final blanked = ex.japanese.replaceFirst('の', '___');
      if (blanked != ex.japanese) {
        qs.add(PracticeQuestion(
          prompt: 'Lengkapi: $blanked',
          options: const ['の', 'は', 'か'],
          correctIndex: 0,
          explanation: 'Contoh: ${ex.japanese} — ${ex.meaning}.',
          reading: ex.reading,
          meaning: ex.meaning,
          masteryKey: 'g:n5-no',
        ));
      }
    }
    qs.add(PracticeQuestion(
      prompt: '～の～ dipakai untuk?',
      options: const [
        'Menghubungkan kata benda',
        'Menandai topik',
        'Membuat pertanyaan'
      ],
      correctIndex: 0,
      explanation: 'Fungsi dari pola ${no.pattern}.',
      masteryKey: 'g:n5-no',
    ));
  }
  final ka = byId['n5-ka'];
  if (ka != null && ka.examples.isNotEmpty) {
    final ex = ka.examples.first;
    final others = [
      for (final g in grammars)
        if (g.id != 'n5-ka' && g.examples.isNotEmpty)
          g.examples.first.meaning,
    ];
    if (others.length >= 2) {
      qs.add(PracticeQuestion(
        prompt: '「${ex.japanese}」 artinya?',
        options: [ex.meaning, others[0], others[1]],
        correctIndex: 0,
        explanation: 'Kalimat tanya: ${ka.pattern}.',
        reading: ex.reading,
        meaning: ex.meaning,
        masteryKey: 'g:n5-ka',
      ));
    }
  }
  // Kanji penyusun kata bab (butuh ≥3).
  if (kanjis.length >= 3) {
    qs.add(PracticeQuestion(
      prompt: 'Kanji「${kanjis[2].character}」 artinya?',
      options: [kanjis[2].meaning, kanjis[0].meaning, kanjis[1].meaning],
      correctIndex: 0,
      explanation: 'Kanji penyusun kata bab ini (Bagian 4).',
      masteryKey: 'k:${kanjis[2].id}',
    ));
  }
  // Listening: dengar via TTS, pilih arti.
  if (listening && phrases.length >= 3) {
    qs.add(PracticeQuestion(
      prompt: 'Dengarkan, lalu pilih artinya.',
      options: [phrases[1].meaning, phrases[0].meaning, phrases[2].meaning],
      correctIndex: 0,
      explanation: 'Dengarkan ulang di Bagian 1 bila ragu.',
      reading: phrases[1].reading,
      meaning: phrases[1].meaning,
      audio: phrases[1].japanese,
    ));
  }
  // Soal authored kurikulum (lesson tanpa ID dataset). Soal tokens
  // (susun-kalimat) boleh punya <2 opsi karena jawabannya dari keping.
  for (final a in authored) {
    final isOrdering = a.tokens.isNotEmpty;
    if ((isOrdering || a.options.length >= 2) &&
        a.correctIndex >= 0 &&
        a.correctIndex < a.options.length) {
      qs.add(PracticeQuestion(
        prompt: a.prompt,
        options: a.options,
        correctIndex: a.correctIndex,
        explanation: a.explanation,
        reading: a.reading,
        meaning: a.meaning,
        audio: a.audio,
        tokens: a.tokens,
        masteryKey: a.masteryKey,
      ));
    }
  }
  return qs;
}

/// Hasil resolusi referensi satu lesson: model asli dari repository
/// (tanpa duplikasi objek). ID tak dikenal di-skip diam-diam.
class ResolvedLesson {
  const ResolvedLesson({
    required this.phrases,
    required this.vocabs,
    required this.grammars,
    required this.kanjis,
  });

  final List<PhraseItem> phrases;
  final List<Vocabulary> vocabs;
  final List<GrammarPoint> grammars;
  final List<Kanji> kanjis;

  bool get isEmpty =>
      phrases.isEmpty &&
      vocabs.isEmpty &&
      grammars.isEmpty &&
      kanjis.isEmpty;
}

/// Resolve vocabularyIds/grammarIds/kanjiIds/phraseIds lesson via
/// repository. Urutan = urutan ID di katalog (deterministik).
ResolvedLesson resolveLessonContent(
    ContentRepository repo, CurriculumLesson lesson) {
  int? intId(String raw) => int.tryParse(raw);
  final phrases = <PhraseItem>[];
  for (final id in lesson.phraseIds) {
    final item = repo.phraseById(id);
    if (item != null) phrases.add(item);
  }
  final vocabs = <Vocabulary>[];
  for (final id in lesson.vocabularyIds) {
    final parsed = intId(id);
    final item = parsed == null ? null : repo.vocabularyById(parsed);
    if (item != null) vocabs.add(item);
  }
  final grammars = <GrammarPoint>[];
  for (final id in lesson.grammarIds) {
    final item = repo.grammarById(id);
    if (item != null) grammars.add(item);
  }
  final kanjis = <Kanji>[];
  for (final id in lesson.kanjiIds) {
    final parsed = intId(id);
    final item = parsed == null ? null : repo.kanjiById(parsed);
    if (item != null) kanjis.add(item);
  }
  return ResolvedLesson(
      phrases: phrases, vocabs: vocabs, grammars: grammars, kanjis: kanjis);
}

/// Soal Tes Bab: dari pool unit (deterministik: ID ter-mapping + soal
/// authored tiap lesson). >=6 soal = tes nyata layak.
List<PracticeQuestion> buildUnitQuestions(
    ContentRepository repo, List<CurriculumLesson> lessons) {
  final phrases = <String, PhraseItem>{};
  final vocabs = <int, Vocabulary>{};
  final grammars = <String, GrammarPoint>{};
  final kanjis = <int, Kanji>{};
  final authored = <AuthoredQuestion>[];
  for (final lesson in lessons) {
    final resolved = resolveLessonContent(repo, lesson);
    for (final item in resolved.phrases) {
      phrases.putIfAbsent(item.id, () => item);
    }
    for (final item in resolved.vocabs) {
      vocabs.putIfAbsent(item.id, () => item);
    }
    for (final item in resolved.grammars) {
      grammars.putIfAbsent(item.id, () => item);
    }
    for (final item in resolved.kanjis) {
      kanjis.putIfAbsent(item.id, () => item);
    }
    authored.addAll(lesson.authoredQuestions);
  }
  return buildLessonQuestions(
    phrases: phrases.values.toList(growable: false),
    vocabs: vocabs.values.toList(growable: false),
    grammars: grammars.values.toList(growable: false),
    kanjis: kanjis.values.toList(growable: false),
    listening: true,
    authored: authored,
  );
}
