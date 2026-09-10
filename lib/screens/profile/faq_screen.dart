import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const entries = <({String q, String a})>[
    (q: 'Bagaimana cara melanjutkan belajar?', a: 'Buka Learning, pilih level, bab, lalu sub-bab. Setelah satu sub-bab selesai, tombol lanjut akan membawa kamu ke sub-bab berikutnya.'),
    (q: 'Apa perbedaan N5 sampai N1?', a: 'N5 adalah tingkat pemula dan N1 adalah tingkat mahir. Materi disusun bertahap sehingga kamu bisa berpindah level setelah penguasaan materi meningkat.'),
    (q: 'Apakah progress tersimpan offline?', a: 'Ya. Progress utama disimpan di perangkat dan dapat disinkronkan saat akun terhubung.'),
    (q: 'Bagaimana cara mengulang materi yang lemah?', a: 'Aktifkan pengaturan Ulangi materi lemah agar latihan berikutnya lebih sering memilih materi dengan penguasaan rendah.'),
    (q: 'Bagaimana cara menghapus data belajar?', a: 'Gunakan menu Bersihkan data belajar. Gunakan Reset belajar hanya setelah membaca konfirmasi karena progress latihan akan kembali ke keadaan awal.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & FAQ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          const Text('Pertanyaan umum', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final item in entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(title: Text(item.q, style: const TextStyle(fontWeight: FontWeight.w800)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [Text(item.a)]),
            ),
        ],
      ),
    );
  }
}
