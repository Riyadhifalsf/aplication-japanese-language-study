import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
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
import 'today_learning_screen.dart';
import 'learning_tracks_screen.dart';

class StudyHubScreen extends StatelessWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        const _Header(),
        const SizedBox(height: 22),
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
          _Item('Kana', 'Hiragana dan Katakana', Icons.grid_view_rounded, const KanaScreen()),
          _Item('Reading', 'Cerita dan bacaan lebih panjang', Icons.auto_stories_rounded, const ReadingScreen()),
        ]),
        const SizedBox(height: 22),
        _Shelf(title: 'Latihan & referensi', cards: [
          _Item('Quiz', 'Latihan soal dan custom quiz', Icons.quiz_rounded, const ExamHubScreen()),
          _Item('Games', 'Latihan ringan dengan permainan', Icons.sports_esports_rounded, const GameHubScreen()),
          _Item('Dialog', 'Percakapan untuk konteks nyata', Icons.chat_bubble_rounded, const DialogScreen()),
          _Item('Budaya Jepang', 'Etika, musim, dan kebiasaan', Icons.temple_buddhist_rounded, const CultureScreen()),
          _Item('Penghitung Jepang', 'Josuushi dan penggunaan', Icons.format_list_numbered_rounded, const CounterCatalogScreen()),
          _Item('Ulasan Kesalahan', 'Lihat hal yang masih perlu diperbaiki', Icons.rate_review_rounded, const MistakeReviewScreen()),
        ]),
        const SizedBox(height: 22),
        _Shelf(title: 'Target & jalur belajar', cards: [
          _Item('Misi Hari Ini', 'Urutan lesson, review, dan remedial', Icons.flag_rounded, const TodayLearningScreen()),
          _Item('Jalur JLPT & JFT', 'N5–N1 · A1 Prep → A2', Icons.alt_route_rounded, const LearningTracksScreen()),
        ]),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary.withValues(alpha: .92), const Color(0xFF4A1110)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('学ぶ · manabu', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
            SizedBox(height: 10),
            Text('Pustaka belajar', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('Materi referensi untuk mendukung perjalanan belajar kamu.', style: TextStyle(color: Colors.white70, height: 1.4)),
          ])),
          SizedBox(width: 12),
          CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.menu_book_rounded, color: Colors.white)),
        ]),
      );
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.cards});
  final String title;
  final List<_Item> cards;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.22),
            itemBuilder: (_, index) => cards[index],
          );
        }),
      ]);
}

class _Item extends StatelessWidget {
  const _Item(this.title, this.subtitle, this.icon, this.screen);
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      );
}
