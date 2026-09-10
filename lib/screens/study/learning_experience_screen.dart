import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import 'curriculum_lesson_detail_screen.dart';
import 'curriculum_path_screen.dart';
import 'enriched_curriculum_chapter_screen.dart';
import '../profile/profile_screen.dart';

class LearningExperienceScreen extends StatefulWidget {
  const LearningExperienceScreen({super.key});

  @override
  State<LearningExperienceScreen> createState() => _LearningExperienceScreenState();
}

class _LearningExperienceScreenState extends State<LearningExperienceScreen> {
  String _levelId = 'N5';

  CurriculumLevel get _level => CurriculumCatalogData.fullLevels.firstWhere(
        (item) => item.id == _levelId,
        orElse: () => CurriculumCatalogData.fullLevels.first,
      );

  List<CurriculumLesson> _lessons(CurriculumLevel level) {
    final result = <CurriculumLesson>[];
    final units = [...level.units]..sort((a, b) => a.sequence.compareTo(b.sequence));
    for (final unit in units) {
      final lessons = unit.lessons.where((lesson) => lesson.sequence > 0).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      result.addAll(lessons);
    }
    return result;
  }

  CurriculumUnit? _unitFor(CurriculumLevel level, CurriculumLesson lesson) {
    for (final unit in level.units) {
      if (unit.lessons.any((item) => item.id == lesson.id)) return unit;
    }
    return null;
  }

  Future<void> _openLesson(AppController app, CurriculumLesson lesson) async {
    app.setCurriculumActiveLevel(_levelId);
    app.setCurriculumActiveLesson(lesson.id);
    final unit = _unitFor(_level, lesson);
    if (!mounted) return;
    if (unit != null && (_levelId == 'N5' || _levelId == 'N4')) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EnrichedCurriculumChapterScreen(level: _level, unit: unit),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id)),
      );
    }
    if (mounted) setState(() {});
  }

  void _selectLevel(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bahasa Jepang Lengkap', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              for (final level in CurriculumCatalogData.fullLevels)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: CircleAvatar(
                    backgroundColor: level.id == _levelId
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(level.id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  title: Text(level.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${level.units.length} bab'),
                  trailing: level.id == _levelId
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _levelId = level.id);
                    app.setCurriculumActiveLevel(level.id);
                    Navigator.pop(sheetContext);
                  },
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.flag_rounded, size: 19),
                ),
                title: const Text('JFT', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Jalani jalur persiapan JFT dari materi yang sama'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final progress = app.curriculumLevelProgress(_levelId);
    final statuses = app.curriculumStatuses(_levelId);
    final lessons = _lessons(_level);
    final visibleLessons = lessons.take(9).toList();
    final activeIndex = lessons.indexWhere((lesson) {
      final status = statuses[lesson.id] ?? CurriculumLessonStatus.locked;
      return status == CurriculumLessonStatus.inProgress || status == CurriculumLessonStatus.available;
    });
    final currentIndex = activeIndex >= 0 && activeIndex < lessons.length ? activeIndex : 0;
    final currentLesson = lessons.isEmpty ? null : lessons[currentIndex];
    final currentUnit = currentLesson == null ? null : _unitFor(_level, currentLesson);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Text('日', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _selectLevel(context, app),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_level.id, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                              const Icon(Icons.keyboard_arrow_down_rounded),
                            ],
                          ),
                        ),
                        Text(_level.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Profil',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    icon: const Icon(Icons.person_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.percent.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text(
                '${(progress.percent * 100).round()}% selesai · ${_level.units.length} bab',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text('Bab ${currentUnit?.sequence ?? 1}', style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w900)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded),
                        const SizedBox(width: 5),
                        Text('${app.streak}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (currentLesson != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Lanjutkan belajarmu', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(currentLesson.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Sub-bab ${currentLesson.sequence} · ${_level.id}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => _openLesson(app, currentLesson),
                        child: const Text('Lanjut'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: visibleLessons.length,
            itemBuilder: (context, index) {
              final lesson = visibleLessons[index];
              final status = statuses[lesson.id] ?? CurriculumLessonStatus.locked;
              final completed = status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered;
              final locked = status == CurriculumLessonStatus.locked;
              final isCurrent = currentLesson?.id == lesson.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                child: Stack(
                  children: [
                    if (index < visibleLessons.length - 1)
                      Positioned(
                        left: 44,
                        top: 66,
                        bottom: -10,
                        child: Container(
                          width: 4,
                          color: locked ? Theme.of(context).colorScheme.outlineVariant : Theme.of(context).colorScheme.primary.withValues(alpha: .7),
                        ),
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: locked ? null : () => _openLesson(app, lesson),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: isCurrent ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: locked ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primaryContainer,
                              ),
                              child: Center(
                                child: locked
                                    ? const Icon(Icons.lock_rounded, size: 22)
                                    : completed
                                        ? const Icon(Icons.check_circle_rounded, size: 28)
                                        : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (isCurrent) Text('PELAJARAN SELANJUTNYA', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900)),
                                Text(lesson.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: locked ? Theme.of(context).colorScheme.onSurfaceVariant : null)),
                                const SizedBox(height: 5),
                                Text('Bab ${_unitFor(_level, lesson)?.sequence ?? 1} · Sub-bab ${lesson.sequence}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ]),
                            ),
                            Icon(locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded, color: locked ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CurriculumPathScreen(initialLevel: _levelId))),
                icon: const Icon(Icons.alt_route_rounded),
                label: const Text('Lihat semua bab'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
