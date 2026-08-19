import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/sentence_item.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class SentenceScreen extends StatefulWidget {
  const SentenceScreen({super.key, this.initialLevel = 'Semua'});

  final String initialLevel;

  @override
  State<SentenceScreen> createState() => _SentenceScreenState();
}

class _SentenceScreenState extends State<SentenceScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  late String _level;
  String _category = 'Semua';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _search.addListener(_refresh);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final categories = [
      'Semua',
      ...app.repository.sentenceCategories.toList()..sort(),
    ];
    final items = _filtered(app);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalimat Jepang'),
        actions: [
          IconButton(
            tooltip: 'Dengarkan kalimat pertama',
            onPressed: items.isEmpty ? null : () => app.tts.speak(items.first.reading),
            icon: const Icon(Icons.record_voice_over_rounded),
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
                hintText: 'Cari kalimat, pola, arti, atau kategori',
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
                for (final level in ['Semua', 'N5', 'N4'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _level == level,
                      label: Text(level),
                      onSelected: (_) => setState(() => _level = level),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _category == category,
                      label: Text(category),
                      onSelected: (_) => setState(() => _category = category),
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
                  '${items.length} kalimat',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${app.completedSentenceIds.length} ditandai',
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
                    title: 'Kalimat tidak ditemukan',
                    message: 'Coba ubah tingkat atau kategori.',
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SentenceCard(
                          item: item,
                          completed: app.completedSentenceIds.contains(item.id),
                          showReading: app.furiganaVisible,
                          onSpeak: () => app.tts.speak(item.reading),
                          onToggle: () => app.toggleSentenceComplete(item.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<SentenceItem> _filtered(AppController app) => app.repository.sentences
      .where((item) {
        if (_level != 'Semua' && item.level != _level) return false;
        if (_category != 'Semua' && item.category != _category) return false;
        return _query.isEmpty ||
            app.repository.sentenceSearchText(item.id).contains(_query);
      })
      .toList(growable: false);
}

class _SentenceCard extends StatelessWidget {
  const _SentenceCard({
    required this.item,
    required this.completed,
    required this.showReading,
    required this.onSpeak,
    required this.onToggle,
  });

  final SentenceItem item;
  final bool completed;
  final bool showReading;
  final VoidCallback onSpeak;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  JlptBadge(item.level, compact: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.category,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dengarkan',
                    onPressed: onSpeak,
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FuriganaText(
                word: item.japanese,
                reading: item.reading,
                showReading: showReading,
                alignment: CrossAxisAlignment.start,
                wordStyle: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
                readingStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.meaning,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.seed.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.pattern,
                      style: const TextStyle(
                        color: AppTheme.seed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.note,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : Icons.add_task_rounded,
                  ),
                  label: Text(completed ? 'Sudah dipahami' : 'Tandai paham'),
                ),
              ),
            ],
          ),
        ),
      );
}
