import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../features/learning/domain/learning_engine.dart';
import '../../features/learning/domain/learning_models.dart';
import '../../state/app_controller.dart';
import '../curriculum/curriculum_lesson_detail_screen.dart';
import '../kanji/kanji_review_screen.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = CurriculumCatalogData.fullLevels.firstWhere(
      (item) => item.id == app.curriculumActiveLevelId,
      orElse: () => CurriculumCatalogData.fullLevels.first,
    );
    final now = DateTime.now();
    final plan = app.learningEngine.buildDailyPlan(
      level: level.id,
      dailyMinutes: app.dailyStudyMinutes,
      now: now,
    );
    final due = app.learningEngine.dueReviews(now);
    final weak = app.learningEngine.weaknesses(limit: 3);
    final units = [...level.units]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final progress = app.curriculumLevelProgress(level.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _Header(level: level, progress: progress),
        const SizedBox(height: 16),
        _DailyPlanCard(
          plan: plan,
          onLesson: (lessonId) => _openLesson(context, lessonId),
          onReview: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KanjiReviewScreen()),
          ),
        ),
        const SizedBox(height: 16),
        if (due.isNotEmpty || weak.isNotEmpty)
          _AdaptiveInsights(dueCount: due.length, weaknesses: weak),
        if (due.isNotEmpty || weak.isNotEmpty) const SizedBox(height: 16),
        Text(
          'Learning Path',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        for (final unit in units)
          _UnitCard(
            unit: unit,
            app: app,
            onOpen: () => _openUnit(context, unit),
          ),
      ],
    );
  }

  void _openLesson(BuildContext context, String? lessonId) {
    if (lessonId == null || lessonId.isEmpty) return;
    final app = AppScope.of(context);
    app.setCurriculumActiveLesson(lessonId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumLessonDetailScreen(lessonId: lessonId),
      ),
    );
  }

  void _openUnit(BuildContext context, CurriculumUnit unit) {
    final app = AppScope.of(context);
    final lessons = [...unit.lessons]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (lessons.isEmpty) return;
    final next = lessons.firstWhere(
      (lesson) {
        final status = app.curriculumLessonStatus(lesson);
        return status != CurriculumLessonStatus.completed &&
            status != CurriculumLessonStatus.mastered;
      },
      orElse: () => lessons.first,
    );
    _openLesson(context, next.id);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.level, required this.progress});

  final CurriculumLevel level;
  final UserLevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.percent.clamp(0.0, 1.0) * 100).round();
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEARNING PATH',
            style: TextStyle(
              color: cs.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Jalur belajar ${level.id}',
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${progress.completedLessons}/${progress.totalLessons} lesson selesai · $percent%',
            style: TextStyle(color: cs.onPrimary.withOpacity(.82)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.percent.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: cs.onPrimary.withOpacity(.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyPlanCard extends StatelessWidget {
  const _DailyPlanCard({
    required this.plan,
    required this.onLesson,
    required this.onReview,
  });

  final DailyPlan plan;
  final ValueChanged<String?> onLesson;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.auto_awesome_rounded)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rencana belajar hari ini',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Dipilih dari progres, kelemahan, dan review yang jatuh tempo.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (plan.items.isEmpty)
              const Text(
                'Belum ada rekomendasi. Mulai lesson berikutnya untuk membangun data adaptif.',
              )
            else
              for (final item in plan.items)
                _PlanRow(
                  item: item,
                  onTap: item.kind == DailyPlanKind.review
                      ? onReview
                      : () => onLesson(item.lessonId),
                ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item, required this.onTap});

  final DailyPlanItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.kind) {
      DailyPlanKind.continueLesson => Icons.play_arrow_rounded,
      DailyPlanKind.review => Icons.replay_rounded,
      DailyPlanKind.weakness => Icons.build_circle_rounded,
      DailyPlanKind.application => Icons.forum_rounded,
      DailyPlanKind.challenge => Icons.bolt_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(item.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.estimatedMinutes} mnt',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveInsights extends StatelessWidget {
  const _AdaptiveInsights({required this.dueCount, required this.weaknesses});

  final int dueCount;
  final List<LearningSkill> weaknesses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adaptive insight',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (dueCount > 0)
              Text('$dueCount item perlu diulang agar retensi tetap terjaga.'),
            if (weaknesses.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Skill yang diprioritaskan: ${weaknesses.map(_skillLabel).join(', ')}.',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _skillLabel(LearningSkill skill) => switch (skill) {
        LearningSkill.kanji => 'Kanji',
        LearningSkill.vocabulary => 'Kosakata',
        LearningSkill.grammar => 'Grammar',
        LearningSkill.reading => 'Reading',
        LearningSkill.listening => 'Listening',
        LearningSkill.speaking => 'Speaking',
        LearningSkill.writing => 'Writing',
      };
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit, required this.app, required this.onOpen});

  final CurriculumUnit unit;
  final AppController app;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = app.curriculumUnitProgress(unit);
    final fraction = progress.total == 0 ? 0.0 : progress.done / progress.total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Text(
                        '${unit.sequence}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text('${progress.done}/${progress.total} lesson selesai'),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0).toDouble(),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
