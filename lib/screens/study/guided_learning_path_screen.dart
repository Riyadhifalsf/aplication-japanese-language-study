import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../grammar/grammar_screen.dart';
import '../vocab/vocabulary_screen.dart';

class GuidedLearningPathScreen extends StatelessWidget {
  const GuidedLearningPathScreen({super.key, this.initialLevel});
  final String? initialLevel;

  static const _n5 = <_Chapter>[
    _Chapter(1, 'Perkenalan', 'Salam, identitas, profesi, dan pola です.', ['は・です', 'も', 'の'], 'N5'),
    _Chapter(2, 'Benda & kepemilikan', 'Menunjuk benda dan menyatakan milik siapa.', ['これ・それ・あれ', 'この・その・あの', 'の'], 'N5'),
    _Chapter(3, 'Tempat & harga', 'Lokasi, asal barang, dan transaksi sederhana.', ['ここ・そこ・あそこ', 'こちら', '～円'], 'N5'),
    _Chapter(4, 'Waktu & rutinitas', 'Jam, hari, jadwal, dan aktivitas harian.', ['～時・～分', 'から・まで', 'ます形'], 'N5'),
    _Chapter(5, 'Pergi & datang', 'Perjalanan, kendaraan, dan tujuan.', ['へ', 'で', 'と'], 'N5'),
    _Chapter(6, 'Aktivitas', 'Objek tindakan dan ajakan sederhana.', ['を', 'ませんか', 'ましょう'], 'N5'),
    _Chapter(7, 'Memberi & menerima', 'Hadiah, alat, dan cara melakukan sesuatu.', ['あげます', 'もらいます', 'くれます'], 'N5'),
    _Chapter(8, 'Deskripsi', 'Sifat benda, tempat, dan kesan sederhana.', ['い-adjective', 'な-adjective', 'とても'], 'N5'),
    _Chapter(9, 'Kesukaan & kemampuan', 'Kesukaan, pemahaman, dan alasan dasar.', ['好き', '分かります', 'から'], 'N5'),
    _Chapter(10, 'Ada & berada', 'Lokasi orang dan benda.', ['あります', 'います', '場所'], 'N5'),
    _Chapter(11, 'Jumlah & frekuensi', 'Hitungan, durasi, dan seberapa sering.', ['counter', '～ぐらい', 'frequency'], 'N5'),
    _Chapter(12, 'Perbandingan', 'Membandingkan benda dan pengalaman.', ['lebih dari', 'paling', 'lebih suka'], 'N5'),
    _Chapter(13, 'Keinginan', 'Menyatakan ingin melakukan atau memiliki sesuatu.', ['ほしい', '～たい', 'に行きます'], 'N5'),
    _Chapter(14, 'Bentuk て', 'Mulai memakai bentuk て untuk permintaan dan progres.', ['てください', 'ています'], 'N5'),
    _Chapter(15, 'Izin & larangan', 'Aturan, izin, dan kebiasaan.', ['てもいい', 'てはいけない', 'ています'], 'N5'),
    _Chapter(16, 'Menghubungkan kalimat', 'Menyusun beberapa aksi menjadi satu cerita.', ['てから', 'ながら', '～たり'], 'N5'),
    _Chapter(17, 'Kewajiban', 'Hal yang harus dan tidak perlu dilakukan.', ['なければならない', 'なくてもいい'], 'N5'),
    _Chapter(18, 'Kemampuan & hobi', 'Kemampuan, hobi, dan persiapan.', ['ことができます', '趣味', 'まえに'], 'N5'),
    _Chapter(19, 'Pengalaman', 'Menceritakan pengalaman dan perubahan keadaan.', ['たことがあります', 'たり', 'なります'], 'N5'),
    _Chapter(20, 'Bentuk biasa', 'Berpindah dari bentuk sopan ke percakapan kasual.', ['普通形', 'と思います'], 'N5'),
    _Chapter(21, 'Pendapat & kutipan', 'Menyampaikan pendapat, kutipan, dan alasan.', ['と思います', 'と言います', 'でしょう'], 'N5'),
    _Chapter(22, 'Klausa penerang', 'Menjelaskan orang atau benda dengan kalimat.', ['relative clause'], 'N5'),
    _Chapter(23, 'Saat & kondisi', 'Menghubungkan waktu, keadaan, dan hasil.', ['とき', 'と', 'なら'], 'N5'),
    _Chapter(24, 'Memberi bantuan', 'Ungkapan bantuan dan menerima tindakan.', ['くれます', 'もらいます', 'てあげます'], 'N5'),
    _Chapter(25, 'Kondisional dasar', 'Harapan, syarat, dan rencana ke depan.', ['たら', 'もし', '～ても'], 'N5'),
  ];

  static const _n4 = <_Chapter>[
    _Chapter(26, 'Alasan & situasi', 'Menjelaskan keadaan dan meminta saran dengan lebih natural.', ['んです', 'ていただけませんか', 'たらいいですか'], 'N4'),
    _Chapter(27, 'Kemungkinan', 'Kemampuan, apa yang terlihat/terdengar, dan pembatasan.', ['可能形', '見えます・聞こえます', 'しか'], 'N4'),
    _Chapter(28, 'Kebiasaan & dua aksi', 'Menggabungkan aktivitas dan beberapa alasan.', ['ながら', 'し', 'ています'], 'N4'),
    _Chapter(29, 'Keadaan & selesai', 'Perubahan keadaan dan pekerjaan yang sudah selesai.', ['ています', 'てしまいます'], 'N4'),
    _Chapter(30, 'Persiapan', 'Menjelaskan sesuatu yang sudah disiapkan.', ['てあります', 'ておきます'], 'N4'),
    _Chapter(31, 'Rencana', 'Rencana, niat, dan keputusan.', ['つもり', '予定', 'ようと思います'], 'N4'),
    _Chapter(32, 'Nasihat & kemungkinan', 'Menyatakan dugaan, saran, dan kewajiban.', ['ほうがいい', 'でしょう', 'かもしれない'], 'N4'),
    _Chapter(33, 'Perintah & tanda', 'Memahami instruksi dan informasi tertulis.', ['命令形', '禁止形', '～という意味'], 'N4'),
    _Chapter(34, 'Urutan tindakan', 'Menyusun prosedur dan keadaan setelah tindakan.', ['とおりに', 'あとで', 'ないで'], 'N4'),
    _Chapter(35, 'Syarat ば', 'Syarat dan kondisi yang lebih luas.', ['ば', 'なら', 'ならば'], 'N4'),
    _Chapter(36, 'Tujuan & perubahan', 'Menyatakan usaha dan perubahan kemampuan.', ['ように', 'ようになります', 'ようにします'], 'N4'),
    _Chapter(37, 'Pasif', 'Mengenal bentuk pasif dalam situasi sehari-hari.', ['受身'], 'N4'),
    _Chapter(38, 'Nominalisasi', 'Mengubah aksi menjadi topik atau objek pembicaraan.', ['のは', 'のが', 'のを'], 'N4'),
    _Chapter(39, 'Sebab & perasaan', 'Menjelaskan sebab dan respons emosional.', ['ので', 'て', 'ために'], 'N4'),
    _Chapter(40, 'Pertanyaan tidak langsung', 'Menyampaikan pertanyaan dan hasil percobaan.', ['かどうか', 'てみます'], 'N4'),
    _Chapter(41, 'Pemberian tingkat lanjut', 'Memberi dan menerima tindakan secara lebih sopan.', ['いただきます', 'くださいます', 'やります'], 'N4'),
    _Chapter(42, 'Tujuan', 'Menjelaskan tujuan tindakan dan kegunaan.', ['ために', 'のに'], 'N4'),
    _Chapter(43, 'Tampak & mulai', 'Menyatakan kecenderungan dan perubahan yang terlihat.', ['そうです', 'ようです'], 'N4'),
    _Chapter(44, 'Cara & terlalu', 'Menyatakan cara, tingkat berlebihan, dan mudah/sulit.', ['すぎます', 'やすい・にくい', 'ように'], 'N4'),
    _Chapter(45, 'Jika terjadi', 'Membicarakan kondisi dan respons.', ['場合', 'のに'], 'N4'),
    _Chapter(46, 'Waktu kejadian', 'Menyatakan tindakan yang baru saja, akan, atau sedang terjadi.', ['ところ', 'ばかり', 'はず'], 'N4'),
    _Chapter(47, 'Dugaan', 'Menyatakan informasi yang didengar dan kemungkinan.', ['そうです', 'ようです', 'らしい'], 'N4'),
    _Chapter(48, 'Kausatif', 'Menyatakan membuat/membiarkan orang melakukan sesuatu.', ['使役'], 'N4'),
    _Chapter(49, 'Hormat', 'Bahasa hormat untuk situasi formal.', ['尊敬語'], 'N4'),
    _Chapter(50, 'Rendah hati', 'Bahasa merendahkan diri dan komunikasi formal.', ['謙譲語', 'お・ご'], 'N4'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final selected = initialLevel ?? app.selectedStudyLevel;
    return Scaffold(
      appBar: AppBar(title: const Text('Jalur Belajar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          _Hero(app: app),
          const SizedBox(height: 14),
          _LevelSelector(value: selected, onChanged: app.setSelectedStudyLevel),
          const SizedBox(height: 18),
          _PathList(level: selected, chapters: selected == 'N4' ? _n4 : _n5),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF302D46)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Jalur terarah', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('Nggak perlu bingung mulai dari mana.', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text('Bab disusun sebagai roadmap aplikasi dengan referensi struktur Minna no Nihongo dan target JLPT. Kontennya tidak menyalin isi buku.', style: const TextStyle(color: Colors.white70, height: 1.4)),
        ]),
      );
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [for (final level in const ['N5', 'N4']) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(level), selected: value == level, onSelected: (_) => onChanged(level)))]),
      );
}

class _PathList extends StatelessWidget {
  const _PathList({required this.level, required this.chapters});
  final String level;
  final List<_Chapter> chapters;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(level == 'N5' ? 'Fondasi → JLPT N5' : 'Penguatan → JLPT N4', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text('${chapters.length} bab • selesaikan berurutan agar progres terasa jelas.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 12),
      for (final chapter in chapters) _ChapterCard(chapter: chapter, completed: app.completedLearningStepIds.contains('chapter-${chapter.number}')),
    ]);
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.completed});
  final _Chapter chapter;
  final bool completed;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ChapterDetail(chapter: chapter))),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              CircleAvatar(child: completed ? const Icon(Icons.check_rounded) : Text('${chapter.number}')),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bab ${chapter.number} · ${chapter.title}', style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(chapter.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]),),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ),
      );
}

class _ChapterDetail extends StatelessWidget {
  const _ChapterDetail({required this.chapter});
  final _Chapter chapter;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final done = app.completedLearningStepIds.contains('chapter-${chapter.number}');
    return Scaffold(
      appBar: AppBar(title: Text('Bab ${chapter.number}')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 30), children: [
        Text(chapter.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(chapter.summary, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45)),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Yang perlu dikuasai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 10), for (final topic in chapter.topics) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check_circle_outline_rounded, size: 18), const SizedBox(width: 8), Expanded(child: Text(topic))]))]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Latihan aplikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 10), const Text('Gunakan modul kosakata dan tata bahasa yang tersedia untuk memperkuat bab ini.'), const SizedBox(height: 14), Row(children: [Expanded(child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VocabularyScreen(initialLevel: chapter.level))), icon: const Icon(Icons.translate_rounded), label: const Text('Kotoba'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrammarScreen(initialLevel: chapter.level))), icon: const Icon(Icons.rule_rounded), label: const Text('Bunpou')))])]))),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: done ? null : () { app.completeLearningStep('chapter-${chapter.number}'); if (context.mounted) Navigator.pop(context); }, icon: Icon(done ? Icons.check_rounded : Icons.done_all_rounded), label: Text(done ? 'Bab selesai' : 'Tandai bab selesai')),
      ]),
    );
  }
}

class _Chapter {
  const _Chapter(this.number, this.title, this.summary, this.topics, this.level);
  final int number;
  final String title;
  final String summary;
  final List<String> topics;
  final String level;
}
