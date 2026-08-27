import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/reviews/service_review.dart';
import 'package:hojuzatcom/features/transport/domain/transport_models.dart';
import 'package:hojuzatcom/features/transport/presentation/car_rental_flow.dart';
import 'package:hojuzatcom/features/transport/presentation/freight_flow.dart';
import 'package:hojuzatcom/features/transport/presentation/land_transport_flow.dart';
import 'package:hojuzatcom/features/transport/presentation/transport_flow.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
  });

  testWidgets('بطاقة تأجير السيارات والنقل تفتح الواجهة المخصصة', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ServicesScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    final transportCard = find.text(
      'تأجير السيارات والنقل البري والشحن الداخلي',
    );
    await tester.scrollUntilVisible(
      transportCard,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(transportCard);
    await tester.pumpAndSettle();
    await tester.tap(transportCard);
    await tester.pumpAndSettle();

    expect(find.byType(TransportDiscoveryScreen), findsOneWidget);
    expect(find.byKey(const Key('transport-search-dropdown')), findsOneWidget);
  });

  testWidgets('واجهة النقل تعرض التصنيفات الثلاثة وبياناتها المستقلة', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: const TransportDiscoveryScreen(province: 'صنعاء'),
      ),
    );
    await tester.pumpAndSettle();

    final banner = tester.widget<Image>(
      find.byKey(const Key('transport-main-banner')),
    );
    expect((banner.image as AssetImage).assetName, transportBannerAsset);

    const passengerKey = Key('transport-category-passengerTransport');
    await _scrollToKey(
      tester,
      passengerKey,
      const Key('transport-discovery-list'),
    );
    await tester.tap(find.byKey(passengerKey));
    await tester.pumpAndSettle();
    expect(find.byType(LandTransportHomeScreen), findsOneWidget);
    expect(find.text('رحلتك البرية تبدأ من هنا'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: const TransportDiscoveryScreen(province: 'صنعاء'),
      ),
    );
    await tester.pumpAndSettle();
    const freightKey = Key('transport-category-freight');
    await _scrollToKey(
      tester,
      freightKey,
      const Key('transport-discovery-list'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(freightKey));
    await tester.pumpAndSettle();
    expect(find.byType(FreightHomeScreen), findsOneWidget);
    expect(find.text('الشحن الداخلي'), findsWidgets);
  });

  testWidgets('مسار تأجير السيارة يعمل من الاستكشاف حتى التقييم', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TransportDiscoveryScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    const rentalKey = Key('transport-category-carRental');
    await _scrollToKey(
      tester,
      rentalKey,
      const Key('transport-discovery-list'),
    );
    await tester.tap(find.byKey(rentalKey));
    await tester.pumpAndSettle();

    expect(find.byType(CarRentalCompaniesScreen), findsOneWidget);
    final office = find.text('إيلاف لتأجير السيارات');
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.ensureVisible(office);
    await tester.tap(office);
    await tester.pumpAndSettle();
    expect(find.byType(RentalOfficeScreen), findsOneWidget);

    final car = find.text('تويوتا لاندكروزر').first;
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.ensureVisible(car);
    await tester.tap(car);
    await tester.pumpAndSettle();
    expect(find.byType(CarDetailsScreen), findsOneWidget);

    await tester.tap(find.text('احجز السيارة'));
    await tester.pumpAndSettle();
    expect(find.byType(CarBookingScreen), findsOneWidget);

    await tester.tap(find.text('متابعة إلى الدفع'));
    await tester.pumpAndSettle();
    expect(find.byType(CarPaymentScreen), findsOneWidget);

    final wallet = find.text('ون كاش');
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.ensureVisible(wallet);
    await tester.tap(wallet);
    await tester.pumpAndSettle();
    await tester.tap(find.text('استكمال الدفع'));
    await tester.pumpAndSettle();
    expect(find.byType(CarInvoiceScreen), findsOneWidget);
    expect(find.text('تم تأكيد الحجز بنجاح'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('تقييم الخدمة'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('تقييم الخدمة'));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceRatingScreen), findsOneWidget);
    expect(find.text('كيف كانت تجربتك؟'), findsOneWidget);
  });

  testWidgets('نموذج الحجز يتكيف مع نقل الركاب والشحن', (tester) async {
    final passenger = transportListings.firstWhere(
      (item) => item.category == TransportCategory.passengerTransport,
    );
    await tester.pumpWidget(
      MaterialApp(home: TransportBookingScreen(listing: passenger)),
    );
    await tester.pumpAndSettle();
    await _scrollToKey(
      tester,
      const Key('transport-passenger-count'),
      const Key('transport-booking-list'),
    );
    expect(find.text('عدد الركاب'), findsOneWidget);
    expect(find.text('حجز رحلة ذهاب وعودة'), findsOneWidget);

    final freight = transportListings.firstWhere(
      (item) => item.category == TransportCategory.freight,
    );
    await tester.pumpWidget(
      MaterialApp(home: TransportBookingScreen(listing: freight)),
    );
    await tester.pumpAndSettle();
    await _scrollToKey(
      tester,
      const Key('transport-cargo-weight'),
      const Key('transport-booking-list'),
    );
    expect(find.byKey(const Key('transport-cargo-type')), findsOneWidget);
    expect(find.textContaining('الوزن التقريبي'), findsOneWidget);
    expect(find.text('خدمة تغليف احترافية'), findsOneWidget);
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
  for (var attempt = 0; attempt < 40; attempt++) {
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
