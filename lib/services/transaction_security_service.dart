class TransactionSecurityService {
  static const allowedHosts = <String>{
    'checkout.xendit.co',
    'checkout-staging.xendit.co',
    'payments.nowpayments.io',
  };

  static SecurityCheck validateCheckoutUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https' || uri.host.isEmpty) {
      return const SecurityCheck(false, 'Checkout ditolak: URL transaksi harus HTTPS.');
    }
    if (!allowedHosts.contains(uri.host)) {
      return SecurityCheck(false, 'Checkout ditolak: domain pembayaran tidak masuk allowlist aplikasi.');
    }
    return const SecurityCheck(true, 'Checkout domain tervalidasi.');
  }
}

class SecurityCheck {
  const SecurityCheck(this.allowed, this.message);
  final bool allowed;
  final String message;
}
