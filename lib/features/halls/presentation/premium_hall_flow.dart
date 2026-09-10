import '../../bookings/presentation/provider_booking_flow.dart';
import 'package:flutter/material.dart';
import '../../auth/presentation/booking_auth_gate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/maps/app_map_launcher.dart';
import '../../../core/reviews/service_review.dart';
import '../../../core/widgets/app_media_gallery.dart';
import '../../event_services/data/event_service_catalog.dart';
import '../../event_services/domain/event_service.dart';
import '../../event_services/presentation/event_service_visuals.dart';
import '../../event_services/presentation/event_service_flow.dart';
import '../domain/hall_booking_details.dart';

const hallCampaignBanner = 'assets/images/hall_campaign_banner.jpg';
const _hallFallback = 'assets/Services images/قاعات الافراح والمناسبات.jpg';
const _ink = Color(0xff173c2a);
const _gold = Color(0xffbd8b40);
const _cream = Color(0xfffffbf4);
const _green = Color(0xff246b35);

class HallAndEventCategoriesScreen extends StatelessWidget {
  const HallAndEventCategoriesScreen({
    super.key,
    required this.province,
    this.catalog,
  });
  final String province;
  final EventServiceCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    final source = catalog ?? eventServiceCatalog;
    return EventCatalogView(
      catalog: source,
      builder: (context) => _Rtl(
        Scaffold(
          backgroundColor: _cream,
          appBar: _bar('صالات الأفراح والمناسبات'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _Title('كل ما تحتاجه لمناسبتك'),
                LocalizedText('اختر التصنيف المناسب في $province'),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: EventPortraitCard(
                          key: const Key('occasion-category-halls'),
                          icon: Icons.apartment_rounded,
                          title: 'صالات الأفراح والمناسبات',
                          image: _hallFallback,
                          description: 'اختر الصالة والموعد والباقة المناسبة.',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PremiumHallHomeScreen(province: province),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: EventPortraitCard(
                          key: const Key('occasion-category-services'),
                          icon: Icons.celebration_rounded,
                          title: eventServicesTitle,
                          image: source.bannerImage,
                          description: 'مراكز متخصصة لكل تفاصيل مناسبتك.',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(
                                name: eventServicesId,
                              ),
                              builder: (_) => EventServicesHomeScreen(
                                province: province,
                                catalog: source,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _Title('عروض مميزة'),
                const SizedBox(height: 12),
                for (final offer in source.promotions.where(
                  (offer) =>
                      offer.isHall ||
                      source
                          .centersFor(province)
                          .any((provider) => provider.id == offer.targetId),
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: EventHeroBanner(
                      key: Key('occasion-offer-${offer.id}'),
                      title: offer.title,
                      subtitle: offer.subtitle,
                      image: offer.image,
                      label: offer.isHall
                          ? 'عروض القاعات'
                          : 'عروض مراكز الخدمات',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => offer.isHall
                              ? HallVenueScreen(
                                  name: offer.targetId,
                                  province: province,
                                )
                              : EventServiceCenterScreen(
                                  province: province,
                                  providerId: offer.targetId,
                                  catalog: source,
                                ),
                        ),
                      ),
                    ),
                  ),
                if (source.promotions.isEmpty)
                  const LocalizedText('لا توجد عروض مضافة حالياً'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumHallHomeScreen extends StatelessWidget {
  const PremiumHallHomeScreen({super.key, required this.province});
  final String province;

  static const _demoHalls = [
    'قاعة لافندر الملكية',
    'قاعة تاج سبأ',
    'قاعة بلقيس',
    'صالة الأندلس',
    'قاعة النخبة',
    'صالة أوركيد',
  ];

  static List<String> get halls => ProviderBookingFlow.current == null
      ? _demoHalls
      : ProviderBookingFlow.current!
            .loaded('halls')
            .where((s) => s.serviceType == 'event_hall')
            .map((s) => s.displayName)
            .toList();
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      appBar: _bar('صالات الأفراح والمناسبات'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            _CampaignBanner(),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: _gold),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LocalizedText(
                      'موقعك الحالي',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    LocalizedText(
                      '$province، اليمن',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SearchBox(hint: 'ابحث عن قاعة، أو صالة مناسبات'),
            const SizedBox(height: 18),
            const _Title('لحظتك تستحق مكاناً استثنائياً'),
            const LocalizedText(
              'اكتشف أفضل قاعات الأفراح والمناسبات واحجزها بسهولة.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    'الأقرب إليك',
                    onTap: () => AppMapLauncher.open(
                      context,
                      query: 'قاعات أفراح $province اليمن',
                    ),
                  ),
                  _FilterChip(
                    'الأعلى تقييماً',
                    onTap: () =>
                        _note(context, 'تم ترتيب القاعات حسب الأعلى تقييماً'),
                  ),
                  _FilterChip(
                    'الأقل سعراً',
                    onTap: () =>
                        _note(context, 'تم ترتيب القاعات حسب الأقل سعراً'),
                  ),
                  _FilterChip(
                    'المفتوحة حديثاً',
                    onTap: () =>
                        _note(context, 'تم عرض القاعات المفتوحة حديثاً'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: halls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .76,
              ),
              itemBuilder: (_, i) => _HallCard(
                name: halls[i],
                views: 74 + i * 19,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HallVenueScreen(
                      name: halls[i],
                      province: province,
                      serviceId: ProviderBookingFlow.current
                          ?.loaded('halls')
                          .where(
                            (service) => service.serviceType == 'event_hall',
                          )
                          .elementAt(i)
                          .id,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _Title('عروض هذا الأسبوع'),
            const SizedBox(height: 10),
            SizedBox(
              height: 125,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _Offer('خصم 20%', 'ينتهي خلال يومين'),
                  _Offer('زينة العروس مجاناً', 'حتى نهاية الأسبوع'),
                  _Offer('وفر 150,000 ر.ي', 'على الباقة الملكية'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HallVenueScreen extends StatelessWidget {
  const HallVenueScreen({
    super.key,
    required this.name,
    this.serviceId,
    required this.province,
  });
  final String name;
  final String? serviceId;
  final String province;
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      bottomNavigationBar: _Sticky(
        'تحقق من المواعيد',
        () => openProtectedBooking(
          context,
          nextScreen: HallDatePackageScreen(
            name: name,
            province: province,
            serviceId: serviceId,
          ),
          serviceTitle: 'قاعات أفراح ومناسبات',
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Gallery()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 105),
              sliver: SliverList.list(
                children: [
                  LocalizedText(
                    name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const LocalizedText(
                        '⭐ 4.8',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const LocalizedText(
                        '  •  96 تقييم',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton.icon(
                        onPressed: () => AppMapLauncher.open(
                          context,
                          query: 'قاعة $name شارع الخمسين $province اليمن',
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const LocalizedText('عرض على الخريطة'),
                      ),
                    ],
                  ),
                  LocalizedText('📍 شارع الخمسين – $province'),
                  const SizedBox(height: 16),
                  const _Title('أبرز المعلومات'),
                  const SizedBox(height: 9),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(Icons.groups_rounded, '250–600 ضيف'),
                      _InfoPill(Icons.square_foot, '950 م²'),
                      _InfoPill(Icons.male_rounded, 'قسم رجال'),
                      _InfoPill(Icons.female_rounded, 'قسم نساء'),
                      _InfoPill(Icons.local_parking_rounded, '120 سيارة'),
                    ],
                  ),
                  const SizedBox(height: 19),
                  const _Title('عن القاعة'),
                  const LocalizedText(
                    'قاعة فاخرة بتفاصيل معمارية راقية وتجهيزات متكاملة، صُممت لتمنح مناسبتك تجربة مميزة وخدمة احترافية من لحظة الوصول حتى نهاية الحفل.',
                  ),
                  const SizedBox(height: 19),
                  const _Title('الخدمات والمميزات'),
                  const SizedBox(height: 9),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.05,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: const [
                      _Amenity(Icons.ac_unit, 'تكييف مركزي'),
                      _Amenity(Icons.celebration, 'منصة زفاف'),
                      _Amenity(Icons.chair, 'كوشة'),
                      _Amenity(Icons.speaker, 'نظام صوت'),
                      _Amenity(Icons.lightbulb, 'إضاءة'),
                      _Amenity(Icons.electric_bolt, 'مولد كهربائي'),
                      _Amenity(Icons.local_parking, 'مواقف'),
                      _Amenity(Icons.elevator, 'مصاعد'),
                      _Amenity(Icons.meeting_room, 'غرف تجهيز'),
                      _Amenity(Icons.security, 'أمن وحراسة'),
                      _Amenity(Icons.wifi, 'Wi-Fi'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const LocalizedText('عرض جميع الخدمات'),
                  ),
                  const SizedBox(height: 19),
                  const _Title('الباقات المتاحة'),
                  const SizedBox(height: 9),
                  const _PackageRow(),
                  const SizedBox(height: 19),
                  const _Title('التقييمات'),
                  const _ReviewCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HallDatePackageScreen extends StatefulWidget {
  const HallDatePackageScreen({
    super.key,
    required this.name,
    this.serviceId,
    required this.province,
  });
  final String name;
  final String? serviceId;
  final String province;
  @override
  State<HallDatePackageScreen> createState() => _HallDatePackageScreenState();
}

class _HallDatePackageScreenState extends State<HallDatePackageScreen> {
  DateTime selected = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 1)),
  );
  int guests = 500;
  String period = 'مسائية';
  String event = 'زفاف';
  String package = 'الذهبية';
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      appBar: _bar('اختر موعد مناسبتك'),
      bottomNavigationBar: _Sticky(
        'متابعة الحجز',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HallBookingDataScreen(
              booking: HallBookingDetails(
                name: widget.name,
                serviceId: widget.serviceId,
                province: widget.province,
                date: selected,
                period: period,
                event: event,
                guests: guests,
                package: package,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 105),
        children: [
          _Section(
            child: CalendarDatePicker(
              initialDate: selected,
              firstDate: DateUtils.dateOnly(DateTime.now()),
              lastDate: DateTime(DateTime.now().year + 2),
              onDateChanged: (v) => setState(() => selected = v),
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            children: [
              _Legend(Colors.green, 'متاح'),
              _Legend(Colors.red, 'محجوز'),
              _Legend(Colors.orange, 'طلب حجز'),
              _Legend(_green, 'المحدد'),
            ],
          ),
          const SizedBox(height: 18),
          const _Title('الفترة'),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  title: 'صباحية',
                  subtitle: '9:00 ص – 1:00 م',
                  selected: period == 'صباحية',
                  onTap: () => setState(() => period = 'صباحية'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Choice(
                  title: 'مسائية',
                  subtitle: '2:00 م – 12:00 ص',
                  selected: period == 'مسائية',
                  onTap: () => setState(() => period = 'مسائية'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _Title('عدد الضيوف'),
          _Counter(
            value: guests,
            onMinus: () =>
                setState(() => guests = (guests - 50).clamp(50, 600).toInt()),
            onPlus: () =>
                setState(() => guests = (guests + 50).clamp(50, 600).toInt()),
          ),
          const SizedBox(height: 18),
          const _Title('نوع المناسبة'),
          Wrap(
            spacing: 7,
            children:
                [
                      'زفاف',
                      'خطوبة',
                      'تخرج',
                      'مناسبة عائلية',
                      'مؤتمر',
                      'عزاء',
                      'أخرى',
                    ]
                    .map(
                      (e) => ChoiceChip(
                        label: LocalizedText(e),
                        selected: event == e,
                        onSelected: (_) => setState(() => event = e),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 18),
          const _Title('اختر الباقة'),
          RadioGroup<String>(
            groupValue: package,
            onChanged: (value) => setState(() => package = value!),
            child: Column(
              children: ['الأساسية', 'الذهبية', 'الملكية']
                  .map(
                    (e) => RadioListTile<String>(
                      value: e,
                      title: LocalizedText('الباقة $e'),
                      subtitle: LocalizedText(
                        e == 'الأساسية'
                            ? '350 ضيف • 450,000 ر.ي'
                            : e == 'الذهبية'
                            ? '500 ضيف • 620,000 ر.ي'
                            : '600 ضيف • 850,000 ر.ي',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

class HallBookingDataScreen extends StatefulWidget {
  const HallBookingDataScreen({super.key, required this.booking});
  final HallBookingDetails booking;
  @override
  State<HallBookingDataScreen> createState() => _HallBookingDataScreenState();
}

class _HallBookingDataScreenState extends State<HallBookingDataScreen> {
  bool agreed = false;
  String document = 'بطاقة شخصية';
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      appBar: _bar('بيانات الحجز'),
      bottomNavigationBar: _Sticky(
        'الانتقال للدفع',
        agreed
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HallSecurePaymentScreen(booking: widget.booking),
                ),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 105),
        children: [
          const _StepperRow(current: 2),
          const SizedBox(height: 18),
          const _Title('المعلومات الشخصية'),
          _Field('الاسم الرباعي', helper: 'كما هو في البطاقة الشخصية'),
          _Field('رقم الهاتف', type: TextInputType.phone),
          _Field('رقم الواتساب', type: TextInputType.phone),
          _Field(
            'البريد الإلكتروني',
            helper: 'اختياري',
            type: TextInputType.emailAddress,
          ),
          DropdownButtonFormField<String>(
            initialValue: document,
            decoration: _input('نوع الوثيقة'),
            items: ['بطاقة شخصية', 'جواز سفر', 'بطاقة عائلية']
                .map((e) => DropdownMenuItem(value: e, child: LocalizedText(e)))
                .toList(),
            onChanged: (v) => setState(() => document = v!),
          ),
          const SizedBox(height: 10),
          _Field('رقم الوثيقة'),
          const SizedBox(height: 12),
          const _Title('تفاصيل المناسبة'),
          _Field('اسم صاحب المناسبة'),
          _Field(
            'ملاحظات خاصة',
            helper: 'يرجى تجهيز مدخل خاص للعروس.',
            lines: 3,
          ),
          _BookingSummary(booking: widget.booking),
          CheckboxListTile(
            value: agreed,
            controlAffinity: ListTileControlAffinity.leading,
            title: const LocalizedText(
              'أوافق على سياسة الحجز والإلغاء وشروط الاستخدام',
            ),
            subtitle: const LocalizedText(
              '1- يمكن إلغاء الحجز خلال 24 ساعة من عملية الحجز فقط.\n'
              '2- المحافظة على جميع أثاث القاعة ومفروشاتها.\n'
              '3- يتحمل صاحب الحجز مسؤولية أي تلفيات أو تمزيق للفراش أو الأجهزة.',
            ),
            onChanged: (v) => setState(() => agreed = v ?? false),
          ),
        ],
      ),
    ),
  );
}

class HallSecurePaymentScreen extends StatefulWidget {
  const HallSecurePaymentScreen({super.key, required this.booking});
  final HallBookingDetails booking;
  int get total => booking.total;
  @override
  State<HallSecurePaymentScreen> createState() =>
      _HallSecurePaymentScreenState();
}

class _HallSecurePaymentScreenState extends State<HallSecurePaymentScreen>
    with ProviderBookingState<HallSecurePaymentScreen> {
  bool deposit = true;
  String method = 'ون كاش';
  int get due => deposit ? (widget.total * .30).round() : widget.total;
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      appBar: _bar('الدفع الآمن'),
      bottomNavigationBar: _Sticky('تأكيد ودفع ${_money(due)} ر.ي', () async {
        await submitProviderBooking(
          ProviderBookingSelection(
            module: 'halls',
            serviceId: widget.booking.serviceId,
            serviceName: widget.booking.name,
            province: widget.booking.province,
            scheduledAt: widget.booking.start,
            metadata: {
              'event': widget.booking.event,
              'guests': widget.booking.guests,
              'package': widget.booking.package,
              'period': widget.booking.period,
            },
          ),
        );
      }),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
        children: [
          _BookingSummary(booking: widget.booking),
          const SizedBox(height: 16),
          const _Title('طريقة الدفع'),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  title: 'المحافظ الإلكترونية',
                  subtitle: 'دفع محلي سريع',
                  selected: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Choice(
                  title: 'البطاقة البنكية',
                  subtitle: 'بطاقة آمنة',
                  selected: false,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 1.75,
            children:
                [
                      'ون كاش',
                      'جوالي',
                      'جيب',
                      'فلوسك',
                      'كاك موبايلي',
                      'بنكي لايت',
                      'يمن والت',
                      'كريمي جوال',
                      'الشامل موني',
                    ]
                    .map(
                      (e) => _WalletChoice(
                        name: e,
                        selected: method == e,
                        onTap: () => setState(() => method = e),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 18),
          const _Title('نوع الدفع'),
          RadioGroup<bool>(
            groupValue: deposit,
            onChanged: (value) => setState(() => deposit = value!),
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: false,
                  title: const LocalizedText('دفع كامل'),
                  subtitle: LocalizedText('${_money(widget.total)} ر.ي'),
                ),
                RadioListTile<bool>(
                  value: true,
                  title: const LocalizedText('دفع عربون'),
                  subtitle: LocalizedText(
                    '${_money((widget.total * .30).round())} ر.ي • 30% لتأكيد الحجز',
                  ),
                ),
              ],
            ),
          ),
          if (deposit)
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocalizedText(
                    'المبلغ المتبقي',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  LocalizedText(
                    '${_money(widget.total - due)} ر.ي',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const LocalizedText(
                    'يُدفع قبل موعد المناسبة حسب سياسة القاعة المحددة من لوحة التحكم.',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: l10n('كود الخصم'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _note(context, 'تم تطبيق الكود'),
                child: const LocalizedText('تطبيق'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.lock_rounded, color: _green),
            title: LocalizedText('عملية الدفع مشفرة وآمنة'),
          ),
        ],
      ),
    ),
  );
}

class HallBookingSuccessScreen extends StatefulWidget {
  const HallBookingSuccessScreen({
    super.key,
    required this.booking,
    required this.paid,
  });
  final HallBookingDetails booking;
  String get name => booking.name;
  int get total => booking.total;
  final int paid;
  @override
  State<HallBookingSuccessScreen> createState() =>
      _HallBookingSuccessScreenState();
}

class _HallBookingSuccessScreenState extends State<HallBookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final paymentStatus = widget.paid == widget.total
        ? 'تم الدفع بالكامل'
        : 'تم دفع العربون';
    final share = 'تم تأكيد حجز ${widget.name} برقم ${booking.reference}';
    return _Rtl(
      Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 25),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: controller,
                  curve: Curves.elasticOut,
                ),
                child: const CircleAvatar(
                  radius: 43,
                  backgroundColor: _green,
                  child: Icon(
                    Icons.check_rounded,
                    size: 55,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const LocalizedText(
                'تم تأكيد حجزك بنجاح 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const LocalizedText(
                'نتمنى لك مناسبة سعيدة وتجربة لا تُنسى.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _Section(
                child: Column(
                  children: [
                    const LocalizedText('رقم الحجز'),
                    LocalizedText(
                      booking.reference,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      widget.name,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _Line('التاريخ', booking.dateLabel),
                    _Line('الفترة', booking.period),
                    _Line('عدد الضيوف', '${booking.guests}'),
                    _Line('المناسبة', booking.event),
                    _Line('الباقة', booking.package),
                  ],
                ),
              ),
              _Section(
                child: Column(
                  children: [
                    _Line('سعر الباقة', '${_money(booking.total)} ر.ي'),
                    _Line(
                      'إجمالي الحجز',
                      '${_money(widget.total)} ر.ي',
                      strong: true,
                    ),
                    _Line('تم دفع', '${_money(widget.paid)} ر.ي'),
                    _Line(
                      'المتبقي',
                      '${_money(widget.total - widget.paid)} ر.ي',
                    ),
                    const _Line('حالة الحجز', 'مؤكد', strong: true),
                    _Line('حالة الدفع', paymentStatus, strong: true),
                  ],
                ),
              ),
              _Action(
                Icons.calendar_month,
                'إضافة إلى التقويم',
                () => launchUrl(
                  Uri.parse(
                    'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent('حجز ${widget.name}')}&dates=${_calendarDate(booking.start)}/${_calendarDate(booking.end)}&details=${Uri.encodeComponent('حجز قاعة عبر تطبيق حجوزاتكم')}',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _Action(
                Icons.phone,
                'التواصل مع القاعة',
                () => launchUrl(Uri(scheme: 'tel', path: '+967700000000')),
              ),
              const SizedBox(height: 8),
              ServiceCompletionFooter(
                serviceKey: 'قاعات أفراح ومناسبات',
                serviceName: 'قاعات أفراح ومناسبات',
                invoiceTitle: 'فاتورة حجز ${widget.name}',
                invoiceReference: booking.reference,
                invoiceStatus: paymentStatus,
                invoiceDetails: [
                  ('رقم الحجز', booking.reference),
                  ('القاعة', widget.name),
                  ('التاريخ', booking.dateLabel),
                  ('الفترة', booking.period),
                  ('عدد الضيوف', '${booking.guests}'),
                  ('المناسبة', booking.event),
                  ('الباقة', booking.package),
                  ('سعر الباقة', '${_money(booking.total)} ر.ي'),
                  ('إجمالي الحجز', '${_money(widget.total)} ر.ي'),
                  ('تم دفع', '${_money(widget.paid)} ر.ي'),
                  ('المتبقي', '${_money(widget.total - widget.paid)} ر.ي'),
                  ('حالة الحجز', 'مؤكد'),
                  ('حالة الدفع', paymentStatus),
                ],
                invoiceText: share,
                onViewInvoice: () => _note(context, 'سيتم فتح الفاتورة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1672 / 941,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.asset(hallCampaignBanner, fit: BoxFit.cover),
    ),
  );
}

class _Gallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 335,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const AppMediaGallery(
          keyPrefix: 'hall-details',
          height: 335,
          accentColor: _gold,
          items: [
            AppMediaItem.image(_hallFallback, label: 'صورة القاعة'),
            AppMediaItem.image(_hallFallback, label: 'منصة الزفاف'),
            AppMediaItem.image(_hallFallback, label: 'تجهيزات القاعة'),
            AppMediaItem.video(_hallFallback, label: 'جولة فيديو للقاعة'),
          ],
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent, Colors.black26],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _Circle(Icons.arrow_forward, () => Navigator.pop(context)),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Row(
            children: [
              _Circle(Icons.favorite_border, () {}),
              const SizedBox(width: 7),
              _Circle(
                Icons.share,
                () => SharePlus.instance.share(
                  ShareParams(text: 'قاعة لافندر الملكية'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HallCard extends StatelessWidget {
  const _HallCard({
    required this.name,
    required this.views,
    required this.onTap,
  });
  final String name;
  final int views;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: _decor(),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_hallFallback, fit: BoxFit.cover),
                const Positioned(
                  top: 7,
                  left: 7,
                  child: _Circle(Icons.favorite_border, null),
                ),
                Positioned(bottom: 7, right: 7, child: _Badge('$views مشاهدة')),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: LocalizedText(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
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
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: 270,
    margin: const EdgeInsetsDirectional.only(end: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_green, _ink]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LocalizedText(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        LocalizedText(subtitle, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );
}

class _PackageRow extends StatelessWidget {
  const _PackageRow();
  @override
  Widget build(BuildContext context) => Column(
    children: const [
      _Package('الأساسية', '350 شخص', '450,000 ر.ي'),
      _Package('الذهبية', '500 شخص', '620,000 ر.ي', featured: true),
      _Package('الملكية', '600 شخص', '850,000 ر.ي'),
    ],
  );
}

class _Package extends StatelessWidget {
  const _Package(this.name, this.people, this.price, {this.featured = false});
  final String name, people, price;
  final bool featured;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: _decor(
      color: featured ? const Color(0xfffff5df) : Colors.white,
    ),
    child: Row(
      children: [
        Icon(Icons.diamond, color: featured ? _gold : _green),
        const SizedBox(width: 9),
        Expanded(
          child: LocalizedText(
            'الباقة $name\n$people',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        LocalizedText(
          price,
          style: const TextStyle(color: _green, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();
  @override
  Widget build(BuildContext context) => _Section(
    child: Column(
      children: const [
        LocalizedText(
          '⭐ 4.8 ممتاز',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        _Rating('النظافة', 4.9),
        _Rating('الخدمة', 4.8),
        _Rating('الموقع', 4.7),
        _Rating('القيمة مقابل السعر', 4.6),
      ],
    ),
  );
}

class _Rating extends StatelessWidget {
  const _Rating(this.label, this.score);
  final String label;
  final double score;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: LocalizedText(label)),
      Expanded(
        flex: 2,
        child: LinearProgressIndicator(
          value: score / 5,
          color: _gold,
          backgroundColor: Colors.black12,
        ),
      ),
      const SizedBox(width: 8),
      LocalizedText('$score'),
    ],
  );
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.booking});
  final HallBookingDetails booking;
  @override
  Widget build(BuildContext context) => _Section(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          booking.name,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        _Line('التاريخ', booking.dateLabel),
        _Line('الفترة', booking.period),
        _Line('عدد الضيوف', '${booking.guests}'),
        _Line('الباقة', booking.package),
        _Line('الإجمالي', '${_money(booking.total)} ر.ي', strong: true),
      ],
    ),
  );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (i) => Expanded(
        child: Column(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: i < current ? _green : Colors.black12,
              child: i < current - 1
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : LocalizedText(
                      '${i + 1}',
                      style: TextStyle(
                        color: i < current ? Colors.white : Colors.black54,
                      ),
                    ),
            ),
            LocalizedText(
              ['الموعد', 'البيانات', 'الدفع'][i],
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final int value;
  final VoidCallback onMinus, onPlus;
  @override
  Widget build(BuildContext context) => _Section(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: onMinus,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 100,
          child: LocalizedText(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton.filled(onPressed: onPlus, icon: const Icon(Icons.add)),
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: _decor(
        color: selected ? const Color(0xfffff5df) : Colors.white,
        border: selected ? _gold : const Color(0xffe7ded0),
      ),
      child: Column(
        children: [
          LocalizedText(
            title,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
          LocalizedText(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _WalletChoice extends StatelessWidget {
  const _WalletChoice({
    required this.name,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: _decor(
        color: selected ? const Color(0xfffff5df) : Colors.white,
        border: selected ? _gold : const Color(0xffe7ded0),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: double.infinity,
              color: const Color(0xfff4ead8),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: _gold,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: LocalizedText(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint});
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
    decoration: InputDecoration(
      hintText: l10n(hint),
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.text, {required this.onTap});
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 7),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffe8ddcd)),
          ),
          child: LocalizedText(
            text,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xffeadfce)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: _gold),
        const SizedBox(width: 5),
        LocalizedText(text),
      ],
    ),
  );
}

class _Amenity extends StatelessWidget {
  const _Amenity(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: _decor(),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _gold),
        const SizedBox(height: 5),
        LocalizedText(
          text,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        const LocalizedText(
          'شامل',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: _green,
          ),
        ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.text);
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(radius: 4, backgroundColor: color),
      const SizedBox(width: 4),
      LocalizedText(text, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(13),
    decoration: _decor(),
    child: child,
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => LocalizedText(
    text,
    style: const TextStyle(
      color: _ink,
      fontSize: 19,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: LocalizedText(
            label,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        LocalizedText(
          value,
          style: TextStyle(
            color: strong ? _green : Colors.black87,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field(this.label, {this.helper, this.type, this.lines = 1});
  final String label;
  final String? helper;
  final TextInputType? type;
  final int lines;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      keyboardType: type,
      maxLines: lines,
      decoration: _input(
        label,
      ).copyWith(helperText: helper == null ? null : l10n(helper!)),
    ),
  );
}

class _Sticky extends StatelessWidget {
  const _Sticky(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      color: Colors.white,
      child: _Primary(label: label, onTap: onTap),
    ),
  );
}

class _Primary extends StatelessWidget {
  const _Primary({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    width: double.infinity,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: LocalizedText(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: LocalizedText(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .68),
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

class _Circle extends StatelessWidget {
  const _Circle(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .92),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: _ink),
    ),
  );
}

class _Rtl extends StatelessWidget {
  const _Rtl(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: localizedTextDirection, child: child);
}

PreferredSizeWidget _bar(String title) => AppBar(
  backgroundColor: _cream,
  surfaceTintColor: Colors.transparent,
  centerTitle: true,
  title: LocalizedText(
    title,
    style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
  ),
  actions: [
    IconButton(
      onPressed: () {},
      icon: const Icon(Icons.notifications_none, color: _ink),
    ),
  ],
);
BoxDecoration _decor({
  Color color = Colors.white,
  Color border = const Color(0xffeadfce),
}) => BoxDecoration(
  color: color.withValues(alpha: .96),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: border),
  boxShadow: const [
    BoxShadow(color: Color(0x180d3322), blurRadius: 15, offset: Offset(0, 7)),
  ],
);
InputDecoration _input(String label) => InputDecoration(
  labelText: l10n(label),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
);
String _money(int value) => formatMoney(value);
String _calendarDate(DateTime value) => value
    .toUtc()
    .toIso8601String()
    .replaceAll('-', '')
    .replaceAll(':', '')
    .replaceAll(RegExp(r'\.\d+'), '');

void _note(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: LocalizedText(message)));
