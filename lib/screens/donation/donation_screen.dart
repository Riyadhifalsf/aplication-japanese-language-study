import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/donation_config.dart';

/// Layar donasi: satu CTA utama ke Saweria, leaderboard donatur,
/// dan dukungan gratis lewat rating Play Store.
class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  String get _saweriaUrl {
    final methods = DonationConfig.methods;
    for (final method in methods) {
      if (method.label.toLowerCase() == 'saweria') return method.value;
    }
    return methods.isNotEmpty ? methods.first.value : '';
  }

  Future<void> _openSaweria(BuildContext context) async {
    final url = _saweriaUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link donasi belum dikonfigurasi.')),
      );
      return;
    }
    final uri = Uri.parse(url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !context.mounted) return;
    } catch (_) {
      // Fall through to snackbar.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka halaman donasi.')),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    final url = _saweriaUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link donasi belum dikonfigurasi.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link Saweria tersalin.')),
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
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Tidak dapat membuka Play Store di perangkat ini.')),
    );
  }

  String _rupiah(int amount) =>
      'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final donors = [...DonationConfig.donors]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dukung Japanese Study')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [cs.primary, const Color(0xFF4A1110)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Dukung Japanese Study',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bantu biaya server, materi, dan pengembangan aplikasi agar tetap bisa digunakan untuk belajar bahasa Jepang.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openSaweria(context),
                    icon: const Icon(Icons.volunteer_activism_rounded),
                    label: const Text('Donasi lewat Saweria'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyLink(context),
                    icon: const Icon(Icons.link_rounded, color: Colors.white),
                    label: const Text('Salin link Saweria',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: const Icon(Icons.emoji_events_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Leaderboard donatur',
                                style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900)),
                            SizedBox(height: 3),
                            Text(
                                'Dukungan terbesar ditampilkan di urutan teratas.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DonationMetric(
                          value: '${DonationConfig.donorCount}',
                          label: 'Donatur',
                        ),
                      ),
                      Expanded(
                        child: _DonationMetric(
                          value: _rupiah(DonationConfig.totalAmount),
                          label: 'Total dukungan',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (donors.isEmpty)
                    Text(
                      'Leaderboard akan terisi saat data donasi dari backend tersedia. Data pembayaran sensitif tidak disimpan di aplikasi.',
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                    )
                  else ...[
                    const Divider(height: 28),
                    const Text('Top donatur',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < donors.take(10).length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(donors[i].displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: Text(_rupiah(donors[i].amount),
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Dukungan gratis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading:
                  const CircleAvatar(child: Icon(Icons.star_rounded)),
              title: const Text('Beri rating 5 bintang',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Rating membantu aplikasi lebih mudah ditemukan.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _rate(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationMetric extends StatelessWidget {
  const _DonationMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12)),
        ],
      );
}
