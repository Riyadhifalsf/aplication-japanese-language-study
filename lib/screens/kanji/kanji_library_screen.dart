import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import 'kanji_detail_screen.dart';
import 'kanji_mastery_quiz_screen.dart';
import 'kanji_review_screen.dart';

class KanjiLibraryScreen extends StatefulWidget {
  const KanjiLibraryScreen({
    super.key,
    this.initialLevel = 'Semua',
  });

  final String initialLevel;

  @override
  State<KanjiLibraryScreen> createState() => _KanjiLibraryScreenState();
}

class _KanjiLibraryScreenState extends State<KanjiLibraryScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  late String _level;
  String _theme = 'Semua';
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = _filtered(app);
    final themes = app.repository.themes.toList()..sort();
    final quizLevel = _level == 'Semua' ? 'N5' : _level;
    final masteredInFilter = items
        .where((item) => app.isKanjiMastered(item.id))
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanji JLPT'),
        actions: [
          IconButton(
            tooltip: 'Kanji favorit',
            onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
            icon: Icon(
              _favoritesOnly
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari kanji, arti, bacaan, atau tema',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final level in [
                      'Semua',
                      'N5',
                      'N4',
                      'N3',
                      'N2',
                      'N1',
                    ])
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 8),
            sliver: SliverToBoxAdapter(
              child: DropdownButtonFormField<String>(
                initialValue: _theme,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  labelText: 'Kelompok tema',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'Semua',
                    child: Text('Semua tema'),
                  ),
                  ...themes.map(
                    (theme) => DropdownMenuItem(
                      value: theme,
                      child: Text(theme, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _theme = value ?? 'Semua'),
              ),
            ),
          ),
          if (app.dueKanjiReviewCount > 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Card(
                  color:
                      const Color(0xFFFFA62B).withValues(alpha: .13),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KanjiReviewScreen(),
                      ),
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFA62B),
                      foregroundColor: Colors.white,
                      child: Icon(Icons.notifications_active_rounded),
                    ),
                    title: Text(
                      '${app.dueKanjiReviewCount} kanji perlu diulang',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Ulangi sekarang agar hafalan tetap kuat.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: .45),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => _openMasteryQuiz(quizLevel),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF173B34),
                      foregroundColor: Colors.white,
                      child: Icon(Icons.verified_rounded),
                    ),
                    title: Text(
                      'Latihan Kanji $quizLevel',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Kuasai kanji dengan 3 jawaban benar berturut-turut.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    '${items.length} kanji',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    '$masteredInFilter dikuasai',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                title: 'Kanji tidak ditemukan',
                message: 'Ubah kata pencarian, tingkat, atau tema.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _KanjiTile(
                    item: items[index],
                    learned: app.learnedKanjiIds.contains(items[index].id),
                    mastered: app.isKanjiMastered(items[index].id),
                    reviewDue: app.isKanjiReviewDue(items[index].id),
                    masteryStreak:
                        app.kanjiMasteryStreak(items[index].id),
                    favorite: app.favoriteKanjiIds.contains(items[index].id),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KanjiDetailScreen(
                          initialId: items[index].id,
                          sourceIds:
                              items.map((item) => item.id).toList(growable: false),
                        ),
                      ),
                    ),
                  ),
                  childCount: items.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns(MediaQuery.sizeOf(context).width),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .92,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMasteryQuiz(quizLevel),
        icon: const Icon(Icons.psychology_alt_rounded),
        label: Text('Latihan $quizLevel'),
      ),
    );
  }

  void _openMasteryQuiz(String level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KanjiMasteryQuizScreen(level: level),
      ),
    );
  }

  List<Kanji> _filtered(AppController app) {
    final source = _level == 'Semua'
        ? app.repository.kanji
        : app.repository.kanjiForLevel(_level);
    return source.where((item) {
      if (_theme != 'Semua' && !item.themes.contains(_theme)) return false;
      if (_favoritesOnly && !app.favoriteKanjiIds.contains(item.id)) {
        return false;
      }
      return _query.isEmpty ||
          app.repository.kanjiSearchText(item.id).contains(_query);
    }).toList(growable: false);
  }

  int _columns(double width) {
    if (width >= 900) return 9;
    if (width >= 650) return 7;
    if (width >= 460) return 5;
    return 4;
  }
}

class _KanjiTile extends StatelessWidget {
  const _KanjiTile({
    required this.item,
    required this.learned,
    required this.mastered,
    required this.reviewDue,
    required this.masteryStreak,
    required this.favorite,
    required this.onTap,
  });

  final Kanji item;
  final bool learned;
  final bool mastered;
  final bool reviewDue;
  final int masteryStreak;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress =
        masteryStreak / AppController.kanjiMasteryThreshold;
    final background = mastered
        ? const Color(0xFF173B34)
        : masteryStreak > 0
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: .58)
            : null;
    final foreground =
        mastered ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Card(
      color: background,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.character,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 38,
                      height: 1,
                      fontWeight:
                          mastered ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (mastered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        item.level,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    JlptBadge(item.level, compact: true),
                ],
              ),
            ),
            if (mastered)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF74E0B8),
                  size: 18,
                ),
              )
            else if (learned)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF17A673),
                  size: 17,
                ),
              )
            else if (favorite)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE64E64),
                  size: 16,
                ),
              ),
            if (reviewDue)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFFFB23F),
                  size: 18,
                ),
              ),
            if (!mastered && masteryStreak > 0)
              Positioned(
                left: 8,
                right: 8,
                bottom: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: .7),
                    color: const Color(0xFF17A673),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
