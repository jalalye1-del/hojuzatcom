import '../../../core/network/json_parsing.dart';

enum PaymentStatus { pending, requiresAction, paid, failed, cancelled }

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.code,
    required this.nameAr,
    required this.type,
    required this.flowType,
    required this.defaultCurrency,
    required this.supportedCurrencies,
    required this.feeType,
    required this.feeValue,
    required this.feeBearer,
    required this.supportsRefunds,
    required this.supportsRedirect,
    required this.supportsDeepLink,
    this.nameEn,
    this.logoUrl,
    this.minimumAmount,
    this.maximumAmount,
  });

  final String code;
  final String nameAr;
  final String? nameEn;
  final String type;
  final String flowType;
  final Uri? logoUrl;
  final String defaultCurrency;
  final List<String> supportedCurrencies;
  final int? minimumAmount;
  final int? maximumAmount;
  final String feeType;
  final double feeValue;
  final String feeBearer;
  final bool supportsRefunds;
  final bool supportsRedirect;
  final bool supportsDeepLink;

  factory PaymentMethodOption.fromJson(JsonMap json) {
    final currencies = json['supported_currencies'];

    return PaymentMethodOption(
      code: requiredString(json, 'code'),
      nameAr: requiredString(json, 'name_ar'),
      nameEn: optionalString(json, 'name_en'),
      type: requiredString(json, 'type'),
      flowType: requiredString(json, 'flow_type'),
      logoUrl: _optionalUri(json, 'logo_url'),
      defaultCurrency: requiredString(json, 'default_currency'),
      supportedCurrencies: currencies is List
          ? currencies
                .map((value) => value.toString().trim().toUpperCase())
                .where((value) => value.isNotEmpty)
                .toList(growable: false)
          : const [],
      minimumAmount: _optionalInt(json['minimum_amount']),
      maximumAmount: _optionalInt(json['maximum_amount']),
      feeType: requiredString(json, 'fee_type'),
      feeValue: _doubleValue(json['fee_value']),
      feeBearer: requiredString(json, 'fee_bearer'),
      supportsRefunds: _boolValue(json['supports_refunds']),
      supportsRedirect: _boolValue(json['supports_redirect']),
      supportsDeepLink: _boolValue(json['supports_deep_link']),
    );
  }

  static Uri? _optionalUri(JsonMap json, String key) {
    final value = optionalString(json, key);
    return value == null ? null : Uri.tryParse(value);
  }

  static int? _optionalInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().trim().toLowerCase();

    return normalized == 'true' || normalized == '1';
  }
}

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
