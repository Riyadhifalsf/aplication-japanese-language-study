import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/reading_item.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, this.initialLevel = 'Semua'});

  final String initialLevel;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late String _level;
  String _category = 'Semua';

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final allItems = <ReadingItem>[
      ..._fullStories,
      ...app.repository.readings.take(80),
    ];
    final categories = allItems.map((e) => e.category).toSet().toList()..sort();
    final items = allItems.where((item) {
      final levelOk = _level == 'Semua' || item.level == _level;
      final categoryOk = _category == 'Semua' || item.category == _category;
      return levelOk && categoryOk;
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Cerita Jepang')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            sliver: SliverToBoxAdapter(child: _BookIntro(total: allItems.length)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            sliver: SliverToBoxAdapter(
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.local_library_rounded),
                  labelText: 'Jenis bacaan',
                ),
                items: [
                  const DropdownMenuItem(value: 'Semua', child: Text('Semua bacaan')),
                  ...categories.map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _category = value ?? 'Semua'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${items.length} bacaan',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                title: 'Belum ada bacaan',
                message: 'Coba tingkat atau kategori lain.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReadingCard(
                    item: items[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReadingBookScreen(
                          readings: items,
                          initialIndex: index,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookIntro extends StatelessWidget {
  const _BookIntro({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF315C7E), Color(0xFF7B5C45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              child: Icon(Icons.auto_stories_rounded, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('長い読み物', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  const Text('Cerita Utuh', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('$total bacaan. Ada alat suara, furigana, terjemahan, dan pencarian kata.', style: const TextStyle(color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.item, required this.onTap});

  final ReadingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.seed.withValues(alpha: .18),
                        const Color(0xFFB57B4E).withValues(alpha: .16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    item.id.startsWith('long_') ? Icons.menu_book_rounded : Icons.article_rounded,
                    color: AppTheme.seed,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          JlptBadge(item.level, compact: true),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(item.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(item.meaning, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      );
}

class ReadingBookScreen extends StatefulWidget {
  const ReadingBookScreen({
    required this.readings,
    required this.initialIndex,
    super.key,
  });

  final List<ReadingItem> readings;
  final int initialIndex;

  @override
  State<ReadingBookScreen> createState() => _ReadingBookScreenState();
}

class _ReadingBookScreenState extends State<ReadingBookScreen> {
  late final PageController _controller;
  late int _index;
  bool _showReading = false;
  bool _showMeaning = false;
  double _fontSize = 24;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final item = widget.readings[_index];
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECDB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF315C7E),
        foregroundColor: Colors.white,
        title: Text('${_index + 1}/${widget.readings.length}', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Pengaturan baca',
            onPressed: _showReaderSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.readings.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) => _BookPage(
                item: widget.readings[index],
                showReading: _showReading,
                showMeaning: _showMeaning,
                fontSize: _fontSize,
                onTapSegment: (text) => _showTranslateTools(text, widget.readings[index]),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF315C7E),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: Row(
                children: [
                  IconButton.filled(
                    tooltip: 'Putar cerita',
                    onPressed: () => app.tts.speak(item.japanese),
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ToolChip(
                            selected: _showReading,
                            icon: Icons.text_fields_rounded,
                            label: 'ふ',
                            onTap: () => setState(() => _showReading = !_showReading),
                          ),
                          _ToolChip(
                            selected: _showMeaning,
                            icon: Icons.translate_rounded,
                            label: '文A',
                            onTap: () => setState(() => _showMeaning = !_showMeaning),
                          ),
                          _ToolChip(
                            selected: false,
                            icon: Icons.search_rounded,
                            label: 'Cari',
                            onTap: () => _showSearchSheet(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Sebelumnya',
                    onPressed: _index == 0 ? null : () => _controller.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Berikutnya',
                    onPressed: _index >= widget.readings.length - 1 ? null : () => _controller.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReaderSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pengaturan baca', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Text('Ukuran huruf ${_fontSize.round()}'),
                Slider(
                  value: _fontSize,
                  min: 18,
                  max: 32,
                  divisions: 7,
                  onChanged: (value) {
                    setState(() => _fontSize = value);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampilkan bacaan/furigana'),
                  value: _showReading,
                  onChanged: (value) {
                    setState(() => _showReading = value);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampilkan arti Indonesia'),
                  value: _showMeaning,
                  onChanged: (value) {
                    setState(() => _showMeaning = value);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTranslateTools(String text, ReadingItem item) {
    final app = AppScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alat baca', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              SelectableText(text, style: const TextStyle(fontSize: 20, height: 1.45, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _translationPreview(item, text),
                  style: const TextStyle(height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => app.tts.speak(text),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Suara'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _showReading = true),
                    icon: const Icon(Icons.text_fields_rounded),
                    label: const Text('Furigana'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _showMeaning = true),
                    icon: const Icon(Icons.translate_rounded),
                    label: const Text('Translate'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showSearchSheet(item, query: _extractKeyword(text)),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Cari'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchSheet(ReadingItem item, {String? query}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cari dalam cerita', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: query ?? ''),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), labelText: 'Kata Jepang / arti'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final word in _suggestions(item))
                    ActionChip(
                      label: Text(word),
                      onPressed: () => AppScope.of(context).tts.speak(word),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.selected, required this.icon, required this.label, required this.onTap});
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: Icon(icon, size: 18, color: selected ? Colors.white : null),
          backgroundColor: selected ? Colors.white.withValues(alpha: .22) : Colors.white,
          labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF315C7E), fontWeight: FontWeight.w900),
          label: Text(label),
          onPressed: onTap,
        ),
      );
}

class _BookPage extends StatelessWidget {
  const _BookPage({
    required this.item,
    required this.showReading,
    required this.showMeaning,
    required this.fontSize,
    required this.onTapSegment,
  });

  final ReadingItem item;
  final bool showReading;
  final bool showMeaning;
  final double fontSize;
  final ValueChanged<String> onTapSegment;

  @override
  Widget build(BuildContext context) {
    final paragraphs = item.japanese.split('\n\n').where((e) => e.trim().isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF4),
          borderRadius: BorderRadius.circular(30),
          image: const DecorationImage(
            opacity: .06,
            fit: BoxFit.cover,
            image: AssetImage('assets/branding/japanese_study_logo.png'),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: ListView(
          children: [
            Row(
              children: [
                JlptBadge(item.level, compact: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7A6F61), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2F2A24), height: 1.25),
            ),
            const SizedBox(height: 20),
            for (final paragraph in paragraphs) ...[
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTapSegment(paragraph.trim()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Text(
                    paragraph.trim(),
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E2922),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Center(
              child: OutlinedButton.icon(
                onPressed: () => onTapSegment(item.japanese.split('。').first),
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Referensi Belajar'),
              ),
            ),
            if (showReading) ...[
              const Divider(height: 30),
              Text(
                item.reading,
                style: const TextStyle(fontSize: 16, height: 1.65, color: Color(0xFF315C7E), fontWeight: FontWeight.w700),
              ),
            ],
            if (showMeaning) ...[
              const Divider(height: 30),
              Text(item.meaning, style: const TextStyle(fontSize: 17, height: 1.65, color: Color(0xFF4F463E))),
            ],
            if (item.questions.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Pertanyaan pemahaman', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              for (final q in item.questions)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBDC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.question, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(q.answer),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _translationPreview(ReadingItem item, String text) {
  final clean = text.replaceAll('\n', ' ');
  final firstMeaning = item.meaning.split('.').first.trim();
  return 'Terjemahan cepat: ${firstMeaning.isEmpty ? item.meaning : firstMeaning}.\n\nBagian dipilih: $clean';
}

String _extractKeyword(String text) {
  final clean = text.replaceAll(RegExp(r'[。、「」\s]'), '');
  if (clean.length <= 4) return clean;
  return clean.substring(0, 4);
}

List<String> _suggestions(ReadingItem item) {
  final words = <String>[];
  for (final raw in item.japanese.split(RegExp(r'[、。\n\s]+'))) {
    final word = raw.trim();
    if (word.length >= 2 && words.length < 12 && !words.contains(word)) words.add(word);
  }
  return words;
}

final List<ReadingItem> _fullStories = [
  ReadingItem(
    id: 'long_forest_house',
    level: 'N4',
    category: 'Cerita Utuh',
    title: '森の中の小さな家',
    japanese: '''聡介は疲れていました。何日も森の中を歩き続けていたのです。彼の目的は、地図の上の金を探すことではありませんでした。子どものころに祖父から聞いた、小さな家を見つけることでした。

朝になると、森は白い霧に包まれました。鳥の声は遠く、足元の草は冷たく濡れていました。聡介は古いノートを開きました。そこには、祖父の字で「大きな杉の木を過ぎたら、川の音を聞け」と書いてありました。

昼ごろ、聡介は本当に大きな杉の木を見つけました。その木は空まで届くように高く、根は地面の上を蛇のように伸びていました。彼は木の下で少し休み、パンを半分だけ食べました。残りは夜のために取っておくことにしました。

しばらく歩くと、かすかな水の音が聞こえました。聡介は胸が少し熱くなるのを感じました。川に近づくと、小さな橋がありました。橋の板は古く、踏むたびにぎしぎしと鳴りましたが、不思議と壊れることはありませんでした。

橋を渡った先に、苔に覆われた小さな家がありました。屋根は低く、窓は丸く、入口には古い鈴が下がっていました。聡介が鈴に触れると、澄んだ音が森の奥まで広がりました。

中には誰もいませんでした。しかし、机の上には新しいお茶が置かれていました。湯気がゆっくり上がっています。壁には祖父の写真がありました。その隣には、聡介が幼いころに描いた家の絵が飾られていました。

聡介は気づきました。祖父が残したものは宝ではなく、帰る場所だったのです。彼は窓を開けました。森の風が部屋に入り、古い紙の匂いとお茶の香りが混ざりました。

その夜、聡介は小さな家で眠りました。外では雨が静かに降っていました。彼は夢の中で祖父に会いました。祖父は何も言わず、ただ笑っていました。朝になったら、この家を直そう。聡介はそう決めました。''',
    reading: 'Sousuke wa tsukarete imashita. Nan-nichi mo mori no naka o aruki-tsudzukete ita no desu. ... Asa ni naru to, mori wa shiroi kiri ni tsutsumaremashita. ... Chiisana ie wa takara de wa naku, kaeru basho datta no desu.',
    meaning: 'Sousuke merasa sangat lelah setelah berhari-hari berjalan di hutan. Tujuannya bukan mencari emas di peta, tetapi menemukan rumah kecil yang dulu diceritakan kakeknya. Ia mengikuti petunjuk dalam buku catatan, melewati pohon cedar besar dan jembatan tua. Akhirnya ia menemukan rumah kecil yang menyimpan kenangan keluarganya. Ia sadar bahwa warisan kakeknya bukan harta, melainkan tempat untuk pulang.',
    questions: const [
      ReadingQuestion(question: '聡介は何を探していましたか。', answer: '祖父から聞いた小さな家を探していました。'),
      ReadingQuestion(question: '家の中に何がありましたか。', answer: '新しいお茶、祖父の写真、子どものころの絵がありました。'),
      ReadingQuestion(question: '聡介は最後に何を決めましたか。', answer: '小さな家を直そうと決めました。'),
    ],
  ),
  ReadingItem(
    id: 'long_station_letter',
    level: 'N3',
    category: 'Cerita Utuh',
    title: '雨の駅と青い手紙',
    japanese: '''春の終わり、町には毎日のように雨が降っていました。駅前の古い時計は少し遅れていて、人々はそれを知りながらも、誰も直そうとはしませんでした。時計が遅れているおかげで、急いでいる人も少しだけ安心できたからです。

美奈はその駅で小さな売店を手伝っていました。朝は新聞を並べ、昼は弁当を売り、夕方になると傘を忘れた人に安い傘を渡しました。彼女は毎日多くの人を見ていましたが、その中で一人だけ気になる人がいました。

その人は青い封筒を持った青年でした。彼は毎週金曜日の午後五時に駅に来て、三番線のベンチに座りました。電車に乗ることもなく、誰かに会うこともなく、ただ封筒を見つめていました。

ある金曜日、風が強く吹き、封筒が青年の手から飛ばされました。美奈は売店から飛び出し、濡れたホームを走りました。封筒は線路の近くまで飛んでいきましたが、美奈はぎりぎりで拾うことができました。

「ありがとうございます」と青年は深く頭を下げました。美奈は封筒を渡しながら、つい聞いてしまいました。「その手紙、大切なものなんですか。」青年は少し迷ってから答えました。「母に出せなかった手紙です。」

青年の母は去年亡くなったそうです。手紙には、都会に出てから言えなかった感謝の言葉が書かれていました。彼は毎週駅まで来るのに、ポストに入れることができませんでした。出しても届かないと分かっていたからです。

美奈は静かに言いました。「届かなくても、出していいと思います。言葉は、誰かの心に残ることがあります。」青年は長い間黙っていました。そして、駅前の赤いポストへ歩いていきました。

手紙がポストに入る音は、雨の音に消えそうなほど小さな音でした。しかし青年の顔は、初めて駅に来た日より少し明るく見えました。次の金曜日、三番線のベンチには誰も座っていませんでした。代わりに、売店の前に青い傘が置かれていました。''',
    reading: 'Haru no owari, machi ni wa mainichi no you ni ame ga futte imashita. ... Mina wa eki de baiten o tetsudatte imashita. ... Aoi fuutou wa haha ni dasenakatta tegami deshita.',
    meaning: 'Pada akhir musim semi, Mina bekerja di kios kecil di stasiun. Ia selalu melihat seorang pemuda yang datang setiap Jumat sambil membawa amplop biru. Setelah amplop itu hampir terbang terbawa angin, Mina mengetahui bahwa isinya adalah surat untuk ibu pemuda itu yang telah meninggal. Mina membantunya berani mengirim surat tersebut sebagai bentuk perpisahan dan ungkapan terima kasih.',
    questions: const [
      ReadingQuestion(question: '青年はいつ駅に来ましたか。', answer: '毎週金曜日の午後五時に来ました。'),
      ReadingQuestion(question: '青い封筒には何が入っていましたか。', answer: '母に出せなかった手紙が入っていました。'),
      ReadingQuestion(question: '最後に売店の前に何が置かれていましたか。', answer: '青い傘が置かれていました。'),
    ],
  ),
  ReadingItem(
    id: 'long_small_cafe',
    level: 'N4',
    category: 'Cerita Utuh',
    title: '坂の上の喫茶店',
    japanese: '''町の北側には、長い坂がありました。坂の上には小さな喫茶店が一つだけあり、看板には「月灯り」と書かれていました。店は古く、椅子も机も少し傷んでいましたが、窓から見える夕日は町で一番きれいでした。

遥はその喫茶店で働き始めたばかりでした。最初の日、店長は彼女に言いました。「ここでは、コーヒーを売るだけではありません。お客さんが少し元気になって帰れるようにするんです。」遥は意味がよく分かりませんでした。

毎日、いろいろな人が店に来ました。試験に落ちて泣きそうな学生、仕事で疲れた会社員、散歩の途中で雨に降られたおばあさん。遥は注文を聞き、コーヒーを運び、静かに話を聞きました。

ある夕方、一人の男の子が店に入りました。彼は何も注文せず、窓の近くに座って外を見ていました。遥が声をかけると、男の子は小さな声で言いました。「家に帰りたくないんです。」

遥は驚きましたが、すぐに温かいミルクを出しました。男の子は少しずつ話し始めました。学校で友だちとけんかをして、謝りたいのに言葉が見つからないのだと言いました。

店長は紙と鉛筆を持ってきました。「言えない言葉は、まず書いてみるといいですよ。」男の子は長い時間をかけて短い手紙を書きました。手紙には「ごめん。明日また話したい」とだけ書いてありました。

次の日、男の子は友だちと一緒に店に来ました。二人は少し照れながら、同じケーキを半分ずつ食べました。遥はその様子を見て、店長の言葉が少し分かった気がしました。

喫茶店は特別な魔法を持っているわけではありません。ただ、誰かが立ち止まれる場所でした。坂を上るのは大変です。でも、上った先で少し休めるなら、人はまた歩き出せるのです。''',
    reading: 'Machi no kitagawa ni wa nagai saka ga arimashita. Saka no ue ni wa chiisana kissaten ga hitotsu dake arimashita. ... Kissa-ten wa dareka ga tachidomareru basho deshita.',
    meaning: 'Di atas bukit ada kafe kecil bernama “Tsukiakari”. Haruka baru mulai bekerja di sana dan belajar bahwa kafe bukan hanya tempat menjual kopi, tetapi tempat orang bisa berhenti sebentar dan merasa lebih kuat. Suatu hari seorang anak datang karena bertengkar dengan temannya. Dengan bantuan Haruka dan pemilik kafe, ia menulis surat permintaan maaf dan akhirnya berdamai.',
    questions: const [
      ReadingQuestion(question: '喫茶店の名前は何ですか。', answer: '月灯りです。'),
      ReadingQuestion(question: '男の子はなぜ帰りたくなかったのですか。', answer: '友だちとけんかをして、謝る言葉が見つからなかったからです。'),
      ReadingQuestion(question: '喫茶店はどんな場所でしたか。', answer: '誰かが立ち止まって休める場所でした。'),
    ],
  ),
];
