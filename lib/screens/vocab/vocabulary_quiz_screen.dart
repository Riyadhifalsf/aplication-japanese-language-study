import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/morphology_service.dart';
import '../../services/vocabulary_examples_service.dart';
import '../../state/app_controller.dart';

class VocabularyQuizScreen extends StatefulWidget {
  const VocabularyQuizScreen(
      {super.key, this.level = 'Semua', this.sessionSize = 10});

  final String level;
  final int sessionSize;

  @override
  State<VocabularyQuizScreen> createState() => _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends State<VocabularyQuizScreen> {
  final _rng = Random();
  final _questions = <_VocabularyQuestion>[];
  int _index = 0;
  int _correct = 0;
  bool _finished = false;
  String? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questions.isEmpty) _buildQuestions(AppScope.of(context));
  }

  void _buildQuestions(AppController app) {
    final source = widget.level == 'Semua'
        ? app.repository.vocabulary
        : app.repository.vocabularyForLevel(widget.level);
    if (source.length < 4) return;
    final pool = [...source]..shuffle(_rng);
    final count = widget.sessionSize.clamp(5, 20).toInt();
    final selected = pool.take(count).toList();
    for (var i = 0; i < selected.length; i++) {
      final item = selected[i];
      final others = source.where((v) => v.id != item.id).toList()
        ..shuffle(_rng);
      final forms = MorphologyService.forms(item);
      final masu = forms.isNotEmpty
          ? forms
              .firstWhere((f) => f.label == 'Masu', orElse: () => forms.first)
              .value
          : item.word;
      final examples = VocabularyExamplesService.build(item);
      final particle = examples.isNotEmpty ? examples.first.particle : 'は';
      final exampleJapanese =
          examples.isNotEmpty ? examples.first.japanese : item.word;
      final mode = i % 4;

      // Every question must have enough unique choices. If a dataset row is
      // sparse, fall back to the safest meaning/reading format instead of
      // indexing an empty list.
      final meaningDistractors = _uniqueDistractors(
        others.map((v) => v.meaning),
        item.meaning,
      );
      final readingDistractors = _uniqueDistractors(
        others.map((v) => v.reading),
        item.reading,
      );
      final formDistractors = _uniqueDistractors(
        forms.where((f) => f.label != 'Masu').map((f) => f.value),
        masu,
      );

      if (mode == 1 && formDistractors.length == 3) {
        _questions.add(_VocabularyQuestion(
          'Bentuk ます yang benar dari 「${item.word}」?',
          masu,
          formDistractors,
        ));
      } else if (mode == 2 && readingDistractors.length == 3) {
        _questions.add(_VocabularyQuestion(
          'Kotoba 「${item.word}」 dibaca bagaimana?',
          item.reading,
          readingDistractors,
        ));
      } else if (mode == 3 && examples.isNotEmpty) {
        _questions.add(_VocabularyQuestion(
          'Partikel pada contoh 「$exampleJapanese」?',
          particle,
          ['は', 'が', 'を', 'に'].where((v) => v != particle).take(3).toList(),
        ));
      } else if (meaningDistractors.length == 3) {
        _questions.add(_VocabularyQuestion(
          'Apa arti 「${item.word}」?',
          item.meaning,
          meaningDistractors,
        ));
      } else if (readingDistractors.length == 3) {
        _questions.add(_VocabularyQuestion(
          'Kotoba 「${item.word}」 dibaca bagaimana?',
          item.reading,
          readingDistractors,
        ));
      }
    }
    for (final q in _questions) {
      q.options = [q.answer, ...q.distractors]..shuffle(_rng);
    }
  }

  List<String> _uniqueDistractors(Iterable<String> values, String answer) {
    final seen = <String>{answer.trim()};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && seen.add(normalized)) result.add(value);
      if (result.length == 3) break;
    }
    return result;
  }

  void _answer(String answer) {
    if (_selected != null || _finished) return;
    final q = _questions[_index];
    final correct = answer == q.answer;
    if (correct) _correct++;
    setState(() => _selected = answer);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      if (_index == _questions.length - 1) {
        AppScope.of(context)
            .recordQuiz(correct: _correct, total: _questions.length);
        setState(() => _finished = true);
      } else {
        setState(() {
          _index++;
          _selected = null;
        });
      }
    });
  }

  void _restart() {
    setState(() {
      _questions.clear();
      _index = 0;
      _correct = 0;
      _finished = false;
      _selected = null;
      _buildQuestions(AppScope.of(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuis Kosakata')),
        body: const Center(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'Soal kosakata belum siap. Kembali ke Pusat Quiz lalu coba lagi setelah data selesai dimuat.',
                    textAlign: TextAlign.center))),
      );
    }
    if (_finished) {
      final percent = (_correct / _questions.length * 100).round();
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Kuis Kosakata')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    percent >= 80
                        ? Icons.emoji_events_rounded
                        : Icons.replay_rounded,
                    size: 78),
                const SizedBox(height: 14),
                Text('$_correct/${_questions.length}',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900)),
                Text('Akurasi $percent%'),
                const SizedBox(height: 20),
                FilledButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Ulangi kuis')),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis Kosakata'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
                child: Text('${_index + 1}/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.w900))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          LinearProgressIndicator(value: (_index + 1) / _questions.length),
          const SizedBox(height: 22),
          Text(q.prompt,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          for (final option in q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: _selected == null ? () => _answer(option) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  alignment: Alignment.centerLeft,
                  side: _selected == null
                      ? null
                      : BorderSide(
                          color: option == q.answer
                              ? Colors.green
                              : option == _selected
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.outline,
                          width:
                              option == q.answer || option == _selected ? 2 : 1,
                        ),
                ),
                child: Text(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _VocabularyQuestion {
  _VocabularyQuestion(this.prompt, this.answer, this.distractors)
      : options = [];
  final String prompt;
  final String answer;
  final List<String> distractors;
  List<String> options;
}
