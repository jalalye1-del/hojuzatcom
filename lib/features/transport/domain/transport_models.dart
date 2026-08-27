import '../../../core/localization/app_locale.dart';

enum TransportCategory { carRental, passengerTransport, freight }

extension TransportCategoryDetails on TransportCategory {
  String get label => switch (this) {
    TransportCategory.carRental => l10n('تأجير سيارات', 'Car rental'),
    TransportCategory.passengerTransport => l10n(
      'النقل البري',
      'Land passenger transport',
    ),
    TransportCategory.freight => l10n('الشحن الداخلي', 'Local freight'),
  };

  String get description => switch (this) {
    TransportCategory.carRental => l10n(
      'سيارات متنوعة لجميع احتياجاتك',
      'A diverse fleet for every need',
    ),
    TransportCategory.passengerTransport => l10n(
      'رحلات آمنة ومريحة بين المدن',
      'Safe and comfortable intercity trips',
    ),
    TransportCategory.freight => l10n(
      'شحن سريع وآمن لمختلف البضائع',
      'Fast and secure freight service',
    ),
  };

  String get bookingPrefix => switch (this) {
    TransportCategory.carRental => 'CR',
    TransportCategory.passengerTransport => 'PT',
    TransportCategory.freight => 'FR',
  };
}

class TransportListing {
  const TransportListing({
    required this.id,
    required this.category,
    required this.title,
    required this.provider,
    required this.city,
    required this.price,
    required this.priceUnit,
    required this.rating,
    required this.reviews,
    required this.capacity,
    required this.description,
    required this.features,
  });

  final String id;
  final TransportCategory category;
  final String title;
  final String provider;
  final String city;
  final int price;
  final String priceUnit;
  final double rating;
  final int reviews;
  final String capacity;
  final String description;
  final List<String> features;
}

const transportListings = <TransportListing>[
  TransportListing(
    id: 'toyota-land-cruiser',
    category: TransportCategory.carRental,
    title: 'تويوتا لاندكروزر 2025',
    provider: 'أسطول حجوزاتكم للسيارات',
    city: 'صنعاء',
    price: 45000,
    priceUnit: 'اليوم',
    rating: 4.9,
    reviews: 164,
    capacity: '7 ركاب',
    description:
        'سيارة دفع رباعي فاخرة ومجهزة للرحلات داخل المدينة وخارجها، مع تأمين شامل وخدمة مساعدة على مدار الساعة.',
    features: ['تأمين شامل', 'ناقل أوتوماتيك', 'مكيف', 'كيلومترات مفتوحة'],
  ),
  TransportListing(
    id: 'hyundai-accent',
    category: TransportCategory.carRental,
    title: 'هيونداي أكسنت اقتصادية',
    provider: 'المدينة لتأجير السيارات',
    city: 'عدن',
    price: 22000,
    priceUnit: 'اليوم',
    rating: 4.7,
    reviews: 118,
    capacity: '5 ركاب',
    description:
        'سيارة اقتصادية حديثة مناسبة للتنقل اليومي، موفرة للوقود ومتاحة بخيارات استلام وتسليم مرنة.',
    features: ['اقتصادية', 'مكيف', 'توصيل للموقع', 'تأمين أساسي'],
  ),
  TransportListing(
    id: 'kia-carnival',
    category: TransportCategory.carRental,
    title: 'كيا كرنفال عائلية',
    provider: 'المسافر لتأجير السيارات',
    city: 'حضرموت',
    price: 35000,
    priceUnit: 'اليوم',
    rating: 4.8,
    reviews: 91,
    capacity: '8 ركاب',
    description:
        'سيارة عائلية واسعة ومريحة للرحلات الطويلة مع مساحة أمتعة كبيرة ومقاعد مرنة.',
    features: ['مناسبة للعائلات', 'مساحة أمتعة', 'شاحن USB', 'تأمين شامل'],
  ),
  TransportListing(
    id: 'sanaa-aden-vip',
    category: TransportCategory.passengerTransport,
    title: 'رحلة صنعاء - عدن VIP',
    provider: 'حجوزاتكم للنقل البري',
    city: 'صنعاء',
    price: 18000,
    priceUnit: 'المقعد',
    rating: 4.9,
    reviews: 236,
    capacity: 'حافلة 32 راكباً',
    description:
        'رحلة مباشرة ومريحة بين صنعاء وعدن بحافلة حديثة ومقاعد واسعة، مع نقاط توقف منظمة وتتبع مباشر.',
    features: ['مقاعد مريحة', 'تكييف', 'تتبع مباشر', 'أمتعة مجانية'],
  ),
  TransportListing(
    id: 'aden-mukalla-express',
    category: TransportCategory.passengerTransport,
    title: 'رحلة عدن - المكلا السريعة',
    provider: 'الطريق الآمن للنقل',
    city: 'عدن',
    price: 22000,
    priceUnit: 'المقعد',
    rating: 4.8,
    reviews: 147,
    capacity: 'حافلة 28 راكباً',
    description:
        'نقل بري يومي بين عدن والمكلا مع سائقين معتمدين وجدول انطلاق ثابت وخدمة عملاء مستمرة.',
    features: ['رحلات يومية', 'سائقون معتمدون', 'واي فاي', 'تأمين ركاب'],
  ),
  TransportListing(
    id: 'private-city-transfer',
    category: TransportCategory.passengerTransport,
    title: 'نقل خاص داخل وخارج المدينة',
    provider: 'مشاوير اليمن',
    city: 'جميع المدن',
    price: 12000,
    priceUnit: 'الرحلة',
    rating: 4.7,
    reviews: 192,
    capacity: 'حتى 6 ركاب',
    description:
        'سيارة خاصة مع سائق لنقلك من وإلى المطار أو بين المدن بمرونة وخصوصية كاملة.',
    features: ['متاح 24/7', 'سائق خاص', 'استقبال المطار', 'سعر ثابت'],
  ),
  TransportListing(
    id: 'medium-truck-city',
    category: TransportCategory.freight,
    title: 'شاحنة متوسطة للنقل الداخلي',
    provider: 'الأمان للشحن والنقل',
    city: 'صنعاء',
    price: 30000,
    priceUnit: 'الحمولة',
    rating: 4.8,
    reviews: 129,
    capacity: 'حتى 5 أطنان',
    description:
        'شاحنة مغلقة لنقل الأثاث والبضائع داخل المدينة مع فريق تحميل وتتبع للشحنة حتى التسليم.',
    features: ['تتبع الشحنة', 'فريق تحميل', 'تأمين البضائع', 'تغليف اختياري'],
  ),
  TransportListing(
    id: 'refrigerated-cargo',
    category: TransportCategory.freight,
    title: 'نقل مبرد للمواد الغذائية',
    provider: 'سلسلة التبريد اليمنية',
    city: 'عدن',
    price: 55000,
    priceUnit: 'الحمولة',
    rating: 4.9,
    reviews: 87,
    capacity: 'حتى 8 أطنان',
    description:
        'نقل مبرد بدرجات حرارة مراقبة للمواد الغذائية والأدوية مع توثيق الاستلام والتسليم.',
    features: ['تبريد مراقب', 'تأمين شامل', 'تتبع مباشر', 'تسليم موثق'],
  ),
  TransportListing(
    id: 'pickup-light-cargo',
    category: TransportCategory.freight,
    title: 'بيك أب للشحنات الخفيفة',
    provider: 'وصلني للشحن السريع',
    city: 'إب',
    price: 15000,
    priceUnit: 'الرحلة',
    rating: 4.7,
    reviews: 153,
    capacity: 'حتى طن واحد',
    description:
        'خدمة سريعة للشحنات الخفيفة ونقل المشتريات والأثاث الصغير داخل المدينة والمناطق القريبة.',
    features: ['حجز فوري', 'سعر اقتصادي', 'مساعدة تحميل', 'تتبع السائق'],
  ),
];
