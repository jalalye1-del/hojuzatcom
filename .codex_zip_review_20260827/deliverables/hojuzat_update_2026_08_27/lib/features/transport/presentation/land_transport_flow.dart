import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/documents/invoice_pdf_service.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/reviews/service_review.dart';
import 'car_rental_flow.dart' show carRentalMasterBanner;
import 'transport_tracking_card.dart';

const _landImage = 'assets/Services images/تأجير السيارات والنقل الداخلي.jpg';
const _navy = Color(0xff0b2c57);
const _blue = Color(0xff155fc5);
const _gold = Color(0xffbc8638);
const _green = Color(0xff159a61);
const _surface = Color(0xfffffaf3);

String _money(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

BoxDecoration _card({double radius = 19}) => BoxDecoration(
  color: Colors.white.withValues(alpha: .97),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xffeadfce)),
  boxShadow: const [
    BoxShadow(color: Color(0x180b2c57), blurRadius: 15, offset: Offset(0, 7)),
  ],
);

enum LandVehicleType { coach, minibus, privateCar }

extension LandVehicleTypeDetails on LandVehicleType {
  String get label => switch (this) {
    LandVehicleType.coach => 'النقل الجماعي',
    LandVehicleType.minibus => 'باصات متوسطة',
    LandVehicleType.privateCar => 'سيارات خاصة',
  };
  String get english => switch (this) {
    LandVehicleType.coach => 'Full-size coaches',
    LandVehicleType.minibus => 'Minibus',
    LandVehicleType.privateCar => 'Private cars',
  };
  IconData get icon => switch (this) {
    LandVehicleType.coach => Icons.directions_bus_filled_rounded,
    LandVehicleType.minibus => Icons.airport_shuttle_rounded,
    LandVehicleType.privateCar => Icons.local_taxi_rounded,
  };
  int get seatCount => switch (this) {
    LandVehicleType.coach => 32,
    LandVehicleType.minibus => 18,
    LandVehicleType.privateCar => 6,
  };
}

class LandCompany {
  const LandCompany(this.name, this.rating);
  final String name;
  final double rating;
}

class LandTrip {
  const LandTrip({
    required this.type,
    required this.company,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.price,
    required this.remainingSeats,
  });
  final LandVehicleType type;
  final String company;
  final String origin;
  final String destination;
  final String departure;
  final String arrival;
  final int price;
  final int remainingSeats;
}

const landCompanies = [
  LandCompany('راحة للنقل البري', 4.9),
  LandCompany('الرويشان للنقل', 4.8),
  LandCompany('النمر للنقل الجماعي', 4.8),
  LandCompany('البراق للنقل', 4.7),
  LandCompany('الطريق الآمن', 4.7),
  LandCompany('اليمن السعيد', 4.6),
  LandCompany('المسافر VIP', 4.8),
  LandCompany('الوحدة للنقل', 4.6),
  LandCompany('سبأ للنقل والسفريات', 4.7),
];

const landTrips = [
  LandTrip(
    type: LandVehicleType.coach,
    company: 'راحة للنقل البري',
    origin: 'صنعاء',
    destination: 'عدن',
    departure: '07:00 ص',
    arrival: '03:30 م',
    price: 18000,
    remainingSeats: 9,
  ),
  LandTrip(
    type: LandVehicleType.coach,
    company: 'الرويشان للنقل',
    origin: 'صنعاء',
    destination: 'تعز',
    departure: '08:30 ص',
    arrival: '01:30 م',
    price: 12000,
    remainingSeats: 13,
  ),
  LandTrip(
    type: LandVehicleType.coach,
    company: 'النمر للنقل الجماعي',
    origin: 'عدن',
    destination: 'المكلا',
    departure: '06:00 ص',
    arrival: '02:00 م',
    price: 22000,
    remainingSeats: 7,
  ),
  LandTrip(
    type: LandVehicleType.minibus,
    company: 'البراق للنقل',
    origin: 'صنعاء',
    destination: 'إب',
    departure: '09:00 ص',
    arrival: '01:00 م',
    price: 9500,
    remainingSeats: 5,
  ),
  LandTrip(
    type: LandVehicleType.minibus,
    company: 'الطريق الآمن',
    origin: 'تعز',
    destination: 'عدن',
    departure: '10:00 ص',
    arrival: '02:30 م',
    price: 11000,
    remainingSeats: 4,
  ),
  LandTrip(
    type: LandVehicleType.minibus,
    company: 'اليمن السعيد',
    origin: 'صنعاء',
    destination: 'الحديدة',
    departure: '07:30 ص',
    arrival: '12:00 م',
    price: 10000,
    remainingSeats: 8,
  ),
  LandTrip(
    type: LandVehicleType.privateCar,
    company: 'المسافر VIP',
    origin: 'صنعاء',
    destination: 'عدن',
    departure: 'حسب الطلب',
    arrival: 'مرن',
    price: 65000,
    remainingSeats: 4,
  ),
  LandTrip(
    type: LandVehicleType.privateCar,
    company: 'الوحدة للنقل',
    origin: 'صنعاء',
    destination: 'مأرب',
    departure: '08:00 ص',
    arrival: '11:30 ص',
    price: 38000,
    remainingSeats: 3,
  ),
  LandTrip(
    type: LandVehicleType.privateCar,
    company: 'سبأ للنقل والسفريات',
    origin: 'إب',
    destination: 'تعز',
    departure: '09:30 ص',
    arrival: '11:30 ص',
    price: 22000,
    remainingSeats: 4,
  ),
];

class LandTransportHomeScreen extends StatefulWidget {
  const LandTransportHomeScreen({super.key, required this.province});
  final String province;

  @override
  State<LandTransportHomeScreen> createState() =>
      _LandTransportHomeScreenState();
}

class _LandTransportHomeScreenState extends State<LandTransportHomeScreen> {
  final from = TextEditingController(text: 'صنعاء');
  final to = TextEditingController(text: 'عدن');
  DateTime date = DateTime.now().add(const Duration(days: 1));
  int passengers = 1;
  bool roundTrip = false;

  @override
  void dispose() {
    from.dispose();
    to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('النقل البري'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 25),
          children: [
            const _Banner(
              title: 'رحلتك البرية تبدأ من هنا',
              subtitle: 'حافلات وباصات وسيارات خاصة من شركات موثقة',
            ),
            const SizedBox(height: 18),
            const _Heading('اختر نوع المركبة'),
            const SizedBox(height: 10),
            ...LandVehicleType.values.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _VehicleTypeCard(
                  type: type,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LandVehicleCategoryScreen(type: type),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const _Heading('البحث عن رحلة'),
            const SizedBox(height: 10),
            _TripSearchForm(
              from: from,
              to: to,
              date: date,
              passengers: passengers,
              roundTrip: roundTrip,
              onDate: _pickDate,
              onPassengers: (v) => setState(() => passengers = v),
              onRoundTrip: (v) => setState(() => roundTrip = v),
            ),
            const SizedBox(height: 20),
            const _Heading('العروض المميزة'),
            const SizedBox(height: 10),
            const _OfferBanner(
              'خصم 20% على رحلات صنعاء–عدن',
              'مقاعد مريحة • أمتعة مجانية • تتبع الرحلة',
            ),
            const SizedBox(height: 11),
            const _OfferBanner(
              'احجز مبكراً ووفر أكثر',
              'أسعار خاصة للحجز قبل موعد السفر بثلاثة أيام',
            ),
            const SizedBox(height: 20),
            _Heading('شركات النقل البري', action: 'عرض الكل'),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: landCompanies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 9,
                mainAxisSpacing: 11,
                childAspectRatio: .72,
              ),
              itemBuilder: (context, index) => _CompanyCard(
                company: landCompanies[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LandCompanyScreen(company: landCompanies[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) setState(() => date = value);
  }
}

class LandVehicleCategoryScreen extends StatelessWidget {
  const LandVehicleCategoryScreen({super.key, required this.type});
  final LandVehicleType type;

  @override
  Widget build(BuildContext context) {
    final trips = landTrips.where((trip) => trip.type == type).toList();
    return _rtl(
      Scaffold(
        backgroundColor: _surface,
        appBar: _appBar(type.label),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(15),
            children: [
              _Banner(
                title: type.label,
                subtitle: '${type.english} • رحلات يومية وخيارات مرنة',
              ),
              const SizedBox(height: 14),
              _TripSearchForm(
                from: TextEditingController(text: 'صنعاء'),
                to: TextEditingController(text: 'عدن'),
                date: DateTime.now().add(const Duration(days: 1)),
                passengers: 1,
                roundTrip: false,
                onDate: () {},
                onPassengers: (_) {},
                onRoundTrip: (_) {},
              ),
              const SizedBox(height: 15),
              _OfferBanner(
                'عرض خاص على ${type.label}',
                'خصم يصل إلى 15% للحجز المبكر',
              ),
              const SizedBox(height: 18),
              const _Heading('الرحلات القادمة'),
              const SizedBox(height: 10),
              _TripGrid(trips: [...trips, ...trips]),
            ],
          ),
        ),
      ),
    );
  }
}

class LandCompanyScreen extends StatefulWidget {
  const LandCompanyScreen({super.key, required this.company});
  final LandCompany company;
  @override
  State<LandCompanyScreen> createState() => _LandCompanyScreenState();
}

class _LandCompanyScreenState extends State<LandCompanyScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final base = landTrips
        .where(
          (trip) =>
              trip.company == widget.company.name ||
              widget.company.name == landCompanies.first.name,
        )
        .toList();
    final source = base.isEmpty ? landTrips.take(3).toList() : base;
    final trips = [...source, ...source]
        .take(6)
        .where(
          (trip) => '${trip.origin}${trip.destination}${trip.type.label}'
              .contains(query),
        )
        .toList();
    return _rtl(
      Scaffold(
        backgroundColor: _surface,
        appBar: _appBar(widget.company.name),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(15),
            children: [
              _Banner(
                title: widget.company.name,
                subtitle: 'شركة نقل معتمدة • تقييم ${widget.company.rating}',
              ),
              const SizedBox(height: 13),
              Container(
                decoration: _card(radius: 16),
                child: TextField(
                  onChanged: (v) => setState(() => query = v.trim()),
                  decoration: InputDecoration(
                    hintText: l10n('عن ماذا تبحث؟'),
                    prefixIcon: const Icon(Icons.search_rounded, color: _blue),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _Heading('الرحلات القادمة'),
              const SizedBox(height: 10),
              _TripGrid(trips: trips),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripGrid extends StatelessWidget {
  const _TripGrid({required this.trips});
  final List<LandTrip> trips;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: trips.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 11,
      mainAxisSpacing: 12,
      childAspectRatio: .70,
    ),
    itemBuilder: (context, index) => _TripCard(
      trip: trips[index],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LandTripDetailsScreen(trip: trips[index]),
        ),
      ),
    ),
  );
}

class LandTripDetailsScreen extends StatelessWidget {
  const LandTripDetailsScreen({super.key, required this.trip});
  final LandTrip trip;
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('تفاصيل الرحلة'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 7, 15, 10),
          child: _PrimaryButton(
            'اختيار الرحلة',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LandSeatSelectionScreen(trip: trip),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            _Banner(
              title: '${trip.origin} ← ${trip.destination}',
              subtitle: '${trip.company} • ${trip.type.label}',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _card(),
              child: Column(
                children: [
                  _InfoLine('نوع المركبة', trip.type.label),
                  _InfoLine('نقطة الانطلاق', trip.origin),
                  _InfoLine('الوجهة', trip.destination),
                  _InfoLine('وقت المغادرة', trip.departure),
                  _InfoLine('وقت الوصول', trip.arrival),
                  const _InfoLine('مدة الرحلة', '6 ساعات و30 دقيقة'),
                  const _InfoLine('عدد التوقفات', '3 محطات'),
                  _InfoLine('المقاعد المتبقية', '${trip.remainingSeats}'),
                  const _InfoLine('التقييم', '4.9 ★'),
                  _InfoLine(
                    'السعر للفرد',
                    '${_money(trip.price)} ر.ي',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _Heading('مسار الرحلة'),
            const SizedBox(height: 9),
            const _Timeline(),
            const SizedBox(height: 14),
            const _Policy('الخدمات داخل المركبة', [
              'Wi‑Fi مجاني',
              'تكييف',
              'شحن USB',
              'مقاعد مريحة',
            ]),
            const _Policy('سياسة الأمتعة', [
              'حقيبة رئيسية حتى 25 كجم',
              'حقيبة يدوية حتى 7 كجم',
            ]),
            const _Policy('سياسة الإلغاء', [
              'في حالة الإلغاء بعد استكمال عملية الحجز لا يمكن استرداد أي مبلغ',
            ]),
          ],
        ),
      ),
    ),
  );
}

class LandSeatSelectionScreen extends StatefulWidget {
  const LandSeatSelectionScreen({super.key, required this.trip});
  final LandTrip trip;
  @override
  State<LandSeatSelectionScreen> createState() =>
      _LandSeatSelectionScreenState();
}

class _LandSeatSelectionScreenState extends State<LandSeatSelectionScreen> {
  String? selected;
  final occupied = const {'A3', 'B2', 'C4', 'D1', 'E3'};
  final unavailable = const {'B4', 'D3'};
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('اختيار المقاعد'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _PrimaryButton(
            'متابعة',
            selected == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LandPassengerScreen(
                        trip: widget.trip,
                        seat: selected!,
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
            _TripMini(trip: widget.trip),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _card(),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LocalizedText('أمام المركبة'),
                      Icon(
                        Icons.airline_seat_recline_extra_rounded,
                        color: _navy,
                      ),
                      LocalizedText('السائق'),
                    ],
                  ),
                  const Divider(height: 25),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.trip.type.seatCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (_, index) {
                      final row = String.fromCharCode(65 + index ~/ 4);
                      final seat = '$row${index % 4 + 1}';
                      final busy = occupied.contains(seat);
                      final blocked = unavailable.contains(seat);
                      final active = selected == seat;
                      return InkWell(
                        onTap: busy || blocked
                            ? () => _notice(
                                context,
                                blocked
                                    ? 'المقعد $seat غير متاح'
                                    : 'المقعد $seat محجوز',
                              )
                            : () => setState(() => selected = seat),
                        child: CircleAvatar(
                          backgroundColor: blocked
                              ? const Color(0xff7d4bc6)
                              : busy
                              ? const Color(0xffead9bf)
                              : active
                              ? const Color(0xff087da4)
                              : const Color(0xff28bde3),
                          child: LocalizedText(
                            seat,
                            style: TextStyle(
                              color: blocked || active
                                  ? Colors.white
                                  : _navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  LocalizedText(
                    selected == null
                        ? 'اختر مقعداً للمتابعة'
                        : 'المقعد المختار: $selected',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 13,
                    runSpacing: 7,
                    children: [
                      _Legend(Color(0xff28bde3), 'متاح'),
                      _Legend(Color(0xff087da4), 'مختار'),
                      _Legend(Color(0xffead9bf), 'محجوز'),
                      _Legend(Color(0xff7d4bc6), 'غير متاح'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PassengerData {
  PassengerData()
    : name = TextEditingController(),
      phone = TextEditingController(),
      identity = TextEditingController(),
      birthDate = TextEditingController();
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController identity;
  final TextEditingController birthDate;
  String gender = 'ذكر';
  String identityType = 'بطاقة شخصية';
  void dispose() {
    name.dispose();
    phone.dispose();
    identity.dispose();
    birthDate.dispose();
  }
}

class LandPassengerScreen extends StatefulWidget {
  const LandPassengerScreen({
    super.key,
    required this.trip,
    required this.seat,
  });
  final LandTrip trip;
  final String seat;
  @override
  State<LandPassengerScreen> createState() => _LandPassengerScreenState();
}

class _LandPassengerScreenState extends State<LandPassengerScreen> {
  final passengers = [PassengerData()];
  @override
  void dispose() {
    for (final p in passengers) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('بيانات المسافر'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _PrimaryButton(
            'استكمال الحجز والدفع',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LandPaymentScreen(
                  trip: widget.trip,
                  seat: widget.seat,
                  passengerName: passengers.first.name.text.trim().isEmpty
                      ? 'مسافر حجوزاتكم'
                      : passengers.first.name.text.trim(),
                  passengersCount: passengers.length,
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
            _TripMini(trip: widget.trip),
            const SizedBox(height: 14),
            ...passengers.asMap().entries.map(
              (entry) => _PassengerForm(
                index: entry.key,
                data: entry.value,
                onChanged: () => setState(() {}),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => passengers.add(PassengerData())),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const LocalizedText('إضافة مسافر آخر'),
            ),
          ],
        ),
      ),
    ),
  );
}

class LandPaymentScreen extends StatefulWidget {
  const LandPaymentScreen({
    super.key,
    required this.trip,
    required this.seat,
    required this.passengerName,
    required this.passengersCount,
  });
  final LandTrip trip;
  final String seat;
  final String passengerName;
  final int passengersCount;
  @override
  State<LandPaymentScreen> createState() => _LandPaymentScreenState();
}

class _LandPaymentScreenState extends State<LandPaymentScreen> {
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
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('الدفع'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _PrimaryButton(
            'استكمال الدفع',
            wallet == null
                ? null
                : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LandInvoiceScreen(
                        trip: widget.trip,
                        seat: widget.seat,
                        passengerName: widget.passengerName,
                        passengersCount: widget.passengersCount,
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
            _Banner(
              title: widget.trip.company,
              subtitle: '${widget.trip.origin} ← ${widget.trip.destination}',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _card(),
              child: Column(
                children: [
                  _InfoLine('السعر للفرد', '${_money(widget.trip.price)} ر.ي'),
                  _InfoLine('عدد المسافرين', '${widget.passengersCount}'),
                  _InfoLine(
                    'الإجمالي',
                    '${_money(widget.trip.price * widget.passengersCount)} ر.ي',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _Heading('اختر المحفظة المالية'),
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
          ],
        ),
      ),
    ),
  );
}

class LandInvoiceScreen extends StatelessWidget {
  const LandInvoiceScreen({
    super.key,
    required this.trip,
    required this.seat,
    required this.passengerName,
    required this.passengersCount,
    required this.wallet,
  });
  final LandTrip trip;
  final String seat;
  final String passengerName;
  final int passengersCount;
  final String wallet;
  String get text =>
      'تذكرة نقل بري\nالراكب: $passengerName\n${trip.origin} إلى ${trip.destination}\nالشركة: ${trip.company}\nالمقعد: $seat\nالإجمالي: ${_money(trip.price * passengersCount)} ر.ي';

  Future<void> _downloadTicket(BuildContext context) async {
    await InvoicePdfService.save(
      fileName: 'ticket_${trip.company}_$seat',
      title: 'التذكرة الإلكترونية',
      reference: '${trip.company}-$seat',
      details: [
        ('اسم الراكب', passengerName),
        ('شركة النقل', trip.company),
        ('نوع المركبة', trip.type.label),
        ('نقطة الانطلاق', trip.origin),
        ('الوجهة', trip.destination),
        ('وقت المغادرة', trip.departure),
        ('وقت الوصول', trip.arrival),
        ('المقعد', seat),
        ('الإجمالي', '${_money(trip.price * passengersCount)} ر.ي'),
      ],
    );
    if (context.mounted) {
      _notice(context, 'تم حفظ التذكرة الإلكترونية بصيغة PDF');
    }
  }
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('تفاصيل الفاتورة'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            const _SuccessCard(),
            const SizedBox(height: 13),
            _Banner(
              title: trip.company,
              subtitle:
                  '${trip.type.label} • ${trip.origin} ← ${trip.destination}',
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _card(),
              child: Column(
                children: [
                  _InfoLine('نوع المركبة', trip.type.label),
                  _InfoLine('نقطة الانطلاق', trip.origin),
                  _InfoLine('الوجهة', trip.destination),
                  _InfoLine('وقت المغادرة المتوقع', trip.departure),
                  _InfoLine('وقت الوصول المتوقع', trip.arrival),
                  const _InfoLine('المدة المتوقعة', '6 ساعات و30 دقيقة'),
                  _InfoLine('المقعد', seat),
                  _InfoLine('المحفظة', wallet),
                  _InfoLine(
                    'الإجمالي',
                    '${_money(trip.price * passengersCount)} ر.ي',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _Timeline(),
            const SizedBox(height: 14),
            TransportTrackingCard(
              title: trip.company,
              distance: '42 كم إلى محطة الوصول',
              rating: 4.8,
              status: 'الرحلة في الطريق',
            ),
            const SizedBox(height: 14),
            _PrimaryButton(
              'تحميل التذكرة الإلكترونية',
              () => _downloadTicket(context),
            ),
            const SizedBox(height: 9),
            ServiceCompletionFooter(
              serviceKey:
                  'تأجير السيارات والنقل البري والشحن الداخلي',
              serviceName: 'النقل البري',
              invoiceText: text,
              onViewInvoice: () => _notice(context, 'الفاتورة معروضة بالفعل'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ElectronicLandTicketScreen extends StatelessWidget {
  const ElectronicLandTicketScreen({
    super.key,
    required this.trip,
    required this.seat,
    required this.passengerName,
  });
  final LandTrip trip;
  final String seat;
  final String passengerName;
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('التذكرة الإلكترونية'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: _card(radius: 26),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    color: _navy,
                    child: Column(
                      children: [
                        LocalizedText(
                          trip.company,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        LocalizedText(
                          '${trip.origin} ← ${trip.destination}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const _Qr(),
                        const SizedBox(height: 15),
                        const _InfoLine('رقم الحجز', 'LT-20458'),
                        _InfoLine('اسم الراكب', passengerName),
                        _InfoLine('شركة النقل', trip.company),
                        const _InfoLine('رقم الرحلة', 'YB-118'),
                        _InfoLine('المقعد', seat),
                        _InfoLine('نقطة الانطلاق', trip.origin),
                        _InfoLine('محطة الوصول', trip.destination),
                        _InfoLine(
                          'التاريخ',
                          '${DateTime.now().day + 1}/${DateTime.now().month}/${DateTime.now().year}',
                        ),
                        _InfoLine('الوقت', trip.departure),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _PrimaryButton(
              'تحميل التذكرة',
              () => _notice(context, 'تم تحميل التذكرة'),
            ),
            const SizedBox(height: 9),
            _OutlineButton(
              Icons.share_rounded,
              'مشاركة',
              () => SharePlus.instance.share(
                ShareParams(
                  text:
                      'تذكرة $passengerName • ${trip.origin} إلى ${trip.destination} • المقعد $seat',
                ),
              ),
            ),
            const SizedBox(height: 9),
            _OutlineButton(
              Icons.calendar_month_rounded,
              'إضافة للتقويم',
              () => _notice(context, 'تمت إضافة الرحلة إلى التقويم'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({required this.type, required this.onTap});
  final LandVehicleType type;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      height: 112,
      padding: const EdgeInsets.all(15),
      decoration: _card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xffffecd0),
            child: Icon(type.icon, color: _gold, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  type.label,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                LocalizedText(
                  type.english,
                  style: const TextStyle(color: Color(0xff667085)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: _blue, size: 18),
        ],
      ),
    ),
  );
}

class _TripSearchForm extends StatelessWidget {
  const _TripSearchForm({
    required this.from,
    required this.to,
    required this.date,
    required this.passengers,
    required this.roundTrip,
    required this.onDate,
    required this.onPassengers,
    required this.onRoundTrip,
  });
  final TextEditingController from;
  final TextEditingController to;
  final DateTime date;
  final int passengers;
  final bool roundTrip;
  final VoidCallback onDate;
  final ValueChanged<int> onPassengers;
  final ValueChanged<bool> onRoundTrip;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _card(),
    child: Column(
      children: [
        TextField(
          controller: from,
          decoration: _input('من أين؟', Icons.trip_origin_rounded),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: to,
          decoration: _input('إلى أين؟', Icons.location_on_outlined),
        ),
        const SizedBox(height: 9),
        InkWell(
          onTap: onDate,
          child: InputDecorator(
            decoration: _input('تاريخ السفر', Icons.calendar_month_rounded),
            child: LocalizedText('${date.day}/${date.month}/${date.year}'),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const Expanded(
              child: LocalizedText(
                'عدد الركاب',
                style: TextStyle(color: _navy, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: passengers > 1
                  ? () => onPassengers(passengers - 1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            LocalizedText(
              '$passengers',
              style: const TextStyle(color: _blue, fontWeight: FontWeight.w900),
            ),
            IconButton(
              onPressed: () => onPassengers(passengers + 1),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            value: roundTrip,
            activeThumbColor: _blue,
            contentPadding: EdgeInsets.zero,
            title: LocalizedText(roundTrip ? 'ذهاب وعودة' : 'ذهاب فقط'),
            onChanged: onRoundTrip,
          ),
        ),
        _PrimaryButton('بحث عن رحلة', () {}),
      ],
    ),
  );
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.company, required this.onTap});
  final LandCompany company;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(17),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(radius: 17),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_landImage, fit: BoxFit.cover),
                Positioned(
                  top: 5,
                  left: 5,
                  child: _SmallBadge('${company.rating} ★'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Center(
                child: LocalizedText(
                  company.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
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

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});
  final LandTrip trip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_landImage, fit: BoxFit.cover),
                Positioned(
                  top: 7,
                  right: 7,
                  child: _SmallBadge(trip.type.label),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    '${trip.origin} ← ${trip.destination}',
                    maxLines: 1,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(trip.departure, style: const TextStyle(fontSize: 11)),
                  const Spacer(),
                  LocalizedText(
                    '${_money(trip.price)} ر.ي',
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
    ),
  );
}

class _PassengerForm extends StatelessWidget {
  const _PassengerForm({
    required this.index,
    required this.data,
    required this.onChanged,
  });
  final int index;
  final PassengerData data;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 13),
    padding: const EdgeInsets.all(14),
    decoration: _card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          'المسافر ${index + 1}',
          style: const TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: data.name,
          decoration: _input('الاسم الكامل', Icons.person_outline_rounded),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: data.gender,
          decoration: _input('الجنس', Icons.wc_rounded),
          items: [
            'ذكر',
            'أنثى',
          ].map((e) => DropdownMenuItem(value: e, child: LocalizedText(e))).toList(),
          onChanged: (v) {
            data.gender = v!;
            onChanged();
          },
        ),
        const SizedBox(height: 9),
        TextField(
          controller: data.phone,
          keyboardType: TextInputType.phone,
          decoration: _input('رقم الهاتف', Icons.phone_outlined),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: data.identityType,
          decoration: _input('نوع الهوية', Icons.badge_outlined),
          items: [
            'بطاقة شخصية',
            'جواز سفر',
            'بطاقة عائلية',
          ].map((e) => DropdownMenuItem(value: e, child: LocalizedText(e))).toList(),
          onChanged: (v) {
            data.identityType = v!;
            onChanged();
          },
        ),
        const SizedBox(height: 9),
        TextField(
          controller: data.identity,
          decoration: _input('رقم الهوية', Icons.numbers_rounded),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: data.birthDate,
          decoration: _input('تاريخ الميلاد', Icons.cake_outlined),
        ),
      ],
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    height: 178,
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
              colors: [Color(0xdd0b2c57), Color(0x220b2c57)],
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

class _OfferBanner extends StatelessWidget {
  const _OfferBanner(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    height: 135,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_landImage, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xdd155fc5), Color(0x44155fc5)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              LocalizedText(
                subtitle,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: _card(),
    child: const Column(
      children: [
        _TimelinePoint('صنعاء', '07:00 ص', 'محطة الانطلاق'),
        _TimelinePoint('ذمار', '09:00 ص', 'توقف 15 دقيقة'),
        _TimelinePoint('إب', '11:30 ص', 'توقف 20 دقيقة'),
        _TimelinePoint('تعز', '01:30 م', 'محطة الوصول'),
      ],
    ),
  );
}

class _TimelinePoint extends StatelessWidget {
  const _TimelinePoint(this.city, this.time, this.note);
  final String city;
  final String time;
  final String note;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        const CircleAvatar(radius: 8, backgroundColor: _gold),
        const SizedBox(width: 10),
        Expanded(
          child: LocalizedText(
            city,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
          ),
        ),
        LocalizedText('$time • $note', style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _Policy extends StatelessWidget {
  const _Policy(this.title, this.items);
  final String title;
  final List<String> items;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 11),
    padding: const EdgeInsets.all(14),
    decoration: _card(),
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

class _TripMini extends StatelessWidget {
  const _TripMini({required this.trip});
  final LandTrip trip;
  @override
  Widget build(BuildContext context) => Container(
    height: 105,
    clipBehavior: Clip.antiAlias,
    decoration: _card(),
    child: Row(
      children: [
        SizedBox(width: 120, child: Image.asset(_landImage, fit: BoxFit.cover)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalizedText(
                  '${trip.origin} ← ${trip.destination}',
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                LocalizedText('${trip.type.label} • ${trip.company}'),
                LocalizedText(
                  '${_money(trip.price)} ر.ي',
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

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xffe9f8f0),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _green,
          child: Icon(Icons.check_rounded, color: Colors.white, size: 36),
        ),
        SizedBox(height: 8),
        LocalizedText(
          'تم تأكيد الحجز بنجاح',
          style: TextStyle(
            color: _green,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        LocalizedText('رقم الحجز: LT-20458'),
      ],
    ),
  );
}

class _Qr extends StatelessWidget {
  const _Qr();
  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    height: 150,
    padding: const EdgeInsets.all(8),
    color: Colors.white,
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 11,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 121,
      itemBuilder: (_, i) => ColoredBox(
        color: (i * 7 + i ~/ 11 * 3) % 4 == 0 ? Colors.white : _navy,
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(radius: 6, backgroundColor: color),
      const SizedBox(width: 4),
      LocalizedText(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.action});
  final String text;
  final String? action;
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
      if (action != null)
        LocalizedText(
          action!,
          style: const TextStyle(color: _blue, fontWeight: FontWeight.bold),
        ),
    ],
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

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: _navy.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(15),
    ),
    child: LocalizedText(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: LocalizedText(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: LocalizedText(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );
}

InputDecoration _input(String label, IconData icon) => InputDecoration(
  labelText: l10n(label),
  prefixIcon: Icon(icon, color: _gold),
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

Widget _rtl(Widget child) =>
    Directionality(textDirection: localizedTextDirection, child: child);
void _notice(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: LocalizedText(message)));
