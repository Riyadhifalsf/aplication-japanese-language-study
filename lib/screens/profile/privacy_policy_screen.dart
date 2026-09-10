import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: const [
          Text('Kebijakan Privasi',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          SizedBox(height: 12),
          Text(
              'Aplikasi menyimpan progres belajar secara lokal pada perangkat. Data seperti XP, streak, hasil kuis, target belajar, dan preferensi digunakan untuk menjalankan fitur aplikasi.',
              style: TextStyle(height: 1.5)),
          SizedBox(height: 18),
          Text('Akun Google',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text(
              'Jika pengguna memilih masuk dengan Google, aplikasi dapat menerima nama, email, dan foto profil dari akun Google untuk mengisi profil. Integrasi Google Drive digunakan untuk cadangan progres jika pengguna mengaktifkannya.',
              style: TextStyle(height: 1.5)),
          SizedBox(height: 18),
          Text('Sistem rekomendasi belajar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text(
              'Versi saat ini menggunakan penilaian offline berbasis progres aplikasi. Tidak ada data belajar yang dikirim ke model AI eksternal untuk fitur tersebut.',
              style: TextStyle(height: 1.5)),
          SizedBox(height: 18),
          Text('Iklan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text(
              'Slot iklan dapat digunakan pada versi gratis. Saat SDK iklan ditambahkan, kebijakan ini perlu diperbarui untuk menjelaskan penyedia iklan dan data yang diproses.',
              style: TextStyle(height: 1.5)),
          SizedBox(height: 18),
          Text('Catatan pengembangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text(
              'Kebijakan ini adalah draft aplikasi dan perlu ditinjau ulang sebelum rilis publik/produksi, terutama setelah database, autentikasi email, analitik, dan SDK iklan diaktifkan.',
              style: TextStyle(height: 1.5)),
        ],
      ));
}
