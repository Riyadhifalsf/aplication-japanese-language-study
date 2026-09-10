import 'package:flutter/material.dart';
import '../../services/study_intelligence_service.dart';
import '../../state/app_controller.dart';
import '../kanji/kanji_review_screen.dart';

class MistakeReviewScreen extends StatelessWidget {
  const MistakeReviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mistakes = (app.quizAnswered - app.quizCorrect).clamp(0, 1 << 31);
    final ai = StudyIntelligenceService.recommend(app);
    return Scaffold(appBar: AppBar(title: const Text('Ulasan & Kesalahan')), body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const CircleAvatar(radius: 27, child: Icon(Icons.rate_review_rounded)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Yang perlu diperbaiki', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('$mistakes jawaban salah dari ${app.quizAnswered} jawaban')]))]))),
      const SizedBox(height: 12),
      Card(child: ListTile(leading: const Icon(Icons.auto_awesome_rounded), title: const Text('AI Study Intelligence', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(ai.reason), trailing: Text('${(ai.risk * 100).round()}% risiko'))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Fokus berikutnya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(_action(ai.action), style: const TextStyle(height: 1.45)), const SizedBox(height: 14), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiReviewScreen())), icon: const Icon(Icons.refresh_rounded), label: const Text('Mulai review'))]))),
    ]));
  }
  String _action(String action) => switch (action) { 'review' => 'Prioritaskan kanji yang jatuh tempo sebelum membuka materi baru.', 'practice_weak_topics' => 'Kembali ke materi dan quiz topik yang sering salah.', 'continue_path' => 'Bangun konsistensi beberapa hari sebelum menaikkan beban materi.', _ => 'Progress stabil. Lanjutkan path dan pertahankan review.' };
}
