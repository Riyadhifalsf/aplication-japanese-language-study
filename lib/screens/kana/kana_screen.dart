import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kana_character.dart';
import '../../services/kana_catalog.dart';
import '../../state/app_controller.dart';

class KanaScreen extends StatefulWidget {
  const KanaScreen({super.key});

  @override
  State<KanaScreen> createState() => _KanaScreenState();
}

class _KanaScreenState extends State<KanaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _group = 'Semua';

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
            IconButton(
              tooltip: 'Kuis seluruh kana',
              onPressed: _openQuiz,
              icon: const Icon(Icons.quiz_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final group in ['Semua', 'Dasar', 'Dakuten', 'Yōon'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: _group == group,
                          label: Text(group),
                          onSelected: (_) => setState(() => _group = group),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _group == 'Dasar'
                      ? const _KanaChart(hiragana: true)
                      : _group == 'Yōon'
                          ? const _YoonChart(hiragana: true)
                          : _KanaGrid(
                              items: _filter(KanaCatalog.hiragana),
                              label: 'hiragana',
                            ),
                  _group == 'Dasar'
                      ? const _KanaChart(hiragana: false)
                      : _group == 'Yōon'
                          ? const _YoonChart(hiragana: false)
                          : _KanaGrid(
                              items: _filter(KanaCatalog.katakana),
                              label: 'katakana',
                            ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openQuiz,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Mulai kuis'),
        ),
      );

  List<KanaCharacter> _filter(List<KanaCharacter> values) => _group == 'Semua'
      ? values
      : values.where((item) => item.group == _group).toList(growable: false);

  void _openQuiz() {
    final source =
        _tabs.index == 0 ? KanaCatalog.hiragana : KanaCatalog.katakana;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KanaQuizScreen(
          title: _tabs.index == 0 ? 'Hiragana' : 'Katakana',
          items: source,
        ),
      ),
    );
  }
}


class _KanaChart extends StatelessWidget {
  const _KanaChart({required this.hiragana});

  final bool hiragana;

  static const _rows = [
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

  static const _columns = ['-A', '-I', '-U', '-E', '-O'];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
        children: [
          const _KanaColumnHeader(columns: _columns),
          for (final row in _rows) _KanaTableRow(row: row, hiragana: hiragana),
          const SizedBox(height: 20),
          Text(
            'Huruf di tabel bisa dipencet untuk mendengarkan suara. Susunannya mengikuti baris bunyi A, K, S, T, N, H, M, Y, R, W seperti referensi.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
          ),
        ],
      );
}

class _YoonChart extends StatelessWidget {
  const _YoonChart({required this.hiragana});

  final bool hiragana;

  static const _rows = [
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

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
        children: [
          const _KanaColumnHeader(columns: ['-A', '-U', '-O']),
          for (final row in _rows) _KanaTableRow(row: row, hiragana: hiragana),
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

class _KanaGrid extends StatelessWidget {
  const _KanaGrid({required this.items, required this.label});

  final List<KanaCharacter> items;
  final String label;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 8 : 5,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        mainAxisExtent:
            MediaQuery.sizeOf(context).width >= 600 ? 96 : 86,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => app.tts.speak(item.character),
            child: Semantics(
              label: '${item.character}, ${item.romaji}, $label',
              button: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.character,
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(
                              fontSize: 40,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.romaji,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class KanaQuizScreen extends StatefulWidget {
  const KanaQuizScreen({
    required this.title,
    required this.items,
    super.key,
  });

  final String title;
  final List<KanaCharacter> items;

  @override
  State<KanaQuizScreen> createState() => _KanaQuizScreenState();
}

class _KanaQuizScreenState extends State<KanaQuizScreen> {
  final _random = Random();
  Timer? _autoNextTimer;
  late List<KanaCharacter> _questions;
  int _index = 0;
  int _correct = 0;
  String? _selected;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _restartData();
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _questions.length) return _result(context);
    final item = _questions[_index];
    final choices = _choices(item);
    return Scaffold(
      appBar: AppBar(title: Text('Kuis ${widget.title}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text('Soal ${_index + 1}/${_questions.length}'),
              const Spacer(),
              Text(
                '$_correct benar',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _index / _questions.length),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Text(
                    item.character,
                    style: const TextStyle(
                      fontSize: 82,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton.filledTonal(
                    onPressed: () =>
                        AppScope.of(context).tts.speak(item.character),
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: _selected == null
                    ? () => _answer(choice, item)
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: _selected != null && choice.romaji == item.romaji
                      ? const BorderSide(
                          color: AppTheme.success,
                          width: 2,
                        )
                      : _selected == choice.romaji
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.error,
                              width: 2,
                            )
                          : null,
                ),
                child: Text(
                  choice.romaji,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          if (_selected != null)
            if (_selected == item.romaji)
              const _KanaAutoNextIndicator()
            else
              FilledButton(
                onPressed: _next,
                child: const Text('Saya sudah paham, lanjutkan'),
              ),
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    final app = AppScope.of(context);
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        app.recordQuiz(correct: _correct, total: _questions.length);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil kuis kana')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_correct/${_questions.length}',
              style: const TextStyle(
                color: AppTheme.seed,
                fontSize: 58,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Kuis memakai seluruh koleksi, bukan hanya 15 kana.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Ulangi'),
            ),
          ],
        ),
      ),
    );
  }

  List<KanaCharacter> _choices(KanaCharacter correct) {
    final seed =
        correct.character.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final random = Random(seed);
    final pool = [...widget.items]..shuffle(random);
    final values = <KanaCharacter>[correct];
    final used = <String>{correct.romaji};
    for (final item in pool) {
      if (used.add(item.romaji)) values.add(item);
      if (values.length == 4) break;
    }
    values.shuffle(random);
    return values;
  }

  void _answer(KanaCharacter choice, KanaCharacter correct) {
    final isCorrect = choice.romaji == correct.romaji;
    setState(() {
      _selected = choice.romaji;
      if (isCorrect) _correct++;
    });
    if (isCorrect) {
      _autoNextTimer?.cancel();
      _autoNextTimer = Timer(const Duration(milliseconds: 550), () {
        if (mounted) _next();
      });
    }
  }

  void _next() {
    _autoNextTimer?.cancel();
    setState(() {
      _index++;
      _selected = null;
    });
  }

  void _restart() {
    _autoNextTimer?.cancel();
    setState(_restartData);
  }

  void _restartData() {
    _questions = [...widget.items]..shuffle(_random);
    _questions = _questions.take(20).toList(growable: false);
    _index = 0;
    _correct = 0;
    _selected = null;
    _recorded = false;
  }
}

class _KanaAutoNextIndicator extends StatelessWidget {
  const _KanaAutoNextIndicator();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 10),
            Text(
              'Benar — lanjut otomatis…',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}
