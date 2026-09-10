import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/curriculum/curriculum_catalog.dart';
import '../../features/curriculum/curriculum_models.dart';
import '../../features/curriculum/n5_n4_course_content.dart';
import '../../state/app_controller.dart';
import 'curriculum_lesson_detail_screen.dart';

/// Rich chapter flow for N5/N4. The screen keeps learning inside one flow:
/// chapter -> subchapter -> next subchapter -> next chapter.
/// N5/N4 content intentionally shows romaji for beginners.
class EnrichedCurriculumChapterScreen extends StatefulWidget {
  const EnrichedCurriculumChapterScreen({
    required this.level,
    required this.unit,
    super.key,
  });

  final CurriculumLevel level;
  final CurriculumUnit unit;

  @override
  State<EnrichedCurriculumChapterScreen> createState() =>
      _EnrichedCurriculumChapterScreenState();
}

class _EnrichedCurriculumChapterScreenState
    extends State<EnrichedCurriculumChapterScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoMoved = false;

  List<CurriculumUnit> get _units => [...widget.level.units]
    ..sort((a, b) => a.sequence.compareTo(b.sequence));

  int get _unitIndex => _units.indexWhere((u) => u.id == widget.unit.id);

  CurriculumUnit? get _nextUnit =>
      _unitIndex >= 0 && _unitIndex + 1 < _units.length
          ? _units[_unitIndex + 1]
          : null;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _goNextChapter({bool replace = false}) async {
    final next = _nextUnit;
    if (next == null || !mounted) return;
    final route = MaterialPageRoute(
      builder: (_) => EnrichedCurriculumChapterScreen(
        level: widget.level,
        unit: next,
      ),
    );
    if (replace) {
      await Navigator.pushReplacement(context, route);
    } else {
      await Navigator.push(context, route);
    }
  }

  void _watchForChapterEnd(ScrollNotification notification) {
    if (_autoMoved || _nextUnit == null || notification.metrics.axis != Axis.vertical) {
      return;
    }
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels >= notification.metrics.maxScrollExtent - 8) {
      _autoMoved = true;
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _goNextChapter(replace: true);
      });
    }
  }

  Future<void> _openSubchapter(CurriculumLesson lesson) async {
    final status = AppScope.of(context).curriculumLessonStatus(lesson);
    if (status == CurriculumLessonStatus.locked) return;
    AppScope.of(context).setCurriculumActiveLesson(lesson.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumLessonDetailScreen(lessonId: lesson.id),
      ),
    );
  }

  Future<void> _openReference() async {
    final data = N5N4CourseContent.forUnit(widget.level.id, widget.unit);
    if (data == null) return;
    final ok = await launchUrl(
      Uri.parse(data.imageUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referensi gambar tidak dapat dibuka.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final data = N5N4CourseContent.forUnit(widget.level.id, widget.unit);
    if (data == null) {
      return _legacyScreen(context);
    }

    final lessons = widget.unit.lessons
        .where((lesson) => lesson.sequence > 0)
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final statuses = app.curriculumStatuses(widget.level.id);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Row(
          children: [
            Text(widget.level.id,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bab ${widget.unit.sequence} · ${data.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _watchForChapterEnd(notification);
          return false;
        },
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _chapterHeader(context, data, lessons, statuses),
            const SizedBox(height: 14),
            _referenceCard(context, data),
            const SizedBox(height: 18),
            _sectionTitle('Kosakata penting', 'Target kata dipakai berulang di contoh dan latihan.'),
            const SizedBox(height: 8),
            _vocabularyGrid(context, data.terms),
            const SizedBox(height: 20),
            _sectionTitle('Pola grammar', 'Pelajari bentuk, fungsi, lalu lihat contoh penggunaan.'),
            const SizedBox(height: 8),
            for (final grammar in data.grammar)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${data.grammar.indexOf(grammar) + 1}')),
                    title: Text(grammar, style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(_grammarHint(grammar)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _sectionTitle('Sub-bab', 'Setiap sub-bab mempunyai contoh penggunaan sendiri.'),
            const SizedBox(height: 8),
            for (var i = 0; i < data.subchapters.length; i++)
              _subchapterCard(
                context,
                data.subchapters[i],
                i,
                lessons,
                statuses,
              ),
            const SizedBox(height: 16),
            _sectionTitle('Contoh penggunaan bab', 'Jangan hanya hafal kata: baca dalam kalimat.'),
            const SizedBox(height: 8),
            for (final example in data.examples)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _exampleCard(context, example),
              ),
            const SizedBox(height: 12),
            _nextChapterCard(context),
          ],
        ),
      ),
    );
  }

  Widget _chapterHeader(
    BuildContext context,
    CourseChapter data,
    List<CurriculumLesson> lessons,
    Map<String, CurriculumLessonStatus> statuses,
  ) {
    final done = lessons.where((lesson) {
      final s = statuses[lesson.id];
      return s == CurriculumLessonStatus.completed || s == CurriculumLessonStatus.mastered;
    }).length;
    final progress = lessons.isEmpty ? 0.0 : done / lessons.length;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BAB ${widget.unit.sequence}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(data.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(data.summary, style: TextStyle(color: cs.onSurfaceVariant, height: 1.45)),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress, minHeight: 9),
          const SizedBox(height: 8),
          Text('$done/${lessons.length} sub-bab selesai', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _referenceCard(BuildContext context, CourseChapter data) => Card(
        child: InkWell(
          onTap: _openReference,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const CircleAvatar(child: Icon(Icons.image_search_rounded)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Referensi gambar', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(data.imageLabel, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
              const Icon(Icons.open_in_new_rounded, size: 18),
            ]),
          ),
        ),
      );

  Widget _vocabularyGrid(BuildContext context, List<CourseTerm> terms) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: terms.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 800 ? 3 : 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (_, index) {
          final term = terms[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(term.word, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(term.romaji, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(term.meaning, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
          );
        },
      );

  Widget _subchapterCard(
    BuildContext context,
    CourseSubchapter sub,
    int index,
    List<CurriculumLesson> lessons,
    Map<String, CurriculumLessonStatus> statuses,
  ) {
    final lesson = index < lessons.length ? lessons[index] : null;
    final lessonStatus = lesson == null
        ? CurriculumLessonStatus.available
        : statuses[lesson.id] ?? CurriculumLessonStatus.locked;
    final locked = lessonStatus == CurriculumLessonStatus.locked;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 19, child: Text(sub.number, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
            const SizedBox(width: 10),
            Expanded(child: Text(sub.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
            if (lessonStatus == CurriculumLessonStatus.completed || lessonStatus == CurriculumLessonStatus.mastered)
              const Icon(Icons.check_circle_rounded),
          ]),
          const SizedBox(height: 8),
          Text(sub.body, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 10),
          for (final example in sub.examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _compactExample(context, example),
            ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: lesson == null || locked ? null : () => _openSubchapter(lesson),
              icon: Icon(locked ? Icons.lock_rounded : Icons.arrow_forward_rounded, size: 17),
              label: Text(lessonStatus == CurriculumLessonStatus.completed ? 'Ulang' : 'Lanjut'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _compactExample(BuildContext context, CourseExample example) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(example.japanese, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(example.romaji, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(example.meaning, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 3),
          Text('Penggunaan: ${example.use}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
        ]),
      );

  Widget _exampleCard(BuildContext context, CourseExample example) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _compactExample(context, example),
        ),
      );

  Widget _nextChapterCard(BuildContext context) {
    final next = _nextUnit;
    if (next == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('N5/N4 checkpoint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text('Kamu sudah sampai akhir jalur level ini. Gunakan review dan latihan sebelum pindah level.'),
          ]),
        ),
      );
    }
    final nextData = N5N4CourseContent.forUnit(widget.level.id, next);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _goNextChapter(),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            CircleAvatar(child: Text('${next.sequence}')),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Lanjut ke bab berikutnya', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(nextData?.title ?? next.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Geser sampai bawah untuk berpindah otomatis.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
            const Icon(Icons.arrow_downward_rounded),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.4))],
      );

  String _grammarHint(String grammar) {
    if (grammar.contains('です')) return 'Pola sopan untuk identitas atau deskripsi.';
    if (grammar.contains('これ')) return 'Kata penunjuk berdasarkan jarak.';
    if (grammar.contains('ます')) return 'Bentuk sopan verba dasar.';
    if (grammar.contains('あります') || grammar.contains('います')) return 'Menyatakan keberadaan benda atau makhluk hidup.';
    if (grammar.contains('たい')) return 'Menyatakan keinginan melakukan sesuatu.';
    if (grammar.contains('て')) return 'Bentuk yang dipakai untuk urutan, permintaan, izin, dan keadaan.';
    if (grammar.contains('より')) return 'Membandingkan dua hal.';
    return 'Pahami fungsi pola dan buat contohmu sendiri.';
  }

  Widget _legacyScreen(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.unit.title)),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CurriculumLessonDetailScreen(
                  lessonId: widget.unit.lessons.first.id,
                ),
              ),
            ),
            child: const Text('Lanjut belajar'),
          ),
        ),
      );
}
