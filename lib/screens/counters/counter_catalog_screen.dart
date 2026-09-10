import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class CounterCatalogScreen extends StatefulWidget {
  const CounterCatalogScreen({super.key});

  @override
  State<CounterCatalogScreen> createState() => _CounterCatalogScreenState();
}

class _CounterCatalogScreenState extends State<CounterCatalogScreen> {
  String _level = 'N5';
  late _CounterPattern _counter = _counters.first;
  String _query = '';

  List<_CounterPattern> get _visibleCounters {
    final pool = _counters.where((item) => item.level == _level).toList();
    if (_query.trim().isEmpty) return pool;
    final q = _query.trim().toLowerCase();
    return pool.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.suffix.contains(q) ||
          item.example.toLowerCase().contains(q) ||
          item.note.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _counter = _counters.firstWhere((item) => item.level == _level);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final visible = _visibleCounters;
    if (!visible.contains(_counter) && visible.isNotEmpty) {
      _counter = visible.first;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Penghitung Jepang')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _Hero(counter: _counter, onSpeak: () => app.tts.speak(_counter.sampleSpeech)),
          const SizedBox(height: 16),
          _LevelSelector(
            value: _level,
            onChanged: (value) {
              setState(() {
                _level = value;
                _counter = _counters.firstWhere((item) => item.level == value);
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Cari penghitung, contoh: orang, benda panjang, hari...',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          SectionTitle(
            title: 'Pilih josuushi',
            subtitle: 'Setiap penghitung punya tabel 1–100. Yang berubah tidak beraturan diberi tanda.',
          ),
          const SizedBox(height: 12),
          _CounterChips(
            counters: visible,
            selected: _counter,
            onSelected: (value) => setState(() => _counter = value),
          ),
          const SizedBox(height: 18),
          _RuleCard(counter: _counter),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'Tabel 1–100',
            subtitle: 'Tap angka untuk mendengar cara bacanya.',
          ),
          const SizedBox(height: 12),
          _CounterGrid(counter: _counter, onSpeak: app.tts.speak),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.counter, required this.onSpeak});

  final _CounterPattern counter;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                counter.suffix,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${counter.level} · ${counter.example}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
      );
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final level in _levels)
            ChoiceChip(
              label: Text(level),
              selected: value == level,
              onSelected: (_) => onChanged(level),
            ),
        ],
      );
}

class _CounterChips extends StatelessWidget {
  const _CounterChips({
    required this.counters,
    required this.selected,
    required this.onSelected,
  });

  final List<_CounterPattern> counters;
  final _CounterPattern selected;
  final ValueChanged<_CounterPattern> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in counters)
            ChoiceChip(
              label: Text('${item.suffix} ${item.name}'),
              selected: item == selected,
              onSelected: (_) => onSelected(item),
            ),
        ],
      );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.counter});

  final _CounterPattern counter;

  @override
  Widget build(BuildContext context) {
    final irregulars = <String>[];
    for (var i = 1; i <= 100; i++) {
      final reading = counter.read(i);
      if (reading.irregular) irregulars.add('$i: ${reading.value}');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(counter.suffix)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(counter.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(counter.note, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            if (irregulars.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Perubahan yang perlu ditandai', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: irregulars.take(18).map((value) => Chip(label: Text(value))).toList(),
              ),
              if (irregulars.length > 18) ...[
                const SizedBox(height: 6),
                Text(
                  '+${irregulars.length - 18} bentuk lain mengikuti pola angka 20, 30, 40, dan seterusnya.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CounterGrid extends StatelessWidget {
  const _CounterGrid({required this.counter, required this.onSpeak});

  final _CounterPattern counter;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 5
              : constraints.maxWidth >= 620
                  ? 4
                  : constraints.maxWidth >= 390
                      ? 3
                      : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 100,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns <= 2 ? 2.35 : 2.55,
            ),
            itemBuilder: (context, index) {
              final number = index + 1;
              final reading = counter.read(number);
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSpeak(reading.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: reading.irregular
                        ? const Color(0xFFFFA62B).withValues(alpha: .15)
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: reading.irregular
                          ? const Color(0xFFFFA62B).withValues(alpha: .55)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: reading.irregular
                              ? const Color(0xFFFFA62B)
                              : Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$number',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: reading.irregular ? Colors.white : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reading.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, height: 1.15),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
}

class _CounterPattern {
  const _CounterPattern({
    required this.level,
    required this.suffix,
    required this.name,
    required this.example,
    required this.note,
    required this.reader,
  });

  final String level;
  final String suffix;
  final String name;
  final String example;
  final String note;
  final _CounterReading Function(int number) reader;

  _CounterReading read(int number) => reader(number);

  String get sampleSpeech {
    final a = read(1).value;
    final b = read(2).value;
    final c = read(3).value;
    return '$a、$b、$c';
  }
}

class _CounterReading {
  const _CounterReading(this.value, {this.irregular = false});

  final String value;
  final bool irregular;
}

const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

final _counters = <_CounterPattern>[
  _CounterPattern(
    level: 'N5',
    suffix: '人',
    name: 'Orang',
    example: 'ひとり、ふたり、さんにん',
    note: '1 dan 2 khusus. Setelah itu biasanya angka + にん.',
    reader: (n) => _humanCounter(n),
  ),
  _CounterPattern(
    level: 'N5',
    suffix: 'つ',
    name: 'Benda umum',
    example: 'ひとつ、ふたつ、みっつ',
    note: 'Angka 1–10 sangat tidak beraturan. Setelah 10 biasanya memakai kata bantu bilangan lain.',
    reader: (n) => _tsuCounter(n),
  ),
  _CounterPattern(
    level: 'N5',
    suffix: '円',
    name: 'Yen / uang',
    example: 'ひゃくえん、ごひゃくえん',
    note: 'Ikuti angka Jepang + えん. 300, 600, 800 berubah bunyi.',
    reader: (n) => _basicCounter(n, 'えん'),
  ),
  _CounterPattern(
    level: 'N5',
    suffix: '時',
    name: 'Jam',
    example: 'いちじ、よじ、しちじ',
    note: '4 jam = よじ, 7 jam = しちじ, 9 jam = くじ.',
    reader: (n) => _hourCounter(n),
  ),
  _CounterPattern(
    level: 'N5',
    suffix: '日',
    name: 'Tanggal / hari',
    example: 'ついたち、ふつか、みっか',
    note: 'Tanggal 1–10, 14, 20, dan 24 wajib dihafal.',
    reader: (n) => _dayCounter(n),
  ),
  _CounterPattern(
    level: 'N4',
    suffix: '枚',
    name: 'Lembaran tipis',
    example: 'いちまい、にまい、さんまい',
    note: 'Untuk kertas, tiket, baju tipis. Polanya cukup teratur.',
    reader: (n) => _basicCounter(n, 'まい'),
  ),
  _CounterPattern(
    level: 'N4',
    suffix: '個',
    name: 'Benda kecil',
    example: 'いっこ、にこ、さんこ',
    note: '1, 6, 8, 10 sering berubah jadi bunyi kecil っ.',
    reader: (n) => _koCounter(n),
  ),
  _CounterPattern(
    level: 'N4',
    suffix: '本',
    name: 'Benda panjang',
    example: 'いっぽん、にほん、さんぼん',
    note: 'Benda panjang seperti botol, pensil, jalan. Banyak perubahan p/b.',
    reader: (n) => _honCounter(n),
  ),
  _CounterPattern(
    level: 'N4',
    suffix: '回',
    name: 'Kali',
    example: 'いっかい、にかい、さんかい',
    note: 'Untuk frekuensi. 1/6/8/10 berubah kecil っ.',
    reader: (n) => _kaiCounter(n),
  ),
  _CounterPattern(
    level: 'N4',
    suffix: '歳',
    name: 'Umur',
    example: 'いっさい、はたち、さんじゅっさい',
    note: '20 tahun = はたち. 1/8/10/20 perlu diingat.',
    reader: (n) => _ageCounter(n),
  ),
  _CounterPattern(
    level: 'N3',
    suffix: '匹',
    name: 'Hewan kecil',
    example: 'いっぴき、にひき、さんびき',
    note: 'Untuk kucing, ikan, serangga. Perhatikan p/h/b.',
    reader: (n) => _hikiCounter(n),
  ),
  _CounterPattern(
    level: 'N3',
    suffix: '杯',
    name: 'Gelas / cangkir',
    example: 'いっぱい、にはい、さんばい',
    note: 'Untuk minuman dalam wadah. Perubahan mirip 匹.',
    reader: (n) => _haiCounter(n),
  ),
  _CounterPattern(
    level: 'N3',
    suffix: '分',
    name: 'Menit',
    example: 'いっぷん、にふん、さんぷん',
    note: '1, 3, 4, 6, 8, 10 sering jadi ぷん.',
    reader: (n) => _minuteCounter(n),
  ),
  _CounterPattern(
    level: 'N3',
    suffix: '階',
    name: 'Lantai',
    example: 'いっかい、さんがい、ろっかい',
    note: '3階 dapat dibaca さんがい. 1/6/8/10 berubah.',
    reader: (n) => _floorCounter(n),
  ),
  _CounterPattern(
    level: 'N2',
    suffix: '冊',
    name: 'Buku berjilid',
    example: 'いっさつ、にさつ、さんさつ',
    note: 'Untuk buku, majalah, kamus. 1/8/10 berubah.',
    reader: (n) => _satsuCounter(n),
  ),
  _CounterPattern(
    level: 'N2',
    suffix: '台',
    name: 'Mesin / kendaraan',
    example: 'いちだい、にだい、さんだい',
    note: 'Untuk mobil, komputer, mesin. Cukup teratur.',
    reader: (n) => _basicCounter(n, 'だい'),
  ),
  _CounterPattern(
    level: 'N2',
    suffix: '名',
    name: 'Orang dalam situasi resmi',
    example: 'いちめい、にめい、さんめい',
    note: 'Bentuk resmi untuk menghitung orang dalam pengumuman atau reservasi.',
    reader: (n) => _basicCounter(n, 'めい'),
  ),
  _CounterPattern(
    level: 'N2',
    suffix: '件',
    name: 'Kasus / urusan',
    example: 'いっけん、にけん、さんけん',
    note: 'Untuk surel, kasus, urusan, dan laporan. Angka 1, 6, 8, dan 10 mengalami perubahan bunyi.',
    reader: (n) => _kenCounter(n),
  ),
  _CounterPattern(
    level: 'N1',
    suffix: '頭',
    name: 'Hewan besar',
    example: 'いっとう、にとう、さんとう',
    note: 'Untuk sapi, kuda, gajah. 1/8/10 berubah.',
    reader: (n) => _touCounter(n),
  ),
  _CounterPattern(
    level: 'N1',
    suffix: '羽',
    name: 'Burung / kelinci',
    example: 'いちわ、さんば、ろっぱ',
    note: 'Burung dan kelinci. Ada variasi わ/ば/ぱ.',
    reader: (n) => _waCounter(n),
  ),
  _CounterPattern(
    level: 'N1',
    suffix: '隻',
    name: 'Kapal',
    example: 'いっせき、にせき、さんせき',
    note: 'Untuk kapal atau perahu. Dipakai dalam konteks resmi atau berita.',
    reader: (n) => _sekiCounter(n),
  ),
  _CounterPattern(
    level: 'N1',
    suffix: '泊',
    name: 'Menginap',
    example: 'いっぱく、にはく、さんぱく',
    note: 'Untuk jumlah malam menginap. 1/3/6/8/10 berubah.',
    reader: (n) => _hakuCounter(n),
  ),
];

_CounterReading _basicCounter(int n, String suffix) {
  final reading = _numberReading(n);
  return _CounterReading('$reading$suffix', irregular: _numberHasIrregularSound(n));
}

_CounterReading _humanCounter(int n) {
  if (n == 1) return const _CounterReading('ひとり', irregular: true);
  if (n == 2) return const _CounterReading('ふたり', irregular: true);
  return _CounterReading('${_numberReading(n)}にん', irregular: _numberHasIrregularSound(n));
}

_CounterReading _tsuCounter(int n) {
  const special = {
    1: 'ひとつ',
    2: 'ふたつ',
    3: 'みっつ',
    4: 'よっつ',
    5: 'いつつ',
    6: 'むっつ',
    7: 'ななつ',
    8: 'やっつ',
    9: 'ここのつ',
    10: 'とお',
  };
  if (special.containsKey(n)) return _CounterReading(special[n]!, irregular: true);
  return _CounterReading('${_numberReading(n)}つ', irregular: true);
}

_CounterReading _hourCounter(int n) {
  final ones = n % 10;
  var base = _numberReading(n);
  var irregular = _numberHasIrregularSound(n);
  if (ones == 4) {
    base = n == 4 ? 'よ' : '${_numberReading(n - 4)}よ';
    irregular = true;
  } else if (ones == 7) {
    base = n == 7 ? 'しち' : '${_numberReading(n - 7)}しち';
    irregular = true;
  } else if (ones == 9) {
    base = n == 9 ? 'く' : '${_numberReading(n - 9)}く';
    irregular = true;
  }
  return _CounterReading('$baseじ', irregular: irregular);
}

_CounterReading _dayCounter(int n) {
  const special = {
    1: 'ついたち',
    2: 'ふつか',
    3: 'みっか',
    4: 'よっか',
    5: 'いつか',
    6: 'むいか',
    7: 'なのか',
    8: 'ようか',
    9: 'ここのか',
    10: 'とおか',
    14: 'じゅうよっか',
    20: 'はつか',
    24: 'にじゅうよっか',
  };
  if (special.containsKey(n)) return _CounterReading(special[n]!, irregular: true);
  return _CounterReading('${_numberReading(n)}にち', irregular: _numberHasIrregularSound(n));
}

_CounterReading _koCounter(int n) => _smallTsuCounter(n, 'こ', {1: 'いっこ', 6: 'ろっこ', 8: 'はっこ', 10: 'じゅっこ'});
_CounterReading _honCounter(int n) => _smallTsuCounter(n, 'ほん', {1: 'いっぽん', 3: 'さんぼん', 6: 'ろっぽん', 8: 'はっぽん', 10: 'じゅっぽん'});
_CounterReading _kaiCounter(int n) => _smallTsuCounter(n, 'かい', {1: 'いっかい', 6: 'ろっかい', 8: 'はっかい', 10: 'じゅっかい'});
_CounterReading _ageCounter(int n) {
  if (n == 20) return const _CounterReading('はたち', irregular: true);
  return _smallTsuCounter(n, 'さい', {1: 'いっさい', 8: 'はっさい', 10: 'じゅっさい'});
}
_CounterReading _hikiCounter(int n) => _smallTsuCounter(n, 'ひき', {1: 'いっぴき', 3: 'さんびき', 6: 'ろっぴき', 8: 'はっぴき', 10: 'じゅっぴき'});
_CounterReading _haiCounter(int n) => _smallTsuCounter(n, 'はい', {1: 'いっぱい', 3: 'さんばい', 6: 'ろっぱい', 8: 'はっぱい', 10: 'じゅっぱい'});
_CounterReading _minuteCounter(int n) => _smallTsuCounter(n, 'ふん', {1: 'いっぷん', 3: 'さんぷん', 4: 'よんぷん', 6: 'ろっぷん', 8: 'はっぷん', 10: 'じゅっぷん'});
_CounterReading _floorCounter(int n) => _smallTsuCounter(n, 'かい', {1: 'いっかい', 3: 'さんがい', 6: 'ろっかい', 8: 'はっかい', 10: 'じゅっかい'});
_CounterReading _satsuCounter(int n) => _smallTsuCounter(n, 'さつ', {1: 'いっさつ', 8: 'はっさつ', 10: 'じゅっさつ'});
_CounterReading _kenCounter(int n) => _smallTsuCounter(n, 'けん', {1: 'いっけん', 6: 'ろっけん', 8: 'はっけん', 10: 'じゅっけん'});
_CounterReading _touCounter(int n) => _smallTsuCounter(n, 'とう', {1: 'いっとう', 8: 'はっとう', 10: 'じゅっとう'});
_CounterReading _sekiCounter(int n) => _smallTsuCounter(n, 'せき', {1: 'いっせき', 8: 'はっせき', 10: 'じゅっせき'});
_CounterReading _hakuCounter(int n) => _smallTsuCounter(n, 'はく', {1: 'いっぱく', 3: 'さんぱく', 6: 'ろっぱく', 8: 'はっぱく', 10: 'じゅっぱく'});
_CounterReading _waCounter(int n) => _smallTsuCounter(n, 'わ', {3: 'さんば', 6: 'ろっぱ', 8: 'はっぱ', 10: 'じゅっぱ'});

_CounterReading _smallTsuCounter(int n, String suffix, Map<int, String> exceptions) {
  final ones = n % 10 == 0 ? 10 : n % 10;
  if (exceptions.containsKey(n)) return _CounterReading(exceptions[n]!, irregular: true);
  if (n > 10 && exceptions.containsKey(ones)) {
    final prefix = _numberReading(n - ones);
    final value = exceptions[ones]!;
    return _CounterReading('$prefix$value', irregular: true);
  }
  return _CounterReading('${_numberReading(n)}$suffix', irregular: _numberHasIrregularSound(n));
}

String _numberReading(int n) {
  if (n <= 0) return '$n';
  const ones = {
    1: 'いち',
    2: 'に',
    3: 'さん',
    4: 'よん',
    5: 'ご',
    6: 'ろく',
    7: 'なな',
    8: 'はち',
    9: 'きゅう',
  };
  if (n < 10) return ones[n]!;
  if (n == 10) return 'じゅう';
  if (n < 20) return 'じゅう${ones[n - 10]}';
  if (n < 100) {
    final tens = n ~/ 10;
    final rest = n % 10;
    return '${ones[tens]}じゅう${rest == 0 ? '' : ones[rest]}';
  }
  if (n == 100) return 'ひゃく';
  return '$n';
}

bool _numberHasIrregularSound(int n) {
  final ones = n % 10;
  return ones == 1 || ones == 3 || ones == 4 || ones == 6 || ones == 8 || ones == 0 || n == 20;
}
