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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
            children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: .92),
                  const Color(0xFF4A1110)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('寄付 · kifu',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 10),
                    Text('Donasi',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Text(
                        'Dukunganmu menjaga aplikasi tetap gratis untuk semua.',
                        style: TextStyle(
                            color: Colors.white70, height: 1.4)),
                  ])),
              SizedBox(width: 12),
              CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 16),
          _LeaderboardCard(donors: donors, rupiah: _rupiah),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Donasi via Saweria',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openSaweria(context),
                      icon:
                          const Icon(Icons.volunteer_activism_rounded),
                      label: const Text('Donasi lewat Saweria'),
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyLink(context),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Salin link Saweria'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
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
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.donors, required this.rupiah});

  final List<DonationRecord> donors;
  final String Function(int amount) rupiah;

  /// Contoh tampilan SEMENTARA selama feed donasi nyata masih kosong.
  /// 100% static/mock, terisolasi di sini, dan TIDAK dicampur dengan data
  /// donatur nyata. Backend leaderboard sungguhan belum dibuat.
  static const _demo = <DonationRecord>[
    DonationRecord(displayName: 'Haruto', amount: 500000),
    DonationRecord(displayName: 'Yuki', amount: 350000),
    DonationRecord(displayName: 'Aoi', amount: 200000),
    DonationRecord(displayName: 'Sakura', amount: 150000),
    DonationRecord(displayName: 'Ren', amount: 100000),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDemo = donors.isEmpty;
    final shown = isDemo ? _demo : donors;
    final total =
        shown.fold<int>(0, (sum, item) => sum + item.amount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
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
                            fontSize: 19, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text(
                        'Dukungan terbesar ditampilkan di urutan teratas.'),
                  ],
                ),
              ),
              if (isDemo)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Demo',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: cs.onTertiaryContainer)),
                ),
            ]),
            if (isDemo) ...[
              const SizedBox(height: 6),
              Text(
                'Contoh tampilan. Bukan peringkat donatur nyata.',
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DonationMetric(
                    value: '${shown.length}',
                    label: 'Donatur',
                  ),
                ),
                Expanded(
                  child: _DonationMetric(
                    value: rupiah(total),
                    label: 'Total dukungan',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 28),
            const Text('Top donatur',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (var i = 0; i < shown.take(10).length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(shown[i].displayName,
                    style:
                        const TextStyle(fontWeight: FontWeight.w800)),
                trailing: Text(rupiah(shown[i].amount),
                    style:
                        const TextStyle(fontWeight: FontWeight.w900)),
              ),
          ],
        ),
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
