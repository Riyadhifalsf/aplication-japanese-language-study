import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

enum KanjiReviewMode { meaning, reading, character }

class KanjiReviewScreen extends StatefulWidget {
  const KanjiReviewScreen({super.key, this.sessionSize = 20});

  final int sessionSize;

  @override
  State<KanjiReviewScreen> createState() => _KanjiReviewScreenState();
}

class _KanjiReviewScreenState extends State<KanjiReviewScreen> {
  final _random = math.Random();
  Timer? _autoNextTimer;
  List<Kanji> _items = const [];
  List<Kanji> _choices = const [];
  final Map<String, List<KanjiReviewMode>> _levelModes = {};
  KanjiReviewMode _mode = KanjiReviewMode.meaning;
  KanjiReviewResult? _lastResult;
  int? _selectedId;
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final app = AppScope.of(context);
    _items = app.dueKanjiReviewIds
        .map(app.repository.kanjiById)
        .whereType<Kanji>()
        .take(widget.sessionSize)
        .toList(growable: false);
    if (_items.isNotEmpty) _prepareQuestion(app);
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (_items.isEmpty) return _emptyState(context, app);
    if (_index >= _items.length) return _resultScreen(context, app);
    final current = _items[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ulangi Kanji'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: JlptBadge(current.level)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            color: const Color(0xFFFFA62B).withValues(alpha: .1),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFE28200),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pengulangan terjadwal menjaga kanji tetap melekat. '
                      'Intervalnya bertahap: 2, 4, 7, 14, lalu 30 hari.',
                      style: TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Soal ${_index + 1}/${_items.length}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$_correct benar · $_wrong salah',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _index / _items.length,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
              child: Column(
                children: [
                  Text(
                    _prompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _questionText(current),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:
                            _mode == KanjiReviewMode.character ? 34 : 78,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_mode != KanjiReviewMode.character)
                    IconButton.filledTonal(
                      tooltip: 'Dengarkan bacaan',
                      onPressed: () =>
                          app.tts.speak(current.preferredReading),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final choice in _choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewAnswerButton(
                text: _answerText(choice),
                characterMode: _mode == KanjiReviewMode.character,
                selected: _selectedId == choice.id,
                reveal: _selectedId != null,
                correct: choice.id == current.id,
                onPressed:
                    _selectedId == null ? () => _answer(choice) : null,
              ),
            ),
          if (_lastResult != null) ...[
            const SizedBox(height: 4),
            Card(
              color: _lastResult!.correct
                  ? AppTheme.success.withValues(alpha: .1)
                  : Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: .55),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _lastResult!.correct
                          ? Icons.check_circle_rounded
                          : Icons.refresh_rounded,
                      color: _lastResult!.correct
                          ? AppTheme.success
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedback(current),
                        style: const TextStyle(
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_lastResult!.correct)
              const _ReviewAutoNextIndicator()
            else
              FilledButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Saya sudah baca, lanjutkan'),
              ),
          ],
        ],
      ),
    );
  }

  String get _prompt => switch (_mode) {
        KanjiReviewMode.meaning => 'Masih ingat arti kanji ini?',
        KanjiReviewMode.reading => 'Masih ingat bacaannya?',
        KanjiReviewMode.character => 'Pilih kanji yang sesuai dengan arti',
      };

  String _questionText(Kanji item) =>
      _mode == KanjiReviewMode.character
          ? item.meaning
          : item.character;

  String _answerText(Kanji item) => switch (_mode) {
        KanjiReviewMode.meaning => item.meaning,
        KanjiReviewMode.reading => item.preferredReading,
        KanjiReviewMode.character => item.character,
      };

  String _feedback(Kanji current) {
    final result = _lastResult!;
    if (result.correct) {
      return 'Benar! ${current.character} dijadwalkan lagi '
          '${result.intervalDays} hari dari sekarang.';
    }
    return 'Belum tepat. Jawabannya ${_answerText(current)}. '
        'Kanji ini akan diingatkan lagi besok.';
  }

  void _prepareQuestion(AppController app) {
    final current = _items[_index];
    final modes = _levelModes.putIfAbsent(current.level, () {
      final levelItems = app.repository
          .kanjiForLevel(current.level)
          .where((item) => item.hasCompleteMetadata)
          .toList(growable: false);
      return KanjiReviewMode.values
          .where((mode) => _distinctAnswerCount(levelItems, mode) >= 4)
          .toList(growable: false);
    });
    _mode = modes.isEmpty
        ? KanjiReviewMode.character
        : modes[_index % modes.length];
    _choices = _buildChoices(app, current);
  }

  int _distinctAnswerCount(
    List<Kanji> items,
    KanjiReviewMode mode,
  ) =>
      items.map((item) {
        return switch (mode) {
          KanjiReviewMode.meaning => item.meaning,
          KanjiReviewMode.reading => item.preferredReading,
          KanjiReviewMode.character => item.character,
        };
      }).toSet().length;

  List<Kanji> _buildChoices(AppController app, Kanji correct) {
    final seed = correct.id * 101 + _index * 37 + _mode.index;
    final stableRandom = math.Random(seed);
    final sameLevel = app.repository.kanjiForLevel(correct.level);
    final output = <Kanji>[correct];
    final usedIds = <int>{correct.id};
    final usedAnswers = <String>{_answerText(correct)};

    void addChoice(Kanji item) {
      if (item.hasCompleteMetadata &&
          usedIds.add(item.id) &&
          usedAnswers.add(_answerText(item))) {
        output.add(item);
      }
    }

    if (sameLevel.isNotEmpty) {
      final start = stableRandom.nextInt(sameLevel.length);
      for (var offset = 0;
          offset < sameLevel.length && output.length < 4;
          offset++) {
        addChoice(sameLevel[(start + offset * 37) % sameLevel.length]);
      }
    }
    final fallback = app.repository.kanji;
    if (output.length < 4 && fallback.isNotEmpty) {
      final start = stableRandom.nextInt(fallback.length);
      for (var offset = 0;
          offset < fallback.length && output.length < 4;
          offset++) {
        addChoice(fallback[(start + offset * 41) % fallback.length]);
      }
    }
    output.shuffle(_random);
    return output;
  }

  void _answer(Kanji choice) {
    final current = _items[_index];
    final correct = choice.id == current.id;
    final app = AppScope.of(context);
    final result = app.recordKanjiReviewAnswer(
      kanjiId: current.id,
      correct: correct,
    );
    app.tts.speak(current.preferredReading);
    setState(() {
      _selectedId = choice.id;
      _lastResult = result;
      if (correct) {
        _correct++;
      } else {
        _wrong++;
      }
    });
    if (correct) {
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
      _lastResult = null;
      if (_index < _items.length) {
        _prepareQuestion(AppScope.of(context));
      }
    });
  }

  Widget _emptyState(BuildContext context, AppController app) {
    final nextDate = app.nextKanjiReviewDate;
    return Scaffold(
      appBar: AppBar(title: const Text('Ulangi Kanji')),
      body: EmptyState(
        title: 'Belum ada ulangan hari ini',
        message: nextDate == null
            ? 'Kuasai kanji lewat kuis. Ulangan pertama akan muncul 2 hari kemudian.'
            : 'Ulangan berikutnya dijadwalkan ${_formatDate(nextDate)}.',
        icon: Icons.event_available_rounded,
      ),
    );
  }

  Widget _resultScreen(BuildContext context, AppController app) => Scaffold(
        appBar: AppBar(title: const Text('Hasil Ulangan')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 58,
                  backgroundColor: Color(0xFF173B34),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.auto_awesome_rounded, size: 54),
                ),
                const SizedBox(height: 22),
                Text(
                  'Ulangan hari ini selesai!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_correct benar · $_wrong perlu diulang',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (app.dueKanjiReviewCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${app.dueKanjiReviewCount} kanji lain masih menunggu ulangan.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ReviewAutoNextIndicator extends StatelessWidget {
  const _ReviewAutoNextIndicator();

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

class _ReviewAnswerButton extends StatelessWidget {
  const _ReviewAnswerButton({
    required this.text,
    required this.characterMode,
    required this.selected,
    required this.reveal,
    required this.correct,
    required this.onPressed,
  });

  final String text;
  final bool characterMode;
  final bool selected;
  final bool reveal;
  final bool correct;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (reveal && correct) color = AppTheme.success;
    if (reveal && selected && !correct) {
      color = Theme.of(context).colorScheme.error;
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        alignment: Alignment.center,
        side: color == null ? null : BorderSide(color: color, width: 2),
        foregroundColor: color,
        backgroundColor: color?.withValues(alpha: .08),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: characterMode ? 29 : 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
