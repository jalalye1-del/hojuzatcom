import '../../../core/localization/app_locale.dart';

enum TravelCategory { flights, touristVisa, workVisa, administrative }

extension TravelCategoryDetails on TravelCategory {
  String get label => switch (this) {
    TravelCategory.flights => l10n('تذاكر طيران', 'Flight tickets'),
    TravelCategory.touristVisa => l10n('فيز سياحة', 'Tourist visas'),
    TravelCategory.workVisa => l10n('فيز عمل', 'Work visas'),
    TravelCategory.administrative => l10n('معاملات إدارية', 'Administrative services'),
  };

  String get description => switch (this) {
    TravelCategory.flights => l10n(
      'رحلات داخلية ودولية بأفضل الأسعار',
      'Domestic and international flights at great prices',
    ),
    TravelCategory.touristVisa => l10n(
      'تأشيرات سياحية مع متابعة كاملة',
      'Tourist visas with complete follow-up',
    ),
    TravelCategory.workVisa => l10n(
      'خدمات تأشيرات وفرص العمل',
      'Work visa and employment services',
    ),
    TravelCategory.administrative => l10n(
      'إنجاز المعاملات والوثائق الرسمية',
      'Official documents and administrative services',
    ),
  };

  String get bookingPrefix => switch (this) {
    TravelCategory.flights => 'FL',
    TravelCategory.touristVisa => 'TV',
    TravelCategory.workVisa => 'WV',
    TravelCategory.administrative => 'AD',
  };
}

class TravelListing {
  const TravelListing({
    required this.id,
    required this.category,
    required this.title,
    required this.provider,
    required this.destination,
    required this.price,
    required this.priceUnit,
    required this.rating,
    required this.reviews,
    required this.processingTime,
    required this.description,
    required this.features,
    required this.requirements,
  });

  final String id;
  final TravelCategory category;
  final String title;
  final String provider;
  final String destination;
  final int price;
  final String priceUnit;
  final double rating;
  final int reviews;
  final String processingTime;
  final String description;
  final List<String> features;
  final List<String> requirements;
}

const travelListings = <TravelListing>[
  TravelListing(
    id: 'sanaa-dubai-flight',
    category: TravelCategory.flights,
    title: 'رحلة صنعاء - دبي',
    provider: 'الخطوط الجوية اليمنية',
    destination: 'دبي، الإمارات',
    price: 185000,
    priceUnit: 'للمسافر',
    rating: 4.8,
    reviews: 238,
    processingTime: 'رحلة مباشرة • ساعتان و45 دقيقة',
    description:
        'حجز مرن لرحلة مباشرة من صنعاء إلى دبي مع أمتعة مشمولة وخيارات متعددة لتعديل الموعد واختيار المقعد.',
    features: ['أمتعة 30 كجم', 'وجبة مجانية', 'اختيار المقعد', 'تعديل مرن'],
    requirements: ['جواز سفر ساري', 'تأشيرة دخول صالحة', 'بيانات المسافر'],
  ),
  TravelListing(
    id: 'aden-cairo-flight',
    category: TravelCategory.flights,
    title: 'رحلة عدن - القاهرة',
    provider: 'طيران السعيدة',
    destination: 'القاهرة، مصر',
    price: 142000,
    priceUnit: 'للمسافر',
    rating: 4.7,
    reviews: 174,
    processingTime: 'رحلة مباشرة • 3 ساعات',
    description:
        'رحلة مباشرة من مطار عدن إلى القاهرة مع حقيبة شحن ووجبة وخدمة دعم قبل موعد السفر.',
    features: ['أمتعة 25 كجم', 'رحلة مباشرة', 'دعم المسافر', 'سعر شامل'],
    requirements: ['جواز سفر ساري', 'تأشيرة مصر', 'بيانات التواصل'],
  ),
  TravelListing(
    id: 'mukalla-jeddah-flight',
    category: TravelCategory.flights,
    title: 'رحلة المكلا - جدة',
    provider: 'الخطوط الجوية اليمنية',
    destination: 'جدة، السعودية',
    price: 128000,
    priceUnit: 'للمسافر',
    rating: 4.8,
    reviews: 151,
    processingTime: 'رحلة مباشرة • ساعتان',
    description:
        'حجز رحلة مباشرة من المكلا إلى جدة بخيارات درجات سفر متعددة وخدمة تأكيد فوري.',
    features: ['تأكيد فوري', 'أمتعة 30 كجم', 'درجات متعددة', 'وجبة مجانية'],
    requirements: ['جواز سفر ساري', 'تأشيرة دخول', 'بيانات المسافر'],
  ),
  TravelListing(
    id: 'uae-tourist-visa',
    category: TravelCategory.touristVisa,
    title: 'تأشيرة الإمارات السياحية',
    provider: 'حجوزاتكم للسفر والسياحة',
    destination: 'الإمارات العربية المتحدة',
    price: 75000,
    priceUnit: 'للطلب',
    rating: 4.9,
    reviews: 312,
    processingTime: '3 - 5 أيام عمل',
    description:
        'خدمة تجهيز ومتابعة طلب التأشيرة السياحية للإمارات مع مراجعة الوثائق قبل التقديم وإشعارات مستمرة لحالة الطلب.',
    features: ['مراجعة مجانية', 'متابعة مباشرة', 'دعم 24/7', 'تحديثات فورية'],
    requirements: ['صورة الجواز', 'صورة شخصية', 'حجز مبدئي', 'بيانات التواصل'],
  ),
  TravelListing(
    id: 'turkey-tourist-visa',
    category: TravelCategory.touristVisa,
    title: 'تأشيرة تركيا السياحية',
    provider: 'بوابة العالم للسياحة',
    destination: 'تركيا',
    price: 95000,
    priceUnit: 'للطلب',
    rating: 4.8,
    reviews: 204,
    processingTime: '7 - 12 يوم عمل',
    description:
        'إعداد ملف التأشيرة السياحية لتركيا، حجز الموعد، مراجعة الوثائق ومتابعة الطلب حتى صدور النتيجة.',
    features: ['حجز الموعد', 'ترجمة الوثائق', 'مراجعة الملف', 'متابعة الطلب'],
    requirements: ['جواز سفر', 'كشف حساب', 'صور شخصية', 'إثبات عمل'],
  ),
  TravelListing(
    id: 'saudi-work-visa',
    category: TravelCategory.workVisa,
    title: 'تأشيرة عمل إلى السعودية',
    provider: 'الإنجاز لخدمات العمل',
    destination: 'المملكة العربية السعودية',
    price: 165000,
    priceUnit: 'للمعاملة',
    rating: 4.9,
    reviews: 265,
    processingTime: '10 - 20 يوم عمل',
    description:
        'تجهيز ومتابعة معاملة تأشيرة العمل إلى السعودية، بما يشمل تدقيق العقد والوثائق وحجز الفحص الطبي.',
    features: ['تدقيق العقد', 'حجز الفحص', 'متابعة السفارة', 'دعم قانوني'],
    requirements: ['عقد العمل', 'جواز سفر', 'مؤهل دراسي', 'فحص طبي'],
  ),
  TravelListing(
    id: 'uae-work-visa',
    category: TravelCategory.workVisa,
    title: 'إقامة وتأشيرة عمل الإمارات',
    provider: 'فرص الخليج للسفريات',
    destination: 'الإمارات العربية المتحدة',
    price: 210000,
    priceUnit: 'للمعاملة',
    rating: 4.8,
    reviews: 189,
    processingTime: '12 - 25 يوم عمل',
    description:
        'خدمة متكاملة لمتابعة تصريح العمل والإقامة الإماراتية بالتنسيق مع جهة العمل ومراكز الفحص المعتمدة.',
    features: ['تصريح العمل', 'فحص طبي', 'متابعة الإقامة', 'تحديثات مستمرة'],
    requirements: ['عرض العمل', 'جواز سفر', 'صور شخصية', 'المؤهلات'],
  ),
  TravelListing(
    id: 'passport-renewal',
    category: TravelCategory.administrative,
    title: 'متابعة إصدار وتجديد جواز السفر',
    provider: 'مكتب حجوزاتكم للمعاملات',
    destination: 'الجهات الحكومية المختصة',
    price: 35000,
    priceUnit: 'للمعاملة',
    rating: 4.8,
    reviews: 221,
    processingTime: '5 - 10 أيام عمل',
    description:
        'مراجعة وتجهيز ملف إصدار أو تجديد جواز السفر ومتابعة المعاملة حتى الاستلام وفق الإجراءات الرسمية.',
    features: [
      'تدقيق الوثائق',
      'حجز الموعد',
      'متابعة المعاملة',
      'إشعار بالاستلام',
    ],
    requirements: ['الهوية', 'الجواز السابق', 'صور شخصية', 'استمارة الطلب'],
  ),
  TravelListing(
    id: 'document-attestation',
    category: TravelCategory.administrative,
    title: 'تصديق وترجمة الوثائق الرسمية',
    provider: 'المعتمد للخدمات الإدارية',
    destination: 'الخارجية والسفارات',
    price: 28000,
    priceUnit: 'للوثيقة',
    rating: 4.7,
    reviews: 176,
    processingTime: '3 - 7 أيام عمل',
    description:
        'ترجمة وتصديق الشهادات والعقود والوثائق الرسمية لدى الجهات المختصة والسفارات مع تتبع كامل.',
    features: ['ترجمة معتمدة', 'تصديق الخارجية', 'متابعة السفارة', 'تسليم آمن'],
    requirements: [
      'أصل الوثيقة',
      'صورة الهوية',
      'جهة الاستخدام',
      'تفويض العميل',
    ],
  ),
];
