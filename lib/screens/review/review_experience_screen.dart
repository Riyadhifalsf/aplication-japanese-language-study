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
    _ReviewItem('アメリカ', 'Amerika', 'Amerika / AS'),
    _ReviewItem('時間', 'じかん · jikan', 'waktu'),
    _ReviewItem('食べる', 'たべる · taberu', 'makan'),
    _ReviewItem('勉強', 'べんきょう · benkyou', 'belajar'),
  ];

  static const _grammar = <_ReviewItem>[
    _ReviewItem('です・ます', 'desu / masu', 'kalimat sopan dasar'),
    _ReviewItem('に', 'ni', 'waktu dan tujuan'),
    _ReviewItem('で', 'de', 'tempat berlangsungnya kegiatan'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = _tab == 0 ? _vocab : _grammar;
    final title = _tab == 0 ? 'Kosakata' : 'Tata bahasa';
    final due = app.dueKanjiReviewCount;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            titleSpacing: 20,
            title: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            actions: [
              IconButton(tooltip: 'Cari', onPressed: () {}, icon: const Icon(Icons.search_rounded)),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(55),
              child: Row(
                children: [
                  Expanded(child: _TabButton(label: 'KOSAKATA', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
                  Expanded(child: _TabButton(label: 'TATA BAHASA', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _PremiumBanner()),
          SliverToBoxAdapter(child: _FilterRow(selected: _filter, onChanged: (value) => setState(() => _filter = value))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Yang perlu kamu ulas', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
                  if (due > 0) Text('$due tersedia', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Text(
                _tab == 0 ? 'Ulangi kata sesuai tingkat ingatanmu agar lebih cepat menempel.' : 'Perkuat pola yang masih sering tertukar lewat contoh singkat.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: _ReviewRow(item: items[index], tab: _tab),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _tab == 0 ? const VocabularyScreen() : const GrammarScreen())),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(_tab == 0 ? 'Ulas sekarang' : 'Praktik tata bahasa'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? cs.primary : Colors.transparent, width: 3)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? cs.primary : cs.onSurface)),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF4C2BAA), Color(0xFF24155E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 22), SizedBox(width: 6), Text('Premium Plus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19))]),
                  SizedBox(height: 12),
                  Text('Praktik kapan saja dengan Premium!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
                  SizedBox(height: 7),
                  Text('Nikmati akses ulasan tanpa batas dan bangun keterampilan pentingmu.', style: TextStyle(color: Colors.white, height: 1.35)),
                  SizedBox(height: 9),
                  Text('Ketuk di sini untuk mendapatkan akses tanpa batas.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ]),
              ),
              SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: Colors.white, size: 34),
            ],
          ),
        ),
      );
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Sulit', 'Sedang', 'Kuat'];
    const counts = [144, 0, 0];
    return SizedBox(
      height: 174,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(index),
          child: SizedBox(
            width: 154,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: 112,
                width: 154,
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
                decoration: BoxDecoration(
                  color: index == 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: selected == index ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                ),
                child: Text(
                  '${counts[index]}',
                  style: TextStyle(color: index == 0 ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onSurface, fontSize: 34, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              Text(labels[index], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.item, required this.tab});
  final _ReviewItem item;
  final int tab;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(tab == 0 ? '語' : '文', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.main, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Row(children: [Text(item.reading, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(width: 6), Icon(tab == 0 ? Icons.volume_up_rounded : Icons.auto_awesome_rounded, size: 17, color: Theme.of(context).colorScheme.onSurfaceVariant)]),
                const SizedBox(height: 2),
                Text(item.meaning, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
            Icon(Icons.bar_chart_rounded, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      );
}

class _ReviewItem {
  const _ReviewItem(this.main, this.reading, this.meaning);
  final String main;
  final String reading;
  final String meaning;
}
