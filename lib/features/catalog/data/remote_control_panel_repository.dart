import '../../event_services/data/event_service_catalog.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_parsing.dart';
import 'control_panel_repository.dart';

/// Published editorial content. Bookable inventory remains in CatalogRepository.
class RemoteControlPanelRepository extends LocalControlPanelRepository {
  RemoteControlPanelRepository(this.api);
  final ApiClient api;
  final revision = ValueNotifier<int>(0);
  List<ProvinceRecord> _provinces = [];
  List<PromotionRecord> _promotions = [];
  SupportConfigRecord _support = const SupportConfigRecord(
    title: 'الدعم',
    subtitle: '',
    whatsappNumbers: [],
    callNumbers: [],
    address: '',
  );
  Map<String, dynamic>? eventBanner;

  @override
  List<ProvinceRecord> get provinces => List.unmodifiable(_provinces);
  @override
  List<PromotionRecord> get promotions => List.unmodifiable(_promotions);
  @override
  SupportConfigRecord get supportConfig => _support;
  @override
  List<ProviderRecord> get providers => const [];
  @override
  List<DeliveryStoreRecord> get deliveryStores => const [];
  @override
  List<BookableExtraRecord> get hotelRoomExtras => const [];
  @override
  List<HallAddonItemRecord> get hallAddonItems => const [];
  @override
  List<PaymentMethodRecord> get paymentMethods => const [];
  @override
  List<NotificationRuleRecord> get notificationRules => const [];

  static String? moduleFor(String type) => switch (type) {
    'hotel_room' => 'hotels',
    'restaurant_order' ||
    'restaurant_table' ||
    'restaurant_reservation' => 'restaurants',
    'delivery' || 'quick_delivery' => 'delivery',
    'apartment' || 'furnished_apartment' => 'apartments',
    'car_rental' ||
    'vehicle_rental' ||
    'land_transport' ||
    'shipping' ||
    'domestic_shipping' => 'cars',
    'event_hall' || 'event_service' => 'halls',
    'travel_service' ||
    'travel_package' ||
    'flight_ticket' ||
    'tourist_visa' ||
    'work_visa' ||
    'administrative' => 'travel',
    'chalet' => 'chalets',
    'resort' => 'resorts',
    'beauty' => 'beauty',
    _ => null,
  };

  int _generation = 0;
  Future<void> load() async {
    final generation = ++_generation;
    final root = expectJsonMap(
      await api.get('app-content', authenticated: false),
    );
    final data = expectJsonMap(root['data']);
    if (data['version'] != 1) {
      throw const FormatException('Unsupported content version');
    }
    final provinces = (data['provinces'] as List)
        .map((value) {
          final row = expectJsonMap(value);
          return ProvinceRecord(
            id: row['id'] as String,
            name: row['name'] as String,
            imagePath: row['image_path'] as String? ?? '',
            enabled: row['enabled'] == true,
          );
        })
        .where((row) => row.enabled)
        .toList();
    final support = expectJsonMap(data['support']);
    final promotions = <PromotionRecord>[];
    for (final value in data['promotions'] as List) {
      final row = expectJsonMap(value);
      final module = moduleFor(row['service_type'] as String);
      if (module == null) continue;
      final definition = services.firstWhere((service) => service.id == module);
      promotions.add(
        PromotionRecord(
          id: row['service_id'] as String,
          serviceId: module,
          providerId: row['provider_id'] as String,
          title: row['title'] as String,
          imagePath: row['image_path'] as String? ?? definition.imagePath,
          discountPercent: 0,
        ),
      );
    }
    final parsedSupport = SupportConfigRecord(
      title: support['title'] as String,
      subtitle: support['subtitle'] as String? ?? '',
      address: support['address'] as String? ?? '',
      whatsappNumbers: List<String>.from(support['whatsapp_numbers'] as List),
      callNumbers: List<String>.from(support['call_numbers'] as List),
    );
    final banner = data['event_banner'] == null
        ? null
        : expectJsonMap(data['event_banner']);
    if (generation != _generation) return;
    _provinces = provinces;
    _promotions = promotions;
    _support = parsedSupport;
    eventBanner = banner;
    eventServiceCatalog.applyPublishedBanner(banner);
    revision.value++;
  }

  @override
  Future<Map<String, dynamic>?> getEventServiceCatalog() async => null;
  @override
  Future<void> saveEventServiceCatalog(Map<String, dynamic> catalog) async =>
      throw StateError('تدار الخدمات من لوحة التحكم المركزية.');
  @override
  Future<void> createBooking(BookingRecord booking) async =>
      throw StateError('استخدم خدمة الحجز المتصلة بالخادم.');
  @override
  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    Map<String, dynamic>? metadata,
  }) async => throw StateError('تدار حالة الحجز عبر الخادم.');
}
