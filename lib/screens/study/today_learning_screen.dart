import 'package:flutter/material.dart';

import '../../features/learning/domain/learning_engine.dart';
import '../../features/learning/domain/learning_models.dart';
import '../../state/app_controller.dart';

/// Satu pintu untuk misi belajar hari ini. Layar ini tidak menawarkan katalog
/// acak: setiap kartu menerangkan apa yang diprioritaskan dan alasannya.
class TodayLearningScreen extends StatelessWidget {
  const TodayLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final plan = app.dailyLearningPlan();
    final lesson = plan.currentLesson;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Misi hari ini')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, const Color(0xFF4A1110)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.level} · ${lesson == null ? 'Review dan pertahankan' : 'Unit saat ini'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson?.title ?? 'Misi inti sudah selesai',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  lesson == null
                      ? 'Lanjutkan review terjadwal sambil menunggu lesson berikutnya tersedia.'
                      : 'Setelah selesai: mastery gate menentukan apakah lesson berikutnya terbuka.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Urutan belajarmu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            'Dihasilkan dari kurikulum, review jatuh tempo, dan kesalahanmu.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < plan.items.length; index++)
            _MissionCard(
              number: index + 1,
              item: plan.items[index],
              onTap: () => _openMission(context, app, plan.items[index]),
            ),
          if (plan.items.isEmpty) const _EmptyMissionCard(),
          const SizedBox(height: 16),
          _MasterySnapshot(app: app, lesson: lesson),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.errorContainer,
                child: Icon(Icons.bookmark_remove_outlined,
                    color: scheme.onErrorContainer),
              ),
              title: const Text('My Mistakes',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                app.learningMistakes().isEmpty
                    ? 'Belum ada kesalahan tersimpan dari lesson terstruktur.'
                    : '${app.learningMistakes().length} konsep perlu diperkuat secara terarah.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LearningMistakesScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMission(
      BuildContext context, AppController app, DailyPlanItem item) {
    switch (item.kind) {
      case DailyPlanKind.continueLesson:
      case DailyPlanKind.application:
        final lesson =
            item.lessonId == null ? null : app.learningLesson(item.lessonId!);
        if (lesson != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => LessonSessionScreen(lesson: lesson)),
          );
        }
      case DailyPlanKind.review:
        final questions = app.dueLearningReviewQuestions();
        if (questions.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => LearningReviewScreen(questions: questions)),
          );
        }
      case DailyPlanKind.weakness:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LearningMistakesScreen()),
        );
      case DailyPlanKind.challenge:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Selesaikan misi inti dulu; tantangan bersifat opsional.')),
        );
    }
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard(
      {required this.number, required this.item, required this.onTap});

  final int number;
  final DailyPlanItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (item.kind) {
      DailyPlanKind.continueLesson => Icons.play_lesson_rounded,
      DailyPlanKind.review => Icons.refresh_rounded,
      DailyPlanKind.weakness => Icons.track_changes_rounded,
      DailyPlanKind.application => Icons.forum_rounded,
      DailyPlanKind.challenge => Icons.rocket_launch_outlined,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text('$number',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: scheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(item.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(item.reason,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, height: 1.3)),
                    const SizedBox(height: 8),
                    Text(
                      '${item.estimatedMinutes} menit${item.count > 0 ? ' · ${item.count} item' : ''}',
                      style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMissionCard extends StatelessWidget {
  const _EmptyMissionCard();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Tidak ada item wajib saat ini. Kamu boleh meninjau kesalahan atau mempertahankan materi yang sudah dipelajari.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4),
          ),
        ),
      );
}

class _MasterySnapshot extends StatelessWidget {
  const _MasterySnapshot({required this.app, required this.lesson});

  final AppController app;
  final LessonDefinition? lesson;

  @override
  Widget build(BuildContext context) {
    final activeLesson = lesson;
    if (activeLesson == null) return const SizedBox.shrink();
    final gate = app.learningEngine.gateStatus(activeLesson);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mastery untuk lesson ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              'Completion dan mastery berbeda. Lesson baru terbuka setelah ambang ini terpenuhi.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3),
            ),
            const SizedBox(height: 12),
            for (final entry in gate.minimums.entries)
              _MasteryRow(
                label: entry.key.label,
                score: gate.scores[entry.key] ?? 0,
                minimum: entry.value,
              ),
          ],
        ),
      ),
    );
  }
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow(
      {required this.label, required this.score, required this.minimum});

  final String label;
  final double score;
  final int minimum;

  @override
  Widget build(BuildContext context) {
    final passed = score >= minimum;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('${score.round()}% / $minimum%',
                  style: TextStyle(
                      color: passed
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0, 1),
              minHeight: 7,
              color: passed ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

class LessonSessionScreen extends StatefulWidget {
  const LessonSessionScreen({required this.lesson, super.key});

  final LessonDefinition lesson;

  @override
  State<LessonSessionScreen> createState() => _LessonSessionScreenState();
}

class _LessonSessionScreenState extends State<LessonSessionScreen> {
  int _questionIndex = 0;
  int? _selectedIndex;
  AnswerEvaluation? _evaluation;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final progress = app.learningEngine.progressFor(widget.lesson.id);
    final phase = progress.currentPhase;
    final questions = widget.lesson.questionsFor(phase);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          _PhaseHeader(phase: phase, lesson: widget.lesson),
          const SizedBox(height: 18),
          if (phase == LessonPhase.introduction) ...[
            _InfoCard(
                title: 'Target yang bisa diuji',
                body: widget.lesson.objectives.first.description),
            const SizedBox(height: 12),
            _InfoCard(
                title: 'Mengapa ini dipelajari sekarang?',
                body: widget.lesson.whyNow),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _advance,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Mulai pelajari konsep'),
            ),
          ] else if (phase == LessonPhase.learn) ...[
            const Text('Materi inti',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final content in widget.lesson.contents)
              Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(_skillIcon(content.skill))),
                  title: Text(content.title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(content.explanation,
                        style: const TextStyle(height: 1.3)),
                  ),
                  trailing: _TierPill(tier: content.tier),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _advance,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Lanjut ke latihan terpandu'),
            ),
          ] else if (questions.isEmpty) ...[
            _InfoCard(
              title: 'Belum ada latihan pada fase ini',
              body:
                  'Kamu dapat melanjutkan; konten baru akan selalu masuk lewat katalog kurikulum, bukan diacak oleh UI.',
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _advance, child: const Text('Lanjutkan')),
          ] else ...[
            if (questions[_questionIndex].scenario != null)
              _ScenarioBanner(text: questions[_questionIndex].scenario!),
            Text(
              '${_questionIndex + 1} / ${questions.length}',
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              questions[_questionIndex].prompt,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w900, height: 1.35),
            ),
            const SizedBox(height: 16),
            for (var index = 0;
                index < questions[_questionIndex].options.length;
                index++)
              _AnswerOption(
                label: questions[_questionIndex].options[index],
                selected: _selectedIndex == index,
                correct: _evaluation == null
                    ? null
                    : index == questions[_questionIndex].correctIndex,
                showResult: _evaluation != null,
                onTap: _evaluation == null
                    ? () => _answer(questions[_questionIndex], index)
                    : null,
              ),
            if (_evaluation != null) ...[
              const SizedBox(height: 10),
              _AnswerFeedback(evaluation: _evaluation!),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => _nextQuestion(questions.length),
                child: Text(_questionIndex + 1 == questions.length
                    ? (phase == LessonPhase.assessment
                        ? 'Evaluasi mastery'
                        : 'Lanjutkan')
                    : 'Soal berikutnya'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _answer(LessonQuestion question, int selectedIndex) {
    final app = AppScope.of(context);
    final evaluation = app.recordLessonAnswer(
        question: question, selectedIndex: selectedIndex);
    setState(() {
      _selectedIndex = selectedIndex;
      _evaluation = evaluation;
    });
  }

  void _nextQuestion(int total) {
    final app = AppScope.of(context);
    final phase = app.learningEngine.progressFor(widget.lesson.id).currentPhase;
    if (_questionIndex + 1 < total) {
      setState(() {
        _questionIndex++;
        _selectedIndex = null;
        _evaluation = null;
      });
      return;
    }
    if (phase == LessonPhase.assessment) {
      _finishAssessment();
      return;
    }
    _advance();
  }

  void _advance() {
    AppScope.of(context).advanceLearningPhase(widget.lesson.id);
    setState(() {
      _questionIndex = 0;
      _selectedIndex = null;
      _evaluation = null;
    });
  }

  Future<void> _finishAssessment() async {
    final app = AppScope.of(context);
    final gate = app.finishLessonAssessment(widget.lesson);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(gate.passed
            ? Icons.workspace_premium_rounded
            : Icons.school_rounded),
        title: Text(
            gate.passed ? 'Lesson dikuasai' : 'Bagian ini perlu diperkuat'),
        content: Text(
          gate.passed
              ? 'Kamu memenuhi mastery gate. Item yang dipelajari telah dijadwalkan untuk review; lesson berikutnya sekarang menjadi langkah utama.'
              : 'Belum memenuhi ambang ${gate.unmetSkills.map((skill) => skill.label.toLowerCase()).join(', ')}. Ulangi latihan yang relevan, lalu coba assessment lagi.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(gate.passed ? 'Selesai' : 'Latihan lagi'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (gate.passed) {
      Navigator.pop(context);
    } else {
      setState(() {
        _questionIndex = 0;
        _selectedIndex = null;
        _evaluation = null;
      });
    }
  }
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({required this.phase, required this.lesson});

  final LessonPhase phase;
  final LessonDefinition lesson;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (LessonPhase.values.indexOf(phase) + 1) /
                LessonPhase.values.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 12),
          Text(phase.label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(lesson.summary,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(body, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      );
}

class _TierPill extends StatelessWidget {
  const _TierPill({required this.tier});

  final ContentTier tier;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(tier.label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
      );
}

class _ScenarioBanner extends StatelessWidget {
  const _ScenarioBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .secondaryContainer
              .withValues(alpha: .65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place_outlined),
            const SizedBox(width: 9),
            Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
          ],
        ),
      );
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.correct,
    required this.showResult,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool? correct;
  final bool showResult;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCorrect = showResult && correct == true;
    final isWrong = showResult && selected && correct == false;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      color: isCorrect
          ? Colors.green.withValues(alpha: .12)
          : (isWrong ? scheme.errorContainer : null),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isCorrect
              ? Icons.check_circle_rounded
              : (isWrong
                  ? Icons.cancel_rounded
                  : Icons.radio_button_unchecked_rounded),
          color: isCorrect ? Colors.green : (isWrong ? scheme.error : null),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.evaluation});
  final AnswerEvaluation evaluation;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: evaluation.correct
              ? Colors.green.withValues(alpha: .12)
              : Theme.of(context)
                  .colorScheme
                  .errorContainer
                  .withValues(alpha: .65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(evaluation.correct ? 'Benar' : 'Belum tepat',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(evaluation.explanation, style: const TextStyle(height: 1.35)),
          ],
        ),
      );
}

class LearningReviewScreen extends StatefulWidget {
  const LearningReviewScreen({required this.questions, super.key});
  final List<LessonQuestion> questions;

  @override
  State<LearningReviewScreen> createState() => _LearningReviewScreenState();
}

class _LearningReviewScreenState extends State<LearningReviewScreen> {
  int _index = 0;
  int? _selected;
  AnswerEvaluation? _evaluation;

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Scaffold(
          body: Center(
              child: Text('Tidak ada review yang dapat dikerjakan saat ini.')));
    }
    final question = widget.questions[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Review terjadwal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          LinearProgressIndicator(
              value: (_index + 1) / widget.questions.length, minHeight: 8),
          const SizedBox(height: 18),
          Text('Review ${_index + 1} dari ${widget.questions.length}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text(question.prompt,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w900, height: 1.35)),
          const SizedBox(height: 14),
          for (var index = 0; index < question.options.length; index++)
            _AnswerOption(
              label: question.options[index],
              selected: _selected == index,
              correct:
                  _evaluation == null ? null : index == question.correctIndex,
              showResult: _evaluation != null,
              onTap:
                  _evaluation == null ? () => _answer(question, index) : null,
            ),
          if (_evaluation != null) ...[
            const SizedBox(height: 10),
            _AnswerFeedback(evaluation: _evaluation!),
            const SizedBox(height: 14),
            FilledButton(
                onPressed: _next,
                child: Text(_index + 1 == widget.questions.length
                    ? 'Selesai review'
                    : 'Berikutnya')),
          ],
        ],
      ),
    );
  }

  void _answer(LessonQuestion question, int index) {
    final evaluation = AppScope.of(context).recordLessonAnswer(
        question: question, selectedIndex: index, review: true);
    setState(() {
      _selected = index;
      _evaluation = evaluation;
    });
  }

  void _next() {
    if (_index + 1 == widget.questions.length) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _evaluation = null;
    });
  }
}

class LearningMistakesScreen extends StatefulWidget {
  const LearningMistakesScreen({super.key});

  @override
  State<LearningMistakesScreen> createState() => _LearningMistakesScreenState();
}

class _LearningMistakesScreenState extends State<LearningMistakesScreen> {
  LearningSkill? _filter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mistakes = app.learningMistakes(skill: _filter);
    return Scaffold(
      appBar: AppBar(title: const Text('My Mistakes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          const Text(
              'Kesalahan disimpan per konsep agar remedial fokus, bukan sekadar mengulang semua materi.',
              style: TextStyle(height: 1.4)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                    label: const Text('Semua'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null)),
                for (final skill in LearningSkill.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                        label: Text(skill.label),
                        selected: _filter == skill,
                        onSelected: (_) => setState(() => _filter = skill)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (mistakes.isEmpty)
            const _EmptyMissionCard()
          else
            for (final mistake in mistakes)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(_contentTitle(app, mistake.conceptId),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900))),
                          Chip(
                              label: Text(mistake.skill.label),
                              visualDensity: VisualDensity.compact),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(mistake.lastPrompt,
                          style: const TextStyle(height: 1.3)),
                      const SizedBox(height: 10),
                      Text('Jawabanmu: ${mistake.lastAnswer}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                      Text('Jawaban benar: ${mistake.correctAnswer}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('${mistake.mistakeCount} kali perlu diperkuat',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _contentTitle(AppController app, String id) {
    for (final lesson in app.learningEngine.catalog.lessons) {
      for (final content in lesson.contents) {
        if (content.id == id) return content.title;
      }
    }
    return id;
  }
}

IconData _skillIcon(LearningSkill skill) => switch (skill) {
      LearningSkill.vocabulary => Icons.menu_book_rounded,
      LearningSkill.grammar => Icons.account_tree_rounded,
      LearningSkill.kanji => Icons.translate_rounded,
      LearningSkill.listening => Icons.headphones_rounded,
      LearningSkill.reading => Icons.auto_stories_rounded,
      LearningSkill.speaking => Icons.mic_rounded,
      LearningSkill.writing => Icons.edit_rounded,
    };
