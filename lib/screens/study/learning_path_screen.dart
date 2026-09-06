import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../grammar/grammar_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_library_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../vocab/vocabulary_screen.dart';
import '../readings/reading_screen.dart';
import 'level_placement_screen.dart';
import 'chapter_assessment_screen.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key, this.initialLevel = 'N5'});
  final String initialLevel;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  String level = 'N5';

  @override
  void initState() {
    super.initState();
    if (['N5','N4','N3','N2','N1'].contains(widget.initialLevel)) level = widget.initialLevel;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final chapters = curriculum[level]!;
    final completed = chapters.where((c) => app.completedLearningStepIds.contains(c.id)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Path Belajar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          _Hero(level: level, completed: completed, total: chapters.length, streak: app.streak),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final l in const ['N5', 'N4', 'N3', 'N2', 'N1'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Row(mainAxisSize: MainAxisSize.min, children: [Text(l), if (!app.isLevelUnlocked(l)) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_rounded, size: 14))]),
                      selected: level == l,
                      onSelected: (_) => setState(() => level = l),
                    ),
                  ),
              ],
            ),
          ),
          if (!app.isLevelUnlocked(level) && app.requiredPreviousLevel(level) != null) ...[
            const SizedBox(height: 14),
            Card(color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: .55), child: ListTile(leading: const Icon(Icons.school_rounded), title: Text('Sudah bisa ${app.requiredPreviousLevel(level)}?'), subtitle: const Text('Ambil placement quiz. Skor 80% membuka level berikutnya.'), trailing: FilledButton.tonal(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LevelPlacementScreen(level: app.requiredPreviousLevel(level)!))), child: const Text('Tes')))),
          ],
          const SizedBox(height: 18),
          Text(
            '${chapters.length} Bab · ${_levelDescription[level]}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Urutan dibuat seperti course modern: belajar inti → latihan → review → uji penguasaan. Bab berikutnya terbuka setelah bab sebelumnya selesai.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 14),
          if (app.isLevelUnlocked(level)) _RoadPath(chapters: chapters) else _LockedLevelPanel(level: level),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.level, required this.completed, required this.total, required this.streak});
  final String level;
  final int completed;
  final int total;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, const Color(0xFF302D46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.route_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text('Path $level', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const Spacer(),
          Row(children: [const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent), const SizedBox(width: 4), Text('$streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))]),
        ]),
        const SizedBox(height: 12),
        Text('$completed / $total bab selesai', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white24)),
        const SizedBox(height: 10),
        const Text('Bukan kumpulan fitur acak. Ini jalur utama yang menentukan apa yang dipelajari selanjutnya.', style: TextStyle(color: Colors.white70, height: 1.35)),
      ]),
    );
  }
}

class _LockedLevelPanel extends StatelessWidget {
  const _LockedLevelPanel({required this.level});
  final String level;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final previous = app.requiredPreviousLevel(level);
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lock_rounded, size: 34), const SizedBox(height: 12), Text('$level masih terkunci', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text('Selesaikan $previous sampai uji penguasaan, atau gunakan placement quiz untuk membuktikan kemampuan awal.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45)), const SizedBox(height: 14), if (previous != null) FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LevelPlacementScreen(level: previous))), icon: const Icon(Icons.quiz_rounded), label: Text('Tes kemampuan $previous'))])));
  }
}

class _RoadPath extends StatelessWidget {
  const _RoadPath({required this.chapters});
  final List<PathChapter> chapters;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Column(children: [
      for (var i = 0; i < chapters.length; i++) ...[
        _NodeCard(
          chapter: chapters[i],
          index: i,
          completed: app.completedLearningStepIds.contains(chapters[i].id),
          locked: i > 0 && !app.completedLearningStepIds.contains(chapters[i - 1].id),
        ),
        if (i != chapters.length - 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(width: 4, height: 24, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(99))),
          ),
      ],
    ]);
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.chapter, required this.index, required this.completed, required this.locked});
  final PathChapter chapter;
  final int index;
  final bool completed;
  final bool locked;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: locked ? .55 : 1,
        duration: const Duration(milliseconds: 180),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: locked ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterDetailScreen(chapter: chapter))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: completed ? Colors.green.withValues(alpha: .14) : Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                  child: locked ? const Icon(Icons.lock_rounded) : completed ? const Icon(Icons.check_rounded, color: Colors.green) : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bab ${chapter.number} · ${chapter.title}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(chapter.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in chapter.tags) Chip(label: Text(tag), visualDensity: VisualDensity.compact)])
                ])),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        ),
      );
}

/// Detail satu bab: materi -> latihan -> review -> uji penguasaan.
///
/// Publik agar "Lanjutkan belajar" di StudyHub bisa deep-link langsung.
class ChapterDetailScreen extends StatelessWidget {
  const ChapterDetailScreen({required this.chapter, super.key});
  final PathChapter chapter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final done = app.completedLearningStepIds.contains(chapter.id);
    final subLessons = chapter.subLessons.isEmpty ? const ['Pengenalan konsep & contoh', 'Latihan terpandu', 'Pemakaian dalam konteks'] : chapter.subLessons;
    return Scaffold(
      appBar: AppBar(title: Text('Bab ${chapter.number}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Text(chapter.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(chapter.summary, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45)),
          const SizedBox(height: 16),
          const Text('Sub-bab', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (var i = 0; i < subLessons.length; i++)
            _LessonTile(title: '${i + 1}. ${subLessons[i]}', subtitle: i == 0 ? 'Pelajari konsep dasar dan contoh.' : 'Latihan terarah dari materi bab.', icon: i == 0 ? Icons.school_rounded : Icons.play_lesson_rounded, onTap: () => _showSubLesson(context, chapter, subLessons[i])),
          const SizedBox(height: 12),
          _LessonTile(title: 'Kotoba', subtitle: 'Kosakata yang mendukung bab ini.', icon: Icons.menu_book_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VocabularyScreen(initialLevel: chapter.level)))),
          _LessonTile(title: 'Bunpou', subtitle: 'Pola tata bahasa dan penggunaan.', icon: Icons.account_tree_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrammarScreen(initialLevel: chapter.level)))),
          _LessonTile(title: 'Kanji', subtitle: 'Kanji yang relevan dengan tema bab.', icon: Icons.translate_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KanjiLibraryScreen(initialLevel: chapter.level)))),
          _LessonTile(title: 'Bacaan', subtitle: 'Gunakan cerita untuk melihat materi dalam konteks.', icon: Icons.auto_stories_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReadingScreen(initialLevel: chapter.level)))),
          _LessonTile(title: 'Review', subtitle: 'Ulangi bagian yang masih lemah.', icon: Icons.refresh_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiReviewScreen()))),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterAssessmentScreen(chapter: chapter))),
            icon: Icon(done ? Icons.replay_rounded : Icons.quiz_rounded),
            label: Text(done ? 'Ulangi Uji Bab' : 'Uji Penguasaan Bab'),
          ),
        ],
      ),
    );
  }

  void _showSubLesson(BuildContext context, PathChapter chapter, String lesson) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(lesson, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 10), Text('Bab ${chapter.number} · ${chapter.level}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...chapter.material.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline_rounded, size: 18), const SizedBox(width: 8), Expanded(child: Text(item))]))), const SizedBox(height: 4), const Text('Setelah membaca, lanjutkan ke latihan pada bab ini lalu ambil Uji Penguasaan Bab.', style: TextStyle(height: 1.4))])));
  }

  void _showMaterial(BuildContext context, PathChapter chapter) {
    showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Materi inti Bab ${chapter.number}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12), for (final item in chapter.material) Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline_rounded, size: 18), const SizedBox(width: 8), Expanded(child: Text(item, style: const TextStyle(height: 1.35)))])), const SizedBox(height: 4), Text('Target: ${chapter.target}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800))])));
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 9), child: ListTile(onTap: onTap, leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded)));
}
/// Satu bab kurikulum path belajar. Publik agar bisa dipakai lintas layar.
class PathChapter {

  const PathChapter(this.id, this.number, this.level, this.title, this.summary, this.material, this.target, this.tags, [this.subLessons = const []]);
  final String id;
  final int number;
  final String level;
  final String title;
  final String summary;
  final List<String> material;
  final String target;
  final List<String> tags;
  final List<String> subLessons;
}

String _n(int i) => i.toString().padLeft(2, '0');

final Map<String, String> _levelDescription = {
  'N5': 'fondasi komunikasi sehari-hari',
  'N4': 'kalimat praktis dan tata bahasa menengah',
  'N3': 'komunikasi mandiri dan bacaan menengah',
  'N2': 'bahasa formal, berita, dan argumentasi',
  'N1': 'bahasa tingkat lanjut dan nuansa',
};

/// Kurikulum per level. Publik agar StudyHub bisa hitung progres & deep-link.
final Map<String, List<PathChapter>> curriculum = {
  'N5': [
    PathChapter('path-n5-01', 1, 'N5', 'Salam & perkenalan', 'Memulai percakapan dan memperkenalkan diri.', ['Hiragana dasar dan bunyi panjang', 'です sebagai penutup sopan', 'Pola nama + です'], 'Bisa memperkenalkan diri sederhana.', ['Kana', 'です', 'Frasa']),
    PathChapter('path-n5-02', 2, 'N5', 'Keluarga & orang', 'Menyebut anggota keluarga dan orang di sekitar.', ['これ・それ・あれ', 'こちら・そちら・あちら', 'Kata ganti dasar'], 'Bisa membicarakan orang terdekat.', ['これそれあれ', 'Keluarga']),
    PathChapter('path-n5-03', 3, 'N5', 'Benda & tempat', 'Menanyakan benda, ruangan, dan lokasi.', ['ここ・そこ・あそこ', 'この・その・あの', 'Tempat umum'], 'Bisa bertanya dan menjawab lokasi.', ['Tempat', 'ここそこあそこ']),
    PathChapter('path-n5-04', 4, 'N5', 'Waktu & jadwal', 'Jam, hari, tanggal, dan aktivitas rutin.', ['Jam dan menit', 'に untuk waktu', 'Kosakata hari dan tanggal'], 'Bisa mengatakan jadwal harian.', ['Waktu', 'に']),
    PathChapter('path-n5-05', 5, 'N5', 'Pergi & transportasi', 'Berbicara tentang tujuan dan kendaraan.', ['へ・に untuk tujuan', 'で untuk alat transportasi', 'いきます・きます・かえります'], 'Bisa menjelaskan perjalanan.', ['へ', 'に', 'で']),
    PathChapter('path-n5-06', 6, 'N5', 'Aktivitas harian', 'Menceritakan apa yang dilakukan.', ['Kata kerja bentuk ます', 'を sebagai objek', 'と sebagai pasangan'], 'Bisa membuat kalimat aktivitas dasar.', ['ます', 'を', 'と']),
    PathChapter('path-n5-07', 7, 'N5', 'Makan & minum', 'Memesan dan membahas makanan.', ['たべます・のみます', 'を dan で', 'Ungkapan permintaan sederhana'], 'Bisa memesan makanan/minuman.', ['Food', 'ます']),
    PathChapter('path-n5-08', 8, 'N5', 'Sifat benda & orang', 'Menjelaskan bagus, ramai, mahal, dan sejenisnya.', ['い-adjective', 'な-adjective', 'Bentuk positif sederhana'], 'Bisa mendeskripsikan sesuatu.', ['Adjektiva']),
    PathChapter('path-n5-09', 9, 'N5', 'Kesukaan & kemampuan', 'Menyampaikan suka, tidak suka, dan kemampuan dasar.', ['すきです・きらいです', 'じょうず・へた', 'が sebagai penanda'], 'Bisa membicarakan preferensi.', ['すき', 'が']),
    PathChapter('path-n5-10', 10, 'N5', 'Ada & berada', 'Menyatakan keberadaan orang dan benda.', ['あります・います', 'に untuk lokasi keberadaan', 'Posisi benda'], 'Bisa menjelaskan apa yang ada di suatu tempat.', ['あります', 'います']),
    PathChapter('path-n5-11', 11, 'N5', 'Jumlah & penghitung', 'Jumlah benda, orang, dan kejadian.', ['Counter dasar', 'berapa jumlahnya', 'Partikel umum kuantitas'], 'Bisa menyebut jumlah sederhana.', ['Counter', 'Jumlah']),
    PathChapter('path-n5-12', 12, 'N5', 'Perbandingan', 'Membandingkan dua atau lebih benda.', ['より', 'ほうが', 'いちばん'], 'Bisa menyatakan yang lebih/terbaik.', ['より', 'ほうが']),
    PathChapter('path-n5-13', 13, 'N5', 'Keinginan & undangan', 'Menyatakan ingin melakukan sesuatu.', ['ほしいです', 'たいです', 'ませんか・ましょう'], 'Bisa mengajak dan menyatakan keinginan.', ['たい', 'ましょう']),
    PathChapter('path-n5-14', 14, 'N5', 'Bentuk て', 'Membuka pintu ke banyak pola kerja dasar.', ['てください', 'ている', 'Urutan kegiatan'], 'Bisa meminta seseorang melakukan sesuatu.', ['て形']),
    PathChapter('path-n5-15', 15, 'N5', 'Izin & larangan', 'Aturan, izin, dan tindakan yang sedang berlangsung.', ['てもいいです', 'てはいけません', 'ています'], 'Bisa bertanya izin dan memahami larangan.', ['Izin', 'Larangan']),
    PathChapter('path-n5-16', 16, 'N5', 'Bentuk biasa dasar', 'Mulai memahami bahasa yang lebih santai.', ['Bentuk kamus', 'ない dasar', 'Kalimat pendek informal'], 'Mulai memahami percakapan santai.', ['辞書形', 'ない']),
    PathChapter('path-n5-17', 17, 'N5', 'Pengalaman & kemampuan', 'Menyatakan pernah, bisa, dan tidak bisa.', ['ことがあります', 'bisa/tidak bisa', 'Ungkapan pengalaman'], 'Bisa menceritakan pengalaman sederhana.', ['経験']),
    PathChapter('path-n5-18', 18, 'N5', 'Rencana & kewajiban', 'Rencana masa depan dan kewajiban dasar.', ['つもりです', 'なければなりません', 'でしょう'], 'Bisa menjelaskan rencana dan kewajiban.', ['つもり', '義務']),
    PathChapter('path-n5-19', 19, 'N5', 'Kondisi & cuaca', 'Cuaca, kondisi, dan perubahan sederhana.', ['どうですか', 'なります dasar', 'Kosakata cuaca'], 'Bisa membicarakan keadaan sehari-hari.', ['Cuaca', 'なる']),
    PathChapter('path-n5-20', 20, 'N5', 'Review N5 A', 'Menyatukan pola inti 1–19 melalui dialog.', ['Dialog pendek', 'Kotoba inti', 'Kanji tema kehidupan'], 'Mampu mengikuti percakapan sangat sederhana.', ['Review']),
    PathChapter('path-n5-21', 21, 'N5', 'Cerita pendek N5', 'Membaca cerita pendek dengan konteks nyata.', ['Kana lancar', 'Kosakata berfrekuensi tinggi', 'Kalimat berantai'], 'Bisa memahami gagasan utama cerita pendek.', ['Reading', 'Story']),
    PathChapter('path-n5-22', 22, 'N5', 'Listening N5', 'Menangkap informasi penting dari percakapan lambat.', ['Kata kunci', 'Angka dan waktu', 'Dialog sehari-hari'], 'Bisa menangkap informasi utama.', ['Listening']),
    PathChapter('path-n5-23', 23, 'N5', 'Kanji N5 terapan', 'Menghubungkan kanji dengan kata yang sudah dipelajari.', ['Kanji angka/waktu/orang/tempat', 'Onyomi dan kunyomi dasar', 'Kata majemuk sederhana'], 'Bisa membaca kanji N5 dalam kata.', ['Kanji']),
    PathChapter('path-n5-24', 24, 'N5', 'Simulasi N5', 'Latihan terpadu seperti mini ujian.', ['Kotoba', 'Bunpou', 'Reading', 'Listening'], 'Mencapai akurasi minimal 80%.', ['Mock']),
    PathChapter('path-n5-25', 25, 'N5', 'Uji Penguasaan N5', 'Checkpoint akhir sebelum membuka N4.', ['Review semua bab', 'Kanji dan kosakata', 'Cerita dan pemahaman'], 'Lulus penguasaan N5.', ['Mastery', 'Final']),
  ],
  'N4': [for (var i = 1; i <= 25; i++) _genericChapter('N4', i)],
  'N3': [for (var i = 1; i <= 20; i++) _genericChapter('N3', i)],
  'N2': [for (var i = 1; i <= 15; i++) _genericChapter('N2', i)],
  'N1': [for (var i = 1; i <= 14; i++) _genericChapter('N1', i)],
};

/// Bab pertama yang belum selesai (menghormati urutan kunci berantai).
/// Null bila semua bab level ini selesai.
PathChapter? nextPathChapter(String level, Set<String> completedIds) {
  final chapters = curriculum[level];
  if (chapters == null) return null;
  for (final c in chapters) {
    if (!completedIds.contains(c.id)) return c;
  }
  return null;
}

PathChapter _genericChapter(String level, int i) {
  final names = {
    1: 'Orientasi & fondasi',
    2: 'Rutinitas & pengalaman',
    3: 'Orang & lingkungan',
    4: 'Waktu & perubahan',
    5: 'Sebab & tujuan',
    6: 'Permintaan & layanan',
    7: 'Pendapat & preferensi',
    8: 'Kondisi & kemungkinan',
    9: 'Perbandingan & penjelasan',
    10: 'Cerita & urutan kejadian',
    11: 'Keinginan & keputusan',
    12: 'Bahasa kerja & sosial',
    13: 'Bacaan & listening',
    14: 'Review terpadu',
    15: 'Uji penguasaan',
    16: 'Nuansa makna',
    17: 'Argumen & alasan',
    18: 'Berita & informasi',
    19: 'Diskusi & pendapat',
    20: 'Checkpoint',
    21: 'Bahasa formal',
    22: 'Keigo terapan',
    23: 'Bacaan panjang',
    24: 'Simulasi',
    25: 'Ujian level',
  };
  final title = names[i] ?? 'Materi lanjutan';
  return PathChapter('path-${level.toLowerCase()}-${_n(i)}', i, level, title, 'Materi ${level} bab $i dengan alur yang terstruktur dan progresif.', ['Materi inti ${level}', 'Kotoba bertema', 'Bunpou dan contoh kalimat', 'Kanji sesuai konteks', 'Latihan pemahaman'], 'Bisa menggunakan materi bab ini dalam konteks.', ['Kotoba', 'Bunpou', if (i % 3 == 0) 'Kanji' else 'Reading']);
}
