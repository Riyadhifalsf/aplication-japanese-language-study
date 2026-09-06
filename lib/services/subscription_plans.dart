import 'package:flutter/material.dart';

/// Paket langganan Japanese Study.
///
/// Harga MURAH saat peluncuran lalu NAIK bertahap per fase
/// ([phases]). Harga aktif dipilih dari tanggal hari ini, jadi kenaikan
/// harga cukup lewat update aplikasi tanpa ubah kode lain.
///
/// PEMBAYARAN NYATA belum aktif: penagihan butuh kunci PSP di backend
/// (Xendit/Midtrans untuk QRIS & bank, BTCPay untuk crypto) dan
/// Google Play Billing untuk versi Play Store (wajib oleh kebijakan
/// Google untuk barang digital). Lihat checklist-konfigurasi.txt.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.months,
    this.lifetime = false,
    this.badge = '',
  });

  final String id; // 'monthly' | 'yearly' | 'lifetime'
  final String title;
  final String subtitle;
  final int months;
  final bool lifetime;
  final String badge;
}

class PricePhase {
  const PricePhase({
    required this.name,
    required this.effectiveFrom,
    required this.monthly,
    required this.yearly,
    required this.lifetime,
  });

  final String name;
  final DateTime effectiveFrom;
  final int monthly;
  final int yearly;
  final int lifetime;

  int priceOf(String planId) => switch (planId) {
        'yearly' => yearly,
        'lifetime' => lifetime,
        _ => monthly,
      };
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.label,
    required this.note,
    required this.icon,
    this.ready = false,
  });

  final String id;
  final String label;
  final String note;
  final IconData icon;

  /// true bila bisa dipakai sekarang; false = butuh integrasi PSP dulu.
  final bool ready;
}

class SubscriptionCatalog {
  SubscriptionCatalog._();

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'monthly',
      title: 'Bulanan',
      subtitle: 'Fleksibel, berhenti kapan saja.',
      months: 1,
    ),
    SubscriptionPlan(
      id: 'yearly',
      title: 'Tahunan',
      subtitle: 'Paling hemat untuk setahun.',
      months: 12,
      badge: 'HEMAT',
    ),
    SubscriptionPlan(
      id: 'lifetime',
      title: 'Lifetime',
      subtitle: 'Bayar sekali, pakai selamanya.',
      months: 1200,
      lifetime: true,
      badge: 'TERBAIK',
    ),
  ];

  /// Fase 1 murah (peluncuran) -> fase berikut naik seiring waktu.
  static final List<PricePhase> phases = [
    PricePhase(
      name: 'Peluncuran',
      effectiveFrom: DateTime(2026, 1, 1),
      monthly: 15000,
      yearly: 129000,
      lifetime: 299000,
    ),
    PricePhase(
      name: 'Pertumbuhan',
      effectiveFrom: DateTime(2027, 1, 1),
      monthly: 29000,
      yearly: 249000,
      lifetime: 499000,
    ),
    PricePhase(
      name: 'Mapan',
      effectiveFrom: DateTime(2027, 7, 1),
      monthly: 49000,
      yearly: 399000,
      lifetime: 799000,
    ),
  ];

  static PricePhase activePhase([DateTime? now]) {
    final ref = now ?? DateTime.now();
    var active = phases.first;
    for (final p in phases) {
      if (!p.effectiveFrom.isAfter(ref)) active = p;
    }
    return active;
  }

  static String rupiah(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rev = s.length - i;
      buf.write(s[i]);
      if (rev > 1 && rev % 3 == 1) buf.write('.');
    }
    return 'Rp$buf';
  }

  static const List<PaymentMethod> methods = [
    PaymentMethod(
      id: 'play',
      label: 'Google Play',
      note: 'Wajib untuk versi Play Store.',
      icon: Icons.play_arrow_rounded,
    ),
    PaymentMethod(
      id: 'qris',
      label: 'QRIS',
      note: 'Semua e-wallet & m-banking. Segera hadir.',
      icon: Icons.qr_code_rounded,
    ),
    PaymentMethod(
      id: 'bank',
      label: 'Transfer bank',
      note: 'BCA, BRI, Mandiri, dll. Segera hadir.',
      icon: Icons.account_balance_rounded,
    ),
    PaymentMethod(
      id: 'ewallet',
      label: 'E-wallet',
      note: 'GoPay, OVO, DANA. Segera hadir.',
      icon: Icons.wallet_rounded,
    ),
    PaymentMethod(
      id: 'card',
      label: 'Kartu kredit/debit',
      note: 'Visa, Mastercard. Segera hadir.',
      icon: Icons.credit_card_rounded,
    ),
    PaymentMethod(
      id: 'crypto',
      label: 'Crypto',
      note: 'BTC, ETH, USDT. Segera hadir.',
      icon: Icons.currency_bitcoin_rounded,
    ),
  ];
}
