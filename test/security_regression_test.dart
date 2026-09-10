import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/config/app_config.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/core/reviews/service_review.dart';
import 'package:hojuzatcom/core/security/payment_uri_policy.dart';
import 'package:hojuzatcom/core/storage/secure_session_store.dart';
import 'package:hojuzatcom/features/auth/data/auth_repository.dart';
import 'package:hojuzatcom/features/auth/domain/auth_input_policy.dart';
import 'package:hojuzatcom/features/auth/presentation/app_session.dart';
import 'package:hojuzatcom/features/auth/presentation/forgot_password_screen.dart';
import 'package:hojuzatcom/features/catalog/data/control_panel_repository.dart';
import 'package:hojuzatcom/features/payments/domain/payment.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('نسخة الإنتاج ترفض عنوان API محلياً غير مشفر', () {
    expect(
      () => AppConfig.parseApiBaseUri(
        'http://10.0.2.2:8080',
        allowLocalHttp: false,
      ),
      throwsFormatException,
    );
    expect(
      AppConfig.parseApiBaseUri(
        'http://10.0.2.2:8080',
        allowLocalHttp: true,
      )?.host,
      '10.0.2.2',
    );
  });

  test('سياسة إدخال المصادقة موحدة للهاتف وكلمة المرور', () {
    expect(
      AuthInputPolicy.normalizePhone('(+967) 700-000-000'),
      '+967700000000',
    );
    expect(AuthInputPolicy.isValidPhone('+967700000000'), isTrue);
    expect(AuthInputPolicy.isValidPhone('700 abc'), isFalse);
    expect(AuthInputPolicy.isValidPassword('1234567'), isFalse);
    expect(AuthInputPolicy.isValidPassword('12345678'), isTrue);
    expect(
      AuthInputPolicy.isValidPassword(List.filled(129, 'x').join()),
      isFalse,
    );
  });

  test('سجل الدفع يستخدم معرفات موحدة غير مكررة', () {
    final methods = localControlPanelRepository.paymentMethods;
    final ids = methods.map((item) => item.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(
      ids,
      containsAll(['jawali', 'jeeb', 'floosk', 'onecash', 'alkuraimi']),
    );
    expect(ids, isNot(contains('floosak')));
    expect(ids, isNot(contains('alkurimi_mobile')));
  });

  test('سياسة الدفع تقبل النطاق والمحفظة المعتمدين فقط', () {
    final payment = PaymentIntent(
      id: 'payment-1',
      bookingId: 'booking-1',
      status: PaymentStatus.requiresAction,
      amount: 1000,
      currency: 'YER',
      checkoutUrl: Uri.parse('https://pay.example.com/checkout/1'),
      deepLink: Uri.parse('jeeb://pay/1'),
    );

    expect(
      PaymentUriPolicy.selectTrustedUri(
        payment,
        paymentMethodId: 'jeeb',
        allowedCheckoutHosts: const {'pay.example.com'},
      ),
      Uri.parse('jeeb://pay/1'),
    );
    expect(
      PaymentUriPolicy.selectTrustedUri(
        payment,
        paymentMethodId: 'onecash',
        allowedCheckoutHosts: const {},
      ),
      isNull,
    );
    expect(
      PaymentUriPolicy.isTrustedCheckoutUrl(
        Uri.parse('https://user@pay.example.com/checkout/1'),
        allowedCheckoutHosts: const {'pay.example.com'},
      ),
      isFalse,
    );
  });

  testWidgets('استعادة كلمة المرور لا تكشف أن الرقم غير مسجل', (tester) async {
    final repository = RemoteAuthRepository(
      ApiClient(
        baseUri: Uri.parse('https://api.example.com/v1'),
        httpClient: MockClient(
          (_) async => http.Response(
            '{"message":"Phone is not registered"}',
            404,
            headers: const {'content-type': 'application/json'},
          ),
        ),
      ),
      _MemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordScreen(repository: repository, isEnglish: true),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '700000000');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    expect(find.text('Phone is not registered'), findsNothing);
    expect(
      find.text('If the number is registered, a reset code will be sent.'),
      findsOneWidget,
    );
    expect(find.text('Reset code'), findsOneWidget);
  });

  test('ترحيل التقييم يخفي رقم الهاتف من مفاتيح التخزين المحلي', () async {
    SharedPreferences.setMockInitialValues({
      'service_used_700000000_hotels': true,
      'service_review_pending_700000000_hotels': true,
    });
    AppSession.currentUserIdentity = '700000000';
    final store = ServiceReviewStore();

    expect(await store.hasPendingReview('hotels'), isTrue);

    final keys = (await SharedPreferences.getInstance()).getKeys();
    expect(keys.any((key) => key.contains('700000000')), isFalse);
    expect(keys.any((key) => key.startsWith('service_used_')), isTrue);
  });
}

class _MemorySessionStore implements SecureSessionStore {
  SessionTokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<SessionTokens?> read() async => tokens;

  @override
  Future<void> write(SessionTokens tokens) async => this.tokens = tokens;
}
