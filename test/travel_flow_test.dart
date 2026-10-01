import 'sector_backend_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/features/travel/domain/travel_models.dart';
import 'package:hojuzatcom/features/travel/presentation/travel_flow.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
  });

  testWidgets('بطاقة سفريات وسياحة تفتح الواجهة المخصصة', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ServicesScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    final travelCard = find.byKey(const Key('service-card-سفريات وسياحة'));
    await tester.scrollUntilVisible(
      travelCard,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(travelCard);
    await tester.pumpAndSettle();
    await tester.tap(travelCard);
    await tester.pumpAndSettle();

    expect(find.byType(TravelDiscoveryScreen), findsOneWidget);
    expect(find.byKey(const Key('travel-search-field')), findsOneWidget);
  });

  testWidgets('واجهة السفر تعرض البنر ومكاتب السفريات دون تصنيفات مكررة', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TravelDiscoveryScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    final banner = tester.widget<Image>(
      find.byKey(const Key('travel-main-banner')),
    );
    expect((banner.image as AssetImage).assetName, travelBannerAsset);
    expect(find.text('التصنيفات'), findsNothing);
    await _scrollToKey(
      tester,
      const Key('travel-listing-sanaa-dubai-flight'),
      const Key('travel-discovery-list'),
    );
    expect(
      find.byKey(const Key('travel-listing-sanaa-dubai-flight')),
      findsOneWidget,
    );
  });

  testWidgets('مسار الطيران يرسل بيانات المسافر ويعرض رقم الحجز الخادمي', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TravelDiscoveryScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    const listingKey = Key('travel-listing-sanaa-dubai-flight');
    await _scrollToKey(tester, listingKey, const Key('travel-discovery-list'));
    await tester.tap(find.byKey(listingKey));
    await tester.pumpAndSettle();
    expect(find.byType(TravelDetailsScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('travel-start-request')));
    await tester.pumpAndSettle();
    expect(find.byType(TravelRequestScreen), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('travel-request-continue'),
      const Key('travel-request-list'),
    );
    await tester.tap(find.byKey(const Key('travel-request-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(TravelApplicantScreen), findsOneWidget);

    await _enterField(
      tester,
      const Key('travel-applicant-name'),
      'أحمد محمد علي',
    );
    await _enterField(
      tester,
      const Key('travel-applicant-phone'),
      '967700000000',
    );
    await _enterField(
      tester,
      const Key('travel-applicant-document'),
      '01024578',
    );
    await _scrollToKey(
      tester,
      const Key('travel-applicant-continue'),
      const Key('travel-applicant-list'),
    );
    await tester.tap(find.byKey(const Key('travel-applicant-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(TravelPaymentScreen), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('travel-pay-button'),
      const Key('travel-payment-list'),
    );
    final payment = tester.widget<TravelPaymentScreen>(
      find.byType(TravelPaymentScreen),
    );
    final backend = SectorBackendFixture(
      services: [
        SectorBackendFixture.service(
          id: payment.listing.id,
          name: payment.listing.title,
          type: 'flight_ticket',
          province: 'صنعاء',
          price: payment.subtotal,
        ),
      ],
      total: payment.subtotal,
    );
    await tester.tap(find.byKey(const Key('travel-pay-button')));
    await tester.pumpAndSettle();
    expect(find.text('تم إرسال طلب الحجز'), findsOneWidget);
    expect(find.text('رقم الحجز: server-booking'), findsOneWidget);
    expect(backend.requests, hasLength(1));
    expect(backend.requests.single['service_id'], payment.listing.id);
    expect(
      backend.requests.single['metadata']['applicant']['name'],
      'أحمد محمد علي',
    );
    expect(
      backend.requests.single['metadata']['applicant']['document_number'],
      '01024578',
    );
    expect(
      find.text('الإجمالي المعتمد: ${payment.subtotal} YER'),
      findsOneWidget,
    );
    expect(find.text('FL-2026-000512'), findsNothing);
  });

  testWidgets('نموذج الطلب يتكيف مع الفيز السياحية والعمل والمعاملات', (
    tester,
  ) async {
    final tourist = travelListings.firstWhere(
      (item) => item.category == TravelCategory.touristVisa,
    );
    await tester.pumpWidget(
      MaterialApp(home: TravelRequestScreen(listing: tourist)),
    );
    await tester.pumpAndSettle();
    await _scrollToKey(
      tester,
      const Key('travel-tourist-nationality'),
      const Key('travel-request-list'),
    );
    expect(find.text('جنسية مقدم الطلب'), findsOneWidget);
    expect(find.text('مدة التأشيرة'), findsOneWidget);

    final work = travelListings.firstWhere(
      (item) => item.category == TravelCategory.workVisa,
    );
    await tester.pumpWidget(
      MaterialApp(home: TravelRequestScreen(listing: work)),
    );
    await tester.pumpAndSettle();
    await _scrollToKey(
      tester,
      const Key('travel-work-profession'),
      const Key('travel-request-list'),
    );
    expect(find.text('المهنة المطلوبة'), findsOneWidget);
    expect(find.text('اسم جهة العمل أو الكفيل'), findsOneWidget);

    final administrative = travelListings.firstWhere(
      (item) => item.category == TravelCategory.administrative,
    );
    await tester.pumpWidget(
      MaterialApp(home: TravelRequestScreen(listing: administrative)),
    );
    await tester.pumpAndSettle();
    await _scrollToKey(
      tester,
      const Key('travel-admin-urgency'),
      const Key('travel-request-list'),
    );
    expect(find.text('الجهة المختصة'), findsOneWidget);
    expect(find.text('سرعة الإنجاز'), findsOneWidget);
    expect(find.text('عدد المعاملات أو الوثائق'), findsOneWidget);
  });
}

Future<void> _enterField(WidgetTester tester, Key key, String value) async {
  final section = find.byKey(key);
  await tester.ensureVisible(section);
  await tester.pumpAndSettle();
  final field = find.descendant(
    of: section,
    matching: find.byType(TextFormField),
  );
  await tester.enterText(field, value);
  await tester.pump();
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
  for (var attempt = 0; attempt < 45; attempt++) {
    final elements = target.evaluate();
    final renderObject = elements.isEmpty ? null : elements.first.renderObject;
    if (renderObject is RenderBox && renderObject.attached) {
      final position = renderObject.localToGlobal(Offset.zero);
      if (position.dy >= 110 && position.dy <= 650) break;
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
