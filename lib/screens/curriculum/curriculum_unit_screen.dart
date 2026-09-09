import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import 'curriculum_lesson_detail_screen.dart';

class CurriculumUnitScreen extends StatelessWidget {
  const CurriculumUnitScreen({super.key, required this.level, required this.unit});

  final CurriculumLevel level;
  final CurriculumUnit unit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lessons = [...unit.lessons]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final progress = app.curriculumUnitProgress(unit);
    final cs = Theme.of(context).colorScheme;
    final next = _nextLesson(app, lessons);

    return Scaffold(
      appBar: AppBar(title: Text('Bab ${unit.sequence}')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.surfaceContainerHighest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(level.id, style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary)),
                  const SizedBox(height: 4),
                  Text('Bab ${unit.sequence}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(unit.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  if (unit.description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(unit.description, style: const TextStyle(height: 1.4)),
                  ],
                  const SizedBox(height: 15),
                  Text('${progress.done}/${progress.total} lesson selesai', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: progress.total == 0 ? 0 : (progress.done / progress.total).clamp(0.0, 1.0), minHeight: 8),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () => _openLesson(context, app, next),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text('Lanjut · ${next.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(child: _SectionLabel()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
            sliver: SliverList.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LessonCard(
                  lesson: lessons[index],
                  number: index + 1,
                  app: app,
                  isNext: next?.id == lessons[index].id,
                  onOpen: () => _openLesson(context, app, lessons[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CurriculumLesson? _nextLesson(AppController app, List<CurriculumLesson> lessons) {
    for (final lesson in lessons) {
      final status = app.curriculumLessonStatus(lesson);
      if (status != CurriculumLessonStatus.completed && status != CurriculumLessonStatus.mastered) return lesson;
    }
    return lessons.isNotEmpty ? lessons.last : null;
  }

  void _openLesson(BuildContext context, AppController app, CurriculumLesson lesson) {
    app.setCurriculumActiveLesson(lesson.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel();
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('Urutan belajar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      ]);
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.number, required this.app, required this.isNext, required this.onOpen});
  final CurriculumLesson lesson;
  final int number;
  final AppController app;
  final bool isNext;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = app.curriculumLessonStatus(lesson);
    final done = status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isNext ? cs.primaryContainer.withValues(alpha: .45) : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isNext ? cs.primary.withValues(alpha: .35) : cs.outlineVariant.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: done ? cs.primary : cs.surfaceContainerHighest),
              child: done ? const Icon(Icons.check_rounded, color: Colors.white) : Text('$number', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pelajaran $number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary)),
              const SizedBox(height: 3),
              Text(lesson.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('${lesson.estimatedMinutes} menit${lesson.subtitle.isEmpty ? '' : ' · ${lesson.subtitle}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ])),
            const SizedBox(width: 8),
            isNext
                ? Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(11)), child: const Text('Lanjut', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)))
                : Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}
