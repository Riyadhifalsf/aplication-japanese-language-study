import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class DialogScreen extends StatefulWidget {
  const DialogScreen({super.key});

  @override
  State<DialogScreen> createState() => _DialogScreenState();
}

class _DialogScreenState extends State<DialogScreen> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final filtered = _dialogLessons.where((lesson) {
      final tabOk = switch (_tab) {
        0 => true,
        1 => !lesson.premium,
        _ => lesson.favorite,
      };
      final q = _query.trim().toLowerCase();
      final queryOk = q.isEmpty ||
          '${lesson.title} ${lesson.category} ${lesson.description} ${lesson.lines.map((e) => '${e.japanese} ${e.reading} ${e.meaning}').join(' ')}'
              .toLowerCase()
              .contains(q);
      return tabOk && queryOk;
    }).toList(growable: false);

    final grouped = <String, List<DialogLesson>>{};
    for (final lesson in filtered) {
      grouped.putIfAbsent(lesson.category, () => []).add(lesson);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialog'),
        actions: [
          IconButton(
            tooltip: 'Urutkan',
            onPressed: () => setState(() => _dialogLessons.sort((a, b) => a.title.compareTo(b.title))),
            icon: const Icon(Icons.sort_rounded),
          ),
          IconButton(
            tooltip: 'Latihan mendengar',
            onPressed: () => app.tts.speak('会話を練習しましょう'),
            icon: const Icon(Icons.hearing_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          _DialogHero(total: _dialogLessons.length),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Semua'), icon: Icon(Icons.forum_rounded)),
              ButtonSegment(value: 1, label: Text('Gratis'), icon: Icon(Icons.lock_open_rounded)),
              ButtonSegment(value: 2, label: Text('Favorit'), icon: Icon(Icons.favorite_rounded)),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Cari dialog, frasa, atau arti',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (grouped.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: EmptyState(
                title: 'Dialog tidak ditemukan',
                message: 'Coba kata kunci lain atau buka bagian Semua.',
              ),
            )
          else
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                child: Text(
                  entry.key.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              for (final lesson in entry.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DialogLessonCard(
                    lesson: lesson,
                    locked: lesson.premium && !app.isPremium,
                    onTap: () {
                      if (lesson.premium && !app.isPremium) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dialog ini tersedia untuk anggota langganan.'),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DialogDetailScreen(lesson: lesson),
                        ),
                      );
                    },
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

class _DialogHero extends StatelessWidget {
  const _DialogHero({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF315C7E), Color(0xFF0D829B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '会話ノート',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dialog Jepang',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total situasi latihan dari kehidupan sehari-hari, sekolah, kerja, layanan, perjalanan, dan percakapan santai.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DialogLessonCard extends StatelessWidget {
  const _DialogLessonCard({required this.lesson, required this.locked, required this.onTap});

  final DialogLesson lesson;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = locked ? Theme.of(context).colorScheme.outline : const Color(0xFF315C7E);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: locked ? .62 : 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(lesson.icon, color: color, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        lesson.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          JlptBadge(lesson.level, compact: true),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${lesson.lines.length} baris percakapan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(locked ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded, size: 20, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DialogDetailScreen extends StatefulWidget {
  const DialogDetailScreen({required this.lesson, super.key});

  final DialogLesson lesson;

  @override
  State<DialogDetailScreen> createState() => _DialogDetailScreenState();
}

class _DialogDetailScreenState extends State<DialogDetailScreen> {
  bool _showReading = true;
  bool _showMeaning = true;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Dengarkan semua',
            onPressed: () => app.tts.speak(lesson.lines.map((e) => e.japanese).join('。')),
            icon: const Icon(Icons.play_circle_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Icon(lesson.icon, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.category, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(lesson.description, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: _showReading,
                label: const Text('Bacaan'),
                onSelected: (value) => setState(() => _showReading = value),
              ),
              FilterChip(
                selected: _showMeaning,
                label: const Text('Arti Indonesia'),
                onSelected: (value) => setState(() => _showMeaning = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lesson.lines.length; i++)
            _DialogBubble(
              line: lesson.lines[i],
              right: i.isOdd,
              showReading: _showReading,
              showMeaning: _showMeaning,
              onSpeak: () => app.tts.speak(lesson.lines[i].japanese),
              onTools: () => _showLineTools(context, lesson.lines[i]),
            ),
          const SizedBox(height: 12),
          _PracticeCard(lesson: lesson),
        ],
      ),
    );
  }

  void _showLineTools(BuildContext context, DialogLine line) {
    final app = AppScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.japanese, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(line.reading, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(line.meaning),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => app.tts.speak(line.japanese),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Suara'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.translate_rounded),
                    label: const Text('Terjemahan'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Cari terkait'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogBubble extends StatelessWidget {
  const _DialogBubble({
    required this.line,
    required this.right,
    required this.showReading,
    required this.showMeaning,
    required this.onSpeak,
    required this.onTools,
  });

  final DialogLine line;
  final bool right;
  final bool showReading;
  final bool showMeaning;
  final VoidCallback onSpeak;
  final VoidCallback onTools;

  @override
  Widget build(BuildContext context) {
    final color = right ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest;
    final align = right ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTools,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(line.speaker, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: 'Bunyikan',
                        onPressed: onSpeak,
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                      ),
                    ],
                  ),
                  Text(line.japanese, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.45)),
                  if (showReading) ...[
                    const SizedBox(height: 4),
                    Text(line.reading, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                  ],
                  if (showMeaning) ...[
                    const SizedBox(height: 6),
                    Text(line.meaning, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.lesson});

  final DialogLesson lesson;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Latihan cepat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text('1. Dengarkan semua dialog.\n2. Ulangi per baris.\n3. Tutup arti, lalu jawab dengan pola yang sama.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in lesson.tags)
                  Chip(label: Text(tag)),
              ],
            ),
          ],
        ),
      );
}

class DialogLesson {
  const DialogLesson({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.level,
    required this.icon,
    required this.lines,
    required this.tags,
    this.premium = false,
    this.favorite = false,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String level;
  final IconData icon;
  final List<DialogLine> lines;
  final List<String> tags;
  final bool premium;
  final bool favorite;
}

class DialogLine {
  const DialogLine({required this.speaker, required this.japanese, required this.reading, required this.meaning});
  final String speaker;
  final String japanese;
  final String reading;
  final String meaning;
}

final List<DialogLesson> _dialogLessons = [
  DialogLesson(
    id: 'greeting_morning',
    category: 'Salam',
    title: 'Salam pagi',
    description: 'Menyapa orang di pagi hari dengan sopan.',
    level: 'N5',
    icon: Icons.wb_sunny_rounded,
    favorite: true,
    tags: ['salam', 'sopan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'おはようございます。', reading: 'ohayou gozaimasu.', meaning: 'Selamat pagi.'),
      DialogLine(speaker: 'B', japanese: 'おはようございます。今日は早いですね。', reading: 'ohayou gozaimasu. kyou wa hayai desu ne.', meaning: 'Selamat pagi. Hari ini datang lebih awal ya.'),
      DialogLine(speaker: 'A', japanese: 'はい、少し勉強したいです。', reading: 'hai, sukoshi benkyou shitai desu.', meaning: 'Ya, saya ingin belajar sebentar.'),
      DialogLine(speaker: 'B', japanese: '頑張ってください。', reading: 'ganbatte kudasai.', meaning: 'Semangat ya.'),
    ],
  ),
  DialogLesson(
    id: 'self_intro',
    category: 'Perkenalan',
    title: 'Memperkenalkan diri',
    description: 'Nama, asal, dan alasan belajar bahasa Jepang.',
    level: 'N5',
    icon: Icons.person_rounded,
    favorite: true,
    tags: ['perkenalan', 'sopan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'はじめまして。リヤディファルです。', reading: 'hajimemashite. Riyadhifaru desu.', meaning: 'Salam kenal. Saya Riyadhifal.'),
      DialogLine(speaker: 'B', japanese: 'はじめまして。どちらから来ましたか。', reading: 'hajimemashite. dochira kara kimashita ka.', meaning: 'Salam kenal. Anda berasal dari mana?'),
      DialogLine(speaker: 'A', japanese: 'インドネシアから来ました。', reading: 'indoneshia kara kimashita.', meaning: 'Saya berasal dari Indonesia.'),
      DialogLine(speaker: 'B', japanese: '日本語を勉強しているんですか。', reading: 'nihongo o benkyou shite iru n desu ka.', meaning: 'Apakah Anda sedang belajar bahasa Jepang?'),
      DialogLine(speaker: 'A', japanese: 'はい、日本で働きたいです。', reading: 'hai, nihon de hatarakitai desu.', meaning: 'Ya, saya ingin bekerja di Jepang.'),
    ],
  ),
  DialogLesson(
    id: 'ask_name',
    category: 'Perkenalan',
    title: 'Menanyakan nama',
    description: 'Menanyakan nama dan cara memanggil seseorang.',
    level: 'N5',
    icon: Icons.badge_rounded,

    tags: ['nama', 'perkenalan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'お名前は何ですか。', reading: 'onamae wa nan desu ka.', meaning: 'Siapa nama Anda?'),
      DialogLine(speaker: 'B', japanese: '山田です。', reading: 'yamada desu.', meaning: 'Saya Yamada.'),
      DialogLine(speaker: 'A', japanese: '何と呼べばいいですか。', reading: 'nan to yobeba ii desu ka.', meaning: 'Saya sebaiknya memanggil Anda apa?'),
      DialogLine(speaker: 'B', japanese: '山田で大丈夫です。', reading: 'yamada de daijoubu desu.', meaning: 'Panggil Yamada saja tidak apa-apa.'),
    ],
  ),
  DialogLesson(
    id: 'school_homework',
    category: 'Sekolah',
    title: 'Menanyakan PR',
    description: 'Bertanya tugas dan batas waktu kepada teman kelas.',
    level: 'N5',
    icon: Icons.school_rounded,
    favorite: true,
    tags: ['sekolah', 'teman', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '今日の宿題は何だった。', reading: 'kyou no shukudai wa nan datta.', meaning: 'PR hari ini apa tadi?'),
      DialogLine(speaker: 'B', japanese: '教科書の二十ページを読んで、質問に答えるんだよ。', reading: 'kyoukasho no nijuu peeji o yonde, shitsumon ni kotaerun da yo.', meaning: 'Baca halaman 20 buku teks, lalu jawab pertanyaannya.'),
      DialogLine(speaker: 'A', japanese: 'いつまでに出せばいい。', reading: 'itsu made ni daseba ii.', meaning: 'Harus dikumpulkan sampai kapan?'),
      DialogLine(speaker: 'B', japanese: '明日の朝まで。忘れないでね。', reading: 'ashita no asa made. wasurenaide ne.', meaning: 'Sampai besok pagi. Jangan lupa ya.'),
    ],
  ),
  DialogLesson(
    id: 'borrow_eraser',
    category: 'Sekolah',
    title: 'Meminjam penghapus',
    description: 'Meminta izin meminjam alat tulis.',
    level: 'N5',
    icon: Icons.edit_rounded,

    tags: ['sekolah', 'permintaan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'すみません、消しゴムを貸してくれませんか。', reading: 'sumimasen, keshigomu o kashite kuremasen ka.', meaning: 'Permisi, boleh pinjam penghapus?'),
      DialogLine(speaker: 'B', japanese: 'いいですよ。どうぞ。', reading: 'ii desu yo. douzo.', meaning: 'Boleh. Silakan.'),
      DialogLine(speaker: 'A', japanese: 'ありがとうございます。すぐ返します。', reading: 'arigatou gozaimasu. sugu kaeshimasu.', meaning: 'Terima kasih. Segera saya kembalikan.'),
      DialogLine(speaker: 'B', japanese: 'ゆっくり使ってください。', reading: 'yukkuri tsukatte kudasai.', meaning: 'Pakai saja dengan santai.'),
    ],
  ),
  DialogLesson(
    id: 'teacher_question',
    category: 'Sekolah',
    title: 'Bertanya kepada guru',
    description: 'Meminta penjelasan ulang dengan sopan.',
    level: 'N5',
    icon: Icons.help_outline_rounded,

    tags: ['sekolah', 'tata bahasa', 'sopan'],
    lines: const [
      DialogLine(speaker: '学生', japanese: '先生、質問があります。', reading: 'sensei, shitsumon ga arimasu.', meaning: 'Sensei, saya punya pertanyaan.'),
      DialogLine(speaker: '先生', japanese: 'はい、何ですか。', reading: 'hai, nan desu ka.', meaning: 'Ya, apa?'),
      DialogLine(speaker: '学生', japanese: 'この文法をもう一度説明していただけますか。', reading: 'kono bunpou o mou ichido setsumei shite itadakemasu ka.', meaning: 'Bisakah menjelaskan tata bahasa ini sekali lagi?'),
      DialogLine(speaker: '先生', japanese: 'もちろんです。例文から見ましょう。', reading: 'mochiron desu. reibun kara mimashou.', meaning: 'Tentu. Mari kita lihat dari contoh kalimat.'),
    ],
  ),
  DialogLesson(
    id: 'club_invite',
    category: 'Sekolah',
    title: 'Diajak masuk klub',
    description: 'Menerima atau menanyakan kegiatan klub sekolah.',
    level: 'N4',
    icon: Icons.groups_rounded,

    tags: ['sekolah', 'klub', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '放課後、サッカー部を見に来ない。', reading: 'houkago, sakkaa-bu o mi ni konai.', meaning: 'Setelah sekolah, mau lihat klub sepak bola?'),
      DialogLine(speaker: 'B', japanese: 'いいね。何時から。', reading: 'ii ne. nanji kara.', meaning: 'Boleh. Mulai jam berapa?'),
      DialogLine(speaker: 'A', japanese: '四時からだよ。', reading: 'yoji kara da yo.', meaning: 'Mulai jam empat.'),
      DialogLine(speaker: 'B', japanese: 'じゃあ、一緒に行こう。', reading: 'jaa, issho ni ikou.', meaning: 'Kalau begitu, ayo pergi bersama.'),
    ],
  ),
  DialogLesson(
    id: 'library_book',
    category: 'Sekolah',
    title: 'Meminjam buku perpustakaan',
    description: 'Menanyakan masa pinjam dan perpanjangan buku.',
    level: 'N4',
    icon: Icons.local_library_rounded,

    tags: ['perpustakaan', 'sekolah'],
    lines: const [
      DialogLine(speaker: '学生', japanese: 'この本を借りたいです。', reading: 'kono hon o karitai desu.', meaning: 'Saya ingin meminjam buku ini.'),
      DialogLine(speaker: '係員', japanese: '学生証を見せてください。', reading: 'gakuseishou o misete kudasai.', meaning: 'Tolong tunjukkan kartu pelajar.'),
      DialogLine(speaker: '学生', japanese: '何日借りられますか。', reading: 'nannichi kariraremasu ka.', meaning: 'Bisa dipinjam berapa hari?'),
      DialogLine(speaker: '係員', japanese: '二週間です。必要なら延長できます。', reading: 'nishuukan desu. hitsuyou nara enchou dekimasu.', meaning: 'Dua minggu. Jika perlu bisa diperpanjang.'),
    ],
  ),
  DialogLesson(
    id: 'restaurant_order',
    category: 'Restoran',
    title: 'Melakukan pemesanan',
    description: 'Memesan makanan, meminta rekomendasi, dan memilih menu dengan sopan.',
    level: 'N5',
    icon: Icons.restaurant_rounded,
    favorite: true,
    tags: ['restoran', 'pesan makanan', 'sopan'],
    lines: const [
      DialogLine(speaker: '店員', japanese: 'いらっしゃいませ。何名様ですか。', reading: 'irasshaimase. nan mei sama desu ka.', meaning: 'Selamat datang. Untuk berapa orang?'),
      DialogLine(speaker: '客', japanese: '二人です。窓の近くの席はありますか。', reading: 'futari desu. mado no chikaku no seki wa arimasu ka.', meaning: 'Dua orang. Apakah ada kursi dekat jendela?'),
      DialogLine(speaker: '店員', japanese: 'はい、こちらへどうぞ。', reading: 'hai, kochira e douzo.', meaning: 'Ya, silakan ke sini.'),
      DialogLine(speaker: '客', japanese: 'おすすめは何ですか。', reading: 'osusume wa nan desu ka.', meaning: 'Rekomendasinya apa?'),
      DialogLine(speaker: '店員', japanese: '今日は味噌ラーメンが人気です。', reading: 'kyou wa miso raamen ga ninki desu.', meaning: 'Hari ini miso ramen populer.'),
      DialogLine(speaker: '客', japanese: 'では、それを一つお願いします。', reading: 'dewa, sore o hitotsu onegai shimasu.', meaning: 'Kalau begitu, saya pesan satu itu.'),
    ],
  ),
  DialogLesson(
    id: 'restaurant_allergy',
    category: 'Restoran',
    title: 'Menanyakan bahan makanan',
    description: 'Menyampaikan alergi sebelum memesan.',
    level: 'N4',
    icon: Icons.no_food_rounded,

    tags: ['restoran', 'alergi'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、これは卵が入っていますか。', reading: 'sumimasen, kore wa tamago ga haitte imasu ka.', meaning: 'Permisi, apakah ini mengandung telur?'),
      DialogLine(speaker: '店員', japanese: 'はい、少し入っています。', reading: 'hai, sukoshi haitte imasu.', meaning: 'Ya, ada sedikit.'),
      DialogLine(speaker: '客', japanese: '卵アレルギーがあります。卵なしにできますか。', reading: 'tamago arerugii ga arimasu. tamago nashi ni dekimasu ka.', meaning: 'Saya alergi telur. Bisa dibuat tanpa telur?'),
      DialogLine(speaker: '店員', japanese: '確認しますので、少々お待ちください。', reading: 'kakunin shimasu node, shoushou omachi kudasai.', meaning: 'Saya cek dulu, mohon tunggu sebentar.'),
    ],
  ),
  DialogLesson(
    id: 'restaurant_bill',
    category: 'Restoran',
    title: 'Meminta tagihan',
    description: 'Meminta pembayaran dan memisahkan tagihan.',
    level: 'N5',
    icon: Icons.receipt_long_rounded,

    tags: ['restoran', 'pembayaran'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、お会計をお願いします。', reading: 'sumimasen, okaikei o onegai shimasu.', meaning: 'Permisi, minta tagihannya.'),
      DialogLine(speaker: '店員', japanese: 'かしこまりました。', reading: 'kashikomarimashita.', meaning: 'Baik.'),
      DialogLine(speaker: '客', japanese: '別々に払えますか。', reading: 'betsubetsu ni haraemasu ka.', meaning: 'Apakah bisa bayar terpisah?'),
      DialogLine(speaker: '店員', japanese: 'はい、できます。', reading: 'hai, dekimasu.', meaning: 'Ya, bisa.'),
    ],
  ),
  DialogLesson(
    id: 'cafe_order',
    category: 'Kafe',
    title: 'Memesan minuman',
    description: 'Memesan minuman dan memilih ukuran.',
    level: 'N5',
    icon: Icons.local_cafe_rounded,

    tags: ['kafe', 'pesanan'],
    lines: const [
      DialogLine(speaker: '店員', japanese: 'ご注文はお決まりですか。', reading: 'gochuumon wa okimari desu ka.', meaning: 'Apakah pesanannya sudah dipilih?'),
      DialogLine(speaker: '客', japanese: 'アイスコーヒーをお願いします。', reading: 'aisu koohii o onegai shimasu.', meaning: 'Saya pesan kopi dingin.'),
      DialogLine(speaker: '店員', japanese: 'サイズはいかがしますか。', reading: 'saizu wa ikaga shimasu ka.', meaning: 'Mau ukuran apa?'),
      DialogLine(speaker: '客', japanese: 'Mサイズでお願いします。', reading: 'emu saizu de onegai shimasu.', meaning: 'Ukuran M, ya.'),
    ],
  ),
  DialogLesson(
    id: 'convenience_payment',
    category: 'Konbini',
    title: 'Membayar di konbini',
    description: 'Menjawab pertanyaan kasir saat pembayaran.',
    level: 'N5',
    icon: Icons.store_rounded,

    tags: ['konbini', 'pembayaran'],
    lines: const [
      DialogLine(speaker: '店員', japanese: '袋はご利用ですか。', reading: 'fukuro wa goriyou desu ka.', meaning: 'Apakah perlu kantong?'),
      DialogLine(speaker: '客', japanese: 'いいえ、大丈夫です。', reading: 'iie, daijoubu desu.', meaning: 'Tidak, tidak perlu.'),
      DialogLine(speaker: '店員', japanese: '温めますか。', reading: 'atatamemasu ka.', meaning: 'Mau dipanaskan?'),
      DialogLine(speaker: '客', japanese: 'はい、お願いします。', reading: 'hai, onegai shimasu.', meaning: 'Ya, tolong.'),
      DialogLine(speaker: '店員', japanese: 'お支払いは現金ですか。', reading: 'oshiharai wa genkin desu ka.', meaning: 'Pembayarannya tunai?'),
      DialogLine(speaker: '客', japanese: 'カードでお願いします。', reading: 'kaado de onegai shimasu.', meaning: 'Dengan kartu, ya.'),
    ],
  ),
  DialogLesson(
    id: 'shopping_size',
    category: 'Belanja',
    title: 'Mencari ukuran pakaian',
    description: 'Menanyakan ukuran dan mencoba pakaian.',
    level: 'N5',
    icon: Icons.checkroom_rounded,

    tags: ['belanja', 'pakaian'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、これのLサイズはありますか。', reading: 'sumimasen, kore no eru saizu wa arimasu ka.', meaning: 'Permisi, apakah ada ukuran L untuk ini?'),
      DialogLine(speaker: '店員', japanese: 'はい、ございます。', reading: 'hai, gozaimasu.', meaning: 'Ya, ada.'),
      DialogLine(speaker: '客', japanese: '試着してもいいですか。', reading: 'shichaku shite mo ii desu ka.', meaning: 'Boleh saya coba?'),
      DialogLine(speaker: '店員', japanese: 'もちろんです。試着室はこちらです。', reading: 'mochiron desu. shichakushitsu wa kochira desu.', meaning: 'Tentu. Ruang pas ada di sini.'),
    ],
  ),
  DialogLesson(
    id: 'shopping_discount',
    category: 'Belanja',
    title: 'Menanyakan diskon',
    description: 'Menanyakan harga dan potongan harga.',
    level: 'N4',
    icon: Icons.sell_rounded,

    tags: ['belanja', 'harga'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'この靴はいくらですか。', reading: 'kono kutsu wa ikura desu ka.', meaning: 'Sepatu ini berapa harganya?'),
      DialogLine(speaker: '店員', japanese: '八千円です。', reading: 'hassen en desu.', meaning: 'Delapan ribu yen.'),
      DialogLine(speaker: '客', japanese: 'セールになっていますか。', reading: 'seeru ni natte imasu ka.', meaning: 'Apakah sedang mendapat potongan harga?'),
      DialogLine(speaker: '店員', japanese: 'はい、今日は二割引きです。', reading: 'hai, kyou wa niwari-biki desu.', meaning: 'Ya, hari ini diskon 20 persen.'),
    ],
  ),
  DialogLesson(
    id: 'supermarket_location',
    category: 'Belanja',
    title: 'Mencari barang di supermarket',
    description: 'Menanyakan letak barang.',
    level: 'N5',
    icon: Icons.shopping_cart_rounded,

    tags: ['belanja', 'supermarket'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、牛乳はどこですか。', reading: 'sumimasen, gyuunyuu wa doko desu ka.', meaning: 'Permisi, susu ada di mana?'),
      DialogLine(speaker: '店員', japanese: '奥の冷蔵コーナーにあります。', reading: 'oku no reizou koonaa ni arimasu.', meaning: 'Ada di bagian pendingin di belakang.'),
      DialogLine(speaker: '客', japanese: 'パンの近くですか。', reading: 'pan no chikaku desu ka.', meaning: 'Dekat roti?'),
      DialogLine(speaker: '店員', japanese: 'はい、その隣です。', reading: 'hai, sono tonari desu.', meaning: 'Ya, di sebelahnya.'),
    ],
  ),
  DialogLesson(
    id: 'station_direction',
    category: 'Transportasi',
    title: 'Menanyakan jalan ke stasiun',
    description: 'Bertanya arah menuju stasiun dan memahami petunjuk.',
    level: 'N5',
    icon: Icons.train_rounded,

    tags: ['arah', 'stasiun', 'perjalanan'],
    lines: const [
      DialogLine(speaker: '旅行者', japanese: 'すみません、駅はどこですか。', reading: 'sumimasen, eki wa doko desu ka.', meaning: 'Permisi, stasiun di mana?'),
      DialogLine(speaker: '人', japanese: 'この道をまっすぐ行って、右に曲がってください。', reading: 'kono michi o massugu itte, migi ni magatte kudasai.', meaning: 'Jalan lurus di jalan ini, lalu belok kanan.'),
      DialogLine(speaker: '旅行者', japanese: '歩いて何分ぐらいですか。', reading: 'aruite nan pun gurai desu ka.', meaning: 'Kira-kira berapa menit jalan kaki?'),
      DialogLine(speaker: '人', japanese: '十分ぐらいです。', reading: 'juppun gurai desu.', meaning: 'Sekitar 10 menit.'),
    ],
  ),
  DialogLesson(
    id: 'train_transfer',
    category: 'Transportasi',
    title: 'Bertanya pindah kereta',
    description: 'Menanyakan jalur dan tempat transit.',
    level: 'N4',
    icon: Icons.alt_route_rounded,

    tags: ['kereta', 'transit'],
    lines: const [
      DialogLine(speaker: '客', japanese: '新宿へ行きたいんですが、どこで乗り換えますか。', reading: 'shinjuku e ikitain desu ga, doko de norikaemasu ka.', meaning: 'Saya ingin ke Shinjuku. Harus transit di mana?'),
      DialogLine(speaker: '駅員', japanese: '東京駅で中央線に乗り換えてください。', reading: 'toukyou-eki de chuousen ni norikaete kudasai.', meaning: 'Silakan pindah ke Jalur Chuo di Stasiun Tokyo.'),
      DialogLine(speaker: '客', japanese: '何番線ですか。', reading: 'nanbansen desu ka.', meaning: 'Peron nomor berapa?'),
      DialogLine(speaker: '駅員', japanese: '五番線です。', reading: 'gobansen desu.', meaning: 'Peron nomor lima.'),
    ],
  ),
  DialogLesson(
    id: 'ic_recharge',
    category: 'Transportasi',
    title: 'Mengisi saldo kartu IC',
    description: 'Menanyakan cara mengisi saldo kartu transportasi.',
    level: 'N5',
    icon: Icons.credit_card_rounded,

    tags: ['transportasi', 'kartu IC'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'このカードにお金を入れたいです。', reading: 'kono kaado ni okane o iretai desu.', meaning: 'Saya ingin mengisi saldo kartu ini.'),
      DialogLine(speaker: '駅員', japanese: 'チャージですね。券売機でできます。', reading: 'chaaji desu ne. kenbaiki de dekimasu.', meaning: 'Isi saldo ya. Bisa dilakukan di mesin tiket.'),
      DialogLine(speaker: '客', japanese: '二千円入れたいです。', reading: 'nisen en iretai desu.', meaning: 'Saya ingin mengisi dua ribu yen.'),
      DialogLine(speaker: '駅員', japanese: 'このボタンを押してください。', reading: 'kono botan o oshite kudasai.', meaning: 'Silakan tekan tombol ini.'),
    ],
  ),
  DialogLesson(
    id: 'bus_route',
    category: 'Transportasi',
    title: 'Menanyakan bus',
    description: 'Memastikan bus menuju tempat yang benar.',
    level: 'N5',
    icon: Icons.directions_bus_rounded,

    tags: ['bus', 'arah'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'このバスは市役所へ行きますか。', reading: 'kono basu wa shiyakusho e ikimasu ka.', meaning: 'Apakah bus ini pergi ke balai kota?'),
      DialogLine(speaker: '運転手', japanese: 'はい、行きます。', reading: 'hai, ikimasu.', meaning: 'Ya.'),
      DialogLine(speaker: '客', japanese: '何番目の停留所ですか。', reading: 'nanbanme no teiryuujo desu ka.', meaning: 'Pemberhentian ke berapa?'),
      DialogLine(speaker: '運転手', japanese: '五つ目です。', reading: 'itsuttsu-me desu.', meaning: 'Yang kelima.'),
    ],
  ),
  DialogLesson(
    id: 'taxi_destination',
    category: 'Transportasi',
    title: 'Naik taksi',
    description: 'Menyebut tujuan dan meminta berhenti.',
    level: 'N5',
    icon: Icons.local_taxi_rounded,

    tags: ['taksi', 'perjalanan'],
    lines: const [
      DialogLine(speaker: '客', japanese: '東京駅までお願いします。', reading: 'toukyou-eki made onegai shimasu.', meaning: 'Tolong ke Stasiun Tokyo.'),
      DialogLine(speaker: '運転手', japanese: 'かしこまりました。', reading: 'kashikomarimashita.', meaning: 'Baik.'),
      DialogLine(speaker: '客', japanese: 'この近くで止めてください。', reading: 'kono chikaku de tomete kudasai.', meaning: 'Tolong berhenti di dekat sini.'),
      DialogLine(speaker: '運転手', japanese: 'はい、こちらでよろしいですか。', reading: 'hai, kochira de yoroshii desu ka.', meaning: 'Baik, apakah di sini tidak apa-apa?'),
    ],
  ),
  DialogLesson(
    id: 'hotel_checkin',
    category: 'Hotel',
    title: 'Lapor masuk hotel',
    description: 'Menunjukkan reservasi dan menerima kunci kamar.',
    level: 'N5',
    icon: Icons.hotel_rounded,

    tags: ['hotel', 'reservasi'],
    lines: const [
      DialogLine(speaker: '客', japanese: '予約しているアディです。', reading: 'yoyaku shite iru adi desu.', meaning: 'Saya Adi yang sudah memesan kamar.'),
      DialogLine(speaker: '受付', japanese: 'パスポートを見せていただけますか。', reading: 'pasupooto o misete itadakemasu ka.', meaning: 'Bolehkah saya melihat paspor Anda?'),
      DialogLine(speaker: '客', japanese: 'はい、どうぞ。', reading: 'hai, douzo.', meaning: 'Ya, silakan.'),
      DialogLine(speaker: '受付', japanese: 'ありがとうございます。お部屋は五階です。', reading: 'arigatou gozaimasu. oheya wa gokai desu.', meaning: 'Terima kasih. Kamar Anda di lantai lima.'),
    ],
  ),
  DialogLesson(
    id: 'hotel_wifi',
    category: 'Hotel',
    title: 'Menanyakan Wi-Fi hotel',
    description: 'Menanyakan sandi dan lokasi jaringan internet.',
    level: 'N5',
    icon: Icons.wifi_rounded,

    tags: ['hotel', 'internet'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、Wi-Fiのパスワードは何ですか。', reading: 'sumimasen, waifai no pasuwaado wa nan desu ka.', meaning: 'Permisi, apa kata sandi Wi-Fi?'),
      DialogLine(speaker: '受付', japanese: 'こちらのカードに書いてあります。', reading: 'kochira no kaado ni kaite arimasu.', meaning: 'Tertulis di kartu ini.'),
      DialogLine(speaker: '客', japanese: '部屋でも使えますか。', reading: 'heya demo tsukaemasu ka.', meaning: 'Bisa dipakai di kamar juga?'),
      DialogLine(speaker: '受付', japanese: 'はい、全館で使えます。', reading: 'hai, zenkan de tsukaemasu.', meaning: 'Ya, bisa digunakan di seluruh hotel.'),
    ],
  ),
  DialogLesson(
    id: 'airport_luggage',
    category: 'Bandara',
    title: 'Bagasi yang hilang',
    description: 'Melapor kehilangan bagasi di bandara dengan kalimat resmi.',
    level: 'N3',
    icon: Icons.luggage_rounded,
    premium: true,
    tags: ['bandara', 'resmi', 'masalah'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、荷物が見つかりません。', reading: 'sumimasen, nimotsu ga mitsukarimasen.', meaning: 'Permisi, barang saya tidak ditemukan.'),
      DialogLine(speaker: '係員', japanese: 'お荷物番号を見せていただけますか。', reading: 'onimotsu bangou o misete itadakemasu ka.', meaning: 'Bolehkah saya melihat nomor bagasi Anda?'),
      DialogLine(speaker: '客', japanese: 'はい、こちらです。赤いスーツケースです。', reading: 'hai, kochira desu. akai suutsukeesu desu.', meaning: 'Ya, ini. Koper saya berwarna merah.'),
      DialogLine(speaker: '係員', japanese: '確認いたしますので、少々お待ちください。', reading: 'kakunin itashimasu node, shoushou omachi kudasai.', meaning: 'Saya akan memeriksa, mohon tunggu sebentar.'),
    ],
  ),
  DialogLesson(
    id: 'airport_gate',
    category: 'Bandara',
    title: 'Mencari gerbang keberangkatan',
    description: 'Menanyakan lokasi gerbang dan waktu naik pesawat.',
    level: 'N4',
    icon: Icons.flight_takeoff_rounded,

    tags: ['bandara', 'penerbangan'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、十二番ゲートはどこですか。', reading: 'sumimasen, juuniban geeto wa doko desu ka.', meaning: 'Permisi, gerbang nomor 12 di mana?'),
      DialogLine(speaker: '係員', japanese: 'まっすぐ行って、左です。', reading: 'massugu itte, hidari desu.', meaning: 'Lurus lalu di sebelah kiri.'),
      DialogLine(speaker: '客', japanese: '搭乗は何時からですか。', reading: 'toujou wa nanji kara desu ka.', meaning: 'Naik pesawat mulai jam berapa?'),
      DialogLine(speaker: '係員', japanese: '午後二時十分からです。', reading: 'gogo niji juppun kara desu.', meaning: 'Mulai pukul 2 lewat 10 sore.'),
    ],
  ),
  DialogLesson(
    id: 'health_back_pain',
    category: 'Kesehatan',
    title: 'Sakit punggung',
    description: 'Menjelaskan gejala dan meminta saran di klinik.',
    level: 'N4',
    icon: Icons.local_hospital_rounded,

    tags: ['klinik', 'gejala', 'sopan'],
    lines: const [
      DialogLine(speaker: '受付', japanese: '今日はどうされましたか。', reading: 'kyou wa dou saremashita ka.', meaning: 'Hari ini ada keluhan apa?'),
      DialogLine(speaker: '患者', japanese: '昨日から背中が痛いです。', reading: 'kinou kara senaka ga itai desu.', meaning: 'Sejak kemarin punggung saya sakit.'),
      DialogLine(speaker: '医者', japanese: '重い物を持ちましたか。', reading: 'omoi mono o mochimashita ka.', meaning: 'Apakah Anda mengangkat barang berat?'),
      DialogLine(speaker: '患者', japanese: 'はい、引っ越しを手伝いました。', reading: 'hai, hikkoshi o tetsudaimashita.', meaning: 'Ya, saya membantu pindahan.'),
      DialogLine(speaker: '医者', japanese: '今日は無理をしないで、薬を飲んでください。', reading: 'kyou wa muri o shinaide, kusuri o nonde kudasai.', meaning: 'Hari ini jangan memaksakan diri, minumlah obat.'),
    ],
  ),
  DialogLesson(
    id: 'health_fever',
    category: 'Kesehatan',
    title: 'Demam dan batuk',
    description: 'Menjelaskan demam dan batuk kepada dokter.',
    level: 'N5',
    icon: Icons.thermostat_rounded,

    tags: ['kesehatan', 'dokter'],
    lines: const [
      DialogLine(speaker: '医者', japanese: '熱はありますか。', reading: 'netsu wa arimasu ka.', meaning: 'Apakah demam?'),
      DialogLine(speaker: '患者', japanese: 'はい、三十八度あります。', reading: 'hai, sanjuuhachi-do arimasu.', meaning: 'Ya, suhunya 38 derajat.'),
      DialogLine(speaker: '医者', japanese: 'せきは出ますか。', reading: 'seki wa demasu ka.', meaning: 'Apakah batuk?'),
      DialogLine(speaker: '患者', japanese: 'はい、夜にひどくなります。', reading: 'hai, yoru ni hidoku narimasu.', meaning: 'Ya, memburuk pada malam hari.'),
    ],
  ),
  DialogLesson(
    id: 'pharmacy_medicine',
    category: 'Kesehatan',
    title: 'Membeli obat',
    description: 'Menanyakan obat dan cara meminumnya.',
    level: 'N4',
    icon: Icons.medication_rounded,

    tags: ['apotek', 'obat'],
    lines: const [
      DialogLine(speaker: '客', japanese: '頭が痛いんですが、薬はありますか。', reading: 'atama ga itain desu ga, kusuri wa arimasu ka.', meaning: 'Kepala saya sakit, apakah ada obat?'),
      DialogLine(speaker: '薬剤師', japanese: 'こちらはいかがですか。', reading: 'kochira wa ikaga desu ka.', meaning: 'Bagaimana dengan yang ini?'),
      DialogLine(speaker: '客', japanese: '一日に何回飲みますか。', reading: 'ichinichi ni nankai nomimasu ka.', meaning: 'Diminum berapa kali sehari?'),
      DialogLine(speaker: '薬剤師', japanese: '食後に一日三回です。', reading: 'shokugo ni ichinichi sankai desu.', meaning: 'Tiga kali sehari setelah makan.'),
    ],
  ),
  DialogLesson(
    id: 'dentist_visit',
    category: 'Kesehatan',
    title: 'Sakit gigi',
    description: 'Menjelaskan bagian gigi yang sakit.',
    level: 'N4',
    icon: Icons.medical_services_rounded,

    tags: ['dokter gigi', 'kesehatan'],
    lines: const [
      DialogLine(speaker: '歯医者', japanese: 'どの歯が痛いですか。', reading: 'dono ha ga itai desu ka.', meaning: 'Gigi yang mana yang sakit?'),
      DialogLine(speaker: '患者', japanese: '右の奥歯が痛いです。', reading: 'migi no okuba ga itai desu.', meaning: 'Gigi geraham kanan saya sakit.'),
      DialogLine(speaker: '歯医者', japanese: 'いつからですか。', reading: 'itsu kara desu ka.', meaning: 'Sejak kapan?'),
      DialogLine(speaker: '患者', japanese: '三日前からです。', reading: 'mikka mae kara desu.', meaning: 'Sejak tiga hari lalu.'),
    ],
  ),
  DialogLesson(
    id: 'home_delivery',
    category: 'Rumah',
    title: 'Menerima paket',
    description: 'Berbicara dengan kurir saat menerima paket.',
    level: 'N5',
    icon: Icons.inventory_2_rounded,

    tags: ['rumah', 'paket'],
    lines: const [
      DialogLine(speaker: '配達員', japanese: 'お届け物です。', reading: 'otodokemono desu.', meaning: 'Ada paket.'),
      DialogLine(speaker: '住人', japanese: 'はい。どこにサインしますか。', reading: 'hai. doko ni sain shimasu ka.', meaning: 'Ya. Saya tanda tangan di mana?'),
      DialogLine(speaker: '配達員', japanese: 'こちらにお願いします。', reading: 'kochira ni onegai shimasu.', meaning: 'Silakan di sini.'),
      DialogLine(speaker: '住人', japanese: 'ありがとうございます。', reading: 'arigatou gozaimasu.', meaning: 'Terima kasih.'),
    ],
  ),
  DialogLesson(
    id: 'neighbor_greeting',
    category: 'Tetangga',
    title: 'Menyapa tetangga baru',
    description: 'Memperkenalkan diri setelah pindah rumah.',
    level: 'N5',
    icon: Icons.home_work_rounded,

    tags: ['tetangga', 'perkenalan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'はじめまして。隣に引っ越してきたアディです。', reading: 'hajimemashite. tonari ni hikkoshite kita adi desu.', meaning: 'Salam kenal. Saya Adi yang baru pindah ke sebelah.'),
      DialogLine(speaker: 'B', japanese: 'はじめまして。よろしくお願いします。', reading: 'hajimemashite. yoroshiku onegai shimasu.', meaning: 'Salam kenal. Senang berkenalan dengan Anda.'),
      DialogLine(speaker: 'A', japanese: 'これ、よかったらどうぞ。', reading: 'kore, yokattara douzo.', meaning: 'Ini, kalau berkenan silakan.'),
      DialogLine(speaker: 'B', japanese: 'ありがとうございます。', reading: 'arigatou gozaimasu.', meaning: 'Terima kasih.'),
    ],
  ),
  DialogLesson(
    id: 'neighbor_noise',
    category: 'Tetangga',
    title: 'Meminta mengecilkan suara',
    description: 'Menyampaikan keluhan dengan tetap sopan.',
    level: 'N4',
    icon: Icons.volume_down_rounded,

    tags: ['tetangga', 'permintaan', 'sopan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'すみません、少しお願いがあるんですが。', reading: 'sumimasen, sukoshi onegai ga arun desu ga.', meaning: 'Permisi, ada sedikit permintaan.'),
      DialogLine(speaker: 'B', japanese: 'はい、何でしょうか。', reading: 'hai, nan deshou ka.', meaning: 'Ya, ada apa?'),
      DialogLine(speaker: 'A', japanese: '夜はもう少し音を小さくしていただけますか。', reading: 'yoru wa mou sukoshi oto o chiisaku shite itadakemasu ka.', meaning: 'Malam hari bisakah suaranya dikecilkan sedikit?'),
      DialogLine(speaker: 'B', japanese: 'すみません。気をつけます。', reading: 'sumimasen. ki o tsukemasu.', meaning: 'Maaf. Saya akan lebih berhati-hati.'),
    ],
  ),
  DialogLesson(
    id: 'garbage_sorting',
    category: 'Rumah',
    title: 'Menanyakan pemilahan sampah',
    description: 'Memahami hari dan jenis pembuangan sampah.',
    level: 'N4',
    icon: Icons.delete_outline_rounded,

    tags: ['rumah', 'sampah'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '燃えるごみは何曜日ですか。', reading: 'moeru gomi wa nan youbi desu ka.', meaning: 'Sampah yang bisa dibakar dibuang hari apa?'),
      DialogLine(speaker: 'B', japanese: '火曜日と金曜日です。', reading: 'kayoubi to kinyoubi desu.', meaning: 'Hari Selasa dan Jumat.'),
      DialogLine(speaker: 'A', japanese: 'ペットボトルはどうしますか。', reading: 'pettobotoru wa dou shimasu ka.', meaning: 'Bagaimana dengan botol plastik?'),
      DialogLine(speaker: 'B', japanese: 'ラベルを取って、別の袋に入れます。', reading: 'raberu o totte, betsu no fukuro ni iremasu.', meaning: 'Lepas labelnya lalu masukkan ke kantong terpisah.'),
    ],
  ),
  DialogLesson(
    id: 'work_meeting',
    category: 'Kerja',
    title: 'Rapat pagi',
    description: 'Mengabarkan kemajuan kerja dan meminta waktu tambahan.',
    level: 'N3',
    icon: Icons.business_center_rounded,
    premium: true,
    tags: ['kerja', 'keigo', 'rapat'],
    lines: const [
      DialogLine(speaker: '上司', japanese: '昨日の進捗を教えてください。', reading: 'kinou no shinchoku o oshiete kudasai.', meaning: 'Tolong jelaskan kemajuan kemarin.'),
      DialogLine(speaker: '社員', japanese: '資料の作成はほとんど終わりました。', reading: 'shiryou no sakusei wa hotondo owarimashita.', meaning: 'Pembuatan materi hampir selesai.'),
      DialogLine(speaker: '社員', japanese: 'ただ、確認にもう少し時間をいただけますか。', reading: 'tada, kakunin ni mou sukoshi jikan o itadakemasu ka.', meaning: 'Namun, bolehkah saya minta sedikit waktu lagi untuk pengecekan?'),
      DialogLine(speaker: '上司', japanese: '分かりました。午後三時までにお願いします。', reading: 'wakarimashita. gogo sanji made ni onegai shimasu.', meaning: 'Baik. Tolong sampai jam 3 sore.'),
    ],
  ),
  DialogLesson(
    id: 'work_absence',
    category: 'Kerja',
    title: 'Mengabarkan tidak masuk kerja',
    description: 'Menelepon atasan ketika sakit.',
    level: 'N4',
    icon: Icons.sick_rounded,

    tags: ['kerja', 'izin', 'sopan'],
    lines: const [
      DialogLine(speaker: '社員', japanese: 'おはようございます。田中です。', reading: 'ohayou gozaimasu. tanaka desu.', meaning: 'Selamat pagi. Saya Tanaka.'),
      DialogLine(speaker: '上司', japanese: 'おはようございます。どうしましたか。', reading: 'ohayou gozaimasu. dou shimashita ka.', meaning: 'Selamat pagi. Ada apa?'),
      DialogLine(speaker: '社員', japanese: '熱があるため、本日お休みをいただきたいです。', reading: 'netsu ga aru tame, honjitsu oyasumi o itadakitai desu.', meaning: 'Karena demam, hari ini saya ingin meminta izin tidak masuk.'),
      DialogLine(speaker: '上司', japanese: '分かりました。ゆっくり休んでください。', reading: 'wakarimashita. yukkuri yasunde kudasai.', meaning: 'Baik. Istirahatlah dengan cukup.'),
    ],
  ),
  DialogLesson(
    id: 'work_dayoff',
    category: 'Kerja',
    title: 'Meminta cuti',
    description: 'Meminta izin cuti untuk urusan pribadi.',
    level: 'N3',
    icon: Icons.event_available_rounded,
    premium: true,
    tags: ['kerja', 'cuti', 'keigo'],
    lines: const [
      DialogLine(speaker: '社員', japanese: '来週の金曜日にお休みをいただけないでしょうか。', reading: 'raishuu no kinyoubi ni oyasumi o itadakenai deshou ka.', meaning: 'Apakah saya boleh mengambil cuti Jumat depan?'),
      DialogLine(speaker: '上司', japanese: '何か予定がありますか。', reading: 'nanika yotei ga arimasu ka.', meaning: 'Apakah ada keperluan?'),
      DialogLine(speaker: '社員', japanese: '家族の用事があります。', reading: 'kazoku no youji ga arimasu.', meaning: 'Ada urusan keluarga.'),
      DialogLine(speaker: '上司', japanese: '分かりました。引き継ぎだけお願いします。', reading: 'wakarimashita. hikitsugi dake onegai shimasu.', meaning: 'Baik. Tolong pastikan serah terima pekerjaannya.'),
    ],
  ),
  DialogLesson(
    id: 'work_mistake',
    category: 'Kerja',
    title: 'Melaporkan kesalahan',
    description: 'Mengakui kesalahan dan menyampaikan tindakan perbaikan.',
    level: 'N3',
    icon: Icons.report_problem_rounded,
    premium: true,
    tags: ['kerja', 'laporan', 'keigo'],
    lines: const [
      DialogLine(speaker: '社員', japanese: '申し訳ありません。入力ミスがありました。', reading: 'moushiwake arimasen. nyuuryoku misu ga arimashita.', meaning: 'Mohon maaf. Ada kesalahan saat memasukkan data.'),
      DialogLine(speaker: '上司', japanese: 'どの部分ですか。', reading: 'dono bubun desu ka.', meaning: 'Bagian yang mana?'),
      DialogLine(speaker: '社員', japanese: '昨日の売上データです。すぐ修正します。', reading: 'kinou no uriage deeta desu. sugu shuusei shimasu.', meaning: 'Data penjualan kemarin. Saya segera memperbaikinya.'),
      DialogLine(speaker: '上司', japanese: '分かりました。修正後にもう一度確認してください。', reading: 'wakarimashita. shuuseigo ni mou ichido kakunin shite kudasai.', meaning: 'Baik. Setelah diperbaiki, tolong periksa sekali lagi.'),
    ],
  ),
  DialogLesson(
    id: 'parttime_shift',
    category: 'Paruh Waktu',
    title: 'Menukar jadwal kerja',
    description: 'Meminta teman mengganti jadwal kerja paruh waktu.',
    level: 'N4',
    icon: Icons.schedule_rounded,

    tags: ['paruh waktu', 'jadwal', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '今度の土曜日、シフト代わってくれない。', reading: 'kondo no doyoubi, shifuto kawatte kurenai.', meaning: 'Sabtu ini, bisa tukar jadwal kerja denganku?'),
      DialogLine(speaker: 'B', japanese: '何時から。', reading: 'nanji kara.', meaning: 'Mulai jam berapa?'),
      DialogLine(speaker: 'A', japanese: '午後三時から九時まで。', reading: 'gogo sanji kara kuji made.', meaning: 'Dari jam tiga sore sampai sembilan malam.'),
      DialogLine(speaker: 'B', japanese: '大丈夫だよ。日曜日と交換しよう。', reading: 'daijoubu da yo. nichiyoubi to koukan shiyou.', meaning: 'Bisa. Kita tukar dengan hari Minggu.'),
    ],
  ),
  DialogLesson(
    id: 'factory_safety',
    category: 'Pabrik',
    title: 'Memastikan prosedur keselamatan',
    description: 'Bertanya sebelum mengoperasikan mesin.',
    level: 'N4',
    icon: Icons.precision_manufacturing_rounded,

    tags: ['pabrik', 'keselamatan'],
    lines: const [
      DialogLine(speaker: '新人', japanese: 'この機械を使う前に、何を確認しますか。', reading: 'kono kikai o tsukau mae ni, nani o kakunin shimasu ka.', meaning: 'Sebelum memakai mesin ini, apa yang harus diperiksa?'),
      DialogLine(speaker: '先輩', japanese: '安全カバーと非常停止ボタンを確認します。', reading: 'anzen kabaa to hijou teishi botan o kakunin shimasu.', meaning: 'Periksa pelindung keselamatan dan tombol berhenti darurat.'),
      DialogLine(speaker: '新人', japanese: '手袋は必要ですか。', reading: 'tebukuro wa hitsuyou desu ka.', meaning: 'Apakah perlu sarung tangan?'),
      DialogLine(speaker: '先輩', japanese: 'はい。この作業では必ず着けてください。', reading: 'hai. kono sagyou de wa kanarazu tsukete kudasai.', meaning: 'Ya. Untuk pekerjaan ini wajib dipakai.'),
    ],
  ),
  DialogLesson(
    id: 'interview_intro',
    category: 'Wawancara',
    title: 'Perkenalan saat wawancara',
    description: 'Menjawab perkenalan singkat dengan sopan.',
    level: 'N3',
    icon: Icons.record_voice_over_rounded,
    premium: true,
    tags: ['wawancara', 'kerja', 'sopan'],
    lines: const [
      DialogLine(speaker: '面接官', japanese: '自己紹介をお願いします。', reading: 'jikoshoukai o onegai shimasu.', meaning: 'Silakan perkenalkan diri.'),
      DialogLine(speaker: '応募者', japanese: 'リヤディファルと申します。インドネシア出身です。', reading: 'riyadifaru to moushimasu. indoneshia shusshin desu.', meaning: 'Nama saya Riyadhifal. Saya berasal dari Indonesia.'),
      DialogLine(speaker: '応募者', japanese: '二年間、日本語と機械の基礎を勉強してきました。', reading: 'ninenkan, nihongo to kikai no kiso o benkyou shite kimashita.', meaning: 'Selama dua tahun saya mempelajari bahasa Jepang dan dasar mesin.'),
      DialogLine(speaker: '面接官', japanese: 'ありがとうございます。', reading: 'arigatou gozaimasu.', meaning: 'Terima kasih.'),
    ],
  ),
  DialogLesson(
    id: 'interview_reason',
    category: 'Wawancara',
    title: 'Alasan melamar',
    description: 'Menjelaskan alasan memilih perusahaan.',
    level: 'N3',
    icon: Icons.work_outline_rounded,
    premium: true,
    tags: ['wawancara', 'tujuan', 'kerja'],
    lines: const [
      DialogLine(speaker: '面接官', japanese: 'なぜ当社を志望しましたか。', reading: 'naze tousha o shibou shimashita ka.', meaning: 'Mengapa Anda melamar di perusahaan kami?'),
      DialogLine(speaker: '応募者', japanese: '技術を学びながら長く働きたいと思ったからです。', reading: 'gijutsu o manabinagara nagaku hatarakitai to omotta kara desu.', meaning: 'Karena saya ingin bekerja lama sambil mempelajari keterampilan.'),
      DialogLine(speaker: '面接官', japanese: '将来の目標は何ですか。', reading: 'shourai no mokuhyou wa nan desu ka.', meaning: 'Apa tujuan Anda di masa depan?'),
      DialogLine(speaker: '応募者', japanese: '仕事を任せてもらえる技術者になりたいです。', reading: 'shigoto o makasete moraeru gijutsusha ni naritai desu.', meaning: 'Saya ingin menjadi teknisi yang dipercaya menangani pekerjaan.'),
    ],
  ),
  DialogLesson(
    id: 'phone_reservation',
    category: 'Telepon',
    title: 'Membuat reservasi lewat telepon',
    description: 'Memesan meja melalui telepon.',
    level: 'N4',
    icon: Icons.phone_rounded,

    tags: ['telepon', 'reservasi'],
    lines: const [
      DialogLine(speaker: '店員', japanese: 'お電話ありがとうございます。さくらレストランです。', reading: 'odenwa arigatou gozaimasu. sakura resutoran desu.', meaning: 'Terima kasih sudah menelepon. Ini Restoran Sakura.'),
      DialogLine(speaker: '客', japanese: '明日の七時に二名で予約したいです。', reading: 'ashita no shichiji ni nimei de yoyaku shitai desu.', meaning: 'Saya ingin memesan meja untuk dua orang besok jam tujuh.'),
      DialogLine(speaker: '店員', japanese: 'お名前をお願いします。', reading: 'onamae o onegai shimasu.', meaning: 'Boleh minta namanya?'),
      DialogLine(speaker: '客', japanese: 'アディです。', reading: 'adi desu.', meaning: 'Adi.'),
    ],
  ),
  DialogLesson(
    id: 'phone_message',
    category: 'Telepon',
    title: 'Meninggalkan pesan',
    description: 'Meminta pesan disampaikan kepada orang yang tidak ada.',
    level: 'N3',
    icon: Icons.voicemail_rounded,
    premium: true,
    tags: ['telepon', 'kerja', 'keigo'],
    lines: const [
      DialogLine(speaker: '受付', japanese: '田中はただいま席を外しております。', reading: 'tanaka wa tadaima seki o hazushite orimasu.', meaning: 'Tanaka sedang tidak berada di tempat.'),
      DialogLine(speaker: '客', japanese: 'では、伝言をお願いできますか。', reading: 'dewa, dengon o onegai dekimasu ka.', meaning: 'Kalau begitu, boleh titip pesan?'),
      DialogLine(speaker: '受付', japanese: 'はい、承ります。', reading: 'hai, uketamawarimasu.', meaning: 'Ya, dengan senang hati.'),
      DialogLine(speaker: '客', japanese: '三時の会議が四時に変わったとお伝えください。', reading: 'sanji no kaigi ga yoji ni kawatta to otsutae kudasai.', meaning: 'Tolong sampaikan bahwa rapat jam tiga berubah menjadi jam empat.'),
    ],
  ),
  DialogLesson(
    id: 'post_office',
    category: 'Layanan',
    title: 'Mengirim paket',
    description: 'Menanyakan biaya dan waktu pengiriman di kantor pos.',
    level: 'N4',
    icon: Icons.local_post_office_rounded,

    tags: ['kantor pos', 'paket'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'この荷物を大阪まで送りたいです。', reading: 'kono nimotsu o oosaka made okuritai desu.', meaning: 'Saya ingin mengirim paket ini ke Osaka.'),
      DialogLine(speaker: '係員', japanese: '普通便と速達、どちらにしますか。', reading: 'futsuubin to sokutatsu, dochira ni shimasu ka.', meaning: 'Mau kiriman biasa atau kilat?'),
      DialogLine(speaker: '客', japanese: '普通便でお願いします。何日ぐらいかかりますか。', reading: 'futsuubin de onegai shimasu. nannichi gurai kakarimasu ka.', meaning: 'Kiriman biasa. Kira-kira butuh berapa hari?'),
      DialogLine(speaker: '係員', japanese: '二日から三日です。', reading: 'futsuka kara mikka desu.', meaning: 'Dua sampai tiga hari.'),
    ],
  ),
  DialogLesson(
    id: 'bank_atm',
    category: 'Layanan',
    title: 'Masalah di ATM',
    description: 'Meminta bantuan karena kartu tidak keluar.',
    level: 'N4',
    icon: Icons.account_balance_rounded,

    tags: ['bank', 'ATM'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、カードが出てきません。', reading: 'sumimasen, kaado ga dete kimasen.', meaning: 'Permisi, kartu saya tidak keluar.'),
      DialogLine(speaker: '係員', japanese: 'どのATMを使いましたか。', reading: 'dono eethiiemu o tsukaimashita ka.', meaning: 'ATM yang mana yang digunakan?'),
      DialogLine(speaker: '客', japanese: '入口の右側です。', reading: 'iriguchi no migigawa desu.', meaning: 'Yang di sebelah kanan pintu masuk.'),
      DialogLine(speaker: '係員', japanese: '確認しますので、こちらでお待ちください。', reading: 'kakunin shimasu node, kochira de omachi kudasai.', meaning: 'Kami akan memeriksa. Mohon tunggu di sini.'),
    ],
  ),
  DialogLesson(
    id: 'city_hall_address',
    category: 'Layanan',
    title: 'Mengurus perubahan alamat',
    description: 'Menanyakan loket untuk perubahan alamat.',
    level: 'N3',
    icon: Icons.apartment_rounded,
    premium: true,
    tags: ['balai kota', 'alamat'],
    lines: const [
      DialogLine(speaker: '客', japanese: '引っ越したので、住所を変更したいです。', reading: 'hikkoshita node, juusho o henkou shitai desu.', meaning: 'Saya pindah, jadi ingin mengubah alamat.'),
      DialogLine(speaker: '職員', japanese: '在留カードをお持ちですか。', reading: 'zairyuu kaado o omochi desu ka.', meaning: 'Apakah membawa kartu izin tinggal?'),
      DialogLine(speaker: '客', japanese: 'はい、持っています。', reading: 'hai, motte imasu.', meaning: 'Ya, saya membawanya.'),
      DialogLine(speaker: '職員', japanese: 'では、この用紙に新しい住所を書いてください。', reading: 'dewa, kono youshi ni atarashii juusho o kaite kudasai.', meaning: 'Kalau begitu, tulis alamat baru di formulir ini.'),
    ],
  ),
  DialogLesson(
    id: 'police_wallet',
    category: 'Darurat',
    title: 'Dompet hilang',
    description: 'Melapor kehilangan dompet di pos polisi.',
    level: 'N4',
    icon: Icons.local_police_rounded,

    tags: ['polisi', 'barang hilang'],
    lines: const [
      DialogLine(speaker: '客', japanese: '財布をなくしました。', reading: 'saifu o nakushimashita.', meaning: 'Saya kehilangan dompet.'),
      DialogLine(speaker: '警察官', japanese: 'どこで最後に使いましたか。', reading: 'doko de saigo ni tsukaimashita ka.', meaning: 'Terakhir digunakan di mana?'),
      DialogLine(speaker: '客', japanese: '駅前のコンビニです。', reading: 'ekimae no konbini desu.', meaning: 'Di konbini depan stasiun.'),
      DialogLine(speaker: '警察官', japanese: '財布の色と中身を教えてください。', reading: 'saifu no iro to nakami o oshiete kudasai.', meaning: 'Tolong beri tahu warna dompet dan isinya.'),
    ],
  ),
  DialogLesson(
    id: 'emergency_call',
    category: 'Darurat',
    title: 'Memanggil ambulans',
    description: 'Menyampaikan lokasi dan kondisi orang sakit.',
    level: 'N4',
    icon: Icons.emergency_rounded,

    tags: ['darurat', 'ambulans'],
    lines: const [
      DialogLine(speaker: '係員', japanese: '119番です。火事ですか、救急ですか。', reading: 'hyakujuukyuu-ban desu. kaji desu ka, kyuukyuu desu ka.', meaning: 'Ini 119. Kebakaran atau ambulans?'),
      DialogLine(speaker: '通報者', japanese: '救急です。人が倒れました。', reading: 'kyuukyuu desu. hito ga taoremashita.', meaning: 'Ambulans. Ada orang pingsan.'),
      DialogLine(speaker: '係員', japanese: '場所はどこですか。', reading: 'basho wa doko desu ka.', meaning: 'Lokasinya di mana?'),
      DialogLine(speaker: '通報者', japanese: '中央駅の北口です。', reading: 'chuuou-eki no kitaguchi desu.', meaning: 'Di pintu utara Stasiun Chuo.'),
    ],
  ),
  DialogLesson(
    id: 'friend_invite',
    category: 'Pertemanan',
    title: 'Mengajak makan',
    description: 'Mengajak teman pergi makan setelah belajar.',
    level: 'N5',
    icon: Icons.people_rounded,

    tags: ['teman', 'ajakan', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '勉強が終わったら、何か食べに行かない。', reading: 'benkyou ga owattara, nanika tabe ni ikanai.', meaning: 'Setelah belajar selesai, mau pergi makan?'),
      DialogLine(speaker: 'B', japanese: 'いいね。何が食べたい。', reading: 'ii ne. nani ga tabetai.', meaning: 'Boleh. Mau makan apa?'),
      DialogLine(speaker: 'A', japanese: 'ラーメンがいいな。', reading: 'raamen ga ii na.', meaning: 'Ramen sepertinya enak.'),
      DialogLine(speaker: 'B', japanese: 'じゃあ、駅前の店に行こう。', reading: 'jaa, ekimae no mise ni ikou.', meaning: 'Kalau begitu, ayo ke restoran depan stasiun.'),
    ],
  ),
  DialogLesson(
    id: 'decline_invite',
    category: 'Pertemanan',
    title: 'Menolak ajakan dengan halus',
    description: 'Menolak ajakan tanpa terdengar kasar.',
    level: 'N4',
    icon: Icons.event_busy_rounded,

    tags: ['teman', 'menolak', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '土曜日、一緒に映画を見ない。', reading: 'doyoubi, issho ni eiga o minai.', meaning: 'Sabtu mau nonton film bersama?'),
      DialogLine(speaker: 'B', japanese: 'ごめん、その日は予定があるんだ。', reading: 'gomen, sono hi wa yotei ga arun da.', meaning: 'Maaf, hari itu saya ada rencana.'),
      DialogLine(speaker: 'A', japanese: 'そっか。じゃあ、また今度。', reading: 'sokka. jaa, mata kondo.', meaning: 'Oh begitu. Lain kali ya.'),
      DialogLine(speaker: 'B', japanese: 'うん、ぜひ。', reading: 'un, zehi.', meaning: 'Ya, tentu.'),
    ],
  ),
  DialogLesson(
    id: 'apology_late',
    category: 'Pertemanan',
    title: 'Meminta maaf karena terlambat',
    description: 'Meminta maaf dan menjelaskan alasan.',
    level: 'N5',
    icon: Icons.access_time_rounded,

    tags: ['teman', 'permintaan maaf'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '遅れてごめん。', reading: 'okurete gomen.', meaning: 'Maaf terlambat.'),
      DialogLine(speaker: 'B', japanese: '大丈夫。何かあった。', reading: 'daijoubu. nanika atta.', meaning: 'Tidak apa-apa. Ada apa?'),
      DialogLine(speaker: 'A', japanese: '電車が遅れたんだ。', reading: 'densha ga okuretan da.', meaning: 'Kereta terlambat.'),
      DialogLine(speaker: 'B', japanese: 'そうだったんだ。じゃあ、行こう。', reading: 'sou dattan da. jaa, ikou.', meaning: 'Oh begitu. Ayo kita pergi.'),
    ],
  ),
  DialogLesson(
    id: 'borrow_umbrella',
    category: 'Pertemanan',
    title: 'Meminjam payung',
    description: 'Meminta pinjam payung saat hujan.',
    level: 'N5',
    icon: Icons.umbrella_rounded,

    tags: ['teman', 'payung', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '雨が降ってきたね。', reading: 'ame ga futte kita ne.', meaning: 'Mulai hujan ya.'),
      DialogLine(speaker: 'B', japanese: '傘を持ってないの。', reading: 'kasa o mottenai no.', meaning: 'Kamu tidak membawa payung?'),
      DialogLine(speaker: 'A', japanese: 'うん。もしよかったら、貸してくれる。', reading: 'un. moshi yokattara, kashite kureru.', meaning: 'Iya. Kalau boleh, bisa pinjamkan?'),
      DialogLine(speaker: 'B', japanese: 'いいよ。明日返してね。', reading: 'ii yo. ashita kaeshite ne.', meaning: 'Boleh. Besok kembalikan ya.'),
    ],
  ),
  DialogLesson(
    id: 'weather_plan',
    category: 'Kegiatan Harian',
    title: 'Membicarakan cuaca',
    description: 'Mengubah rencana karena hujan.',
    level: 'N5',
    icon: Icons.cloud_rounded,

    tags: ['cuaca', 'rencana'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '明日は雨らしいよ。', reading: 'ashita wa ame rashii yo.', meaning: 'Katanya besok hujan.'),
      DialogLine(speaker: 'B', japanese: 'じゃあ、公園はやめようか。', reading: 'jaa, kouen wa yameyou ka.', meaning: 'Kalau begitu, batal ke taman?'),
      DialogLine(speaker: 'A', japanese: 'うん。駅の近くの博物館はどう。', reading: 'un. eki no chikaku no hakubutsukan wa dou.', meaning: 'Ya. Bagaimana kalau museum dekat stasiun?'),
      DialogLine(speaker: 'B', japanese: 'いいね。そうしよう。', reading: 'ii ne. sou shiyou.', meaning: 'Bagus. Ayo begitu.'),
    ],
  ),
  DialogLesson(
    id: 'hair_salon',
    category: 'Layanan',
    title: 'Di salon rambut',
    description: 'Menjelaskan panjang potongan rambut yang diinginkan.',
    level: 'N4',
    icon: Icons.content_cut_rounded,

    tags: ['salon', 'layanan'],
    lines: const [
      DialogLine(speaker: '店員', japanese: '今日はどうなさいますか。', reading: 'kyou wa dou nasaimasu ka.', meaning: 'Hari ini ingin model seperti apa?'),
      DialogLine(speaker: '客', japanese: '三センチぐらい切ってください。', reading: 'san senchi gurai kitte kudasai.', meaning: 'Tolong potong sekitar tiga sentimeter.'),
      DialogLine(speaker: '店員', japanese: '前髪はどうしますか。', reading: 'maegami wa dou shimasu ka.', meaning: 'Bagaimana dengan poni?'),
      DialogLine(speaker: '客', japanese: '少し短くしてください。', reading: 'sukoshi mijikaku shite kudasai.', meaning: 'Tolong dibuat sedikit lebih pendek.'),
    ],
  ),
  DialogLesson(
    id: 'photo_request',
    category: 'Perjalanan',
    title: 'Meminta tolong difoto',
    description: 'Meminta orang lain mengambil foto.',
    level: 'N5',
    icon: Icons.photo_camera_rounded,

    tags: ['wisata', 'foto'],
    lines: const [
      DialogLine(speaker: '旅行者', japanese: 'すみません、写真を撮ってもらえますか。', reading: 'sumimasen, shashin o totte moraemasu ka.', meaning: 'Permisi, bisa tolong fotokan?'),
      DialogLine(speaker: '人', japanese: 'いいですよ。', reading: 'ii desu yo.', meaning: 'Boleh.'),
      DialogLine(speaker: '旅行者', japanese: 'この建物も入れてください。', reading: 'kono tatemono mo irete kudasai.', meaning: 'Tolong masukkan bangunan ini juga.'),
      DialogLine(speaker: '人', japanese: 'はい、撮ります。', reading: 'hai, torimasu.', meaning: 'Baik, saya ambil.'),
    ],
  ),
  DialogLesson(
    id: 'onsen_rules',
    category: 'Budaya',
    title: 'Menanyakan aturan onsen',
    description: 'Memastikan aturan sebelum masuk pemandian.',
    level: 'N4',
    icon: Icons.hot_tub_rounded,
    premium: true,
    tags: ['budaya', 'onsen'],
    lines: const [
      DialogLine(speaker: '客', japanese: '初めてなんですが、タオルは中に持って入れますか。', reading: 'hajimete nan desu ga, taoru wa naka ni motte hairemasu ka.', meaning: 'Ini pertama kali saya. Apakah handuk boleh dibawa masuk?'),
      DialogLine(speaker: '係員', japanese: '小さいタオルは持って入れますが、湯船には入れないでください。', reading: 'chiisai taoru wa motte hairemasu ga, yubune ni wa irenaide kudasai.', meaning: 'Handuk kecil boleh dibawa masuk, tetapi jangan dimasukkan ke bak mandi.'),
      DialogLine(speaker: '客', japanese: '分かりました。先に体を洗いますね。', reading: 'wakarimashita. saki ni karada o araimasu ne.', meaning: 'Baik. Saya mandi dulu sebelum masuk ya.'),
      DialogLine(speaker: '係員', japanese: 'はい、お願いします。', reading: 'hai, onegai shimasu.', meaning: 'Ya, silakan.'),
    ],
  ),
  DialogLesson(
    id: 'office_lunch',
    category: 'Kerja',
    title: 'Makan siang dengan rekan',
    description: 'Percakapan ringan saat istirahat kantor.',
    level: 'N5',
    icon: Icons.lunch_dining_rounded,

    tags: ['kerja', 'makan siang'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'お昼、どこで食べますか。', reading: 'ohiru, doko de tabemasu ka.', meaning: 'Makan siang di mana?'),
      DialogLine(speaker: 'B', japanese: '近くの定食屋に行きませんか。', reading: 'chikaku no teishokuya ni ikimasen ka.', meaning: 'Mau ke rumah makan set dekat sini?'),
      DialogLine(speaker: 'A', japanese: 'いいですね。何時に行きますか。', reading: 'ii desu ne. nanji ni ikimasu ka.', meaning: 'Boleh. Jam berapa kita pergi?'),
      DialogLine(speaker: 'B', japanese: '十二時になったら行きましょう。', reading: 'juuniji ni nattara ikimashou.', meaning: 'Mari pergi saat jam dua belas.'),
    ],
  ),
  DialogLesson(
    id: 'meeting_schedule',
    category: 'Kerja',
    title: 'Mengubah jadwal rapat',
    description: 'Mengusulkan perubahan waktu rapat secara sopan.',
    level: 'N3',
    icon: Icons.calendar_month_rounded,
    premium: true,
    tags: ['kerja', 'rapat', 'keigo'],
    lines: const [
      DialogLine(speaker: '社員', japanese: '明日の会議ですが、時間を変更してもよろしいでしょうか。', reading: 'ashita no kaigi desu ga, jikan o henkou shite mo yoroshii deshou ka.', meaning: 'Tentang rapat besok, bolehkah waktunya diubah?'),
      DialogLine(speaker: '上司', japanese: '何時がいいですか。', reading: 'nanji ga ii desu ka.', meaning: 'Jam berapa yang baik?'),
      DialogLine(speaker: '社員', japanese: '午後二時からでしたら参加できます。', reading: 'gogo niji kara deshitara sanka dekimasu.', meaning: 'Saya bisa ikut jika mulai pukul dua siang.'),
      DialogLine(speaker: '上司', japanese: 'では、二時に変更しましょう。', reading: 'dewa, niji ni henkou shimashou.', meaning: 'Kalau begitu, kita ubah menjadi jam dua.'),
    ],
  ),
  DialogLesson(
    id: 'customer_complaint',
    category: 'Layanan',
    title: 'Menangani keluhan pelanggan',
    description: 'Meminta maaf dan menawarkan penggantian barang.',
    level: 'N3',
    icon: Icons.support_agent_rounded,
    premium: true,
    tags: ['pelanggan', 'keigo', 'layanan'],
    lines: const [
      DialogLine(speaker: '客', japanese: '昨日買った商品が動きません。', reading: 'kinou katta shouhin ga ugokimasen.', meaning: 'Barang yang saya beli kemarin tidak berfungsi.'),
      DialogLine(speaker: '店員', japanese: 'ご迷惑をおかけして申し訳ございません。', reading: 'gomeiwaku o okake shite moushiwake gozaimasen.', meaning: 'Mohon maaf atas ketidaknyamanannya.'),
      DialogLine(speaker: '客', japanese: '交換できますか。', reading: 'koukan dekimasu ka.', meaning: 'Apakah bisa ditukar?'),
      DialogLine(speaker: '店員', japanese: 'はい、レシートを確認して交換いたします。', reading: 'hai, reshiito o kakunin shite koukan itashimasu.', meaning: 'Ya, kami akan memeriksa struk lalu menukarnya.'),
    ],
  ),
  DialogLesson(
    id: 'delivery_delay',
    category: 'Layanan',
    title: 'Menanyakan paket terlambat',
    description: 'Menghubungi layanan pelanggan tentang paket yang belum tiba.',
    level: 'N3',
    icon: Icons.local_shipping_rounded,

    tags: ['paket', 'layanan'],
    lines: const [
      DialogLine(speaker: '客', japanese: '荷物がまだ届いていないんですが。', reading: 'nimotsu ga mada todoite inain desu ga.', meaning: 'Paket saya belum sampai.'),
      DialogLine(speaker: '係員', japanese: 'お問い合わせ番号をお願いします。', reading: 'otoiawase bangou o onegai shimasu.', meaning: 'Mohon nomor pelacakannya.'),
      DialogLine(speaker: '客', japanese: '123456です。', reading: 'ichi ni san yon go roku desu.', meaning: 'Nomornya 123456.'),
      DialogLine(speaker: '係員', japanese: '確認したところ、明日の午前中に届く予定です。', reading: 'kakunin shita tokoro, ashita no gozenchuu ni todoku yotei desu.', meaning: 'Setelah diperiksa, paket dijadwalkan tiba besok pagi.'),
    ],
  ),
  DialogLesson(
    id: 'gym_membership',
    category: 'Kegiatan Harian',
    title: 'Mendaftar pusat kebugaran',
    description: 'Menanyakan biaya dan jam buka.',
    level: 'N4',
    icon: Icons.fitness_center_rounded,

    tags: ['olahraga', 'layanan'],
    lines: const [
      DialogLine(speaker: '客', japanese: '入会したいんですが、月会費はいくらですか。', reading: 'nyuukai shitain desu ga, tsukikaihi wa ikura desu ka.', meaning: 'Saya ingin mendaftar. Berapa biaya bulanannya?'),
      DialogLine(speaker: '店員', japanese: '月に五千円です。', reading: 'tsuki ni gosen en desu.', meaning: 'Lima ribu yen per bulan.'),
      DialogLine(speaker: '客', japanese: '何時まで開いていますか。', reading: 'nanji made aite imasu ka.', meaning: 'Buka sampai jam berapa?'),
      DialogLine(speaker: '店員', japanese: '平日は夜十一時までです。', reading: 'heijitsu wa yoru juuichiji made desu.', meaning: 'Hari kerja sampai jam sebelas malam.'),
    ],
  ),
  DialogLesson(
    id: 'apartment_viewing',
    category: 'Rumah',
    title: 'Melihat apartemen',
    description: 'Menanyakan biaya sewa dan fasilitas.',
    level: 'N3',
    icon: Icons.real_estate_agent_rounded,
    premium: true,
    tags: ['rumah', 'apartemen'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'この部屋の家賃はいくらですか。', reading: 'kono heya no yachin wa ikura desu ka.', meaning: 'Berapa sewa kamar ini?'),
      DialogLine(speaker: '担当者', japanese: '月七万円です。管理費は別です。', reading: 'tsuki nana man en desu. kanrihi wa betsu desu.', meaning: 'Tujuh puluh ribu yen per bulan. Biaya pengelolaan terpisah.'),
      DialogLine(speaker: '客', japanese: '駅まで何分ぐらいですか。', reading: 'eki made nanpun gurai desu ka.', meaning: 'Sekitar berapa menit ke stasiun?'),
      DialogLine(speaker: '担当者', japanese: '歩いて八分ほどです。', reading: 'aruite happun hodo desu.', meaning: 'Sekitar delapan menit berjalan kaki.'),
    ],
  ),
  DialogLesson(
    id: 'lost_phone',
    category: 'Darurat',
    title: 'Ponsel tertinggal',
    description: 'Meminta bantuan mencari ponsel yang tertinggal.',
    level: 'N4',
    icon: Icons.phone_android_rounded,

    tags: ['barang hilang', 'kereta'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、電車に携帯電話を忘れました。', reading: 'sumimasen, densha ni keitai denwa o wasuremashita.', meaning: 'Permisi, saya meninggalkan ponsel di kereta.'),
      DialogLine(speaker: '駅員', japanese: '何線の電車ですか。', reading: 'nansen no densha desu ka.', meaning: 'Kereta jalur apa?'),
      DialogLine(speaker: '客', japanese: '山手線です。黒い携帯です。', reading: 'yamanotesen desu. kuroi keitai desu.', meaning: 'Jalur Yamanote. Ponselnya berwarna hitam.'),
      DialogLine(speaker: '駅員', japanese: '遺失物センターに確認します。', reading: 'ishitsubutsu sentaa ni kakunin shimasu.', meaning: 'Kami akan memeriksa ke pusat barang hilang.'),
    ],
  ),
  DialogLesson(
    id: 'museum_ticket',
    category: 'Perjalanan',
    title: 'Membeli tiket museum',
    description: 'Menanyakan harga dan jam tutup.',
    level: 'N5',
    icon: Icons.museum_rounded,

    tags: ['wisata', 'tiket'],
    lines: const [
      DialogLine(speaker: '客', japanese: '大人一枚お願いします。', reading: 'otona ichimai onegai shimasu.', meaning: 'Satu tiket dewasa.'),
      DialogLine(speaker: '係員', japanese: '千二百円です。', reading: 'sen nihyaku en desu.', meaning: 'Seribu dua ratus yen.'),
      DialogLine(speaker: '客', japanese: '何時まで見られますか。', reading: 'nanji made miraremasu ka.', meaning: 'Bisa melihat sampai jam berapa?'),
      DialogLine(speaker: '係員', japanese: '午後五時までです。', reading: 'gogo goji made desu.', meaning: 'Sampai jam lima sore.'),
    ],
  ),
  DialogLesson(
    id: 'restaurant_reservation_change',
    category: 'Restoran',
    title: 'Mengubah reservasi',
    description: 'Mengubah jumlah orang dalam reservasi.',
    level: 'N4',
    icon: Icons.event_repeat_rounded,

    tags: ['restoran', 'reservasi'],
    lines: const [
      DialogLine(speaker: '客', japanese: '今夜七時に予約している山田です。', reading: 'konya shichiji ni yoyaku shite iru yamada desu.', meaning: 'Saya Yamada, punya reservasi malam ini jam tujuh.'),
      DialogLine(speaker: '店員', japanese: 'はい、四名様ですね。', reading: 'hai, yonmei sama desu ne.', meaning: 'Ya, untuk empat orang.'),
      DialogLine(speaker: '客', japanese: '六名に変更できますか。', reading: 'rokumei ni henkou dekimasu ka.', meaning: 'Bisa diubah menjadi enam orang?'),
      DialogLine(speaker: '店員', japanese: '確認します。少々お待ちください。', reading: 'kakunin shimasu. shoushou omachi kudasai.', meaning: 'Saya cek. Mohon tunggu sebentar.'),
    ],
  ),
  DialogLesson(
    id: 'school_absence',
    category: 'Sekolah',
    title: 'Izin tidak masuk kelas',
    description: 'Mengabarkan ketidakhadiran kepada guru.',
    level: 'N4',
    icon: Icons.event_busy_rounded,

    tags: ['sekolah', 'izin'],
    lines: const [
      DialogLine(speaker: '学生', japanese: '先生、明日の授業を休みます。', reading: 'sensei, ashita no jugyou o yasumimasu.', meaning: 'Sensei, besok saya tidak masuk kelas.'),
      DialogLine(speaker: '先生', japanese: 'どうしましたか。', reading: 'dou shimashita ka.', meaning: 'Ada apa?'),
      DialogLine(speaker: '学生', japanese: '病院へ行かなければなりません。', reading: 'byouin e ikanakereba narimasen.', meaning: 'Saya harus pergi ke rumah sakit.'),
      DialogLine(speaker: '先生', japanese: '分かりました。後で資料を送ります。', reading: 'wakarimashita. ato de shiryou o okurimasu.', meaning: 'Baik. Nanti saya kirim materinya.'),
    ],
  ),
  DialogLesson(
    id: 'study_group',
    category: 'Sekolah',
    title: 'Belajar kelompok',
    description: 'Mengatur waktu untuk belajar bersama.',
    level: 'N5',
    icon: Icons.menu_book_rounded,

    tags: ['sekolah', 'belajar', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '今日、一緒に漢字を勉強しない。', reading: 'kyou, issho ni kanji o benkyou shinai.', meaning: 'Hari ini mau belajar kanji bersama?'),
      DialogLine(speaker: 'B', japanese: 'いいよ。何時から。', reading: 'ii yo. nanji kara.', meaning: 'Boleh. Mulai jam berapa?'),
      DialogLine(speaker: 'A', japanese: '七時から図書館でどう。', reading: 'shichiji kara toshokan de dou.', meaning: 'Bagaimana jam tujuh di perpustakaan?'),
      DialogLine(speaker: 'B', japanese: '分かった。七時に行くね。', reading: 'wakatta. shichiji ni iku ne.', meaning: 'Oke. Aku datang jam tujuh.'),
    ],
  ),
  DialogLesson(
    id: 'job_first_day',
    category: 'Kerja',
    title: 'Hari pertama kerja',
    description: 'Menyapa senior dan menanyakan pekerjaan pertama.',
    level: 'N4',
    icon: Icons.handshake_rounded,

    tags: ['kerja', 'hari pertama'],
    lines: const [
      DialogLine(speaker: '新人', japanese: '今日からお世話になります。よろしくお願いします。', reading: 'kyou kara osewa ni narimasu. yoroshiku onegai shimasu.', meaning: 'Mulai hari ini mohon bimbingannya.'),
      DialogLine(speaker: '先輩', japanese: 'こちらこそ、よろしくお願いします。', reading: 'kochira koso, yoroshiku onegai shimasu.', meaning: 'Sama-sama, senang bekerja bersama.'),
      DialogLine(speaker: '新人', japanese: '最初に何をすればいいですか。', reading: 'saisho ni nani o sureba ii desu ka.', meaning: 'Pertama saya harus melakukan apa?'),
      DialogLine(speaker: '先輩', japanese: 'まず、このマニュアルを読んでください。', reading: 'mazu, kono manyuaru o yonde kudasai.', meaning: 'Pertama, silakan baca panduan ini.'),
    ],
  ),
  DialogLesson(
    id: 'work_report_finish',
    category: 'Kerja',
    title: 'Melapor pekerjaan selesai',
    description: 'Melaporkan pekerjaan kepada atasan.',
    level: 'N4',
    icon: Icons.task_alt_rounded,

    tags: ['kerja', 'laporan'],
    lines: const [
      DialogLine(speaker: '社員', japanese: '頼まれた作業が終わりました。', reading: 'tanomareta sagyou ga owarimashita.', meaning: 'Pekerjaan yang diminta sudah selesai.'),
      DialogLine(speaker: '上司', japanese: 'ありがとうございます。問題はありませんでしたか。', reading: 'arigatou gozaimasu. mondai wa arimasen deshita ka.', meaning: 'Terima kasih. Tidak ada masalah?'),
      DialogLine(speaker: '社員', japanese: '一か所だけ確認していただきたいです。', reading: 'ikkasho dake kakunin shite itadakitai desu.', meaning: 'Ada satu bagian yang ingin saya minta diperiksa.'),
      DialogLine(speaker: '上司', japanese: '分かりました。後で見ます。', reading: 'wakarimashita. ato de mimasu.', meaning: 'Baik. Nanti saya lihat.'),
    ],
  ),
  DialogLesson(
    id: 'restaurant_takeout',
    category: 'Restoran',
    title: 'Memesan untuk dibawa pulang',
    description: 'Menanyakan apakah makanan bisa dibawa pulang.',
    level: 'N5',
    icon: Icons.takeout_dining_rounded,

    tags: ['restoran', 'bawa pulang'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'これは持ち帰りできますか。', reading: 'kore wa mochikaeri dekimasu ka.', meaning: 'Apakah ini bisa dibawa pulang?'),
      DialogLine(speaker: '店員', japanese: 'はい、できます。', reading: 'hai, dekimasu.', meaning: 'Ya, bisa.'),
      DialogLine(speaker: '客', japanese: 'では、二つお願いします。', reading: 'dewa, futatsu onegai shimasu.', meaning: 'Kalau begitu, dua ya.'),
      DialogLine(speaker: '店員', japanese: '少々お待ちください。', reading: 'shoushou omachi kudasai.', meaning: 'Mohon tunggu sebentar.'),
    ],
  ),
  DialogLesson(
    id: 'hotel_checkout',
    category: 'Hotel',
    title: 'Lapor keluar hotel',
    description: 'Mengembalikan kunci dan menyelesaikan pembayaran.',
    level: 'N5',
    icon: Icons.logout_rounded,

    tags: ['hotel', 'pembayaran'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'チェックアウトをお願いします。', reading: 'chekkuauto o onegai shimasu.', meaning: 'Saya ingin lapor keluar.'),
      DialogLine(speaker: '受付', japanese: 'お部屋番号をお願いします。', reading: 'oheya bangou o onegai shimasu.', meaning: 'Mohon nomor kamarnya.'),
      DialogLine(speaker: '客', japanese: '五〇三号室です。', reading: 'gohyakusan-goushitsu desu.', meaning: 'Kamar 503.'),
      DialogLine(speaker: '受付', japanese: '追加料金はありません。ありがとうございました。', reading: 'tsuuka ryoukin wa arimasen. arigatou gozaimashita.', meaning: 'Tidak ada biaya tambahan. Terima kasih.'),
    ],
  ),
  DialogLesson(
    id: 'friend_hobby',
    category: 'Pertemanan',
    title: 'Membicarakan hobi',
    description: 'Menanyakan hobi dan kegiatan akhir pekan.',
    level: 'N5',
    icon: Icons.sports_esports_rounded,

    tags: ['teman', 'hobi', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '趣味は何。', reading: 'shumi wa nani.', meaning: 'Hobimu apa?'),
      DialogLine(speaker: 'B', japanese: 'ゲームと映画かな。', reading: 'geemu to eiga kana.', meaning: 'Mungkin gim dan film.'),
      DialogLine(speaker: 'A', japanese: '週末もよくゲームする。', reading: 'shuumatsu mo yoku geemu suru.', meaning: 'Akhir pekan juga sering main?'),
      DialogLine(speaker: 'B', japanese: 'うん。でも最近は日本語も勉強してる。', reading: 'un. demo saikin wa nihongo mo benkyou shiteru.', meaning: 'Ya. Tapi belakangan ini saya juga belajar bahasa Jepang.'),
    ],
  ),
  DialogLesson(
    id: 'language_exchange',
    category: 'Pertemanan',
    title: 'Pertukaran bahasa',
    description: 'Mengatur latihan bahasa Indonesia dan Jepang.',
    level: 'N4',
    icon: Icons.translate_rounded,

    tags: ['bahasa', 'teman'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '日本語の会話を練習したいんだけど。', reading: 'nihongo no kaiwa o renshuu shitain da kedo.', meaning: 'Saya ingin berlatih percakapan bahasa Jepang.'),
      DialogLine(speaker: 'B', japanese: 'じゃあ、私もインドネシア語を教えてほしい。', reading: 'jaa, watashi mo indoneshiago o oshiete hoshii.', meaning: 'Kalau begitu, saya juga ingin diajari bahasa Indonesia.'),
      DialogLine(speaker: 'A', japanese: '三十分ずつ話すのはどう。', reading: 'sanjuppun zutsu hanasu no wa dou.', meaning: 'Bagaimana kalau masing-masing berbicara tiga puluh menit?'),
      DialogLine(speaker: 'B', japanese: 'いいね。毎週やろう。', reading: 'ii ne. maishuu yarou.', meaning: 'Bagus. Ayo lakukan setiap minggu.'),
    ],
  ),
  DialogLesson(
    id: 'restaurant_recommendation',
    category: 'Restoran',
    title: 'Meminta rekomendasi menu',
    description: 'Menanyakan menu yang paling direkomendasikan pelayan.',
    level: 'N4',
    icon: Icons.restaurant_rounded,
    tags: ['restoran', 'rekomendasi', 'sopan'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'おすすめは何ですか。', reading: 'osusume wa nan desu ka.', meaning: 'Apa menu yang direkomendasikan?'),
      DialogLine(speaker: '店員', japanese: '今日は焼き魚定食がおすすめです。', reading: 'kyou wa yakizakana teishoku ga osusume desu.', meaning: 'Hari ini paket ikan bakar yang paling direkomendasikan.'),
      DialogLine(speaker: '客', japanese: '辛いですか。', reading: 'karai desu ka.', meaning: 'Apakah pedas?'),
      DialogLine(speaker: '店員', japanese: 'いいえ、辛くありません。', reading: 'iie, karaku arimasen.', meaning: 'Tidak, tidak pedas.'),
      DialogLine(speaker: '客', japanese: 'では、それをお願いします。', reading: 'dewa, sore o onegai shimasu.', meaning: 'Kalau begitu, saya pesan itu.'),
    ],
  ),
  DialogLesson(
    id: 'shopping_return_item',
    category: 'Belanja',
    title: 'Menukar barang',
    description: 'Meminta penukaran barang yang ukurannya tidak sesuai.',
    level: 'N4',
    icon: Icons.shopping_cart_rounded,
    tags: ['belanja', 'penukaran', 'sopan'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、この服を交換したいんですが。', reading: 'sumimasen, kono fuku o koukan shitain desu ga.', meaning: 'Permisi, saya ingin menukar pakaian ini.'),
      DialogLine(speaker: '店員', japanese: '何か問題がありましたか。', reading: 'nanika mondai ga arimashita ka.', meaning: 'Apakah ada masalah?'),
      DialogLine(speaker: '客', japanese: 'サイズが少し小さかったです。', reading: 'saizu ga sukoshi chiisakatta desu.', meaning: 'Ukurannya sedikit kekecilan.'),
      DialogLine(speaker: '店員', japanese: 'レシートをお持ちですか。', reading: 'reshiito o omochi desu ka.', meaning: 'Apakah Anda membawa struk?'),
      DialogLine(speaker: '客', japanese: 'はい、こちらです。', reading: 'hai, kochira desu.', meaning: 'Ya, ini.'),
    ],
  ),
  DialogLesson(
    id: 'train_delay',
    category: 'Transportasi',
    title: 'Kereta terlambat',
    description: 'Menanyakan keterlambatan dan perkiraan kedatangan kereta.',
    level: 'N4',
    icon: Icons.train_rounded,
    tags: ['kereta', 'terlambat', 'stasiun'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'すみません、東京行きの電車は遅れていますか。', reading: 'sumimasen, toukyou-yuki no densha wa okurete imasu ka.', meaning: 'Permisi, apakah kereta menuju Tokyo terlambat?'),
      DialogLine(speaker: '駅員', japanese: 'はい、約十分遅れています。', reading: 'hai, yaku juppun okurete imasu.', meaning: 'Ya, terlambat sekitar sepuluh menit.'),
      DialogLine(speaker: '客', japanese: '何番線に来ますか。', reading: 'nanbansen ni kimasu ka.', meaning: 'Akan datang di peron nomor berapa?'),
      DialogLine(speaker: '駅員', japanese: '三番線です。', reading: 'sanbansen desu.', meaning: 'Peron tiga.'),
    ],
  ),
  DialogLesson(
    id: 'work_overtime',
    category: 'Kerja',
    title: 'Meminta izin lembur',
    description: 'Membicarakan pekerjaan yang belum selesai dan waktu lembur.',
    level: 'N3',
    icon: Icons.work_rounded,
    premium: true,
    tags: ['kerja', 'lembur', 'sopan'],
    lines: const [
      DialogLine(speaker: '社員', japanese: '今日、少し残業してもよろしいでしょうか。', reading: 'kyou, sukoshi zangyou shite mo yoroshii deshou ka.', meaning: 'Apakah hari ini saya boleh lembur sebentar?'),
      DialogLine(speaker: '上司', japanese: '何時ごろまでかかりそうですか。', reading: 'nanji goro made kakarisou desu ka.', meaning: 'Kira-kira sampai jam berapa?'),
      DialogLine(speaker: '社員', japanese: '一時間ほどで終わると思います。', reading: 'ichijikan hodo de owaru to omoimasu.', meaning: 'Saya rasa selesai sekitar satu jam lagi.'),
      DialogLine(speaker: '上司', japanese: '分かりました。無理をしないでください。', reading: 'wakarimashita. muri o shinaide kudasai.', meaning: 'Baik. Jangan memaksakan diri.'),
    ],
  ),
  DialogLesson(
    id: 'apartment_broken_aircon',
    category: 'Rumah',
    title: 'Pendingin ruangan rusak',
    description: 'Menghubungi pengelola apartemen karena pendingin ruangan bermasalah.',
    level: 'N4',
    icon: Icons.apartment_rounded,
    tags: ['apartemen', 'perbaikan', 'layanan'],
    lines: const [
      DialogLine(speaker: '住人', japanese: 'エアコンが動かないんですが。', reading: 'eakon ga ugokanain desu ga.', meaning: 'Pendingin ruangannya tidak berfungsi.'),
      DialogLine(speaker: '管理人', japanese: 'いつからですか。', reading: 'itsu kara desu ka.', meaning: 'Sejak kapan?'),
      DialogLine(speaker: '住人', japanese: '昨夜からです。', reading: 'sakuya kara desu.', meaning: 'Sejak tadi malam.'),
      DialogLine(speaker: '管理人', japanese: '今日の午後、確認に伺います。', reading: 'kyou no gogo, kakunin ni ukagaimasu.', meaning: 'Sore ini saya akan datang memeriksanya.'),
    ],
  ),
  DialogLesson(
    id: 'hospital_appointment',
    category: 'Kesehatan',
    title: 'Membuat janji dokter',
    description: 'Menelepon klinik untuk memilih waktu pemeriksaan.',
    level: 'N4',
    icon: Icons.local_hospital_rounded,
    tags: ['kesehatan', 'janji', 'telepon'],
    lines: const [
      DialogLine(speaker: '患者', japanese: '明日の診察を予約したいんですが。', reading: 'ashita no shinsatsu o yoyaku shitain desu ga.', meaning: 'Saya ingin membuat janji pemeriksaan untuk besok.'),
      DialogLine(speaker: '受付', japanese: '午前と午後、どちらがよろしいですか。', reading: 'gozen to gogo, dochira ga yoroshii desu ka.', meaning: 'Lebih cocok pagi atau sore?'),
      DialogLine(speaker: '患者', japanese: '午後三時ごろは空いていますか。', reading: 'gogo sanji goro wa aite imasu ka.', meaning: 'Apakah sekitar jam tiga sore tersedia?'),
      DialogLine(speaker: '受付', japanese: 'はい、三時半なら空いています。', reading: 'hai, sanji han nara aite imasu.', meaning: 'Ya, jam setengah empat tersedia.'),
    ],
  ),
  DialogLesson(
    id: 'phone_wrong_number',
    category: 'Telepon',
    title: 'Salah sambung telepon',
    description: 'Menanggapi telepon yang tersambung ke nomor yang salah.',
    level: 'N5',
    icon: Icons.phone_rounded,
    tags: ['telepon', 'sopan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'もしもし、田中さんですか。', reading: 'moshimoshi, tanaka-san desu ka.', meaning: 'Halo, apakah ini Tanaka?'),
      DialogLine(speaker: 'B', japanese: 'いいえ、違います。', reading: 'iie, chigaimasu.', meaning: 'Bukan.'),
      DialogLine(speaker: 'A', japanese: 'すみません、番号を間違えました。', reading: 'sumimasen, bangou o machigaemashita.', meaning: 'Maaf, saya salah nomor.'),
      DialogLine(speaker: 'B', japanese: '大丈夫です。', reading: 'daijoubu desu.', meaning: 'Tidak apa-apa.'),
    ],
  ),
  DialogLesson(
    id: 'family_dinner_plan',
    category: 'Keluarga',
    title: 'Rencana makan malam keluarga',
    description: 'Menentukan menu dan waktu makan bersama keluarga.',
    level: 'N5',
    icon: Icons.home_rounded,
    tags: ['keluarga', 'makan', 'harian'],
    lines: const [
      DialogLine(speaker: '母', japanese: '今晩、何が食べたい。', reading: 'konban, nani ga tabetai.', meaning: 'Malam ini ingin makan apa?'),
      DialogLine(speaker: '子', japanese: 'カレーが食べたい。', reading: 'karee ga tabetai.', meaning: 'Saya ingin makan kari.'),
      DialogLine(speaker: '母', japanese: 'じゃあ、七時に食べよう。', reading: 'jaa, shichiji ni tabeyou.', meaning: 'Kalau begitu, kita makan jam tujuh.'),
      DialogLine(speaker: '子', japanese: 'うん、手伝うよ。', reading: 'un, tetsudau yo.', meaning: 'Ya, saya bantu.'),
    ],
  ),
  DialogLesson(
    id: 'school_absence_note',
    category: 'Sekolah',
    title: 'Memberi tahu tidak masuk kelas',
    description: 'Memberi tahu guru bahwa tidak bisa hadir karena sakit.',
    level: 'N4',
    icon: Icons.school_rounded,
    tags: ['sekolah', 'izin', 'sopan'],
    lines: const [
      DialogLine(speaker: '学生', japanese: '先生、今日は体調が悪いので、授業を休みます。', reading: 'sensei, kyou wa taichou ga warui node, jugyou o yasumimasu.', meaning: 'Pak/Bu Guru, hari ini saya tidak masuk kelas karena kurang sehat.'),
      DialogLine(speaker: '先生', japanese: '分かりました。ゆっくり休んでください。', reading: 'wakarimashita. yukkuri yasunde kudasai.', meaning: 'Baik. Istirahatlah dengan cukup.'),
      DialogLine(speaker: '学生', japanese: '宿題はありますか。', reading: 'shukudai wa arimasu ka.', meaning: 'Apakah ada tugas?'),
      DialogLine(speaker: '先生', japanese: '後で連絡します。', reading: 'ato de renraku shimasu.', meaning: 'Nanti saya kabari.'),
    ],
  ),
  DialogLesson(
    id: 'group_project',
    category: 'Sekolah',
    title: 'Membagi tugas kelompok',
    description: 'Membagi peran untuk tugas presentasi kelompok.',
    level: 'N4',
    icon: Icons.groups_rounded,
    tags: ['sekolah', 'kelompok', 'presentasi'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '発表の役割を決めよう。', reading: 'happyou no yakuwari o kimeyou.', meaning: 'Ayo tentukan pembagian tugas presentasi.'),
      DialogLine(speaker: 'B', japanese: '私は資料を作ります。', reading: 'watashi wa shiryou o tsukurimasu.', meaning: 'Saya akan membuat bahan presentasi.'),
      DialogLine(speaker: 'C', japanese: 'じゃあ、私は発表します。', reading: 'jaa, watashi wa happyou shimasu.', meaning: 'Kalau begitu, saya yang presentasi.'),
      DialogLine(speaker: 'A', japanese: '私は最後にまとめます。', reading: 'watashi wa saigo ni matomemasu.', meaning: 'Saya akan membuat rangkuman di bagian akhir.'),
    ],
  ),
  DialogLesson(
    id: 'language_ask_meaning',
    category: 'Bahasa',
    title: 'Menanyakan arti kata',
    description: 'Meminta penjelasan arti sebuah kata bahasa Jepang.',
    level: 'N5',
    icon: Icons.language_rounded,
    tags: ['bahasa', 'belajar', 'arti'],
    lines: const [
      DialogLine(speaker: '学生', japanese: '「丁寧」はどういう意味ですか。', reading: 'teinei wa dou iu imi desu ka.', meaning: 'Apa arti “teinei”?'),
      DialogLine(speaker: '先生', japanese: '礼儀正しくて、きちんとしているという意味です。', reading: 'reigi tadashikute, kichin to shite iru to iu imi desu.', meaning: 'Artinya bersikap sopan dan melakukan sesuatu dengan baik.'),
      DialogLine(speaker: '学生', japanese: '例文を教えてください。', reading: 'reibun o oshiete kudasai.', meaning: 'Tolong berikan contoh kalimat.'),
      DialogLine(speaker: '先生', japanese: '「丁寧に説明します」のように使います。', reading: 'teinei ni setsumei shimasu no you ni tsukaimasu.', meaning: 'Bisa digunakan seperti pada kalimat “menjelaskan dengan teliti dan sopan”.'),
    ],
  ),
  DialogLesson(
    id: 'festival_invitation',
    category: 'Budaya',
    title: 'Mengajak ke matsuri',
    description: 'Mengajak teman pergi ke festival musim panas.',
    level: 'N4',
    icon: Icons.celebration_rounded,
    tags: ['budaya', 'festival', 'teman'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '土曜日の夏祭り、一緒に行かない。', reading: 'doyoubi no natsu matsuri, issho ni ikanai.', meaning: 'Mau pergi bersama ke festival musim panas hari Sabtu?'),
      DialogLine(speaker: 'B', japanese: '行きたい。何時に会う。', reading: 'ikitai. nanji ni au.', meaning: 'Mau. Kita bertemu jam berapa?'),
      DialogLine(speaker: 'A', japanese: '駅に六時でどう。', reading: 'eki ni rokuji de dou.', meaning: 'Bagaimana kalau jam enam di stasiun?'),
      DialogLine(speaker: 'B', japanese: 'いいよ。浴衣を着て行こうかな。', reading: 'ii yo. yukata o kite ikou kana.', meaning: 'Boleh. Mungkin saya akan memakai yukata.'),
    ],
  ),
  DialogLesson(
    id: 'bus_last_service',
    category: 'Transportasi',
    title: 'Menanyakan bus terakhir',
    description: 'Menanyakan jam keberangkatan bus terakhir.',
    level: 'N4',
    icon: Icons.directions_bus_rounded,
    tags: ['bus', 'jadwal', 'transportasi'],
    lines: const [
      DialogLine(speaker: '客', japanese: '駅行きの最終バスは何時ですか。', reading: 'eki-yuki no saishuu basu wa nanji desu ka.', meaning: 'Bus terakhir menuju stasiun jam berapa?'),
      DialogLine(speaker: '係員', japanese: '十時四十五分です。', reading: 'juuji yonjuugofun desu.', meaning: 'Jam sepuluh lewat empat puluh lima menit.'),
      DialogLine(speaker: '客', japanese: 'この乗り場から出ますか。', reading: 'kono noriba kara demasu ka.', meaning: 'Apakah berangkat dari halte ini?'),
      DialogLine(speaker: '係員', japanese: 'はい、五番乗り場です。', reading: 'hai, goban noriba desu.', meaning: 'Ya, dari halte nomor lima.'),
    ],
  ),
  DialogLesson(
    id: 'airport_customs',
    category: 'Bandara',
    title: 'Pemeriksaan bea cukai',
    description: 'Menjawab pertanyaan sederhana saat pemeriksaan bea cukai.',
    level: 'N4',
    icon: Icons.flight_rounded,
    premium: true,
    tags: ['bandara', 'bea cukai', 'perjalanan'],
    lines: const [
      DialogLine(speaker: '職員', japanese: '申告する物はありますか。', reading: 'shinkoku suru mono wa arimasu ka.', meaning: 'Apakah ada barang yang perlu dilaporkan?'),
      DialogLine(speaker: '旅行者', japanese: 'いいえ、ありません。', reading: 'iie, arimasen.', meaning: 'Tidak ada.'),
      DialogLine(speaker: '職員', japanese: 'この荷物はご自分の物ですか。', reading: 'kono nimotsu wa gojibun no mono desu ka.', meaning: 'Apakah barang bawaan ini milik Anda sendiri?'),
      DialogLine(speaker: '旅行者', japanese: 'はい、全部自分の物です。', reading: 'hai, zenbu jibun no mono desu.', meaning: 'Ya, semuanya milik saya.'),
    ],
  ),
  DialogLesson(
    id: 'post_office_parcel',
    category: 'Layanan',
    title: 'Mengirim paket',
    description: 'Mengirim paket dan menanyakan lama pengiriman.',
    level: 'N4',
    icon: Icons.local_post_office_rounded,
    tags: ['kantor pos', 'paket', 'layanan'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'この荷物を大阪まで送りたいです。', reading: 'kono nimotsu o oosaka made okuritai desu.', meaning: 'Saya ingin mengirim paket ini ke Osaka.'),
      DialogLine(speaker: '局員', japanese: '普通便と速達、どちらにしますか。', reading: 'futsuubin to sokutatsu, dochira ni shimasu ka.', meaning: 'Mau pengiriman biasa atau kilat?'),
      DialogLine(speaker: '客', japanese: '普通便でお願いします。何日ぐらいかかりますか。', reading: 'futsuubin de onegai shimasu. nannichi gurai kakarimasu ka.', meaning: 'Pengiriman biasa saja. Kira-kira berapa hari?'),
      DialogLine(speaker: '局員', japanese: '二日ほどです。', reading: 'futsuka hodo desu.', meaning: 'Sekitar dua hari.'),
    ],
  ),
  DialogLesson(
    id: 'bank_transfer',
    category: 'Layanan',
    title: 'Melakukan transfer bank',
    description: 'Menanyakan cara melakukan transfer ke rekening lain.',
    level: 'N3',
    icon: Icons.account_balance_rounded,
    premium: true,
    tags: ['bank', 'transfer', 'layanan'],
    lines: const [
      DialogLine(speaker: '客', japanese: '別の銀行へ振り込みたいんですが。', reading: 'betsu no ginkou e furikomitain desu ga.', meaning: 'Saya ingin melakukan transfer ke bank lain.'),
      DialogLine(speaker: '行員', japanese: 'こちらの用紙に必要事項をご記入ください。', reading: 'kochira no youshi ni hitsuyou jikou o gokinyuu kudasai.', meaning: 'Silakan isi informasi yang diperlukan pada formulir ini.'),
      DialogLine(speaker: '客', japanese: '手数料はいくらですか。', reading: 'tesuuryou wa ikura desu ka.', meaning: 'Berapa biaya administrasinya?'),
      DialogLine(speaker: '行員', japanese: 'この金額ですと、六百円です。', reading: 'kono kingaku desu to, roppyaku-en desu.', meaning: 'Untuk jumlah ini, biayanya enam ratus yen.'),
    ],
  ),
  DialogLesson(
    id: 'konbini_bill_payment',
    category: 'Konbini',
    title: 'Membayar tagihan',
    description: 'Membayar tagihan bulanan di konbini.',
    level: 'N4',
    icon: Icons.store_rounded,
    tags: ['konbini', 'tagihan', 'pembayaran'],
    lines: const [
      DialogLine(speaker: '客', japanese: 'この料金を支払いたいです。', reading: 'kono ryoukin o shiharaitai desu.', meaning: 'Saya ingin membayar tagihan ini.'),
      DialogLine(speaker: '店員', japanese: 'はい、バーコードを確認します。', reading: 'hai, baakoodo o kakunin shimasu.', meaning: 'Baik, saya periksa kode batangnya.'),
      DialogLine(speaker: '店員', japanese: '合計は五千二百円です。', reading: 'goukei wa gosen nihyaku-en desu.', meaning: 'Totalnya lima ribu dua ratus yen.'),
      DialogLine(speaker: '客', japanese: '現金でお願いします。', reading: 'genkin de onegai shimasu.', meaning: 'Saya bayar tunai.'),
    ],
  ),
  DialogLesson(
    id: 'factory_machine_stop',
    category: 'Pabrik',
    title: 'Mesin berhenti mendadak',
    description: 'Melaporkan mesin yang berhenti dan mengikuti prosedur keselamatan.',
    level: 'N3',
    icon: Icons.construction_rounded,
    premium: true,
    tags: ['pabrik', 'mesin', 'keselamatan'],
    lines: const [
      DialogLine(speaker: '作業員', japanese: 'すみません、機械が急に止まりました。', reading: 'sumimasen, kikai ga kyuu ni tomarimashita.', meaning: 'Permisi, mesinnya tiba-tiba berhenti.'),
      DialogLine(speaker: '班長', japanese: '電源には触らないでください。', reading: 'dengen ni wa sawaranaide kudasai.', meaning: 'Jangan menyentuh sumber listrik.'),
      DialogLine(speaker: '作業員', japanese: 'はい。周りの人にも伝えます。', reading: 'hai. mawari no hito ni mo tsutaemasu.', meaning: 'Baik. Saya juga akan memberi tahu orang di sekitar.'),
      DialogLine(speaker: '班長', japanese: '担当者を呼びますので、ここで待ってください。', reading: 'tantousha o yobimasu node, koko de matte kudasai.', meaning: 'Saya akan memanggil petugas yang bertanggung jawab, jadi tunggu di sini.'),
    ],
  ),
  DialogLesson(
    id: 'warehouse_inventory',
    category: 'Kerja',
    title: 'Memeriksa persediaan',
    description: 'Mengecek jumlah barang di gudang bersama rekan kerja.',
    level: 'N4',
    icon: Icons.inventory_rounded,
    tags: ['kerja', 'gudang', 'persediaan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: 'この箱は何個残っていますか。', reading: 'kono hako wa nanko nokotte imasu ka.', meaning: 'Kotak ini tersisa berapa?'),
      DialogLine(speaker: 'B', japanese: '今、十二個あります。', reading: 'ima, juuniko arimasu.', meaning: 'Sekarang ada dua belas.'),
      DialogLine(speaker: 'A', japanese: 'あと八個必要です。', reading: 'ato hakko hitsuyou desu.', meaning: 'Kita masih membutuhkan delapan lagi.'),
      DialogLine(speaker: 'B', japanese: '倉庫の奥も確認します。', reading: 'souko no oku mo kakunin shimasu.', meaning: 'Saya akan memeriksa bagian belakang gudang juga.'),
    ],
  ),
  DialogLesson(
    id: 'part_time_shift_swap',
    category: 'Paruh Waktu',
    title: 'Menukar jadwal kerja',
    description: 'Meminta rekan menukar giliran kerja.',
    level: 'N4',
    icon: Icons.schedule_rounded,
    tags: ['paruh waktu', 'jadwal', 'permintaan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '金曜日のシフト、代わってもらえない。', reading: 'kinyoubi no shifuto, kawatte moraenai.', meaning: 'Bisa menggantikan giliran kerja saya hari Jumat?'),
      DialogLine(speaker: 'B', japanese: '何時から。', reading: 'nanji kara.', meaning: 'Mulai jam berapa?'),
      DialogLine(speaker: 'A', japanese: '午後五時から九時まで。', reading: 'gogo goji kara kuji made.', meaning: 'Dari jam lima sore sampai jam sembilan malam.'),
      DialogLine(speaker: 'B', japanese: '大丈夫だよ。日曜日と交換しよう。', reading: 'daijoubu da yo. nichiyoubi to koukan shiyou.', meaning: 'Bisa. Kita tukar dengan jadwal hari Minggu.'),
    ],
  ),
  DialogLesson(
    id: 'earthquake_safety',
    category: 'Darurat',
    title: 'Saat terjadi gempa',
    description: 'Percakapan singkat tentang tindakan aman saat gempa.',
    level: 'N4',
    icon: Icons.warning_rounded,
    tags: ['darurat', 'gempa', 'keselamatan'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '地震です。机の下に入ってください。', reading: 'jishin desu. tsukue no shita ni haitte kudasai.', meaning: 'Gempa. Silakan berlindung di bawah meja.'),
      DialogLine(speaker: 'B', japanese: '外に出たほうがいいですか。', reading: 'soto ni deta hou ga ii desu ka.', meaning: 'Apakah sebaiknya keluar?'),
      DialogLine(speaker: 'A', japanese: '今は危ないので、揺れが止まるまで待ちましょう。', reading: 'ima wa abunai node, yure ga tomaru made machimashou.', meaning: 'Sekarang berbahaya, jadi mari menunggu sampai guncangan berhenti.'),
      DialogLine(speaker: 'B', japanese: '分かりました。', reading: 'wakarimashita.', meaning: 'Baik.'),
    ],
  ),
  DialogLesson(
    id: 'cleaning_duty',
    category: 'Kegiatan Harian',
    title: 'Membagi tugas bersih-bersih',
    description: 'Membagi pekerjaan membersihkan ruangan.',
    level: 'N5',
    icon: Icons.cleaning_services_rounded,
    tags: ['harian', 'bersih-bersih', 'kerja sama'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '私は床を掃除します。', reading: 'watashi wa yuka o souji shimasu.', meaning: 'Saya akan membersihkan lantai.'),
      DialogLine(speaker: 'B', japanese: 'じゃあ、私は机を拭きます。', reading: 'jaa, watashi wa tsukue o fukimasu.', meaning: 'Kalau begitu, saya akan mengelap meja.'),
      DialogLine(speaker: 'A', japanese: 'ごみも出してくれる。', reading: 'gomi mo dashite kureru.', meaning: 'Bisa sekalian membuang sampah?'),
      DialogLine(speaker: 'B', japanese: 'うん、任せて。', reading: 'un, makasete.', meaning: 'Ya, serahkan pada saya.'),
    ],
  ),
  DialogLesson(
    id: 'schedule_appointment_change',
    category: 'Layanan',
    title: 'Mengubah jadwal janji',
    description: 'Meminta perubahan waktu janji dengan sopan.',
    level: 'N4',
    icon: Icons.event_rounded,
    tags: ['jadwal', 'janji', 'sopan'],
    lines: const [
      DialogLine(speaker: '客', japanese: '明日の予約時間を変更したいんですが。', reading: 'ashita no yoyaku jikan o henkou shitain desu ga.', meaning: 'Saya ingin mengubah waktu janji besok.'),
      DialogLine(speaker: '受付', japanese: '何時をご希望ですか。', reading: 'nanji o gokibou desu ka.', meaning: 'Jam berapa yang Anda inginkan?'),
      DialogLine(speaker: '客', japanese: '午後四時にできますか。', reading: 'gogo yoji ni dekimasu ka.', meaning: 'Apakah bisa jam empat sore?'),
      DialogLine(speaker: '受付', japanese: 'はい、変更いたしました。', reading: 'hai, henkou itashimashita.', meaning: 'Ya, sudah kami ubah.'),
    ],
  ),
  DialogLesson(
    id: 'child_pickup',
    category: 'Keluarga',
    title: 'Menjemput anak',
    description: 'Memberi tahu pihak sekolah tentang penjemputan anak.',
    level: 'N4',
    icon: Icons.child_care_rounded,
    tags: ['keluarga', 'sekolah', 'penjemputan'],
    lines: const [
      DialogLine(speaker: '保護者', japanese: '山田太郎の迎えに来ました。', reading: 'yamada tarou no mukae ni kimashita.', meaning: 'Saya datang untuk menjemput Yamada Taro.'),
      DialogLine(speaker: '先生', japanese: 'お名前を確認してもよろしいですか。', reading: 'onamae o kakunin shite mo yoroshii desu ka.', meaning: 'Boleh kami memastikan nama Anda?'),
      DialogLine(speaker: '保護者', japanese: '山田花子です。母です。', reading: 'yamada hanako desu. haha desu.', meaning: 'Saya Yamada Hanako, ibunya.'),
      DialogLine(speaker: '先生', japanese: 'ありがとうございます。すぐ呼びます。', reading: 'arigatou gozaimasu. sugu yobimasu.', meaning: 'Terima kasih. Kami panggil sekarang.'),
    ],
  ),
  DialogLesson(
    id: 'pet_clinic',
    category: 'Kesehatan',
    title: 'Membawa hewan ke klinik',
    description: 'Menjelaskan kondisi hewan peliharaan kepada dokter hewan.',
    level: 'N4',
    icon: Icons.pets_rounded,
    premium: true,
    tags: ['hewan', 'klinik', 'kesehatan'],
    lines: const [
      DialogLine(speaker: '飼い主', japanese: '犬が昨日からご飯を食べないんです。', reading: 'inu ga kinou kara gohan o tabenain desu.', meaning: 'Anjing saya sejak kemarin tidak mau makan.'),
      DialogLine(speaker: '獣医', japanese: '水は飲んでいますか。', reading: 'mizu wa nonde imasu ka.', meaning: 'Apakah masih minum air?'),
      DialogLine(speaker: '飼い主', japanese: '少しだけ飲んでいます。', reading: 'sukoshi dake nonde imasu.', meaning: 'Hanya minum sedikit.'),
      DialogLine(speaker: '獣医', japanese: 'では、まず診察しましょう。', reading: 'dewa, mazu shinsatsu shimashou.', meaning: 'Baik, kita periksa terlebih dahulu.'),
    ],
  ),
  DialogLesson(
    id: 'tourist_information',
    category: 'Perjalanan',
    title: 'Bertanya di pusat informasi',
    description: 'Menanyakan tempat wisata dan cara menuju ke sana.',
    level: 'N4',
    icon: Icons.public_rounded,
    tags: ['wisata', 'informasi', 'arah'],
    lines: const [
      DialogLine(speaker: '旅行者', japanese: 'この近くでおすすめの場所はありますか。', reading: 'kono chikaku de osusume no basho wa arimasu ka.', meaning: 'Apakah ada tempat yang direkomendasikan di sekitar sini?'),
      DialogLine(speaker: '案内員', japanese: '古いお寺と庭園が人気です。', reading: 'furui otera to teien ga ninki desu.', meaning: 'Kuil tua dan taman Jepang cukup populer.'),
      DialogLine(speaker: '旅行者', japanese: '歩いて行けますか。', reading: 'aruite ikemasu ka.', meaning: 'Apakah bisa ditempuh dengan berjalan kaki?'),
      DialogLine(speaker: '案内員', japanese: 'はい、ここから十五分ぐらいです。', reading: 'hai, koko kara juugofun gurai desu.', meaning: 'Ya, sekitar lima belas menit dari sini.'),
    ],
  ),
  DialogLesson(
    id: 'asking_directions_complex',
    category: 'Perjalanan',
    title: 'Menanyakan arah lebih rinci',
    description: 'Memastikan belokan dan patokan tempat ketika mencari alamat.',
    level: 'N4',
    icon: Icons.map_rounded,
    tags: ['arah', 'jalan', 'wisata'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '市役所へ行きたいんですが、道を教えていただけますか。', reading: 'shiyakusho e ikitain desu ga, michi o oshiete itadakemasu ka.', meaning: 'Saya ingin pergi ke balai kota, bisakah Anda menunjukkan jalannya?'),
      DialogLine(speaker: 'B', japanese: 'この道をまっすぐ行って、二つ目の信号を右に曲がってください。', reading: 'kono michi o massugu itte, futatsume no shingou o migi ni magatte kudasai.', meaning: 'Jalan lurus di jalan ini, lalu belok kanan di lampu lalu lintas kedua.'),
      DialogLine(speaker: 'A', japanese: '右に曲がったあと、すぐですか。', reading: 'migi ni magatta ato, sugu desu ka.', meaning: 'Setelah belok kanan, apakah langsung sampai?'),
      DialogLine(speaker: 'B', japanese: 'はい、左側に大きな白い建物があります。', reading: 'hai, hidarigawa ni ookina shiroi tatemono ga arimasu.', meaning: 'Ya, ada gedung putih besar di sebelah kiri.'),
    ],
  ),
  DialogLesson(
    id: 'neighbor_greeting_movein',
    category: 'Tetangga',
    title: 'Menyapa setelah pindah rumah',
    description: 'Memperkenalkan diri kepada tetangga setelah pindah.',
    level: 'N4',
    icon: Icons.home_rounded,
    tags: ['tetangga', 'perkenalan', 'sopan'],
    lines: const [
      DialogLine(speaker: '新住人', japanese: '昨日、隣に引っ越してきたリヤディファルです。', reading: 'kinou, tonari ni hikkoshite kita Riyadhifaru desu.', meaning: 'Saya Riyadhifal yang kemarin baru pindah ke sebelah.'),
      DialogLine(speaker: '隣人', japanese: 'はじめまして。よろしくお願いします。', reading: 'hajimemashite. yoroshiku onegai shimasu.', meaning: 'Salam kenal. Senang bertetangga dengan Anda.'),
      DialogLine(speaker: '新住人', japanese: 'こちらこそ、よろしくお願いします。', reading: 'kochira koso, yoroshiku onegai shimasu.', meaning: 'Saya juga senang bertetangga dengan Anda.'),
      DialogLine(speaker: '隣人', japanese: '何か分からないことがあったら聞いてください。', reading: 'nanika wakaranai koto ga attara kiite kudasai.', meaning: 'Kalau ada yang tidak Anda mengerti, silakan bertanya.'),
    ],
  ),
  DialogLesson(
    id: 'work_feedback',
    category: 'Kerja',
    title: 'Menerima masukan dari atasan',
    description: 'Menanggapi koreksi pekerjaan secara profesional.',
    level: 'N3',
    icon: Icons.work_rounded,
    premium: true,
    tags: ['kerja', 'masukan', 'sopan'],
    lines: const [
      DialogLine(speaker: '上司', japanese: 'この資料ですが、数字をもう一度確認してください。', reading: 'kono shiryou desu ga, suuji o mou ichido kakunin shite kudasai.', meaning: 'Untuk dokumen ini, tolong periksa kembali angkanya.'),
      DialogLine(speaker: '社員', japanese: '申し訳ありません。すぐに確認します。', reading: 'moushiwake arimasen. sugu ni kakunin shimasu.', meaning: 'Mohon maaf. Akan segera saya periksa.'),
      DialogLine(speaker: '上司', japanese: '確認したら、今日中に送り直してください。', reading: 'kakunin shitara, kyoujuu ni okurinaoshite kudasai.', meaning: 'Setelah diperiksa, tolong kirim ulang hari ini.'),
      DialogLine(speaker: '社員', japanese: '承知しました。', reading: 'shouchi shimashita.', meaning: 'Baik, saya mengerti.'),
    ],
  ),
  DialogLesson(
    id: 'interview_strength',
    category: 'Wawancara',
    title: 'Menjelaskan kelebihan diri',
    description: 'Menjawab pertanyaan tentang kelebihan saat wawancara kerja.',
    level: 'N3',
    icon: Icons.badge_rounded,
    premium: true,
    tags: ['wawancara', 'kerja', 'kelebihan'],
    lines: const [
      DialogLine(speaker: '面接官', japanese: 'あなたの長所を教えてください。', reading: 'anata no chousho o oshiete kudasai.', meaning: 'Tolong jelaskan kelebihan Anda.'),
      DialogLine(speaker: '応募者', japanese: '最後まで責任を持って仕事をするところです。', reading: 'saigo made sekinin o motte shigoto o suru tokoro desu.', meaning: 'Kelebihan saya adalah bertanggung jawab menyelesaikan pekerjaan sampai akhir.'),
      DialogLine(speaker: '面接官', japanese: '具体的な経験はありますか。', reading: 'gutaiteki na keiken wa arimasu ka.', meaning: 'Apakah ada pengalaman konkretnya?'),
      DialogLine(speaker: '応募者', japanese: 'はい、学校のチーム活動で進行役を担当しました。', reading: 'hai, gakkou no chiimu katsudou de shinkouyaku o tantou shimashita.', meaning: 'Ya, saya pernah menjadi penanggung jawab jalannya kegiatan tim di sekolah.'),
    ],
  ),
  DialogLesson(
    id: 'friend_congratulations',
    category: 'Pertemanan',
    title: 'Mengucapkan selamat',
    description: 'Memberi selamat kepada teman atas keberhasilannya.',
    level: 'N5',
    icon: Icons.celebration_rounded,
    tags: ['teman', 'selamat', 'santai'],
    lines: const [
      DialogLine(speaker: 'A', japanese: '試験に合格したんだって。おめでとう。', reading: 'shiken ni goukaku shitan datte. omedetou.', meaning: 'Katanya kamu lulus ujian. Selamat!'),
      DialogLine(speaker: 'B', japanese: 'ありがとう。すごくうれしい。', reading: 'arigatou. sugoku ureshii.', meaning: 'Terima kasih. Saya senang sekali.'),
      DialogLine(speaker: 'A', japanese: 'ずっと頑張ってたもんね。', reading: 'zutto ganbatteta mon ne.', meaning: 'Kamu memang sudah lama berusaha keras.'),
      DialogLine(speaker: 'B', japanese: '次の目標も頑張るよ。', reading: 'tsugi no mokuhyou mo ganbaru yo.', meaning: 'Saya juga akan berusaha untuk target berikutnya.'),
    ],
  ),

];
