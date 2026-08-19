import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/payment_models.dart';

class PaymentService {
  PaymentService({http.Client? client, this.baseUrl = const String.fromEnvironment('PAYMENT_API_URL')})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  bool get configured => baseUrl.trim().isNotEmpty;

  Future<PaymentCheckout?> createCheckout({
    required PaymentPlan plan,
    required String userEmail,
    required String provider,
  }) async {
    if (!configured) return null;
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/v1/payments/checkout');
    final response = await _client.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'plan_id': plan.id,
        'price_version': plan.priceVersion,
        'amount': plan.amountIdr,
        'currency': 'IDR',
        'user_email': userEmail,
        'provider': provider,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Checkout gagal (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentCheckout(
      orderId: '${data['order_id'] ?? ''}',
      checkoutUrl: '${data['checkout_url'] ?? ''}',
      provider: '${data['provider'] ?? provider}',
      status: '${data['status'] ?? 'created'}',
    );
  }
}
