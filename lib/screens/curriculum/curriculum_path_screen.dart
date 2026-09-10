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
  int? _chapterSequence;

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

    if (units.isNotEmpty && (_chapterSequence == null || !units.any((u) => u.sequence == _chapterSequence))) {
      final continueLesson = app.curriculumNextLesson(level.id);
      final continueUnit = continueLesson == null ? null : units.where((u) => u.id == continueLesson.unitId).firstOrNull;
      _chapterSequence = continueUnit?.sequence ?? units.first.sequence;
    }

    final selectedUnit = units.where((u) => u.sequence == _chapterSequence).firstOrNull;
    final progress = app.curriculumLevelProgress(level.id);
    final statuses = app.curriculumStatuses(level.id);
    final nextLesson = app.curriculumNextLesson(level.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 22,
        title: _LevelDropdown(
          level: level,
          onSelected: (id) {
            setState(() { _levelId = id; _chapterSequence = null; });
            app.setCurriculumActiveLevel(id);
          },
        ),
        actions: [
          _HeaderStat(icon: Icons.local_fire_department_rounded, value: '${app.streak}'),
          const SizedBox(width: 6),
          _HeaderStat(icon: Icons.star_border_rounded, value: '${app.quizCorrect}'),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _ProgressHeader(progress: progress),
          const SizedBox(height: 22),
          _KanaShortcutRow(onHiragana: () => _openKana(context), onKatakana: () => _openKana(context)),
          const SizedBox(height: 22),
          if (units.isEmpty)
            const _EmptyCurriculum()
          else ...[
            _ChapterHeader(
              level: level,
              units: units,
              selectedSequence: selectedUnit?.sequence ?? units.first.sequence,
              statuses: statuses,
              onSelected: (sequence) => setState(() => _chapterSequence = sequence),
            ),
            const SizedBox(height: 12),
            if (selectedUnit != null)
              _VerticalLessonPath(app: app, unit: selectedUnit, statuses: statuses, onOpen: (lesson) => _openLesson(context, app, lesson)),
            if (nextLesson != null && selectedUnit != null && nextLesson.unitId != selectedUnit.id) ...[
              const SizedBox(height: 18),
              _NextChapterButton(
                nextLesson: nextLesson,
                onPressed: () {
                  final nextUnit = units.where((u) => u.id == nextLesson.unitId).firstOrNull;
                  if (nextUnit == null) return;
                  setState(() => _chapterSequence = nextUnit.sequence);
                },
              ),
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
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'Ganti level', offset: const Offset(0, 44), onSelected: onSelected,
        itemBuilder: (_) => [for (final id in const ['N5', 'N4', 'N3', 'N2', 'N1']) PopupMenuItem<String>(value: id, child: Row(children: [SizedBox(width: 42, child: Text(id, style: const TextStyle(fontWeight: FontWeight.w900))), if (id == level.id) const Icon(Icons.check_rounded, size: 18)]))],
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(level.id, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(width: 5), const Icon(Icons.keyboard_arrow_down_rounded, size: 27)]),
      );
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.value});
  final IconData icon; final String value;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Theme.of(context).colorScheme.primary, size: 25), const SizedBox(width: 4), Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]);
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress});
  final UserLevelProgress progress;
  @override
  Widget build(BuildContext context) {
    final value = progress.percent.clamp(0.0, 1.0).toDouble();
    return Row(children: [
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: value, minHeight: 11, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success)))),
      const SizedBox(width: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: .20), blurRadius: 10, offset: const Offset(0, 3))]), child: Text('${(value * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
    ]);
  }
}

class _KanaShortcutRow extends StatelessWidget {
  const _KanaShortcutRow({required this.onHiragana, required this.onKatakana});
  final VoidCallback onHiragana; final VoidCallback onKatakana;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: _KanaShortcut(label: 'Hiragana', symbol: 'あ', onTap: onHiragana)), const SizedBox(width: 12), Expanded(child: _KanaShortcut(label: 'Katakana', symbol: 'ア', onTap: onKatakana))]);
}

class _KanaShortcut extends StatelessWidget {
  const _KanaShortcut({required this.label, required this.symbol, required this.onTap});
  final String label; final String symbol; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18), onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .55))),
          child: Row(children: [Text(symbol, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)), const SizedBox(width: 10), Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.primary)]),
        ),
      );
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.level, required this.units, required this.selectedSequence, required this.statuses, required this.onSelected});
  final CurriculumLevel level; final List<CurriculumUnit> units; final int selectedSequence; final Map<String, CurriculumLessonStatus> statuses; final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final unit = units.firstWhere((u) => u.sequence == selectedSequence, orElse: () => units.first);
    final done = unit.lessons.where((lesson) { final status = statuses[lesson.id]; return status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered; }).length;
    final isChapterOne = _chapterNumber(unit, 0) == 1;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (isChapterOne) ...[const Icon(Icons.menu_book_rounded, size: 34), const SizedBox(width: 8)],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bab ${_chapterNumber(unit, 0)}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text('Pelajaran $done/${unit.lessons.length}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant))])),
      ])),
      PopupMenuButton<int>(
        tooltip: 'Pilih bab', onSelected: onSelected,
        itemBuilder: (_) => [for (final item in units) PopupMenuItem<int>(value: item.sequence, child: Text('Bab ${_chapterNumber(item, 0)} · ${item.title}', overflow: TextOverflow.ellipsis))],
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.list_rounded, size: 19), SizedBox(width: 5), Text('Bab', style: TextStyle(fontWeight: FontWeight.w800))])),
      ),
    ]);
  }
}

class _VerticalLessonPath extends StatelessWidget {
  const _VerticalLessonPath({required this.app, required this.unit, required this.statuses, required this.onOpen});
  final AppController app; final CurriculumUnit unit; final Map<String, CurriculumLessonStatus> statuses; final ValueChanged<CurriculumLesson> onOpen;
  @override
  Widget build(BuildContext context) {
    final lessons = [...unit.lessons]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final doneCount = lessons.where((lesson) { final status = statuses[lesson.id]; return status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered; }).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (lessons.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Pelajaran selesai $doneCount/${lessons.length}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
      for (var i = 0; i < lessons.length; i++) _LessonPathNode(lesson: lessons[i], number: '${_chapterNumber(unit, i)}.${i + 1}', status: statuses[lessons[i].id] ?? CurriculumLessonStatus.locked, isLast: i == lessons.length - 1, onOpen: () => onOpen(lessons[i])),
    ]);
  }
}

int _chapterNumber(CurriculumUnit unit, int index) => unit.levelId == 'N5' && unit.sequence >= 3 ? unit.sequence - 2 : unit.sequence;

class _LessonPathNode extends StatelessWidget {
  const _LessonPathNode({required this.lesson, required this.number, required this.status, required this.isLast, required this.onOpen});
  final CurriculumLesson lesson; final String number; final CurriculumLessonStatus status; final bool isLast; final VoidCallback onOpen;
  bool get done => status == CurriculumLessonStatus.completed || status == CurriculumLessonStatus.mastered;
  bool get locked => status == CurriculumLessonStatus.locked;
  bool get active => status == CurriculumLessonStatus.inProgress || status == CurriculumLessonStatus.available;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nodeColor = done ? AppColors.success : (locked ? AppColors.locked : scheme.primary);
    final background = done ? scheme.surface : (active ? scheme.primaryContainer.withValues(alpha: .32) : scheme.surface);
    return Opacity(opacity: locked ? .52 : 1, child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 66, child: Column(children: [
        Container(width: 54, height: 54, padding: const EdgeInsets.all(5), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: nodeColor, width: 5), color: scheme.surface), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: nodeColor.withValues(alpha: .10)), child: Icon(_lessonIcon(lesson), color: nodeColor, size: 24))),
        if (!isLast) Expanded(child: Container(width: 5, margin: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: done ? AppColors.success : scheme.outlineVariant.withValues(alpha: .55), borderRadius: BorderRadius.circular(99)))),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Material(color: background, borderRadius: BorderRadius.circular(22), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: locked ? null : onOpen, child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 10, 16), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: nodeColor)), const SizedBox(height: 3), Text(lesson.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, height: 1.25, fontWeight: FontWeight.w800)), if (lesson.subtitle.isNotEmpty) ...[const SizedBox(height: 3), Text(lesson.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant))]])),
        const SizedBox(width: 8),
        Icon(done ? Icons.check_circle_rounded : (locked ? Icons.lock_rounded : Icons.menu_book_rounded), color: nodeColor, size: 29),
      ])))))),
    ])));
  }

  IconData _lessonIcon(CurriculumLesson lesson) {
    switch (lesson.primaryType) {
      case CurriculumActivityType.vocabulary: return Icons.translate_rounded;
      case CurriculumActivityType.grammar: return Icons.text_fields_rounded;
      case CurriculumActivityType.kanji: return Icons.brush_rounded;
      case CurriculumActivityType.conversation:
      case CurriculumActivityType.speaking: return Icons.chat_bubble_outline_rounded;
      case CurriculumActivityType.reading:
      case CurriculumActivityType.exampleSentences: return Icons.menu_book_rounded;
      case CurriculumActivityType.listening: return Icons.headphones_rounded;
      default: return Icons.menu_book_rounded;
    }
  }
}

class _NextChapterButton extends StatelessWidget {
  const _NextChapterButton({required this.nextLesson, required this.onPressed});
  final CurriculumLesson nextLesson; final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.arrow_forward_rounded), label: Text('Lanjut ke ${nextLesson.levelId} · Bab berikutnya'));
}

class _EmptyCurriculum extends StatelessWidget {
  const _EmptyCurriculum();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Icon(Icons.menu_book_outlined, size: 38), const SizedBox(height: 10), const Text('Materi belum tersedia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text('Level ini sudah bisa dipilih, tetapi isi kurikulumnya belum tersedia.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])));
}
