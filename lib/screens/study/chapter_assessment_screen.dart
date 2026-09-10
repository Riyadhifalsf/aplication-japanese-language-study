import 'package:flutter/material.dart';
import 'learning_path_screen.dart';
import '../../state/app_controller.dart';

class ChapterAssessmentScreen extends StatefulWidget {
  const ChapterAssessmentScreen({required this.chapter, super.key});
  final dynamic chapter;
  @override State<ChapterAssessmentScreen> createState() => _ChapterAssessmentScreenState();
}

class _ChapterAssessmentScreenState extends State<ChapterAssessmentScreen> {
  int index = 0;
  int correct = 0;
  int? selected;
  final List<String> options = const ['Pernyataan pertama paling sesuai dengan target bab.', 'Pilihan kedua sebagai pengecoh.', 'Pilihan ketiga sebagai pengecoh.', 'Pilihan keempat sebagai pengecoh.'];

  dynamic get chapter => widget.chapter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final materials = (chapter.material as List<String>);
    final total = materials.length < 5 ? 5 : materials.length;
    final prompt = index < materials.length ? 'Mana konsep yang termasuk materi inti Bab ${chapter.number}?\n\n${materials[index]}' : 'Target utama Bab ${chapter.number} adalah…\n\n${chapter.target}';
    return Scaffold(
      appBar: AppBar(title: Text('Uji Bab ${chapter.number}')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 30), children: [
        LinearProgressIndicator(value: (index + 1) / total, minHeight: 8),
        const SizedBox(height: 18),
        Text(chapter.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('${index + 1} / $total soal', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.4)))),
        const SizedBox(height: 12),
        for (var i = 0; i < options.length; i++) _Option(text: options[i], selected: selected == i, correct: selected != null && i == 0, onTap: selected == null ? () => _answer(i) : null),
        const SizedBox(height: 12),
        if (selected != null) FilledButton(onPressed: _next, child: Text(index == total - 1 ? 'Lihat hasil' : 'Berikutnya')),
        const SizedBox(height: 8),
        Text('Lulus otomatis pada 80% atau lebih. Bab yang lulus membuka bab berikutnya.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ]),
    );
  }

  void _answer(int value) {
    setState(() { selected = value; if (value == 0) correct++; });
  }

  void _next() {
    final materials = (chapter.material as List<String>);
    final total = materials.length < 5 ? 5 : materials.length;
    if (index < total - 1) { setState(() { index++; selected = null; }); return; }
    final score = (correct / total * 100).round();
    final app = AppScope.of(context);
    app.recordQuiz(correct: correct, total: total);
    if (score >= 80) app.completeLearningStep(chapter.id as String);
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => AlertDialog(title: Text('Hasil $score%'), content: Text(score >= 80 ? 'Lulus. Bab ${chapter.number} selesai dan bab berikutnya dapat dibuka.' : 'Belum lulus. Ulangi materi lalu coba lagi.'), actions: [FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Selesai'))]));
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.text, required this.selected, required this.correct, required this.onTap});
  final String text; final bool selected; final bool correct; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => Card(color: selected ? (correct ? Colors.green.withValues(alpha: .10) : Theme.of(context).colorScheme.errorContainer.withValues(alpha: .45)) : null, child: ListTile(onTap: onTap, leading: Icon(selected ? (correct ? Icons.check_circle_rounded : Icons.cancel_rounded) : Icons.radio_button_unchecked_rounded), title: Text(text), trailing: selected ? Icon(correct ? Icons.check_rounded : Icons.close_rounded) : null));
}
