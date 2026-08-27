import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/features/beauty_centers/presentation/beauty_center_flow.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
  });

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

  testWidgets('مسار مركز التجميل يعمل من الاستكشاف حتى التقييم', (
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

    await tester.tap(find.byKey(const Key('beauty-book-now')));
    await tester.pumpAndSettle();
    expect(find.byType(BeautyBookingScreen), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('beauty-booking-continue'),
      const Key('beauty-booking-list'),
    );
    await tester.tap(find.byKey(const Key('beauty-booking-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(BeautyPaymentScreen), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('beauty-pay-button'),
      const Key('beauty-payment-list'),
    );
    await tester.tap(find.byKey(const Key('beauty-pay-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BeautyBookingSuccessScreen), findsOneWidget);
    expect(find.text('تم حجز موعدك بنجاح'), findsOneWidget);
    expect(find.text('BC-2026-000318'), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('beauty-show-invoice'),
      const Key('beauty-success-list'),
    );
    await tester.tap(find.byKey(const Key('beauty-show-invoice')));
    await tester.pumpAndSettle();
    expect(find.byType(BeautyInvoiceScreen), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('beauty-invoice-code'),
      const Key('beauty-invoice-list'),
    );
    expect(find.text('BC20458'), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('beauty-rate-from-invoice'),
      const Key('beauty-invoice-list'),
    );
    await tester.tap(find.byKey(const Key('beauty-rate-from-invoice')));
    await tester.pumpAndSettle();
    expect(find.byType(BeautyRatingScreen), findsOneWidget);
    expect(find.text('كيف كانت تجربتك؟'), findsOneWidget);
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
