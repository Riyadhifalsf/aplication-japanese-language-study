import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
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
    final units = [...level.units]..sort((a, b) => a.sequence.compareTo(b.sequence));

    final progress = app.curriculumLevelProgress(level.id);
    final statuses = app.curriculumStatuses(level.id);
    var unitsDone = 0;
    for (final unit in units) {
      final prog = app.curriculumUnitProgress(unit);
      if (prog.total > 0 && prog.done >= prog.total) unitsDone++;
    }
    // Persen fraksional: sub-bab setengah jalan ikut dihitung setengah.
    var fracSum = 0.0;
    var fracTotal = 0;
    for (final unit in units) {
      for (final lesson in unit.lessons) {
        fracSum += _lessonFraction(app, lesson);
        fracTotal++;
      }
    }
    final levelFraction =
        fracTotal == 0 ? 0.0 : (fracSum / fracTotal).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 22,
        title: _LevelDropdown(
          level: level,
          onSelected: (id) {
            setState(() => _levelId = id);
            app.setCurriculumActiveLevel(id);
          },
        ),
        actions: [
          _HeaderStat(icon: Icons.local_fire_department_rounded, value: '${app.streak}'),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _ProgressHeader(
            levelId: level.id,
            progress: progress,
            fraction: levelFraction,
            unitsDone: unitsDone,
            unitsTotal: units.length,
          ),
          const SizedBox(height: 22),
          _KanaShortcutRow(
              app: app,
              onHiragana: () => _openKana(context),
              onKatakana: () => _openKana(context)),
          const SizedBox(height: 22),
          if (units.isEmpty)
            const _EmptyCurriculum()
          else ...[
            for (var i = 0; i < units.length; i++) ...[
              _ChapterHeader(
                  unit: units[i],
                  chapterNo: i + 1,
                  fraction: _unitFraction(app, units[i]),
                  statuses: statuses),
              const SizedBox(height: 12),
              _VerticalLessonPath(app: app, unit: units[i], chapterNo: i + 1, statuses: statuses, onOpen: (lesson) => _openLesson(context, app, lesson)),
              if (i != units.length - 1) const SizedBox(height: 18),
            ],
          ],
        ],
      ),
    );
  }

  void _openKana(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanaScreen()));

  void _openLesson(BuildContext context, AppController app, CurriculumLesson lesson) {
    app.setCurriculumActiveLesson(lesson.id);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id)));
  }
}

class _LevelDropdown extends StatelessWidget {
  const _LevelDropdown({required this.level, required this.onSelected});
  final CurriculumLevel level;
  final ValueChanged<String> onSelected;

  static const _levels = [
    ('N5', 'Pemula'),
    ('N4', 'Dasar'),
    ('N3', 'Menengah'),
    ('N2', 'Menengah Atas'),
    ('N1', 'Lanjutan'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(level.id, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.primary)),
          const SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down_rounded, size: 23, color: cs.primary),
        ]),
      ),
    );
  }

  /// Bottom sheet pilih level ala referensi: ring progres + icon +
  /// nama + jumlah Bab per level, dengan tombol X.
  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final app = AppScope.of(sheetContext);
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.translate_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Pilih Level JLPT',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _levels.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final entry = _levels[i];
                      final lv = CurriculumCatalogData.levelById(entry.$1);
                      final units = lv?.units ?? const [];
                      // Fraksi per aktivitas: sedikit belajar tetap tampil.
                      var fracSum = 0.0;
                      var fracTotal = 0;
                      for (final unit in units) {
                        for (final lesson in unit.lessons) {
                          fracSum += _lessonFraction(app, lesson);
                          fracTotal++;
                        }
                      }
                      final fraction = fracTotal == 0
                          ? 0.0
                          : (fracSum / fracTotal)
                              .clamp(0.0, 1.0)
                              .toDouble();
                      return _LevelSheetRow(
                        id: entry.$1,
                        label: entry.$2,
                        babCount: units.length,
                        percent: fraction,
                        selected: entry.$1 == level.id,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onSelected(entry.$1);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LevelSheetRow extends StatelessWidget {
  const _LevelSheetRow({
    required this.id,
    required this.label,
    required this.babCount,
    required this.percent,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final int babCount;
  final double percent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Level tuntas 100% tampil beda: ring hijau + cap selesai.
    final finished = percent >= 1.0;
    final ringColor =
        finished ? Colors.green.shade600 : cs.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: finished
              ? Colors.green.shade600.withValues(alpha: .12)
              : selected
                  ? cs.primaryContainer.withValues(alpha: .55)
                  : cs.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(20),
          border: finished
              ? Border.all(
                  color: Colors.green.shade600.withValues(alpha: .6))
              : null,
        ),
        child: Row(children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 5,
                    backgroundColor: cs.outlineVariant.withValues(alpha: .5),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: finished
                        ? Colors.green.shade700
                        : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label $id',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('$babCount bab',
                    style: TextStyle(
                        color: finished
                            ? Colors.green.shade700
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (finished)
            Icon(Icons.check_circle_rounded,
                color: Colors.green.shade600, size: 26)
          else if (selected)
            Icon(Icons.check_circle_rounded,
                color: cs.primary, size: 26),
        ]),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.value});
  final IconData icon; final String value;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Theme.of(context).colorScheme.primary, size: 25), const SizedBox(width: 4), Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]);
}

/// Fraksi penyelesaian satu unit 0..1 (rata-rata fraksi lesson-nya).
double _unitFraction(AppController app, CurriculumUnit unit) {
  if (unit.lessons.isEmpty) return 0.0;
  var sum = 0.0;
  for (final lesson in unit.lessons) {
    sum += _lessonFraction(app, lesson);
  }
  return (sum / unit.lessons.length).clamp(0.0, 1.0).toDouble();
}

/// Fraksi penyelesaian satu lesson 0..1 dari aktivitasnya.
/// Tuntas/mastered = 1. Sub-bab setengah jalan ikut dihitung setengah.
double _lessonFraction(AppController app, CurriculumLesson lesson) {
  final prog = app.curriculumProgressById[lesson.id];
  final status = prog?.status;
  if (status == CurriculumLessonStatus.completed ||
      status == CurriculumLessonStatus.mastered) {
    return 1.0;
  }
  if (lesson.activities.isEmpty) return 0.0;
  final done = prog?.completedActivityIds.length ?? 0;
  return (done / lesson.activities.length).clamp(0.0, 1.0).toDouble();
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.levelId,
    required this.progress,
    required this.fraction,
    required this.unitsDone,
    required this.unitsTotal,
  });
  final String levelId;
  final UserLevelProgress progress;
  final double fraction;
  final int unitsDone;
  final int unitsTotal;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = fraction.clamp(0.0, 1.0).toDouble();
    final pct = (value * 100).round();
    const dotSize = 18.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: .72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress $levelId',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  // Angka persen disembunyikan saat masih 0%.
                  if (pct > 0)
                    Text('$pct%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$unitsDone/$unitsTotal Bab',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 10),
          // Bulatan yang maju mengikuti progres — ringkas tanpa angka.
          LayoutBuilder(
            builder: (context, constraints) {
              final dx =
                  (constraints.maxWidth - dotSize) * value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor:
                          Colors.white.withValues(alpha: .25),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  ),
                  Positioned(
                    left: dx,
                    top: (10 - dotSize) / 2,
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.completedLessons}/${progress.totalLessons} sub-bab selesai',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _KanaShortcutRow extends StatelessWidget {
  const _KanaShortcutRow(
      {required this.app, required this.onHiragana, required this.onKatakana});
  final AppController app;
  final VoidCallback onHiragana;
  final VoidCallback onKatakana;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fondasi Kana',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Selesaikan keduanya sebelum masuk Bab.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _KanaProgressCard(
                  symbol: 'あ',
                  label: 'Hiragana',
                  unitId: 'n5-u02',
                  app: app,
                  onTap: onHiragana)),
          const SizedBox(width: 12),
          Expanded(
              child: _KanaProgressCard(
                  symbol: 'ア',
                  label: 'Katakana',
                  unitId: 'n5-u03',
                  app: app,
                  onTap: onKatakana)),
        ]),
      ],
    );
  }
}

class _KanaProgressCard extends StatelessWidget {
  const _KanaProgressCard(
      {required this.symbol,
      required this.label,
      required this.unitId,
      required this.app,
      required this.onTap});
  final String symbol;
  final String label;
  final String unitId;
  final AppController app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unit = CurriculumCatalogData.unitById(unitId);
    final prog = unit == null
        ? (done: 0, total: 0, percent: 0.0)
        : app.curriculumUnitProgress(unit);
    final done = prog.total > 0 && prog.done >= prog.total;
    // Fraksi per aktivitas: sub-bab setengah jalan ikut dihitung.
    var fracSum = 0.0;
    var fracTotal = 0;
    if (unit != null) {
      for (final lesson in unit.lessons) {
        fracSum += _lessonFraction(app, lesson);
        fracTotal++;
      }
    }
    final value = fracTotal == 0
        ? 0.0
        : (fracSum / fracTotal).clamp(0.0, 1.0).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: done
              ? cs.primaryContainer.withValues(alpha: .55)
              : cs.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: .5),
            width: done ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(symbol,
                  style:
                      const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const Spacer(),
              if (done)
                Icon(Icons.check_circle_rounded,
                    color: cs.primary, size: 20),
            ]),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor:
                    cs.outlineVariant.withValues(alpha: .4),
                valueColor:
                    AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prog.total == 0
                  ? 'Belum tersedia'
                  : '${prog.done}/${prog.total} selesai · ${(value * 100).round()}%',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader(
      {required this.unit,
      required this.chapterNo,
      required this.fraction,
      required this.statuses});
  final CurriculumUnit unit;
  /// Nomor Bab linear sesuai urutan tampil (1, 2, 3, ...) — tidak pernah dobel.
  final int chapterNo;
  /// Progres unit 0..1 sebagai stroke lingkaran mengikuti bentuk icon.
  final double fraction;
  final Map<String, CurriculumLessonStatus> statuses;
  @override
  Widget build(BuildContext context) {
    final done = unit.lessons.where((lesson) { final status = statuses[lesson.id]; return status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered; }).length;
    final scheme = Theme.of(context).colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: fraction.clamp(0.0, 1.0).toDouble(),
                strokeWidth: 5,
                backgroundColor:
                    scheme.outlineVariant.withValues(alpha: .45),
                valueColor: AlwaysStoppedAnimation<Color>(
                    done == unit.lessons.length && unit.lessons.isNotEmpty
                        ? Colors.green.shade600
                        : scheme.primary),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.menu_book_rounded,
                  color: scheme.primary, size: 22),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bab $chapterNo', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text('${unit.title} · $done/${unit.lessons.length} pelajaran selesai', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ])),
    ]);
  }
}

class _VerticalLessonPath extends StatelessWidget {
  const _VerticalLessonPath({required this.app, required this.unit, required this.chapterNo, required this.statuses, required this.onOpen});
  final AppController app; final CurriculumUnit unit; final int chapterNo; final Map<String, CurriculumLessonStatus> statuses; final ValueChanged<CurriculumLesson> onOpen;
  @override
  Widget build(BuildContext context) {
    final lessons = [...unit.lessons]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final doneCount = lessons.where((lesson) { final status = statuses[lesson.id]; return status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered; }).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (lessons.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Pelajaran selesai $doneCount/${lessons.length}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
      for (var i = 0; i < lessons.length; i++) _LessonPathNode(lesson: lessons[i], number: '$chapterNo.${i + 1}', status: statuses[lessons[i].id] ?? CurriculumLessonStatus.locked, progress: _lessonProgress(app, lessons[i]), isLast: i == lessons.length - 1, onOpen: () => onOpen(lessons[i])),
    ]);
  }

  /// Progres aktivitas lesson 0..1 (50% belajar = setengah lingkaran).
  /// Lesson tuntas/mastered selalu penuh.
  static double _lessonProgress(AppController app, CurriculumLesson lesson) {
    final doneIds =
        app.curriculumProgressById[lesson.id]?.completedActivityIds ??
            const <String>{};
    if (lesson.activities.isEmpty) {
      return doneIds.isNotEmpty ? 1.0 : 0.0;
    }
    return (doneIds.length / lesson.activities.length)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class _LessonPathNode extends StatelessWidget {
  const _LessonPathNode({required this.lesson, required this.number, required this.status, required this.progress, required this.isLast, required this.onOpen});
  final CurriculumLesson lesson; final String number; final CurriculumLessonStatus status; final double progress; final bool isLast; final VoidCallback onOpen;
  bool get done => status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered;
  bool get locked => status == CurriculumLessonStatus.locked;
  bool get active => status == CurriculumLessonStatus.inProgress || status == CurriculumLessonStatus.available;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nodeColor = done ? AppColors.success : (locked ? AppColors.locked : scheme.primary);
    // Ring progres aktivitas: 50% belajar = setengah lingkaran penuh warna.
    final ringValue = done ? 1.0 : progress.clamp(0.0, 1.0).toDouble();
    final background = done ? scheme.surface : (active ? scheme.primaryContainer.withValues(alpha: .32) : scheme.surface);
    return Opacity(opacity: locked ? .52 : 1, child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 66, child: Column(children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: ringValue,
                  strokeWidth: 6,
                  backgroundColor:
                      scheme.outlineVariant.withValues(alpha: .45),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(nodeColor),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nodeColor.withValues(alpha: .10),
                ),
                child: Icon(
                    done
                        ? Icons.check_rounded
                        : (locked
                            ? Icons.lock_rounded
                            : Icons.book_rounded),
                    color: nodeColor,
                    size: 22),
              ),
            ],
          ),
        ),
        if (!isLast) Expanded(child: Container(width: 5, margin: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: done ? AppColors.success : scheme.outlineVariant.withValues(alpha: .55), borderRadius: BorderRadius.circular(99)))),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Material(color: background, borderRadius: BorderRadius.circular(22), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: locked ? null : onOpen, child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 10, 16), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: nodeColor)), const SizedBox(height: 3), Text(lesson.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, height: 1.25, fontWeight: FontWeight.w800)), if (lesson.subtitle.isNotEmpty) ...[const SizedBox(height: 3), Text(lesson.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant))]])),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: nodeColor.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(done ? Icons.check_rounded : (locked ? Icons.lock_rounded : Icons.download_rounded), color: nodeColor, size: 22),
        ),
      ])))))),
    ])));
  }
}

class _EmptyCurriculum extends StatelessWidget {
  const _EmptyCurriculum();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Icon(Icons.menu_book_outlined, size: 38), const SizedBox(height: 10), const Text('Materi belum tersedia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text('Level ini sudah bisa dipilih, tetapi isi kurikulumnya belum tersedia.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])));
}
