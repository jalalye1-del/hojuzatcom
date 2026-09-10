import '../../../core/network/api_client.dart';
import '../../../core/network/json_parsing.dart';
import '../domain/payment.dart';

abstract interface class PaymentRepository {
  Future<List<PaymentMethodOption>> listPaymentMethods({
    String? currency,
    int? amount,
  });

  Future<PaymentIntent> createIntent(PaymentRequest request);

  Future<PaymentIntent> getStatus(String paymentId);

  Future<PaymentIntent> cancel(String paymentId);
}

class RemotePaymentRepository implements PaymentRepository {
  RemotePaymentRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<PaymentMethodOption>> listPaymentMethods({
    String? currency,
    int? amount,
  }) async {
    final normalizedCurrency = currency?.trim().toUpperCase();

    final query = <String, Object?>{};

    if (normalizedCurrency != null && normalizedCurrency.isNotEmpty) {
      query['currency'] = normalizedCurrency;
    }

    if (amount != null) {
      query['amount'] = amount;
    }

    final response = await _api.get('payment-methods', query: query);

    final data = unwrapApiData(response);

    if (data is! List) {
      throw const FormatException('Expected payment methods list.');
    }

    return data
        .map(
          (item) => PaymentMethodOption.fromJson(
            expectJsonMap(item, context: 'payment method'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<PaymentIntent> createIntent(PaymentRequest request) {
    _validateId(request.bookingId, 'bookingId');
    _validateId(request.methodId, 'methodId');

    return _intentFrom(_api.post('payments/intents', body: request.toJson()));
  }

  @override
  Future<PaymentIntent> getStatus(String paymentId) {
    _validateId(paymentId, 'paymentId');

    return _intentFrom(_api.get('payments/${Uri.encodeComponent(paymentId)}'));
  }

  @override
  Future<PaymentIntent> cancel(String paymentId) {
    _validateId(paymentId, 'paymentId');

    return _intentFrom(
      _api.post('payments/${Uri.encodeComponent(paymentId)}/cancel'),
    );
  }

  Future<PaymentIntent> _intentFrom(Future<Object?> request) async =>
      PaymentIntent.fromJson(
        expectJsonMap(unwrapApiData(await request), context: 'payment intent'),
      );

  void _validateId(String value, String name) {
    if (value.trim().isEmpty || value.length > 128) {
      throw ArgumentError.value(value, name, 'Invalid identifier.');
    }
  }
}
