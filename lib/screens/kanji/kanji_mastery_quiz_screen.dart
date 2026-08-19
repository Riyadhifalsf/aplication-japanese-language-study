import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

enum KanjiMasteryMode { meaning, reading, character }

class KanjiMasteryQuizScreen extends StatefulWidget {
  const KanjiMasteryQuizScreen({
    required this.level,
    super.key,
    this.sessionSize = 10,
  });

  final String level;
  final int sessionSize;

  @override
  State<KanjiMasteryQuizScreen> createState() =>
      _KanjiMasteryQuizScreenState();
}

class _KanjiMasteryQuizScreenState
    extends State<KanjiMasteryQuizScreen> {
  final _random = math.Random();
  Timer? _autoNextTimer;
  final List<Kanji> _queue = [];
  List<Kanji> _targets = const [];
  List<Kanji> _choices = const [];
  List<KanjiMasteryMode> _sessionModes = const [
    KanjiMasteryMode.meaning,
    KanjiMasteryMode.reading,
    KanjiMasteryMode.character,
  ];
  Kanji? _current;
  KanjiMasteryMode _mode = KanjiMasteryMode.meaning;
  KanjiMasteryResult? _lastResult;
  int? _selectedId;
  int _questionNumber = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _answerStreak = 0;
  int _bestAnswerStreak = 0;
  bool _initialized = false;
  bool _finished = false;
  bool _allLevelMastered = false;

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _startSession(AppScope.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (_allLevelMastered) return _allMasteredScreen(context, app);
    if (_finished) return _sessionResult(context, app);
    final current = _current;
    if (current == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentStreak = app.kanjiMasteryStreak(current.id);
    final masteredInSession = _targets
        .where((item) => app.isKanjiMastered(item.id))
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Uji Penguasaan ${widget.level}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: JlptBadge(widget.level)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        children: [
          Card(
            color: AppTheme.seed.withValues(alpha: .08),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_rounded, color: AppTheme.seed),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jawab kanji yang sama 3× berturut-turut dengan benar. '
                      'Jika salah, progres kanji itu kembali ke 0 dan akan '
                      'muncul lagi.',
                      style: TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuizStat(
                  value: '$masteredInSession/${_targets.length}',
                  label: 'Lulus sesi',
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuizStat(
                  value: '$_answerStreak',
                  label: 'Rentetan',
                  color: const Color(0xFFFFA62B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuizStat(
                  value: '$_wrongAnswers',
                  label: 'Salah',
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _targets.isEmpty
                  ? 0.0
                  : masteredInSession / _targets.length,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                        fontSize: _mode == KanjiMasteryMode.character ? 34 : 78,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_mode != KanjiMasteryMode.character)
                    IconButton.filledTonal(
                      tooltip: 'Dengarkan bacaan',
                      onPressed: () =>
                          app.tts.speak(current.preferredReading),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  const SizedBox(height: 15),
                  Text(
                    'Progres kanji ini',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0;
                          index < AppController.kanjiMasteryThreshold;
                          index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 44,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index < currentStreak
                                ? AppTheme.success
                                : Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$currentStreak/${AppController.kanjiMasteryThreshold} benar berturut-turut',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final choice in _choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MasteryAnswerButton(
                text: _answerText(choice),
                characterMode: _mode == KanjiMasteryMode.character,
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
                          : Icons.cancel_rounded,
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
              const _AutoNextIndicator()
            else
              FilledButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Saya sudah paham, lanjutkan'),
              ),
          ],
        ],
      ),
    );
  }

  String get _prompt => switch (_mode) {
        KanjiMasteryMode.meaning => 'Pilih arti kanji yang benar',
        KanjiMasteryMode.reading => 'Pilih bacaan kanji yang benar',
        KanjiMasteryMode.character => 'Pilih kanji yang sesuai dengan arti',
      };

  String _questionText(Kanji item) =>
      _mode == KanjiMasteryMode.character
          ? item.meaning
          : item.character;

  String _answerText(Kanji item) => switch (_mode) {
        KanjiMasteryMode.meaning => item.meaning,
        KanjiMasteryMode.reading => item.preferredReading,
        KanjiMasteryMode.character => item.character,
      };

  String _feedback(Kanji current) {
    final result = _lastResult!;
    if (result.justMastered) {
      return 'Benar! ${current.character} resmi dikuasai. '
          'Kartunya sekarang diberi warna gelap di daftar kanji.';
    }
    if (result.correct) {
      return 'Benar! Progres ${current.character} menjadi '
          '${result.streak}/${AppController.kanjiMasteryThreshold}.';
    }
    return 'Belum tepat. Jawabannya ${_answerText(current)}. '
        'Progres ${current.character} direset ke 0 dan akan ditanyakan lagi.';
  }

  void _startSession(AppController app) {
    _autoNextTimer?.cancel();
    final eligible = app.repository
        .kanjiForLevel(widget.level)
        .where(
          (item) =>
              item.hasCompleteMetadata &&
              item.preferredReading.isNotEmpty,
        )
        .toList(growable: false);
    final candidates = eligible
        .where((item) => !app.isKanjiMastered(item.id))
        .toList();
    candidates.sort((a, b) {
      final streakCompare = app
          .kanjiMasteryStreak(b.id)
          .compareTo(app.kanjiMasteryStreak(a.id));
      return streakCompare != 0 ? streakCompare : a.id.compareTo(b.id);
    });

    _allLevelMastered = candidates.isEmpty;
    _finished = false;
    _questionNumber = 0;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    _answerStreak = 0;
    _bestAnswerStreak = 0;
    _selectedId = null;
    _lastResult = null;
    _targets = candidates.take(widget.sessionSize).toList(growable: false);
    _sessionModes = KanjiMasteryMode.values
        .where((mode) => _distinctAnswerCount(eligible, mode) >= 4)
        .toList(growable: false);
    if (_sessionModes.isEmpty) {
      _sessionModes = const [KanjiMasteryMode.character];
    }
    _queue
      ..clear()
      ..addAll(_targets);
    if (_queue.isNotEmpty) _prepareQuestion(app);
  }

  void _prepareQuestion(AppController app) {
    if (_queue.isEmpty) {
      _finished = true;
      _current = null;
      _choices = const [];
      return;
    }
    _current = _queue.removeAt(0);
    _mode = _sessionModes[_questionNumber % _sessionModes.length];
    _choices = _buildChoices(app, _current!);
  }

  int _distinctAnswerCount(
    List<Kanji> items,
    KanjiMasteryMode mode,
  ) =>
      items.map((item) {
        return switch (mode) {
          KanjiMasteryMode.meaning => item.meaning,
          KanjiMasteryMode.reading => item.preferredReading,
          KanjiMasteryMode.character => item.character,
        };
      }).toSet().length;

  List<Kanji> _buildChoices(AppController app, Kanji correct) {
    final pool = app.repository
        .kanjiForLevel(widget.level)
        .where(
          (item) =>
              item.hasCompleteMetadata &&
              item.id != correct.id,
        )
        .toList(growable: false);
    final stableRandom =
        math.Random(correct.id * 97 + _questionNumber * 31 + _mode.index);
    final output = <Kanji>[correct];
    final usedAnswers = <String>{_answerText(correct)};
    if (pool.isNotEmpty) {
      final start = stableRandom.nextInt(pool.length);
      for (var offset = 0;
          offset < pool.length && output.length < 4;
          offset++) {
        final item = pool[(start + offset * 37) % pool.length];
        if (usedAnswers.add(_answerText(item))) output.add(item);
      }
    }
    if (output.length < 4) {
      for (final item in app.repository.kanji) {
        if (item.id == correct.id || !item.hasCompleteMetadata) continue;
        if (usedAnswers.add(_answerText(item))) output.add(item);
        if (output.length == 4) break;
      }
    }
    output.shuffle(_random);
    return output;
  }

  void _answer(Kanji choice) {
    final current = _current!;
    final correct = choice.id == current.id;
    final app = AppScope.of(context);
    final result = app.recordKanjiMasteryAnswer(
      kanjiId: current.id,
      correct: correct,
    );
    app.tts.speak(current.preferredReading);
    setState(() {
      _selectedId = choice.id;
      _lastResult = result;
      if (correct) {
        _correctAnswers++;
        _answerStreak++;
        _bestAnswerStreak = math.max(_bestAnswerStreak, _answerStreak);
      } else {
        _wrongAnswers++;
        _answerStreak = 0;
      }
      if (!result.mastered) {
        final spacing = correct ? 2 : 1;
        _queue.insert(math.min(spacing, _queue.length), current);
      }
    });
    if (correct) {
      _autoNextTimer?.cancel();
      _autoNextTimer = Timer(const Duration(milliseconds: 850), () {
        if (mounted) _nextQuestion();
      });
    }
  }

  void _nextQuestion() {
    _autoNextTimer?.cancel();
    final app = AppScope.of(context);
    setState(() {
      _questionNumber++;
      _selectedId = null;
      _lastResult = null;
      _prepareQuestion(app);
    });
  }

  Widget _sessionResult(BuildContext context, AppController app) {
    final levelItems = app.repository.kanjiForLevel(widget.level);
    final levelTotal = levelItems.length;
    final levelMastered = levelItems
        .where(
          (item) => app.isKanjiMastered(item.id),
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: Text('Hasil Penguasaan ${widget.level}')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 58,
                backgroundColor: Color(0xFF173B34),
                foregroundColor: Colors.white,
                child: Icon(Icons.verified_rounded, size: 58),
              ),
              const SizedBox(height: 22),
              Text(
                '${_targets.length} kanji dikuasai!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '$_correctAnswers jawaban benar · $_wrongAnswers salah · '
                'rentetan terbaik $_bestAnswerStreak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total penguasaan ${widget.level}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Text('$levelMastered/$levelTotal'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: levelTotal == 0
                              ? 0.0
                              : levelMastered / levelTotal,
                          minHeight: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: levelMastered >= levelTotal
                      ? null
                      : () => setState(() => _startSession(app)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Mulai sesi berikutnya'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke daftar kanji'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _allMasteredScreen(BuildContext context, AppController app) =>
      Scaffold(
        appBar: AppBar(title: Text('Penguasaan ${widget.level}')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 92,
                  color: Color(0xFFFFA62B),
                ),
                const SizedBox(height: 18),
                Text(
                  'Semua kanji ${widget.level} sudah dikuasai!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kamu sudah menjawab setiap kanji dengan benar '
                  '3× berturut-turut.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _QuizStat extends StatelessWidget {
  const _QuizStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              value,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _AutoNextIndicator extends StatelessWidget {
  const _AutoNextIndicator();

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

class _MasteryAnswerButton extends StatelessWidget {
  const _MasteryAnswerButton({
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
