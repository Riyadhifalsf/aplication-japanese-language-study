import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../culture/culture_screen.dart';
import '../grammar/grammar_screen.dart';
import '../kanji/kanji_detail_screen.dart';
import '../phrases/phrase_screen.dart';
import '../readings/reading_screen.dart';
import '../sentences/sentence_screen.dart';
import '../vocab/vocabulary_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  Timer? _timer;
  String _query = '';
  String _type = 'Semua';

  static const _types = [
    'Semua',
    'Kanji',
    'Kotoba',
    'Bunpou',
    'Frasa',
    'Kalimat',
    'Bacaan',
    'Budaya',
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final results = _buildResults(app, _query);
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Materi')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          TextField(
            controller: _search,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari: 山, yama, keluarga, ～たい, budaya...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _search.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final type in _types)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _type == type,
                      label: Text(type),
                      onSelected: (_) => setState(() => _type = type),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_query.isEmpty)
            _SearchHome(app: app)
          else if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: EmptyState(
                title: 'Tidak ketemu',
                message: 'Coba kata lain, romaji, arti Indonesia, atau kanji langsung.',
              ),
            )
          else ...[
            Text(
              '${results.length} hasil',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (final result in results) result,
          ],
        ],
      ),
    );
  }

  List<Widget> _buildResults(AppController app, String query) {
    if (query.isEmpty) return const [];
    final widgets = <Widget>[];
    bool allow(String type) => _type == 'Semua' || _type == type;

    if (allow('Kanji')) {
      final items = app.repository.kanji
          .where((item) => app.repository.kanjiSearchText(item.id).contains(query))
          .take(12);
      for (final item in items) {
        widgets.add(_ResultTile(
          color: AppTheme.seed,
          icon: Icons.translate_rounded,
          title: '${item.character} · ${item.meaning}',
          subtitle: '${item.level} · ${item.onyomi} · ${item.kunyomi}',
          onTap: () => _open(KanjiDetailScreen(initialId: item.id)),
        ));
      }
    }

    if (allow('Kotoba')) {
      final items = app.repository.vocabulary
          .where((item) => app.repository.vocabularySearchText(item.id).contains(query))
          .take(12);
      for (final item in items) {
        widgets.add(_ResultTile(
          color: const Color(0xFF3687FF),
          icon: Icons.menu_book_rounded,
          title: '${item.word} · ${item.meaning}',
          subtitle: '${item.reading} · ${item.level}',
          onTap: () => _open(const VocabularyScreen()),
        ));
      }
    }

    if (allow('Bunpou')) {
      final items = app.repository.grammar
          .where((item) => app.repository.grammarSearchText(item.id).contains(query))
          .take(10);
      for (final item in items) {
        widgets.add(_ResultTile(
          color: const Color(0xFFFF8A4C),
          icon: Icons.account_tree_rounded,
          title: item.pattern,
          subtitle: '${item.level} · ${item.title}',
          onTap: () => _open(const GrammarScreen()),
        ));
      }
    }

    if (allow('Frasa')) {
      final items = app.repository.phrases
          .where((item) => app.repository.phraseSearchText(item.id).contains(query))
          .take(10);
      for (final item in items) {
        widgets.add(_ResultTile(
          color: const Color(0xFFE64E64),
          icon: Icons.forum_rounded,
          title: item.japanese,
          subtitle: '${item.meaning} · ${item.politeness}',
          onTap: () => _open(const PhraseScreen()),
          onPlay: () => app.tts.speak(item.japanese),
        ));
      }
    }

    if (allow('Kalimat')) {
      final items = app.repository.sentences
          .where((item) => app.repository.sentenceSearchText(item.id).contains(query))
          .take(10);
      for (final item in items) {
        widgets.add(_ResultTile(
          color: const Color(0xFF00A6A6),
          icon: Icons.subject_rounded,
          title: item.japanese,
          subtitle: '${item.meaning} · ${item.pattern}',
          onTap: () => _open(const SentenceScreen()),
          onPlay: () => app.tts.speak(item.japanese),
        ));
      }
    }

    if (allow('Bacaan')) {
      final items = app.repository.readings
          .where((item) => app.repository.readingSearchText(item.id).contains(query))
          .take(8);
      for (final item in items) {
        widgets.add(_ResultTile(
          color: const Color(0xFF20A4F3),
          icon: Icons.auto_stories_rounded,
          title: item.title,
          subtitle: '${item.level} · ${item.category}',
          onTap: () => _open(ReadingScreen(initialLevel: item.level)),
          onPlay: () => app.tts.speak(item.japanese),
        ));
      }
    }

    if (allow('Budaya')) {
      final items = app.repository.culture
          .where((item) => app.repository.cultureSearchText(item.id).contains(query))
          .take(8);
      for (final item in items) {
        widgets.add(_ResultTile(
          color: const Color(0xFFEF6C00),
          icon: Icons.temple_buddhist_rounded,
          title: item.title,
          subtitle: '${item.category} · ${item.summary}',
          onTap: () => _open(const CultureScreen()),
        ));
      }
    }
    return widgets;
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _SearchHome extends StatelessWidget {
  const _SearchHome({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Card(
            color: AppTheme.seed.withValues(alpha: .1),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pencarian ini dibuat ringan: hasil muncul setelah kamu mengetik, lalu bisa difilter per jenis materi.',
                      style: TextStyle(fontWeight: FontWeight.w800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CountChip(label: 'Kanji', value: app.repository.kanji.length),
              _CountChip(label: 'Kotoba', value: app.repository.vocabulary.length),
              _CountChip(label: 'Bunpou', value: app.repository.grammar.length),
              _CountChip(label: 'Frasa', value: app.repository.phrases.length),
              _CountChip(label: 'Kalimat', value: app.repository.sentences.length),
              _CountChip(label: 'Bacaan', value: app.repository.readings.length),
            ],
          ),
        ],
      );
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text('$label · $value'),
        avatar: const Icon(Icons.check_circle_rounded, size: 18),
      );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onPlay,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Card(
          child: ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: .13),
              foregroundColor: color,
              child: Icon(icon),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: onPlay == null
                ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
                : IconButton(
                    onPressed: onPlay,
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
          ),
        ),
      );
}
