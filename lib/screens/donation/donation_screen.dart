import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/donation_config.dart';

/// Layar Donasi: dukung pengembangan agar aplikasi tetap gratis.
/// Menampilkan HANYA kanal resmi yang diisi di [DonationConfig.methods]
/// (tombol salin) + dukungan gratis (rating Play Store). Tidak ada tombol
/// dummy: setiap aksi benar-benar berfungsi.
class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  Future<void> _copy(BuildContext context, DonationMethod method) async {
    await Clipboard.setData(ClipboardData(text: method.value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${method.label} tersalin.')),
    );
  }

  Future<void> _rate(BuildContext context) async {
    final uris = [
      Uri.parse('market://details?id=${DonationConfig.playPackage}'),
      Uri.parse(
          'https://play.google.com/store/apps/details?id=${DonationConfig.playPackage}'),
    ];
    for (final uri in uris) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {
        // Coba tautan berikutnya.
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Tidak dapat membuka Play Store di perangkat ini.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods = DonationConfig.methods;
    return Scaffold(
      appBar: AppBar(title: const Text('Donasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF4A1110),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.volunteer_activism_rounded,
                    color: Colors.white, size: 36),
                SizedBox(height: 10),
                Text('Dukung Japanese Study',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text(
                  'Aplikasi ini gratis tanpa paywall. Donasimu menjaga server, konten, dan pengembangan tetap berjalan.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Kanal resmi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (methods.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Belum ada kanal donasi',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    'Kanal resmi akan tampil di sini. Sementara itu kamu tetap bisa mendukung lewat rating.'),
              ),
            )
          else
            for (final method in methods)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(method.icon)),
                    title: Text(method.label,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('${method.value}\n${method.note}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Salin ${method.label}',
                      onPressed: () => _copy(context, method),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          const Text('Dukungan gratis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.star_rounded)),
              title: const Text('Beri rating 5 bintang',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle:
                  const Text('Buka halaman aplikasi di Play Store.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _rate(context),
            ),
          ),
        ],
      ),
    );
  }
}
