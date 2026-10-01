import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/features/transport/domain/transport_models.dart';
import 'package:hojuzatcom/features/transport/presentation/car_rental_flow.dart';
import 'package:hojuzatcom/features/transport/presentation/freight_flow.dart';
import 'package:hojuzatcom/features/transport/presentation/land_transport_flow.dart';
import 'package:hojuzatcom/features/transport/presentation/transport_flow.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('car rental dates determine days and are carried to checkout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CarBookingScreen(
          office: RentalOffice('مكتب اختبار', 'صنعاء', 0, 1),
          car: RentalCar(
            name: 'سيارة اختبار',
            model: '2026',
            oldPrice: 1000,
            price: 1000,
            status: '',
            specs: {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final startTile = find.byKey(const Key('car-rental-start-date'));
    await tester.scrollUntilVisible(
      startTile,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(startTile);
    await tester.pumpAndSettle();
    final firstPicker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    final start = firstPicker.firstDate.add(const Duration(days: 2));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    var localization = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    await tester.enterText(
      find.byType(TextField).last,
      localization.formatCompactDate(start),
    );
    await tester.tap(find.text(localization.okButtonLabel));
    await tester.pumpAndSettle();
    final endTile = find.byKey(const Key('car-rental-end-date'));
    await tester.ensureVisible(endTile);
    await tester.tap(endTile);
    await tester.pumpAndSettle();
    final endPicker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(endPicker.firstDate, start.add(const Duration(days: 1)));
    expect(endPicker.lastDate, start.add(const Duration(days: 100)));
    final end = start.add(const Duration(days: 5));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    localization = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    await tester.enterText(
      find.byType(TextField).last,
      localization.formatCompactDate(end),
    );
    await tester.tap(find.text(localization.okButtonLabel));
    await tester.pumpAndSettle();
    expect(find.text('عدد أيام الإيجار: 5'), findsOneWidget);
    await tester.tap(find.text('متابعة إلى الدفع'));
    await tester.pumpAndSettle();
    final checkout = tester.widget<CarPaymentScreen>(
      find.byType(CarPaymentScreen),
    );
    expect(checkout.rentalStart, start);
    expect(checkout.rentalEnd, end);
    expect(checkout.days, 5);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
    'مسار تأجير السيارة يصل للدفع ولا ينشئ حجزاً محلياً عند غياب الخادم',
    (tester) async {
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
      expect(find.byType(CarInvoiceScreen), findsNothing);
      expect(find.byType(CarPaymentScreen), findsOneWidget);
      expect(
        find.text('تعذر الاتصال بخدمة الحجوزات. حاول مجددًا.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
