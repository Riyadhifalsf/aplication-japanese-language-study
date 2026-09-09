import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../quiz/reference_quiz_screen.dart';
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
    final firstLesson = lessons.isEmpty ? null : lessons.first;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Bab ${unit.sequence}')),
      body: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          sliver: SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: color.secondaryContainer),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(level.id, style: TextStyle(fontWeight: FontWeight.w900, color: color.primary)),
              const SizedBox(height: 4),
              Text('Bab ${unit.sequence}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(unit.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              if (unit.description.isNotEmpty) ...[const SizedBox(height: 7), Text(unit.description)],
              const SizedBox(height: 14),
              Text('${progress.done}/${progress.total} pelajaran selesai', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress.total == 0 ? 0 : progress.done / progress.total, minHeight: 8)),
              if (firstLesson != null) ...[
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReferenceQuizScreen(lessonId: firstLesson.id))),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('MULAI LATIHAN', style: TextStyle(fontWeight: FontWeight.w900)),
                )),
              ],
            ]),
          )),
        ),
        const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 18), sliver: SliverToBoxAdapter(child: _SectionLabel())),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final lesson = lessons[index];
              final status = app.curriculumLessonStatus(lesson);
              final done = status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered;
              return Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id))),
                  child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Center(child: Text('${lesson.sequence}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color.onPrimaryContainer)))),
                      const Spacer(),
                      Icon(done ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, color: done ? color.primary : color.onSurfaceVariant),
                    ]),
                    const Spacer(),
                    Text('Pelajaran ${lesson.sequence}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color.primary)),
                    const SizedBox(height: 4),
                    Text(lesson.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    if (lesson.subtitle.isNotEmpty) ...[const SizedBox(height: 4), Text(lesson.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis)],
                    const SizedBox(height: 8),
                    Text('${lesson.activities.length} aktivitas · ${lesson.estimatedMinutes} menit', style: TextStyle(fontSize: 12, color: color.onSurfaceVariant)),
                  ])),
                ),
              );
            }, childCount: lessons.length),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 430, mainAxisExtent: 190, crossAxisSpacing: 12, mainAxisSpacing: 12),
          ),
        ),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text('Belajar dengan praktik', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
    ]),
  );
}
