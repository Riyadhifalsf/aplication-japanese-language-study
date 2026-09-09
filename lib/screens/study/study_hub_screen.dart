import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../counters/counter_catalog_screen.dart';
import '../culture/culture_screen.dart';
import '../dialogs/dialog_screen.dart';
import '../exams/exam_hub_screen.dart';
import '../grammar/grammar_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_library_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../phrases/phrase_screen.dart';
import '../readings/reading_screen.dart';
import '../sentences/sentence_screen.dart';
import '../vocab/vocabulary_screen.dart';
import '../games/game_hub_screen.dart';
import '../review/mistake_review_screen.dart';
import '../profile/study_stats_screen.dart';
import '../curriculum/curriculum_lesson_detail_screen.dart';

class StudyHubScreen extends StatelessWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = CurriculumCatalogData.fullLevels.firstWhere(
      (item) => item.id == app.curriculumActiveLevelId,
      orElse: () => CurriculumCatalogData.fullLevels.first,
    );
    final units = [...level.units]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final progress = app.curriculumLevelProgress(level.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        const _Header(),
        const SizedBox(height: 16),
        _ActiveLearning(app: app, level: level, units: units, progress: progress),
        const SizedBox(height: 22),
        _Stats(app: app),
        const SizedBox(height: 24),
        _Shelf(title: 'Kosakata & tata bahasa', cards: [
          _Item('Kosakata', 'Kumpulan kosakata berdasarkan level', Icons.menu_book_rounded, const VocabularyScreen()),
          _Item('Grammar', 'Pola tata bahasa dan contoh', Icons.account_tree_rounded, const GrammarScreen()),
          _Item('Pola Kalimat', 'Contoh kalimat untuk latihan', Icons.subject_rounded, const SentenceScreen()),
          _Item('Frasa', 'Frasa praktis sehari-hari', Icons.forum_rounded, const PhraseScreen()),
        ]),
        const SizedBox(height: 22),
        _Shelf(title: 'Kanji & membaca', cards: [
          _Item('Kanji', 'Cari, baca, dan lihat detail kanji', Icons.translate_rounded, const KanjiLibraryScreen()),
          _Item('Review Kanji', 'Ulangi kanji yang perlu diperkuat', Icons.replay_rounded, const KanjiReviewScreen()),
          _Item('Reading', 'Cerita dan bacaan lebih panjang', Icons.auto_stories_rounded, const ReadingScreen()),
        ]),
        const SizedBox(height: 22),
        _Shelf(title: 'Latihan & referensi', cards: [
          _Item('Kana', 'Hiragana dan Katakana', Icons.grid_view_rounded, const KanaScreen()),
          _Item('Quiz', 'Latihan soal dan custom quiz', Icons.quiz_rounded, const ExamHubScreen()),
          _Item('Games', 'Latihan ringan dengan permainan', Icons.sports_esports_rounded, const GameHubScreen()),
          _Item('Dialog', 'Percakapan untuk konteks nyata', Icons.chat_bubble_rounded, const DialogScreen()),
          _Item('Budaya Jepang', 'Etika, musim, dan kebiasaan', Icons.temple_buddhist_rounded, const CultureScreen()),
          _Item('Penghitung Jepang', 'Josuushi dan penggunaan', Icons.format_list_numbered_rounded, const CounterCatalogScreen()),
          _Item('Ulasan Kesalahan', 'Lihat hal yang masih perlu diperbaiki', Icons.rate_review_rounded, const MistakeReviewScreen()),
          _Item('Statistik Belajar', 'Waktu, streak, dan mastery', Icons.insights_rounded, const StudyStatsScreen()),
        ]),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF4A1110)]),
    ),
    child: const Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LIBRARY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        SizedBox(height: 7),
        Text('Pustaka belajar', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
        SizedBox(height: 6),
        Text('Learning aktif dan materi pendukung ada di satu tempat.', style: TextStyle(color: Colors.white70, height: 1.4)),
      ])),
      CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.menu_book_rounded, color: Colors.white)),
    ]),
  );
}

class _ActiveLearning extends StatelessWidget {
  const _ActiveLearning({required this.app, required this.level, required this.units, required this.progress});
  final AppController app;
  final CurriculumLevel level;
  final List<CurriculumUnit> units;
  final UserLevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = (progress.percent * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => _showAllProgress(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Learning aktif', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
                Text(level.id, style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary)),
                const SizedBox(width: 5),
                const Icon(Icons.open_in_new_rounded, size: 17),
              ]),
              const SizedBox(height: 5),
              Text('${progress.completedLessons}/${progress.totalLessons} lesson · $percent% tercapai', style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress.percent.clamp(0.0, 1.0).toDouble(), minHeight: 7),
            ]),
          ),
        ),
        const Divider(height: 1),
        for (var i = 0; i < units.length; i++)
          _UnitProgressRow(unit: units[i], app: app, onTap: () => _openUnit(context, units[i])),
      ]),
    );
  }

  void _openUnit(BuildContext context, CurriculumUnit unit) {
    final lessons = [...unit.lessons]..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (lessons.isEmpty) return;
    final next = lessons.firstWhere(
      (lesson) {
        final status = app.curriculumLessonStatus(lesson);
        return status != CurriculumLessonStatus.completed && status != CurriculumLessonStatus.mastered;
      },
      orElse: () => lessons.first,
    );
    app.setCurriculumActiveLesson(next.id);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CurriculumLessonDetailScreen(lessonId: next.id)));
  }

  void _showAllProgress(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          shrinkWrap: true,
          children: [
            Text('Pencapaian ${level.id}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text('${progress.completedLessons}/${progress.totalLessons} lesson selesai.', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            for (final unit in units)
              _UnitProgressRow(unit: unit, app: app, onTap: () { Navigator.pop(context); _openUnit(context, unit); }),
          ],
        ),
      ),
    );
  }
}

class _UnitProgressRow extends StatelessWidget {
  const _UnitProgressRow({required this.unit, required this.app, required this.onTap});
  final CurriculumUnit unit;
  final AppController app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = app.curriculumUnitProgress(unit);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(children: [
          Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surfaceContainerHighest), child: Text('${unit.sequence}', style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bab ${unit.sequence} · ${unit.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('${progress.done}/${progress.total} lesson selesai', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
          const Icon(Icons.chevron_right_rounded),
        ]),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    Expanded(child: _Metric('${app.streak}', 'streak', Icons.local_fire_department_rounded)),
    Expanded(child: _Metric('${app.masteredKanjiIds.length}', 'kanji', Icons.translate_rounded)),
    Expanded(child: _Metric('${app.masteredVocabularyIds.length}', 'kosakata', Icons.menu_book_rounded)),
  ])));
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.icon);
  final String value; final String label; final IconData icon;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]);
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.cards});
  final String title; final List<_Item> cards;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 430, mainAxisExtent: 112, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (_, i) {
        final item = cards[i];
        return Card(elevation: 0, clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(item.icon, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          const Icon(Icons.chevron_right_rounded),
        ]))));
      },
    ),
  ]);
}

class _Item {
  const _Item(this.title, this.subtitle, this.icon, this.screen);
  final String title; final String subtitle; final IconData icon; final Widget screen;
}
