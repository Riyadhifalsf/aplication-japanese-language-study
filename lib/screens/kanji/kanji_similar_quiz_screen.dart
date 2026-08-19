import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class KanjiSimilarQuizScreen extends StatefulWidget {
  const KanjiSimilarQuizScreen({super.key});

  @override
  State<KanjiSimilarQuizScreen> createState() => _KanjiSimilarQuizScreenState();
}

class _KanjiSimilarQuizScreenState extends State<KanjiSimilarQuizScreen> {
  final _random = Random();
  String _level = 'N5';
  var _questionIndex = 0;
  var _correct = 0;
  var _started = false;
  var _finished = false;
  int? _selectedId;
  List<Kanji> _questions = const [];
  List<Kanji> _choices = const [];

  @override
  Widget build(BuildContext context) {
    if (!_started) return _setup(context);
    if (_finished) return _result(context);
    return _quiz(context);
  }

  Widget _setup(BuildContext context) {
    final app = AppScope.of(context);
    final count = app.repository.kanji.where((item) => item.level == _level).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Kuis Kanji Mirip')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF2F2C44), Color(0xFF7C3AED)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.blur_on_rounded, color: Colors.white, size: 34),
                SizedBox(height: 14),
                Text(
                  'Bedakan kanji yang kelihatan mirip',
                  style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'Latihan ini memilih pilihan pengecoh dari kanji satu tingkat, jumlah goresan yang berdekatan, dan kanji terkait.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: 'Tingkat'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in ['N5', 'N4', 'N3', 'N2', 'N1'])
                ChoiceChip(
                  selected: _level == level,
                  label: Text(level),
                  onSelected: (_) => setState(() => _level = level),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.remove_red_eye_rounded)),
              title: Text('$count kanji tersedia', style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Sesi latihan mengambil 12 soal.'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: count < 6 ? null : () => _start(app),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Mulai latihan'),
          ),
        ],
      ),
    );
  }

  Widget _quiz(BuildContext context) {
    final current = _questions[_questionIndex];
    final reveal = _selectedId != null;
    return Scaffold(
      appBar: AppBar(title: Text('Mirip · $_level')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Row(
            children: [
              Expanded(child: Text('Soal ${_questionIndex + 1}/${_questions.length}')),
              Text('Benar $_correct', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: (_questionIndex + 1) / _questions.length, minHeight: 8),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Pilih kanji yang artinya:',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    current.meaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Goresan target: ${current.strokes}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _choices.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final item = _choices[index];
                  final selected = _selectedId == item.id;
                  final correct = item.id == current.id;
                  final color = reveal && correct
                      ? const Color(0xFF17A673)
                      : reveal && selected
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.outlineVariant;
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: reveal ? null : () => _answer(item, current),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: reveal && (selected || correct) ? .16 : .05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: color.withValues(alpha: .55)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.character,
                              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.preferredReading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (reveal) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_questionIndex == _questions.length - 1 ? 'Lihat hasil' : 'Berikutnya'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _result(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hasil')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 54, color: Color(0xFFFFA62B)),
                    const SizedBox(height: 12),
                    Text('$_correct/${_questions.length} benar', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      'Latihan kanji mirip membantu mata lebih cepat membedakan bentuk yang dekat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => setState(() => _started = false), child: const Text('Latihan lagi')),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _start(AppController app) {
    final pool = app.repository.kanji.where((item) => item.level == _level).toList()..shuffle(_random);
    _questions = pool.take(12).toList();
    _questionIndex = 0;
    _correct = 0;
    _selectedId = null;
    _started = true;
    _finished = false;
    _makeChoices(app);
    setState(() {});
  }

  void _makeChoices(AppController app) {
    final current = _questions[_questionIndex];
    final pool = app.repository.kanji.where((item) => item.level == _level && item.id != current.id).toList();
    pool.sort((a, b) {
      final ar = current.relatedIds.contains(a.id) ? 0 : 1;
      final br = current.relatedIds.contains(b.id) ? 0 : 1;
      if (ar != br) return ar.compareTo(br);
      final ad = (a.strokes - current.strokes).abs();
      final bd = (b.strokes - current.strokes).abs();
      return ad.compareTo(bd);
    });
    _choices = [current, ...pool.take(3)]..shuffle(_random);
  }

  void _answer(Kanji choice, Kanji current) {
    final app = AppScope.of(context);
    setState(() {
      _selectedId = choice.id;
      if (choice.id == current.id) _correct++;
    });
    app.tts.speak(current.preferredReading);
  }

  void _next() {
    if (_questionIndex >= _questions.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedId = null;
      _makeChoices(AppScope.of(context));
    });
  }
}
