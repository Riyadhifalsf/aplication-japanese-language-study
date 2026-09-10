import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../../widgets/content_dummy_image.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  int selectedGame = 0;

  static const games = [
    ('Hiragana', 'あ', 'Latih hiragana lewat tahap cepat.'),
    ('Katakana', 'ア', 'Kuasai katakana satu tahap demi satu.'),
    ('Kanji', '漢', 'Kenali kanji, arti, dan bacaannya.'),
  ];

  void _openStage(int stage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StageGameScreen(gameType: selectedGame, stage: stage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final game = games[selectedGame];
    return Scaffold(
      appBar: AppBar(title: const Text('Permainan'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          const ContentDummyImage(
            title: 'Permainan Jepang',
            subtitle: 'Gambar sementara — siap diganti dengan ilustrasi asli',
            height: 170,
          ),
          const SizedBox(height: 14),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Latihan Jepang sambil bermain', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Pilih kategori, buka tahap, kumpulkan bintang, lalu tingkatkan skor kamu.'),
                const SizedBox(height: 18),
                Row(children: [const Icon(Icons.emoji_events_rounded), const SizedBox(width: 8), Text('100+ tahap siap dimainkan', style: TextStyle(fontWeight: FontWeight.w900))]),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Text('Pilih permainan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: games.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final item = games[index];
                final selected = selectedGame == index;
                return SizedBox(width: 150, child: Card(color: selected ? cs.primaryContainer : null, child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => selectedGame = index),
                  child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(item.$2, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: selected ? cs.primary : null)), const Spacer(), if (selected) Icon(Icons.check_circle_rounded, color: cs.primary, size: 18)]),
                    const Spacer(), Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ])),
                )));
              },
            ),
          ),
          const SizedBox(height: 22),
          Row(children: [Expanded(child: Text(game.$1, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))), Text('0 / 27 tahap', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 4),
          Text(game.$3, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: const LinearProgressIndicator(value: .18, minHeight: 8)),
          const SizedBox(height: 18),
          _StageGrid(onStageTap: _openStage),
        ],
      ),
    );
  }
}

class _StageGrid extends StatelessWidget {
  const _StageGrid({required this.onStageTap});
  final void Function(int stage) onStageTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 27,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.02),
      itemBuilder: (_, index) {
        final stage = index + 1;
        final unlocked = stage <= 6;
        final stars = stage < 4 ? 3 : stage == 4 ? 2 : stage == 5 ? 1 : 0;
        return Card(color: unlocked ? cs.primaryContainer : cs.surfaceContainerHighest, child: InkWell(
          onTap: unlocked ? () => onStageTap(stage) : null,
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 15, color: i < stars ? cs.tertiary : cs.onSurfaceVariant))),
            const SizedBox(height: 4), Text('$stage', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: unlocked ? cs.primary : cs.onSurfaceVariant)),
            const SizedBox(height: 3), Icon(unlocked ? Icons.play_circle_fill_rounded : Icons.lock_rounded, size: 18, color: unlocked ? cs.primary : cs.onSurfaceVariant),
          ])),
        ));
      },
    );
  }
}

class StageGameScreen extends StatefulWidget {
  const StageGameScreen({required this.gameType, required this.stage, super.key});
  final int gameType;
  final int stage;

  @override
  State<StageGameScreen> createState() => _StageGameScreenState();
}

class _StageGameScreenState extends State<StageGameScreen> {
  static const kanaQuestions = [('a', ['あ', 'お', 'う', 'え', 'か']), ('ka', ['か', 'き', 'く', 'け', 'こ']), ('shi', ['し', 'さ', 'す', 'せ', 'そ']), ('ta', ['た', 'ち', 'つ', 'て', 'と']), ('na', ['な', 'に', 'ぬ', 'ね', 'の']), ('ha', ['は', 'ひ', 'ふ', 'へ', 'ほ']), ('ma', ['ま', 'み', 'む', 'め', 'も']), ('ya', ['や', 'ゆ', 'よ', 'ら', 'り']), ('ra', ['ら', 'り', 'る', 'れ', 'ろ']), ('wa', ['わ', 'を', 'ん', 'ね', 'の'])];
  static const katakanaQuestions = [('a', ['ア', 'オ', 'ウ', 'エ', 'カ']), ('ka', ['カ', 'キ', 'ク', 'ケ', 'コ']), ('shi', ['シ', 'サ', 'ス', 'セ', 'ソ']), ('ta', ['タ', 'チ', 'ツ', 'テ', 'ト']), ('na', ['ナ', 'ニ', 'ヌ', 'ネ', 'ノ']), ('ha', ['ハ', 'ヒ', 'フ', 'ヘ', 'ホ']), ('ma', ['マ', 'ミ', 'ム', 'メ', 'モ']), ('ya', ['ヤ', 'ユ', 'ヨ', 'ラ', 'リ']), ('ra', ['ラ', 'リ', 'ル', 'レ', 'ロ']), ('wa', ['ワ', 'ヲ', 'ン', 'ネ', 'ノ'])];
  static const kanjiQuestions = [('air', ['水', '火', '木', '山', '川']), ('gunung', ['山', '川', '田', '口', '人']), ('api', ['火', '水', '土', '金', '日']), ('matahari', ['日', '月', '火', '木', '年']), ('bulan', ['月', '日', '本', '中', '天']), ('pohon', ['木', '林', '森', '山', '土']), ('orang', ['人', '入', '大', '子', '女']), ('anak', ['子', '人', '女', '父', '母']), ('ibu', ['母', '父', '女', '子', '友']), ('teman', ['友', '父', '母', '学', '生'])];
  late final List<(String, List<String>)> questions;
  final random = Random();
  Timer? timer;
  int index = 0, score = 0, seconds = 15;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    questions = widget.gameType == 0 ? kanaQuestions : widget.gameType == 1 ? katakanaQuestions : kanjiQuestions;
    timer = Timer.periodic(const Duration(seconds: 1), (_) { if (!mounted || answered) return; if (seconds <= 1) { _answer(''); } else { setState(() => seconds--); } });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  String get title => widget.gameType == 0 ? 'HIRAGANA' : widget.gameType == 1 ? 'KATAKANA' : 'KANJI';
  (String, List<String>) get question => questions[index % questions.length];

  void _answer(String value) {
    if (answered) return;
    answered = true;
    final correct = value == question.$2[0];
    if (correct) score++;
    AppScope.of(context).recordQuiz(correct: correct ? 1 : 0, total: 1);
    Future.delayed(const Duration(milliseconds: 300), () { if (!mounted) return; if (index >= 9) { timer?.cancel(); _showResult(); } else { setState(() { index++; seconds = 15; answered = false; }); } });
  }

  void _showResult() {
    final stars = score >= 9 ? 3 : score >= 6 ? 2 : score >= 3 ? 1 : 0;
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      title: const Text('Tahap selesai!'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 42, color: Theme.of(context).colorScheme.tertiary))), const SizedBox(height: 14), Text('Skor $score/10', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(stars == 3 ? 'Mantap! Tahap dikuasai.' : 'Coba lagi untuk mendapatkan lebih banyak bintang.')]),
      actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Kembali')), FilledButton(onPressed: () { Navigator.pop(context); setState(() { index = 0; score = 0; seconds = 15; answered = false; }); timer = Timer.periodic(const Duration(seconds: 1), (_) { if (!mounted || answered) return; if (seconds <= 1) { _answer(''); } else { setState(() => seconds--); } }); }, child: const Text('Main lagi'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = [...question.$2.sublist(0, 5)]..shuffle(random);
    return Scaffold(appBar: AppBar(title: Text('Tahap ${widget.stage}')), body: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 30), children: [
      ContentDummyImage(title: title, subtitle: 'Ilustrasi sementara permainan', height: 145),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5))), Text('${index + 1}/10', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: (index + 1) / 10, minHeight: 9)),
      const SizedBox(height: 8), Row(children: [const Icon(Icons.timer_rounded, size: 18), const SizedBox(width: 5), Text('${seconds}s', style: TextStyle(fontWeight: FontWeight.w900)), const Spacer(), Icon(Icons.star_rounded, color: cs.tertiary), const SizedBox(width: 4), Text('$score', style: const TextStyle(fontWeight: FontWeight.w900))]),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20), child: Column(children: [Text(question.$1, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: cs.primary)), const SizedBox(height: 14), Text(widget.gameType == 2 ? 'Pilih kanji yang benar' : 'Pilih karakter yang sesuai', style: TextStyle(color: cs.onSurfaceVariant))]))),
      const SizedBox(height: 16),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: options.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.1), itemBuilder: (_, i) => FilledButton.tonal(onPressed: answered ? null : () => _answer(options[i]), child: Text(options[i], style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))))
    ]));
  }
}
