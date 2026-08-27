class Apartment {
  const Apartment({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.city,
    required this.pricePerNight,
    required this.oldPrice,
    required this.rating,
    required this.reviews,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.floor,
    required this.unitType,
    required this.description,
    required this.features,
    required this.amenities,
    required this.utilities,
  });

  final String id;
  final String name;
  final String neighborhood;
  final String city;
  final int pricePerNight;
  final int oldPrice;
  final double rating;
  final int reviews;
  final int bedrooms;
  final int bathrooms;
  final int area;
  final String floor;
  final String unitType;
  final String description;
  final List<String> features;
  final List<String> amenities;
  final Map<String, bool> utilities;
}

const apartments = <Apartment>[
  Apartment(
    id: 'nuqum-modern',
    name: 'شقة مودرن بإطلالة جبل نقم',
    neighborhood: 'نقم',
    city: 'صنعاء',
    pricePerNight: 18000,
    oldPrice: 22500,
    rating: 4.7,
    reviews: 132,
    bedrooms: 2,
    bathrooms: 2,
    area: 145,
    floor: 'الطابق السادس',
    unitType: 'متوسطة',
    description:
        'شقة حديثة وهادئة بإطلالة مباشرة على جبل نقم، مفروشة بأثاث راقٍ ومجهزة بكل ما تحتاجه لإقامة مريحة وآمنة.',
    features: ['صالة واسعة', 'مطبخ مجهز', 'واي فاي مجاني', 'موقف خاص'],
    amenities: [
      'مطبخ مجهز',
      'تلفزيون ذكي',
      'غسالة ملابس',
      'تكييف مركزي',
      'مصعد',
      'إنترنت سريع',
      'مياه ساخنة',
      'خدمة تنظيف',
    ],
    utilities: {
      'الماء': true,
      'الكهرباء': true,
      'الهاتف': false,
      'النظافة الداخلية': true,
      'الإنترنت': true,
      'الغاز': true,
    },
  ),
  Apartment(
    id: 'hadda-luxury',
    name: 'شقة فاخرة في شارع حدة',
    neighborhood: 'حدة',
    city: 'صنعاء',
    pricePerNight: 25000,
    oldPrice: 29000,
    rating: 4.8,
    reviews: 96,
    bedrooms: 3,
    bathrooms: 2,
    area: 175,
    floor: 'الطابق الرابع',
    unitType: 'عائلية',
    description:
        'شقة فاخرة مناسبة للعائلات في قلب شارع حدة، قريبة من المطاعم والخدمات ومجهزة بأثاث عصري متكامل.',
    features: ['3 غرف نوم', 'مجلس عائلي', 'مطبخ مجهز', 'حراسة'],
    amenities: [
      'مطبخ مجهز',
      'تلفزيون ذكي',
      'غسالة ملابس',
      'تكييف مركزي',
      'مصعد',
      'إنترنت سريع',
      'موقف خاص',
      'خدمة تنظيف',
    ],
    utilities: {
      'الماء': true,
      'الكهرباء': true,
      'الهاتف': true,
      'النظافة الداخلية': true,
      'الإنترنت': true,
      'الغاز': true,
    },
  ),
  Apartment(
    id: 'bait-baws-family',
    name: 'شقة عائلية واسعة',
    neighborhood: 'بيت بوس',
    city: 'صنعاء',
    pricePerNight: 21000,
    oldPrice: 24000,
    rating: 4.7,
    reviews: 84,
    bedrooms: 3,
    bathrooms: 3,
    area: 190,
    floor: 'الطابق الثالث',
    unitType: 'صغيرة',
    description:
        'شقة عائلية رحبة في منطقة هادئة، توفر الخصوصية ومساحات مريحة مع جميع الخدمات الأساسية للإقامات القصيرة والطويلة.',
    features: ['مناسبة للعائلات', '3 حمامات', 'موقف خاص', 'دخول ذاتي'],
    amenities: [
      'مطبخ مجهز',
      'تلفزيون ذكي',
      'غسالة ملابس',
      'تكييف',
      'إنترنت سريع',
      'مياه ساخنة',
      'موقف خاص',
      'دخول ذاتي',
    ],
    utilities: {
      'الماء': true,
      'الكهرباء': true,
      'الهاتف': false,
      'النظافة الداخلية': false,
      'الإنترنت': true,
      'الغاز': true,
    },
  ),
  Apartment(
    id: 'aden-seaview',
    name: 'شقة بإطلالة بحرية',
    neighborhood: 'خور مكسر',
    city: 'عدن',
    pricePerNight: 28000,
    oldPrice: 32000,
    rating: 4.9,
    reviews: 117,
    bedrooms: 2,
    bathrooms: 2,
    area: 155,
    floor: 'الطابق الخامس',
    unitType: 'استوديو',
    description:
        'شقة مفروشة بإطلالة بحرية جميلة وقريبة من المطار والخدمات، مثالية لرحلات العمل والإقامات العائلية.',
    features: ['إطلالة بحرية', 'قرب المطار', 'دخول ذاتي', 'موقف خاص'],
    amenities: [
      'مطبخ مجهز',
      'تلفزيون ذكي',
      'غسالة ملابس',
      'تكييف مركزي',
      'مصعد',
      'إنترنت سريع',
      'مياه ساخنة',
      'خدمة تنظيف',
    ],
    utilities: {
      'الماء': true,
      'الكهرباء': true,
      'الهاتف': false,
      'النظافة الداخلية': true,
      'الإنترنت': true,
      'الغاز': false,
    },
  ),
];
