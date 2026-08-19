import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/vocabulary.dart';
import '../../services/morphology_service.dart';
import '../../services/vocabulary_examples_service.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mnemonic_visual.dart';

class VocabularyDetailScreen extends StatelessWidget {
  const VocabularyDetailScreen({required this.item, super.key});

  final Vocabulary item;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Kotoba'),
          actions: [
            IconButton(
              tooltip: 'Dengarkan',
              onPressed: () => app.tts.speak(item.reading),
              icon: const Icon(Icons.volume_up_rounded),
            ),
            IconButton(
              tooltip: 'Tandai dikuasai',
              onPressed: () => app.toggleMasteredVocabulary(item.id),
              icon: Icon(
                app.masteredVocabularyIds.contains(item.id)
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Ringkas'),
              Tab(text: '10 Kalimat'),
              Tab(text: 'Bentuk'),
              Tab(text: 'Partikel'),
              Tab(text: 'Kuis'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(item: item),
            _ExamplesTab(item: item),
            _FormsTab(item: item),
            _ParticleTab(item: item),
            _VocabQuiz(item: item),
          ],
        ),
      ),
    );
  }

}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.item});

  final Vocabulary item;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Center(
          child: FuriganaText(
            word: item.word,
            reading: item.reading,
            showReading: app.furiganaVisible,
            alignment: CrossAxisAlignment.center,
            wordStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
            readingStyle: const TextStyle(fontSize: 17),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            item.meaning,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: [
            JlptBadge(item.level),
            Chip(
              avatar: const Icon(Icons.category_rounded, size: 17),
              label: Text(item.inferredPartOfSpeech),
            ),
            Chip(
              avatar: const Icon(Icons.person_outline_rounded, size: 17),
              label: Text(item.genderLabel),
            ),
          ],
        ),
        const SizedBox(height: 18),
        MnemonicVisual(word: item.word, meaning: item.meaning),
        const SizedBox(height: 18),
        _InfoCard(
          title: 'Nuansa gender & maskulinitas',
          icon: Icons.person_rounded,
          child: Text(
            '${item.genderLabel}. Bahasa Jepang tidak mempunyai gender gramatikal seperti beberapa bahasa Eropa; label ini hanya menunjukkan kecenderungan penggunaan/register ketika memang relevan.',
            style: const TextStyle(height: 1.45),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}


class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamplesTab extends StatelessWidget {
  const _ExamplesTab({required this.item});
  final Vocabulary item;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final examples = VocabularyExamplesService.build(item);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      itemCount: examples.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '10 kalimat pendek · sengaja dibuat bertingkat agar satu kotoba bisa dipelajari bersama konteks partikel dan JLPT.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
            ),
          );
        }
        final e = examples[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => app.tts.speak(e.reading),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$index.', style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      )),
                      const Spacer(),
                      Chip(label: Text(e.particle == '—' ? 'tanpa partikel target' : 'partikel ${e.particle}')),
                      const SizedBox(width: 5),
                      JlptBadge(e.grammarLevel, compact: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(e.japanese, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(e.reading, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 6),
                  Text(e.meaning, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.volume_up_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FormsTab extends StatelessWidget {
  const _FormsTab({required this.item});
  final Vocabulary item;

  @override
  Widget build(BuildContext context) {
    final forms = MorphologyService.forms(item);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        Text(
          'Laboratorium perubahan bentuk',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          'Bentuk dibuat berdasarkan klasifikasi otomatis. Untuk kata yang tidak cukup jelas dari data kosakata, tandai sebagai kemungkinan dan verifikasi melalui konteks.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
        ),
        const SizedBox(height: 12),
        for (final f in forms)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(f.value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              subtitle: Text('${f.label} · ${f.note}'),
              trailing: IconButton(
                onPressed: () => AppScope.of(context).tts.speak(f.value.replaceAll(RegExp(r'[（）→]'), ' ')),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticleTab extends StatelessWidget {
  const _ParticleTab({required this.item});
  final Vocabulary item;

  @override
  Widget build(BuildContext context) {
    final examples = VocabularyExamplesService.build(item);
    final grouped = <String, VocabularyExample>{};
    for (final e in examples) {
      grouped.putIfAbsent(e.particle, () => e);
    }
    final order = ['は', 'が', 'を', 'に', 'で', 'と', 'も', 'から', 'まで', 'について', 'なら', 'でも'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        Text(
          'Kotoba × partikel',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          'Contoh dipetakan ke partikel/pola yang relevan dengan progres JLPT. Gunakan tombol suara untuk shadowing.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        for (final p in order)
          if (grouped.containsKey(p))
            _ParticleCard(example: grouped[p]!, particle: p),
      ],
    );
  }
}

class _ParticleCard extends StatelessWidget {
  const _ParticleCard({required this.example, required this.particle});
  final VocabularyExample example;
  final String particle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: () => app.tts.speak(example.reading),
        leading: CircleAvatar(child: Text(particle)),
        title: Text(example.japanese, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${example.meaning}\n${example.grammarLevel}'),
        isThreeLine: true,
        trailing: const Icon(Icons.volume_up_rounded),
      ),
    );
  }
}

class _VocabQuiz extends StatefulWidget {
  const _VocabQuiz({required this.item});
  final Vocabulary item;

  @override
  State<_VocabQuiz> createState() => _VocabQuizState();
}

class _VocabQuizState extends State<_VocabQuiz> {
  int _index = 0;
  int _correct = 0;
  bool _finished = false;
  final _questions = <_Question>[];

  bool _built = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    final app = AppScope.of(context);
    final rng = Random(widget.item.id);
    final forms = MorphologyService.forms(widget.item);
    if (forms.isEmpty) return;
    final masu = forms.firstWhere((f) => f.label == 'Masu', orElse: () => forms.first).value;
    final others = app.repository.vocabulary
        .where((v) => v.id != widget.item.id)
        .take(100)
        .toList()
      ..shuffle(rng);
    _questions.addAll([
      _Question('Apa arti ${widget.item.word}?', widget.item.meaning,
          others.take(3).map((v) => v.meaning).toList()),
      _Question('Bentuk masu yang benar?', masu,
          forms.where((f) => f.label != 'Masu').take(3).map((f) => f.value).toList()),
      _Question('Nuansa gender penggunaan?', widget.item.genderLabel,
          const ['Netral · tidak bergender', 'Maskulin · cenderung laki-laki', 'Feminin · cenderung perempuan']),
      _Question('Kotoba ini dibaca bagaimana?', widget.item.reading,
          others.skip(3).take(3).map((v) => v.reading).toList()),
      _Question('Partikel yang digunakan pada contoh “${VocabularyExamplesService.build(widget.item).first.japanese}”?',
          VocabularyExamplesService.build(widget.item).first.particle,
          const ['は', 'が', 'を']),
    ]);
    for (final q in _questions) {
      q.options = {...q.options, q.answer}.toList()..shuffle(rng);
    }
  }

  void _answer(String answer) {
    if (_finished) return;
    if (answer == _questions[_index].answer) _correct++;
    if (_index == _questions.length - 1) {
      setState(() => _finished = true);
      AppScope.of(context).recordQuiz(correct: _correct, total: _questions.length);
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: Text('Kuis belum siap untuk kotoba ini.'));
    }
    if (_finished) {
      final percent = (_correct / _questions.length * 100).round();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                percent >= 80 ? Icons.emoji_events_rounded : Icons.replay_rounded,
                size: 68,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text('$_correct/${_questions.length}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              Text('Akurasi $percent%'),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _index = 0;
                  _correct = 0;
                  _finished = false;
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Ulangi kuis'),
              ),
            ],
          ),
        ),
      );
    }
    final q = _questions[_index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        LinearProgressIndicator(value: (_index + 1) / _questions.length),
        const SizedBox(height: 18),
        Text('Soal ${_index + 1}/${_questions.length}',
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(q.prompt, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        for (final option in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () => _answer(option),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                alignment: Alignment.centerLeft,
              ),
              child: Text(option),
            ),
          ),
      ],
    );
  }
}

class _Question {
  _Question(this.prompt, this.answer, List<String> distractors)
      : options = distractors;

  final String prompt;
  final String answer;
  List<String> options;
}

class _PracticeNextCard extends StatelessWidget {
  const _PracticeNextCard({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => Card(color: Theme.of(context).colorScheme.primary.withValues(alpha: .06), child: const Padding(padding: EdgeInsets.all(16), child: Row(children: [CircleAvatar(child: Icon(Icons.route_rounded)), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Langkah berikutnya', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('Lanjutkan path, ulangi kata yang lemah, lalu ambil kuis penguasaan.', style: TextStyle(height: 1.4))]))])));
}
