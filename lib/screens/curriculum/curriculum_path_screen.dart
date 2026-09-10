import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../kana/kana_screen.dart';
import '../profile/profile_screen.dart';
import 'curriculum_lesson_detail_screen.dart';
import 'enriched_curriculum_chapter_screen.dart';

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

  String _validLevel(String value) => {'N5', 'N4', 'N3', 'N2', 'N1'}.contains(value) ? value : 'N5';

  List<CurriculumLesson> _lessons(CurriculumUnit unit) =>
      unit.lessons.where((lesson) => lesson.sequence > 0).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

  CurriculumLesson? _currentLesson(CurriculumLevel level, Map<String, CurriculumLessonStatus> statuses) {
    for (final unit in level.units) {
      for (final lesson in _lessons(unit)) {
        final status = statuses[lesson.id] ?? CurriculumLessonStatus.locked;
        if (status == CurriculumLessonStatus.inProgress || status == CurriculumLessonStatus.available) return lesson;
      }
    }
    return null;
  }

  CurriculumUnit? _unitOfLesson(CurriculumLevel level, String lessonId) {
    for (final unit in level.units) {
      if (unit.lessons.any((lesson) => lesson.id == lessonId)) return unit;
    }
    return null;
  }

  void _openLesson(BuildContext context, AppController app, CurriculumLesson lesson) {
    app.setCurriculumActiveLesson(lesson.id);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id))).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openChapter(BuildContext context, AppController app, CurriculumLevel level, CurriculumUnit unit) {
    app.setCurriculumActiveLevel(level.id);
    if (level.id == 'N5' || level.id == 'N4') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => EnrichedCurriculumChapterScreen(level: level, unit: unit))).then((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    final lessons = _lessons(unit);
    if (lessons.isNotEmpty) _openLesson(context, app, lessons.first);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = CurriculumCatalogData.fullLevels.firstWhere((item) => item.id == _levelId, orElse: () => CurriculumCatalogData.fullLevels.first);
    final units = [...level.units]..sort((a, b) => a.sequence.compareTo(b.sequence));
    final statuses = app.curriculumStatuses(level.id);
    final progress = app.curriculumLevelProgress(level.id);
    final currentLesson = _currentLesson(level, statuses);
    final currentUnit = currentLesson == null ? null : _unitOfLesson(level, currentLesson.id);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Row(children: [
          PopupMenuButton<String>(
            tooltip: 'Pilih level Learning',
            onSelected: (id) {
              setState(() => _levelId = id);
              app.setCurriculumActiveLevel(id);
            },
            itemBuilder: (_) => [
              for (final id in const ['N5', 'N4', 'N3', 'N2', 'N1'])
                PopupMenuItem<String>(
                  value: id,
                  child: Row(children: [
                    Expanded(child: Text(id, style: const TextStyle(fontWeight: FontWeight.w900))),
                    if (id == level.id) const Icon(Icons.check_rounded, size: 18),
                  ]),
                ),
            ],
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(level.id, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(level.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
          IconButton.filledTonal(
            tooltip: 'Profil',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.person_rounded),
          ),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(level.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(level.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress.percent.clamp(0.0, 1.0).toDouble(), minHeight: 10)),
            ])),
            const SizedBox(width: 18),
            Text('${(progress.percent * 100).round()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ]))),
          const SizedBox(height: 14),
          if (currentLesson != null && currentUnit != null)
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sedang berada di Bab ${currentUnit.sequence}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(currentLesson.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              Text('${level.id} · Sub-bab ${currentLesson.sequence}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => _openChapter(context, app, currentUnit),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Lanjut belajar'),
              )),
            ]))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _KanaCard(label: 'Hiragana', symbol: 'あ', onTap: _openKana)),
            const SizedBox(width: 12),
            Expanded(child: _KanaCard(label: 'Katakana', symbol: 'ア', onTap: _openKana)),
          ]),
          const SizedBox(height: 20),
          const Text('Roadmap Learning', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Introduction tidak ditampilkan sebagai langkah belajar. Bab N5/N4 berisi materi rinci, kosakata, romaji, contoh penggunaan, dan navigasi berantai.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          for (final unit in units)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: _ChapterCard(
              unit: unit,
              status: statuses,
              richFlow: level.id == 'N5' || level.id == 'N4',
              onOpen: () => _openChapter(context, app, level, unit),
              onContinue: () => _openChapter(context, app, level, unit),
            )),
        ],
      ),
    );
  }

  void _openKana(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanaScreen()));
}

class _KanaCard extends StatelessWidget {
  const _KanaCard({required this.label, required this.symbol, required this.onTap});
  final String label; final String symbol; final ValueChanged<BuildContext> onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20), onTap: () => onTap(context),
    child: Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), child: Row(children: [
      Text(symbol, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), const Icon(Icons.chevron_right_rounded),
    ]))),
  );
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.unit, required this.status, required this.richFlow, required this.onOpen, required this.onContinue});
  final CurriculumUnit unit; final Map<String, CurriculumLessonStatus> status; final bool richFlow; final VoidCallback onOpen; final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    final lessons = unit.lessons.where((lesson) => lesson.sequence > 0).toList();
    final done = lessons.where((lesson) {
      final s = status[lesson.id]; return s == CurriculumLessonStatus.completed || s == CurriculumLessonStatus.mastered;
    }).length;
    final percent = lessons.isEmpty ? 0.0 : done / lessons.length;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(child: Text('${unit.sequence}', style: const TextStyle(fontWeight: FontWeight.w900))), const Spacer(), Text('${(percent * 100).round()}%', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900))]),
      const SizedBox(height: 11),
      Text(unit.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      if (unit.subtitle.isNotEmpty) ...[const SizedBox(height: 3), Text(unit.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))],
      const SizedBox(height: 9),
      LinearProgressIndicator(value: percent), const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text('${lessons.length} sub-bab · ${richFlow ? 'Materi + romaji + contoh' : 'Materi + latihan'}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
        FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.menu_book_rounded, size: 17), label: const Text('Buka')),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: onContinue, icon: const Icon(Icons.arrow_forward_rounded, size: 17), label: const Text('Lanjut')),
      ]),
    ])));
  }
}