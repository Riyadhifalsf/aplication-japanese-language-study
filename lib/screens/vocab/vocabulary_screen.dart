import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../models/vocabulary.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import 'vocabulary_detail_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key, this.initialLevel = 'Semua'});

  final String initialLevel;

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final _search = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  late String _level;
  String? _chapter;
  bool _masteredOnly = false;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _search.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  List<CurriculumUnit> _mappedUnits() => CurriculumCatalogData.mappedUnits(_level);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final chapters = _mappedUnits();
    Set<int>? chapterIds;
    if (_chapter != null) {
      for (final unit in chapters) {
        if (unit.id == _chapter) {
          chapterIds = CurriculumCatalogData.vocabIdsOfUnit(unit);
          break;
        }
      }
    }
    final items = _filtered(app, chapterIds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kosakata'),
        actions: [
          IconButton(
            tooltip: 'Hanya yang dikuasai',
            onPressed: () => setState(() => _masteredOnly = !_masteredOnly),
            icon: Icon(_masteredOnly ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari kata, bacaan, atau arti',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(onPressed: _search.clear, icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              _QuickAction(icon: Icons.style_rounded, label: 'Flashcard'),
              const SizedBox(width: 8),
              _QuickAction(icon: Icons.favorite_border_rounded, label: 'Favorit'),
              const SizedBox(width: 8),
              _QuickAction(icon: Icons.filter_list_rounded, label: 'Filter'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              _MetricChip(value: '${items.length}', label: 'Tersedia'),
              const SizedBox(width: 8),
              _MetricChip(value: '${app.masteredVocabularyIds.length}', label: 'Dikuasai'),
              const SizedBox(width: 8),
              _MetricChip(value: _level == 'Semua' ? 'N5–N1' : _level, label: 'Level'),
            ]),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final level in const ['Semua', 'N5', 'N4', 'N3', 'N2', 'N1'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _level == level,
                      label: Text(level),
                      onSelected: (_) => setState(() {
                        _level = level;
                        _chapter = null;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          if (chapters.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _chapter == null,
                      label: const Text('Semua Bab'),
                      onSelected: (_) => setState(() => _chapter = null),
                    ),
                  ),
                  for (final unit in chapters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: _chapter == unit.id,
                        label: Text('Bab ${unit.sequence}'),
                        onSelected: (_) => setState(() => _chapter = _chapter == unit.id ? null : unit.id),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Row(children: [
              Text('${items.length} kosakata', style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${app.masteredVocabularyIds.length} dikuasai', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(title: 'Kosakata tidak ditemukan', message: 'Ubah pencarian atau pilihan tingkat.')
                : ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    itemCount: items.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _VocabularyTile(
                        item: items[index],
                        mastered: app.masteredVocabularyIds.contains(items[index].id),
                        showReading: app.furiganaVisible,
                        onSpeak: () => app.tts.speak(items[index].reading),
                        onTap: () => _showDetails(context, items[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Vocabulary> _filtered(AppController app, [Set<int>? chapterIds]) {
    final source = _level == 'Semua' ? app.repository.vocabulary : app.repository.vocabularyForLevel(_level);
    return source.where((item) {
      if (chapterIds != null && !chapterIds.contains(item.id)) return false;
      if (_masteredOnly && !app.masteredVocabularyIds.contains(item.id)) return false;
      return _query.isEmpty || app.repository.vocabularySearchText(item.id).contains(_query);
    }).toList(growable: false);
  }

  void _showDetails(BuildContext context, Vocabulary item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VocabularyDetailScreen(item: item)));
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _VocabularyTile extends StatelessWidget {
  const _VocabularyTile({
    required this.item,
    required this.mastered,
    required this.showReading,
    required this.onSpeak,
    required this.onTap,
  });

  final Vocabulary item;
  final bool mastered;
  final bool showReading;
  final VoidCallback onSpeak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          child: Row(children: [
            IconButton.filledTonal(onPressed: onSpeak, icon: const Icon(Icons.volume_up_rounded)),
            const SizedBox(width: 4),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: FuriganaText(word: item.word, reading: item.reading, showReading: showReading, alignment: CrossAxisAlignment.start, wordStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
                if (mastered) Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
              ]),
              const SizedBox(height: 4),
              Text(item.meaning, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant)),
            ])),
            const SizedBox(width: 10),
            JlptBadge(item.level, compact: true),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}
