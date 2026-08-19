import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kanji.dart';
import '../../models/vocabulary.dart';
import '../../state/app_controller.dart';

enum QuizMode { meaning, reading, word }

class KanjiQuizScreen extends StatefulWidget {
  const KanjiQuizScreen({
    required this.kanji,
    required this.items,
    super.key,
  });

  final Kanji kanji;
  final List<Vocabulary> items;

  @override
  State<KanjiQuizScreen> createState() => _KanjiQuizScreenState();
}

class _KanjiQuizScreenState extends State<KanjiQuizScreen> {
  final _random = Random();
  Timer? _autoNextTimer;
  late List<Vocabulary> _questions;
  QuizMode _mode = QuizMode.meaning;
  int _index = 0;
  int _correct = 0;
  int? _selectedId;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _questions = [...widget.items]..shuffle(_random);
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    super.dispose();
  }

  bool get _finished => _index >= _questions.length;

  @override
  Widget build(BuildContext context) {
    if (_finished) return _result(context);
    final question = _questions[_index];
    final choices = _choices(question);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kanji.character} · Kuis'),
        actions: [
          PopupMenuButton<QuizMode>(
            initialValue: _mode,
            tooltip: 'Mode kuis',
            onSelected: (mode) => setState(() {
              _autoNextTimer?.cancel();
              _mode = mode;
              _selectedId = null;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: QuizMode.meaning,
                child: Text('Kosakata → arti'),
              ),
              PopupMenuItem(
                value: QuizMode.reading,
                child: Text('Kosakata → bacaan'),
              ),
              PopupMenuItem(
                value: QuizMode.word,
                child: Text('Arti → kosakata'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Row(
            children: [
              Text('Soal ${_index + 1}/${_questions.length}'),
              const Spacer(),
              Text(
                'Benar: $_correct',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _index / _questions.length,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 36,
              ),
              child: Column(
                children: [
                  Text(
                    _promptLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _questionValue(question),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerButton(
                text: _answerValue(choice),
                selected: _selectedId == choice.id,
                reveal: _selectedId != null,
                correct: choice.id == question.id,
                onPressed:
                    _selectedId == null ? () => _answer(choice, question) : null,
              ),
            ),
          if (_selectedId != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _selectedId == question.id
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: _selectedId == question.id
                          ? AppTheme.success
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${question.word}（${question.reading}）— ${question.meaning}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedId == question.id)
              const _QuizAutoNextIndicator()
            else
              FilledButton(
                onPressed: _next,
                child: Text(
                  _index == _questions.length - 1
                      ? 'Lihat hasil'
                      : 'Soal berikutnya',
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    final app = AppScope.of(context);
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        app.recordQuiz(correct: _correct, total: _questions.length);
      });
    }
    final accuracy = (_correct / _questions.length * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil kuis')),
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
                accuracy == 100
                    ? '満点！ Sempurna!'
                    : accuracy >= 80
                        ? 'Bagus sekali!'
                        : 'Terus berlatih!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '$_correct benar dari ${_questions.length} soal',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Ulangi kuis'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke detail kanji'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _promptLabel => switch (_mode) {
        QuizMode.meaning => 'Pilih arti yang benar',
        QuizMode.reading => 'Pilih bacaan yang benar',
        QuizMode.word => 'Pilih kosakata yang benar',
      };

  String _questionValue(Vocabulary item) => switch (_mode) {
        QuizMode.meaning || QuizMode.reading => item.word,
        QuizMode.word => item.meaning,
      };

  String _answerValue(Vocabulary item) => switch (_mode) {
        QuizMode.meaning => item.meaning,
        QuizMode.reading => item.reading,
        QuizMode.word => item.word,
      };

  List<Vocabulary> _choices(Vocabulary correct) {
    final app = AppScope.of(context);
    final stableRandom = Random(correct.id * 10 + _mode.index);
    final output = <Vocabulary>[correct];
    final seen = <String>{_answerValue(correct)};

    void addChoice(Vocabulary item) {
      if (seen.add(_answerValue(item))) output.add(item);
    }

    for (final item in widget.items) {
      if (item.id != correct.id) addChoice(item);
      if (output.length == 4) break;
    }
    final pool = app.repository.vocabulary;
    if (output.length < 4 && pool.isNotEmpty) {
      final start = stableRandom.nextInt(pool.length);
      for (var offset = 0;
          offset < pool.length && output.length < 4;
          offset++) {
        final item = pool[(start + offset * 37) % pool.length];
        if (item.id != correct.id) addChoice(item);
      }
    }
    output.shuffle(stableRandom);
    return output;
  }

  void _answer(Vocabulary choice, Vocabulary correct) {
    final isCorrect = choice.id == correct.id;
    AppScope.of(context).tts.speak(correct.reading);
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
    setState(() {
      _index++;
      _selectedId = null;
    });
  }

  void _restart() {
    _autoNextTimer?.cancel();
    setState(() {
      _questions = [...widget.items]..shuffle(_random);
      _index = 0;
      _correct = 0;
      _selectedId = null;
      _recorded = false;
    });
  }
}

class _QuizAutoNextIndicator extends StatelessWidget {
  const _QuizAutoNextIndicator();

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

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
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
    Color? color;
    if (reveal && correct) color = AppTheme.success;
    if (reveal && selected && !correct) {
      color = Theme.of(context).colorScheme.error;
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        alignment: Alignment.centerLeft,
        side: color == null ? null : BorderSide(color: color, width: 2),
        foregroundColor: color,
        backgroundColor: color?.withValues(alpha: .08),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}
