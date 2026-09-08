import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../models/grammar_point.dart';
import '../../models/kanji.dart';
import '../../models/phrase_item.dart';
import '../../models/vocabulary.dart';
import '../../services/content_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/learning_components.dart';
import '../exams/exam_hub_screen.dart';
import '../grammar/grammar_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_library_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../readings/reading_screen.dart';
import '../study/level_placement_screen.dart';
import '../vocab/vocabulary_screen.dart';

/// Detail satu lesson: daftar aktivitas bervariasi + navigasi ke materi
/// yang SUDAH ADA (reuse, tanpa duplikasi). Setiap aktivitas yang selesai
/// memberi XP + membuka lesson berikutnya bila semua selesai.
class CurriculumLessonDetailScreen extends StatefulWidget {
  const CurriculumLessonDetailScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<CurriculumLessonDetailScreen> createState() =>
      _CurriculumLessonDetailScreenState();
}

class _CurriculumLessonDetailScreenState
    extends State<CurriculumLessonDetailScreen> {
  bool _celebrated = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lesson = CurriculumCatalogData.lessonById(widget.lessonId);
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: const Center(child: Text('Lesson tidak ditemukan.')),
      );
    }
    final unit = CurriculumCatalogData.unitById(lesson.unitId);
    final status = app.curriculumLessonStatus(lesson);
    final progress = app.curriculumProgressById[lesson.id];
    final doneIds = progress?.completedActivityIds ?? const <String>{};
    final allDone =
        lesson.activities.every((a) => doneIds.contains(a.id));

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Text(
            unit == null
                ? lesson.levelId
                : 'Unit ${unit.sequence}: ${unit.title}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(lesson.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          if (lesson.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(lesson.subtitle,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          _StatusBanner(status: status, lesson: lesson),
          const SizedBox(height: 16),
          // Inline lesson content: materi tampil di dalam lesson (bukan
          // sekadar shortcut ke library global). Referensi ID lesson
          // di-resolve via ContentRepository; fallback pratinjau level bila
          // lesson belum punya mapping kurikulum.
          _LessonInlineContent(
              lesson: lesson,
              unitTitle: unit == null ? '' : unit.title,
              unitSequence: unit?.sequence ?? 0,
              unitDescription: unit == null ? '' : unit.description,
              doneCount: doneIds.length,
              totalCount: lesson.activities.length,
              quizActivityId: _quizActivityId(lesson),
              quizXp: _quizXp(lesson, _quizActivityId(lesson)),
              doneIds: doneIds,
              onProgressChanged: () => setState(() {}),
              unitLessons: unit?.lessons ?? const [],
              onSubmitTestScore: (score) =>
                  _submitTestScore(context, app, lesson, score)),
          const SizedBox(height: 16),
          const Text('Aktivitas lesson',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            'Selesaikan berurutan. Tiap aktivitas memberi XP berbeda.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < lesson.activities.length; i++)
            _ActivityTile(
              number: i + 1,
              activity: lesson.activities[i],
              done: doneIds.contains(lesson.activities[i].id),
              locked: i > 0 &&
                  !doneIds.contains(lesson.activities[i - 1].id) &&
                  !allDone,
              onTap: () => _openActivity(
                  context, app, lesson, lesson.activities[i]),
            ),
          const SizedBox(height: 16),
          // Tes nyata (soal pool unit) menggantikan input skor manual bila
          // tersedia; _TestPanel dipertahankan sebagai fallback legacy.
          if ((lesson.isFinalTest || lesson.isBossTest || lesson.isTest) &&
              !(lesson.isTest &&
                  _buildUnitQuestions(app.repository, unit?.lessons ?? const [])
                          .length >=
                      6))
            _TestPanel(
              lesson: lesson,
              onSubmitScore: (score) =>
                  _submitTestScore(context, app, lesson, score),
            ),
          if (allDone && !_celebrated)
            _CelebrationCard(
              lesson: lesson,
              onClose: () => setState(() => _celebrated = true),
            ),
        ],
      ),
    );
  }

  Future<void> _openActivity(BuildContext context, AppController app,
      CurriculumLesson lesson, LessonActivity activity) async {
    // Tandai aktif agar Home "Continue" selalu tepat.
    app.setCurriculumActiveLesson(lesson.id);
    final route = activity.routeHint;
    Widget? screen;
    switch (route) {
      case 'vocabulary':
        screen = VocabularyScreen(initialLevel: _jlptOrNull(lesson.levelId));
      case 'grammar':
      case 'sentences':
        screen = GrammarScreen(initialLevel: _jlptOrNull(lesson.levelId));
      case 'kanji':
        screen = KanjiLibraryScreen(initialLevel: _jlptOrNull(lesson.levelId));
      case 'reading':
        screen = ReadingScreen(initialLevel: _jlptOrNull(lesson.levelId));
      case 'kana':
        screen = const KanaScreen();
      case 'review':
        screen = const KanjiReviewScreen();
      case 'exam':
        screen = const ExamHubScreen();
      case 'placement':
        screen = LevelPlacementScreen(level: lesson.levelId);
      case 'conversation':
      case 'speaking':
      case 'listening':
      case 'quiz':
      default:
        screen = null;
    }
    // Root-cause fix '!_debugDoingThisLayout': sebelumnya bottom sheet
    // dimunculkan via Future.delayed 350ms memakai context lama — bisa
    // menyela transisi/layout route. Sekarang tunggu route di-pop
    // (await), lalu tampilkan bottom sheet hanya bila context masih mounted.
    // Tidak ada timer, tidak ada showModalBottomSheet saat layout.
    if (screen != null) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => screen!));
      if (!context.mounted) return;
    }
    if (!context.mounted) return;
    _askComplete(context, app, lesson, activity);
  }

  String _jlptOrNull(String levelId) =>
      {'N5', 'N4', 'N3', 'N2', 'N1'}.contains(levelId) ? levelId : 'Semua';

  /// XP aktivitas quiz untuk info hasil latihan terpandu.
  static int _quizXp(CurriculumLesson lesson, String activityId) {
    for (final activity in lesson.activities) {
      if (activity.id == activityId) return activity.xp;
    }
    return 0;
  }

  /// Aktivitas quiz/assessment pertama untuk penyelesaian via latihan
  /// terpandu. '' bila lesson tidak punya aktivitas assessment.
  static String _quizActivityId(CurriculumLesson lesson) {
    const testTypes = {
      CurriculumActivityType.quiz,
      CurriculumActivityType.unitTest,
      CurriculumActivityType.finalTest,
      CurriculumActivityType.bossTest,
      CurriculumActivityType.mockTest,
    };
    for (final activity in lesson.activities) {
      if (testTypes.contains(activity.type)) return activity.id;
    }
    return '';
  }

  void _askComplete(BuildContext context, AppController app,
      CurriculumLesson lesson, LessonActivity activity) {
    final done =
        app.curriculumProgressById[lesson.id]?.completedActivityIds.contains(activity.id) ??
            false;
    if (done) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selesaikan "${activity.title}"?',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'Menyelesaikan aktivitas memberi +${activity.xp} XP dan memperbarui streak harianmu. Lesson berikutnya terbuka setelah semua aktivitas lesson ini selesai.',
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Nanti'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final xp = app.completeCurriculumActivity(
                          lesson.id, activity.id);
                      Navigator.pop(sheetContext);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '+$xp XP · ${activity.title} selesai')),
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text('+${activity.xp} XP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitTestScore(BuildContext context, AppController app,
      CurriculumLesson lesson, int score) {
    final passed = app.recordCurriculumFinalTest(lesson.id, score);
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: Icon(passed
            ? Icons.workspace_premium_rounded
            : Icons.school_rounded),
        title: Text(passed ? 'Lulus $score%' : 'Skor $score%'),
        content: Text(passed
            ? (lesson.isFinalTest
                ? 'Final test lulus (≥${lesson.requiredScore == 0 ? 70 : lesson.requiredScore}%). Level berikutnya terbuka bila semua lesson selesai. +${lesson.totalXp} XP.'
                : 'Unit test lulus. Lesson berikutnya terbuka. +${lesson.totalXp} XP.')
            : 'Belum mencapai ${lesson.requiredScore == 0 ? 70 : lesson.requiredScore}%. Pelajari lagi aktivitas di atas lalu coba lagi. Materi yang sering salah masuk antrean review.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (passed) Navigator.pop(context);
            },
            child: Text(passed ? 'Lanjut' : 'Latihan lagi'),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.lesson});
  final CurriculumLessonStatus status;
  final CurriculumLesson lesson;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      CurriculumLessonStatus.locked => 'Terkunci — selesaikan lesson sebelumnya.',
      CurriculumLessonStatus.available => 'Tersedia — mulai dari aktivitas 1.',
      CurriculumLessonStatus.inProgress => 'Sedang dipelajari — lanjutkan.',
      CurriculumLessonStatus.completed => 'Selesai — pertahankan dengan review.',
      CurriculumLessonStatus.mastered => 'Mastered ★ — pertahankan streak.',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: .6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
          Text('+${lesson.totalXp} XP',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// Inline lesson content: ruang belajar di dalam lesson.
///
/// CONTENT (repository) → REFERENSI (lesson ids) → PRESENTASI (di sini).
/// Tidak ada duplikasi objek; tidak ada navigasi keluar sebagai alur utama.
/// Library tetap terpisah untuk belajar bebas.
class _LessonInlineContent extends StatelessWidget {
  const _LessonInlineContent(
      {required this.lesson,
      required this.unitTitle,
      required this.unitSequence,
      required this.unitDescription,
      required this.doneCount,
      required this.totalCount,
      required this.quizActivityId,
      required this.quizXp,
      required this.doneIds,
      required this.onProgressChanged,
      required this.unitLessons,
      required this.onSubmitTestScore});

  final CurriculumLesson lesson;
  final String unitTitle;
  final int unitSequence;
  final String unitDescription;
  final int doneCount;
  final int totalCount;
  final String quizActivityId;
  final int quizXp;
  final Set<String> doneIds;
  final VoidCallback onProgressChanged;
  final List<CurriculumLesson> unitLessons;
  final ValueChanged<int> onSubmitTestScore;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final repo = app.repository;
    // Resolusi referensi kurikulum (skip ID yang tidak ada — tanpa crash).
    final resolved = _resolveLessonContent(repo, lesson);
    final phrases = resolved.phrases;
    final vocabs = resolved.vocabs;
    final grammars = resolved.grammars;
    final kanjis = resolved.kanjis;
    // Pool Tes Bab: gabungan konten ter-mapping seluruh lesson unit ini.
    final unitQuestions = lesson.isTest
        ? _buildUnitQuestions(repo, unitLessons)
        : const <_PracticeQuestion>[];
    final showChapterTest = lesson.isTest && unitQuestions.length >= 6;
    final lessonQuestions = lesson.isTest
        ? const <_PracticeQuestion>[]
        : _buildLessonQuestions(
            phrases: phrases,
            vocabs: vocabs,
            grammars: grammars,
            kanjis: kanjis,
            listening: true,
            authored: lesson.authoredQuestions,
          );
    final showPractice = !lesson.isTest &&
        lessonQuestions.length >= 3 &&
        quizActivityId.isNotEmpty;
    final hasListeningActivity = lesson.activities.any(
        (a) => a.type == CurriculumActivityType.listening);
    // Contoh kalimat terverifikasi untuk strip dengar & reading.
    final exampleLines = [
      for (final g in grammars)
        for (final e in g.examples.take(1))
          (japanese: e.japanese, reading: e.reading, meaning: e.meaning),
    ];
    final useMapped = lesson.hasInlineContent &&
        (phrases.isNotEmpty ||
            vocabs.isNotEmpty ||
            grammars.isNotEmpty ||
            kanjis.isNotEmpty);
    // Fallback pratinjau level bila lesson belum punya mapping.
    final fallbackVocabs = useMapped
        ? const []
        : repo.vocabulary
            .where((v) => v.level == lesson.levelId)
            .take(3)
            .toList();
    final fallbackGrammars = useMapped
        ? const []
        : repo.grammar
            .where((g) => g.level == lesson.levelId)
            .take(1)
            .toList();
    final fallbackKanjis = useMapped
        ? const []
        : repo.kanji
            .where((k) => k.level == lesson.levelId)
            .take(4)
            .toList();
    final showVocabs = useMapped ? vocabs : fallbackVocabs;
    final showGrammars = useMapped ? grammars : fallbackGrammars;
    final showKanjis = useMapped ? kanjis : fallbackKanjis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${lesson.levelId}${unitSequence > 0 ? ' · Unit $unitSequence' : ''} · Progress $doneCount/$totalCount aktivitas',
          style: TextStyle(
              color: cs.primary, fontWeight: FontWeight.w900, fontSize: 12),
        ),
        const SizedBox(height: 8),
        const Text('Tujuan belajar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        if (lesson.objectives.isNotEmpty)
          for (final objective in lesson.objectives)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                      child: Text(objective,
                          style: const TextStyle(height: 1.4))),
                ],
              ),
            )
        else
          Text(
            lesson.subtitle.isNotEmpty
                ? lesson.subtitle
                : (unitDescription.isNotEmpty
                    ? unitDescription
                    : 'Selesaikan semua aktivitas untuk membuka lesson berikutnya.'),
            style: TextStyle(height: 1.45, color: cs.onSurfaceVariant),
          ),
        if (unitTitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Konteks: $unitTitle · JLPT ${lesson.levelId}',
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
        // Catatan kurikulum (materi standar spesifikasi bab).
        if (lesson.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final note in lesson.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(note.body,
                          style: const TextStyle(height: 1.45)),
                      for (final line in note.lines) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(line.japanese,
                                      style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          height: 1.35)),
                                  Text(
                                      '${line.reading} — ${line.meaning}',
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          height: 1.35)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Dengarkan',
                              onPressed: () =>
                                  app.tts.speak(line.japanese),
                              icon: const Icon(Icons.volume_up_rounded),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        const Text('Bagian 1 — Materi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text(
            'Pelajari dulu di sini — detail bebas tetap di Library. Progres lesson terpisah dari mastery library.',
            style: TextStyle(fontSize: 12, height: 1.4)),
        const SizedBox(height: 8),
        // Materi salam/perkenalan (phrases + catatan pakai).
        // Dikelompokkan sesuai kategori data (Salam / Perkenalan).
        if (phrases.isNotEmpty)
          for (final entry in _groupPhrases(phrases).entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(entry.key,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900)),
            ),
            for (final phrase in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(phrase.japanese,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.3)),
                          ),
                          IconButton(
                            tooltip: 'Dengarkan',
                            onPressed: () =>
                                app.tts.speak(phrase.japanese),
                            icon: const Icon(Icons.volume_up_rounded),
                          ),
                        ],
                      ),
                      Text(phrase.reading,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, height: 1.35)),
                      const SizedBox(height: 4),
                      Text('Arti: ${phrase.meaning}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, height: 1.4)),
                      const SizedBox(height: 4),
                      Text(
                          'Penggunaan (${phrase.politeness}): ${phrase.note}',
                          style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        if (showVocabs.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Bagian 2 — Kotoba Bab ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'Kosakata pilihan khusus bab ini (bukan seluruh library).',
              style: TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kotoba lesson ini',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  for (final v in showVocabs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      // Mastery jujur 2-state dari data user (toggle di
                      // Library): ● dikuasai, ○ baru. Tanpa progres palsu.
                      child: Text(
                          '${app.masteredVocabularyIds.contains(v.id) ? '●' : '○'} ${v.word} (${v.reading}) — ${v.meaning}',
                          style: const TextStyle(height: 1.35)),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (showGrammars.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Bagian 3 — Bunpou Bab ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'Grammar yang memang diperlukan bab ini, dijelaskan di sini.',
              style: TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          for (final grammar in showGrammars)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${app.completedGrammarIds.contains(grammar.id) ? '●' : '○'} Grammar: ${grammar.pattern}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w900)),
                      Text(grammar.title,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Bentuk: ${grammar.formation}',
                          style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 4),
                      Text(grammar.explanation,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.4)),
                      if (grammar.examples.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                            '${grammar.examples.first.japanese} — ${grammar.examples.first.meaning}',
                            style: const TextStyle(height: 1.35)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
        if (showKanjis.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Bagian 4 — Kanji Bab ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'Hanya kanji penyusun kata bab ini (bukan seluruh kanji).',
              style: TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kanji lesson ini',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  const Text(
                      'Kanji penyusun kata di lesson ini.',
                      style: TextStyle(fontSize: 12, height: 1.4)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // ● mastered, ◑ dipelajari, ○ baru — dari data user.
                      for (final k in showKanjis)
                        Chip(
                            label: Text(
                                '${app.masteredKanjiIds.contains(k.id) ? '●' : (app.learnedKanjiIds.contains(k.id) ? '◑' : '○')} ${k.character} · ${k.meaning}')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        // Listening: dengar via TTS (hanya bila lesson punya aktivitas
        // listening + ada materi suara terverifikasi). Tanpa mic.
        if (hasListeningActivity &&
            (phrases.isNotEmpty || exampleLines.isNotEmpty)) ...[
          const SizedBox(height: 12),
          const Text('Bagian Listening — Dengarkan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'Putar audio, dengarkan baik-baik, lalu lanjut ke latihan.',
              style: TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          for (final line in [
            for (final p in phrases.take(3))
              (japanese: p.japanese, reading: p.reading, meaning: p.meaning),
            ...exampleLines.take(2),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.headphones_rounded),
                  title: Text(line.japanese,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${line.reading} — ${line.meaning}',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: 'Putar audio',
                    onPressed: () => app.tts.speak(line.japanese),
                    icon: const Icon(Icons.play_circle_rounded),
                  ),
                ),
              ),
            ),
        ],
        // Reading: teks pendek HANYA dari materi yang sudah diajarkan
        // (salam + contoh grammar terverifikasi lesson ini).
        if (useMapped && phrases.length >= 2 && exampleLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Bagian Reading — Baca',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in [
                    (japanese: phrases[2].japanese,
                        reading: phrases[2].reading,
                        meaning: phrases[2].meaning),
                    exampleLines.first,
                  ]) ...[
                    Text(line.japanese,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900,
                            height: 1.5)),
                    Text('${line.reading} — ${line.meaning}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, height: 1.4)),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                      'Bacaan ini hanya memakai salam dan pola yang sudah dipelajari di atas.',
                      style: TextStyle(fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
        // Bagian 5 — Latihan terpandu dari materi bab ini saja.
        if (showPractice) ...[
          const SizedBox(height: 12),
          const Text('Bagian 5 — Latihan Terpandu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'Mudah ke sulit, soalnya dari materi bab ini saja.',
              style: TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          _LessonGuidedPractice(
            lesson: lesson,
            questions: lessonQuestions,
            quizActivityId: quizActivityId,
            quizXp: quizXp,
            alreadyDone: doneIds.contains(quizActivityId),
            onCompleted: onProgressChanged,
          ),
        ],
        // Tes Bab nyata: soal dari pool unit, dinilai otomatis.
        // Menggantikan input skor manual agar hasil jujur.
        if (showChapterTest) ...[
          const SizedBox(height: 12),
          Text('Tes ${unitTitle.isNotEmpty ? unitTitle : 'Bab'}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'Soal dari seluruh materi bab ini. Lulus ≥70% untuk lanjut.',
              style: TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          _LessonGuidedPractice(
            lesson: lesson,
            questions: unitQuestions,
            quizActivityId: quizActivityId,
            quizXp: lesson.totalXp,
            alreadyDone: false,
            onCompleted: onProgressChanged,
            isTest: true,
            onSubmitTestScore: onSubmitTestScore,
          ),
        ],
        // Bagian 6 — Review ringkasan bab.
        const SizedBox(height: 12),
        const Text('Bagian 6 — Review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Bab ini mengajarkan: ${phrases.length} salam, ${vocabs.length} kosakata, ${grammars.length} pola grammar, ${kanjis.length} kanji.',
                    style: const TextStyle(height: 1.45)),
                const SizedBox(height: 4),
                const Text(
                    'Selesaikan latihan + quiz di bawah, item yang salah tampil di hasil latihan untuk direview.',
                    style: TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Kelompokkan phrase sesuai kategori data (Salam / Perkenalan, ...),
  /// menjaga urutan kemunculan pertama.
  Map<String, List<dynamic>> _groupPhrases(List<dynamic> items) {
    final grouped = <String, List<dynamic>>{};
    for (final item in items) {
      final category = (item.category as String?)?.trim();
      final key = (category == null || category.isEmpty) ? 'Materi' : category;
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }
}

/// Satu soal latihan terpandu: seluruh teks berasal dari konten lesson
/// yang sudah di-resolve (tanpa soal random global, tanpa mengarang).
/// [audio]: bila diisi, soal adalah listening — putar via TTS, teks
/// Jepang pertanyaan disembunyikan agar benar-benar melatih dengar.
class _PracticeQuestion {
  const _PracticeQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.reading = '',
    this.meaning = '',
    this.audio = '',
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String reading;
  final String meaning;
  final String audio;
}

/// Hasil resolusi referensi satu lesson: list-model asli dari repository
/// (tanpa duplikasi objek). ID tak dikenal di-skip diam-diam.
class _ResolvedLesson {
  const _ResolvedLesson({
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
_ResolvedLesson _resolveLessonContent(
    ContentRepository repo, CurriculumLesson lesson) {
  final phrases = <PhraseItem>[];
  for (final id in lesson.phraseIds) {
    final item = repo.phraseById(id);
    if (item != null) phrases.add(item);
  }
  final vocabs = <Vocabulary>[];
  for (final id in lesson.vocabularyIds) {
    final parsed = int.tryParse(id);
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
    final parsed = int.tryParse(id);
    final item = parsed == null ? null : repo.kanjiById(parsed);
    if (item != null) kanjis.add(item);
  }
  return _ResolvedLesson(
      phrases: phrases, vocabs: vocabs, grammars: grammars, kanjis: kanjis);
}

/// Gabungkan konten ter-resolve seluruh lesson satu unit (dedupe per ID,
/// urutan = urutan lesson). Dipakai Tes Bab agar soal berasal dari materi
/// unit tersebut saja — bukan random global.
_ResolvedLesson _resolveUnitContent(
    ContentRepository repo, List<CurriculumLesson> lessons) {
  final phrases = <String, PhraseItem>{};
  final vocabs = <int, Vocabulary>{};
  final grammars = <String, GrammarPoint>{};
  final kanjis = <int, Kanji>{};
  for (final lesson in lessons) {
    final resolved = _resolveLessonContent(repo, lesson);
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
  }
  return _ResolvedLesson(
    phrases: phrases.values.toList(growable: false),
    vocabs: vocabs.values.toList(growable: false),
    grammars: grammars.values.toList(growable: false),
    kanjis: kanjis.values.toList(growable: false),
  );
}

/// Soal Tes Bab: dari pool unit (deterministik: ID ter-mapping + soal
/// authored tiap lesson). ≥6 soal = tes nyata layak.
List<_PracticeQuestion> _buildUnitQuestions(
    ContentRepository repo, List<CurriculumLesson> lessons) {
  final pool = _resolveUnitContent(repo, lessons);
  final authored = [
    for (final lesson in lessons) ...lesson.authoredQuestions,
  ];
  return _buildLessonQuestions(
    phrases: pool.phrases,
    vocabs: pool.vocabs,
    grammars: pool.grammars,
    kanjis: pool.kanjis,
    listening: true,
    authored: authored,
  );
}

/// Bangun soal deterministik (urutan tetap: mudah → sulit) dari konten
/// lesson yang sudah di-resolve. Hanya memakai item yang ADA (guard
/// panjang) — tidak pernah mengarang opsi. [listening]: tambah soal dengar
/// (butuh phrases ≥ 3).
List<_PracticeQuestion> _buildLessonQuestions({
  required List<PhraseItem> phrases,
  required List<Vocabulary> vocabs,
  required List<GrammarPoint> grammars,
  required List<Kanji> kanjis,
  bool listening = false,
  List<AuthoredQuestion> authored = const [],
}) {
  final qs = <_PracticeQuestion>[];
  // 1. Arti salam (mudah).
  if (phrases.length >= 3) {
    qs.add(_PracticeQuestion(
      prompt: '「${phrases[0].japanese}」 artinya?',
      options: [phrases[0].meaning, phrases[1].meaning, phrases[2].meaning],
      correctIndex: 0,
      explanation: 'Hafalkan pasangan salam–artinya di Bagian 1.',
      reading: phrases[0].reading,
      meaning: phrases[0].meaning,
    ));
    // 2. Penggunaan sesuai situasi.
    qs.add(_PracticeQuestion(
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
  }
  // 3. Tingkat kesopanan (butuh varian Sopan).
  if (phrases.length >= 6) {
    qs.add(_PracticeQuestion(
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
  // 4-5. Kotoba (butuh ≥5 agar opsi pengecoh valid).
  if (vocabs.length >= 5) {
    qs.add(_PracticeQuestion(
      prompt: '「${vocabs[2].word}」 dibaca?',
      options: [vocabs[2].reading, vocabs[3].reading, vocabs[4].reading],
      correctIndex: 0,
      explanation: 'Perhatikan bacaan di Bagian 2.',
      reading: vocabs[2].reading,
      meaning: vocabs[2].meaning,
    ));
    // 5. Arti kotoba.
    qs.add(_PracticeQuestion(
      prompt: '「${vocabs[4].word}」 artinya?',
      options: [vocabs[4].meaning, vocabs[2].meaning, vocabs[3].meaning],
      correctIndex: 0,
      explanation: 'Pasangan kata–arti ada di Bagian 2.',
      reading: vocabs[4].reading,
      meaning: vocabs[4].meaning,
    ));
  }
  // 6. Pola grammar.
  if (grammars.isNotEmpty) {
    qs.add(_PracticeQuestion(
      prompt: 'Lengkapi: わたし ___ がくせいです。',
      options: const ['は', 'の', 'か'],
      correctIndex: 0,
      explanation:
          'Pola ${grammars[0].pattern}: ${grammars[0].formation}.',
    ));
  }
  // 7. Arti kanji.
  if (kanjis.length >= 3) {
    qs.add(_PracticeQuestion(
      prompt: 'Kanji「${kanjis[2].character}」 artinya?',
      options: [kanjis[2].meaning, kanjis[0].meaning, kanjis[1].meaning],
      correctIndex: 0,
      explanation: 'Kanji penyusun kata bab ini (Bagian 4).',
    ));
  }
  // 8. Listening: dengar via TTS, pilih arti.
  if (listening && phrases.length >= 3) {
    qs.add(_PracticeQuestion(
      prompt: 'Dengarkan, lalu pilih artinya.',
      options: [phrases[1].meaning, phrases[0].meaning, phrases[2].meaning],
      correctIndex: 0,
      explanation: 'Dengarkan ulang di Bagian 1 bila ragu.',
      reading: phrases[1].reading,
      meaning: phrases[1].meaning,
      audio: phrases[1].japanese,
    ));
  }
  // 9. Soal authored kurikulum (lesson tanpa ID dataset).
  for (final a in authored) {
    if (a.options.length >= 2 &&
        a.correctIndex >= 0 &&
        a.correctIndex < a.options.length) {
      qs.add(_PracticeQuestion(
        prompt: a.prompt,
        options: a.options,
        correctIndex: a.correctIndex,
        explanation: a.explanation,
        reading: a.reading,
        meaning: a.meaning,
        audio: a.audio,
      ));
    }
  }
  return qs;
}

/// Latihan/tes terpandu di dalam lesson: mudah → sulit, soalnya HANYA dari
/// materi yang diberikan via [questions] (deterministik, tanpa random
/// global). Mode latihan: selesai → aktivitas quiz ditandai (+XP,
/// idempotent). Mode tes ([isTest]): nilai persen → [onSubmitTestScore]
/// (recordCurriculumFinalTest: bestScore + unlock + review).
class _LessonGuidedPractice extends StatefulWidget {
  const _LessonGuidedPractice({
    required this.lesson,
    required this.questions,
    required this.quizActivityId,
    required this.quizXp,
    required this.alreadyDone,
    required this.onCompleted,
    this.isTest = false,
    this.onSubmitTestScore,
  });

  final CurriculumLesson lesson;
  final List<_PracticeQuestion> questions;
  final String quizActivityId;
  final int quizXp;
  final bool alreadyDone;
  final VoidCallback onCompleted;
  final bool isTest;
  final ValueChanged<int>? onSubmitTestScore;

  @override
  State<_LessonGuidedPractice> createState() => _LessonGuidedPracticeState();
}

class _LessonGuidedPracticeState extends State<_LessonGuidedPractice> {
  List<_PracticeQuestion> get _questions => widget.questions;
  int _index = 0;
  int _selected = -1;
  int _correct = 0;
  final List<String> _wrong = [];
  bool _finished = false;
  bool _claimed = false;

  void _answer(int i) {
    if (_selected != -1 || _finished) return;
    final q = _questions[_index];
    setState(() {
      _selected = i;
      if (i == q.correctIndex) {
        _correct++;
      } else {
        _wrong.add(q.prompt);
      }
    });
  }

  void _next() {
    if (_index >= _questions.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = -1;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = -1;
      _correct = 0;
      _wrong.clear();
      _finished = false;
    });
  }

  Future<void> _claim(BuildContext context, AppController app) async {
    if (_claimed || widget.alreadyDone) return;
    setState(() => _claimed = true);
    final xp = app.completeCurriculumActivity(
        widget.lesson.id, widget.quizActivityId);
    widget.onCompleted();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('+$xp XP · Latihan ${widget.lesson.title} selesai')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (_questions.isEmpty) return const SizedBox.shrink();
    if (_finished) return _resultCard(context, app);
    final q = _questions[_index];
    final answered = _selected != -1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soal ${_index + 1}/${_questions.length}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 6),
            Text(q.prompt,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            // Listening: audio via TTS, teks Jepang disembunyikan.
            if (q.audio.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => AppScope.of(context).tts.speak(q.audio),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Putar audio'),
              ),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: answered ? null : () => _answer(i),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !answered
                          ? null
                          : (i == q.correctIndex
                              ? Colors.green.withValues(alpha: .15)
                              : (i == _selected
                                  ? Colors.red.withValues(alpha: .12)
                                  : null)),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(q.options[i],
                          style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
              ),
            if (answered) ...[
              const SizedBox(height: 4),
              if (_selected == q.correctIndex)
                AnswerFeedback.correct(
                    reading: q.reading,
                    meaning: q.meaning,
                    explanation: q.explanation)
              else
                AnswerFeedback.wrong(
                    answer: q.options[q.correctIndex],
                    reading: q.reading,
                    meaning: q.meaning,
                    explanation: q.explanation),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_index >= _questions.length - 1
                      ? 'Lihat Hasil'
                      : 'Lanjut'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Nilai huruf tes bab: 90+ Excellent, 80+ Great, 70+ Passed.
  static String gradeFor(int percent) => percent >= 90
      ? 'Excellent'
      : percent >= 80
          ? 'Great'
          : percent >= 70
              ? 'Passed'
              : 'Review required';

  Widget _resultCard(BuildContext context, AppController app) {
    final total = _questions.length;
    final percent =
        total == 0 ? 0 : ((_correct / total) * 100).round();
    final done = widget.alreadyDone || _claimed;
    final isTest = widget.isTest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTest ? 'Hasil Tes Bab' : 'Hasil Latihan',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Skor: $percent% ($_correct/$total benar)',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            if (isTest)
              Text('Nilai: ${gradeFor(percent)} (lulus ≥70%)',
                  style: const TextStyle(fontWeight: FontWeight.w700))
            else
              Text('+${widget.quizXp} XP bila ditandai selesai',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (_wrong.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Perlu direview:',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              for (final w in _wrong)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('• $w',
                      style: const TextStyle(height: 1.35)),
                ),
            ] else ...[
              const SizedBox(height: 8),
              Text(isTest
                  ? 'Sempurna! Simpan hasil untuk membuka bab berikutnya.'
                  : 'Sempurna! Lanjut ke quiz bab.'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _restart,
                    child: const Text('Ulangi'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: isTest
                      ? FilledButton(
                          onPressed: widget.onSubmitTestScore == null
                              ? null
                              : () => widget.onSubmitTestScore!(percent),
                          child: const Text('Simpan hasil test'),
                        )
                      : FilledButton(
                          onPressed:
                              done ? null : () => _claim(context, app),
                          child: Text(done
                              ? 'Selesai ✓'
                              : 'Tandai selesai +${widget.quizXp} XP'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(
      {required this.number,
      required this.activity,
      required this.done,
      required this.locked,
      required this.onTap});

  final int number;
  final LessonActivity activity;
  final bool done;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: locked ? null : onTap,
        leading: CircleAvatar(
          backgroundColor: done
              ? Colors.green.withValues(alpha: .14)
              : scheme.primary.withValues(alpha: .1),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.green)
              : locked
                  ? const Icon(Icons.lock_rounded)
                  : Icon(_iconFor(activity.type)),
        ),
        title: Text(activity.title,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          '${activity.type.label} · +${activity.xp} XP · ~${activity.estimatedMinutes} mnt${activity.description.isEmpty ? '' : '\n${activity.description}'}',
          style: const TextStyle(height: 1.3),
        ),
        isThreeLine: activity.description.isNotEmpty,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  IconData _iconFor(CurriculumActivityType type) => switch (type) {
        CurriculumActivityType.vocabulary => Icons.menu_book_rounded,
        CurriculumActivityType.kanji => Icons.translate_rounded,
        CurriculumActivityType.grammar => Icons.account_tree_rounded,
        CurriculumActivityType.exampleSentences => Icons.subject_rounded,
        CurriculumActivityType.reading => Icons.auto_stories_rounded,
        CurriculumActivityType.listening => Icons.headphones_rounded,
        CurriculumActivityType.speaking => Icons.mic_rounded,
        CurriculumActivityType.shadowing => Icons.repeat_rounded,
        CurriculumActivityType.conversation => Icons.forum_rounded,
        CurriculumActivityType.quiz => Icons.quiz_rounded,
        CurriculumActivityType.review => Icons.refresh_rounded,
        CurriculumActivityType.writing => Icons.edit_rounded,
        CurriculumActivityType.unitTest => Icons.shield_rounded,
        CurriculumActivityType.bossTest => Icons.castle_rounded,
        CurriculumActivityType.finalTest => Icons.workspace_premium_rounded,
        CurriculumActivityType.mockTest => Icons.school_rounded,
        CurriculumActivityType.placementTest => Icons.assignment_rounded,
      };
}

class _TestPanel extends StatefulWidget {
  const _TestPanel({required this.lesson, required this.onSubmitScore});
  final CurriculumLesson lesson;
  final ValueChanged<int> onSubmitScore;

  @override
  State<_TestPanel> createState() => _TestPanelState();
}

class _TestPanelState extends State<_TestPanel> {
  double _score = 80;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: .5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lesson.isFinalTest
                    ? 'Final Test — masukkan skormu'
                    : 'Unit Test — masukkan skormu',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Ambil quiz/mock terkait lalu catat skor di sini. Lulus butuh ≥${widget.lesson.requiredScore == 0 ? 70 : widget.lesson.requiredScore}%. Skor terbaik tersimpan & membuka level berikutnya.',
                style: const TextStyle(height: 1.4),
              ),
              Slider(
                value: _score,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_score.round()}%',
                onChanged: (v) => setState(() => _score = v),
              ),
              Center(
                  child: Text('${_score.round()}%',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => widget.onSubmitScore(_score.round()),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Simpan skor test'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _CelebrationCard extends StatefulWidget {
  const _CelebrationCard({required this.lesson, required this.onClose});
  final CurriculumLesson lesson;
  final VoidCallback onClose;

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                const Color(0xFF1B3A2B),
              ],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lesson selesai!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900)),
                    Text(
                      '${widget.lesson.title} · +${widget.lesson.totalXp} XP. Lesson berikutnya terbuka.',
                      style: const TextStyle(
                          color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      );
}
