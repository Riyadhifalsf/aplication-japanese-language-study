import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/grammar_point.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key, this.initialLevel = 'Semua'});

  final String initialLevel;

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final _search = TextEditingController();
  late String _level;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _search.addListener(_refresh);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final items = app.repository.grammar.where((item) {
      if (_level != 'Semua' && item.level != _level) return false;
      return query.isEmpty ||
          '${item.pattern} ${item.title} ${item.explanation}'
              .toLowerCase()
              .contains(query);
    }).toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Bunpou')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari pola atau penjelasan tata bahasa',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Row(
              children: [
                Text(
                  '${items.length} materi',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${app.completedGrammarIds.length} selesai',
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
                    title: 'Materi tidak ditemukan',
                    message: 'Ubah kata pencarian atau tingkat.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final completed =
                          app.completedGrammarIds.contains(item.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GrammarDetailScreen(item: item),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.seed.withValues(alpha: .12),
                              foregroundColor: AppTheme.seed,
                              child: Icon(
                                completed
                                    ? Icons.check_rounded
                                    : Icons.account_tree_rounded,
                              ),
                            ),
                            title: Text(
                              item.pattern,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: JlptBadge(item.level, compact: true),
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
}

class GrammarDetailScreen extends StatelessWidget {
  const GrammarDetailScreen({required this.item, super.key});

  final GrammarPoint item;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final completed = app.completedGrammarIds.contains(item.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(item.pattern),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: JlptBadge(item.level)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.pattern,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.seed,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.explanation,
                    style: const TextStyle(height: 1.65),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rumus',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.seed.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      item.formation,
                      style: const TextStyle(
                        color: AppTheme.seed,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            title: 'Contoh kalimat',
            subtitle: 'Tekan tombol suara untuk mendengar pelafalan Jepang.',
          ),
          const SizedBox(height: 12),
          for (final example in item.examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              example.japanese,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                app.tts.speak(example.japanese),
                            icon: const Icon(Icons.volume_up_rounded),
                          ),
                        ],
                      ),
                      if (app.furiganaVisible) ...[
                        const SizedBox(height: 3),
                        Text(
                          example.reading,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Divider(height: 22),
                      Text(example.meaning),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => app.toggleGrammarComplete(item.id),
            icon: Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.add_task_rounded,
            ),
            label: Text(
              completed ? 'Materi sudah selesai' : 'Tandai selesai',
            ),
          ),
        ],
      ),
    );
  }
}
