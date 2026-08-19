import '../models/payment_models.dart';

class PricingService {
  static const int currentPriceVersion = 4;

  static const premium = PaymentPlan(
    id: 'premium_monthly',
    title: 'Premium',
    description: 'Akses seluruh jalur belajar dan fitur premium selama masa aktif.',
    amountIdr: 79000,
    intervalLabel: 'per bulan',
    priceVersion: currentPriceVersion,
    features: ['N5–N1', 'Adaptive learning', 'Review kanji', 'JLPT/JFT simulator', 'Web3 Passport'],
  );

  static const lifetime = PaymentPlan(
    id: 'lifetime',
    title: 'Lifetime',
    description: 'Sekali bayar untuk akses seumur hidup pada fitur yang termasuk dalam pembelian.',
    amountIdr: 799000,
    intervalLabel: 'sekali bayar',
    priceVersion: currentPriceVersion,
    features: ['Semua Premium', 'Tidak kedaluwarsa', 'Harga versi pembelian terkunci'],
  );
}
