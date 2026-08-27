import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/maps/app_map_launcher.dart';
import '../../../core/reviews/service_review.dart';

const hallCampaignBanner = 'assets/images/hall_campaign_banner.jpg';
const _hallFallback = 'assets/Services images/قاعات الافراح والمناسبات.jpg';
const _ink = Color(0xff173c2a);
const _gold = Color(0xffbd8b40);
const _cream = Color(0xfffffbf4);
const _green = Color(0xff246b35);

class PremiumHallHomeScreen extends StatelessWidget {
  const PremiumHallHomeScreen({super.key, required this.province});
  final String province;

  static const halls = [
    'قاعة لافندر الملكية',
    'قاعة تاج سبأ',
    'قاعة بلقيس',
    'صالة الأندلس',
    'قاعة النخبة',
    'صالة أوركيد',
  ];

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
                    onTap: () => _note(context, 'تم ترتيب القاعات حسب الأعلى تقييماً'),
                  ),
                  _FilterChip(
                    'الأقل سعراً',
                    onTap: () => _note(context, 'تم ترتيب القاعات حسب الأقل سعراً'),
                  ),
                  _FilterChip(
                    'المفتوحة حديثاً',
                    onTap: () => _note(context, 'تم عرض القاعات المفتوحة حديثاً'),
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
                    builder: (_) =>
                        HallVenueScreen(name: halls[i], province: province),
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
    required this.province,
  });
  final String name;
  final String province;
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      bottomNavigationBar: _Sticky(
        'تحقق من المواعيد',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HallDatePackageScreen(name: name, province: province),
          ),
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
                  Row(
                    children: [
                      const LocalizedText(
                        '⭐ 4.8',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const LocalizedText(
                        '  •  96 تقييم',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const Spacer(),
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
                      _Amenity(Icons.camera_alt, 'تصوير', included: false),
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
    required this.province,
  });
  final String name;
  final String province;
  @override
  State<HallDatePackageScreen> createState() => _HallDatePackageScreenState();
}

class _HallDatePackageScreenState extends State<HallDatePackageScreen> {
  DateTime selected = DateTime(2026, 9, 12);
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
            builder: (_) =>
                HallAddonsScreen(name: widget.name, province: widget.province),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 105),
        children: [
          _Section(
            child: CalendarDatePicker(
              initialDate: selected,
              firstDate: DateTime.now(),
              lastDate: DateTime(2028),
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

class HallAddonsScreen extends StatefulWidget {
  const HallAddonsScreen({
    super.key,
    required this.name,
    required this.province,
  });
  final String name;
  final String province;
  @override
  State<HallAddonsScreen> createState() => _HallAddonsScreenState();
}

class _HallAddonsScreenState extends State<HallAddonsScreen> {
  final selected = <String>{'تصوير فوتوغرافي + فيديو'};
  int speakers = 2;
  int cake = 75000;
  int flowers = 95000;
  int get extras =>
      (selected.contains('تصوير فوتوغرافي + فيديو') ? 120000 : 0) +
      (selected.contains('تنسيق وزينة القاعة') ? 150000 : 0) +
      (selected.contains('نظام صوت إضافي')
          ? 80000 + ((speakers - 2) ~/ 2) * 30000
          : 0) +
      (selected.contains('ترتة المناسبة') ? cake : 0) +
      (selected.contains('تنسيق الزهور') ? flowers : 0);
  void toggle(String value) => setState(
    () =>
        selected.contains(value) ? selected.remove(value) : selected.add(value),
  );
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      appBar: _bar('خصص مناسبتك'),
      bottomNavigationBar: _Sticky(
        'متابعة',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HallBookingDataScreen(name: widget.name, extras: extras),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 105),
        children: [
          const LocalizedText('أضف الخدمات التي تحتاجها للحصول على تجربة متكاملة.'),
          const SizedBox(height: 15),
          const _Title('مشمول في الباقة'),
          const _Included(),
          const SizedBox(height: 18),
          const _Title('الخدمات الإضافية'),
          _Addon(
            title: 'بوفيه فاخر',
            price: '',
            icon: Icons.restaurant,
            selected: selected.contains('بوفيه فاخر'),
            onTap: () => toggle('بوفيه فاخر'),
            buttonAfterChild: true,
            child: const _MealTable(),
          ),
          _PhotoStrip(
            captions: const ['ضيافة ملكية', 'حلويات', 'مشروبات'],
            onTap: (caption) => _showHospitalityDetails(context, caption),
          ),
          _Addon(
            title: 'تصوير فوتوغرافي + فيديو',
            price: '120,000 ر.ي',
            icon: Icons.camera_alt,
            selected: selected.contains('تصوير فوتوغرافي + فيديو'),
            onTap: () => toggle('تصوير فوتوغرافي + فيديو'),
          ),
          _Addon(
            title: 'تنسيق وزينة القاعة',
            price: '150,000 ر.ي',
            icon: Icons.auto_awesome,
            selected: selected.contains('تنسيق وزينة القاعة'),
            onTap: () => toggle('تنسيق وزينة القاعة'),
          ),
          const _PhotoStrip(captions: ['زينة ذهبية', 'مدخل العروس', 'كوشة']),
          _Addon(
            title: 'نظام صوت إضافي',
            price: '${80000 + ((speakers - 2) ~/ 2) * 30000} ر.ي',
            icon: Icons.speaker,
            selected: selected.contains('نظام صوت إضافي'),
            onTap: () => toggle('نظام صوت إضافي'),
            child: _Counter(
              value: speakers,
              step: 2,
              onMinus: () =>
                  setState(() => speakers = (speakers - 2).clamp(2, 8).toInt()),
              onPlus: () =>
                  setState(() => speakers = (speakers + 2).clamp(2, 8).toInt()),
            ),
          ),
          _Addon(
            title: 'ترتة المناسبة',
            price: '$cake ر.ي',
            icon: Icons.cake,
            selected: selected.contains('ترتة المناسبة'),
            onTap: () => toggle('ترتة المناسبة'),
          ),
          const _PhotoStrip(
            captions: ['75,000 ر.ي', '95,000 ر.ي', '120,000 ر.ي'],
          ),
          _Addon(
            title: 'تنسيق الزهور',
            price: '$flowers ر.ي',
            icon: Icons.local_florist,
            selected: selected.contains('تنسيق الزهور'),
            onTap: () => toggle('تنسيق الزهور'),
          ),
          const _PhotoStrip(
            captions: ['95,000 ر.ي', '110,000 ر.ي', '140,000 ر.ي'],
          ),
          const SizedBox(height: 12),
          _Summary(extras: extras),
        ],
      ),
    ),
  );
}

class HallBookingDataScreen extends StatefulWidget {
  const HallBookingDataScreen({
    super.key,
    required this.name,
    required this.extras,
  });
  final String name;
  final int extras;
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
                  builder: (_) => HallSecurePaymentScreen(
                    name: widget.name,
                    total: 620000 + widget.extras,
                  ),
                ),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 105),
        children: [
          const _StepperRow(current: 3),
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
            items: [
              'بطاقة شخصية',
              'جواز سفر',
              'بطاقة عائلية',
            ].map((e) => DropdownMenuItem(value: e, child: LocalizedText(e))).toList(),
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
          _BookingSummary(name: widget.name, total: 620000 + widget.extras),
          CheckboxListTile(
            value: agreed,
            controlAffinity: ListTileControlAffinity.leading,
            title: const LocalizedText('أوافق على سياسة الحجز والإلغاء وشروط الاستخدام'),
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
  const HallSecurePaymentScreen({
    super.key,
    required this.name,
    required this.total,
  });
  final String name;
  final int total;
  @override
  State<HallSecurePaymentScreen> createState() =>
      _HallSecurePaymentScreenState();
}

class _HallSecurePaymentScreenState extends State<HallSecurePaymentScreen> {
  bool deposit = true;
  String method = 'ون كاش';
  int get due => deposit ? (widget.total * .30).round() : widget.total;
  @override
  Widget build(BuildContext context) => _Rtl(
    Scaffold(
      backgroundColor: _cream,
      appBar: _bar('الدفع الآمن'),
      bottomNavigationBar: _Sticky(
        'تأكيد ودفع ${_money(due)} ر.ي',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HallBookingSuccessScreen(
              name: widget.name,
              total: widget.total,
              paid: due,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
        children: [
          _BookingSummary(name: widget.name, total: widget.total),
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
            children: [
              'ون كاش',
              'جوالي',
              'جيب',
              'فلوسك',
              'كاك موبايلي',
              'بنكي لايت',
              'يمن والت',
              'كريمي جوال',
              'الشامل موني',
            ].map(
              (e) => ChoiceChip(
                label: FittedBox(child: LocalizedText(e)),
                selected: method == e,
                onSelected: (_) => setState(() => method = e),
              ),
            ).toList(),
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
    required this.name,
    required this.total,
    required this.paid,
  });
  final String name;
  final int total;
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
    final share = 'تم تأكيد حجز ${widget.name} برقم #WV-260912-1845';
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
              const _Section(
                child: Column(
                  children: [
                    LocalizedText('رقم الحجز'),
                    LocalizedText(
                      '#WV-260912-1845',
                      style: TextStyle(
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
                    const _Line('التاريخ', 'السبت 12 سبتمبر 2026'),
                    const _Line('الوقت', '4:00 م – 9:00 م'),
                    const _Line('عدد الضيوف', '500 ضيف'),
                    const _Line('المناسبة', 'حفل زفاف'),
                    const _Line('الباقة', 'الذهبية'),
                  ],
                ),
              ),
              _Section(
                child: Column(
                  children: [
                    _Line('سعر الباقة', '${_money(620000)} ر.ي'),
                    const _Line('تصوير فوتوغرافي وفيديو', '120,000 ر.ي'),
                    const _Line('تنسيق الزهور', '95,000 ر.ي'),
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
                    const _Line('حالة الدفع', 'تم دفع العربون', strong: true),
                  ],
                ),
              ),
              _Action(
                Icons.calendar_month,
                'إضافة إلى التقويم',
                () => launchUrl(
                  Uri.parse(
                    'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent('حجز ${widget.name}')}&dates=20260912T130000Z/20260912T180000Z&details=${Uri.encodeComponent('حجز قاعة عبر تطبيق حجوزاتكم')}',
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
        Image.asset(_hallFallback, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black45, Colors.transparent, Colors.black45],
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
        const Positioned(
          bottom: 13,
          left: 13,
          child: _Badge('+18 صورة وفيديو'),
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

class _MealTable extends StatelessWidget {
  const _MealTable();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columnSpacing: 14,
      columns: const [
        DataColumn(label: LocalizedText('الصنف')),
        DataColumn(label: LocalizedText('الكمية')),
        DataColumn(label: LocalizedText('سعر الحبة')),
        DataColumn(label: LocalizedText('الإجمالي')),
      ],
      rows: const [
        DataRow(
          cells: [
            DataCell(LocalizedText('مشروبات بيبسي')),
            DataCell(LocalizedText('400')),
            DataCell(LocalizedText('200')),
            DataCell(LocalizedText('80,000')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(LocalizedText('باكت ضيافة')),
            DataCell(LocalizedText('400')),
            DataCell(LocalizedText('400')),
            DataCell(LocalizedText('160,000')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(LocalizedText('قطع كيك')),
            DataCell(LocalizedText('400')),
            DataCell(LocalizedText('100')),
            DataCell(LocalizedText('40,000')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(LocalizedText('فاين كبير')),
            DataCell(LocalizedText('20')),
            DataCell(LocalizedText('100')),
            DataCell(LocalizedText('2,000')),
          ],
        ),
      ],
    ),
  );
}

class _Addon extends StatelessWidget {
  const _Addon({
    required this.title,
    required this.price,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.child,
    this.buttonAfterChild = false,
  });
  final String title, price;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;
  final bool buttonAfterChild;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: _decor(
      color: selected ? const Color(0xfffff5df) : Colors.white,
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xfff4ead8),
              child: Icon(icon, color: _gold),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (price.isNotEmpty) LocalizedText(price),
                ],
              ),
            ),
            if (!buttonAfterChild)
              FilledButton.tonal(
                onPressed: onTap,
                child: LocalizedText(selected ? 'مضاف ✓' : 'إضافة'),
              ),
          ],
        ),
        if (child != null) ...[const Divider(), child!],
        if (buttonAfterChild) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onTap,
              child: LocalizedText(
                selected ? 'تمت إضافة الاختيارات ✓' : 'إضافة الاختيارات',
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.captions, this.onTap});
  final List<String> captions;
  final ValueChanged<String>? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 105,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: captions
          .map(
            (e) => InkWell(
              onTap: onTap == null ? null : () => onTap!(e),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 180,
                margin: const EdgeInsetsDirectional.only(end: 8, top: 7),
                clipBehavior: Clip.antiAlias,
                decoration: _decor(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(_hallFallback, fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.black54,
                        padding: const EdgeInsets.all(5),
                        child: LocalizedText(
                          e,
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
          )
          .toList(),
    ),
  );
}

class _Included extends StatelessWidget {
  const _Included();
  @override
  Widget build(BuildContext context) => _Section(
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          ['القاعة', 'نظام الصوت', 'الإضاءة', 'موقف السيارات', 'غرفة العروس']
              .map(
                (e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: _green, size: 18),
                    const SizedBox(width: 4),
                    LocalizedText(e),
                  ],
                ),
              )
              .toList(),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.extras});
  final int extras;
  @override
  Widget build(BuildContext context) => _Section(
    child: Column(
      children: [
        _Line('الباقة', '620,000 ر.ي'),
        _Line('الخدمات الإضافية', '${_money(extras)} ر.ي'),
        _Line('الإجمالي', '${_money(620000 + extras)} ر.ي', strong: true),
      ],
    ),
  );
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.name, required this.total});
  final String name;
  final int total;
  @override
  Widget build(BuildContext context) => _Section(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          name,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const _Line('التاريخ', 'السبت 12 سبتمبر 2026'),
        const _Line('الفترة', 'المسائية'),
        const _Line('عدد الضيوف', '500 ضيف'),
        const _Line('الباقة', 'الذهبية'),
        _Line('الإجمالي', '${_money(total)} ر.ي', strong: true),
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
      4,
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
              ['الموعد', 'الخدمات', 'البيانات', 'الدفع'][i],
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
    this.step = 50,
  });
  final int value, step;
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
  const _Amenity(this.icon, this.text, {this.included = true});
  final IconData icon;
  final String text;
  final bool included;
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
        LocalizedText(
          included ? 'شامل' : 'غير شامل',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: included ? _green : Colors.deepOrange,
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
      decoration: _input(label).copyWith(
        helperText: helper == null ? null : l10n(helper!),
      ),
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
      child: LocalizedText(label, style: const TextStyle(fontWeight: FontWeight.w900)),
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
String _money(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

void _showHospitalityDetails(BuildContext context, String title) {
  const items = [
    ('سندوتش كريسبي بالجبن', 'حجم صغير • دجاج وجبن • 450 ر.ي'),
    ('قطعة بيتزا صغيرة', 'خضار وجبن • 350 ر.ي'),
    ('حلوى مشكلة', 'قطعتان صغيرتان • 250 ر.ي'),
    ('عصير طبيعي', 'عبوة 250 مل • 300 ر.ي'),
    ('مياه معدنية', 'عبوة 330 مل • 100 ر.ي'),
  ];
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Directionality(
      textDirection: localizedTextDirection,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(title),
              const SizedBox(height: 8),
              const LocalizedText(
                'اختر المكونات المطلوبة، وستظهر الاختيارات في جدول الضيافة.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 205,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (_, index) => SizedBox(
                    width: 155,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Image.asset(_hallFallback, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LocalizedText(
                                  items[index].$1,
                                  maxLines: 1,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                LocalizedText(
                                  items[index].$2,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _note(context, 'تمت إضافة اختيارات الضيافة إلى الجدول');
                  },
                  child: const LocalizedText('إضافة الاختيارات'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _note(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: LocalizedText(message)));
