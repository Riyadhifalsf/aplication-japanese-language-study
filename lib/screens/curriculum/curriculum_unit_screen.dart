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

    void open(CurriculumLesson lesson) {
      app.setCurriculumActiveLesson(lesson.id);
      Navigator.push(context, MaterialPageRoute(builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id)));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bab ${unit.sequence}')),
      body: CustomScrollView(slivers: [
        SliverPadding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 18), sliver: SliverToBoxAdapter(child: _ChapterHero(
          level: level, unit: unit, progress: progress, next: next, onNext: next == null ? null : () => open(next),
        ))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 10), sliver: SliverToBoxAdapter(child: Row(children: [
          Text('Materi Bab ${unit.sequence}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('${lessons.length} sub-bab', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ]))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 34), sliver: SliverList.builder(
          itemCount: lessons.length,
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RichLessonCard(lesson: lessons[index], number: index + 1, app: app, isNext: next?.id == lessons[index].id, onOpen: () => open(lessons[index])),
          ),
        )),
      ]),
    );
  }

  CurriculumLesson? _nextLesson(AppController app, List<CurriculumLesson> lessons) {
    for (final lesson in lessons) {
      final status = app.curriculumLessonStatus(lesson);
      if (status != CurriculumLessonStatus.completed && status != CurriculumLessonStatus.mastered) return lesson;
    }
    return lessons.isEmpty ? null : lessons.last;
  }
}

class _ChapterHero extends StatelessWidget {
  const _ChapterHero({required this.level, required this.unit, required this.progress, required this.next, required this.onNext});
  final CurriculumLevel level;
  final CurriculumUnit unit;
  final dynamic progress;
  final CurriculumLesson? next;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [cs.primaryContainer, cs.surfaceContainerHighest], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(level.id, style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary)), const Spacer(), Text('${progress.done}/${progress.total}', style: const TextStyle(fontWeight: FontWeight.w900))]),
        const SizedBox(height: 8),
        Text('Bab ${unit.sequence}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(unit.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        if (unit.description.isNotEmpty) ...[const SizedBox(height: 7), Text(unit.description, style: const TextStyle(height: 1.45))],
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress.total == 0 ? 0 : (progress.done / progress.total).clamp(0.0, 1.0), minHeight: 8)),
        if (next != null) ...[
          const SizedBox(height: 15),
          SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward_rounded), label: Text('Lanjut · ${next!.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)))),
        ] else ...[
          const SizedBox(height: 13),
          const Text('Semua sub-bab selesai.', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ]),
    );
  }
}

class _RichLessonCard extends StatelessWidget {
  const _RichLessonCard({required this.lesson, required this.number, required this.app, required this.isNext, required this.onOpen});
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
    final activityLabels = lesson.activities.take(4).map((a) => a.title).toList();
    return Card(elevation: isNext ? 1 : 0, clipBehavior: Clip.antiAlias, child: InkWell(onTap: onOpen, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? cs.primary : cs.primaryContainer), child: Center(child: done ? const Icon(Icons.check_rounded, color: Colors.white) : Text('$number', style: const TextStyle(fontWeight: FontWeight.w900)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('Pelajaran $number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.primary)), if (isNext) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(99)), child: const Text('LANJUT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)))]]),
          const SizedBox(height: 4),
          Text(lesson.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ])),
        Icon(done ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: done ? cs.primary : cs.onSurfaceVariant),
      ]),
      if (lesson.subtitle.isNotEmpty) ...[const SizedBox(height: 8), Text(lesson.subtitle, style: TextStyle(color: cs.onSurfaceVariant, height: 1.4))],
      if (lesson.objectives.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('Yang dipelajari', style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
        const SizedBox(height: 5),
        for (final objective in lesson.objectives.take(3)) Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• '), Expanded(child: Text(objective, style: const TextStyle(height: 1.35)))])),
      ],
      if (activityLabels.isNotEmpty) ...[
        const SizedBox(height: 9),
        Wrap(spacing: 7, runSpacing: 7, children: [for (final label in activityLabels) _Tag(label)]),
      ],
      const SizedBox(height: 12),
      Row(children: [
        _Meta(icon: Icons.schedule_rounded, text: '${lesson.estimatedMinutes} mnt'),
        const SizedBox(width: 10),
        _Meta(icon: Icons.layers_rounded, text: '${lesson.activities.length} aktivitas'),
        const Spacer(),
        Text(done ? 'Ulangi' : (isNext ? 'Lanjut' : 'Buka'), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
      ]),
    ]))));
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)));
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))]);
}
