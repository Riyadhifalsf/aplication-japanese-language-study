import 'package:flutter/material.dart';
import '../../state/app_controller.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games Bahasa Jepang')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          _GameCard(
            title: 'Ketik Kana',
            subtitle: 'Ketik jawaban hiragana/katakana secepat mungkin.',
            icon: Icons.keyboard_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TypingGameScreen(mode: 'kana')),
            ),
          ),
          _GameCard(
            title: 'Ketik Kotoba',
            subtitle: 'Tulis kata Jepang yang benar dari arti.',
            icon: Icons.abc_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TypingGameScreen(mode: 'vocab')),
            ),
          ),
          _GameCard(
            title: 'Ketik Kanji',
            subtitle: 'Tulis kanji yang sesuai dengan kata.',
            icon: Icons.translate_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TypingGameScreen(mode: 'kanji')),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        isThreeLine: true,
        onTap: onTap,
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle)),
        trailing: const Icon(Icons.play_arrow_rounded),
      ),
    );
  }
}

class TypingGameScreen extends StatefulWidget {
  const TypingGameScreen({required this.mode, super.key});
  final String mode;
  @override
  State<TypingGameScreen> createState() => _TypingGameScreenState();
}

class _TypingGameScreenState extends State<TypingGameScreen> {
  final controller = TextEditingController();
  int index = 0;
  int score = 0;
  final items = const [
    ('ka', 'か', 'か'),
    ('sa', 'さ', 'さ'),
    ('a', 'あ', 'あ'),
    ('neko', 'ねこ', '猫'),
    ('yama', 'やま', '山'),
    ('mizu', 'みず', '水'),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get prompt {
    final item = items[index % items.length];
    if (widget.mode == 'kana') return item.$1;
    if (widget.mode == 'kanji') return item.$2;
    return item.$1;
  }

  String get answer {
    final item = items[index % items.length];
    if (widget.mode == 'kana') return item.$2;
    if (widget.mode == 'kanji') return item.$3;
    return item.$2;
  }

  void submit() {
    final correct = controller.text.trim() == answer;
    if (correct) score++;
    AppScope.of(context).recordQuiz(correct: correct ? 1 : 0, total: 1);
    controller.clear();
    if (index >= 9) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Selesai'),
          content: Text('Skor $score/10'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } else {
      setState(() => index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.mode == 'kana' ? 'Tulis kana' : widget.mode == 'kanji' ? 'Tulis kanji' : 'Tulis kotoba';
    return Scaffold(
      appBar: AppBar(title: const Text('Typing Game')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (index + 1) / 10),
            const SizedBox(height: 22),
            Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            Card(child: Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(prompt, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900))))),
            const SizedBox(height: 16),
            TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Jawaban', border: OutlineInputBorder()), onSubmitted: (_) => submit()),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: submit, icon: const Icon(Icons.check_rounded), label: const Text('Jawab')),
          ],
        ),
      ),
    );
  }
}
