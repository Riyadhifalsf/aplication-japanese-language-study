import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/payment_models.dart';
import '../../services/payment_service.dart';
import '../../state/app_controller.dart';
import '../../services/transaction_security_service.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key, required this.plan});
  final PaymentPlan plan;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final _service = PaymentService();
  String _provider = 'xendit';
  bool _busy = false;
  String? _message;

  static const _fiatMethods = [
    ('QRIS', Icons.qr_code_2_rounded),
    ('Mastercard / Visa', Icons.credit_card_rounded),
    ('GoPay', Icons.account_balance_wallet_rounded),
    ('DANA', Icons.account_balance_wallet_outlined),
    ('Bank Transfer / VA', Icons.account_balance_rounded),
    ('E-wallet lain yang tersedia', Icons.wallet_rounded),
  ];

  static const _cryptoMethods = [
    ('Bitcoin', 'BTC'),
    ('Ethereum', 'ETH'),
    ('USDT', 'USDT'),
    ('USDC', 'USDC'),
    ('Solana', 'SOL'),
  ];

  String _formatIdr(int amount) => 'Rp${amount.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}' ;

  Future<void> _pay() async {
    final app = AppScope.of(context);
    if (!app.paymentsEnabled) {
      setState(() => _message = 'Pembayaran sedang dinonaktifkan oleh admin. Tidak ada transaksi yang dikirim.');
      return;
    }
    if (!app.isAuthenticated || app.profileEmail.trim().isEmpty) {
      setState(() => _message = 'Login diperlukan sebelum checkout supaya order dan hak akses bisa dikaitkan ke akun.');
      return;
    }
    if (!_service.configured) {
      setState(() => _message = 'Payment backend belum dikonfigurasi. Tambahkan --dart-define=PAYMENT_API_URL=https://domain-kamu.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      final checkout = await _service.createCheckout(
        plan: widget.plan,
        userEmail: app.profileEmail.trim(),
        provider: _provider,
      );
      if (checkout == null || checkout.checkoutUrl.isEmpty) {
        throw Exception('URL checkout kosong.');
      }
      final security = TransactionSecurityService.validateCheckoutUrl(checkout.checkoutUrl);
      if (!security.allowed) {
        throw Exception(security.message);
      }
      final launched = await launchUrl(Uri.parse(checkout.checkoutUrl), mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Checkout tidak dapat dibuka oleh perangkat.');
      if (mounted) {
        setState(() => _message = 'Checkout dibuka. Status Premium baru diaktifkan setelah webhook pembayaran tervalidasi.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crypto = _provider == 'nowpayments';
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran aman')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.plan.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(widget.plan.description),
                const SizedBox(height: 12),
                Text(_formatIdr(widget.plan.amountIdr), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text('Harga terkunci pada versi ${widget.plan.priceVersion}. Pembeli lama mempertahankan harga saat pembelian.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'xendit', icon: Icon(Icons.payments_rounded), label: Text('Rupiah')),
              ButtonSegment(value: 'nowpayments', icon: Icon(Icons.currency_bitcoin_rounded), label: Text('Crypto')),
            ],
            selected: {_provider},
            onSelectionChanged: (v) => setState(() => _provider = v.first),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(crypto ? 'Crypto yang diprioritaskan' : 'Channel pembayaran Rupiah', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 10),
                if (!crypto)
                  for (final item in _fiatMethods)
                    ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(item.$2), title: Text(item.$1), trailing: const Icon(Icons.check_circle_outline_rounded)),
                if (crypto)
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final coin in _cryptoMethods) Chip(avatar: const Icon(Icons.currency_exchange_rounded, size: 18), label: Text('${coin.$1} (${coin.$2})'))]),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: .55),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Keamanan: API key, secret webhook, dan kredensial wallet tidak pernah ditaruh di APK. Checkout dibuat di server, lalu akses Premium hanya berubah setelah webhook terverifikasi. Untuk Rupiah, settlement mengikuti rekening bisnis yang kamu daftarkan pada provider. Crypto memakai wallet payout yang kamu daftarkan.', style: TextStyle(fontWeight: FontWeight.w600, height: 1.45)),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(_message!))),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: _busy ? null : _pay, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_rounded), label: Text(_busy ? 'Membuka checkout...' : 'Lanjut ke pembayaran')),
        ],
      ),
    );
  }
}
