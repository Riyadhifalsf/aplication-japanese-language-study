import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class KanaScreen extends StatefulWidget {
  const KanaScreen({super.key});

  @override
  State<KanaScreen> createState() => _KanaScreenState();
}

class _KanaScreenState extends State<KanaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Unduh paket kana untuk offline via sistem paket yang sudah ada.
  /// Bundel lokal menjamin tetap bisa dipakai tanpa internet.
  Future<void> _downloadKana(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final app = AppScope.of(context);
    if (_downloading) return;
    setState(() => _downloading = true);
    final refreshed = await app.downloadOfflinePack('kana');
    if (!mounted) return;
    setState(() => _downloading = false);
    final synced = app.packSyncedAt['kana'];
    messenger.showSnackBar(
      SnackBar(
        content: Text(refreshed
            ? 'Kana diperbarui dari server dan tersimpan offline.'
            : 'Kana tersimpan untuk offline.${synced == null ? '' : ' Sinkron terakhir $synced.'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Kana'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Hiragana'),
              Tab(text: 'Katakana'),
            ],
          ),
          actions: [
            _DownloadKanaButton(
              downloading: _downloading,
              onPressed: () => _downloadKana(context),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _KanaTabPage(hiragana: true),
            _KanaTabPage(hiragana: false),
          ],
        ),
      );
}

/// Tombol unduh kana di pojok kanan atas: spinner saat mengunduh,
/// centang bila paket kana sudah tersimpan offline.
class _DownloadKanaButton extends StatelessWidget {
  const _DownloadKanaButton({required this.downloading, required this.onPressed});

  final bool downloading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (downloading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    final downloaded =
        AppScope.of(context).downloadedPacks.contains('kana');
    return IconButton(
      tooltip: downloaded ? 'Kana sudah offline' : 'Unduh kana offline',
      onPressed: onPressed,
      icon: Icon(
        downloaded
            ? Icons.check_circle_rounded
            : Icons.download_rounded,
      ),
    );
  }
}

/// Satu halaman scroll penuh per tab: shortcut + Dasar + Dakuten + Yoon
/// (semua gaya tabel Dasar).
class _KanaTabPage extends StatelessWidget {
  _KanaTabPage({required this.hiragana});

  final bool hiragana;
  final _dasarKey = GlobalKey();
  final _dakutenKey = GlobalKey();
  final _yoonKey = GlobalKey();

  void _jump(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ShortcutChip(
                  label: 'Dasar', onTap: () => _jump(_dasarKey)),
              const SizedBox(width: 8),
              _ShortcutChip(
                  label: 'Dakuten', onTap: () => _jump(_dakutenKey)),
              const SizedBox(width: 8),
              _ShortcutChip(
                  label: 'Yōon', onTap: () => _jump(_yoonKey)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _dasarKey,
          child: _ChartSection(
            title: 'Dasar',
            subtitle: 'Bunyi dasar gojuon + bacaannya.',
            rows: _KanaChartRows.dasar,
            columns: const ['-A', '-I', '-U', '-E', '-O'],
            hiragana: hiragana,
          ),
        ),
        const SizedBox(height: 22),
        KeyedSubtree(
          key: _dakutenKey,
          child: _ChartSection(
            title: 'Dakuten',
            subtitle: 'Bunyi berubah dengan tenten dan maru.',
            rows: _KanaChartRows.dakuten,
            columns: const ['-A', '-I', '-U', '-E', '-O'],
            hiragana: hiragana,
          ),
        ),
        const SizedBox(height: 22),
        KeyedSubtree(
          key: _yoonKey,
          child: _ChartSection(
            title: 'Yōon',
            subtitle: 'Bunyi gabungan (kecil ゃゅょ).',
            rows: _KanaChartRows.yoon,
            columns: const ['-A', '-U', '-O'],
            hiragana: hiragana,
          ),
        ),
      ],
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(label),
        avatar: const Icon(Icons.arrow_downward_rounded, size: 16),
        onPressed: onTap,
      );
}


/// Baris tabel kana gaya Dasar (kana + romaji), dipakai semua section.
class _KanaChartRows {
  _KanaChartRows._();

  static const dasar = [
    ('A-', ['あ', 'い', 'う', 'え', 'お'], ['A', 'I', 'U', 'E', 'O']),
    ('K-', ['か', 'き', 'く', 'け', 'こ'], ['KA', 'KI', 'KU', 'KE', 'KO']),
    ('S-', ['さ', 'し', 'す', 'せ', 'そ'], ['SA', 'SHI', 'SU', 'SE', 'SO']),
    ('T-', ['た', 'ち', 'つ', 'て', 'と'], ['TA', 'CHI', 'TSU', 'TE', 'TO']),
    ('N-', ['な', 'に', 'ぬ', 'ね', 'の'], ['NA', 'NI', 'NU', 'NE', 'NO']),
    ('H-', ['は', 'ひ', 'ふ', 'へ', 'ほ'], ['HA', 'HI', 'FU', 'HE', 'HO']),
    ('M-', ['ま', 'み', 'む', 'め', 'も'], ['MA', 'MI', 'MU', 'ME', 'MO']),
    ('Y-', ['や', '', 'ゆ', '', 'よ'], ['YA', '', 'YU', '', 'YO']),
    ('R-', ['ら', 'り', 'る', 'れ', 'ろ'], ['RA', 'RI', 'RU', 'RE', 'RO']),
    ('W-', ['わ', '', '', '', 'を'], ['WA', '', '', '', 'WO']),
    ('N', ['ん', '', '', '', ''], ['N', '', '', '', '']),
  ];

  static const dakuten = [
    ('G-', ['が', 'ぎ', 'ぐ', 'げ', 'ご'], ['GA', 'GI', 'GU', 'GE', 'GO']),
    ('Z-', ['ざ', 'じ', 'ず', 'ぜ', 'ぞ'], ['ZA', 'JI', 'ZU', 'ZE', 'ZO']),
    ('D-', ['だ', 'ぢ', 'づ', 'で', 'ど'], ['DA', 'JI', 'ZU', 'DE', 'DO']),
    ('B-', ['ば', 'び', 'ぶ', 'べ', 'ぼ'], ['BA', 'BI', 'BU', 'BE', 'BO']),
    ('P-', ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'], ['PA', 'PI', 'PU', 'PE', 'PO']),
  ];

  static const yoon = [
    ('KY-', ['きゃ', 'きゅ', 'きょ'], ['KYA', 'KYU', 'KYO']),
    ('SH-', ['しゃ', 'しゅ', 'しょ'], ['SHA', 'SHU', 'SHO']),
    ('CH-', ['ちゃ', 'ちゅ', 'ちょ'], ['CHA', 'CHU', 'CHO']),
    ('NY-', ['にゃ', 'にゅ', 'にょ'], ['NYA', 'NYU', 'NYO']),
    ('HY-', ['ひゃ', 'ひゅ', 'ひょ'], ['HYA', 'HYU', 'HYO']),
    ('MY-', ['みゃ', 'みゅ', 'みょ'], ['MYA', 'MYU', 'MYO']),
    ('RY-', ['りゃ', 'りゅ', 'りょ'], ['RYA', 'RYU', 'RYO']),
    ('GY-', ['ぎゃ', 'ぎゅ', 'ぎょ'], ['GYA', 'GYU', 'GYO']),
    ('J-', ['じゃ', 'じゅ', 'じょ'], ['JA', 'JU', 'JO']),
    ('BY-', ['びゃ', 'びゅ', 'びょ'], ['BYA', 'BYU', 'BYO']),
    ('PY-', ['ぴゃ', 'ぴゅ', 'ぴょ'], ['PYA', 'PYU', 'PYO']),
  ];
}

/// Satu section tabel (judul + kolom + baris) untuk halaman scroll.
class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.columns,
    required this.hiragana,
  });

  final String title;
  final String subtitle;
  final List<(String, List<String>, List<String>)> rows;
  final List<String> columns;
  final bool hiragana;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          _KanaColumnHeader(columns: columns),
          for (final row in rows)
            _KanaTableRow(row: row, hiragana: hiragana),
          const SizedBox(height: 6),
          Text(
            'Huruf di tabel bisa dipencet untuk mendengarkan suara.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45),
          ),
        ],
      );
}

class _KanaColumnHeader extends StatelessWidget {
  const _KanaColumnHeader({required this.columns});

  final List<String> columns;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 44, bottom: 8),
        child: Row(
          children: [
            for (final label in columns)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      );
}

class _KanaTableRow extends StatelessWidget {
  const _KanaTableRow({required this.row, required this.hiragana});

  final (String, List<String>, List<String>) row;
  final bool hiragana;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final label = row.$1;
    final chars = row.$2;
    final roman = row.$3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800),
            ),
          ),
          for (var index = 0; index < chars.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: chars[index].isEmpty
                    ? const SizedBox(height: 64)
                    : _KanaTableCell(
                        character: hiragana ? chars[index] : _toKatakana(chars[index]),
                        romaji: roman[index],
                        onTap: () => app.tts.speak(hiragana ? chars[index] : _toKatakana(chars[index])),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  static String _toKatakana(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x3041 && rune <= 0x3096) {
        buffer.writeCharCode(rune + 0x60);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}

class _KanaTableCell extends StatelessWidget {
  const _KanaTableCell({required this.character, required this.romaji, required this.onTap});

  final String character;
  final String romaji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(character, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 5),
                Text(romaji, textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
}
