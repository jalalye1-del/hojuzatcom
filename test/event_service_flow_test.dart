import 'sector_backend_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/documents/invoice_pdf_service.dart';
import 'package:hojuzatcom/core/formatting/money_format.dart';

import 'package:hojuzatcom/features/catalog/data/control_panel_repository.dart';
import 'package:hojuzatcom/features/event_services/data/event_service_catalog.dart';
import 'package:hojuzatcom/features/event_services/domain/event_service.dart';
import 'package:hojuzatcom/features/event_services/presentation/event_service_admin.dart';
import 'package:hojuzatcom/features/event_services/presentation/event_service_flow.dart';
import 'package:hojuzatcom/features/halls/presentation/premium_hall_flow.dart';
import 'package:hojuzatcom/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('تنسيق مبالغ الفاتورة لا يضيف فاصلة في بداية المبلغ', () {
    expect(formatMoney(100), '100');
    expect(formatMoney(1000), '1,000');
    expect(formatMoney(135000), '135,000');
    expect(formatMoney(1000000), '1,000,000');
  });
  late EventServiceCatalog catalog;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
    appSession.isRegistered = true;
    appSession.isAuthenticated = true;
    catalog = EventServiceCatalog();
    await catalog.load();
  });

  test('المراكز تحتوي الأقسام الخمسة وخدماتها دون المكان ومرافقه', () {
    expect(eventServiceSections.map((section) => section.name), [
      'المطبوعات',
      'الضيافة',
      'فرق المناسبة',
      'التصوير والتجهيزات الصوتية',
      'التنسيق والكوش',
    ]);
    for (final provider in catalog.providers) {
      final categories = catalog.categoriesFor(provider.id);
      expect(
        categories.map((category) => category.group).toSet(),
        eventServiceSections.map((section) => section.id).toSet(),
      );
      expect(
        categories.map((category) => category.name),
        isNot(
          anyElement(
            isIn([
              'القاعة',
              'موقف السيارات',
              'غرفة العروس',
              'المكان ومرافقه',
              'الإضاءة',
            ]),
          ),
        ),
      );
      for (final category in categories) {
        expect(
          catalog
              .itemsFor(provider)
              .where((item) => item.category.id == category.id),
          isNotEmpty,
        );
      }
      for (final original in localControlPanelRepository.hallAddonItems) {
        expect(
          catalog
              .itemsFor(provider)
              .any(
                (item) =>
                    item.name == original.name &&
                    item.unitPrice == original.unitPrice,
              ),
          isTrue,
        );
      }
    }
  });

  test(
    'تعديلات الإدارة تحفظ وتستعاد وتشمل البنرات والصور وحذف التصنيفات',
    () async {
      const center = EventServiceProvider(id: 'new-center', name: 'مركز جديد');
      await catalog.saveProvider(center);
      const category = EventServiceCategory(
        'custom',
        'تغليف هدايا',
        'printing',
        providerId: 'new-center',
      );
      await catalog.saveCategory(category);
      final item = EventServiceItem(
        id: 'custom-item',
        providerId: center.id,
        category: category,
        name: 'تغليف فاخر',
        unit: 'هدية',
        unitPrice: 700,
        images: const [eventServiceImage],
      );
      await catalog.saveItem(item);
      await catalog.saveSection(
        const EventSectionContent(
          providerId: 'new-center',
          sectionId: 'printing',
          title: 'بنر جديد',
          subtitle: 'تفاصيل جديدة',
          gallery: ['https://example.com/photo.jpg'],
        ),
      );
      await catalog.saveBanner(
        title: 'عنوان المراكز',
        subtitle: 'وصف المراكز',
        image: eventServiceImage,
      );
      await catalog.savePromotion(
        const EventPromotion(
          id: 'custom-offer',
          title: 'عرض جديد',
          subtitle: 'وصف العرض',
          targetId: 'new-center',
        ),
      );
      final restored = EventServiceCatalog();
      await restored.load();
      expect(restored.itemsFor(center).single.unitPrice, 700);
      expect(restored.bannerTitle, 'عنوان المراكز');
      expect(restored.sectionFor(center.id, 'printing').gallery, [
        'https://example.com/photo.jpg',
      ]);
      final cart = EventServiceCart(restored, center.id)
        ..setQuantity(item.id, 2);
      expect(cart.total, 1400);
      await restored.deleteCategory(category.id);
      expect(cart.lines, isEmpty);
      await restored.deleteProvider(center.id);
      final afterDelete = EventServiceCatalog();
      await afterDelete.load();
      expect(afterDelete.providerById(center.id), isNull);
      expect(
        afterDelete.promotions.any((offer) => offer.targetId == center.id),
        isFalse,
      );
      expect(afterDelete.categoriesFor(center.id), isEmpty);
    },
  );

  test('فشل الحفظ لا يحذف البيانات المعروضة ولا المحفوظة', () async {
    final repository = _FailingRepository();
    final source = EventServiceCatalog(source: repository);
    await source.load();
    final first = source.providers.first;
    await expectLater(source.deleteProvider(first.id), throwsStateError);
    expect(source.providerById(first.id), isNotNull);
    expect(source.saving, isFalse);
  });

  testWidgets('بطاقة الصالات تفتح بطاقتين عموديتين متجاورتين وعروضاً مميزة', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ServicesScreen(province: 'صنعاء')));
    await tester.pumpAndSettle();
    await _visible(tester, find.text('قاعات أفراح ومناسبات'));
    await tester.tap(find.text('قاعات أفراح ومناسبات'));
    await tester.pumpAndSettle();
    _phone(tester);
    await tester.pumpAndSettle();
    final halls = find.byKey(const Key('occasion-category-halls'));
    final centers = find.byKey(const Key('occasion-category-services'));
    await _visible(tester, halls);
    expect(tester.getTopLeft(halls).dy, tester.getTopLeft(centers).dy);
    expect(tester.getTopLeft(halls).dx, isNot(tester.getTopLeft(centers).dx));
    expect(
      tester.getSize(halls).height,
      greaterThan(tester.getSize(halls).width),
    );
    await _tap(tester, 'occasion-offer-center-featured');
    expect(find.byType(EventServiceCenterScreen), findsOneWidget);
    _back<EventServiceCenterScreen>(tester);
    await tester.pumpAndSettle();
    await _tap(tester, 'occasion-offer-hall-featured');
    expect(find.byType(HallVenueScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('حجز القاعة يرسل سعر الباقة للخادم دون إضافات أو تحصيل وهمي', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const HallDatePackageScreen(name: 'قاعة اختبار', province: 'عدن')),
    );
    await tester.pumpAndSettle();
    await _visible(tester, find.text('الباقة الأساسية'));
    await tester.tap(find.text('الباقة الأساسية'));
    await tester.tap(find.text('متابعة الحجز'));
    await tester.pumpAndSettle();
    final data = tester.widget<HallBookingDataScreen>(
      find.byType(HallBookingDataScreen),
    );
    expect(data.booking.total, 450000);
    expect(find.text('خصص مناسبتك'), findsNothing);
    final agreement = find.byType(CheckboxListTile);
    await _visible(tester, agreement);
    await tester.tap(agreement);
    await tester.pump();
    await tester.tap(find.text('الانتقال للدفع'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<HallSecurePaymentScreen>(find.byType(HallSecurePaymentScreen))
          .total,
      450000,
    );
    final backend = SectorBackendFixture(
      services: [
        SectorBackendFixture.service(
          id: 'hall-service',
          name: 'قاعة اختبار',
          type: 'event_hall',
          province: 'عدن',
          price: 450000,
          providerName: 'قاعة اختبار',
        ),
      ],
      total: 450000,
    );
    await tester.tap(find.text('تأكيد ودفع 135,000 ر.ي'));
    await tester.pumpAndSettle();
    expect(find.text('تم إرسال طلب الحجز'), findsOneWidget);
    expect(find.text('الإجمالي المعتمد: 450000 YER'), findsOneWidget);
    expect(backend.requests, hasLength(1));
    expect(backend.requests.single['service_id'], 'hall-service');
    expect(backend.requests.single['total'], 450000);
    expect(backend.requests.single.containsKey('items'), isFalse);
    expect(backend.requests.single['metadata'].containsKey('extras'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('كل قسم في المركز يعرض بنراً ومعرض صور', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        EventServiceCenterScreen(
          province: 'تعز',
          providerId: 'event-hospitality',
          catalog: catalog,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final section in eventServiceSections) {
      await _tap(tester, 'event-section-${section.id}');
      expect(
        find.byKey(Key('event-section-banner-${section.id}')),
        findsOneWidget,
      );
      await _visible(tester, find.byKey(Key('event-${section.id}-gallery')));
      await _tap(tester, 'event-${section.id}-photo-0');
      expect(find.byType(InteractiveViewer), findsWidgets);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      _back<EventServiceSelectionScreen>(tester);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('خدمات قسمين تبقى في السلة حتى إرسال الأصناف والكميات للخادم', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(HallAndEventCategoriesScreen(province: 'تعز', catalog: catalog)),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'occasion-category-services');
    expect(find.byKey(const Key('event-centers-banner')), findsOneWidget);
    await _tap(tester, 'event-provider-event-hospitality');
    await _tap(tester, 'event-section-printing');
    await _enter(tester, 'event-quantity-event-hospitality/invitation', '٢');
    _back<EventServiceSelectionScreen>(tester);
    await tester.pumpAndSettle();
    await _tap(tester, 'event-section-hospitality');
    await _enter(tester, 'event-quantity-event-hospitality/meal-crispy', '١٠٠');
    await _tap(tester, 'event-filter-event-hospitality/soft-drinks');
    await _enter(tester, 'event-quantity-event-hospitality/drink-pepsi', '50');
    expect(find.text('الإجمالي: 55,700 ر.ي'), findsOneWidget);
    await _tap(tester, 'event-filter-event-hospitality/meals');
    await _enter(tester, 'event-quantity-event-hospitality/meal-crispy', '80');
    await tester.tap(find.text('متابعة الحجز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراجعة الطلب والدفع'));
    await tester.pumpAndSettle();
    expect(find.byType(EventServicePaymentScreen), findsNothing);
    await _enter(tester, 'event-address', 'شارع جمال، منزل العائلة');
    await _enter(tester, 'event-guests', '٨٠');
    await _enter(tester, 'event-customer-name', 'أحمد محمد علي');
    await _enter(tester, 'event-phone', '٧٧٧١٢٣٤٥٦');
    await _enter(tester, 'event-notes', 'تجهيز الضيافة قبل الموعد');
    await tester.tap(find.text('مراجعة الطلب والدفع'));
    await tester.pumpAndSettle();
    final payment = tester.widget<EventServicePaymentScreen>(
      find.byType(EventServicePaymentScreen),
    );
    expect(payment.order.total, 46700);
    expect(payment.order.toBookingDraft().serviceId, eventServicesId);
    expect(payment.order.phone, '777123456');
    await _tap(tester, 'event-payment-jeeb');
    await _tap(tester, 'event-review-confirmation');
    final backend = SectorBackendFixture(
      services: payment.order.lines
          .map(
            (line) => SectorBackendFixture.service(
              id: line.item.id,
              name: line.item.name,
              type: 'event_service',
              province: 'تعز',
              price: line.item.unitPrice,
              provider: payment.order.provider.id,
              providerName: payment.order.provider.name,
            ),
          )
          .toList(),
      total: 46700,
    );
    await tester.tap(find.text('معاينة الحجز والفاتورة'));
    await tester.pumpAndSettle();
    expect(find.text('تم إرسال طلب الحجز'), findsOneWidget);
    expect(find.text('الإجمالي المعتمد: 46700 YER'), findsOneWidget);
    expect(backend.requests, hasLength(1));
    final submitted = backend.requests.single;
    expect(submitted['provider_id'], payment.order.provider.id);
    expect(submitted['items'], [
      for (final line in payment.order.lines)
        {'service_id': line.item.id, 'quantity': line.quantity},
    ]);
    expect((submitted['items'] as List).length, 3);
    expect(submitted['metadata']['phone'], '777123456');
    expect(submitted.containsKey('method_id'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('لوحة التحكم تضيف تصنيفاً وخدمة وتحذفهما مع حفظ التغيير', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(EventServicesHomeScreen(province: 'عدن', catalog: catalog)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-open-admin')));
    await tester.pumpAndSettle();
    expect(find.byType(EventServiceAdminScreen), findsOneWidget);
    await _tap(tester, 'admin-center-event-hospitality');
    await _visible(tester, find.text('إضافة تصنيف'));
    await tester.tap(find.text('إضافة تصنيف'));
    await tester.pumpAndSettle();
    await _enter(tester, 'admin-field-name', 'هدايا الضيوف');
    await tester.tap(find.byKey(const Key('admin-save')));
    await tester.pumpAndSettle();
    final category = catalog
        .categoriesFor('event-hospitality')
        .firstWhere((item) => item.name == 'هدايا الضيوف');
    await _tap(tester, 'admin-add-service-${category.id}');
    await _enter(tester, 'admin-field-name', 'بطاقة شكر');
    await _enter(tester, 'admin-field-price', '٥٠٠');
    await tester.tap(find.byKey(const Key('admin-save')));
    await tester.pumpAndSettle();
    final item = catalog
        .itemsFor(catalog.providers.first)
        .firstWhere((item) => item.name == 'بطاقة شكر');
    expect(item.unitPrice, 500);
    final restored = EventServiceCatalog();
    await restored.load();
    expect(
      restored
          .itemsFor(restored.providers.first)
          .any((entry) => entry.id == item.id),
      isTrue,
    );
    await _tap(tester, 'admin-delete-service-${item.id}');
    await tester.tap(find.byKey(const Key('admin-confirm-delete')));
    await tester.pumpAndSettle();
    expect(
      catalog
          .itemsFor(catalog.providers.first)
          .any((entry) => entry.id == item.id),
      isFalse,
    );
    await _tap(tester, 'admin-delete-category-${category.id}');
    await tester.tap(find.byKey(const Key('admin-confirm-delete')));
    await tester.pumpAndSettle();
    expect(catalog.categories.any((entry) => entry.id == category.id), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('البحث عن المراكز والترجمة الإنجليزية', (tester) async {
    appSession.language = 'English';
    await tester.pumpWidget(
      _app(EventServicesHomeScreen(province: 'عدن', catalog: catalog)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Event service centers'), findsOneWidget);
    await _enter(tester, 'event-center-search', 'no-such-center');
    expect(find.text('No results match your search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('فاتورة المركز تنشئ PDF متعدد الخدمات', () async {
    final provider = catalog.providers.first;
    final order = EventServiceOrder(
      provider: provider,
      lines: [
        for (final item in catalog.itemsFor(provider))
          EventServiceLine(item: item, quantity: 100),
      ],
      province: 'صنعاء',
      scheduledAt: DateTime.now().add(const Duration(days: 10)),
      guestCount: 100,
      address: 'شارع الزبيري، منزل العائلة',
      customerName: 'أحمد محمد علي',
      phone: '777123456',
    );
    final receipt = EventServiceReceipt(
      order: order,
      reference: 'ES-pdf-test',
      paymentMethodName: 'جيب',
      createdAt: DateTime.now(),
    );
    final bytes = await InvoicePdfService.build(
      title: 'فاتورة تجريبية لخدمات المناسبات',
      reference: receipt.invoiceReference,
      details: receipt.invoiceDetails,
      status: receipt.status,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

class _FailingRepository extends LocalControlPanelRepository {
  @override
  Future<void> saveEventServiceCatalog(Map<String, dynamic> catalog) async =>
      throw StateError('Storage unavailable');
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);
void _back<T extends Widget>(WidgetTester tester) =>
    Navigator.of(tester.element(find.byType(T))).pop();
Future<void> _visible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 80,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await _visible(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(Key(key));
  await _visible(tester, finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}
