import '../../../core/network/api_client.dart';
import '../../../core/network/json_parsing.dart';
import '../domain/payment.dart';

abstract interface class PaymentRepository {
  Future<PaymentIntent> createIntent(PaymentRequest request);
  Future<PaymentIntent> getStatus(String paymentId);
  Future<PaymentIntent> cancel(String paymentId);
}

class RemotePaymentRepository implements PaymentRepository {
  RemotePaymentRepository(this._api);

  final ApiClient _api;

  @override
  Future<PaymentIntent> createIntent(PaymentRequest request) =>
      _intentFrom(_api.post('payments/intents', body: request.toJson()));

  @override
  Future<PaymentIntent> getStatus(String paymentId) =>
      _intentFrom(_api.get('payments/${Uri.encodeComponent(paymentId)}'));

  @override
  Future<PaymentIntent> cancel(String paymentId) => _intentFrom(
    _api.post('payments/${Uri.encodeComponent(paymentId)}/cancel'),
  );

  Future<PaymentIntent> _intentFrom(Future<Object?> request) async =>
      PaymentIntent.fromJson(
        expectJsonMap(unwrapApiData(await request), context: 'payment intent'),
      );
}
