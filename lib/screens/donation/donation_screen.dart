import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/donation_config.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  Future<void> _openSaweria(BuildContext context) async {
    final uri = Uri.parse(DonationConfig.saweriaUrl);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka Saweria.')),
    );
  }

  Future<void> _copySaweria(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: DonationConfig.saweriaUrl),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link Saweria disalin.')),
    );
  }

  Future<void> _rate(BuildContext context) async {
    final uris = [
      Uri.parse('market://details?id=${DonationConfig.playPackage}'),
      Uri.parse(
        'https://play.google.com/store/apps/details?id=${DonationConfig.playPackage}',
      ),
    ];
    for (final uri in uris) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka Play Store.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donors = [...DonationConfig.donors]
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      appBar: AppBar(title: const Text('Donasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
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
                Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                SizedBox(height: 12),
                Text(
                  'Dukung Japanese Language Study',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Dukungan digunakan untuk pengembangan aplikasi dan konten pembelajaran.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SaweriaCard(
            onOpen: () => _openSaweria(context),
            onCopy: () => _copySaweria(context),
          ),
          const SizedBox(height: 18),
          _Leaderboard(donors: donors),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.star_rounded)),
              title: const Text(
                'Beri rating di Play Store',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('Dukungan gratis yang membantu aplikasi berkembang.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _rate(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaweriaCard extends StatelessWidget {
  const _SaweriaCard({required this.onOpen, required this.onCopy});

  final VoidCallback onOpen;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(child: Icon(Icons.favorite_rounded)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saweria',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 3),
                      Text('Donasi langsung melalui halaman resmi.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DonationConfig.saweriaUrl,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Donasi sekarang'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onCopy,
                  tooltip: 'Salin link Saweria',
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.donors});

  final List<DonationRecord> donors;

  String _rupiah(int amount) =>
      'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.leaderboard_rounded),
                SizedBox(width: 10),
                Text(
                  'Leaderboard donatur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Urutan berdasarkan total dukungan.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (donors.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 34),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada donatur yang ditampilkan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Leaderboard akan menampilkan data yang sudah masuk ke feed donasi aplikasi.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              if (donors.length >= 3) _TopThree(donors: donors, rupiah: _rupiah),
              const SizedBox(height: 8),
              for (var i = donors.length >= 3 ? 3 : 0; i < donors.take(10).length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(
                    donors[i].displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: Text(
                    _rupiah(donors[i].amount),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    value: '${DonationConfig.donorCount}',
                    label: 'Donatur',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: _rupiah(DonationConfig.totalAmount),
                    label: 'Total dukungan',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopThree extends StatelessWidget {
  const _TopThree({required this.donors, required this.rupiah});

  final List<DonationRecord> donors;
  final String Function(int) rupiah;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _Podium(rank: 2, donor: donors[1], rupiah: rupiah)),
        const SizedBox(width: 8),
        Expanded(child: _Podium(rank: 1, donor: donors[0], rupiah: rupiah)),
        const SizedBox(width: 8),
        Expanded(child: _Podium(rank: 3, donor: donors[2], rupiah: rupiah)),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.rank, required this.donor, required this.rupiah});

  final int rank;
  final DonationRecord donor;
  final String Function(int) rupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(rank == 1 ? Icons.emoji_events_rounded : Icons.workspace_premium_rounded),
          const SizedBox(height: 6),
          Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            donor.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            rupiah(donor.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      );
}
