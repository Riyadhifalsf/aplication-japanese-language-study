import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kanji.dart';
import '../../models/vocabulary.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import 'flashcard_screen.dart';
import 'kanji_quiz_screen.dart';

class KanjiDetailScreen extends StatefulWidget {
  const KanjiDetailScreen({
    required this.initialId,
    super.key,
    this.sourceIds,
  });

  final int initialId;
  final List<int>? sourceIds;

  @override
  State<KanjiDetailScreen> createState() => _KanjiDetailScreenState();
}

class _KanjiDetailScreenState extends State<KanjiDetailScreen> {
  late List<int> _ids;
  late int _index;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final app = AppScope.of(context);
    _ids = widget.sourceIds ?? app.repository.kanji.map((e) => e.id).toList();
    _index = _ids.indexOf(widget.initialId);
    if (_index < 0) _index = 0;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final item = app.repository.kanjiById(_ids[_index])!;
    final directWords = app.repository.directVocabulary(item);
    final studyWords = app.repository.studyVocabulary(item);
    final related = app.repository.relatedKanji(item);
    final learned = app.learnedKanjiIds.contains(item.id);
    final favorite = app.favoriteKanjiIds.contains(item.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${item.level} · ${_index + 1}/${_ids.length}'),
        actions: [
          IconButton(
            tooltip: favorite ? 'Hapus favorit' : 'Tambah favorit',
            onPressed: () => app.toggleFavoriteKanji(item.id),
            icon: Icon(
              favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: favorite ? const Color(0xFFE64E64) : null,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          _HeroCard(
            item: item,
            learned: learned,
            onSound: () => app.tts.speak(item.preferredReading),
            onLearned: () => app.toggleLearnedKanji(item.id),
          ),
          const SizedBox(height: 14),
          _InformationCard(item: item),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: studyWords.isEmpty
                      ? null
                      : () => _open(
                            FlashcardScreen(
                              kanji: item,
                              items: studyWords,
                            ),
                          ),
                  icon: const Icon(Icons.style_rounded),
                  label: const Text('Kartu hafalan'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: studyWords.length < 2
                      ? null
                      : () => _open(
                            KanjiQuizScreen(
                              kanji: item,
                              items: studyWords,
                            ),
                          ),
                  icon: const Icon(Icons.quiz_rounded),
                  label: const Text('Kuis'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          SectionTitle(
            title: 'Kosakata terkait',
            subtitle: '${directWords.length} kosakata langsung',
          ),
          const SizedBox(height: 12),
          if (directWords.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Kosakata untuk kanji ini belum dipetakan. Metadata tingkat lanjut tetap tersedia sebagai indeks belajar.',
                ),
              ),
            )
          else
            ...directWords.map(
              (word) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _VocabularyRow(word: word),
              ),
            ),
          const SizedBox(height: 17),
          const SectionTitle(
            title: 'Kanji terkait',
            subtitle: 'Berdasarkan tema dan kelompok yang sama.',
          ),
          const SizedBox(height: 12),
          if (related.isEmpty)
            const Text('Belum ada kanji terkait.')
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: related
                  .map(
                    (relatedItem) => ActionChip(
                      avatar: Text(
                        relatedItem.character,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      label: Text(relatedItem.level),
                      onPressed: () {
                        setState(() {
                          final found = _ids.indexOf(relatedItem.id);
                          if (found >= 0) {
                            _index = found;
                          } else {
                            _ids = [..._ids, relatedItem.id];
                            _index = _ids.length - 1;
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Sebelumnya'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Berikutnya'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _move(int delta) => setState(() {
        _index = (_index + delta) % _ids.length;
        if (_index < 0) _index = _ids.length - 1;
      });

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.item,
    required this.learned,
    required this.onSound,
    required this.onLearned,
  });

  final Kanji item;
  final bool learned;
  final VoidCallback onSound;
  final VoidCallback onLearned;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: AppTheme.seed.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.seed.withValues(alpha: .16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.character,
                    style: const TextStyle(
                      fontSize: 104,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final app = AppScope.of(context);
                final reading = app.adaptiveReading(reading: item.preferredReading, level: item.level);
                return reading.isEmpty ? const SizedBox.shrink() : Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(reading, style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                );
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  JlptBadge(item.level),
                  const SizedBox(width: 8),
                  Text(
                    item.strokes > 0
                        ? '${item.strokes} goresan'
                        : 'Goresan belum dipetakan',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.meaning.isEmpty ? 'Belum dipetakan' : item.meaning,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onSound,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Dengarkan'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onLearned,
                    icon: Icon(
                      learned
                          ? Icons.check_circle_rounded
                          : Icons.add_task_rounded,
                    ),
                    label: Text(learned ? 'Dipelajari' : 'Tandai'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.item});

  final Kanji item;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _FactRow(
                label: 'Kun’yomi',
                value: item.kunyomi.isEmpty ? '—' : item.kunyomi,
              ),
              const Divider(height: 25),
              _FactRow(
                label: 'On’yomi',
                value: item.onyomi.isEmpty ? '—' : item.onyomi,
              ),
              if (item.themes.isNotEmpty) ...[
                const Divider(height: 25),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: item.themes
                        .map((theme) => Chip(label: Text(theme)))
                        .toList(growable: false),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
}

class _VocabularyRow extends StatelessWidget {
  const _VocabularyRow({required this.word});

  final Vocabulary word;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mastered = app.masteredVocabularyIds.contains(word.id);
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: IconButton.filledTonal(
          tooltip: 'Putar suara',
          onPressed: () => app.tts.speak(word.reading),
          icon: const Icon(Icons.volume_up_rounded),
        ),
        title: FuriganaText(
          word: word.word,
          reading: word.reading,
          showReading: app.furiganaVisible,
          alignment: CrossAxisAlignment.start,
          wordStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(word.meaning),
        trailing: IconButton(
          tooltip: mastered ? 'Sudah dikuasai' : 'Tandai dikuasai',
          onPressed: () => app.toggleMasteredVocabulary(word.id),
          icon: Icon(
            mastered
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: mastered ? AppTheme.success : null,
          ),
        ),
      ),
    );
  }
}
