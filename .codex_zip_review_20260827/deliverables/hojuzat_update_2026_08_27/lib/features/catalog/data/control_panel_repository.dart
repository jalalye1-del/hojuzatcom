/// العقود الموحدة لبيانات لوحة التحكم.
/// يمكن استبدال [LocalControlPanelRepository] لاحقاً بمستودع API دون تغيير الواجهات.
class ProvinceRecord {
  const ProvinceRecord({
    required this.id,
    required this.name,
    required this.imagePath,
    this.enabled = true,
  });
  final String id;
  final String name;
  final String imagePath;
  final bool enabled;
}

class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.imagePath,
    this.enabled = true,
  });
  final String id;
  final String name;
  final String iconKey;
  final String imagePath;
  final bool enabled;
}

class ProviderRecord {
  const ProviderRecord({
    required this.id,
    required this.serviceId,
    required this.provinceId,
    required this.name,
    required this.address,
    required this.imagePath,
    required this.rating,
    this.enabled = true,
    this.features = const [],
  });
  final String id;
  final String serviceId;
  final String provinceId;
  final String name;
  final String address;
  final String imagePath;
  final double rating;
  final bool enabled;
  final List<String> features;
}

class PromotionRecord {
  const PromotionRecord({
    required this.id,
    required this.serviceId,
    required this.providerId,
    required this.title,
    required this.imagePath,
    required this.discountPercent,
    this.enabled = true,
  });
  final String id;
  final String serviceId;
  final String providerId;
  final String title;
  final String imagePath;
  final int discountPercent;
  final bool enabled;
}

class PaymentMethodRecord {
  const PaymentMethodRecord({
    required this.id,
    required this.name,
    required this.type,
    this.enabled = true,
    this.deepLink,
  });
  final String id;
  final String name;
  final String type;
  final bool enabled;
  final String? deepLink;
}

class DeliveryCategoryRecord {
  const DeliveryCategoryRecord({
    required this.id,
    required this.name,
    required this.iconKey,
    this.enabled = true,
  });
  final String id;
  final String name;
  final String iconKey;
  final bool enabled;
}

class DeliveryStoreRecord {
  const DeliveryStoreRecord({
    required this.id,
    required this.categoryId,
    required this.provinceId,
    required this.name,
    required this.address,
    required this.imagePath,
    required this.rating,
    this.enabled = true,
  });
  final String id;
  final String categoryId;
  final String provinceId;
  final String name;
  final String address;
  final String imagePath;
  final double rating;
  final bool enabled;
}

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.serviceId,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    this.metadata = const {},
  });
  final String id;
  final String userId;
  final String providerId;
  final String serviceId;
  final String status;
  final int total;
  final String currency;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
}

/// نقطة الربط الوحيدة لواجهة API/Firestore/لوحة التحكم لاحقاً.
abstract class ControlPanelRepository {
  Future<List<ProvinceRecord>> getProvinces();
  Future<List<ServiceRecord>> getServices(String provinceId);
  Future<List<ProviderRecord>> getProviders({
    required String provinceId,
    required String serviceId,
  });
  Future<List<PromotionRecord>> getPromotions({
    String? provinceId,
    String? serviceId,
  });
  Future<List<PaymentMethodRecord>> getPaymentMethods();
  Future<List<DeliveryCategoryRecord>> getDeliveryCategories();
  Future<List<DeliveryStoreRecord>> getDeliveryStores({
    required String provinceId,
    required String categoryId,
    String query = '',
  });
  Future<void> createBooking(BookingRecord booking);
  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    Map<String, dynamic>? metadata,
  });
}

/// بيانات محلية مؤقتة بنفس بنية API؛ تستبدل عند ربط لوحة التحكم.
class LocalControlPanelRepository implements ControlPanelRepository {
  final List<ProvinceRecord> provinces = const [
    ProvinceRecord(
      id: 'abyan',
      name: 'أبين',
      imagePath: 'assets/images/محافظة ابين.jpg',
    ),
    ProvinceRecord(id: 'aden', name: 'عدن', imagePath: 'assets/images/عدن.jpg'),
    ProvinceRecord(
      id: 'al-bayda',
      name: 'البيضاء',
      imagePath: 'assets/images/محافظة البيضاء.jpg',
    ),
    ProvinceRecord(
      id: 'al-dhale',
      name: 'الضالع',
      imagePath: 'assets/images/محافظة الضالع.jpg',
    ),
    ProvinceRecord(
      id: 'al-hudaydah',
      name: 'الحديدة',
      imagePath: 'assets/images/محافظة الحديدة.jpg',
    ),
    ProvinceRecord(
      id: 'al-jawf',
      name: 'الجوف',
      imagePath: 'assets/images/محافظة الجوف.jpg',
    ),
    ProvinceRecord(
      id: 'al-mahrah',
      name: 'المهرة',
      imagePath: 'assets/images/محافظة المهرة.jpg',
    ),
    ProvinceRecord(
      id: 'al-mahwit',
      name: 'المحويت',
      imagePath: 'assets/images/محافظة المحويت.jpg',
    ),
    ProvinceRecord(
      id: 'amran',
      name: 'عمران',
      imagePath: 'assets/images/عمران.jpg',
    ),
    ProvinceRecord(
      id: 'dhamar',
      name: 'ذمار',
      imagePath: 'assets/images/ذمار.jpg',
    ),
    ProvinceRecord(
      id: 'hadramawt',
      name: 'حضرموت',
      imagePath: 'assets/images/حضرموت.jpg',
    ),
    ProvinceRecord(
      id: 'hajjah',
      name: 'حجة',
      imagePath: 'assets/images/حجة.jpg',
    ),
    ProvinceRecord(
      id: 'ibb',
      name: 'إب',
      imagePath: 'assets/images/محافظة اب.jpg',
    ),
    ProvinceRecord(
      id: 'lahij',
      name: 'لحج',
      imagePath: 'assets/images/لحج.jpg',
    ),
    ProvinceRecord(
      id: 'marib',
      name: 'مأرب',
      imagePath: 'assets/images/مأرب.jpg',
    ),
    ProvinceRecord(
      id: 'raymah',
      name: 'ريمة',
      imagePath: 'assets/images/ريمة.jpg',
    ),
    ProvinceRecord(
      id: 'saada',
      name: 'صعدة',
      imagePath: 'assets/images/صعدة.jpg',
    ),
    ProvinceRecord(
      id: 'sanaa',
      name: 'صنعاء',
      imagePath: 'assets/images/محافظة صنعاء.jpg',
    ),
    ProvinceRecord(
      id: 'socotra',
      name: 'سقطرى',
      imagePath: 'assets/images/سقطرى.jpg',
    ),
    ProvinceRecord(
      id: 'shabwah',
      name: 'شبوة',
      imagePath: 'assets/images/شبوة.jpg',
    ),
    ProvinceRecord(id: 'taiz', name: 'تعز', imagePath: 'assets/images/تعز.jpg'),
  ];

  final List<ServiceRecord> services = const [
    ServiceRecord(
      id: 'hotels',
      name: 'فنادق',
      iconKey: 'hotel',
      imagePath: 'assets/Services images/الفنادق.jpg',
    ),
    ServiceRecord(
      id: 'restaurants',
      name: 'مطاعم',
      iconKey: 'restaurant',
      imagePath: 'assets/Services images/المطاعم.jpg',
    ),
    ServiceRecord(
      id: 'cars',
      name: 'تأجير سيارات ونقل',
      iconKey: 'car',
      imagePath: 'assets/Services images/تأجير السيارات.jpg',
    ),
    ServiceRecord(
      id: 'delivery',
      name: 'التوصيل السريع',
      iconKey: 'delivery',
      imagePath: 'assets/Services images/التوصيل السريع.jpg',
    ),
    ServiceRecord(
      id: 'apartments',
      name: 'شقق مفروشة',
      iconKey: 'apartment',
      imagePath: 'assets/Services images/شقق مفروشة.jpg',
    ),
    ServiceRecord(
      id: 'halls',
      name: 'قاعات أفراح ومناسبات',
      iconKey: 'hall',
      imagePath: 'assets/Services images/قاعات افراح ومناسبات.jpg',
    ),
    ServiceRecord(
      id: 'travel',
      name: 'سفريات وسياحة',
      iconKey: 'travel',
      imagePath: 'assets/Services images/سفريات وسياحة.jpg',
    ),
    ServiceRecord(
      id: 'chalets',
      name: 'شاليهات',
      iconKey: 'chalet',
      imagePath: 'assets/Services images/شاليهات.jpg',
    ),
    ServiceRecord(
      id: 'resorts',
      name: 'منتجعات',
      iconKey: 'resort',
      imagePath: 'assets/Services images/منتجعات.jpg',
    ),
    ServiceRecord(
      id: 'beauty',
      name: 'مراكز تجميل',
      iconKey: 'beauty',
      imagePath: 'assets/Services images/مراكز تجميل.jpg',
    ),
  ];

  final List<ProviderRecord> providers = const [
    ProviderRecord(id: 'travel-1', serviceId: 'travel', provinceId: 'all', name: 'روائع اليمن للسفريات', address: 'صنعاء', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.9),
    ProviderRecord(id: 'travel-2', serviceId: 'travel', provinceId: 'all', name: 'سبأ للسياحة', address: 'صنعاء', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.8),
    ProviderRecord(id: 'travel-3', serviceId: 'travel', provinceId: 'all', name: 'العالمية للسفريات', address: 'عدن', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.8),
    ProviderRecord(id: 'travel-4', serviceId: 'travel', provinceId: 'all', name: 'بوابة اليمن', address: 'تعز', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.7),
    ProviderRecord(id: 'travel-5', serviceId: 'travel', provinceId: 'all', name: 'رحلات النخبة', address: 'إب', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.7),
    ProviderRecord(id: 'travel-6', serviceId: 'travel', provinceId: 'all', name: 'أجنحة سبأ', address: 'صنعاء', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.6),
    ProviderRecord(id: 'travel-7', serviceId: 'travel', provinceId: 'all', name: 'دروب للسياحة', address: 'حضرموت', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.6),
    ProviderRecord(id: 'travel-8', serviceId: 'travel', provinceId: 'all', name: 'المسافر اليمني', address: 'الحديدة', imagePath: 'assets/Services images/سفريات وسياحة.jpg', rating: 4.5),
  ];

  final List<PromotionRecord> promotions = const [
    PromotionRecord(id: 'hotel-offer-1', serviceId: 'hotels', providerId: '', title: 'إقامة بخصم 20%', imagePath: 'assets/Services images/الفنادق.jpg', discountPercent: 20),
    PromotionRecord(id: 'chalet-offer-1', serviceId: 'chalets', providerId: '', title: 'عرض عائلي مميز', imagePath: 'assets/Services images/شاليهات.jpg', discountPercent: 15),
    PromotionRecord(id: 'beauty-offer-1', serviceId: 'beauty', providerId: '', title: 'جلسة عناية خاصة', imagePath: 'assets/Services images/مراكز تجميل.jpg', discountPercent: 18),
    PromotionRecord(id: 'travel-offer-1', serviceId: 'travel', providerId: 'travel-1', title: 'خصم 15% على تذاكر مختارة', imagePath: 'assets/Services images/سفريات وسياحة.jpg', discountPercent: 15),
    PromotionRecord(id: 'travel-offer-2', serviceId: 'travel', providerId: 'travel-2', title: 'متابعة التأشيرة مجاناً', imagePath: 'assets/Services images/سفريات وسياحة.jpg', discountPercent: 10),
    PromotionRecord(id: 'travel-offer-3', serviceId: 'travel', providerId: 'travel-3', title: 'عرض معاملات الشركات', imagePath: 'assets/Services images/سفريات وسياحة.jpg', discountPercent: 20),
  ];

  final List<PaymentMethodRecord> paymentMethods = const [
    PaymentMethodRecord(id: 'jawali', name: 'جوالي', type: 'wallet'),
    PaymentMethodRecord(id: 'jeeb', name: 'جيب', type: 'wallet'),
    PaymentMethodRecord(id: 'floosk', name: 'فلوسك', type: 'wallet'),
    PaymentMethodRecord(id: 'onecash', name: 'ون كاش', type: 'wallet'),
    PaymentMethodRecord(id: 'alkuraimi', name: 'الكريمي جوال', type: 'wallet'),
    PaymentMethodRecord(id: 'shamel_money', name: 'الشامل موني', type: 'wallet'),
    PaymentMethodRecord(id: 'card', name: 'بطاقة ائتمان', type: 'card'),
    PaymentMethodRecord(id: 'cash', name: 'الدفع عند الاستلام', type: 'cash'),
  ];

  final List<DeliveryCategoryRecord> deliveryCategories = const [
    DeliveryCategoryRecord(id: 'market', name: 'سوبر ماركت', iconKey: 'cart'),
    DeliveryCategoryRecord(id: 'beauty', name: 'العطور وأدوات التجميل', iconKey: 'spa'),
    DeliveryCategoryRecord(id: 'fashion', name: 'ملابس ومفروشات', iconKey: 'fashion'),
    DeliveryCategoryRecord(id: 'spices', name: 'بهارات وأعشاب', iconKey: 'nature'),
    DeliveryCategoryRecord(id: 'meat', name: 'اللحوم والدواجن', iconKey: 'food'),
    DeliveryCategoryRecord(id: 'bakery', name: 'مخبوزات وحلويات', iconKey: 'bakery'),
    DeliveryCategoryRecord(id: 'gifts', name: 'هدايا وورود', iconKey: 'gift'),
    DeliveryCategoryRecord(id: 'stationery', name: 'مكتبات وقرطاسية', iconKey: 'book'),
    DeliveryCategoryRecord(id: 'produce', name: 'الخضروات والفواكه', iconKey: 'produce'),
    DeliveryCategoryRecord(id: 'home', name: 'الأدوات المنزلية', iconKey: 'home'),
    DeliveryCategoryRecord(id: 'pharmacy', name: 'صيدليات', iconKey: 'pharmacy'),
    DeliveryCategoryRecord(id: 'building', name: 'الكهرباء ومواد بناء', iconKey: 'building'),
    DeliveryCategoryRecord(id: 'appliances', name: 'الأجهزة الكهربائية', iconKey: 'devices'),
    DeliveryCategoryRecord(id: 'online', name: 'المتاجر الإلكترونية', iconKey: 'store'),
    DeliveryCategoryRecord(id: 'cars', name: 'تجهيز الكوش وزينة السيارات', iconKey: 'car'),
    DeliveryCategoryRecord(id: 'computers', name: 'الكمبيوترات ومستلزماتها', iconKey: 'computer'),
    DeliveryCategoryRecord(id: 'other', name: 'احتياجات أخرى', iconKey: 'other'),
  ];

  final List<DeliveryStoreRecord> deliveryStores = const [
    DeliveryStoreRecord(id: 'delivery-store-1', categoryId: 'all', provinceId: 'all', name: 'هايبر سما مول', address: 'وسط المدينة', imagePath: 'assets/images/quick_delivery_banner.png', rating: 4.9),
    DeliveryStoreRecord(id: 'delivery-store-2', categoryId: 'all', provinceId: 'all', name: 'متجر المدينة', address: 'الشارع الرئيسي', imagePath: 'assets/images/quick_delivery_banner.png', rating: 4.8),
    DeliveryStoreRecord(id: 'delivery-store-3', categoryId: 'all', provinceId: 'all', name: 'متجر الوفاء', address: 'جولة المصباحي', imagePath: 'assets/images/quick_delivery_banner.png', rating: 4.7),
    DeliveryStoreRecord(id: 'delivery-store-4', categoryId: 'all', provinceId: 'all', name: 'سوق الخير', address: 'شارع تعز', imagePath: 'assets/images/quick_delivery_banner.png', rating: 4.6),
  ];

  @override
  Future<List<ProvinceRecord>> getProvinces() async =>
      provinces.where((item) => item.enabled).toList();
  @override
  Future<List<ServiceRecord>> getServices(String provinceId) async =>
      services.where((item) => item.enabled).toList();
  @override
  Future<List<ProviderRecord>> getProviders({
    required String provinceId,
    required String serviceId,
  }) async => providers
      .where(
        (item) =>
            item.enabled &&
            item.serviceId == serviceId &&
            (item.provinceId == 'all' || item.provinceId == provinceId),
      )
      .toList();
  @override
  Future<List<PromotionRecord>> getPromotions({
    String? provinceId,
    String? serviceId,
  }) async => promotions
      .where(
        (item) =>
            item.enabled && (serviceId == null || item.serviceId == serviceId),
      )
      .toList();
  @override
  Future<List<PaymentMethodRecord>> getPaymentMethods() async =>
      paymentMethods.where((item) => item.enabled).toList();
  @override
  Future<List<DeliveryCategoryRecord>> getDeliveryCategories() async =>
      deliveryCategories.where((item) => item.enabled).toList();
  @override
  Future<List<DeliveryStoreRecord>> getDeliveryStores({
    required String provinceId,
    required String categoryId,
    String query = '',
  }) async => deliveryStores
      .where(
        (item) =>
            item.enabled &&
            (item.categoryId == 'all' || item.categoryId == categoryId) &&
            (item.provinceId == 'all' || item.provinceId == provinceId) &&
            (query.isEmpty ||
                item.name.contains(query) ||
                item.address.contains(query)),
      )
      .toList();
  @override
  Future<void> createBooking(BookingRecord booking) async {}
  @override
  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    Map<String, dynamic>? metadata,
  }) async {}
}

/// مصدر محلي مشترك تستخدمه الواجهات الآن، ويُستبدل بتنفيذ API عند جاهزية الخادم.
final localControlPanelRepository = LocalControlPanelRepository();
