import '../../../core/network/json_parsing.dart';

enum PaymentStatus { pending, requiresAction, paid, failed, cancelled }

class PaymentRequest {
  const PaymentRequest({
    required this.bookingId,
    required this.methodId,
    this.returnUrl,
  });

  final String bookingId;
  final String methodId;
  final Uri? returnUrl;

  JsonMap toJson() => {
    'booking_id': bookingId,
    'method_id': methodId,
    if (returnUrl != null) 'return_url': returnUrl.toString(),
  };
}

class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.amount,
    required this.currency,
    this.checkoutUrl,
    this.deepLink,
  });

  final String id;
  final String bookingId;
  final PaymentStatus status;
  final int amount;
  final String currency;
  final Uri? checkoutUrl;
  final Uri? deepLink;

  factory PaymentIntent.fromJson(JsonMap json) => PaymentIntent(
    id: requiredString(json, 'id'),
    bookingId: requiredString(json, 'booking_id'),
    status: _paymentStatus(requiredString(json, 'status')),
    amount: requiredInt(json, 'amount'),
    currency: requiredString(json, 'currency'),
    checkoutUrl: _optionalUri(json, 'checkout_url'),
    deepLink: _optionalUri(json, 'deep_link'),
  );

  static PaymentStatus _paymentStatus(String value) {
    if (value == 'requires_action') return PaymentStatus.requiresAction;
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  static Uri? _optionalUri(JsonMap json, String key) {
    final value = optionalString(json, key);
    return value == null ? null : Uri.tryParse(value);
  }
}
