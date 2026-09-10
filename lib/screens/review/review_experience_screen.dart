import 'package:flutter/material.dart';
import '../../state/app_controller.dart';
import '../vocab/vocabulary_screen.dart';
import '../grammar/grammar_screen.dart';

class ReviewExperienceScreen extends StatefulWidget {
  const ReviewExperienceScreen({super.key});
  @override
  State<ReviewExperienceScreen> createState() => _ReviewExperienceScreenState();
}

class _ReviewExperienceScreenState extends State<ReviewExperienceScreen> {
  int _tab = 0;
  int _filter = 0;

  static const _vocab = <_ReviewItem>[
    _ReviewItem('アメリカ', 'amerika', 'Amerika / AS', 'Sulit'),
    _ReviewItem('時間', 'じかん · jikan', 'waktu', 'Perlu diulang'),
    _ReviewItem('食べる', 'たべる · taberu', 'makan', 'Perlu diulang'),
    _ReviewItem('勉強', 'べんきょう · benkyou', 'belajar', 'Perlu diulang'),
  ];
  static const _grammar = <_ReviewItem>[
    _ReviewItem('です・ます', 'desu / masu', 'kalimat sopan dasar', 'Perlu diulang'),
    _ReviewItem('に', 'ni', 'waktu dan tujuan', 'Perlu diulang'),
    _ReviewItem('で', 'de', 'tempat berlangsungnya kegiatan', 'Perlu diulang'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final items = _tab == 0 ? _vocab : _grammar;
    final due = app.dueKanjiReviewCount;
    final title = _tab == 0 ? 'Ulasan Kosakata' : 'Ulasan Tata Bahasa';
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: cs.surface,
          titleSpacing: 20,
          title: Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          actions: [IconButton(tooltip: 'Cari', onPressed: () {}, icon: const Icon(Icons.search_rounded)), const SizedBox(width: 8)],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(55),
            child: Row(children: [
              Expanded(child: _TabButton(label: 'KOSAKATA', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
              Expanded(child: _TabButton(label: 'TATA BAHASA', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: _ReviewHero(due: due)),
        SliverToBoxAdapter(child: _FilterRow(selected: _filter, due: due, onChanged: (v) => setState(() => _filter = v))),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Row(children: [
            const Expanded(child: Text('Materi yang perlu diperkuat', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
            if (due > 0) Text('$due siap', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text('Mulai dari item yang paling lemah. Review ulang segera setelah salah, lalu beri jeda lebih panjang saat jawabanmu sudah konsisten.', style: TextStyle(color: cs.onSurfaceVariant, height: 1.35)),
        )),
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 10), child: _ReviewRow(item: items[index], tab: _tab, index: index)),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _tab == 0 ? const VocabularyScreen() : const GrammarScreen())),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_tab == 0 ? 'Mulai ulasan kosakata' : 'Mulai ulasan tata bahasa'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          ),
        )),
      ]),
    );
  }
}

class _ReviewHero extends StatelessWidget {
  const _ReviewHero({required this.due});
  final int due;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(17)), child: Icon(Icons.replay_rounded, color: cs.onPrimary, size: 29)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(due > 0 ? '$due item siap diulas' : 'Tidak ada review yang mendesak', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(due > 0 ? 'Fokus pada kesalahan terbaru agar tidak cepat lupa.' : 'Tetap latihan untuk menjaga materi tetap aktif.', style: TextStyle(color: cs.onSurfaceVariant, height: 1.25)),
          ])),
        ]),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(onTap: onTap, child: Container(height: 55, alignment: Alignment.center, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? cs.primary : Colors.transparent, width: 3))), child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? cs.primary : cs.onSurface))));
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.due, required this.onChanged});
  final int selected;
  final int due;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filters = [('Perlu diulang', due, Icons.refresh_rounded), ('Sedang dikuatkan', 0, Icons.trending_up_rounded), ('Sudah kuat', 0, Icons.check_circle_outline_rounded)];
    return SizedBox(height: 126, child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8), scrollDirection: Axis.horizontal, itemCount: filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final f = filters[index];
        final active = selected == index;
        return InkWell(
          borderRadius: BorderRadius.circular(18), onTap: () => onChanged(index),
          child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 166, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: active ? cs.primaryContainer : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? cs.primary : Colors.transparent, width: 1.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(f.$3, size: 19, color: active ? cs.primary : cs.onSurfaceVariant), const Spacer(), Text('${f.$2}', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: active ? cs.primary : cs.onSurface))]),
            const Spacer(), Text(f.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
          ])),
        );
      },
    ));
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.item, required this.tab, required this.index});
  final _ReviewItem item;
  final int tab;
  final int index;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.outlineVariant.withValues(alpha: .45))),
      child: Row(children: [
        Container(width: 58, height: 58, alignment: Alignment.center, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(15)), child: Icon(tab == 0 ? Icons.translate_rounded : Icons.auto_awesome_rounded, color: cs.primary, size: 27)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(item.main, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), const SizedBox(width: 6), _StatusChip(label: item.status)]),
          const SizedBox(height: 4), Text(item.reading, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2), Text(item.meaning, style: TextStyle(color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(width: 6), Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)));
  }
}

class _ReviewItem {
  const _ReviewItem(this.main, this.reading, this.meaning, this.status);
  final String main;
  final String reading;
  final String meaning;
  final String status;
}
