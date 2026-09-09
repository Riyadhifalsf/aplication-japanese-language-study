import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import 'curriculum_lesson_detail_screen.dart';

/// Learning Path utama. Semua bab dan sub-bab terlihat langsung secara vertikal.
/// Polanya mengikuti course roadmap modern: progress → level → chapter → lesson.
class ReferenceLearningPathScreen extends StatefulWidget {
  const ReferenceLearningPathScreen({super.key, this.initialLevel = 'N5'});

  final String initialLevel;

  @override
  State<ReferenceLearningPathScreen> createState() =>
      _ReferenceLearningPathScreenState();
}

class _ReferenceLearningPathScreenState
    extends State<ReferenceLearningPathScreen> {
  late String _levelId;

  @override
  void initState() {
    super.initState();
    _levelId = _validLevel(widget.initialLevel);
  }

  String _validLevel(String value) =>
      const {'N5', 'N4', 'N3', 'N2', 'N1'}.contains(value) ? value : 'N5';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = CurriculumCatalogData.fullLevels.firstWhere(
      (item) => item.id == _levelId,
      orElse: () => CurriculumCatalogData.fullLevels.first,
    );
    final levels = CurriculumCatalogData.levelsForTrack('jlpt');
    final units = [...level.units]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final progress = app.curriculumLevelProgress(level.id);
    final nextLesson = app.curriculumNextLesson(level.id);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(level.id, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          _HeaderPill(icon: Icons.local_fire_department_rounded, value: '${app.streak}'),
          const SizedBox(width: 8),
          _HeaderPill(icon: Icons.check_circle_outline_rounded, value: '${progress.completedLessons}'),
          const SizedBox(width: 16),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            sliver: SliverToBoxAdapter(
              child: _CourseHeader(
                level: level,
                progress: progress,
                nextLesson: nextLesson,
                onContinue: nextLesson == null
                    ? null
                    : () => _openLesson(context, app, nextLesson),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: _LevelRail(
                levels: levels,
                selectedId: level.id,
                app: app,
                onTap: (id) {
                  setState(() => _levelId = id);
                  app.setCurriculumActiveLevel(id);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
            sliver: SliverList.builder(
              itemCount: units.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _ChapterCard(
                  unit: units[index],
                  index: index,
                  app: app,
                  onOpenLesson: (lesson) => _openLesson(context, app, lesson),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLesson(
      BuildContext context, AppController app, CurriculumLesson lesson) {
    app.setCurriculumActiveLesson(lesson.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({
    required this.level,
    required this.progress,
    required this.nextLesson,
    required this.onContinue,
  });

  final CurriculumLevel level;
  final UserLevelProgress progress;
  final CurriculumLesson? nextLesson;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = (progress.percent * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: .72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(level.subtitle, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))),
          Text('$percent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
        const SizedBox(height: 7),
        Text(level.title, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        if (level.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(level.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.35)),
        ],
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.percent.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 7),
        Text('${progress.completedLessons}/${progress.totalLessons} lesson selesai', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        if (nextLesson != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: cs.primary),
              onPressed: onContinue,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Lanjut · ${nextLesson!.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _LevelRail extends StatelessWidget {
  const _LevelRail({required this.levels, required this.selectedId, required this.app, required this.onTap});
  final List<CurriculumLevel> levels;
  final String selectedId;
  final AppController app;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: levels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final level = levels[index];
            final selected = level.id == selectedId;
            final unlocked = app.isCurriculumLevelUnlocked(level.id);
            return ChoiceChip(
              selected: selected,
              label: Text(level.id, style: const TextStyle(fontWeight: FontWeight.w900)),
              avatar: Icon(unlocked ? Icons.menu_book_rounded : Icons.lock_rounded, size: 17),
              onSelected: unlocked ? (_) => onTap(level.id) : null,
            );
          },
        ),
      );
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.unit, required this.index, required this.app, required this.onOpenLesson});
  final CurriculumUnit unit;
  final int index;
  final AppController app;
  final ValueChanged<CurriculumLesson> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final lessons = [...unit.lessons]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final progress = app.curriculumUnitProgress(unit);
    final done = progress.total > 0 && progress.done >= progress.total;
    final cs = Theme.of(context).colorScheme;
    final accent = [cs.primary, cs.tertiary, cs.secondary][index % 3];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .55)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accent.withValues(alpha: .14), shape: BoxShape.circle),
              child: done
                  ? Icon(Icons.check_rounded, color: accent, size: 26)
                  : Text('${unit.sequence}', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: accent)),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BAB ${unit.sequence}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: accent)),
              const SizedBox(height: 3),
              Text(unit.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              if (unit.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(unit.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, height: 1.35)),
              ],
              const SizedBox(height: 8),
              Text('${progress.done}/${progress.total} lesson', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
            ]),
          ]),
        ),
        if (lessons.isNotEmpty)
          for (var i = 0; i < lessons.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 18, endIndent: 18, color: cs.outlineVariant.withValues(alpha: .4)),
            _LessonRow(
              lesson: lessons[i],
              number: i + 1,
              app: app,
              isRecommended: _isNext(app, lessons[i]),
              onTap: () => onOpenLesson(lessons[i]),
            ),
          ],
        if (lessons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () => onOpenLesson(_nextLesson(app, lessons) ?? lessons.first),
                icon: Icon(done ? Icons.replay_rounded : Icons.arrow_forward_rounded),
                label: Text(done ? 'Ulangi Bab' : 'Lanjut Bab', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
      ]),
    );
  }

  bool _isNext(AppController app, CurriculumLesson lesson) {
    final status = app.curriculumLessonStatus(lesson);
    return status != CurriculumLessonStatus.completed && status != CurriculumLessonStatus.mastered;
  }

  CurriculumLesson? _nextLesson(AppController app, List<CurriculumLesson> lessons) {
    for (final lesson in lessons) {
      if (_isNext(app, lesson)) return lesson;
    }
    return null;
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.number, required this.app, required this.isRecommended, required this.onTap});
  final CurriculumLesson lesson;
  final int number;
  final AppController app;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = app.curriculumLessonStatus(lesson);
    final completed = status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: completed ? cs.primary : cs.surfaceContainerHighest),
            child: completed ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : Text('$number', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('${lesson.estimatedMinutes} menit${lesson.subtitle.isEmpty ? '' : ' · ${lesson.subtitle}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
          if (isRecommended)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)), child: Text('Lanjut', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary)))
          else
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}
