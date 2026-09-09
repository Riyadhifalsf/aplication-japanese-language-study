import 'package:flutter/material.dart';

import '../../models/exam_question.dart';
import '../../state/app_controller.dart';
import '../exams/exam_hub_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_hiragana_quiz_screen.dart';
import '../kanji/kanji_mastery_quiz_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../kanji/kanji_similar_quiz_screen.dart';
import '../vocab/vocabulary_quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});
  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  bool _kanjiMode = true;
  String _level = 'N5';
  int _questionCount = 10;
  int _secondsPerQuestion = 15;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final accuracy = (app.quizAccuracy * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Quiz')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          _Hero(kanjiMode: _kanjiMode, level: _level, count: _questionCount, seconds: _secondsPerQuestion),
          const SizedBox(height: 16),
          const Text('Materi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.translate_rounded), label: Text('Kanji')),
              ButtonSegment(value: false, icon: Icon(Icons.menu_book_rounded), label: Text('Kosakata')),
            ],
            selected: {_kanjiMode},
            onSelectionChanged: (value) => setState(() => _kanjiMode = value.first),
          ),
          const SizedBox(height: 18),
          _Panel(title: 'Tingkat', child: Wrap(spacing: 8, runSpacing: 8, children: [for (final level in const ['N5', 'N4', 'N3', 'N2', 'N1']) ChoiceChip(label: Text(level), selected: _level == level, onSelected: (_) => setState(() => _level = level))])),
          const SizedBox(height: 12),
          _Panel(title: 'Jumlah soal', child: Wrap(spacing: 8, runSpacing: 8, children: [for (final count in const [5, 10, 15, 20, 30]) ChoiceChip(label: Text('$count'), selected: _questionCount == count, onSelected: (_) => setState(() => _questionCount = count))])),
          const SizedBox(height: 12),
          _Panel(title: 'Waktu per soal', child: Wrap(spacing: 8, runSpacing: 8, children: [for (final seconds in const [10, 15, 20, 30]) ChoiceChip(label: Text('${seconds}s'), selected: _secondsPerQuestion == seconds, onSelected: (_) => setState(() => _secondsPerQuestion = seconds))])),
          const SizedBox(height: 16),
          Card(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55), child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [const Icon(Icons.insights_rounded), const SizedBox(width: 10), Expanded(child: Text('${app.quizAnswered} jawaban · akurasi $accuracy%', style: const TextStyle(fontWeight: FontWeight.w800)))]))),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: app.contentReady ? () => _start(context) : null, icon: const Icon(Icons.play_arrow_rounded), label: Text(app.contentReady ? 'Mulai Custom Quiz' : 'Menyiapkan soal…'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          const SizedBox(height: 22),
          const Text('Latihan cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _QuickTile('Kanji ke Hiragana', 'Lihat kanji, pilih bacaannya', Icons.translate_rounded, () => _open(context, const KanjiHiraganaQuizScreen())),
          _QuickTile('Kanji Mirip', 'Bedakan karakter yang serupa', Icons.blur_on_rounded, () => _open(context, const KanjiSimilarQuizScreen())),
          _QuickTile('Ulangi yang Lemah', 'Fokus pada kanji yang perlu diingat lagi', Icons.replay_rounded, () => _open(context, const KanjiReviewScreen())),
          _QuickTile('Kana Cepat', 'Hiragana dan Katakana', Icons.grid_view_rounded, () => _open(context, const KanaScreen())),
          _QuickTile('Simulasi JLPT', 'Latihan dengan format ujian', Icons.school_rounded, () => _open(context, const ExamHubScreen())),
        ],
      ),
    );
  }

  void _start(BuildContext context) {
    if (_kanjiMode) {
      _open(context, KanjiMasteryQuizScreen(level: _level, sessionSize: _questionCount));
    } else {
      _open(context, VocabularyQuizScreen(level: _level, sessionSize: _questionCount));
    }
  }

  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _Hero extends StatelessWidget {
  const _Hero({required this.kanjiMode, required this.level, required this.count, required this.seconds});
  final bool kanjiMode;
  final String level;
  final int count;
  final int seconds;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer])),
    child: Row(children: [
      Container(width: 68, height: 68, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(21)), child: Text(kanjiMode ? '漢' : '語', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Custom Quiz', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('$level · $count soal · $seconds detik/soal', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 10), child])));
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(this.title, this.subtitle, this.icon, this.onTap);
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, clipBehavior: Clip.antiAlias, child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap));
}
