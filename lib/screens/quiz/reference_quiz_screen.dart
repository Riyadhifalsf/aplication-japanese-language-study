import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/lesson_questions.dart';
import '../../state/app_controller.dart';

/// Interactive quiz UI based on the supplied references: one question at a
/// time, large answer cards, immediate feedback, explanation and progress.
class ReferenceQuizScreen extends StatefulWidget {
  const ReferenceQuizScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  State<ReferenceQuizScreen> createState() => _ReferenceQuizScreenState();
}

class _ReferenceQuizScreenState extends State<ReferenceQuizScreen> {
  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _correct = 0;
  List<PracticeQuestion> _questions = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questions.isNotEmpty) return;
    final app = AppScope.of(context);
    final lesson = CurriculumCatalogData.lessonById(widget.lessonId);
    if (lesson == null) return;
    final resolved = resolveLessonContent(app.repository, lesson);
    _questions = buildLessonQuestions(
      phrases: resolved.phrases,
      vocabs: resolved.vocabs,
      grammars: resolved.grammars,
      kanjis: resolved.kanjis,
      listening: false,
      authored: lesson.authoredQuestions,
    );
    if (_questions.length > 10) _questions = _questions.take(10).toList();
  }

  void _answer(int index) {
    if (_answered) return;
    setState(() {
      _selected = index;
      _answered = true;
      if (index == _questions[_index].correctIndex) _correct++;
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _showResult();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  void _showResult() {
    final percent = ((_correct / _questions.length) * 100).round();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(percent >= 70 ? '🎉 Bagus!' : '💪 Ulangi lagi'),
        content: Text('Skor $_correct/${_questions.length} · $percent%\n\n${percent >= 70 ? 'Latihan selesai. Materi sudah cukup dikuasai.' : 'Coba ulangi materi yang masih terasa sulit.'}'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('SELESAI')),
          if (percent < 70) FilledButton(onPressed: () { Navigator.pop(context); setState(() { _index = 0; _selected = null; _answered = false; _correct = 0; }); }, child: const Text('ULANGI')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Latihan')), body: const Center(child: Text('Belum ada soal untuk lesson ini.')));
    final q = _questions[_index];
    final scheme = Theme.of(context).colorScheme;
    final progress = (_index + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Latihan'), actions: [Padding(padding: const EdgeInsets.only(right: 18), child: Center(child: Text('${_index + 1}/${_questions.length}', style: const TextStyle(fontWeight: FontWeight.w800))))]),
      body: Column(children: [
        LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 6),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
          Text(q.isListening ? 'Ketuk apa yang Anda dengar' : 'Pilih jawaban yang benar', style: scheme.primary == scheme.primary ? TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 15) : null),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.fromLTRB(18, 24, 18, 24), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(26)), child: Column(children: [
            if (q.isListening) const Icon(Icons.volume_up_rounded, size: 52),
            if (q.isListening) const SizedBox(height: 12),
            Text(q.prompt, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.25)),
            if (q.reading.isNotEmpty && !q.isListening) ...[const SizedBox(height: 8), Text(q.reading, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16))],
          ])),
          const SizedBox(height: 20),
          if (q.isOrdering && q.tokens.isNotEmpty)
            _OrderingHint(tokens: q.tokens)
          else
            for (var i = 0; i < q.options.length; i++) _AnswerCard(index: i, text: q.options[i], selected: _selected == i, answered: _answered, correct: q.correctIndex == i, onTap: () => _answer(i)),
          if (_answered) ...[
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: (_selected == q.correctIndex ? Colors.green : Colors.red).withValues(alpha: .10), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selected == q.correctIndex ? '✓ Benar' : '✕ Belum tepat', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _selected == q.correctIndex ? Colors.green.shade700 : Colors.red.shade700)),
              const SizedBox(height: 7),
              if (_selected != q.correctIndex) Text('Jawaban: ${q.options[q.correctIndex]}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(q.explanation, style: const TextStyle(height: 1.4)),
            ])),
          ],
        ])),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 18), child: SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: _answered ? _next : null, child: Text(_index + 1 == _questions.length ? 'LIHAT HASIL' : 'LANJUTKAN'))))),
      ]),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.index, required this.text, required this.selected, required this.answered, required this.correct, required this.onTap});
  final int index;
  final String text;
  final bool selected;
  final bool answered;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? fill;
    Color? border;
    if (answered && correct) { fill = Colors.green.withValues(alpha: .10); border = Colors.green; }
    else if (answered && selected) { fill = Colors.red.withValues(alpha: .10); border = Colors.red; }
    else if (selected) { fill = scheme.primaryContainer; border = scheme.primary; }
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20), border: Border.all(color: border ?? scheme.outlineVariant, width: border == null ? 1 : 2)), child: InkWell(borderRadius: BorderRadius.circular(20), onTap: answered ? null : onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17), child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(String.fromCharCode(65 + index), style: const TextStyle(fontWeight: FontWeight.w900)))),
      const SizedBox(width: 14),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
      if (answered && correct) const Icon(Icons.check_circle_rounded, color: Colors.green),
      if (answered && selected && !correct) const Icon(Icons.cancel_rounded, color: Colors.red),
    ]))));
  }
}

class _OrderingHint extends StatelessWidget {
  const _OrderingHint({required this.tokens});
  final List<String> tokens;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Theme.of(context).colorScheme.primaryContainer), child: Wrap(spacing: 8, runSpacing: 8, children: tokens.map((token) => Chip(label: Text(token))).toList()));
}
