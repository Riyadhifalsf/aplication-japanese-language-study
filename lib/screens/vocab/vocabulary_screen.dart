import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
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
      setState(() {
        _query = _search.text.trim().toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = _filtered(app);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kotoba'),
        actions: [
          IconButton(
            tooltip: 'Hanya yang dikuasai',
            onPressed: () => setState(() => _masteredOnly = !_masteredOnly),
            icon: Icon(
              _masteredOnly
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari kosakata, bacaan, atau arti',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _search.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final level in ['Semua', 'N5', 'N4', 'N3', 'N2', 'N1'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _level == level,
                      label: Text(level == 'Semua' ? 'Semua' : level),
                      onSelected: (_) => setState(() => _level = level),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Row(
              children: [
                Text(
                  '${items.length} kosakata',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${app.masteredVocabularyIds.length} dikuasai',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    title: 'Kosakata tidak ditemukan',
                    message: 'Ubah pencarian atau pilihan tingkat.',
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                    itemCount: items.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _VocabularyTile(
                        item: items[index],
                        mastered: app.masteredVocabularyIds
                            .contains(items[index].id),
                        showReading: app.furiganaVisible,
                        onSpeak: () =>
                            app.tts.speak(items[index].reading),
                        onTap: () => _showDetails(context, items[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Vocabulary> _filtered(AppController app) {
    final source = _level == 'Semua'
        ? app.repository.vocabulary
        : app.repository.vocabularyForLevel(_level);
    return source.where((item) {
      if (_masteredOnly && !app.masteredVocabularyIds.contains(item.id)) {
        return false;
      }
      return _query.isEmpty ||
          app.repository.vocabularySearchText(item.id).contains(_query);
    }).toList(growable: false);
  }

  void _showDetails(BuildContext context, Vocabulary item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VocabularyDetailScreen(item: item),
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
  Widget build(BuildContext context) => Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: IconButton.filledTonal(
          onPressed: onSpeak,
          icon: const Icon(Icons.volume_up_rounded),
        ),
        title: FuriganaText(
          word: item.word,
          reading: item.reading,
          showReading: showReading,
          alignment: CrossAxisAlignment.start,
          wordStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          item.meaning,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            JlptBadge(item.level, compact: true),
            if (mastered) ...[
              const SizedBox(height: 4),
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.success,
              ),
            ],
          ],
        ),
      ),
    );
}
