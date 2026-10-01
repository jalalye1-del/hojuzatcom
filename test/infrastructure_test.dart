import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/documents/invoice_pdf_service.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/core/network/api_exception.dart';
import 'package:hojuzatcom/core/storage/secure_session_store.dart';
import 'package:hojuzatcom/features/auth/data/auth_repository.dart';
import 'package:hojuzatcom/features/auth/domain/auth_models.dart';
import 'package:hojuzatcom/features/bookings/data/booking_repository.dart';
import 'package:hojuzatcom/features/bookings/domain/booking.dart';
import 'package:hojuzatcom/features/delivery/presentation/delivery_basket.dart';
import 'package:hojuzatcom/features/notifications/data/push_token_repository.dart';
import 'package:hojuzatcom/features/payments/data/payment_repository.dart';
import 'package:hojuzatcom/features/payments/domain/payment.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient', () {
    test('يرسل رمز الجلسة ويفك استجابة JSON', () async {
      final transport = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.com/v1/bookings?status=pending',
        );
        expect(request.headers['Authorization'], 'Bearer secure-token');
        return _jsonResponse({
          'data': {'ok': true},
        }, 200);
      });
      final client = ApiClient(
        baseUri: Uri.parse('https://api.example.com/v1'),
        httpClient: transport,
        accessTokenProvider: () async => 'secure-token',
      );

      final result = await client.get('bookings', query: {'status': 'pending'});

      expect(result, {
        'data': {'ok': true},
      });
    });

    test('يحوّل أخطاء الخادم إلى خطأ موحد', () async {
      final client = ApiClient(
        baseUri: Uri.parse('https://api.example.com/v1'),
        accessTokenProvider: () async => 'secure-token',
        httpClient: MockClient(
          (_) async => _jsonResponse({
            'code': 'invalid_booking',
            'message': 'بيانات غير صالحة',
          }, 422),
        ),
      );

      await expectLater(
        client.post('bookings', body: const {}),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.code, 'code', 'invalid_booking'),
        ),
      );
    });

    test('يرفض الطلب المحمي عند غياب رمز الجلسة', () async {
      var sent = false;
      final client = ApiClient(
        baseUri: Uri.parse('https://api.example.com/v1'),
        httpClient: MockClient((_) async {
          sent = true;
          return _jsonResponse(const {}, 200);
        }),
      );

      await expectLater(
        client.get('bookings'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having((error) => error.code, 'code', 'missing_access_token'),
        ),
      );
      expect(sent, isFalse);
    });
  });

  test('المصادقة تحفظ الرموز في مخزن الجلسة', () async {
    final store = _MemorySessionStore();
    final api = ApiClient(
      baseUri: Uri.parse('https://api.example.com/v1'),
      accessTokenProvider: () async => 'secure-token',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/auth/login');
        expect(jsonDecode(request.body), {
          'phone': '700000000',
          'password': 'secret12',
        });
        return _jsonResponse({
          'data': {
            'user': {'id': 'u1', 'name': 'محمد', 'phone': '700000000'},
            'tokens': {
              'access_token': 'access',
              'refresh_token': 'refresh',
              'expires_in': 3600,
            },
          },
        }, 200);
      }),
    );
    final repository = RemoteAuthRepository(api, store);

    final session = await repository.login(
      const LoginRequest(phone: '700000000', password: 'secret12'),
    );

    expect(session.user.id, 'u1');
    expect(repository.authenticatedUserId, 'u1');
    expect(store.tokens?.accessToken, 'access');
    expect(store.tokens?.refreshToken, 'refresh');
  });

  test('restored account identity is cleared even when logout fails', () async {
    final store = _MemorySessionStore();
    await store.write(SessionTokens(accessToken: 'access'));
    final api = ApiClient(
      baseUri: Uri.parse('https://api.example.com/v1'),
      accessTokenProvider: () async => store.tokens?.accessToken,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          return _jsonResponse({
            'data': {
              'id': 'restored-user',
              'name': 'Test User',
              'phone': '700000000',
            },
          }, 200);
        }
        return _jsonResponse({'message': 'Unavailable'}, 503);
      }),
    );
    final repository = RemoteAuthRepository(api, store);
    expect(repository.authenticatedUserId, isNull);
    await repository.restoreSession();
    expect(repository.authenticatedUserId, 'restored-user');
    await expectLater(repository.logout(), throwsA(isA<ApiException>()));
    expect(repository.authenticatedUserId, isNull);
    expect(store.tokens, isNull);
    expect(await repository.restoreSession(), isNull);
  });

  test('مستودع الحجوزات يحوّل مسودة الحجز والاستجابة', () async {
    final api = ApiClient(
      baseUri: Uri.parse('https://api.example.com/v1'),
      accessTokenProvider: () async => 'secure-token',
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['provider_id'], 'hotel-1');
        expect(body['total'], 15000);
        return _jsonResponse({
          'data': {
            'id': 'booking-1',
            'provider_id': 'hotel-1',
            'service_id': 'hotels',
            'status': 'confirmed',
            'total': 15000,
            'currency': 'YER',
            'created_at': '2026-08-25T12:00:00Z',
            'metadata': {'room': 'suite'},
          },
        }, 201);
      }),
    );

    final booking = await RemoteBookingRepository(api).create(
      const BookingDraft(
        providerId: 'hotel-1',
        serviceId: 'hotels',
        total: 15000,
        currency: 'YER',
      ),
    );

    expect(booking.id, 'booking-1');
    expect(booking.status, BookingStatus.confirmed);
  });

  test('مستودع الدفع يعيد رابط التحويل فقط دون بيانات بطاقة', () async {
    final api = ApiClient(
      baseUri: Uri.parse('https://api.example.com/v1'),
      accessTokenProvider: () async => 'secure-token',
      httpClient: MockClient((request) async {
        expect(jsonDecode(request.body), {
          'booking_id': 'booking-1',
          'method_id': 'wallet-jeeb',
        });
        return _jsonResponse({
          'data': {
            'id': 'payment-1',
            'booking_id': 'booking-1',
            'status': 'requires_action',
            'amount': 15000,
            'currency': 'YER',
            'checkout_url': 'https://pay.example.com/p/payment-1',
          },
        }, 201);
      }),
    );

    final payment = await RemotePaymentRepository(api).createIntent(
      const PaymentRequest(bookingId: 'booking-1', methodId: 'wallet-jeeb'),
    );

    expect(payment.status, PaymentStatus.requiresAction);
    expect(payment.checkoutUrl?.host, 'pay.example.com');
  });

  test('مستودع الإشعارات يسجل رمز Firebase في الخادم', () async {
    const firebaseToken = 'firebase-device-token-1234567890';
    final api = ApiClient(
      baseUri: Uri.parse('https://api.example.com/v1'),
      accessTokenProvider: () async => 'secure-token',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/push-tokens');
        expect(jsonDecode(request.body), {
          'token': firebaseToken,
          'platform': 'android',
        });
        return _jsonResponse({
          'data': {
            'push_token': {'id': 'push-token-1', 'platform': 'android'},
          },
        }, 201);
      }),
    );

    final id = await RemotePushTokenRepository(
      api,
    ).register(token: firebaseToken, platform: 'android');

    expect(id, 'push-token-1');
  });

  test('مستودع الإشعارات يعطل رمز الجهاز عند تسجيل الخروج', () async {
    final api = ApiClient(
      baseUri: Uri.parse('https://api.example.com/v1'),
      accessTokenProvider: () async => 'secure-token',
      httpClient: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/v1/push-tokens/push-token-1');
        return _jsonResponse({'message': 'تم إيقاف الإشعارات.'}, 200);
      }),
    );

    await RemotePushTokenRepository(api).disable('push-token-1');
  });

  test('سلة التوصيل تجمع الكميات وتحسب الإجمالي', () {
    final basket = DeliveryBasket();
    basket.add(
      DeliveryCartItem(
        id: 'item-1',
        name: 'ماء',
        category: 'بقالة',
        unitPrice: 500,
      ),
    );
    basket.add(
      DeliveryCartItem(
        id: 'item-1',
        name: 'ماء',
        category: 'بقالة',
        unitPrice: 500,
        quantity: 2,
      ),
    );

    expect(basket.items.single.quantity, 3);
    expect(basket.subtotal, 1500);
    expect(basket.total, 2100);
  });

  test('خدمة الفاتورة تنشئ ملف PDF حقيقياً', () async {
    final bytes = await InvoicePdfService.build(
      title: 'فاتورة الحجز',
      reference: 'INV-2026-001',
      details: const [('الخدمة', 'شقة مفروشة'), ('الإجمالي', '25,000 ر.ي')],
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}

http.Response _jsonResponse(Object body, int statusCode) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  statusCode,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

class _MemorySessionStore implements SecureSessionStore {
  SessionTokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<SessionTokens?> read() async => tokens;

  @override
  Future<void> write(SessionTokens tokens) async => this.tokens = tokens;
}
