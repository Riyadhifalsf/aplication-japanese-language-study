import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../../services/pricing_service.dart';
import '../payment/payment_checkout_screen.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.paymentsEnabled) {
      return Scaffold(appBar: AppBar(title: const Text('Langganan & Pembayaran')), body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Card(child: Padding(padding: EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_clock_rounded, size: 44), SizedBox(height: 12), Text('Pembayaran belum diaktifkan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('Fitur payment sengaja dinonaktifkan selama tahap pengujian. Aktifkan dari Dashboard Admin saat siap diuji.', textAlign: TextAlign.center)]))))));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Langganan & Pembayaran')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 32), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2F2C44), Color(0xFF635BFF)]), borderRadius: BorderRadius.circular(30)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_rounded, color: Color(0xFFFFC400), size: 40),
            SizedBox(height: 14),
            Text('Pembayaran aman & fleksibel', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('QRIS, kartu, e-wallet, bank transfer, dan crypto. Rahasia API hanya berada di server.', style: TextStyle(color: Colors.white70, height: 1.45)),
          ]),
        ),
        const SizedBox(height: 16),
        _TierCard(
          title: 'PREMIUM',
          subtitle: '${_idr(PricingService.premium.amountIdr)} ${PricingService.premium.intervalLabel} · harga v${PricingService.premium.priceVersion}',
          color: const Color(0xFFFFA62B),
          active: app.membershipPlan == 'premium',
          features: PricingService.premium.features,
          button: 'Bayar Premium',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentCheckoutScreen(plan: PricingService.premium))),
        ),
        const SizedBox(height: 12),
        _TierCard(
          title: 'LIFETIME',
          subtitle: '${_idr(PricingService.lifetime.amountIdr)} sekali bayar · harga v${PricingService.lifetime.priceVersion}',
          color: const Color(0xFF7C3AED),
          active: app.membershipPlan == 'lifetime',
          features: PricingService.lifetime.features,
          button: 'Bayar Lifetime',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentCheckoutScreen(plan: PricingService.lifetime))),
        ),
        const SizedBox(height: 14),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55),
          child: const Padding(
            padding: EdgeInsets.all(15),
            child: Text('Grandfather pricing aktif: setiap order menyimpan price_version dan nominal saat transaksi. Ketika harga dinaikkan di masa depan, pembeli lama tetap mengikuti harga/order yang sudah mereka beli.', style: TextStyle(fontWeight: FontWeight.w700, height: 1.4)),
          ),
        ),
      ]),
    );
  }

  static String _idr(int amount) => 'Rp${amount.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}';

}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.title, required this.subtitle, required this.color, required this.active, required this.features, required this.button, required this.onTap});
  final String title; final String subtitle; final Color color; final bool active; final List<String> features; final String button; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: BorderSide(color: active ? color : Theme.of(context).colorScheme.outlineVariant, width: active ? 2 : 1)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.workspace_premium_rounded, color: color)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])), if (active) Icon(Icons.check_circle_rounded, color: color)]), const SizedBox(height: 14), for (final feature in features) Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Icon(Icons.check_rounded, size: 18, color: color), const SizedBox(width: 8), Expanded(child: Text(feature, style: const TextStyle(fontWeight: FontWeight.w700)))])), const SizedBox(height: 8), SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: onTap, child: Text(active ? 'Sedang aktif' : button)))])));
}
