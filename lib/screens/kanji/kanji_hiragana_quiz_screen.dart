import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class KanjiHiraganaQuizScreen extends StatefulWidget {
  const KanjiHiraganaQuizScreen({super.key, this.initialLevel = 'N5'});

  final String initialLevel;

  @override
  State<KanjiHiraganaQuizScreen> createState() => _KanjiHiraganaQuizScreenState();
}

class _KanjiHiraganaQuizScreenState extends State<KanjiHiraganaQuizScreen> {
  final _random = Random();
  Timer? _autoNextTimer;
  late String _level;
  var _started = false;
  var _finished = false;
  var _index = 0;
  var _correct = 0;
  int? _selectedId;
  bool _recorded = false;
  List<Kanji> _questions = const [];
  List<Kanji> _choices = const [];

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return _setup(context);
    if (_finished) return _result(context);
    return _quiz(context);
  }

  Widget _setup(BuildContext context) {
    final app = AppScope.of(context);
    final count = _pool(app).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Kuis Kanji Hiragana')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFFE64E64), Color(0xFFFFA62B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '漢字 → ひらがな',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Lihat kanji, lalu pilih bacaan hiragana yang benar. Cocok untuk melatih baca kanji tanpa bergantung pada arti.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Pilih tingkat'),
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
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.seed.withValues(alpha: .14),
                foregroundColor: AppTheme.seed,
                child: const Icon(Icons.menu_book_rounded),
              ),
              title: Text(
                '$count kanji siap dilatih',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('Satu sesi berisi 15 soal acak.'),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: count < 4 ? null : () => _start(app),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Mulai latihan'),
          ),
          if (count < 4) ...[
            const SizedBox(height: 10),
            Text(
              'Tingkat ini belum punya cukup data bacaan. Pilih tingkat lain dulu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quiz(BuildContext context) {
    final current = _questions[_index];
    final reveal = _selectedId != null;
    return Scaffold(
      appBar: AppBar(title: Text('Kanji Hiragana · $_level')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              Expanded(child: Text('Soal ${_index + 1}/${_questions.length}')),
              Text(
                'Benar $_correct',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Card(
              key: ValueKey(current.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Column(
                  children: [
                    Text(
                      'Pilih bacaan hiragana untuk kanji ini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        current.character,
                        style: const TextStyle(
                          fontSize: 88,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    JlptBadge(current.level),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final choice in _choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HiraganaAnswerButton(
                text: _reading(choice),
                selected: _selectedId == choice.id,
                reveal: reveal,
                correct: choice.id == current.id,
                onPressed: reveal ? null : () => _answer(choice, current),
              ),
            ),
          if (reveal) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  _selectedId == current.id
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: _selectedId == current.id
                      ? AppTheme.success
                      : Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '${current.character} dibaca ${_reading(current)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(current.meaning),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedId == current.id)
              const _LanjutOtomatis()
            else
              FilledButton(
                onPressed: _next,
                child: Text(_index == _questions.length - 1 ? 'Lihat hasil' : 'Soal berikutnya'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    final app = AppScope.of(context);
    final accuracy = (_correct / _questions.length * 100).round();
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        app.recordQuiz(correct: _correct, total: _questions.length);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil latihan')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 58,
                backgroundColor: AppTheme.seed.withValues(alpha: .13),
                child: Text(
                  '$accuracy%',
                  style: const TextStyle(
                    color: AppTheme.seed,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                accuracy >= 85 ? 'Bacaan kanjimu makin kuat.' : 'Ulangi lagi pelan-pelan.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text('$_correct benar dari ${_questions.length} soal'),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: () => _start(AppScope.of(context)),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Ulangi latihan'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _started = false;
                  _finished = false;
                  _selectedId = null;
                }),
                child: const Text('Pilih tingkat lain'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Kanji> _pool(AppController app) => app.repository
      .kanjiForLevel(_level)
      .where((item) => item.hasCompleteMetadata)
      .where((item) => _reading(item).isNotEmpty)
      .toList(growable: true);

  void _start(AppController app) {
    final pool = _pool(app)..shuffle(_random);
    setState(() {
      _questions = pool.take(15).toList(growable: false);
      _index = 0;
      _correct = 0;
      _selectedId = null;
      _recorded = false;
      _started = true;
      _finished = false;
    });
    _makeChoices(app);
  }

  void _makeChoices(AppController app) {
    final current = _questions[_index];
    final output = <Kanji>[current];
    final seen = <String>{_reading(current)};
    final pool = app.repository
        .kanjiForLevel(current.level)
        .where((item) => item.id != current.id && item.hasCompleteMetadata)
        .toList(growable: true)
      ..shuffle(_random);
    for (final item in pool) {
      if (seen.add(_reading(item))) output.add(item);
      if (output.length == 4) break;
    }
    setState(() => _choices = output..shuffle(_random));
  }

  void _answer(Kanji choice, Kanji current) {
    final isCorrect = choice.id == current.id;
    AppScope.of(context).tts.speak(_reading(current));
    setState(() {
      _selectedId = choice.id;
      if (isCorrect) _correct++;
    });
    if (isCorrect) {
      _autoNextTimer?.cancel();
      _autoNextTimer = Timer(const Duration(milliseconds: 850), () {
        if (mounted) _next();
      });
    }
  }

  void _next() {
    _autoNextTimer?.cancel();
    if (_index >= _questions.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selectedId = null;
    });
    _makeChoices(AppScope.of(context));
  }

  String _reading(Kanji item) => _katakanaToHiragana(item.preferredReading);

  String _katakanaToHiragana(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[.・、,/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final buffer = StringBuffer();
    for (final code in cleaned.runes) {
      if (code >= 0x30A1 && code <= 0x30F6) {
        buffer.writeCharCode(code - 0x60);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }
}

class _HiraganaAnswerButton extends StatelessWidget {
  const _HiraganaAnswerButton({
    required this.text,
    required this.selected,
    required this.reveal,
    required this.correct,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final bool reveal;
  final bool correct;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = !reveal
        ? Theme.of(context).colorScheme.outlineVariant
        : correct
            ? AppTheme.success
            : selected
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: color.withValues(alpha: reveal && (selected || correct) ? .12 : .03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .65)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
              if (reveal && correct)
                const Icon(Icons.check_circle_rounded, color: AppTheme.success)
              else if (reveal && selected)
                Icon(Icons.cancel_rounded, color: Theme.of(context).colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanjutOtomatis extends StatelessWidget {
  const _LanjutOtomatis();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 10),
            Text(
              'Benar — lanjut otomatis…',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}
