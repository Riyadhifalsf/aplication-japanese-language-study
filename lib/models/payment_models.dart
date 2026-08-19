class PaymentPlan {
  const PaymentPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.amountIdr,
    required this.intervalLabel,
    required this.priceVersion,
    required this.features,
  });

  final String id;
  final String title;
  final String description;
  final int amountIdr;
  final String intervalLabel;
  final int priceVersion;
  final List<String> features;
}

class PaymentCheckout {
  const PaymentCheckout({
    required this.orderId,
    required this.checkoutUrl,
    required this.provider,
    required this.status,
  });

  final String orderId;
  final String checkoutUrl;
  final String provider;
  final String status;
}
