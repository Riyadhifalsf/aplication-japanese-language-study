import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../study/level_placement_screen.dart';
import 'curriculum_lesson_detail_screen.dart';
import 'curriculum_winding_path.dart';

/// Learning Path vertikal: perjalanan Beginner → N5 → N4 → N3 → N2 → N1
/// plus cabang Work in Japan (JFT-A1 → JFT-A2 → SSW).
///
/// - Recommended curriculum (jalur utama), bukan kumpulan menu.
/// - Dictionary/Kanji/Vocab/Grammar tetap bebas dibuka di luar path.
/// - Node: lingkaran/card dengan status ✓ ▶ 🔒 ★ + animasi sederhana.
/// - Desain modern & clean, tidak childish.
class CurriculumPathScreen extends StatefulWidget {
  const CurriculumPathScreen({super.key, this.initialLevel = 'N5'});

  final String initialLevel;

  @override
  State<CurriculumPathScreen> createState() => _CurriculumPathScreenState();
}

class _CurriculumPathScreenState extends State<CurriculumPathScreen> {
  late String _track;
  late String _levelId;

  @override
  void initState() {
    super.initState();
    final initial = CurriculumCatalogData.levelById(widget.initialLevel);
    _track = initial?.track ?? 'jlpt';
    _levelId = widget.initialLevel;
    if (CurriculumCatalogData.levelById(_levelId) == null) _levelId = 'N5';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final levels = CurriculumCatalogData.levelsForTrack(_track);
    var level = CurriculumCatalogData.levelById(_levelId);
    if (level == null || level.track != _track) {
      level = levels.isNotEmpty ? levels.first : null;
      if (level != null) _levelId = level.id;
    }
    if (level == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Learning Path')),
          body: const EmptyState(
              title: 'Belum ada level',
              message: 'Katalog kurikulum belum tersedia.'));
    }
    final current = level;
    final unlocked = app.isCurriculumLevelUnlocked(current.id);
    final progress = app.curriculumLevelProgress(current.id);
    final statuses = app.curriculumStatuses(current.id);
    final adaptive = app.curriculumAdaptive(current.id);
    final reviews = app.curriculumReviewQueue(current.id, limit: 3);
    final unlockState = current.requiredPreviousLevelId == null
        ? null
        : app.curriculumUnlockState(current.id);
    final hasAnyProgress = app.curriculumProgressById.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          _PathHero(
            level: current,
            progress: progress,
            streak: app.streak,
            xp: app.xp,
          ),
          const SizedBox(height: 14),
          const PromoBanner(),
          const SizedBox(height: 14),
          // Track selector: Japanese Path vs Work in Japan Path.
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'jlpt',
                  label: Text('Japanese Path'),
                  icon: Icon(Icons.school_rounded)),
              ButtonSegment(
                  value: 'work',
                  label: Text('Work Path'),
                  icon: Icon(Icons.badge_rounded)),
            ],
            selected: {_track},
            onSelectionChanged: (selected) {
              setState(() {
                _track = selected.first;
                final first =
                    CurriculumCatalogData.levelsForTrack(_track).firstOrNull;
                if (first != null) {
                  _levelId = first.id;
                  app.setCurriculumActiveLevel(first.id);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final l in levels)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _LevelChip(
                      level: l,
                      selected: l.id == _levelId,
                      unlocked: app.isCurriculumLevelUnlocked(l.id),
                      progress: app.curriculumLevelProgress(l.id),
                      onTap: () {
                        setState(() => _levelId = l.id);
                        app.setCurriculumActiveLevel(l.id);
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Placement entry: mulai dari awal vs placement test.
          if (!hasAnyProgress) ...[
            const SizedBox(height: 14),
            Card(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: .55),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Baru mulai?',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih "Mulai dari Beginner" untuk jalur N5 Unit 1, atau "Placement Test" untuk menentukan titik awal (N5 Beginner / Intermediate / N4 Beginner ...). Kamu tetap bisa mulai dari awal kapan saja.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              app.setCurriculumActiveLevel('N5');
                              setState(() {
                                _track = 'jlpt';
                                _levelId = 'N5';
                              });
                            },
                            icon: const Icon(Icons.flag_rounded),
                            label: const Text('Mulai Beginner'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LevelPlacementScreen(
                                    level: 'N5'),
                              ),
                            ),
                            icon: const Icon(Icons.quiz_rounded),
                            label: const Text('Placement Test'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!unlocked && unlockState != null) ...[
            const SizedBox(height: 14),
            _LockedBanner(
              level: current,
              unlockState: unlockState,
              onPlacement: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelPlacementScreen(
                      level: current.requiredPreviousLevelId ?? 'N5'),
                ),
              ),
            ),
          ],
          // Adaptive recommendation (jalur utama tetap, saran personal).
          if (unlocked && adaptive != null) ...[
            const SizedBox(height: 14),
            _AdaptiveCard(recommendation: adaptive),
          ],
          if (unlocked && reviews.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ReviewStrip(
              reviews: reviews,
              onOpen: (lesson) => _openLesson(context, app, lesson),
            ),
          ],
          const SizedBox(height: 18),
          if (unlocked)
            Text(
              '${current.units.length} Unit · ${progress.completedLessons}/${progress.totalLessons} lesson · ${(progress.percent * 100).round()}%',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          if (unlocked) ...[
            const SizedBox(height: 4),
            Text(
              'Lesson berikutnya terbuka setelah lesson sebelumnya selesai. Unit Test & Final Test butuh skor ≥70%.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4),
            ),
            const SizedBox(height: 14),
            // Path melengkung ala LingoDeer: satu node = satu unit.
            CurriculumWindingPath(
              nodes: _nodeVMs(app, current, statuses),
              onOpen: (node) => _openNode(context, app, node),
            ),
            const SizedBox(height: 18),
            _FinalArea(level: current, progress: progress),
          ] else
            _LockedLevelPanel(
              level: current,
              unlockState: unlockState,
              onPlacement: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelPlacementScreen(
                      level: current.requiredPreviousLevelId ?? 'N5'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isUnitLocked({
    required CurriculumUnit unit,
    required CurriculumLevel level,
    required Map<String, CurriculumLessonStatus> statuses,
  }) {
    // Unit terkunci bila lesson pertamanya locked & bukan unit pertama.
    if (unit.sequence <= 1) return false;
    final first = [...unit.lessons]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (first.isEmpty) return false;
    return statuses[first.first.id] == CurriculumLessonStatus.locked;
  }

  /// View-model node untuk path melengkung: satu node = satu unit.
  List<UnitPathNode> _nodeVMs(
    AppController app,
    CurriculumLevel level,
    Map<String, CurriculumLessonStatus> statuses,
  ) {
    final units = [...level.units]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final out = <UnitPathNode>[];
    var currentSet = false;
    for (final unit in units) {
      final lessons = [...unit.lessons]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      final prog = app.curriculumUnitProgress(unit);
      final locked =
          _isUnitLocked(unit: unit, level: level, statuses: statuses);
      final complete = prog.total > 0 && prog.done >= prog.total;
      final isCurrent = !locked && !complete && !currentSet;
      if (isCurrent) currentSet = true;
      CurriculumLesson? next;
      if (lessons.isNotEmpty) {
        next = lessons.firstWhere(
          (l) {
            final s = statuses[l.id];
            return s != CurriculumLessonStatus.completed &&
                s != CurriculumLessonStatus.mastered;
          },
          orElse: () => lessons.first,
        );
      }
      out.add(UnitPathNode(
        unit: unit,
        done: prog.done,
        total: prog.total,
        locked: locked,
        isCurrent: isCurrent,
        nextLesson: next,
      ));
    }
    return out;
  }

  void _openNode(BuildContext context, AppController app, UnitPathNode node) {
    if (node.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selesaikan unit sebelumnya dulu.')),
      );
      return;
    }
    final lesson = node.nextLesson;
    if (lesson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada lesson di unit ini.')),
      );
      return;
    }
    _openLesson(context, app, lesson);
  }

  void _openLesson(
      BuildContext context, AppController app, CurriculumLesson lesson) {
    final status = app.curriculumLessonStatus(lesson);
    if (status == CurriculumLessonStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selesaikan lesson sebelumnya dulu.')),
      );
      return;
    }
    app.setCurriculumActiveLesson(lesson.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id),
      ),
    );
  }
}

class _PathHero extends StatelessWidget {
  const _PathHero(
      {required this.level,
      required this.progress,
      required this.streak,
      required this.xp});

  final CurriculumLevel level;
  final UserLevelProgress progress;
  final int streak;
  final int xp;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              const Color(0xFF302D46)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_rounded,
                    color: Colors.white, size: 28),
                const Spacer(),
                _Pill(icon: Icons.local_fire_department_rounded, text: '$streak'),
                const SizedBox(width: 8),
                _Pill(icon: Icons.star_rounded, text: '$xp XP'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              level.subtitle,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${progress.completedLessons} / ${progress.totalLessons} lesson selesai · ${(progress.percent * 100).round()}%',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.percent.clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Recommended curriculum: ikuti node dari atas ke bawah. Menu Dictionary/Kanji/Vocab/Grammar tetap bebas dibuka kapan saja.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12)),
          ],
        ),
      );
}

class _LevelChip extends StatelessWidget {
  const _LevelChip(
      {required this.level,
      required this.selected,
      required this.unlocked,
      required this.progress,
      required this.onTap});

  final CurriculumLevel level;
  final bool selected;
  final bool unlocked;
  final UserLevelProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${level.id} · ${(progress.percent * 100).round()}%'),
            if (!unlocked)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.lock_rounded, size: 13),
              ),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner(
      {required this.level,
      required this.unlockState,
      required this.onPlacement});

  final CurriculumLevel level;
  final LevelUnlockState unlockState;
  final VoidCallback onPlacement;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: .55),
        child: ListTile(
          leading: const Icon(Icons.lock_rounded),
          title: Text('${level.id} masih terkunci',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(unlockState.reason),
          trailing: FilledButton.tonal(
              onPressed: onPlacement, child: const Text('Tes')),
        ),
      );
}

class _LockedLevelPanel extends StatelessWidget {
  const _LockedLevelPanel(
      {required this.level,
      required this.unlockState,
      required this.onPlacement});

  final CurriculumLevel level;
  final LevelUnlockState? unlockState;
  final VoidCallback onPlacement;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_rounded, size: 34),
              const SizedBox(height: 12),
              Text('${level.id} masih terkunci',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                unlockState?.reason ??
                    'Selesaikan level sebelumnya untuk membuka ${level.id}. Skor placement ≥80% juga bisa membuka level.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onPlacement,
                icon: const Icon(Icons.quiz_rounded),
                label: Text(
                    'Tes kemampuan ${level.requiredPreviousLevelId ?? ''}'),
              ),
            ],
          ),
        ),
      );
}

class _AdaptiveCard extends StatelessWidget {
  const _AdaptiveCard({required this.recommendation});
  final AdaptiveRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.auto_awesome_rounded)),
        title: Text('Recommended: ${recommendation.title}',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(recommendation.reason),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: recommendation.targetLessonId == null
            ? null
            : () {
                final lesson = CurriculumCatalogData.lessonById(
                    recommendation.targetLessonId!);
                if (lesson == null) return;
                app.setCurriculumActiveLesson(lesson.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CurriculumLessonDetailScreen(lessonId: lesson.id),
                  ),
                );
              },
      ),
    );
  }
}

class _ReviewStrip extends StatelessWidget {
  const _ReviewStrip({required this.reviews, required this.onOpen});
  final List<CurriculumLesson> reviews;
  final ValueChanged<CurriculumLesson> onOpen;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Review',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'Materi yang sering salah muncul lebih sering.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12),
              ),
              const SizedBox(height: 10),
              for (final lesson in reviews)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(lesson.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onOpen(lesson),
                ),
            ],
          ),
        ),
      );
}

class _FinalArea extends StatelessWidget {
  const _FinalArea({required this.level, required this.progress});
  final CurriculumLevel level;
  final UserLevelProgress progress;

  @override
  Widget build(BuildContext context) {
    if (!{'N5', 'N4', 'N3', 'N2', 'N1'}.contains(level.id)) {
      return const SizedBox.shrink();
    }
    if (!progress.completed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.school_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Area JLPT ${level.id}: Reading/Listening Practice + Mock Test ada di Unit terakhir. Lulus Final ≥70% untuk membuka level berikutnya.',
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }
    const order = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final i = order.indexOf(level.id);
    final next = i >= 0 && i < order.length - 1 ? order[i + 1] : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            const Color(0xFF1B3A2B),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded,
              color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${level.id} Completed',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                Text(
                  next == null
                      ? 'Kamu menuntaskan seluruh JLPT path. Pertahankan dengan review.'
                      : '$next sudah terbuka. Lanjutkan perjalananmu.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
