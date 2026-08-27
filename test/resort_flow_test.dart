import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
  });

  testWidgets('بطاقة المنتجعات تفتح واجهة المنتجعات المخصصة', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ServicesScreen(province: 'عدن')),
    );
    await tester.pumpAndSettle();

    final resortsCard = find.byKey(const Key('service-card-منتجعات'));
    await tester.scrollUntilVisible(
      resortsCard,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(resortsCard);
    await tester.pumpAndSettle();
    await tester.tap(resortsCard);
    await tester.pumpAndSettle();

    expect(find.byType(ResortDiscoveryScreen), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'ابحث عن منتجع أو مدينة'),
      findsOneWidget,
    );
  });

  testWidgets('مسار المنتجع يعمل من الاستكشاف حتى الدفع والتقييم', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ResortDiscoveryScreen(province: 'عدن')),
    );
    await tester.pumpAndSettle();

    final usesResortBanner = tester.widgetList<Image>(find.byType(Image)).any((
      image,
    ) {
      final provider = image.image;
      return provider is AssetImage &&
          provider.assetName == 'assets/images/resort_booking_banner.png';
    });
    expect(usesResortBanner, isTrue);
    final firstResort = find.text('منتجع لاجون عدن');
    await _scrollTo(tester, firstResort, const Key('retreat-discovery-list'));
    expect(find.text('منتجع لاجون عدن'), findsOneWidget);
    await tester.tap(firstResort);
    await tester.pumpAndSettle();
    expect(find.text('الموقع على الخارطة'), findsOneWidget);

    final gallery = find.textContaining('معرض الصور والفيديو');
    await _scrollTo(tester, gallery, const Key('retreat-detail-list'));
    expect(gallery, findsOneWidget);

    final bookNow = find.text('احجز الآن');
    await _scrollTo(tester, bookNow, const Key('retreat-detail-list'));
    await tester.tap(bookNow);
    await tester.pumpAndSettle();
    expect(find.textContaining('اختر تاريخ الوصول والمغادرة'), findsOneWidget);

    final continueToPayment = find.text('متابعة إلى الدفع');
    await _scrollTo(
      tester,
      continueToPayment,
      const Key('retreat-booking-list'),
    );
    await tester.tap(continueToPayment);
    await tester.pumpAndSettle();
    expect(find.textContaining('اختر طريقة الدفع'), findsOneWidget);

    final payNow = find.textContaining('ادفع الآن ·');
    await _scrollTo(tester, payNow, const Key('retreat-payment-list'));
    await tester.tap(payNow);
    await tester.pumpAndSettle();
    expect(find.text('تم تأكيد الحجز بنجاح'), findsOneWidget);
    expect(find.text('RS-2026-000245'), findsOneWidget);

    final rateResort = find.text('تقييم الخدمة');
    await _scrollTo(tester, rateResort, const Key('retreat-success-list'));
    await tester.tap(rateResort);
    await tester.pumpAndSettle();
    expect(find.text('كيف كانت إقامتك؟'), findsOneWidget);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder target, Key listKey) async {
  final list = find.byKey(listKey);
  final scrollable = find
      .descendant(of: list, matching: find.byType(Scrollable))
      .first;
  final state = tester.state<ScrollableState>(scrollable);
  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    final position = state.position;
    final next = (position.pixels + 220).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.jumpTo(next);
    await tester.pump(const Duration(milliseconds: 80));
  }
  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await tester.pumpAndSettle();
}
