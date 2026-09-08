import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../study/level_placement_screen.dart';
import '../../widgets/kana_foundation_section.dart';
import 'curriculum_lesson_detail_screen.dart';
import 'curriculum_winding_path.dart';

/// Learning hub: perjalanan Beginner → N5 → N4 → N3 → N2 → N1
/// plus cabang Work in Japan (JFT-A1 → JFT-A2 → SSW).
///
/// - Recommended curriculum (jalur utama), bukan kumpulan menu.
/// - Dictionary/Kanji/Vocab/Grammar tetap bebas dibuka di luar Learning.
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
    if (_track == 'jlpt' && {'N5','N4','N3','N2','N1'}.contains(app.selectedStudyLevel)) {
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
              message: 'Katalog kurikulum belum tersedia.'));
    }
    final current = level;
    final unlocked = app.isCurriculumLevelUnlocked(current.id);
    final progress = app.curriculumLevelProgress(current.id);
    final statuses = app.curriculumStatuses(current.id);
    final adaptive = app.curriculumAdaptive(current.id);
    final reviews = app.curriculumReviewQueue(current.id, limit: 3);
    final unlockState = null;
    final hasAnyProgress = app.curriculumProgressById.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Learning')),
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
          // Dua jalur utama tetap jelas tanpa menampilkan istilah “Path” pada UI.
          _TrackSelector(
            track: _track,
            onChanged: (value) {
              setState(() {
                _track = value;
                final candidates = CurriculumCatalogData.levelsForTrack(value);
                final firstUnlocked = candidates.where((item) => app.isCurriculumLevelUnlocked(item.id)).firstOrNull;
                final fallback = candidates.firstOrNull;
                _levelId = (firstUnlocked ?? fallback)?.id ?? _levelId;
                app.setCurriculumActiveLevel(_levelId);
              });
            },
          ),
          const SizedBox(height: 12),
          if (_track == 'jlpt') _LevelSelectorRail(
            levels: levels,
            selectedId: _levelId,
            app: app,
            onTap: (id) {
              final selected = levels.firstWhere((item) => item.id == id);
              if (!app.isCurriculumLevelUnlocked(selected.id)) return;
              setState(() => _levelId = id);
              app.setCurriculumActiveLevel(id);
            },
          ),
          if (_track == 'jlpt') const SizedBox(height: 14),
          if (_track == 'jlpt') const KanaFoundationSection(),
          if (_track == 'jlpt') const SizedBox(height: 14),
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
              '${current.units.length} Bab · ${progress.completedLessons}/${progress.totalLessons} sub-bab · ${(progress.percent * 100).round()}%',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          if (unlocked) ...[
            const SizedBox(height: 4),
            Text(
              'Semua sub-bab di level aktif tersedia sejak awal. Urutannya membantu belajar bertahap, tetapi kamu tetap bebas memilih bab yang paling relevan sekarang.',
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
    return false;
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
      const locked = false;
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
    final lessons = [...node.unit.lessons]..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (lessons.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bab ${node.unit.sequence} · ${node.unit.title}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(node.unit.description.isEmpty ? 'Pilih sub-bab mana pun untuk langsung belajar.' : node.unit.description),
            const SizedBox(height: 12),
            Flexible(child: ListView.separated(
              shrinkWrap: true,
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final lesson = lessons[index];
                final status = app.curriculumLessonStatus(lesson);
                final done = status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: done ? const Icon(Icons.check_rounded) : Text('${index + 1}')),
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(lesson.subtitle.isEmpty ? '${lesson.activities.length} aktivitas · ${lesson.estimatedMinutes} menit' : lesson.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () { Navigator.pop(context); _openLesson(context, app, lesson); },
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _openLesson(
      BuildContext context, AppController app, CurriculumLesson lesson) {
    final status = app.curriculumLessonStatus(lesson);
    app.setCurriculumActiveLesson(lesson.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id),
      ),
    );
  }
}

class _TrackSelector extends StatelessWidget {
  const _TrackSelector({required this.track, required this.onChanged});
  final String track;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'jlpt', label: Text('Japanese'), icon: Icon(Icons.school_rounded)),
              ButtonSegment(value: 'work', label: Text('Work in Japan'), icon: Icon(Icons.work_outline_rounded)),
            ],
            selected: {track},
            onSelectionChanged: (value) => onChanged(value.first),
          ),
        ),
      );
}

class _LevelSelectorRail extends StatelessWidget {
  const _LevelSelectorRail({required this.levels, required this.selectedId, required this.app, required this.onTap});
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
        height: 108,
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
              width: 132,
              child: Material(
                color: selected ? tone : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: unlocked ? () => onTap(level.id) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(level.id, style: TextStyle(color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900))),
                        if (!unlocked) Icon(Icons.lock_outline_rounded, size: 16, color: selected ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant),
                      ]),
                      const Spacer(),
                      Text('${progress.completedLessons}/${progress.totalLessons} lessons', style: TextStyle(color: selected ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress.percent.clamp(0.0, 1.0).toDouble(), minHeight: 5, backgroundColor: selected ? Colors.white24 : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .4), valueColor: AlwaysStoppedAnimation<Color>(selected ? Colors.white : tone))),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      );
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
                const Icon(Icons.auto_stories_rounded,
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
              'Urutan ini memberi arah, bukan batasan. Pilih unit sesuai kebutuhanmu; materi Library tetap bisa dicari kapan saja.',
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
                      ? 'Kamu sudah menuntaskan seluruh level JLPT. Pertahankan kemampuanmu dengan review rutin.'
                      : '$next sudah tersedia. Lanjutkan saat kamu merasa siap.',
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
