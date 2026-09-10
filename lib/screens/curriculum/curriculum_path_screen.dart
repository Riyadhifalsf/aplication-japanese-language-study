import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../kana/kana_screen.dart';
import 'curriculum_lesson_detail_screen.dart';

class CurriculumPathScreen extends StatefulWidget {
  const CurriculumPathScreen({super.key, this.initialLevel = 'N5'});

  final String initialLevel;

  @override
  State<CurriculumPathScreen> createState() => _CurriculumPathScreenState();
}

class _CurriculumPathScreenState extends State<CurriculumPathScreen> {
  late String _levelId;

  @override
  void initState() {
    super.initState();
    _levelId = _validLevel(widget.initialLevel);
  }

  String _validLevel(String value) {
    const ids = {'N5', 'N4', 'N3', 'N2', 'N1'};
    return ids.contains(value) ? value : 'N5';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = CurriculumCatalogData.fullLevels.firstWhere(
      (item) => item.id == _levelId,
      orElse: () => CurriculumCatalogData.fullLevels.first,
    );
    final units = [...level.units]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final progress = app.curriculumLevelProgress(level.id);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              tooltip: 'Ringkasan progres ${level.id}',
              onPressed: () => _showProgressSheet(context, app, level),
              icon: const Icon(Icons.menu_book_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ganti level',
              onSelected: (id) {
                setState(() => _levelId = id);
                app.setCurriculumActiveLevel(id);
              },
              itemBuilder: (_) => [
                for (final id in const ['N5', 'N4', 'N3', 'N2', 'N1'])
                  PopupMenuItem<String>(
                    value: id,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(id,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900)),
                        ),
                        if (id == level.id)
                          const Icon(Icons.check_rounded, size: 18),
                      ],
                    ),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(level.id,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w900)),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          _LearningHero(level: level, progress: progress),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _KanaCard(
                    label: 'Hiragana', symbol: 'あ', onTap: _openKana),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KanaCard(
                    label: 'Katakana', symbol: 'ア', onTap: _openKana),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Semua bab ${level.id}',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            'Pilih bab langsung. Setiap bab berisi sub-bab berurutan: 1.1 → 1.2 → 1.3 dan seterusnya.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (units.isEmpty)
            const _EmptyCurriculum()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                final width =
                    (constraints.maxWidth - ((cols - 1) * 12)) / cols;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < units.length; i++)
                      SizedBox(
                        width: width,
                        child: _ChapterCard(
                          unit: units[i],
                          status: app.curriculumStatuses(level.id),
                          onTap: () => _showChapterSheet(
                              context, app, level, units[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _openKana(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KanaScreen()),
    );
  }

  void _showProgressSheet(
      BuildContext context, AppController app, CurriculumLevel level) {
    final progress = app.curriculumLevelProgress(level.id);
    final value = progress.percent.clamp(0.0, 1.0).toDouble();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    CircleAvatar(
                      radius: 57,
                      child: Icon(Icons.menu_book_rounded,
                          size: 52, color: Theme.of(context).colorScheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .12),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text('${(value * 100).round()}%',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Progress ${level.id}',
                  style: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                '${progress.completedLessons} dari ${progress.totalLessons} sub-bab selesai.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChapterSheet(BuildContext context, AppController app,
      CurriculumLevel level, CurriculumUnit unit) {
    final statuses = app.curriculumStatuses(level.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .68,
          maxChildSize: .94,
          minChildSize: .40,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Text('Bab ${unit.sequence}',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(unit.title,
                  style: TextStyle(
                      fontSize: 17,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              for (var i = 0; i < unit.lessons.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SubchapterCard(
                    number: '${unit.sequence}.${i + 1}',
                    lesson: unit.lessons[i],
                    status: statuses[unit.lessons[i].id] ??
                        CurriculumLessonStatus.locked,
                    onTap: () {
                      app.setCurriculumActiveLesson(unit.lessons[i].id);
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CurriculumLessonDetailScreen(
                              lessonId: unit.lessons[i].id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningHero extends StatelessWidget {
  const _LearningHero({required this.level, required this.progress});
  final CurriculumLevel level;
  final UserLevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = progress.percent.clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(level.subtitle,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Text('${(value * 100).round()}%',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary)),
          ],
        ),
      ),
    );
  }
}

class _KanaCard extends StatelessWidget {
  const _KanaCard({required this.label, required this.symbol, required this.onTap});
  final String label;
  final String symbol;
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onTap(context),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: [
                Text(symbol,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800))),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.unit, required this.status, required this.onTap});
  final CurriculumUnit unit;
  final Map<String, CurriculumLessonStatus> status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = unit.lessons.where((lesson) {
      final s = status[lesson.id];
      return s == CurriculumLessonStatus.completed ||
          s == CurriculumLessonStatus.mastered;
    }).length;
    final percent = unit.lessons.isEmpty ? 0.0 : done / unit.lessons.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                    child: Text('${unit.sequence}',
                        style: const TextStyle(fontWeight: FontWeight.w900))),
                const Spacer(),
                Text('${(percent * 100).round()}%',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 12),
              Text(unit.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              if (unit.subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(unit.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(value: percent),
              const SizedBox(height: 8),
              Text('${unit.lessons.length} sub-bab',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubchapterCard extends StatelessWidget {
  const _SubchapterCard({required this.number, required this.lesson, required this.status, required this.onTap});
  final String number;
  final CurriculumLesson lesson;
  final CurriculumLessonStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = status == CurriculumLessonStatus.completed ||
        status == CurriculumLessonStatus.mastered;
    final locked = status == CurriculumLessonStatus.locked;
    return Card(
      child: ListTile(
        onTap: locked ? null : onTap,
        leading: CircleAvatar(
          backgroundColor: done
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
        ),
        title: Text(lesson.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(lesson.subtitle),
        trailing: Icon(done
            ? Icons.check_circle_rounded
            : locked
                ? Icons.lock_rounded
                : Icons.arrow_forward_ios_rounded),
      ),
    );
  }
}

class _EmptyCurriculum extends StatelessWidget {
  const _EmptyCurriculum();
  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Materi belum tersedia.'),
        ),
      );
}
