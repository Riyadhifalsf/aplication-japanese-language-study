import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import 'curriculum_unit_screen.dart';

/// Learning Path inspired by the supplied learning-app references.
/// Semua Bab tampil langsung dalam daftar vertikal yang panjang.
class ReferenceLearningPathScreen extends StatefulWidget {
  const ReferenceLearningPathScreen({super.key, this.initialLevel = 'N5'});

  final String initialLevel;

  @override
  State<ReferenceLearningPathScreen> createState() =>
      _ReferenceLearningPathScreenState();
}

class _ReferenceLearningPathScreenState
    extends State<ReferenceLearningPathScreen> {
  late String _track;
  late String _levelId;

  @override
  void initState() {
    super.initState();
    final level = CurriculumCatalogData.levelById(widget.initialLevel);
    _track = level?.track ?? 'jlpt';
    _levelId = level?.id ?? 'N5';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final levels = CurriculumCatalogData.levelsForTrack(_track);
    final level = CurriculumCatalogData.levelById(_levelId) ??
        (levels.isNotEmpty ? levels.first : null);
    if (level == null) {
      return const Scaffold(
        body: Center(child: Text('Belum ada kurikulum.')),
      );
    }

    final units = [...level.units]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final progress = app.curriculumLevelProgress(level.id);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          level.id,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            sliver: SliverToBoxAdapter(
              child: _Header(level: level, progress: progress),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: _LevelRail(
                levels: levels,
                selectedId: level.id,
                app: app,
                onTap: (id) => setState(() => _levelId = id),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            sliver: SliverList.builder(
              itemCount: units.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UnitCard(
                  unit: units[index],
                  progress: app.curriculumUnitProgress(units[index]),
                  accent: _accent(context, index),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CurriculumUnitScreen(
                        level: level,
                        unit: units[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _accent(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    return [
      scheme.primary,
      scheme.tertiary,
      scheme.secondary,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
    ][index % 5];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.level, required this.progress});

  final CurriculumLevel level;
  final dynamic progress;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level.id,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              level.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.totalLessons == 0
                    ? 0
                    : progress.completedLessons / progress.totalLessons,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${progress.completedLessons}/${progress.totalLessons} sub-bab selesai',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _LevelRail extends StatelessWidget {
  const _LevelRail({
    required this.levels,
    required this.selectedId,
    required this.app,
    required this.onTap,
  });

  final List<CurriculumLevel> levels;
  final String selectedId;
  final AppController app;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
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
              label: Text(level.id),
              avatar: Icon(
                unlocked ? Icons.menu_book_rounded : Icons.lock_rounded,
                size: 17,
              ),
              onSelected: unlocked ? (_) => onTap(level.id) : null,
            );
          },
        ),
      );
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.progress,
    required this.accent,
    required this.onTap,
  });

  final CurriculumUnit unit;
  final dynamic progress;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = progress.total > 0 && progress.done >= progress.total;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '${unit.sequence}',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bab ${unit.sequence}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.done}/${progress.total} pelajaran',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                done ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                color: done ? accent : scheme.onSurfaceVariant,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
