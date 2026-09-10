import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/culture_item.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class CultureScreen extends StatefulWidget {
  const CultureScreen({super.key});

  @override
  State<CultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends State<CultureScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _category = 'Semua';
  String _query = '';

  @override
  void initState() {
    super.initState();
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
      ...app.repository.cultureCategories.toList()..sort(),
    ];
    final items = _filtered(app);
    return Scaffold(
      appBar: AppBar(title: const Text('Budaya Jepang')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari budaya, etika, kerja, makan, transportasi',
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
                  '${items.length} topik budaya',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${app.completedCultureIds.length} dibaca',
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
                    title: 'Topik tidak ditemukan',
                    message: 'Coba ubah kategori atau kata kunci.',
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
                        child: _CultureCard(
                          item: item,
                          completed: app.completedCultureIds.contains(item.id),
                          onOpen: () => _showDetail(context, app, item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<CultureItem> _filtered(AppController app) => app.repository.culture
      .where((item) {
        if (_category != 'Semua' && item.category != _category) return false;
        return _query.isEmpty ||
            app.repository.cultureSearchText(item.id).contains(_query);
      })
      .toList(growable: false);

  void _showDetail(BuildContext context, AppController app, CultureItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          minChildSize: .45,
          maxChildSize: .92,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.seed.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: AppTheme.seed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => app.toggleCultureComplete(item.id),
                    icon: Icon(
                      app.completedCultureIds.contains(item.id)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                item.summary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              Text(item.detail),
              const SizedBox(height: 16),
              Card(
                color: AppTheme.seed.withValues(alpha: .08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contoh',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(item.example),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tips cepat',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final tip in item.tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  app.toggleCultureComplete(item.id);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.done_rounded),
                label: const Text('Tandai sudah dibaca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CultureCard extends StatelessWidget {
  const _CultureCard({
    required this.item,
    required this.completed,
    required this.onOpen,
  });

  final CultureItem item;
  final bool completed;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE64E64).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.temple_buddhist_rounded, color: Color(0xFFE64E64)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (completed)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.category,
                        style: const TextStyle(
                          color: AppTheme.seed,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );
}
