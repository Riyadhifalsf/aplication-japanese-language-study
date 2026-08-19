import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../kanji/kanji_library_screen.dart';
import '../quiz/quiz_setup_screen.dart';
import '../vocab/vocabulary_quiz_screen.dart';

class StudyModesScreen extends StatelessWidget {
  const StudyModesScreen({super.key});

  static const modes = [
    (
      'Seimbang',
      'Campuran kotoba, kanji, grammar, dan review.',
      Icons.auto_awesome_rounded
    ),
    (
      'Cepat 10 menit',
      'Satu sesi kecil untuk menjaga streak.',
      Icons.bolt_rounded
    ),
    (
      'Fokus 30 menit',
      'Sesi lengkap dengan latihan dan review.',
      Icons.timer_rounded
    ),
    (
      'Kanji',
      'Fokus membaca, arti, dan pengenalan kanji.',
      Icons.translate_rounded
    ),
    ('Kotoba', 'Perbanyak kosakata dan recall cepat.', Icons.menu_book_rounded),
    (
      'Ujian',
      'Latihan soal berdasarkan target JLPT/JFT.',
      Icons.fact_check_rounded
    ),
    (
      'Listening',
      'Prioritaskan pemahaman audio dan TTS.',
      Icons.headphones_rounded
    ),
    (
      'Kerja Jepang',
      'Situasi komunikasi praktis untuk kerja.',
      Icons.work_rounded
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mode Belajar')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      const Icon(Icons.tune_rounded, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('Mode aktif: ${app.learningMode}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)))
                    ]))),
            const SizedBox(height: 12),
            for (final mode in modes)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(mode.$3)),
                  title: Text(mode.$1,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(mode.$2),
                  trailing: app.learningMode == mode.$1
                      ? const Icon(Icons.check_circle_rounded)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    app.setLearningMode(mode.$1);
                    if (mode.$1 == 'Kanji') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KanjiLibraryScreen()));
                    } else if (mode.$1 == 'Kotoba') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VocabularyQuizScreen()));
                    } else if (mode.$1 == 'Ujian') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QuizSetupScreen()));
                    }
                  },
                ),
              ),
          ]),
    );
  }
}
