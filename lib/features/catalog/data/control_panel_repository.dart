import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

class SupportConfigRecord {
  const SupportConfigRecord({
    required this.title,
    required this.subtitle,
    required this.whatsappNumbers,
    required this.callNumbers,
    required this.address,
  });
  final String title;
  final String subtitle;
  final List<String> whatsappNumbers;
  final List<String> callNumbers;
  final String address;
}

class NotificationRuleRecord {
  const NotificationRuleRecord({
    required this.id,
    required this.event,
    required this.title,
    required this.body,
    this.enabled = true,
  });
  final String id;
  final String event;
  final String title;
  final String body;
  final bool enabled;
}

class BookableExtraRecord {
  const BookableExtraRecord({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.price,
    required this.iconKey,
    this.enabled = true,
  });
  final String id;
  final String serviceId;
  final String name;
  final int price;
  final String iconKey;
  final bool enabled;
}

/// صنف قابل للإدارة داخل كتالوج الخدمات الإضافية لقاعات المناسبات.
/// تُستبدل هذه السجلات لاحقاً ببيانات API/لوحة التحكم دون تعديل واجهة الحجز.
class HallAddonItemRecord {
  const HallAddonItemRecord({
    required this.id,
    required this.category,
    required this.name,
    required this.size,
    required this.unitPrice,
    this.enabled = true,
  });

  final String id;
  final String category;
  final String name;
  final String size;
  final int unitPrice;
  final bool enabled;
}

/// نقطة الربط الوحيدة لواجهة API/Firestore/لوحة التحكم لاحقاً.
abstract class ControlPanelRepository {
  Future<Map<String, dynamic>?> getEventServiceCatalog();
  Future<void> saveEventServiceCatalog(Map<String, dynamic> catalog);
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
  Future<List<HallAddonItemRecord>> getHallAddonItems(String category);
  Future<void> createBooking(BookingRecord booking);
  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    Map<String, dynamic>? metadata,
  });
}

/// بيانات محلية مؤقتة بنفس بنية API؛ تستبدل عند ربط لوحة التحكم.
class LocalControlPanelRepository implements ControlPanelRepository {
  static const _eventCatalogKey = 'event_centers_catalog_v2';

  @override
  Future<Map<String, dynamic>?> getEventServiceCatalog() async {
    final value = (await SharedPreferences.getInstance()).getString(_eventCatalogKey);
    return value == null ? null : Map<String, dynamic>.from(jsonDecode(value) as Map);
  }

  @override
  Future<void> saveEventServiceCatalog(Map<String, dynamic> catalog) async {
    final saved = await (await SharedPreferences.getInstance()).setString(_eventCatalogKey, jsonEncode(catalog));
    if (!saved) throw StateError('Could not save event catalog.');
  }
  final SupportConfigRecord supportConfig = const SupportConfigRecord(
    title: 'الدعم والخط الساخن',
    subtitle: 'اختر وسيلة التواصل المناسبة لك',
    whatsappNumbers: ['+967 777 000 001', '+967 777 000 002'],
    callNumbers: ['800 0001', '+967 1 500 500'],
    address: 'صنعاء، اليمن',
  );

  final List<NotificationRuleRecord> notificationRules = const [
    NotificationRuleRecord(
      id: 'interest',
      event: 'service_viewed',
      title: 'خدمة قد تهمك',
      body: 'سنبلغك بالعروض والتحديثات المتعلقة بالخدمات التي شاهدتها.',
    ),
    NotificationRuleRecord(
      id: 'availability',
      event: 'availability_requested',
      title: 'تنبيه التوفر',
      body: 'سيصلك إشعار فور توفر العنصر الذي طلبت متابعته.',
    ),
  ];

  final List<BookableExtraRecord> hotelRoomExtras = const [
    BookableExtraRecord(id: 'airport', serviceId: 'hotels', name: 'توصيل من المطار', price: 10000, iconKey: 'airport'),
    BookableExtraRecord(id: 'lunch', serviceId: 'hotels', name: 'وجبة الغداء', price: 6000, iconKey: 'restaurant'),
    BookableExtraRecord(id: 'sauna', serviceId: 'hotels', name: 'ساونا وجاكوزي', price: 2000, iconKey: 'spa'),
    BookableExtraRecord(id: 'gym', serviceId: 'hotels', name: 'صالة رياضية', price: 3000, iconKey: 'gym'),
    BookableExtraRecord(id: 'wellness', serviceId: 'hotels', name: 'منتجع صحي', price: 8000, iconKey: 'wellness'),
    BookableExtraRecord(id: 'pool', serviceId: 'hotels', name: 'مسبح', price: 2000, iconKey: 'pool'),
  ];

  final List<HallAddonItemRecord> hallAddonItems = const [
    HallAddonItemRecord(id: 'meal-crispy', category: 'وجبة ضيافة', name: 'سندوتش كريسبي بالجبن', size: 'صغير', unitPrice: 450),
    HallAddonItemRecord(id: 'meal-pizza', category: 'وجبة ضيافة', name: 'قطعة بيتزا بالخضار', size: 'صغير', unitPrice: 350),
    HallAddonItemRecord(id: 'meal-sweets', category: 'وجبة ضيافة', name: 'قطعتا حلوى مشكلة', size: 'وجبة', unitPrice: 250),
    HallAddonItemRecord(id: 'meal-royal', category: 'وجبة ضيافة', name: 'وجبة ضيافة ملكية', size: 'كبير', unitPrice: 900),
    HallAddonItemRecord(id: 'drink-pepsi', category: 'مشروبات غازية', name: 'بيبسي', size: '250 مل', unitPrice: 200),
    HallAddonItemRecord(id: 'drink-seven', category: 'مشروبات غازية', name: 'سفن أب', size: '250 مل', unitPrice: 200),
    HallAddonItemRecord(id: 'drink-mirinda', category: 'مشروبات غازية', name: 'ميرندا', size: '250 مل', unitPrice: 200),
    HallAddonItemRecord(id: 'drink-dew', category: 'مشروبات غازية', name: 'ديو', size: '250 مل', unitPrice: 220),
    HallAddonItemRecord(id: 'water-small', category: 'الماء والعصائر', name: 'مياه معدنية', size: '330 مل', unitPrice: 100),
    HallAddonItemRecord(id: 'juice-orange', category: 'الماء والعصائر', name: 'عصير برتقال', size: '250 مل', unitPrice: 300),
    HallAddonItemRecord(id: 'juice-mango', category: 'الماء والعصائر', name: 'عصير مانجو', size: '250 مل', unitPrice: 320),
    HallAddonItemRecord(id: 'juice-apple', category: 'الماء والعصائر', name: 'عصير تفاح', size: '250 مل', unitPrice: 300),
    HallAddonItemRecord(id: 'bag-paper', category: 'كيس الضيافة', name: 'كيس ورقي فاخر', size: 'متوسط', unitPrice: 250),
    HallAddonItemRecord(id: 'bag-printed', category: 'كيس الضيافة', name: 'كيس مطبوع', size: 'متوسط', unitPrice: 350),
    HallAddonItemRecord(id: 'bag-box', category: 'كيس الضيافة', name: 'علبة ضيافة', size: 'كبير', unitPrice: 500),
    HallAddonItemRecord(id: 'bag-cloth', category: 'كيس الضيافة', name: 'كيس قماشي', size: 'كبير', unitPrice: 650),
    HallAddonItemRecord(id: 'security-man', category: 'فريق أمن رجال', name: 'حارس أمن', size: 'فرد', unitPrice: 12000),
    HallAddonItemRecord(id: 'security-man-supervisor', category: 'فريق أمن رجال', name: 'مشرف أمن', size: 'فرد', unitPrice: 18000),
    HallAddonItemRecord(id: 'security-woman', category: 'فريق أمن نساء', name: 'حارسة أمن', size: 'فرد', unitPrice: 12000),
    HallAddonItemRecord(id: 'security-woman-supervisor', category: 'فريق أمن نساء', name: 'مشرفة أمن', size: 'فرد', unitPrice: 18000),
    HallAddonItemRecord(id: 'organizer', category: 'فريق تنظيم', name: 'منظم فعالية', size: 'فرد', unitPrice: 10000),
    HallAddonItemRecord(id: 'organizer-supervisor', category: 'فريق تنظيم', name: 'مشرف تنظيم', size: 'فرد', unitPrice: 16000),
    HallAddonItemRecord(id: 'dance-folk', category: 'فرقة رقص', name: 'فرقة شعبية', size: 'ساعة', unitPrice: 65000),
    HallAddonItemRecord(id: 'dance-zafat', category: 'فرقة رقص', name: 'فرقة زفات', size: 'ساعة', unitPrice: 80000),
    HallAddonItemRecord(id: 'hospitality-host', category: 'فريق ضيافة', name: 'مضيف', size: 'فرد', unitPrice: 9000),
    HallAddonItemRecord(id: 'hospitality-supervisor', category: 'فريق ضيافة', name: 'مشرف ضيافة', size: 'فرد', unitPrice: 14000),
    HallAddonItemRecord(id: 'photo-photographer', category: 'التصوير الفوتوغرافي', name: 'مصور فوتوغرافي', size: 'ساعة', unitPrice: 25000),
    HallAddonItemRecord(id: 'photo-video', category: 'التصوير الفوتوغرافي', name: 'مصور فيديو', size: 'ساعة', unitPrice: 35000),
    HallAddonItemRecord(id: 'photo-album', category: 'التصوير الفوتوغرافي', name: 'ألبوم مطبوع', size: 'نسخة', unitPrice: 30000),
    HallAddonItemRecord(id: 'sound-speaker', category: 'النظام الصوتي', name: 'مكبر صوت', size: 'قطعة', unitPrice: 30000),
    HallAddonItemRecord(id: 'sound-mixer', category: 'النظام الصوتي', name: 'مكسر صوت', size: 'جهاز', unitPrice: 80000),
    HallAddonItemRecord(id: 'sound-engineer', category: 'النظام الصوتي', name: 'مهندس صوت', size: 'ساعة', unitPrice: 20000),
    HallAddonItemRecord(id: 'sweet-cake', category: 'حلويات', name: 'قطع كيك', size: 'صغير', unitPrice: 100),
    HallAddonItemRecord(id: 'sweet-maamoul', category: 'حلويات', name: 'معمول فاخر', size: 'قطعة', unitPrice: 180),
    HallAddonItemRecord(id: 'sweet-chocolate', category: 'حلويات', name: 'شوكولاتة', size: 'قطعة', unitPrice: 250),
  ];
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
      imagePath: 'assets/images/محافظة عمران.jpg',
    ),
    ProvinceRecord(
      id: 'dhamar',
      name: 'ذمار',
      imagePath: 'assets/images/محافظة ذمار.jpg',
    ),
    ProvinceRecord(
      id: 'hadramawt',
      name: 'حضرموت',
      imagePath: 'assets/images/حضرموت.jpg',
    ),
    ProvinceRecord(
      id: 'hajjah',
      name: 'حجة',
      imagePath: 'assets/images/محافظة حجة.jpg',
    ),
    ProvinceRecord(
      id: 'ibb',
      name: 'إب',
      imagePath: 'assets/images/محافظة اب.jpg',
    ),
    ProvinceRecord(
      id: 'lahij',
      name: 'لحج',
      imagePath: 'assets/images/محافظة لحج.jpg',
    ),
    ProvinceRecord(
      id: 'marib',
      name: 'مأرب',
      imagePath: 'assets/images/محافظة مأرب.jpg',
    ),
    ProvinceRecord(
      id: 'raymah',
      name: 'ريمة',
      imagePath: 'assets/images/محافظة ريمة.jpg',
    ),
    ProvinceRecord(
      id: 'saada',
      name: 'صعدة',
      imagePath: 'assets/images/محافظة صعدة.jpg',
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
      imagePath: 'assets/images/محافظة شبوة.jpg',
    ),
    ProvinceRecord(id: 'taiz', name: 'تعز', imagePath: 'assets/images/محافظة تعز.jpg'),
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
      imagePath: 'assets/Services images/مطاعم.jpg',
    ),
    ServiceRecord(
      id: 'cars',
      name: 'تأجير سيارات ونقل',
      iconKey: 'car',
      imagePath: 'assets/Services images/تأجير السيارات والنقل الداخلي.jpg',
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
      imagePath: 'assets/Services images/الشقق المفروشة.jpg',
    ),
    ServiceRecord(
      id: 'halls',
      name: 'قاعات أفراح ومناسبات',
      iconKey: 'hall',
      imagePath: 'assets/Services images/قاعات الافراح والمناسبات.jpg',
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
  Future<List<HallAddonItemRecord>> getHallAddonItems(String category) async =>
      hallAddonItems
          .where((item) => item.enabled && item.category == category)
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
