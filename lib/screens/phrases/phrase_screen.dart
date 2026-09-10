import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/phrase_item.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class PhraseScreen extends StatefulWidget {
  const PhraseScreen({super.key, this.initialCategory = 'Semua'});

  final String initialCategory;

  @override
  State<PhraseScreen> createState() => _PhraseScreenState();
}

class _PhraseScreenState extends State<PhraseScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  late String _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
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
      ...app.repository.phraseCategories.toList()..sort(),
    ];
    final items = _filtered(app);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frasa Jepang'),
        actions: [
          IconButton(
            tooltip: 'Putar frasa pertama',
            onPressed: items.isEmpty ? null : () => app.tts.speak(items.first.reading),
            icon: const Icon(Icons.volume_up_rounded),
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
                hintText: 'Cari frasa, arti, situasi, atau bacaan',
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
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
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
                  '${items.length} frasa',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${app.completedPhraseIds.length} ditandai',
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
                    title: 'Frasa tidak ditemukan',
                    message: 'Coba ubah kategori atau kata kunci.',
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(item.id),
                        duration: Duration(milliseconds: 220 + index.clamp(0, 4).toInt() * 45),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PhraseCard(
                            item: item,
                            completed: app.completedPhraseIds.contains(item.id),
                            onSpeak: () => app.tts.speak(item.reading),
                            onToggle: () => app.togglePhraseComplete(item.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<PhraseItem> _filtered(AppController app) => app.repository.phrases
      .where((item) {
        if (_category != 'Semua' && item.category != _category) return false;
        return _query.isEmpty ||
            app.repository.phraseSearchText(item.id).contains(_query);
      })
      .toList(growable: false);
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    required this.item,
    required this.completed,
    required this.onSpeak,
    required this.onToggle,
  });

  final PhraseItem item;
  final bool completed;
  final VoidCallback onSpeak;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.seed.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: AppTheme.seed),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.japanese,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: .11),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            item.politeness,
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.reading,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.meaning,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.note,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.volume_up_rounded, size: 18),
                          label: const Text('Dengar'),
                          onPressed: onSpeak,
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: Icon(
                            completed
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                          ),
                          label: Text(completed ? 'Sudah' : 'Tandai'),
                          onPressed: onToggle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
