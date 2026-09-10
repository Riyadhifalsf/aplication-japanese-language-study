import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/exam_question.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class ExamSessionScreen extends StatefulWidget {
  const ExamSessionScreen({required this.plan, super.key});

  final ExamSessionPlan plan;

  @override
  State<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends State<ExamSessionScreen> {
  final Map<int, int> _answers = {};
  final Set<int> _marked = {};
  Timer? _timer;
  late int _remainingSeconds;
  var _index = 0;
  var _finished = false;
  var _recorded = false;

  ExamQuestion get _question => widget.plan.questions[_index];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.plan.minutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      if (_remainingSeconds <= 1) {
        setState(() {
          _remainingSeconds = 0;
          _finished = true;
        });
        _timer?.cancel();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _finished ? _buildResult(context) : _buildQuestion(context),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final q = _question;
    final app = AppScope.of(context);
    final selected = _answers[_index];
    final progress = (_index + 1) / widget.plan.questions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _ExamTopBar(
          title: widget.plan.title,
          progress: progress,
          current: _index + 1,
          total: widget.plan.questions.length,
          timeLeft: _formatTime(_remainingSeconds),
          answered: _answers.length,
          marked: _marked.length,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SectionChip(section: q.section),
            JlptBadge(q.level, compact: true),
            Chip(
              avatar: const Icon(Icons.stars_rounded, size: 16),
              label: Text('${q.point} poin'),
            ),
            if (_marked.contains(_index))
              const Chip(
                avatar: Icon(Icons.bookmark_rounded, size: 16),
                label: Text('Ditandai'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (q.passage != null) ...[
          _PassageCard(text: q.passage!),
          const SizedBox(height: 16),
        ],
        _QuestionCard(
          question: q,
          onPlayAudio: q.hasAudio ? () => app.tts.speak(q.audioText!) : null,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++) ...[
          _OptionButton(
            label: q.options[i],
            index: i,
            selected: selected == i,
            onTap: () => _choose(i),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        _NavigationControls(
          canBack: _index > 0,
          isLast: _index == widget.plan.questions.length - 1,
          marked: _marked.contains(_index),
          onBack: _previous,
          onMark: _toggleMark,
          onNext: _nextOrFinish,
        ),
        const SizedBox(height: 16),
        _QuestionGrid(
          total: widget.plan.questions.length,
          current: _index,
          answers: _answers,
          marked: _marked,
          onJump: (value) => setState(() => _index = value),
        ),
        const SizedBox(height: 10),
        _ExamModeNote(type: widget.plan.examType),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final app = AppScope.of(context);
    final total = widget.plan.questions.length;
    final correct = Iterable<int>.generate(total).where((index) {
      return widget.plan.questions[index].correctIndex == _answers[index];
    }).length;
    final score = total == 0 ? 0 : (correct / total * 100).round();
    final scaled = _estimateScaledResult(widget.plan, _answers);
    final examPassed = scaled.passed;
    final earnedPoints = widget.plan.questions.asMap().entries.fold<int>(0, (sum, entry) {
      final answer = _answers[entry.key];
      return sum + (answer == entry.value.correctIndex ? entry.value.point : 0);
    });

    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          app.recordExamSimulation(
            examType: widget.plan.examType,
            level: widget.plan.level,
            stage: widget.plan.stage,
            correct: correct,
            total: total,
            points: earnedPoints,
          );
        }
      });
    }

    final sections = <ExamSection, List<int>>{};
    for (var i = 0; i < widget.plan.questions.length; i++) {
      sections.putIfAbsent(widget.plan.questions[i].section, () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: examPassed
                  ? const [Color(0xFF17A673), Color(0xFF235CFF)]
                  : const [Color(0xFFFF8A4C), Color(0xFFE64E64)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                examPassed ? 'Lulus simulasi!' : 'Belum aman, ulangi lagi',
                style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.plan.title} · ${widget.plan.questionCountLabel}',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ResultMetric(label: widget.plan.examType == ExamType.jlpt ? 'Skor JLPT' : 'Skor', value: widget.plan.examType == ExamType.jlpt ? '${scaled.totalScore}/180' : '$score%'),
                  _ResultMetric(label: 'Benar', value: '$correct/$total'),
                  _ResultMetric(label: 'Poin', value: '$earnedPoints'),
                  _ResultMetric(label: 'Terjawab', value: '${_answers.length}/$total'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle(
          title: 'Rincian bagian',
          subtitle: widget.plan.examType == ExamType.jlpt
              ? 'Nilai memakai perkiraan skor berskala agar simulasi terasa lebih dekat dengan JLPT.'
              : 'Gunakan rincian ini untuk mengetahui kelemahan pada dokkai, choukai, atau tata bahasa.',
        ),
        const SizedBox(height: 12),
        _ScaledScoreCard(summary: scaled),
        const SizedBox(height: 12),
        for (final entry in sections.entries) ...[
          _SectionResultRow(
            section: entry.key,
            correct: entry.value.where((i) => _answers[i] == widget.plan.questions[i].correctIndex).length,
            total: entry.value.length,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        _OfficialNote(type: widget.plan.examType),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.list_rounded),
                label: const Text('Pilih paket'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => setState(() {
                  _answers.clear();
                  _marked.clear();
                  _index = 0;
                  _finished = false;
                  _recorded = false;
                  _remainingSeconds = widget.plan.minutes * 60;
                  _startTimer();
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Ulangi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _choose(int index) => setState(() => _answers[_index] = index);

  void _previous() {
    if (_index > 0) setState(() => _index--);
  }

  void _toggleMark() {
    setState(() {
      if (_marked.contains(_index)) {
        _marked.remove(_index);
      } else {
        _marked.add(_index);
      }
    });
  }

  void _nextOrFinish() {
    if (_index < widget.plan.questions.length - 1) {
      setState(() => _index++);
    } else {
      _timer?.cancel();
      setState(() => _finished = true);
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}



_ScaledSummary _estimateScaledResult(ExamSessionPlan plan, Map<int, int> answers) {
  int correctIn(Set<ExamSection> allowed) {
    var correct = 0;
    for (var i = 0; i < plan.questions.length; i++) {
      final q = plan.questions[i];
      if (allowed.contains(q.section) && answers[i] == q.correctIndex) {
        correct++;
      }
    }
    return correct;
  }

  int totalIn(Set<ExamSection> allowed) {
    return plan.questions.where((q) => allowed.contains(q.section)).length;
  }

  int scaledScore(int correct, int total, int maxScore) {
    if (total <= 0) return 0;
    return (correct / total * maxScore).round().clamp(0, maxScore).toInt();
  }

  if (plan.examType == ExamType.jft) {
    final sections = <_ScaledSection>[];
    var totalCorrect = 0;
    for (final section in ExamSection.values) {
      final total = totalIn({section});
      if (total == 0) continue;
      final correct = correctIn({section});
      totalCorrect += correct;
      final score = scaledScore(correct, total, 100);
      sections.add(_ScaledSection(
        label: '${examSectionLabel(section)} · ${examSectionIndonesian(section)}',
        score: score,
        maxScore: 100,
        passMark: 60,
        correct: correct,
        total: total,
        passed: score >= 60,
      ));
    }
    final percent = scaledScore(totalCorrect, plan.questions.length, 100);
    return _ScaledSummary(
      examType: plan.examType,
      totalScore: percent,
      totalMax: 100,
      passMark: 60,
      passed: percent >= 60,
      sections: sections,
      note: 'Skor JFT di aplikasi ini adalah estimasi latihan dari persentase benar. Gunakan sebagai simulasi CBT, bukan skor resmi.',
    );
  }

  final languageSections = {ExamSection.mojiGoi, ExamSection.bunpou};
  final readingSections = {ExamSection.dokkai};
  final listeningSections = {ExamSection.choukai};
  final isLower = plan.level == 'N4' || plan.level == 'N5';

  final passMark = switch (plan.level) {
    'N1' => 100,
    'N2' => 90,
    'N3' => 95,
    'N4' => 90,
    'N5' => 80,
    _ => 90,
  };

  final sections = <_ScaledSection>[];
  if (isLower) {
    final combined = {...languageSections, ...readingSections};
    final correct = correctIn(combined);
    final total = totalIn(combined);
    final score = scaledScore(correct, total, 120);
    sections.add(_ScaledSection(
      label: '言語知識・読解 · Kosakata, Tata Bahasa & Bacaan',
      score: score,
      maxScore: 120,
      passMark: 38,
      correct: correct,
      total: total,
      passed: score >= 38,
    ));
  } else {
    final langCorrect = correctIn(languageSections);
    final langTotal = totalIn(languageSections);
    final langScore = scaledScore(langCorrect, langTotal, 60);
    sections.add(_ScaledSection(
      label: '言語知識 · Kosakata & Tata Bahasa',
      score: langScore,
      maxScore: 60,
      passMark: 19,
      correct: langCorrect,
      total: langTotal,
      passed: langScore >= 19,
    ));

    final readCorrect = correctIn(readingSections);
    final readTotal = totalIn(readingSections);
    final readScore = scaledScore(readCorrect, readTotal, 60);
    sections.add(_ScaledSection(
      label: '読解 · Bacaan',
      score: readScore,
      maxScore: 60,
      passMark: 19,
      correct: readCorrect,
      total: readTotal,
      passed: readScore >= 19,
    ));
  }

  final listenCorrect = correctIn(listeningSections);
  final listenTotal = totalIn(listeningSections);
  final listenScore = scaledScore(listenCorrect, listenTotal, 60);
  sections.add(_ScaledSection(
    label: '聴解 · Menyimak',
    score: listenScore,
    maxScore: 60,
    passMark: 19,
    correct: listenCorrect,
    total: listenTotal,
    passed: listenScore >= 19,
  ));

  final totalScore = sections.fold<int>(0, (sum, section) => sum + section.score).clamp(0, 180).toInt();
  final passed = totalScore >= passMark && sections.every((section) => section.passed);

  return _ScaledSummary(
    examType: plan.examType,
    totalScore: totalScore,
    totalMax: 180,
    passMark: passMark,
    passed: passed,
    sections: sections,
    note: 'Ini adalah perkiraan skor berskala untuk latihan. Skor resmi JLPT dihitung memakai metode penyetaraan khusus, jadi hasil aplikasi hanya simulasi yang mendekati format ujian.',
  );
}

class _ScaledSummary {
  const _ScaledSummary({
    required this.examType,
    required this.totalScore,
    required this.totalMax,
    required this.passMark,
    required this.passed,
    required this.sections,
    required this.note,
  });

  final ExamType examType;
  final int totalScore;
  final int totalMax;
  final int passMark;
  final bool passed;
  final List<_ScaledSection> sections;
  final String note;
}

class _ScaledSection {
  const _ScaledSection({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.passMark,
    required this.correct,
    required this.total,
    required this.passed,
  });

  final String label;
  final int score;
  final int maxScore;
  final int passMark;
  final int correct;
  final int total;
  final bool passed;
}

class _ScaledScoreCard extends StatelessWidget {
  const _ScaledScoreCard({required this.summary});

  final _ScaledSummary summary;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    summary.passed ? Icons.verified_rounded : Icons.info_rounded,
                    color: summary.passed ? const Color(0xFF17A673) : const Color(0xFFFF8A4C),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary.examType == ExamType.jlpt
                          ? 'Estimasi nilai JLPT ${summary.totalScore}/${summary.totalMax} · batas ${summary.passMark}'
                          : 'Skor JFT latihan ${summary.totalScore}%',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final section in summary.sections) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${section.score}/${section.maxScore}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: section.passed ? const Color(0xFF17A673) : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: section.maxScore == 0 ? 0 : section.score / section.maxScore,
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                summary.note,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ExamTopBar extends StatelessWidget {
  const _ExamTopBar({
    required this.title,
    required this.progress,
    required this.current,
    required this.total,
    required this.timeLeft,
    required this.answered,
    required this.marked,
  });

  final String title;
  final double progress;
  final int current;
  final int total;
  final String timeLeft;
  final int answered;
  final int marked;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(timeLeft, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 9),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('Soal $current/$total', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Terjawab $answered', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (marked > 0)
                Text('Ditandai $marked', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      );
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.section});

  final ExamSection section;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(_iconFor(section), size: 16),
        label: Text('${examSectionLabel(section)} · ${examSectionIndonesian(section)}'),
      );

  IconData _iconFor(ExamSection section) {
    switch (section) {
      case ExamSection.mojiGoi:
        return Icons.translate_rounded;
      case ExamSection.bunpou:
        return Icons.account_tree_rounded;
      case ExamSection.dokkai:
        return Icons.menu_book_rounded;
      case ExamSection.choukai:
        return Icons.hearing_rounded;
      case ExamSection.conversation:
        return Icons.forum_rounded;
    }
  }
}

class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            text,
            style: const TextStyle(height: 1.55, fontSize: 16),
          ),
        ),
      );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, this.onPlayAudio});

  final ExamQuestion question;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onPlayAudio != null) ...[
              FilledButton.tonalIcon(
                onPressed: onPlayAudio,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Putar suara'),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              question.prompt,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.35),
            ),
          ],
        ),
      );
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant;
    return Card(
      color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: .10) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: color.withValues(alpha: .16),
                foregroundColor: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                child: Text(letter, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
              ),
              if (selected) const Icon(Icons.check_circle_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationControls extends StatelessWidget {
  const _NavigationControls({
    required this.canBack,
    required this.isLast,
    required this.marked,
    required this.onBack,
    required this.onMark,
    required this.onNext,
  });

  final bool canBack;
  final bool isLast;
  final bool marked;
  final VoidCallback onBack;
  final VoidCallback onMark;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canBack ? onBack : null,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Sebelumnya'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onMark,
            icon: Icon(marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            tooltip: 'Tandai',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
              label: Text(isLast ? 'Selesai' : 'Berikutnya'),
            ),
          ),
        ],
      );
}

class _QuestionGrid extends StatelessWidget {
  const _QuestionGrid({
    required this.total,
    required this.current,
    required this.answers,
    required this.marked,
    required this.onJump,
  });

  final int total;
  final int current;
  final Map<int, int> answers;
  final Set<int> marked;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Navigasi soal', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < total; i++)
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          backgroundColor: i == current
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: .12)
                              : answers.containsKey(i)
                                  ? const Color(0xFF17A673).withValues(alpha: .10)
                                  : null,
                          side: BorderSide(
                            color: marked.contains(i)
                                ? const Color(0xFFFF8A4C)
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        onPressed: () => onJump(i),
                        child: Text('${i + 1}', textScaler: TextScaler.noScaling),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ExamModeNote extends StatelessWidget {
  const _ExamModeNote({required this.type});

  final ExamType type;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Mode ujian: jawaban benar tidak ditampilkan sampai selesai. ${type == ExamType.jft ? 'Untuk choukai, berlatihlah seperti ujian komputer: dengarkan suara lalu langsung pilih jawaban.' : 'Kerjakan sesuai urutan bagian dan gunakan penanda untuk soal yang masih diragukan.'}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
        ),
      );
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: 118,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .17),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _SectionResultRow extends StatelessWidget {
  const _SectionResultRow({required this.section, required this.correct, required this.total});

  final ExamSection section;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : correct / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(child: Text(examSectionLabel(section).substring(0, 1))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(examSectionIndonesian(section), style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: value, minHeight: 7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$correct/$total', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _OfficialNote extends StatelessWidget {
  const _OfficialNote({required this.type});

  final ExamType type;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${examTypeLabel(type)} Simulasi ini memakai soal buatan sendiri dengan gaya ujian. Soal resmi atau soal tahun sebelumnya tidak disalin kata demi kata.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
        ),
      );
}
