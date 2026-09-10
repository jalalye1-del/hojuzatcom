import '../../bookings/presentation/provider_booking_flow.dart';
import 'package:flutter/material.dart';

import '../../../core/documents/invoice_pdf_service.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/maps/app_map_launcher.dart';
import '../../../core/reviews/service_review.dart';
import 'car_rental_flow.dart' show carRentalMasterBanner;
import 'transport_tracking_card.dart';

const _freightImage =
    'assets/Services images/تأجير السيارات والنقل الداخلي.jpg';
const _navy = Color(0xff0b2c57);
const _blue = Color(0xff155fc5);
const _gold = Color(0xffbc8638);
const _green = Color(0xff159a61);
const _surface = Color(0xfffffaf3);

String _money(int value) => formatMoney(value);
BoxDecoration _card({double radius = 19}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xffeadfce)),
  boxShadow: const [
    BoxShadow(color: Color(0x180b2c57), blurRadius: 15, offset: Offset(0, 7)),
  ],
);

enum FreightSize { small, medium, large }

extension FreightSizeDetails on FreightSize {
  String get label => switch (this) {
    FreightSize.small => 'شحن صغير',
    FreightSize.medium => 'شحن متوسط',
    FreightSize.large => 'شحن كبير',
  };
  String get description => switch (this) {
    FreightSize.small => 'طرود ومستندات وشحنات خفيفة',
    FreightSize.medium => 'أثاث وأجهزة وبضائع متوسطة',
    FreightSize.large => 'حمولات كبيرة ونقل تجاري',
  };
  String get vehicle => switch (this) {
    FreightSize.small => 'Van / Mini truck',
    FreightSize.medium => 'Medium truck',
    FreightSize.large => 'Heavy truck',
  };
  IconData get icon => switch (this) {
    FreightSize.small => Icons.local_shipping_outlined,
    FreightSize.medium => Icons.fire_truck_rounded,
    FreightSize.large => Icons.fire_truck_outlined,
  };
}

class FreightOffice {
  const FreightOffice(
    this.name,
    this.kind,
    this.rating,
    this.shipments,
    this.city, {
    this.serviceId,
    this.serviceName,
    this.basePrice,
  });
  final String name;
  final String kind;
  final double rating;
  final int shipments;
  final String city;
  final String? serviceId, serviceName;
  final int? basePrice;
}

const _demoFreightOffices = [
  FreightOffice('الأمان للشحن والنقل', 'متعدد', 4.9, 2380, 'صنعاء'),
  FreightOffice('وصلني للشحن السريع', 'صغير', 4.8, 1940, 'إب'),
  FreightOffice('الرواد للنقل الثقيل', 'كبير', 4.8, 870, 'عدن'),
  FreightOffice('المدينة لنقل الأثاث', 'متوسط', 4.7, 1250, 'تعز'),
  FreightOffice('السعيدة للخدمات اللوجستية', 'متعدد', 4.7, 2100, 'الحديدة'),
  FreightOffice('حضرموت للشحن', 'متعدد', 4.8, 1760, 'المكلا'),
];

class FreightDraft {
  FreightDraft({required this.office, required this.quoteOnly});
  final FreightOffice office;
  final bool quoteOnly;
  FreightSize size = FreightSize.medium;
  String pickupProvince = 'صنعاء';
  String pickupCity = 'صنعاء';
  String pickupAddress = '';
  String deliveryProvince = 'تعز';
  String deliveryCity = 'تعز';
  String deliveryAddress = '';
  String cargoType = 'طرد';
  String volume = 'متوسط';
  double weight = 50;
  double length = 40;
  double width = 100;
  double height = 40;
  int pieces = 4;
  int itemValue = 20000;
  bool packaging = true;
  bool loading = true;
  bool unloading = true;
  bool fragile = true;
  bool insurance = false;
  int get cargoValue => itemValue * pieces;
  int get freightCost => office.basePrice ?? pieces * 4000;
  int get extras => ProviderBookingFlow.current != null
      ? 0
      : (packaging ? pieces * 1000 : 0) +
            (loading ? 1000 : 0) +
            (unloading ? 1000 : 0) +
            (fragile ? pieces * 500 : 0);
  int get insuranceCost => ProviderBookingFlow.current == null && insurance
      ? (cargoValue * .2).round()
      : 0;
  int get total => freightCost + extras + insuranceCost;
}

class FreightHomeScreen extends StatelessWidget {
  const FreightHomeScreen({super.key, required this.province});
  final String province;
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('الشحن الداخلي'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            _Banner(
              title: 'الشحن الداخلي',
              subtitle: '$province • حلول آمنة وسريعة من الباب إلى الباب',
            ),
            const SizedBox(height: 13),
            Container(
              decoration: _card(radius: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n('ابحث عن مكتب أو خدمة شحن'),
                  prefixIcon: const Icon(Icons.search_rounded, color: _blue),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _Heading('اختر حجم الشحن'),
            const SizedBox(height: 10),
            Row(
              children: FreightSize.values
                  .map(
                    (size) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _FreightSizeCard(
                          size: size,
                          onTap: () async {
                            final offices = freightOffices
                                .where((office) => office.city == province)
                                .toList();
                            if (offices.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: LocalizedText(
                                    'لا توجد خدمات شحن متاحة في هذه المحافظة بعد.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final office = offices.length == 1
                                ? offices.single
                                : await showDialog<FreightOffice>(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                      title: const LocalizedText(
                                        'اختر مقدم خدمة الشحن',
                                      ),
                                      children: offices
                                          .map(
                                            (office) => SimpleDialogOption(
                                              onPressed: () => Navigator.pop(
                                                context,
                                                office,
                                              ),
                                              child: Text(office.name),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );
                            if (office == null || !context.mounted) return;
                            final draft = FreightDraft(
                              office: office,
                              quoteOnly: false,
                            )..size = size;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FreightRequestScreen(draft: draft),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const _Heading('العروض المميزة'),
            const SizedBox(height: 10),
            const Column(
              children: [
                _Offer(
                  'خصم 20% على نقل الأثاث',
                  'تغليف وتحميل مجاني للطلبات المختارة',
                ),
                SizedBox(height: 10),
                _Offer(
                  'شحن الطرود بسعر موحد',
                  'تتبع مباشر وتسليم موثق داخل المدينة',
                ),
                SizedBox(height: 10),
                _Offer(
                  'حلول للشركات والمتاجر',
                  'أسعار شهرية وخدمة عملاء مخصصة',
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _Heading('شركات ومكاتب الشحن الداخلي'),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: freightOffices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 11,
                mainAxisSpacing: 13,
                childAspectRatio: .78,
              ),
              itemBuilder: (context, index) => _OfficeCard(
                office: freightOffices[index],
                onTap: () => freightOffices.isEmpty
                    ? null
                    : Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FreightOfficeScreen(
                            office: freightOffices[index],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class FreightOfficeScreen extends StatelessWidget {
  const FreightOfficeScreen({super.key, required this.office});
  final FreightOffice office;
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar(office.name),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            _Banner(
              title: office.name,
              subtitle: '${office.city} • مكتب شحن ${office.kind}',
            ),
            const SizedBox(height: 13),
            Container(
              decoration: _card(radius: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n('عن ماذا تبحث؟'),
                  prefixIcon: const Icon(Icons.search_rounded, color: _blue),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    Icons.star_rounded,
                    '${office.rating}',
                    'التقييم',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    Icons.local_shipping_rounded,
                    office.kind,
                    'نوع المكتب',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    Icons.inventory_2_outlined,
                    '${office.shipments}',
                    'شحنة منفذة',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _card(),
              child: Column(
                children: [
                  _Info('الموقع الرئيسي', '${office.city}، الدائري'),
                  const _Info('الخدمات الإضافية', 'تغليف، تحميل، تفريغ، تأمين'),
                  const Divider(),
                  const _Branch('صنعاء', 'شارع الستين', '777 111 222'),
                  const _Branch('عدن', 'المنصورة', '777 222 333'),
                  const _Branch('تعز', 'شارع جمال', '777 333 444'),
                  const _Branch('إب', 'الدائري', '777 444 555'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _Heading('أسطول الشحن'),
            const SizedBox(height: 9),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: FreightSize.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => Container(
                  width: 180,
                  clipBehavior: Clip.antiAlias,
                  decoration: _card(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(_freightImage, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: const Color(0xcc0b2c57),
                          padding: const EdgeInsets.all(8),
                          child: LocalizedText(
                            FreightSize.values[index].vehicle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _Outline(
                    Icons.request_quote_outlined,
                    'طلب عرض سعر',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FreightRequestScreen(
                          draft: FreightDraft(office: office, quoteOnly: true),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Primary(
                    'احجز الآن',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FreightRequestScreen(
                          draft: FreightDraft(office: office, quoteOnly: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class FreightRequestScreen extends StatefulWidget {
  const FreightRequestScreen({super.key, required this.draft});
  final FreightDraft draft;
  @override
  State<FreightRequestScreen> createState() => _FreightRequestScreenState();
}

class _FreightRequestScreenState extends State<FreightRequestScreen> {
  late final pickupAddress = TextEditingController(
    text: widget.draft.pickupAddress,
  );
  late final deliveryAddress = TextEditingController(
    text: widget.draft.deliveryAddress,
  );
  @override
  void dispose() {
    pickupAddress.dispose();
    deliveryAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar(
        widget.draft.quoteOnly ? 'طلب عرض سعر' : 'حجز خدمة الشحن',
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _Primary(
            widget.draft.quoteOnly ? 'إنشاء عرض سعر' : 'متابعة الحجز',
            () {
              widget.draft.pickupAddress = pickupAddress.text;
              widget.draft.deliveryAddress = deliveryAddress.text;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FreightSummaryScreen(draft: widget.draft),
                ),
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            _Banner(
              title: widget.draft.office.name,
              subtitle: widget.draft.quoteOnly
                  ? 'أدخل البيانات للحصول على عرض سعر واضح'
                  : 'أدخل بيانات الشحنة لإتمام الحجز',
            ),
            const SizedBox(height: 16),
            const _Heading('نوع النقل'),
            const SizedBox(height: 9),
            Row(
              children: FreightSize.values
                  .map(
                    (size) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: LocalizedText(
                              size.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          selected: widget.draft.size == size,
                          showCheckmark: false,
                          selectedColor: const Color(0xffffecd0),
                          onSelected: (_) =>
                              setState(() => widget.draft.size = size),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _LocationForm(
              title: 'موقع استلام الشحنة',
              province: widget.draft.pickupProvince,
              city: widget.draft.pickupCity,
              address: pickupAddress,
            ),
            const SizedBox(height: 12),
            _LocationForm(
              title: 'موقع التسليم',
              province: widget.draft.deliveryProvince,
              city: widget.draft.deliveryCity,
              address: deliveryAddress,
            ),
            const SizedBox(height: 16),
            const _Heading('بيانات الشحنة'),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: widget.draft.cargoType,
              decoration: _input('نوع الشحنة'),
              items:
                  [
                        'مستندات',
                        'طرد',
                        'أجهزة',
                        'أثاث',
                        'بضائع',
                        'مواد تجارية',
                        'أخرى',
                      ]
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e, child: LocalizedText(e)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => widget.draft.cargoType = v!),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: widget.draft.volume,
              decoration: _input('الحجم'),
              items: ['صغير', 'متوسط', 'كبير']
                  .map(
                    (e) => DropdownMenuItem(value: e, child: LocalizedText(e)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => widget.draft.volume = v!),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    'الوزن kg / ton',
                    widget.draft.weight,
                    (v) => widget.draft.weight = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    'عدد القطع',
                    widget.draft.pieces.toDouble(),
                    (v) => widget.draft.pieces = v.round(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    'الطول سم',
                    widget.draft.length,
                    (v) => widget.draft.length = v,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _NumberField(
                    'العرض سم',
                    widget.draft.width,
                    (v) => widget.draft.width = v,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _NumberField(
                    'الارتفاع سم',
                    widget.draft.height,
                    (v) => widget.draft.height = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _NumberField(
              'قيمة القطعة ر.ي',
              widget.draft.itemValue.toDouble(),
              (v) => widget.draft.itemValue = v.round(),
            ),
            const SizedBox(height: 14),
            _Switch(
              'هل تحتاج تغليف؟',
              widget.draft.packaging,
              (v) => setState(() => widget.draft.packaging = v),
            ),
            _Switch(
              'هل تحتاج تحميل؟',
              widget.draft.loading,
              (v) => setState(() => widget.draft.loading = v),
            ),
            _Switch(
              'هل تحتاج تفريغ؟',
              widget.draft.unloading,
              (v) => setState(() => widget.draft.unloading = v),
            ),
            _Switch(
              'هل الشحنة قابلة للكسر؟',
              widget.draft.fragile,
              (v) => setState(() => widget.draft.fragile = v),
            ),
            _Switch(
              'تأمين الشحنة 20%',
              widget.draft.insurance,
              (v) => setState(() => widget.draft.insurance = v),
            ),
            const _Info('الحمولة القصوى', 'حسب المركبة المختارة'),
          ],
        ),
      ),
    ),
  );
}

class FreightSummaryScreen extends StatelessWidget {
  const FreightSummaryScreen({super.key, required this.draft});
  final FreightDraft draft;

  List<(String, String)> get _pdfDetails => [
    ('الشركة', draft.office.name),
    ('نوع النقل', '${draft.size.label} • ${draft.size.vehicle}'),
    (
      'موقع الاستلام',
      '${draft.pickupProvince}، ${draft.pickupCity}، ${draft.pickupAddress}',
    ),
    (
      'موقع التسليم',
      '${draft.deliveryProvince}، ${draft.deliveryCity}، ${draft.deliveryAddress}',
    ),
    ('نوع الشحنة', draft.cargoType),
    ('الحجم', draft.volume),
    ('الوزن', '${draft.weight} kg'),
    ('الأبعاد', '${draft.length} × ${draft.width} × ${draft.height} سم'),
    ('عدد القطع', '${draft.pieces}'),
    ('قيمة الشحنة', '${_money(draft.cargoValue)} ر.ي'),
    ('تكاليف الشحن', '${_money(draft.freightCost)} ر.ي'),
    ('الإضافات المعتمدة', '${_money(draft.extras)} ر.ي'),
    ('تأمين الشحنة', '${_money(draft.insuranceCost)} ر.ي'),
    ('الإجمالي المطلوب', '${_money(draft.total)} ر.ي'),
    ('المركبة المخصصة', 'مركبة الشحن المخصصة'),
    ('المسافة', '12 كم'),
    ('التقييم', '4.9'),
    ('الحالة', 'جاهزة للاستلام'),
  ];
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar(draft.quoteOnly ? 'تفاصيل عرض السعر' : 'تفاصيل الشحن'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            _Banner(
              title: draft.office.name,
              subtitle: '${draft.size.label} • ${draft.size.vehicle}',
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _card(),
              child: Column(
                children: [
                  _Info(
                    'موقع الاستلام',
                    '${draft.pickupProvince}، ${draft.pickupCity}، ${draft.pickupAddress}',
                  ),
                  _Info(
                    'موقع التسليم',
                    '${draft.deliveryProvince}، ${draft.deliveryCity}، ${draft.deliveryAddress}',
                  ),
                  _Info('نوع الشحنة', draft.cargoType),
                  _Info('الحجم', draft.volume),
                  _Info('الوزن', '${draft.weight} kg'),
                  _Info(
                    'الأبعاد',
                    '${draft.length} × ${draft.width} × ${draft.height} سم',
                  ),
                  _Info('عدد القطع', '${draft.pieces}'),
                  _Info('قيمة الشحنة', '${_money(draft.cargoValue)} ر.ي'),
                  const Divider(),
                  _Info('تكاليف الشحن', '${_money(draft.freightCost)} ر.ي'),
                  _Info('الإضافات المعتمدة', '${_money(draft.extras)} ر.ي'),
                  _Info('تأمين الشحنة', '${_money(draft.insuranceCost)} ر.ي'),
                  _Info(
                    'الإجمالي المطلوب',
                    '${_money(draft.total)} ر.ي',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            const TransportTrackingCard(
              title: 'مركبة الشحن المخصصة',
              distance: '12 كم',
              rating: 4.9,
              status: 'جاهزة للاستلام',
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _Primary(
                    'استكمال الحجز',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FreightPaymentScreen(draft: draft),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Outline(Icons.download_rounded, 'حفظ العرض', () async {
                    try {
                      await InvoicePdfService.save(
                        fileName: 'freight_quote_${draft.office.name}',
                        title: 'عرض سعر الشحن',
                        reference:
                            'QT-${DateTime.now().millisecondsSinceEpoch}',
                        details: _pdfDetails,
                        status: 'عرض سعر',
                      );
                      if (context.mounted) {
                        _notice(context, 'تم حفظ عرض السعر بصيغة PDF');
                      }
                    } on Object {
                      if (context.mounted) {
                        _notice(
                          context,
                          'تعذر حفظ عرض السعر. تحقق من أذونات الجهاز وحاول مجددًا.',
                        );
                      }
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _Outline(Icons.share_rounded, 'مشاركة العرض', () async {
              try {
                await InvoicePdfService.share(
                  fileName: 'freight_quote_${draft.office.name}',
                  title: 'عرض سعر الشحن',
                  reference: 'QT-${DateTime.now().millisecondsSinceEpoch}',
                  details: _pdfDetails,
                  status: 'عرض سعر',
                );
              } on Object {
                if (context.mounted) {
                  _notice(context, 'تعذر مشاركة عرض السعر. حاول مجددًا.');
                }
              }
            }),
          ],
        ),
      ),
    ),
  );
}

class FreightPaymentScreen extends StatefulWidget {
  const FreightPaymentScreen({super.key, required this.draft});
  final FreightDraft draft;
  @override
  State<FreightPaymentScreen> createState() => _FreightPaymentScreenState();
}

class _FreightPaymentScreenState extends State<FreightPaymentScreen>
    with ProviderBookingState<FreightPaymentScreen> {
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
      appBar: _appBar('الدفع المالي'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _Primary(
            'استكمال الدفع',
            wallet == null
                ? null
                : () async {
                    await submitProviderBooking(
                      ProviderBookingSelection(
                        module: 'freight',
                        serviceId: widget.draft.office.serviceId,
                        serviceName:
                            widget.draft.office.serviceName ??
                            widget.draft.size.label,
                        providerName: widget.draft.office.name,
                        province: widget.draft.office.city,
                        metadata: {
                          'pickup_address': widget.draft.pickupAddress,
                          'delivery_address': widget.draft.deliveryAddress,
                          'pickup_city': widget.draft.pickupCity,
                          'delivery_city': widget.draft.deliveryCity,
                          'weight': widget.draft.weight,
                          'pieces': widget.draft.pieces,
                          'cargo_type': widget.draft.cargoType,
                        },
                      ),
                    );
                  },
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            _Banner(
              title: widget.draft.office.name,
              subtitle:
                  '${widget.draft.size.label} • إجمالي ${_money(widget.draft.total)} ر.ي',
            ),
            const SizedBox(height: 16),
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

class FreightInvoiceScreen extends StatelessWidget {
  const FreightInvoiceScreen({
    super.key,
    required this.draft,
    required this.wallet,
  });
  final FreightDraft draft;
  final String wallet;
  String get text =>
      'فاتورة شحن داخلي\n${draft.office.name}\n${draft.pickupCity} إلى ${draft.deliveryCity}\n${draft.size.label}\nالإجمالي ${_money(draft.total)} ر.ي';
  List<(String, String)> get invoiceDetails => [
    ('الشركة', draft.office.name),
    ('نوع النقل', '${draft.size.label} • ${draft.size.vehicle}'),
    (
      'موقع الاستلام',
      '${draft.pickupProvince}، ${draft.pickupCity}، ${draft.pickupAddress}',
    ),
    (
      'موقع التسليم',
      '${draft.deliveryProvince}، ${draft.deliveryCity}، ${draft.deliveryAddress}',
    ),
    ('نوع الشحنة', draft.cargoType),
    ('الحجم', draft.volume),
    ('الوزن', '${draft.weight} kg'),
    ('الأبعاد', '${draft.length} × ${draft.width} × ${draft.height} سم'),
    ('عدد القطع', '${draft.pieces}'),
    ('قيمة الشحنة', '${_money(draft.cargoValue)} ر.ي'),
    ('تكاليف الشحن', '${_money(draft.freightCost)} ر.ي'),
    ('الإضافات', '${_money(draft.extras)} ر.ي'),
    ('تأمين الشحنة', '${_money(draft.insuranceCost)} ر.ي'),
    ('طريقة الدفع', wallet),
    ('الإجمالي', '${_money(draft.total)} ر.ي'),
    ('مركبة التتبع', 'شاحنة الأمان 24'),
    ('المسافة', '8 كم عن موقع التسليم'),
    ('التقييم', '4.9'),
    ('الحالة', 'الشحنة في الطريق'),
  ];
  @override
  Widget build(BuildContext context) => _rtl(
    Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('تفاصيل الفاتورة'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            const _Success(),
            const SizedBox(height: 13),
            _Banner(
              title: draft.office.name,
              subtitle: '${draft.size.label} • ${draft.size.vehicle}',
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _card(),
              child: Column(
                children: [
                  _Info(
                    'موقع الاستلام',
                    '${draft.pickupProvince}، ${draft.pickupCity}، ${draft.pickupAddress}',
                  ),
                  _Info(
                    'موقع التسليم',
                    '${draft.deliveryProvince}، ${draft.deliveryCity}، ${draft.deliveryAddress}',
                  ),
                  _Info('نوع الشحنة', draft.cargoType),
                  _Info('الحجم', draft.volume),
                  _Info('الوزن', '${draft.weight} kg'),
                  _Info(
                    'الأبعاد',
                    '${draft.length} × ${draft.width} × ${draft.height} سم',
                  ),
                  _Info('عدد القطع', '${draft.pieces}'),
                  _Info('قيمة الشحنة', '${_money(draft.cargoValue)} ر.ي'),
                  _Info('تكاليف الشحن', '${_money(draft.freightCost)} ر.ي'),
                  _Info('الإضافات', '${_money(draft.extras)} ر.ي'),
                  _Info('تأمين الشحنة', '${_money(draft.insuranceCost)} ر.ي'),
                  _Info('طريقة الدفع', wallet),
                  _Info('الإجمالي', '${_money(draft.total)} ر.ي', strong: true),
                ],
              ),
            ),
            const SizedBox(height: 13),
            const TransportTrackingCard(
              title: 'شاحنة الأمان 24',
              distance: '8 كم عن موقع التسليم',
              rating: 4.9,
              status: 'الشحنة في الطريق',
            ),
            const SizedBox(height: 13),
            _Outline(Icons.file_download_outlined, 'تحميل الفاتورة', () async {
              try {
                await InvoicePdfService.save(
                  fileName: 'freight_invoice_${draft.office.name}',
                  title: 'فاتورة الشحن الداخلي',
                  reference: 'FR-${draft.office.name}',
                  details: invoiceDetails,
                  status: 'تم تأكيد الحجز بنجاح',
                );
                if (context.mounted) {
                  _notice(context, 'تم حفظ الفاتورة بصيغة PDF');
                }
              } on Object {
                if (context.mounted) {
                  _notice(
                    context,
                    'تعذر حفظ الفاتورة. تحقق من أذونات الجهاز وحاول مجددًا.',
                  );
                }
              }
            }),
            const SizedBox(height: 9),
            ServiceCompletionFooter(
              serviceKey: 'تأجير السيارات والنقل البري والشحن الداخلي',
              serviceName: 'الشحن الداخلي',
              invoiceTitle: 'فاتورة الشحن الداخلي',
              invoiceReference: 'FR-${draft.office.name}',
              invoiceStatus: 'تم تأكيد الحجز بنجاح',
              invoiceDetails: invoiceDetails,
              invoiceText: text,
              onViewInvoice: () => _notice(context, 'الفاتورة معروضة بالفعل'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FreightSizeCard extends StatelessWidget {
  const _FreightSizeCard({required this.size, required this.onTap});
  final FreightSize size;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 125,
      padding: const EdgeInsets.all(8),
      decoration: _card(radius: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(size.icon, color: _gold, size: 31),
          const SizedBox(height: 5),
          LocalizedText(
            size.label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          LocalizedText(
            size.description,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({required this.office, required this.onTap});
  final FreightOffice office;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(radius: 18),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_freightImage, fit: BoxFit.cover),
                Positioned(top: 7, left: 7, child: _Tag('${office.rating} ★')),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: LocalizedText(
                  office.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
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

class _Offer extends StatelessWidget {
  const _Offer(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 150,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_blue, _navy]),
      borderRadius: BorderRadius.circular(19),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    padding: const EdgeInsets.all(7),
    decoration: _card(radius: 15),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _gold),
        LocalizedText(
          value,
          maxLines: 1,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
        ),
        LocalizedText(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9),
        ),
      ],
    ),
  );
}

class _Branch extends StatelessWidget {
  const _Branch(this.city, this.address, this.phone);
  final String city;
  final String address;
  final String phone;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.location_city_rounded, color: _gold),
    title: LocalizedText(
      '$city • $address',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: LocalizedText(phone),
  );
}

class _LocationForm extends StatelessWidget {
  const _LocationForm({
    required this.title,
    required this.province,
    required this.city,
    required this.address,
  });
  final String title;
  final String province;
  final String city;
  final TextEditingController address;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          title,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 9),
        TextFormField(initialValue: province, decoration: _input('المحافظة')),
        const SizedBox(height: 8),
        TextFormField(initialValue: city, decoration: _input('المدينة')),
        const SizedBox(height: 8),
        TextField(controller: address, decoration: _input('العنوان')),
        const SizedBox(height: 8),
        _Outline(
          Icons.map_outlined,
          'تحديد الموقع على الخريطة',
          () => AppMapLauncher.open(
            context,
            query: '$province $city ${address.text}',
          ),
        ),
      ],
    ),
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField(this.label, this.value, this.onChanged);
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value.toString(),
    keyboardType: TextInputType.number,
    decoration: _input(label),
    onChanged: (v) => onChanged(double.tryParse(v) ?? value),
  );
}

class _Switch extends StatelessWidget {
  const _Switch(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    activeThumbColor: _blue,
    title: LocalizedText(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    tileColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    onChanged: onChanged,
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
          padding: const EdgeInsets.all(15),
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

class _Success extends StatelessWidget {
  const _Success();
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
        LocalizedText('رقم الشحنة: FR-20458'),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => LocalizedText(
    text,
    style: const TextStyle(
      color: _navy,
      fontSize: 19,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Flexible(
          child: LocalizedText(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: strong ? _blue : const Color(0xff5f6670),
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _navy.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(15),
    ),
    child: LocalizedText(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _Primary extends StatelessWidget {
  const _Primary(this.label, this.onTap);
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
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _Outline extends StatelessWidget {
  const _Outline(this.icon, this.label, this.onTap);
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

InputDecoration _input(String label) => InputDecoration(
  labelText: l10n(label),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xffe5d8c5)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
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

List<FreightOffice> get freightOffices {
  final flow = ProviderBookingFlow.current;
  if (flow == null) return _demoFreightOffices;
  return flow
      .loaded('freight')
      .map(
        (s) => FreightOffice(
          s.provider?.displayName ?? '',
          s.displayName,
          0,
          0,
          s.provider?.province ?? '',
          serviceId: s.id,
          serviceName: s.displayName,
          basePrice: s.basePrice,
        ),
      )
      .toList();
}
