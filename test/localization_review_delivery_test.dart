import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/localization/app_locale.dart';
import 'package:hojuzatcom/core/reviews/service_review.dart';
import 'package:hojuzatcom/features/apartments/presentation/apartment_flow.dart';
import 'package:hojuzatcom/features/auth/presentation/app_session.dart';
import 'package:hojuzatcom/features/delivery/presentation/delivery_basket.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
    AppSession.currentUserIdentity = '700000000';
    deliveryBasket.clear();
    await serviceReviewStore.clearForTesting();
  });

  testWidgets('تبديل اللغة يظهر فوراً قبل انتهاء الحفظ', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LocalizedText('تقييم الخدمة'))),
    );
    expect(find.text('تقييم الخدمة'), findsOneWidget);

    final saving = appSession.setLanguage('English');
    await tester.pump();

    expect(AppSession.languageListenable.value, 'English');
    expect(find.text('Rate service'), findsOneWidget);
    await saving;
  });

  testWidgets('اللغة الإنجليزية تغطي الدخول والخدمات والشقق', (tester) async {
    appSession.language = 'English';

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Hujuzatcom'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    _expectNoArabicText(tester);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: const ServicesScreen(province: 'صنعاء'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Furnished apartments'), findsOneWidget);
    expect(find.text('Quick delivery'), findsOneWidget);
    _expectNoArabicText(tester);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: const ApartmentDiscoveryScreen(province: 'صنعاء'),
      ),
    );
    await tester.pumpAndSettle();
    final featuredOffers = find.text('Featured offers');
    await tester.scrollUntilVisible(
      featuredOffers,
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('apartment-home-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(featuredOffers, findsOneWidget);
    final firstApartment = find.byKey(
      const Key('apartment-card-nuqum-modern'),
    );
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
    await tester.pumpAndSettle();
    expect(
      find.text('Modern apartment overlooking Jabal Nuqum'),
      findsOneWidget,
    );
    _expectNoArabicText(tester);
  });

  testWidgets('التقييم التلقائي يظهر للحساب والخدمة المستخدمين فقط', (
    tester,
  ) async {
    await serviceReviewStore.markCompleted('شقق مفروشة');
    await tester.pumpWidget(
      const MaterialApp(home: ServicesScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();

    await _openServiceCard(tester, 'شقق مفروشة');
    expect(find.byType(ServiceRatingScreen), findsOneWidget);
    expect(find.text('أخبرنا عن تجربتك السابقة'), findsWidgets);

    final later = find.text('لاحقاً');
    await tester.ensureVisible(later);
    await tester.pumpAndSettle();
    await tester.tap(later);
    await tester.pumpAndSettle();
    expect(find.byType(ApartmentDiscoveryScreen), findsOneWidget);

    AppSession.currentUserIdentity = '711111111';
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: const ServicesScreen(province: 'صنعاء'),
      ),
    );
    await tester.pumpAndSettle();
    await _openServiceCard(tester, 'شقق مفروشة');
    expect(find.byType(ServiceRatingScreen), findsNothing);
    expect(find.byType(ApartmentDiscoveryScreen), findsOneWidget);
  });

  testWidgets('كمية التوصيل تعدل مباشرة بدون أزرار زيادة أو إنقاص', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final item = DeliveryCartItem(
      id: 'water',
      name: 'مياه معدنية',
      category: 'سوبر ماركت',
      unitPrice: 500,
      quantity: 2,
    );
    deliveryBasket.add(item);
    deliveryBasket.setDeliveryLocation('صنعاء');

    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryCartScreen(province: 'صنعاء', category: 'متنوع'),
      ),
    );
    await tester.pumpAndSettle();

    final quantity = find.byKey(const ValueKey('delivery-quantity-water'));
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '4');
    await tester.pumpAndSettle();

    expect(item.quantity, 4);
    expect(item.total, 2000);
    final compactCard = find.byKey(const ValueKey('delivery-item-water'));
    expect(
      find.descendant(of: compactCard, matching: find.byIcon(Icons.add)),
      findsNothing,
    );
    expect(
      find.descendant(of: compactCard, matching: find.byIcon(Icons.remove)),
      findsNothing,
    );
  });
}

Future<void> _openServiceCard(WidgetTester tester, String label) async {
  final card = find.text(label);
  await tester.scrollUntilVisible(
    card,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void _expectNoArabicText(WidgetTester tester) {
  final arabic = RegExp(r'[\u0600-\u06ff]');
  final visibleArabic = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .where(arabic.hasMatch)
      .toList();
  expect(visibleArabic, isEmpty, reason: 'Arabic text found: $visibleArabic');
}
