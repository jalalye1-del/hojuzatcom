import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/reviews/service_review.dart';
import 'transport_tracking_card.dart';

const carRentalMasterBanner =
    'assets/images/transport_car_rental_master_banner.jpg';
const carRentalFallbackImage =
    'assets/Services images/تأجير السيارات والنقل الداخلي.jpg';

const _navy = Color(0xff0b2c57);
const _blue = Color(0xff155fc5);
const _gold = Color(0xffbc8638);
const _surface = Color(0xfffffaf3);
const _green = Color(0xff159a61);

String _money(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

BoxDecoration _card({double radius = 20}) => BoxDecoration(
  color: Colors.white.withValues(alpha: .96),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xffeee2d1)),
  boxShadow: const [
    BoxShadow(color: Color(0x1a0b2c57), blurRadius: 16, offset: Offset(0, 7)),
  ],
);

class RentalOffice {
  const RentalOffice(this.name, this.city, this.rating, this.fleet);
  final String name;
  final String city;
  final double rating;
  final int fleet;
}

class RentalCar {
  const RentalCar({
    required this.name,
    required this.model,
    required this.oldPrice,
    required this.price,
    required this.status,
    required this.specs,
  });
  final String name;
  final String model;
  final int oldPrice;
  final int price;
  final String status;
  final Map<String, String> specs;
}

const rentalOffices = [
  RentalOffice('إيلاف لتأجير السيارات', 'صنعاء', 4.9, 46),
  RentalOffice('المدينة لتأجير السيارات', 'عدن', 4.8, 35),
  RentalOffice('المسافر لتأجير السيارات', 'حضرموت', 4.8, 31),
  RentalOffice('النخبة لتأجير السيارات', 'تعز', 4.7, 28),
  RentalOffice('رويال كار', 'إب', 4.7, 24),
  RentalOffice('السعيدة لتأجير السيارات', 'الحديدة', 4.6, 22),
];

const rentalCars = [
  RentalCar(
    name: 'تويوتا لاندكروزر',
    model: '2025',
    oldPrice: 52000,
    price: 45000,
    status: 'جاهزة للتسليم',
    specs: {
      'النوع': 'SUV',
      'الموديل': '2025',
      'اللون': 'أبيض لؤلؤي',
      'المقاعد': '7',
      'الأبواب': '5',
      'الوقود': 'بنزين',
      'ناقل الحركة': 'أوتوماتيك',
      'التكييف': 'مزدوج',
      'الأمتعة': '4 حقائب',
    },
  ),
  RentalCar(
    name: 'مرسيدس S-Class',
    model: '2024',
    oldPrice: 68000,
    price: 59000,
    status: 'محجوزة',
    specs: {
      'النوع': 'سيدان فاخرة',
      'الموديل': '2024',
      'اللون': 'أسود',
      'المقاعد': '5',
      'الأبواب': '4',
      'الوقود': 'بنزين',
      'ناقل الحركة': 'أوتوماتيك',
      'التكييف': 'رباعي',
      'الأمتعة': '3 حقائب',
    },
  ),
  RentalCar(
    name: 'هيونداي توسان',
    model: '2025',
    oldPrice: 35000,
    price: 30000,
    status: 'جاهزة للتسليم',
    specs: {
      'النوع': 'كروس أوفر',
      'الموديل': '2025',
      'اللون': 'فضي',
      'المقاعد': '5',
      'الأبواب': '5',
      'الوقود': 'بنزين',
      'ناقل الحركة': 'أوتوماتيك',
      'التكييف': 'مزدوج',
      'الأمتعة': '3 حقائب',
    },
  ),
  RentalCar(
    name: 'تويوتا كامري',
    model: '2024',
    oldPrice: 31000,
    price: 27000,
    status: 'غير متوفرة',
    specs: {
      'النوع': 'سيدان',
      'الموديل': '2024',
      'اللون': 'أبيض',
      'المقاعد': '5',
      'الأبواب': '4',
      'الوقود': 'هجين',
      'ناقل الحركة': 'أوتوماتيك',
      'التكييف': 'مزدوج',
      'الأمتعة': '3 حقائب',
    },
  ),
  RentalCar(
    name: 'كيا كرنفال',
    model: '2025',
    oldPrice: 44000,
    price: 38000,
    status: 'جاهزة للتسليم',
    specs: {
      'النوع': 'عائلية',
      'الموديل': '2025',
      'اللون': 'رمادي',
      'المقاعد': '8',
      'الأبواب': '5',
      'الوقود': 'بنزين',
      'ناقل الحركة': 'أوتوماتيك',
      'التكييف': 'ثلاثي',
      'الأمتعة': '5 حقائب',
    },
  ),
];

class CarRentalCompaniesScreen extends StatelessWidget {
  const CarRentalCompaniesScreen({super.key, required this.province});
  final String province;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('شركات ومكاتب تأجير السيارات'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 24),
          children: [
            _ImageBanner(
              height: 180,
              title: 'اختر مكتبك بثقة',
              subtitle: '$province • مكاتب موثقة وأساطيل متنوعة',
            ),
            const SizedBox(height: 20),
            const _Heading('مكاتب تأجير السيارات', trailing: '6 مكاتب'),
            const SizedBox(height: 11),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rentalOffices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: .82,
              ),
              itemBuilder: (context, index) => _OfficeCard(
                office: rentalOffices[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RentalOfficeScreen(office: rentalOffices[index]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _ImageBanner(
              height: 144,
              title: 'خصم يصل إلى 20%',
              subtitle: 'على السيارات المختارة للحجوزات الأسبوعية',
            ),
          ],
        ),
      ),
    ),
  );
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({required this.office, required this.onTap});
  final RentalOffice office;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(carRentalFallbackImage, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _Badge('${office.rating} ★', _navy),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: LocalizedText(
                  office.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class RentalOfficeScreen extends StatefulWidget {
  const RentalOfficeScreen({super.key, required this.office});
  final RentalOffice office;

  @override
  State<RentalOfficeScreen> createState() => _RentalOfficeScreenState();
}

class _RentalOfficeScreenState extends State<RentalOfficeScreen> {
  int tab = 0;
  String query = '';

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _surface,
      appBar: _appBar(widget.office.name),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 24),
          children: [
            _ImageBanner(
              height: 180,
              title: widget.office.name,
              subtitle: 'أسطول حديث • تأمين شامل • دعم على مدار الساعة',
            ),
            const SizedBox(height: 13),
            Container(
              decoration: _card(radius: 17),
              child: TextField(
                onChanged: (value) => setState(() => query = value.trim()),
                decoration: InputDecoration(
                  hintText: l10n('عن ماذا تبحث؟'),
                  prefixIcon: const Icon(Icons.search_rounded, color: _blue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: ['السيارات', 'الخدمات', 'تواصل معنا', 'التقييمات']
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: LocalizedText(
                              entry.value,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          selected: tab == entry.key,
                          showCheckmark: false,
                          selectedColor: const Color(0xffffe9c7),
                          side: BorderSide(
                            color: tab == entry.key
                                ? _gold
                                : const Color(0xffe8ddcc),
                          ),
                          onSelected: (_) => setState(() => tab = entry.key),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 15),
            if (tab == 0) _cars(context),
            if (tab == 1) const _OfficeServices(),
            if (tab == 2) _OfficeContact(office: widget.office),
            if (tab == 3) const _OfficeRatings(),
          ],
        ),
      ),
    ),
  );

  Widget _cars(BuildContext context) {
    final cars = rentalCars
        .where((car) => car.name.contains(query) || car.model.contains(query))
        .toList();
    return Column(
      children: cars
          .map(
            (car) => _CarRow(
              car: car,
              onTap: () {
                if (car.status != 'جاهزة للتسليم') {
                  _notice(context, 'هذه السيارة غير متاحة للحجز حالياً');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CarDetailsScreen(office: widget.office, car: car),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }
}

class _CarRow extends StatelessWidget {
  const _CarRow({required this.car, required this.onTap});
  final RentalCar car;
  final VoidCallback onTap;

  bool get available => car.status == 'جاهزة للتسليم';
  Color get statusColor =>
      available ? const Color(0xff09a9d2) : const Color(0xffd83945);

  @override
  Widget build(BuildContext context) => Container(
    height: 142,
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    decoration: _card(radius: 18),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width * .31,
            child: Image.asset(carRentalFallbackImage, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedText(
                          car.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  LocalizedText(
                    'موديل ${car.model}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  LocalizedText(
                    '${_money(car.oldPrice)} ر.ي',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  LocalizedText(
                    '${_money(car.price)} ر.ي / اليوم',
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedText(
                          available ? 'متاحة' : 'غير متاحة',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!available)
                        IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n('أعلمني عند توفرها'),
                          onPressed: () => _notice(
                            context,
                            'تم تفعيل التنبيه وسنُعلمك عندما تصبح السيارة متاحة',
                          ),
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            color: _blue,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OfficeServices extends StatelessWidget {
  const _OfficeServices();
  static const services = [
    (Icons.delivery_dining_rounded, 'توصيل السيارة'),
    (Icons.flight_land_rounded, 'استلام من المطار'),
    (Icons.person_pin_circle_rounded, 'سائق خاص'),
    (Icons.celebration_rounded, 'سيارات زفاف'),
    (Icons.business_center_rounded, 'سيارات شركات'),
    (Icons.calendar_month_rounded, 'تأجير طويل الأجل'),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 1.45,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    children: services
        .map(
          (item) => Container(
            decoration: _card(radius: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$1, color: _gold, size: 31),
                const SizedBox(height: 7),
                LocalizedText(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _OfficeContact extends StatelessWidget {
  const _OfficeContact({required this.office});
  final RentalOffice office;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(),
        child: Column(
          children: [
            _InfoLine('اسم المكتب', office.name),
            _InfoLine('الموقع', '${office.city}، شارع الستين'),
            const _InfoLine('تاريخ التأسيس', '2017'),
            _InfoLine('حجم الأسطول', '${office.fleet} سيارة'),
            const _InfoLine('الهاتف', '01 234 567'),
            const _InfoLine('الجوال', '777 123 456'),
            const _InfoLine('جوال إضافي', '733 123 456'),
            const _InfoLine('واتساب', '777 123 456'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          _ContactButton(Icons.call_rounded, 'اتصال'),
          _ContactButton(Icons.chat_rounded, 'واتساب'),
          _ContactButton(Icons.directions_rounded, 'الاتجاهات'),
        ],
      ),
      const SizedBox(height: 14),
      const LocalizedText(
        'تابعنا',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.facebook_rounded, color: _blue, size: 30),
          SizedBox(width: 18),
          Icon(Icons.camera_alt_outlined, color: Color(0xffb33771), size: 28),
          SizedBox(width: 18),
          Icon(
            Icons.alternate_email_rounded,
            color: Color(0xff1d9bf0),
            size: 28,
          ),
          SizedBox(width: 18),
          Icon(Icons.play_circle_outline_rounded, color: Colors.red, size: 30),
        ],
      ),
    ],
  );
}

class _OfficeRatings extends StatelessWidget {
  const _OfficeRatings();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(),
        child: const Column(
          children: [
            _RatingLine('نوع السيارات', 4.9),
            _RatingLine('نظافة السيارات', 4.8),
            _RatingLine('التعامل وخدمة العملاء', 4.9),
            _RatingLine('السعر', 4.6),
          ],
        ),
      ),
      const SizedBox(height: 17),
      const Align(
        alignment: Alignment.centerRight,
        child: LocalizedText(
          'تحدثوا عنا',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 9),
      const _Comment(
        'محمد القباطي',
        'سيارات نظيفة والتسليم كان في الموعد تماماً.',
      ),
      const _Comment('سارة أحمد', 'تعامل راقٍ وسعر واضح دون رسوم مخفية.'),
      const _Comment('عبدالله علي', 'تجربة ممتازة وسأكرر الحجز عبر حجوزاتكم.'),
    ],
  );
}

class CarDetailsScreen extends StatelessWidget {
  const CarDetailsScreen({super.key, required this.office, required this.car});
  final RentalOffice office;
  final RentalCar car;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('تفاصيل السيارة'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 10),
          child: _PrimaryButton(
            'احجز السيارة',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CarBookingScreen(office: office, car: car),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            SizedBox(
              height: 285,
              child: PageView.builder(
                itemCount: 3,
                itemBuilder: (_, index) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(carRentalFallbackImage, fit: BoxFit.cover),
                    Positioned(
                      left: 15,
                      bottom: 15,
                      child: _Badge('${index + 1}/3', _navy),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedText(
                          car.name,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const LocalizedText(
                        '4.9 ★',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  LocalizedText('موديل ${car.model} • ${office.name}'),
                  const SizedBox(height: 7),
                  LocalizedText(
                    '${_money(car.price)} ر.ي / اليوم',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _Heading('مواصفات السيارة'),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.18,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: car.specs.entries
                        .map((e) => _SpecCard(e.key, e.value))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  const _PolicyCard('الضمانات المطلوبة', [
                    'هوية أصلية سارية',
                    'رخصة قيادة سارية',
                    'تأمين مسترد بقيمة 50,000 ر.ي',
                  ]),
                  const _PolicyCard('يشمل السعر', [
                    'التأمين الأساسي',
                    'الصيانة الدورية',
                    'مساعدة على الطريق 24/7',
                  ]),
                  const _PolicyCard('غير مشمول', [
                    'الوقود',
                    'المخالفات المرورية',
                    'الأضرار الناتجة عن سوء الاستخدام',
                  ]),
                  const _PolicyCard('سياسة الإلغاء', [
                    'إلغاء مجاني خلال 6 ساعات من وقت الحجز',
                    'خصم يوم واحد عند الإلغاء المتأخر',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CarBookingScreen extends StatefulWidget {
  const CarBookingScreen({super.key, required this.office, required this.car});
  final RentalOffice office;
  final RentalCar car;

  @override
  State<CarBookingScreen> createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();
  final email = TextEditingController();
  final identity = TextEditingController();
  final license = TextEditingController();
  String identityType = 'بطاقة شخصية';
  int age = 25;
  int days = 3;
  final selected = <String>{};

  static const extras = {
    'سائق خاص': 10000,
    'سائق إضافي': 5000,
    'كرسي طفل': 3000,
    'تأمين إضافي': 7000,
    'توصيل السيارة': 4000,
    'تموين السيارة': 15000,
  };

  int get extrasTotal => selected.fold(0, (sum, key) => sum + extras[key]!);
  int get total => widget.car.price * days + extrasTotal;

  @override
  void dispose() {
    for (final controller in [
      name,
      phone,
      whatsapp,
      email,
      identity,
      license,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('حجز السيارة'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 10),
          child: _PrimaryButton(
            'متابعة إلى الدفع',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CarPaymentScreen(
                  office: widget.office,
                  car: widget.car,
                  customerName: name.text.trim().isEmpty
                      ? 'عميل حجوزاتكم'
                      : name.text.trim(),
                  days: days,
                  selectedExtras: {
                    for (final key in selected) key: extras[key]!,
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            const _BookingStepper(active: 1),
            const SizedBox(height: 16),
            _CarMiniSummary(car: widget.car),
            const SizedBox(height: 18),
            const _Heading('بيانات المستأجر'),
            const SizedBox(height: 10),
            _Field('الاسم الكامل', name),
            _Field('رقم الهاتف', phone, keyboardType: TextInputType.phone),
            _Field('رقم واتساب', whatsapp, keyboardType: TextInputType.phone),
            _Field(
              'البريد الإلكتروني (اختياري)',
              email,
              keyboardType: TextInputType.emailAddress,
            ),
            DropdownButtonFormField<String>(
              initialValue: identityType,
              decoration: _inputDecoration('نوع الهوية'),
              items: [
                'بطاقة شخصية',
                'جواز سفر',
                'بطاقة عائلية',
              ].map((e) => DropdownMenuItem(value: e, child: LocalizedText(e))).toList(),
              onChanged: (value) => setState(() => identityType = value!),
            ),
            const SizedBox(height: 10),
            _Field('رقم الهوية', identity),
            _Field('رقم رخصة القيادة', license),
            _CounterRow(
              'العمر',
              age,
              (value) => setState(() => age = value),
              minimum: 18,
            ),
            _CounterRow(
              'عدد أيام الإيجار',
              days,
              (value) => setState(() => days = value),
            ),
            const SizedBox(height: 18),
            const _Heading('الإضافات'),
            const SizedBox(height: 9),
            ...extras.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: CheckboxListTile(
                    value: selected.contains(entry.key),
                    activeColor: _blue,
                    title: LocalizedText(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: LocalizedText('${_money(entry.value)} ر.ي'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onChanged: (_) => setState(() {
                      selected.contains(entry.key)
                          ? selected.remove(entry.key)
                          : selected.add(entry.key);
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PriceSummary(
              carPrice: widget.car.price,
              days: days,
              extras: extrasTotal,
            ),
          ],
        ),
      ),
    ),
  );
}

class CarPaymentScreen extends StatefulWidget {
  const CarPaymentScreen({
    super.key,
    required this.office,
    required this.car,
    required this.customerName,
    required this.days,
    required this.selectedExtras,
  });
  final RentalOffice office;
  final RentalCar car;
  final String customerName;
  final int days;
  final Map<String, int> selectedExtras;

  @override
  State<CarPaymentScreen> createState() => _CarPaymentScreenState();
}

class _CarPaymentScreenState extends State<CarPaymentScreen> {
  String? wallet;
  static const wallets = [
    'ون كاش',
    'جوالي',
    'جيب',
    'فلوسك',
    'كاك موبايلي',
    'بنكي لايت',
    'يمن والت',
    'كريمي جوال',
  ];

  int get extrasTotal => widget.selectedExtras.values.fold(0, (a, b) => a + b);
  int get total => widget.car.price * widget.days + extrasTotal;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('الدفع المالي'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 10),
          child: _PrimaryButton(
            'استكمال الدفع',
            onTap: wallet == null
                ? null
                : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CarInvoiceScreen(
                        office: widget.office,
                        car: widget.car,
                        customerName: widget.customerName,
                        days: widget.days,
                        selectedExtras: widget.selectedExtras,
                        wallet: wallet!,
                      ),
                    ),
                  ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            const _BookingStepper(active: 3),
            const SizedBox(height: 15),
            _ImageBanner(
              height: 180,
              title: widget.car.name,
              subtitle: 'موديل ${widget.car.model} • ${widget.office.name}',
            ),
            const SizedBox(height: 14),
            _PriceSummary(
              carPrice: widget.car.price,
              days: widget.days,
              extras: extrasTotal,
            ),
            if (widget.selectedExtras.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: _card(),
                child: Column(
                  children: widget.selectedExtras.entries
                      .map((e) => _InfoLine(e.key, '${_money(e.value)} ر.ي'))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const _Heading('اختر المحفظة المالية الإلكترونية'),
            const SizedBox(height: 9),
            RadioGroup<String>(
              groupValue: wallet,
              onChanged: (value) => setState(() => wallet = value),
              child: Column(
                children: wallets
                    .map(
                      (name) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: RadioListTile<String>(
                            value: name,
                            activeColor: _blue,
                            title: LocalizedText(
                              name,
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            secondary: const CircleAvatar(
                              backgroundColor: Color(0xffffecd0),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: _gold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            LocalizedText(
              'الإجمالي العام: ${_money(total)} ر.ي',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _blue,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CarInvoiceScreen extends StatelessWidget {
  const CarInvoiceScreen({
    super.key,
    required this.office,
    required this.car,
    required this.customerName,
    required this.days,
    required this.selectedExtras,
    required this.wallet,
  });
  final RentalOffice office;
  final RentalCar car;
  final String customerName;
  final int days;
  final Map<String, int> selectedExtras;
  final String wallet;

  int get extrasTotal => selectedExtras.values.fold(0, (a, b) => a + b);
  int get total => car.price * days + extrasTotal;
  String get invoiceText =>
      'فاتورة حجز سيارة\nالعميل: $customerName\nالسيارة: ${car.name} ${car.model}\nالمكتب: ${office.name}\nالمدة: $days أيام\nالإجمالي: ${_money(total)} ر.ي\nالدفع: $wallet';

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('تفاصيل الفاتورة'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xffe9f8f0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: _green,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  SizedBox(height: 9),
                  LocalizedText(
                    'تم تأكيد الحجز بنجاح',
                    style: TextStyle(
                      color: _green,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText('رقم الحجز: CR-20458'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ImageBanner(height: 175, title: car.name, subtitle: office.name),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _card(),
              child: Column(
                children: [
                  _InfoLine('اسم المستأجر', customerName),
                  _InfoLine('السيارة', '${car.name} ${car.model}'),
                  _InfoLine('المكتب', office.name),
                  _InfoLine('تكلفة اليوم', '${_money(car.price)} ر.ي'),
                  _InfoLine('عدد الأيام', '$days'),
                  _InfoLine(
                    'الإيجار الأساسي',
                    '${_money(car.price * days)} ر.ي',
                  ),
                  ...selectedExtras.entries.map(
                    (e) => _InfoLine(e.key, '${_money(e.value)} ر.ي'),
                  ),
                  _InfoLine('طريقة الدفع', wallet),
                  const Divider(height: 24),
                  _InfoLine(
                    'الإجمالي العام',
                    '${_money(total)} ر.ي',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const TransportTrackingCard(
              title: 'السيارة المؤجرة',
              distance: '3.2 كم عن موقعك',
              rating: 4.8,
              status: 'جاهزة للتسليم',
            ),
            const SizedBox(height: 14),
            ServiceCompletionFooter(
              serviceKey:
                  'تأجير السيارات والنقل البري والشحن الداخلي',
              serviceName: 'تأجير السيارات',
              invoiceText: invoiceText,
              onViewInvoice: () => _notice(context, 'الفاتورة معروضة بالفعل'),
            ),
          ],
        ),
      ),
    ),
  );
}

PreferredSizeWidget _appBar(String title) => AppBar(
  backgroundColor: _surface,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,
  title: LocalizedText(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
  ),
  actions: [
    IconButton(
      onPressed: () {},
      icon: const Icon(Icons.notifications_none_rounded, color: _navy),
    ),
  ],
);

class _ImageBanner extends StatelessWidget {
  const _ImageBanner({
    required this.height,
    required this.title,
    required this.subtitle,
  });
  final double height;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(carRentalMasterBanner, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xcc0b2c57), Color(0x110b2c57)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                LocalizedText(
                  subtitle,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.trailing});
  final String text;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: LocalizedText(
          text,
          style: const TextStyle(
            color: _navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      if (trailing != null)
        LocalizedText(
          trailing!,
          style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
        ),
    ],
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: LocalizedText(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: LocalizedText(
            label,
            style: TextStyle(
              color: _navy,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        LocalizedText(
          value,
          style: TextStyle(
            color: strong ? _blue : const Color(0xff5f6670),
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ContactButton extends StatelessWidget {
  const _ContactButton(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: () => _notice(context, 'سيتم فتح $label'),
        icon: Icon(icon, size: 18),
        label: LocalizedText(label, style: const TextStyle(fontSize: 11)),
      ),
    ),
  );
}

class _RatingLine extends StatelessWidget {
  const _RatingLine(this.label, this.rating);
  final String label;
  final double rating;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: LocalizedText(label)),
        LocalizedText(
          '$rating ★',
          style: const TextStyle(color: _gold, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _Comment extends StatelessWidget {
  const _Comment(this.name, this.text);
  final String name;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: _card(radius: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          name,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
        ),
        const LocalizedText('★★★★★', style: TextStyle(color: _gold)),
        LocalizedText(text),
      ],
    ),
  );
}

class _SpecCard extends StatelessWidget {
  const _SpecCard(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: _card(radius: 14),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LocalizedText(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff667085), fontSize: 11),
        ),
        const SizedBox(height: 4),
        LocalizedText(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard(this.title, this.items);
  final String title;
  final List<String> items;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 11),
    padding: const EdgeInsets.all(14),
    decoration: _card(radius: 17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          title,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _green,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(child: LocalizedText(e)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _BookingStepper extends StatelessWidget {
  const _BookingStepper({required this.active});
  final int active;
  @override
  Widget build(BuildContext context) {
    const labels = ['السيارة', 'البيانات', 'الإضافات', 'الدفع'];
    return Row(
      children: labels
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: e.key <= active
                        ? _blue
                        : const Color(0xffd9dde3),
                    child: LocalizedText(
                      '${e.key + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  LocalizedText(
                    e.value,
                    style: TextStyle(
                      color: e.key <= active ? _blue : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CarMiniSummary extends StatelessWidget {
  const _CarMiniSummary({required this.car});
  final RentalCar car;
  @override
  Widget build(BuildContext context) => Container(
    height: 105,
    clipBehavior: Clip.antiAlias,
    decoration: _card(),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Image.asset(carRentalFallbackImage, fit: BoxFit.cover),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalizedText(
                  car.name,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                LocalizedText('موديل ${car.model}'),
                LocalizedText(
                  '${_money(car.price)} ر.ي / اليوم',
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.controller, {this.keyboardType});
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label),
    ),
  );
}

InputDecoration _inputDecoration(String label) => InputDecoration(
  labelText: l10n(label),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xffe5d8c5)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xffe5d8c5)),
  ),
);

class _CounterRow extends StatelessWidget {
  const _CounterRow(this.label, this.value, this.onChanged, {this.minimum = 1});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int minimum;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    decoration: _card(radius: 15),
    child: Row(
      children: [
        Expanded(
          child: LocalizedText(
            label,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value > minimum ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        LocalizedText(
          '$value',
          style: const TextStyle(color: _blue, fontWeight: FontWeight.w900),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    ),
  );
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.carPrice,
    required this.days,
    required this.extras,
  });
  final int carPrice;
  final int days;
  final int extras;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _card(),
    child: Column(
      children: [
        _InfoLine('تكلفة اليوم', '${_money(carPrice)} ر.ي'),
        _InfoLine('عدد الأيام', '$days'),
        _InfoLine('الإيجار الأساسي', '${_money(carPrice * days)} ر.ي'),
        _InfoLine('الخدمات المضافة', '${_money(extras)} ر.ي'),
        const Divider(height: 24),
        _InfoLine(
          'الإجمالي العام',
          '${_money(carPrice * days + extras)} ر.ي',
          strong: true,
        ),
      ],
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(this.label, {required this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      child: LocalizedText(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

void _notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: LocalizedText(message)));
}
