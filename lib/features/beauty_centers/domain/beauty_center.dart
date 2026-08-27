class BeautyService {
  const BeautyService({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
    required this.iconName,
    this.expectedSessions = 'جلسة واحدة',
    this.resultSummary = 'نتائج تدريجية حسب تقييم المختص',
  });

  final String id;
  final String name;
  final String category;
  final int durationMinutes;
  final int price;
  final String iconName;
  final String expectedSessions;
  final String resultSummary;
}

class BeautyCenter {
  const BeautyCenter({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.features,
    required this.specialists,
    required this.services,
  });

  final String id;
  final String name;
  final String city;
  final String district;
  final double rating;
  final int reviews;
  final String description;
  final List<String> features;
  final List<String> specialists;
  final List<BeautyService> services;
}

const _coreBeautyServices = <BeautyService>[
  BeautyService(
    id: 'rhinoplasty-consultation',
    name: 'استشارة تجميل الأنف',
    category: 'الجراحة التجميلية',
    durationMinutes: 45,
    price: 20000,
    iconName: 'face',
    expectedSessions: 'استشارة + متابعة',
    resultSummary: 'خطة علاجية يحددها الجراح',
  ),
  BeautyService(
    id: 'face-lift-consultation',
    name: 'استشارة شد الوجه',
    category: 'الجراحة التجميلية',
    durationMinutes: 50,
    price: 25000,
    iconName: 'face',
    expectedSessions: 'استشارة + فحوصات',
    resultSummary: 'تقييم شامل وخطة مخصصة',
  ),
  BeautyService(
    id: 'deep-cleansing',
    name: 'تنظيف عميق للبشرة',
    category: 'العناية بالبشرة والشعر',
    durationMinutes: 60,
    price: 12000,
    iconName: 'face',
  ),
  BeautyService(
    id: 'hydrafacial',
    name: 'جلسة هيدرافيشل',
    category: 'العناية بالبشرة والشعر',
    durationMinutes: 75,
    price: 18000,
    iconName: 'spa',
  ),
  BeautyService(
    id: 'hair-care',
    name: 'عناية متكاملة بالشعر',
    category: 'العناية بالبشرة والشعر',
    durationMinutes: 90,
    price: 15000,
    iconName: 'hair',
  ),
  BeautyService(
    id: 'massage',
    name: 'مساج واسترخاء',
    category: 'العناية بالبشرة والشعر',
    durationMinutes: 60,
    price: 20000,
    iconName: 'massage',
  ),
  BeautyService(
    id: 'laser',
    name: 'جلسة إزالة الشعر بالليزر',
    category: 'الجلدية',
    durationMinutes: 45,
    price: 25000,
    iconName: 'laser',
  ),
  BeautyService(
    id: 'nails',
    name: 'عناية بالأظافر',
    category: 'العناية بالبشرة والشعر',
    durationMinutes: 50,
    price: 9000,
    iconName: 'nails',
  ),
  BeautyService(
    id: 'acne-treatment',
    name: 'علاج آثار حب الشباب',
    category: 'الجلدية',
    durationMinutes: 60,
    price: 22000,
    iconName: 'laser',
    expectedSessions: '3–6 جلسات',
    resultSummary: 'تحسين الملمس وتوحيد البشرة',
  ),
];

const beautyCenters = <BeautyCenter>[
  BeautyCenter(
    id: 'lavender-sanaa',
    name: 'مركز لافندر للتجميل والعناية',
    city: 'صنعاء',
    district: 'شارع حدة',
    rating: 4.9,
    reviews: 186,
    description:
        'مركز متخصص للعناية بالبشرة والشعر والليزر، يقدم خدماته بأجهزة حديثة وعلى أيدي مختصين معتمدين ضمن بيئة مريحة وآمنة.',
    features: ['مختصون معتمدون', 'أجهزة حديثة', 'غرف خاصة', 'تعقيم مستمر'],
    specialists: ['د. سارة أحمد', 'أ. ريم خالد', 'د. محمود علي'],
    services: _coreBeautyServices,
  ),
  BeautyCenter(
    id: 'rosa-aden',
    name: 'مركز روزا سبا',
    city: 'عدن',
    district: 'خور مكسر',
    rating: 4.8,
    reviews: 142,
    description:
        'سبا عصري للعناية والاسترخاء يقدم جلسات البشرة والمساج والعناية بالشعر بمنتجات موثوقة وخدمة احترافية.',
    features: ['سبا متكامل', 'منتجات أصلية', 'خصوصية تامة', 'مواقف متاحة'],
    specialists: ['أ. هبة سالم', 'أ. منى أحمد', 'أ. نجلاء حسن'],
    services: _coreBeautyServices,
  ),
  BeautyCenter(
    id: 'beauty-touch-ibb',
    name: 'مركز لمسة جمال',
    city: 'إب',
    district: 'الدائري الغربي',
    rating: 4.7,
    reviews: 118,
    description:
        'وجهة متكاملة لخدمات العناية اليومية والمناسبات، مع باقات متنوعة وأسعار مناسبة وحجز سريع للمواعيد.',
    features: ['باقات متنوعة', 'أسعار مناسبة', 'خدمة سريعة', 'تعقيم مستمر'],
    specialists: ['أ. أمل يحيى', 'أ. نور محمد', 'أ. سماح علي'],
    services: _coreBeautyServices,
  ),
  BeautyCenter(
    id: 'aura-hadramout',
    name: 'مركز أورا للتجميل',
    city: 'حضرموت',
    district: 'المكلا',
    rating: 4.8,
    reviews: 96,
    description:
        'مركز راقٍ يقدم حلول العناية بالبشرة والشعر وتقنيات الليزر الحديثة مع استشارات متخصصة قبل كل جلسة.',
    features: ['استشارة مجانية', 'تقنيات حديثة', 'مختصون معتمدون', 'دعم مستمر'],
    specialists: ['د. أروى باوزير', 'أ. إيمان خالد', 'د. أحمد عمر'],
    services: _coreBeautyServices,
  ),
];
