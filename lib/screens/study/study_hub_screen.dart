import 'package:flutter/material.dart';

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

class StudyHubScreen extends StatelessWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        const _Header(),
        const SizedBox(height: 16),
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
        Text('Referensi dan latihan tambahan. Course utama ada di Learning.', style: TextStyle(color: Colors.white70, height: 1.4)),
      ])),
      CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.menu_book_rounded, color: Colors.white)),
    ]),
  );
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
