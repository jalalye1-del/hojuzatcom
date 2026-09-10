import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/features/catalog/data/catalog_repository.dart';
import 'package:hojuzatcom/features/bookings/data/booking_repository.dart';
import 'package:hojuzatcom/features/bookings/domain/booking.dart';
import 'package:hojuzatcom/features/bookings/presentation/provider_booking_flow.dart';
import 'package:hojuzatcom/features/beauty_centers/data/beauty_backend_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/features/beauty_centers/presentation/beauty_center_flow.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    final service = <String, Object?>{
      'id': 'beauty-service',
      'provider_id': 'lavender-sanaa',
      'service_category_id': 'beauty-category',
      'name_ar': 'جلسة عناية مسجلة',
      'service_type': 'beauty',
      'base_price': 12000,
      'currency': 'YER',
      'provider': {
        'id': 'lavender-sanaa',
        'display_name_ar': 'مركز لافندر للتجميل والعناية',
        'province': 'صنعاء',
      },
    };
    http.Response response(Object data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    final api = ApiClient(
      accessTokenProvider: () async => 'test-token',
      baseUri: Uri.parse('https://example.test/api/'),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/availabilities'))
          return response({'data': []});
        if (request.url.path.endsWith('/services'))
          return response({
            'data': [service],
          });
        if (request.url.path.endsWith('/services/beauty-service'))
          return response({'data': service});
        expect(request.url.path, '/api/bookings');
        expect(jsonDecode(request.body)['service_id'], 'beauty-service');
        return response({
          'data': {
            'id': 'server-beauty-booking',
            'provider_id': 'lavender-sanaa',
            'service_id': 'beauty-service',
            'status': 'pending',
            'total': 15000,
            'currency': 'YER',
            'created_at': '2026-09-09T12:00:00Z',
          },
        }, 201);
      }),
    );
    final flow = ProviderBookingFlow(
      catalog: RemoteCatalogRepository(api),
      bookings: RemoteBookingRepository(api),
    );
    ProviderBookingFlow.current = flow;
    configureBeautyBackendBridge(
      profileProvider: () => const BeautyProfileSnapshot(
        name: 'عميل الاختبار',
        phone: '967700000000',
      ),
      targetResolver: (_) async => null,
      bookingCreator: (request) async {
        final booking = await flow.bookings.create(
          BookingDraft(
            providerId: request.target.providerId,
            serviceId: request.target.serviceId,
            total: request.total,
            currency: request.target.currency,
            serviceAvailabilityId: request.serviceAvailabilityId,
            scheduledAt: request.scheduledAt,
          ),
        );
        return BeautyRemoteBooking(
          id: booking.id,
          status: booking.status.name,
          total: booking.total,
          currency: booking.currency,
        );
      },
      paymentMethodsProvider: ({required currency, required amount}) async =>
          [],
      paymentExecutor: (_, __) async {
        fail('Payment must not be called');
      },
    );
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
  });

  tearDown(() => ProviderBookingFlow.current = null);

  testWidgets('بطاقة مراكز التجميل تفتح الواجهة المخصصة', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ServicesScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    final beautyCard = find.byKey(const Key('service-card-مراكز تجميل'));
    await tester.scrollUntilVisible(
      beautyCard,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(beautyCard);
    await tester.pumpAndSettle();
    await tester.tap(beautyCard);
    await tester.pumpAndSettle();

    expect(find.byType(BeautyCenterDiscoveryScreen), findsOneWidget);
    expect(find.byKey(const Key('beauty-search-field')), findsOneWidget);
  });

  testWidgets('مسار مركز التجميل يستخدم بيانات الخادم ويتوقف قبل الدفع', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BeautyCenterDiscoveryScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    final banner = tester.widget<Image>(
      find.byKey(const Key('beauty-main-banner')),
    );
    expect((banner.image as AssetImage).assetName, beautyCenterBannerAsset);

    final firstCenter = find.byKey(const Key('beauty-center-lavender-sanaa'));
    await _scrollToKey(
      tester,
      const Key('beauty-center-lavender-sanaa'),
      const Key('beauty-discovery-list'),
    );
    await tester.tap(firstCenter);
    await tester.pumpAndSettle();
    expect(find.byType(BeautyCenterDetailsScreen), findsOneWidget);
    expect(find.text('مركز لافندر للتجميل والعناية'), findsOneWidget);

    const aboutCardKey = Key('beauty-info-من نحن');
    await _scrollToKey(tester, aboutCardKey, const Key('beauty-detail-list'));
    final aboutCardInk = tester.widget<Ink>(
      find.descendant(of: find.byKey(aboutCardKey), matching: find.byType(Ink)),
    );
    final aboutCardDecoration = aboutCardInk.decoration! as BoxDecoration;
    expect(aboutCardDecoration.boxShadow ?? const <BoxShadow>[], isEmpty);

    await _scrollToKey(
      tester,
      const Key('beauty-open-surgery'),
      const Key('beauty-detail-list'),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('beauty-open-surgery')),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BeautyBookingScreen), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('beauty-booking-continue'),
      const Key('beauty-booking-list'),
    );
    await tester.tap(find.byKey(const Key('beauty-booking-continue')));
    await tester.pumpAndSettle();
    expect(find.text('رقم الحجز: server-beauty-booking'), findsOneWidget);
    expect(find.text('الإجمالي: 15000 YER'), findsOneWidget);
    expect(find.textContaining('بانتظار موافقة مقدم الخدمة'), findsOneWidget);
    expect(find.byType(BeautyPaymentScreen), findsNothing);
    expect(find.byType(BeautyBookingSuccessScreen), findsNothing);
    expect(find.text('BC-2026-000318'), findsNothing);
  });
}

Future<void> _scrollToKey(
  WidgetTester tester,
  Key targetKey,
  Key listKey,
) async {
  final target = find.byKey(targetKey);
  final list = find.byKey(listKey);
  final scrollable = find
      .descendant(of: list, matching: find.byType(Scrollable))
      .first;
  final state = tester.state<ScrollableState>(scrollable);
  for (var attempt = 0; attempt < 35; attempt++) {
    final elements = target.evaluate();
    final renderObject = elements.isEmpty ? null : elements.first.renderObject;
    if (renderObject is RenderBox && renderObject.attached) {
      final position = renderObject.localToGlobal(Offset.zero);
      if (position.dy >= 115 && position.dy <= 650) break;
    }
    final position = state.position;
    final next = (position.pixels + 220).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.jumpTo(next);
    await tester.pump(const Duration(milliseconds: 60));
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}
