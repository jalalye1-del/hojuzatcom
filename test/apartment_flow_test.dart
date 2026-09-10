import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/features/apartments/presentation/apartment_flow.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
  });

  testWidgets('بطاقة الشقق المفروشة تفتح الواجهة المخصصة', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ServicesScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    final apartmentCard = find.text('شقق مفروشة');
    await tester.scrollUntilVisible(
      apartmentCard,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(apartmentCard);
    await tester.pumpAndSettle();
    await tester.tap(apartmentCard);
    await tester.pumpAndSettle();

    expect(find.byType(ApartmentDiscoveryScreen), findsOneWidget);
    expect(find.byKey(const Key('apartment-search-field')), findsOneWidget);
  });

  testWidgets('مسار الشقة لا يصدر دفعًا أو فاتورة عند غياب الربط بالخادم', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ApartmentDiscoveryScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    final banner = tester.widget<Image>(
      find.byKey(const Key('apartment-main-banner')),
    );
    expect((banner.image as AssetImage).assetName, apartmentBannerAsset);
    final firstApartment = find.byKey(const Key('apartment-card-nuqum-modern'));
    await tester.scrollUntilVisible(
      firstApartment,
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('apartment-home-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(firstApartment);
    await tester.pumpAndSettle();
    expect(find.text('شقة مودرن بإطلالة جبل نقم'), findsOneWidget);

    await tester.tap(firstApartment);
    await tester.pumpAndSettle();
    expect(find.byType(ApartmentHostListingsScreen), findsOneWidget);
    expect(find.text('نواره للشقق المفروشة'), findsWidgets);

    final hostUnit = find.byKey(const Key('apartment-host-unit-nuqum-modern'));
    await tester.ensureVisible(hostUnit);
    await tester.tap(hostUnit);
    await tester.pumpAndSettle();
    expect(find.byType(ApartmentDetailsScreen), findsOneWidget);
    expect(find.text('المميزات والخدمات'), findsOneWidget);

    await tester.tap(find.byKey(const Key('apartment-book-now-button')));
    await tester.pumpAndSettle();
    expect(find.byType(ApartmentBookingDetailsScreen), findsOneWidget);

    await _scrollToKey(
      tester,
      const Key('apartment-booking-continue'),
      const Key('apartment-booking-details-list'),
    );
    await tester.tap(find.byKey(const Key('apartment-booking-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(ApartmentRenterInformationScreen), findsOneWidget);

    await _enterField(tester, const Key('renter-name'), 'أحمد محمد علي');
    await _enterField(tester, const Key('renter-phone'), '967700000000');
    await _enterField(tester, const Key('renter-id'), '01024578');
    await _scrollToKey(
      tester,
      const Key('renter-continue'),
      const Key('apartment-renter-list'),
    );
    await tester.tap(find.byKey(const Key('renter-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(ApartmentRenterInformationScreen), findsOneWidget);
    expect(find.byType(ApartmentPaymentScreen), findsNothing);
    expect(find.byType(ApartmentBookingSuccessScreen), findsNothing);
    expect(find.text('AP-2026-020458'), findsNothing);
    expect(
      find.text('خدمة الشقق غير مربوطة بكتالوج Laravel لهذه المحافظة.'),
      findsOneWidget,
    );
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
  for (var attempt = 0; attempt < 30; attempt++) {
    final elements = target.evaluate();
    final renderObject = elements.isEmpty ? null : elements.first.renderObject;
    if (renderObject is RenderBox && renderObject.attached) {
      final position = renderObject.localToGlobal(Offset.zero);
      if (position.dy >= 120 && position.dy <= 650) break;
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
