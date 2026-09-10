import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

enum KanjiThemeQuizMode { meaning, reading, character }

class KanjiThemeQuizScreen extends StatefulWidget {
  const KanjiThemeQuizScreen({super.key});

  @override
  State<KanjiThemeQuizScreen> createState() => _KanjiThemeQuizScreenState();
}

class _KanjiThemeQuizScreenState extends State<KanjiThemeQuizScreen> {
  final _random = Random();
  Timer? _autoNextTimer;
  String _level = 'N5';
  String _group = 'Keluarga';
  KanjiThemeQuizMode _mode = KanjiThemeQuizMode.meaning;
  List<Kanji> _questions = const [];
  int _index = 0;
  int _correct = 0;
  int? _selectedId;
  bool _recorded = false;

  static const _groups = <String, List<String>>{
    'Keluarga': ['keluarga', 'orang', 'ayah', 'ibu', 'anak', 'laki', 'perempuan', 'nama'],
    'Angka & waktu': ['angka', 'waktu', 'hari', 'bulan', 'tahun', 'jam', 'minggu'],
    'Alam & cuaca': ['alam', 'cuaca', 'gunung', 'sungai', 'hujan', 'api', 'air', 'langit'],
    'Sekolah & belajar': ['sekolah', 'belajar', 'buku', 'bahasa', 'guru', 'murid', 'ujian'],
    'Kerja & bisnis': ['kerja', 'bisnis', 'uang', 'perusahaan', 'toko', 'jual', 'beli'],
    'Makanan': ['makanan', 'makan', 'minum', 'nasi', 'air', 'ikan', 'daging'],
    'Tubuh': ['tubuh', 'mata', 'telinga', 'tangan', 'kaki', 'mulut', 'kepala'],
    'Arah & tempat': ['arah', 'tempat', 'atas', 'bawah', 'kiri', 'kanan', 'luar', 'dalam'],
    'Transportasi': ['transportasi', 'kereta', 'mobil', 'jalan', 'stasiun', 'kapal'],
  };

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    super.dispose();
  }

  bool get _started => _questions.isNotEmpty;
  bool get _finished => _started && _index >= _questions.length;

  @override
  Widget build(BuildContext context) {
    if (!_started) return _setup(context);
    if (_finished) return _result(context);
    return _quiz(context);
  }

  Widget _setup(BuildContext context) {
    final app = AppScope.of(context);
    final count = _pool(app).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Kuis Kanji Kelompok')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE64E64), Color(0xFFFF8A65)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.category_rounded, color: Colors.white, size: 34),
                SizedBox(height: 14),
                Text(
                  'Belajar kanji berdasarkan tema',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Contoh: keluarga, alam, waktu, sekolah, dan kerja. Setelah menjawab, suara bacaan kanji akan diputar.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Pilih tingkat'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in ['N5', 'N4', 'N3', 'N2', 'N1'])
                ChoiceChip(
                  selected: _level == level,
                  label: Text(level),
                  onSelected: (_) => setState(() => _level = level),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Pilih kelompok'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in _groups.keys)
                ChoiceChip(
                  selected: _group == group,
                  label: Text(group),
                  onSelected: (_) => setState(() => _group = group),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.seed.withValues(alpha: .14),
                foregroundColor: AppTheme.seed,
                child: const Icon(Icons.quiz_rounded),
              ),
              title: Text(
                '$count kanji cocok',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('Kuis mengambil maksimal 12 soal acak.'),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: count < 4 ? null : () => _start(app),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Mulai kuis'),
          ),
          if (count < 4) ...[
            const SizedBox(height: 10),
            Text(
              'Kelompok ini belum cukup untuk pilihan ganda. Coba tingkat atau kelompok lain.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quiz(BuildContext context) {
    final question = _questions[_index];
    final choices = _choices(question);
    return Scaffold(
      appBar: AppBar(
        title: Text('$_group · $_level'),
        actions: [
          PopupMenuButton<KanjiThemeQuizMode>(
            initialValue: _mode,
            onSelected: (mode) => setState(() {
              _autoNextTimer?.cancel();
              _mode = mode;
              _selectedId = null;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: KanjiThemeQuizMode.meaning,
                child: Text('Kanji → arti'),
              ),
              PopupMenuItem(
                value: KanjiThemeQuizMode.reading,
                child: Text('Kanji → bacaan'),
              ),
              PopupMenuItem(
                value: KanjiThemeQuizMode.character,
                child: Text('Arti → kanji'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Row(
            children: [
              Text('Soal ${_index + 1}/${_questions.length}'),
              const Spacer(),
              Text(
                'Benar: $_correct',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _index / _questions.length,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Card(
              key: ValueKey('${question.id}-$_mode'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
                child: Column(
                  children: [
                    Text(
                      _promptLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _questionText(question),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    JlptBadge(question.level),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ThemeAnswerButton(
                text: _answerText(choice),
                selected: _selectedId == choice.id,
                reveal: _selectedId != null,
                correct: choice.id == question.id,
                onPressed:
                    _selectedId == null ? () => _answer(choice, question) : null,
              ),
            ),
          if (_selectedId != null) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  _selectedId == question.id
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: _selectedId == question.id
                      ? AppTheme.success
                      : Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '${question.character} · ${question.preferredReading}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(question.meaning),
                trailing: IconButton(
                  onPressed: () => AppScope.of(context).tts.speak(question.preferredReading),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedId == question.id)
              const _ThemeAutoNextIndicator()
            else
              FilledButton(
                onPressed: _next,
                child: Text(
                  _index == _questions.length - 1
                      ? 'Lihat hasil'
                      : 'Soal berikutnya',
                ),
              ),
          ],
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
    final accuracy = (_correct / _questions.length * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil kuis kelompok')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 58,
                backgroundColor: const Color(0xFFE64E64).withValues(alpha: .13),
                child: Text(
                  '$accuracy%',
                  style: const TextStyle(
                    color: Color(0xFFE64E64),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                accuracy >= 80 ? 'Bagus! Tema ini mulai nempel.' : 'Ulangi lagi biar makin kuat.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text('$_correct benar dari ${_questions.length} soal'),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Ulangi kelompok ini'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _questions = const [];
                  _index = 0;
                  _correct = 0;
                  _selectedId = null;
                  _recorded = false;
                }),
                child: const Text('Pilih kelompok lain'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _promptLabel => switch (_mode) {
        KanjiThemeQuizMode.meaning => 'Pilih arti kanji yang benar',
        KanjiThemeQuizMode.reading => 'Pilih bacaan utama',
        KanjiThemeQuizMode.character => 'Pilih kanji yang sesuai',
      };

  String _questionText(Kanji item) => _mode == KanjiThemeQuizMode.character
      ? item.meaning
      : item.character;

  String _answerText(Kanji item) => switch (_mode) {
        KanjiThemeQuizMode.meaning => item.meaning,
        KanjiThemeQuizMode.reading => item.preferredReading,
        KanjiThemeQuizMode.character => item.character,
      };

  void _start(AppController app) {
    final pool = _pool(app)..shuffle(_random);
    setState(() {
      _questions = pool.take(12).toList(growable: false);
      _index = 0;
      _correct = 0;
      _selectedId = null;
      _recorded = false;
    });
  }

  List<Kanji> _pool(AppController app) {
    final keywords = _groups[_group] ?? const [];
    return app.repository
        .kanjiForLevel(_level)
        .where((item) => item.hasCompleteMetadata)
        .where((item) {
          final haystack = [
            item.meaning,
            ...item.themes,
          ].join(' ').toLowerCase();
          return keywords.any(haystack.contains);
        })
        .toList(growable: true);
  }

  List<Kanji> _choices(Kanji correct) {
    final app = AppScope.of(context);
    final output = <Kanji>[correct];
    final seen = <String>{_answerText(correct)};
    final pool = app.repository
        .kanjiForLevel(correct.level)
        .where((item) => item.hasCompleteMetadata)
        .toList(growable: false);
    final stableRandom = Random(correct.id * 13 + _mode.index);
    if (pool.isNotEmpty) {
      final start = stableRandom.nextInt(pool.length);
      for (var offset = 0; offset < pool.length && output.length < 4; offset++) {
        final item = pool[(start + offset * 17) % pool.length];
        if (item.id != correct.id && seen.add(_answerText(item))) {
          output.add(item);
        }
      }
    }
    output.shuffle(stableRandom);
    return output;
  }

  void _answer(Kanji choice, Kanji correct) {
    final isCorrect = choice.id == correct.id;
    AppScope.of(context).tts.speak(correct.preferredReading);
    setState(() {
      _selectedId = choice.id;
      if (isCorrect) _correct++;
    });
    if (isCorrect) {
      _autoNextTimer?.cancel();
      _autoNextTimer = Timer(const Duration(milliseconds: 850), () {
        if (mounted) _next();
      });
    }
  }

  void _next() {
    _autoNextTimer?.cancel();
    setState(() {
      _index++;
      _selectedId = null;
    });
  }

  void _restart() {
    final app = AppScope.of(context);
    _start(app);
  }
}

class _ThemeAnswerButton extends StatelessWidget {
  const _ThemeAnswerButton({
    required this.text,
    required this.selected,
    required this.reveal,
    required this.correct,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final bool reveal;
  final bool correct;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = !reveal
        ? Theme.of(context).colorScheme.surface
        : correct
            ? AppTheme.success.withValues(alpha: .12)
            : selected
                ? Theme.of(context).colorScheme.error.withValues(alpha: .12)
                : Theme.of(context).colorScheme.surface;
    final borderColor = !reveal
        ? Theme.of(context).colorScheme.outlineVariant
        : correct
            ? AppTheme.success
            : selected
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (reveal && correct)
                const Icon(Icons.check_circle_rounded, color: AppTheme.success)
              else if (reveal && selected)
                Icon(Icons.cancel_rounded, color: Theme.of(context).colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeAutoNextIndicator extends StatelessWidget {
  const _ThemeAutoNextIndicator();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Benar, lanjut otomatis…',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}
