import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syarat & Layanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: const [
          Text('Penggunaan aplikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          SizedBox(height: 10),
          Text('Japanese Study digunakan sebagai sarana belajar bahasa Jepang. Gunakan materi secara wajar dan jangan mencoba mengeksploitasi layanan untuk memanipulasi progress atau akses akun.'),
          SizedBox(height: 20),
          Text('Akun dan data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Kamu bertanggung jawab atas keamanan akun. Data belajar dapat tersimpan lokal dan, saat sinkronisasi diaktifkan, pada layanan cloud yang digunakan aplikasi.'),
          SizedBox(height: 20),
          Text('Perubahan layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Fitur, materi, dan kebijakan dapat diperbarui untuk menjaga kualitas, keamanan, dan kestabilan aplikasi.'),
        ],
      ),
    );
  }
}
