import 'package:flutter/material.dart';

import '../../services/subscription_plans.dart';
import '../../state/app_controller.dart';

/// Layar Premium: pilih paket (harga naik per fase) + metode bayar.
///
/// Penagihan nyata BELUM aktif — butuh kunci PSP di backend dan
/// Google Play Billing untuk versi Play Store. Tombol bayar menampilkan
/// status integrasi masing-masing metode secara jujur.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _planId = 'yearly';
  String _methodId = 'qris';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final phase = SubscriptionCatalog.activePhase();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Japanese Study Premium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          Card(
            color: cs.primaryContainer.withValues(alpha: .5),
            child: const ListTile(
              leading: Icon(Icons.workspace_premium_rounded),
              title: Text('Buka semua materi',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                  'Tanpa iklan, semua level JLPT, simulasi ujian, dan sync cloud prioritas.'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Pilih paket',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Fase ${phase.name}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final plan in SubscriptionCatalog.plans)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<String>(
                value: plan.id,
                groupValue: _planId,
                onChanged: (v) => setState(() => _planId = v ?? _planId),
                title: Row(
                  children: [
                    Text(plan.title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    if (plan.badge.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(plan.badge,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: cs.onPrimary)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(plan.subtitle),
                secondary: Text(
                  SubscriptionCatalog.rupiah(phase.priceOf(plan.id)),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          const SizedBox(height: 14),
          const Text('Metode pembayaran',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0;
                    i < SubscriptionCatalog.methods.length;
                    i++) ...[
                  if (i > 0) const Divider(height: 1),
                  RadioListTile<String>(
                    value: SubscriptionCatalog.methods[i].id,
                    groupValue: _methodId,
                    onChanged: (v) =>
                        setState(() => _methodId = v ?? _methodId),
                    title: Text(SubscriptionCatalog.methods[i].label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle:
                        Text(SubscriptionCatalog.methods[i].note),
                    secondary: Icon(SubscriptionCatalog.methods[i].icon),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _pay(context, app, phase),
            icon: const Icon(Icons.lock_rounded),
            label: Text(
                'Bayar ${SubscriptionCatalog.rupiah(phase.priceOf(_planId))}'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pembayaran aman end-to-end saat integrasi PSP aktif. Harga bisa naik di fase berikutnya — kunci harga sekarang.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _pay(BuildContext context, AppController app, PricePhase phase) {
    final method = SubscriptionCatalog.methods
        .firstWhere((m) => m.id == _methodId);
    if (!method.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${method.label} segera hadir. Integrasi PSP sedang disiapkan — harga fase ${phase.name} terkunci untukmu.',
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuka pembayaran…')),
    );
  }
}
