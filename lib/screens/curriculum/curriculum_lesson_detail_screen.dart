import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
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
              totalCount: lesson.activities.length),
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
          if (lesson.isFinalTest || lesson.isBossTest || lesson.isTest)
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
      required this.totalCount});

  final CurriculumLesson lesson;
  final String unitTitle;
  final int unitSequence;
  final String unitDescription;
  final int doneCount;
  final int totalCount;

  int? _intId(String raw) => int.tryParse(raw);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final repo = app.repository;
    // Resolusi referensi kurikulum (skip ID yang tidak ada — tanpa crash).
    final phrases = [
      for (final id in lesson.phraseIds)
        if (repo.phraseById(id) != null) repo.phraseById(id)!
    ];
    final vocabs = [
      for (final id in lesson.vocabularyIds)
        if (_intId(id) != null && repo.vocabularyById(_intId(id)!) != null)
          repo.vocabularyById(_intId(id)!)!
    ];
    final grammars = [
      for (final id in lesson.grammarIds)
        if (repo.grammarById(id) != null) repo.grammarById(id)!
    ];
    final kanjis = [
      for (final id in lesson.kanjiIds)
        if (_intId(id) != null && repo.kanjiById(_intId(id)!) != null)
          repo.kanjiById(_intId(id)!)!
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
        const SizedBox(height: 12),
        const Text('Materi lesson ini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text(
            'Materi dipelajari di sini — detail bebas tetap di Library. Progres lesson terpisah dari mastery library.',
            style: TextStyle(fontSize: 12, height: 1.4)),
        const SizedBox(height: 8),
        // Bagian 1 — Materi salam/perkenalan (phrases + catatan pakai).
        if (phrases.isNotEmpty)
          for (final phrase in phrases)
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
        if (showVocabs.isNotEmpty)
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
                      child: Text('${v.word} (${v.reading}) — ${v.meaning}',
                          style: const TextStyle(height: 1.35)),
                    ),
                ],
              ),
            ),
          ),
        if (showGrammars.isNotEmpty) ...[
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
                      Text('Grammar: ${grammar.pattern}',
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
                      for (final k in showKanjis)
                        Chip(label: Text('${k.character} · ${k.meaning}')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
