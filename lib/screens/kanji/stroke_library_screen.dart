import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import 'stroke_order_screen.dart';

class StrokeLibraryScreen extends StatefulWidget {
  const StrokeLibraryScreen({super.key});

  @override
  State<StrokeLibraryScreen> createState() => _StrokeLibraryScreenState();
}

class _StrokeLibraryScreenState extends State<StrokeLibraryScreen> {
  final _search = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  String _level = 'Semua';

  @override
  void initState() {
    super.initState();
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
    final source = _level == 'Semua'
        ? app.repository.kanji
        : app.repository.kanjiForLevel(_level);
    final items = source.where((item) {
      return _query.isEmpty ||
          app.repository.kanjiSearchText(item.id).contains(_query);
    }).toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Urutan Goresan')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Cari kanji untuk latihan menulis',
                  prefixIcon: const Icon(Icons.gesture_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${items.length} kanji · pilih untuk memutar animasi',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                title: 'Tidak ditemukan',
                message: 'Coba kata pencarian atau tingkat lain.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _StrokeTile(
                    item: items[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StrokeOrderScreen(item: items[index]),
                      ),
                    ),
                  ),
                  childCount: items.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 600 ? 7 : 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StrokeTile extends StatelessWidget {
  const _StrokeTile({required this.item, required this.onTap});

  final Kanji item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
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
                      style: const TextStyle(
                        fontSize: 39,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    JlptBadge(item.level, compact: true),
                  ],
                ),
              ),
              const Positioned(
                top: 7,
                right: 7,
                child: Icon(Icons.gesture_rounded, size: 15),
              ),
            ],
          ),
        ),
      );
}
