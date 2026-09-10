import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class LevelPlacementScreen extends StatefulWidget {
  const LevelPlacementScreen({required this.level, super.key});

  final String level;

  @override
  State<LevelPlacementScreen> createState() => _LevelPlacementScreenState();
}

class _LevelPlacementScreenState extends State<LevelPlacementScreen> {
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _answered = false;

  List<_PlacementQuestion> get _questions => _bank(widget.level);

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    const nextLevel = {'N5': 'N4', 'N4': 'N3', 'N3': 'N2', 'N2': 'N1', 'N1': 'N1'};
    final opens = nextLevel[widget.level] ?? widget.level;

    return Scaffold(
      appBar: AppBar(title: Text('Placement ${widget.level}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          Text(
            'Tes kemampuan ${widget.level}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Jawab 10 soal. Skor 80% akan membuka $opens.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(value: (_index + 1) / _questions.length),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soal ${_index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(q.prompt, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  for (var i = 0; i < q.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _answered ? null : () => _choose(i),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(q.options[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_answered)
            Text(
              _selected == q.correct ? '正解！' : 'Jawaban belum tepat. Pelajari lagi materi terkait.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _selected == q.correct ? Colors.green : Theme.of(context).colorScheme.error,
              ),
            ),
          if (_answered) const SizedBox(height: 10),
          if (_answered)
            FilledButton(
              onPressed: _next,
              child: Text(_index == _questions.length - 1 ? 'Lihat hasil' : 'Berikutnya'),
            ),
        ],
      ),
    );
  }

  void _choose(int index) {
    setState(() {
      _selected = index;
      _answered = true;
      if (index == _questions[_index].correct) _correct++;
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
      return;
    }
    final score = ((_correct / _questions.length) * 100).round();
    final app = AppScope.of(context);
    app.recordPlacement(widget.level, score);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Skor $score%'),
        content: Text(
          score >= 80
              ? 'Mantap. Level berikutnya dibuka.'
              : 'Belum cukup untuk membuka level berikutnya. Kamu tetap bisa belajar dari path yang tersedia.',
        ),
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
  }
}

class _PlacementQuestion {
  const _PlacementQuestion(this.prompt, this.options, this.correct);
  final String prompt;
  final List<String> options;
  final int correct;
}

List<_PlacementQuestion> _bank(String level) {
  if (level == 'N5') {
    return const [
      _PlacementQuestion('「ありがとう」 artinya…', ['Terima kasih', 'Selamat pagi', 'Maaf', 'Sampai jumpa'], 0),
      _PlacementQuestion('「わたしは学生です」 berarti…', ['Saya siswa', 'Saya guru', 'Saya bekerja', 'Saya pergi'], 0),
      _PlacementQuestion('Hiragana untuk “ka” adalah…', ['か', 'さ', 'き', 'け'], 0),
      _PlacementQuestion('「これは本です」 menunjuk…', ['Buku ini', 'Rumah itu', 'Orang itu', 'Hari ini'], 0),
      _PlacementQuestion('Partikel objek yang umum adalah…', ['を', 'に', 'へ', 'と'], 0),
      _PlacementQuestion('「日本」 dibaca…', ['にほん', 'ほんに', 'にっぽんご', 'にほんご'], 0),
      _PlacementQuestion('Bentuk sopan “makan” adalah…', ['たべます', 'たべるる', 'たべした', 'たべませんか'], 0),
      _PlacementQuestion('「どこ」 digunakan untuk menanyakan…', ['Di mana', 'Kapan', 'Siapa', 'Berapa'], 0),
      _PlacementQuestion('「水」 artinya…', ['Air', 'Api', 'Gunung', 'Buku'], 0),
      _PlacementQuestion('「7時」 adalah…', ['Jam 7', 'Tanggal 7', 'Tujuh orang', 'Tujuh buku'], 0),
    ];
  }
  return List.generate(
    10,
    (i) => _PlacementQuestion(
      'Pilih pemahaman dasar yang paling tepat untuk kompetensi $level, soal ${i + 1}.',
      const ['Makna dan penggunaan tepat', 'Pilihan kedua', 'Pilihan ketiga', 'Pilihan keempat'],
      0,
    ),
  );
}
