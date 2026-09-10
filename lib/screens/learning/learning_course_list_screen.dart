import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../study/level_placement_screen.dart';
import '../curriculum/curriculum_lesson_detail_screen.dart';

/// Learning utama berbentuk daftar Bab/Chapter.
///
/// Konsep UI: course modern ala Busuu — Bab tampil vertikal sebagai list,
/// setiap Bab bisa dibuka dan memiliki tombol download/simpan offline.
class LearningCourseListScreen extends StatefulWidget {
  const LearningCourseListScreen({super.key, this.initialLevel = 'N5'});

  final String initialLevel;

  @override
  State<LearningCourseListScreen> createState() =>
      _LearningCourseListScreenState();
}

class _LearningCourseListScreenState extends State<LearningCourseListScreen> {
  late String _track;
  late String _levelId;
  final Set<String> _downloadedUnits = <String>{};

  @override
  void initState() {
    super.initState();
    final initial = CurriculumCatalogData.levelById(widget.initialLevel);
    _track = initial?.track ?? 'jlpt';
    _levelId = initial?.id ?? 'N5';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final levels = CurriculumCatalogData.levelsForTrack(_track);

    if (_track == 'jlpt' &&
        {'N5', 'N4', 'N3', 'N2', 'N1'}.contains(app.selectedStudyLevel)) {
      _levelId = app.selectedStudyLevel;
    }

    var level = CurriculumCatalogData.levelById(_levelId);
    if (level == null || level.track != _track) {
      level = levels.isNotEmpty ? levels.first : null;
      if (level != null) _levelId = level.id;
    }

    if (level == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning')),
        body: const EmptyState(
          title: 'Belum ada level',
          message: 'Katalog kurikulum belum tersedia.',
        ),
      );
    }

    final current = level;
    final progress = app.curriculumLevelProgress(current.id);
    final unlocked = app.isCurriculumLevelUnlocked(current.id);
    final units = [...current.units]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
        actions: [
          IconButton(
            tooltip: 'Download semua Bab',
            onPressed: units.isEmpty
                ? null
                : () {
                    setState(() => _downloadedUnits
                        .addAll(units.map((unit) => unit.id)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Semua Bab ditandai untuk offline.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
            icon: const Icon(Icons.download_for_offline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
        children: [
          _CourseHero(
            level: current,
            progress: progress,
            streak: app.streak,
            tierLabel: app.masteryTier.label,
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 14),
          _TrackSelector(
            track: _track,
            onChanged: (value) {
              setState(() {
                _track = value;
                final candidates =
                    CurriculumCatalogData.levelsForTrack(value);
                final firstUnlocked = candidates
                    .where((item) => app.isCurriculumLevelUnlocked(item.id))
                    .firstOrNull;
                final fallback = candidates.firstOrNull;
                _levelId = (firstUnlocked ?? fallback)?.id ?? _levelId;
                app.setCurriculumActiveLevel(_levelId);
                _downloadedUnits.clear();
              });
            },
          ),
          const SizedBox(height: 12),
          if (_track == 'jlpt') ...[
            _LevelSelector(
              levels: levels,
              selectedId: _levelId,
              app: app,
              onTap: (id) {
                final selected = levels.firstWhere((item) => item.id == id);
                if (!app.isCurriculumLevelUnlocked(selected.id)) return;
                setState(() {
                  _levelId = id;
                  _downloadedUnits.clear();
                });
                app.setCurriculumActiveLevel(id);
              },
            ),
            const SizedBox(height: 14),
          ],
          if (!unlocked)
            _LockedPanel(
              level: current,
              onPlacement: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelPlacementScreen(
                    level: current.requiredPreviousLevelId ?? 'N5',
                  ),
                ),
              ),
            )
          else ...[
            _SectionHeading(
              title: '${units.length} Bab',
              subtitle:
                  '${progress.completedLessons}/${progress.totalLessons} sub-bab selesai · ${(progress.percent * 100).round()}%',
            ),
            const SizedBox(height: 10),
            for (final unit in units) ...[
              _ChapterCard(
                unit: unit,
                app: app,
                downloaded: _downloadedUnits.contains(unit.id),
                onDownload: () => _toggleDownload(unit),
                onOpen: () => _openUnit(context, app, unit),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  void _toggleDownload(CurriculumUnit unit) {
    setState(() {
      if (_downloadedUnits.contains(unit.id)) {
        _downloadedUnits.remove(unit.id);
      } else {
        _downloadedUnits.add(unit.id);
      }
    });
    final saved = _downloadedUnits.contains(unit.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? '${unit.title} disimpan untuk offline.'
              : '${unit.title} dihapus dari daftar offline.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openUnit(
    BuildContext context,
    AppController app,
    CurriculumUnit unit,
  ) {
    final lessons = [...unit.lessons]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (lessons.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bab ${unit.sequence} · ${unit.title}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                unit.description.isEmpty
                    ? 'Pilih sub-bab untuk langsung belajar.'
                    : unit.description,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final lesson = lessons[index];
                    final status = app.curriculumLessonStatus(lesson);
                    final done = status == CurriculumLessonStatus.completed ||
                        status == CurriculumLessonStatus.mastered;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: done
                            ? const Icon(Icons.check_rounded)
                            : Text('${index + 1}'),
                      ),
                      title: Text(
                        lesson.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        lesson.subtitle.isEmpty
                            ? '${lesson.activities.length} aktivitas · ${lesson.estimatedMinutes} menit'
                            : lesson.subtitle,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        _openLesson(context, app, lesson);
                      },
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

  void _openLesson(
    BuildContext context,
    AppController app,
    CurriculumLesson lesson,
  ) {
    app.setCurriculumActiveLesson(lesson.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id),
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({
    required this.level,
    required this.progress,
    required this.streak,
    required this.tierLabel,
  });

  final CurriculumLevel level;
  final UserLevelProgress progress;
  final int streak;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (progress.percent.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [scheme.primary, const Color(0xFF302D46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 28,
              ),
              const Spacer(),
              _Pill(
                icon: Icons.local_fire_department_rounded,
                text: '$streak',
              ),
              const SizedBox(width: 8),
              _Pill(icon: Icons.military_tech_rounded, text: tierLabel),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            level.id,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            level.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.percent.clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

class _TrackSelector extends StatelessWidget {
  const _TrackSelector({required this.track, required this.onChanged});

  final String track;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'jlpt',
                label: Text('Japanese'),
                icon: Icon(Icons.school_rounded),
              ),
              ButtonSegment(
                value: 'work',
                label: Text('Work in Japan'),
                icon: Icon(Icons.work_outline_rounded),
              ),
            ],
            selected: {track},
            onSelectionChanged: (value) => onChanged(value.first),
          ),
        ),
      );
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.levels,
    required this.selectedId,
    required this.app,
    required this.onTap,
  });

  final List<CurriculumLevel> levels;
  final String selectedId;
  final AppController app;
  final ValueChanged<String> onTap;

  Color _tone(BuildContext context, String id) {
    final colors = Theme.of(context).colorScheme;
    return switch (id) {
      'N5' => colors.primary,
      'N4' => const Color(0xFF0E7490),
      'N3' => const Color(0xFF7C3AED),
      'N2' => const Color(0xFFB45309),
      'N1' => const Color(0xFFBE123C),
      _ => colors.primary,
    };
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 94,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: levels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final level = levels[index];
            final unlocked = app.isCurriculumLevelUnlocked(level.id);
            final selected = selectedId == level.id;
            final progress = app.curriculumLevelProgress(level.id);
            final tone = _tone(context, level.id);
            return SizedBox(
              width: 124,
              child: Material(
                color: selected
                    ? tone
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: unlocked ? () => onTap(level.id) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                level.id,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!unlocked)
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 15,
                                color: selected
                                    ? Colors.white70
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${progress.completedLessons}/${progress.totalLessons}',
                          style: TextStyle(
                            color: selected
                                ? Colors.white70
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress.percent.clamp(0.0, 1.0).toDouble(),
                            minHeight: 5,
                            backgroundColor: selected
                                ? Colors.white24
                                : Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: .4),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              selected ? Colors.white : tone,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download_for_offline_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      );
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.unit,
    required this.app,
    required this.downloaded,
    required this.onDownload,
    required this.onOpen,
  });

  final CurriculumUnit unit;
  final AppController app;
  final bool downloaded;
  final VoidCallback onDownload;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = app.curriculumUnitProgress(unit);
    final fraction = progress.total == 0 ? 0.0 : progress.done / progress.total;
    final scheme = Theme.of(context).colorScheme;
    final complete = progress.total > 0 && progress.done >= progress.total;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: complete
                      ? scheme.primary
                      : scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: complete
                    ? Icon(Icons.check_rounded, color: scheme.onPrimary)
                    : Text(
                        '${unit.sequence}',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bab ${unit.sequence}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${progress.done}/${progress.total} sub-bab · ${fraction == 0 ? 0 : (fraction * 100).round()}%',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0.0, 1.0).toDouble(),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: downloaded
                    ? 'Tersimpan offline'
                    : 'Download Bab',
                onPressed: onDownload,
                icon: Icon(
                  downloaded
                      ? Icons.download_done_rounded
                      : Icons.download_for_offline_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Buka Bab',
                onPressed: onOpen,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.level, required this.onPlacement});

  final CurriculumLevel level;
  final VoidCallback onPlacement;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 30),
              const SizedBox(height: 10),
              Text(
                '${level.id} belum terbuka',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Selesaikan level sebelumnya atau gunakan penempatan level.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onPlacement,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Cek level saya'),
              ),
            ],
          ),
        ),
      );
}
