import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/maps/app_map_launcher.dart';
import '../../../core/reviews/service_review.dart';
import '../domain/beauty_center.dart';

const beautyCenterBannerAsset =
    'assets/images/beauty_center_booking_banner.png';
const beautyCenterImageAsset = 'assets/Services images/مراكز تجميل.jpg';

const _beautyPink = Color(0xffd92f76);
const _beautyDeepPink = Color(0xffa9185b);
const _beautyNavy = Color(0xff211132);
const _beautyGreen = Color(0xff12b86a);
const _beautyOrange = Color(0xffff9800);
const _beautyBackground = Color(0xfffff7fb);

String _beautyMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

String _beautyDate(DateTime value) =>
    '${value.day}/${value.month}/${value.year}';

class BeautyCenterDiscoveryScreen extends StatefulWidget {
  const BeautyCenterDiscoveryScreen({super.key, required this.province});

  final String province;

  @override
  State<BeautyCenterDiscoveryScreen> createState() =>
      _BeautyCenterDiscoveryScreenState();
}

class _BeautyCenterDiscoveryScreenState
    extends State<BeautyCenterDiscoveryScreen> {
  String query = '';
  final favorites = <String>{};

  List<BeautyCenter> get results {
    var items = beautyCenters
        .where(
          (center) =>
              center.name.contains(query) ||
              center.city.contains(query) ||
              center.district.contains(query),
        )
        .toList();
    return items;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _beautyBackground,
      bottomNavigationBar: const _BeautyBottomNav(),
      body: SafeArea(
        child: ListView(
          key: const Key('beauty-discovery-list'),
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xffffeef5),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      beautyCenterBannerAsset,
                      key: const Key('beauty-main-banner'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 12,
                  child: _BeautyRoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.all(15),
                decoration: _beautyCard(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LocalizedText(
                      'ابحث عن مركز التجميل المناسب',
                      style: TextStyle(
                        color: _beautyNavy,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextField(
                      key: const Key('beauty-search-field'),
                      onChanged: (value) =>
                          setState(() => query = value.trim()),
                      decoration: InputDecoration(
                        hintText: l10n('اسم المركز، الخدمة، أو المنطقة'),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _beautyPink,
                        ),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: _beautyPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                          ),
                        ),
                        filled: true,
                        fillColor: _beautyBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xffffd4e6),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xffffd4e6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 9),
              child: _BeautyHeading('العروض المميزة'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  _BeautyOfferBanner('خصم 25% على جلسات البشرة', 'ينتهي العرض خلال 3 أيام', () => _openBeautyOffer(context)),
                  _BeautyOfferBanner('استشارة تجميل مجانية', 'مع باقات العناية المتكاملة', () => _openBeautyOffer(context)),
                  _BeautyOfferBanner('جلسة ليزر إضافية مجاناً', 'عند حجز الباقة الكاملة', () => _openBeautyOffer(context)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 22, 15, 10),
              child: _BeautyHeading('مراكز التجميل الموثوقة'),
            ),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(child: LocalizedText('لا توجد نتائج مطابقة لبحثك')),
              )
            else
              ...results.map(
                (center) => _BeautyCenterCard(
                  key: Key('beauty-center-${center.id}'),
                  center: center,
                  favorite: favorites.contains(center.id),
                  onFavorite: () => setState(() {
                    favorites.contains(center.id)
                        ? favorites.remove(center.id)
                        : favorites.add(center.id);
                  }),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BeautyCenterDetailsScreen(center: center),
                    ),
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(15, 14, 15, 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_beautyDeepPink, _beautyPink],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'جودة مضمونة وحجز آمن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        LocalizedText(
                          'مراكز موثقة وخدمات تناسب الجميع مع إلغاء مجاني',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _openBeautyOffer(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BeautyCenterDetailsScreen(center: beautyCenters.first),
    ),
  );
}

class _BeautyOfferBanner extends StatelessWidget {
  const _BeautyOfferBanner(this.title, this.subtitle, this.onTap);
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: Container(
    height: 125,
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    decoration: _beautyCard(radius: 19),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(beautyCenterImageAsset, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xdd8e164e), Color(0x558e164e)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LocalizedText(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(subtitle, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    ),
  ),
  );
}

class _BeautyCenterCard extends StatelessWidget {
  const _BeautyCenterCard({
    super.key,
    required this.center,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final BeautyCenter center;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final startingPrice = center.services
        .map((service) => service.price)
        .reduce((a, b) => a < b ? a : b);
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 12),
      decoration: _beautyCard(radius: 19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 132,
              height: 155,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(beautyCenterImageAsset, fit: BoxFit.cover),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffeafff3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const LocalizedText(
                        'موثق',
                        style: TextStyle(
                          color: _beautyGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LocalizedText(
                            center.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _beautyNavy,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onFavorite,
                          icon: Icon(
                            favorite
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            color: favorite ? Colors.redAccent : _beautyPink,
                          ),
                        ),
                      ],
                    ),
                    LocalizedText(
                      '${center.district} • ${center.city}',
                      style: const TextStyle(color: Color(0xff89798a)),
                    ),
                    LocalizedText(
                      '★ ${center.rating} ممتاز • ${center.reviews} تقييم',
                      style: const TextStyle(
                        color: _beautyOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const LocalizedText('يبدأ من '),
                        LocalizedText(
                          '${_beautyMoney(startingPrice)} ر.ي',
                          style: const TextStyle(
                            color: _beautyPink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
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
}

class BeautyCenterDetailsScreen extends StatelessWidget {
  const BeautyCenterDetailsScreen({super.key, required this.center});

  final BeautyCenter center;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _beautyBackground,
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: _BeautyPrimaryButton(
            key: const Key('beauty-book-now'),
            label: 'احجز موعدك الآن',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BeautyBookingScreen(center: center),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('beauty-detail-list'),
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Image.asset(
                  beautyCenterImageAsset,
                  width: double.infinity,
                  height: 310,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: 14,
                  top: 12,
                  child: _BeautyRoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 12,
                  child: Row(
                    children: [
                      _BeautyRoundButton(
                        icon: Icons.share_outlined,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(
                            text:
                                '${center.name}\n${center.district}، ${center.city}\nاحجز عبر حجوزاتكم',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BeautyRoundButton(
                        icon: Icons.favorite_border_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: _beautyPink,
                          size: 19,
                        ),
                        SizedBox(width: 5),
                        LocalizedText(
                          'عرض الصور 12',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(17, 21, 17, 27),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    center.name,
                    style: const TextStyle(
                      color: _beautyNavy,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    '${center.district} • ${center.city}',
                    style: const TextStyle(
                      color: Color(0xff887b91),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LocalizedText(
                        '★ ${center.rating} ممتاز • ${center.reviews} تقييم',
                        style: const TextStyle(
                          color: _beautyOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const _BeautyPill(
                        label: 'مركز موثق ومعتمد',
                        icon: Icons.verified_rounded,
                        color: _beautyGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      'من نحن',
                      'فريقنا',
                      'قبل وبعد',
                      'أسئلة متكررة',
                      'مواعيدنا',
                    ]
                        .map(
                          (label) => ActionChip(
                            label: LocalizedText(label),
                            onPressed: () => _showBeautySection(
                              context,
                              center,
                              label,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: center.features.length,
                    itemBuilder: (_, index) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _beautyBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffffdce9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: _beautyPink,
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: LocalizedText(
                              center.features[index],
                              style: const TextStyle(
                                color: _beautyNavy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 23),
                  const _BeautyHeading('عن المركز'),
                  const SizedBox(height: 7),
                  LocalizedText(
                    center.description,
                    style: const TextStyle(
                      color: Color(0xff746b78),
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 23),
                  const _BeautyHeading('قسم الجراحة التجميلية'),
                  const SizedBox(height: 10),
                  ...center.services
                      .where((service) => service.category == 'الجراحة التجميلية')
                      .map(
                    (service) => _BeautyServiceTile(service: service),
                  ),
                  const SizedBox(height: 18),
                  const _BeautyHeading('قسم العناية بالبشرة والشعر'),
                  const SizedBox(height: 10),
                  ...center.services
                      .where((service) => service.category == 'العناية بالبشرة والشعر')
                      .map(
                    (service) => _BeautyServiceTile(service: service),
                  ),
                  const SizedBox(height: 18),
                  const _BeautyHeading('قسم الجلدية'),
                  const SizedBox(height: 10),
                  ...center.services
                      .where((service) => service.category == 'الجلدية')
                      .map(
                    (service) => _BeautyServiceTile(service: service),
                  ),
                  const SizedBox(height: 18),
                  const _BeautyHeading('فريق المختصين'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 105,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: center.specialists
                          .map(
                            (name) => Container(
                              width: 125,
                              margin: const EdgeInsets.only(left: 9),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _beautyBackground,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xffffdce9),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xffffe3ef),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: _beautyPink,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  LocalizedText(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _beautyNavy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xffffedf5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: _beautyPink),
                        SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText(
                                'ساعات العمل',
                                style: TextStyle(
                                  color: _beautyNavy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              LocalizedText('يومياً من 9:00 صباحاً حتى 9:00 مساءً'),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _BeautyServiceTile extends StatelessWidget {
  const _BeautyServiceTile({required this.service});

  final BeautyService service;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    height: 176,
    clipBehavior: Clip.antiAlias,
    decoration: _beautyCard(),
    child: Row(
      children: [
        Expanded(
          child: Image.asset(
            beautyCenterImageAsset,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border, color: _beautyPink),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: '${service.name} • ${_beautyMoney(service.price)} ر.ي'),
                    ),
                    icon: const Icon(Icons.share_outlined, color: _beautyPink),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: LocalizedText(
                  service.name,
                  maxLines: 2,
                  style: const TextStyle(
                    color: _beautyNavy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: LocalizedText(
                  '${service.durationMinutes} دقيقة • ${service.expectedSessions}',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 10, color: Color(0xff887b91)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: LocalizedText(
                  service.resultSummary,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
                child: LocalizedText(
                  '${_beautyMoney(service.price)} ر.ي',
                  style: const TextStyle(
                    color: _beautyPink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class BeautyBookingScreen extends StatefulWidget {
  const BeautyBookingScreen({super.key, required this.center});

  final BeautyCenter center;

  @override
  State<BeautyBookingScreen> createState() => _BeautyBookingScreenState();
}

class _BeautyBookingScreenState extends State<BeautyBookingScreen> {
  int selectedService = 0;
  int selectedSpecialist = 0;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTime = '10:00 صباحاً';

  BeautyService get service => widget.center.services[selectedService];

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  @override
  Widget build(BuildContext context) => BeautyBookingFrame(
    step: 2,
    title: 'تفاصيل موعدك',
    child: ListView(
      key: const Key('beauty-booking-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _BeautyCenterSummary(center: widget.center),
        const SizedBox(height: 18),
        const _BeautyHeading('اختر الخدمة'),
        const SizedBox(height: 9),
        ...List.generate(widget.center.services.length, (index) {
          final item = widget.center.services[index];
          final chosen = index == selectedService;
          return InkWell(
            onTap: () => setState(() => selectedService = index),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: chosen ? _beautyPink : const Color(0xffffdce9),
                  width: chosen ? 1.7 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    chosen
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: chosen ? _beautyPink : const Color(0xff96899a),
                  ),
                  const SizedBox(width: 9),
                  Icon(_beautyServiceIcon(item.iconName), color: _beautyPink),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          item.name,
                          style: const TextStyle(
                            color: _beautyNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LocalizedText('${item.durationMinutes} دقيقة'),
                      ],
                    ),
                  ),
                  LocalizedText(
                    '${_beautyMoney(item.price)} ر.ي',
                    style: const TextStyle(
                      color: _beautyPink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        const _BeautyHeading('اختر المختص'),
        const SizedBox(height: 9),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.center.specialists.length,
            itemBuilder: (_, index) {
              final chosen = index == selectedSpecialist;
              return InkWell(
                onTap: () => setState(() => selectedSpecialist = index),
                child: Container(
                  width: 138,
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: chosen ? const Color(0xffffe8f1) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: chosen ? _beautyPink : const Color(0xffffdce9),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: chosen
                            ? _beautyPink
                            : const Color(0xffffe3ee),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: chosen ? Colors.white : _beautyPink,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: LocalizedText(
                          widget.center.specialists[index],
                          maxLines: 2,
                          style: const TextStyle(
                            color: _beautyNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 19),
        const _BeautyHeading('اختر التاريخ والوقت'),
        const SizedBox(height: 9),
        InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _beautyCard(),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: _beautyPink),
                const SizedBox(width: 10),
                const Expanded(
                  child: LocalizedText(
                    'تاريخ الموعد',
                    style: TextStyle(
                      color: _beautyNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                LocalizedText(
                  _beautyDate(selectedDate),
                  style: const TextStyle(
                    color: _beautyPink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children:
              [
                    '10:00 صباحاً',
                    '12:00 ظهراً',
                    '03:00 عصراً',
                    '05:00 مساءً',
                    '07:00 مساءً',
                  ]
                  .map(
                    (time) => ChoiceChip(
                      label: LocalizedText(time),
                      selected: selectedTime == time,
                      showCheckmark: false,
                      selectedColor: const Color(0xffffe5f0),
                      side: BorderSide(
                        color: selectedTime == time
                            ? _beautyPink
                            : const Color(0xffffdce9),
                      ),
                      labelStyle: TextStyle(
                        color: selectedTime == time ? _beautyPink : _beautyNavy,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => selectedTime = time),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffffeaf3),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            children: [
              _BeautyInvoiceLine('الخدمة', service.name),
              _BeautyInvoiceLine('المدة', '${service.durationMinutes} دقيقة'),
              _BeautyInvoiceLine(
                'الإجمالي المبدئي',
                '${_beautyMoney(service.price)} ر.ي',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _BeautyPrimaryButton(
          key: const Key('beauty-booking-continue'),
          label: 'متابعة إلى الدفع',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeautyPaymentScreen(
                center: widget.center,
                service: service,
                specialist: widget.center.specialists[selectedSpecialist],
                date: selectedDate,
                time: selectedTime,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class BeautyPaymentScreen extends StatefulWidget {
  const BeautyPaymentScreen({
    super.key,
    required this.center,
    required this.service,
    required this.specialist,
    required this.date,
    required this.time,
  });

  final BeautyCenter center;
  final BeautyService service;
  final String specialist;
  final DateTime date;
  final String time;

  @override
  State<BeautyPaymentScreen> createState() => _BeautyPaymentScreenState();
}

class _BeautyPaymentScreenState extends State<BeautyPaymentScreen> {
  String selectedMethod = 'محفظة ون كاش';

  int get serviceFee => (widget.service.price * .05).round();
  int get total => widget.service.price + serviceFee;

  static const methods = [
    ('محفظة ون كاش', Icons.account_balance_wallet_rounded),
    ('جوالي', Icons.phone_android_rounded),
    ('جيب', Icons.wallet_rounded),
    ('فلوسك', Icons.account_balance_rounded),
    ('بطاقة ائتمانية', Icons.credit_card_rounded),
  ];

  @override
  Widget build(BuildContext context) => BeautyBookingFrame(
    step: 3,
    title: 'إتمام الدفع',
    child: ListView(
      key: const Key('beauty-payment-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _BeautyCenterSummary(center: widget.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: _beautyCard(),
          child: Column(
            children: [
              _BeautyInvoiceLine('الخدمة', widget.service.name),
              _BeautyInvoiceLine('المختص', widget.specialist),
              _BeautyInvoiceLine(
                'الموعد',
                '${_beautyDate(widget.date)} • ${widget.time}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _BeautyHeading('تفاصيل السعر'),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _beautyCard(),
          child: Column(
            children: [
              _BeautyInvoiceLine(
                'سعر الخدمة',
                '${_beautyMoney(widget.service.price)} ر.ي',
              ),
              const Divider(),
              _BeautyInvoiceLine(
                'رسوم الحجز',
                '${_beautyMoney(serviceFee)} ر.ي',
              ),
              const Divider(),
              _BeautyInvoiceLine(
                'الإجمالي الكلي',
                '${_beautyMoney(total)} ر.ي',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _BeautyHeading('سياسة إلغاء الحجز'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _beautyCard(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText('1- يمكنكم إلغاء موعد الحجز مجاناً خلال 6 ساعات من تاريخ الحجز فقط.'),
              Divider(),
              LocalizedText('2- يخصم 50% من قيمة الحجز في حالة تأجيل الحجز إلى موعد آخر.'),
              Divider(),
              LocalizedText('3- لا يعاد مبلغ الحجز عند عدم حضور العميل في الموعد المحدد أو خلال مواعيد العمل في اليوم نفسه.'),
            ],
          ),
        ),
        const _BeautyHeading('اختر طريقة الدفع'),
        const SizedBox(height: 9),
        ...methods.map(
          (method) => InkWell(
            onTap: () => setState(() => selectedMethod = method.$1),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedMethod == method.$1
                      ? _beautyPink
                      : const Color(0xffffdce9),
                  width: selectedMethod == method.$1 ? 1.7 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedMethod == method.$1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selectedMethod == method.$1
                        ? _beautyPink
                        : const Color(0xff95889a),
                  ),
                  const SizedBox(width: 9),
                  Icon(method.$2, color: _beautyPink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LocalizedText(
                      method.$1,
                      style: const TextStyle(
                        color: _beautyNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const LocalizedText(
                    'دفع آمن',
                    style: TextStyle(color: Color(0xff8c7e91)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xffffedf5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: _beautyPink),
              SizedBox(width: 7),
              Flexible(
                child: LocalizedText(
                  'جميع معاملاتك مشفرة ومحمية بأعلى معايير الأمان',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _beautyPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _BeautyPrimaryButton(
          key: const Key('beauty-pay-button'),
          label: 'ادفع الآن • ${_beautyMoney(total)} ر.ي',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BeautyBookingSuccessScreen(
                center: widget.center,
                service: widget.service,
                specialist: widget.specialist,
                date: widget.date,
                time: widget.time,
                method: selectedMethod,
                serviceFee: serviceFee,
                total: total,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class BeautyBookingSuccessScreen extends StatelessWidget {
  const BeautyBookingSuccessScreen({
    super.key,
    required this.center,
    required this.service,
    required this.specialist,
    required this.date,
    required this.time,
    required this.method,
    required this.serviceFee,
    required this.total,
  });

  static const bookingNumber = 'BC-2026-000318';

  final BeautyCenter center;
  final BeautyService service;
  final String specialist;
  final DateTime date;
  final String time;
  final String method;
  final int serviceFee;
  final int total;

  @override
  Widget build(BuildContext context) => BeautyBookingFrame(
    step: 4,
    title: 'تم تأكيد الموعد',
    child: ListView(
      key: const Key('beauty-success-list'),
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_beautyDeepPink, _beautyPink],
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 37,
                backgroundColor: Colors.white,
                child: Icon(Icons.check_rounded, color: _beautyGreen, size: 50),
              ),
              SizedBox(height: 12),
              LocalizedText(
                'تم حجز موعدك بنجاح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                'أرسلنا تفاصيل الموعد إلى هاتفك',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _BeautyCenterSummary(center: center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _beautyCard(),
          child: Column(
            children: [
              const _BeautyInvoiceLine('رقم الحجز', bookingNumber),
              _BeautyInvoiceLine('الخدمة', service.name),
              _BeautyInvoiceLine('المختص', specialist),
              _BeautyInvoiceLine('الموعد', '${_beautyDate(date)} • $time'),
              _BeautyInvoiceLine('طريقة الدفع', method),
              const _BeautyInvoiceLine('حالة الحجز', 'مؤكد ✓', success: true),
              _BeautyInvoiceLine(
                'الإجمالي',
                '${_beautyMoney(total)} ر.ي',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _BeautyPrimaryButton(
          key: const Key('beauty-show-invoice'),
          label: 'عرض تفاصيل الحجز والفاتورة',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeautyInvoiceScreen(
                center: center,
                service: service,
                specialist: specialist,
                date: date,
                time: time,
                method: method,
                serviceFee: serviceFee,
                total: total,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeautyRatingScreen(center: center),
            ),
          ),
          icon: const Icon(Icons.star_outline_rounded),
          label: const LocalizedText('تقييم مركز التجميل'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).popUntil(
            (route) => route.settings.name == 'services-home' || route.isFirst,
          ),
          icon: const Icon(Icons.home_outlined),
          label: const LocalizedText('العودة إلى الرئيسية'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
        ),
      ],
    ),
  );
}

class BeautyInvoiceScreen extends StatelessWidget {
  const BeautyInvoiceScreen({
    super.key,
    required this.center,
    required this.service,
    required this.specialist,
    required this.date,
    required this.time,
    required this.method,
    required this.serviceFee,
    required this.total,
  });

  final BeautyCenter center;
  final BeautyService service;
  final String specialist;
  final DateTime date;
  final String time;
  final String method;
  final int serviceFee;
  final int total;

  @override
  Widget build(BuildContext context) => BeautyBookingFrame(
    step: 5,
    title: 'فاتورة الحجز',
    child: ListView(
      key: const Key('beauty-invoice-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _BeautyCenterSummary(center: center),
        const SizedBox(height: 13),
        Row(
          children: [
            const Expanded(
              child: _BeautyPill(
                label: 'حجز مؤكد',
                icon: Icons.verified_rounded,
                color: _beautyGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LocalizedText(
                'رقم الحجز ${BeautyBookingSuccessScreen.bookingNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _beautyNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffffedf5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const LocalizedText(
            'تم إرسال تفاصيل الحجز إلى رقم الواتساب المسجل',
            textAlign: TextAlign.center,
            style: TextStyle(color: _beautyPink, fontWeight: FontWeight.bold),
          ),
        ),
        const _BeautyHeading('تفاصيل الموعد'),
        const SizedBox(height: 9),
        _BeautyInvoiceGrid(
          entries: [
            ('الخدمة', service.name),
            ('المختص', specialist),
            ('التاريخ', _beautyDate(date)),
            ('الوقت', time),
            ('المدة', '${service.durationMinutes} دقيقة'),
            ('المركز', center.name),
          ],
        ),
        const SizedBox(height: 19),
        const _BeautyHeading('تفاصيل الدفع'),
        const SizedBox(height: 9),
        _BeautyInvoiceGrid(
          entries: [
            ('طريقة الدفع', method),
            ('سعر الخدمة', '${_beautyMoney(service.price)} ر.ي'),
            ('رسوم الحجز', '${_beautyMoney(serviceFee)} ر.ي'),
            ('الإجمالي', '${_beautyMoney(total)} ر.ي'),
            ('حالة الدفع', 'تم الدفع بنجاح'),
            ('رقم العملية', 'PAY-BC-20458'),
          ],
          successIndex: 4,
        ),
        const SizedBox(height: 19),
        const _BeautyHeading('الموقع'),
        const SizedBox(height: 9),
        InkWell(
          onTap: () => AppMapLauncher.open(
            context,
            query: '${center.name} ${center.district} ${center.city} اليمن',
          ),
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 125,
            decoration: BoxDecoration(
              color: const Color(0xffffedf5),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xffffd8e7)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: CustomPaint(painter: _BeautyMapPainter())),
                const Icon(
                  Icons.location_on_rounded,
                  color: _beautyPink,
                  size: 47,
                ),
                Positioned(
                  right: 12,
                  bottom: 8,
                  child: LocalizedText(
                    '${center.district} • ${center.city} • اضغط لفتح الموقع',
                    style: const TextStyle(
                      color: _beautyNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 19),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _beautyCard(),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'الفاتورة والتحقق',
                      style: TextStyle(
                        color: _beautyNavy,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    LocalizedText('رمز التحقق'),
                    LocalizedText(
                      'BC20458',
                      key: Key('beauty-invoice-code'),
                      style: TextStyle(
                        color: _beautyPink,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _BeautyQrPattern(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ServiceCompletionFooter(
          serviceKey: 'مراكز تجميل',
          serviceName: 'مراكز تجميل',
          invoiceText:
              'فاتورة حجز ${center.name}\n${service.name}\nرقم الحجز: ${BeautyBookingSuccessScreen.bookingNumber}\nالإجمالي: ${_beautyMoney(total)} ر.ي',
          rateButtonKey: const Key('beauty-rate-from-invoice'),
          ratingScreenBuilder: (_) => BeautyRatingScreen(center: center),
        ),
      ],
    ),
  );
}

class BeautyRatingScreen extends StatefulWidget {
  const BeautyRatingScreen({super.key, required this.center});

  final BeautyCenter center;

  @override
  State<BeautyRatingScreen> createState() => _BeautyRatingScreenState();
}

class _BeautyRatingScreenState extends State<BeautyRatingScreen> {
  int rating = 5;
  final categoryRatings = <String, int>{
    'جودة الخدمة': 5,
    'النظافة': 5,
    'تعامل المختص': 5,
    'الالتزام بالموعد': 5,
  };
  final comment = TextEditingController();
  bool saved = false;

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    await serviceReviewStore.saveReview(
      'مراكز تجميل',
      rating: rating,
      comment: comment.text.trim(),
    );
    if (!mounted) return;
    setState(() => saved = true);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _beautyBackground,
      appBar: AppBar(title: const LocalizedText('تقييم مركز التجميل')),
      body: SafeArea(
        child: ListView(
          key: const Key('beauty-rating-list'),
          padding: const EdgeInsets.all(16),
          children: [
            _BeautyCenterSummary(center: widget.center),
            const SizedBox(height: 20),
            const LocalizedText(
              'كيف كانت تجربتك؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _beautyNavy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const LocalizedText(
              'رأيك يساعد المركز والعملاء على تقديم واختيار الأفضل',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff827688)),
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => setState(() => rating = index + 1),
                  iconSize: 37,
                  icon: Icon(
                    index < rating ? Icons.star_rounded : Icons.star_border,
                    color: _beautyOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...categoryRatings.entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: _beautyCard(),
                child: Row(
                  children: [
                    Expanded(
                      child: LocalizedText(
                        entry.key,
                        style: const TextStyle(
                          color: _beautyNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...List.generate(
                      5,
                      (index) => InkWell(
                        onTap: () => setState(
                          () => categoryRatings[entry.key] = index + 1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            index < entry.value
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: _beautyOrange,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: comment,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: l10n('اكتب ملاحظتك عن المركز والخدمة...'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xffffdce9)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (saved)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xffeafff3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: _beautyGreen),
                    SizedBox(width: 8),
                    LocalizedText(
                      'تم حفظ تقييمك، شكراً لمشاركتنا تجربتك.',
                      style: TextStyle(
                        color: _beautyGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            _BeautyPrimaryButton(
              label: saved ? 'تحديث التقييم' : 'إرسال التقييم',
              onPressed: _saveReview,
            ),
          ],
        ),
      ),
    ),
  );
}

class BeautyBookingFrame extends StatelessWidget {
  const BeautyBookingFrame({
    super.key,
    required this.step,
    required this.title,
    required this.child,
  });

  final int step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _beautyBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 17),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_beautyDeepPink, _beautyPink],
                ),
              ),
              child: Row(
                children: [
                  _BeautyRoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const LocalizedText(
                          'حجز آمن وسريع بخطوات سهلة',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 78,
                    height: 68,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      'assets/images/logo_transparent.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            _BeautyProgress(step: step),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _BeautyProgress extends StatelessWidget {
  const _BeautyProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['المركز', 'الموعد', 'الدفع', 'التأكيد', 'الفاتورة'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(5, 9, 5, 7),
      child: Row(
        children: List.generate(labels.length, (index) {
          final number = index + 1;
          final done = number < step;
          final active = number == step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: done
                              ? _beautyGreen
                              : active
                              ? _beautyPink
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done
                                ? _beautyGreen
                                : active
                                ? _beautyPink
                                : const Color(0xffffd4e5),
                          ),
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : LocalizedText(
                                  '$number',
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : const Color(0xff968a9a),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      LocalizedText(
                        labels[index],
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 9,
                          color: done
                              ? _beautyGreen
                              : active
                              ? _beautyPink
                              : const Color(0xff918493),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < labels.length - 1)
                  Container(
                    width: 8,
                    height: 2,
                    color: number < step
                        ? _beautyGreen
                        : const Color(0xffffd9e8),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BeautyCenterSummary extends StatelessWidget {
  const _BeautyCenterSummary({required this.center});

  final BeautyCenter center;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: _beautyCard(),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            beautyCenterImageAsset,
            width: 104,
            height: 82,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                center.name,
                style: const TextStyle(
                  color: _beautyNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                '${center.district} • ${center.city}',
                style: const TextStyle(color: Color(0xff887b90)),
              ),
              LocalizedText(
                '★ ${center.rating} ممتاز • ${center.reviews} تقييم',
                style: const TextStyle(
                  color: _beautyOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BeautyHeading extends StatelessWidget {
  const _BeautyHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => LocalizedText(
    label,
    style: const TextStyle(
      color: _beautyNavy,
      fontSize: 22,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _BeautyPrimaryButton extends StatelessWidget {
  const _BeautyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: _beautyPink,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 53),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    ),
    child: LocalizedText(label),
  );
}

class _BeautyRoundButton extends StatelessWidget {
  const _BeautyRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 2,
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: _beautyPink),
    ),
  );
}

class _BeautyPill extends StatelessWidget {
  const _BeautyPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: LocalizedText(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _BeautyInvoiceLine extends StatelessWidget {
  const _BeautyInvoiceLine(
    this.label,
    this.value, {
    this.highlight = false,
    this.success = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool success;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: LocalizedText(
            label,
            style: TextStyle(
              color: highlight ? _beautyNavy : const Color(0xff827688),
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Flexible(
          child: LocalizedText(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: success
                  ? _beautyGreen
                  : highlight
                  ? _beautyPink
                  : _beautyNavy,
              fontSize: highlight ? 18 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BeautyInvoiceGrid extends StatelessWidget {
  const _BeautyInvoiceGrid({required this.entries, this.successIndex = -1});

  final List<(String, String)> entries;
  final int successIndex;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 1.95,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: entries.length,
    itemBuilder: (_, index) => Container(
      padding: const EdgeInsets.all(10),
      decoration: _beautyCard(radius: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            entries[index].$1,
            style: const TextStyle(color: Color(0xff8b7e90)),
          ),
          LocalizedText(
            entries[index].$2,
            maxLines: entries[index].$1 == 'المركز' ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: index == successIndex ? _beautyGreen : _beautyNavy,
              fontWeight: FontWeight.bold,
              fontSize: entries[index].$1 == 'المركز' ? 10.5 : 14,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BeautyMeta extends StatelessWidget {
  const _BeautyMeta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: _beautyPink, size: 19),
        const SizedBox(height: 3),
        LocalizedText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _beautyNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _BeautyMetaDivider extends StatelessWidget {
  const _BeautyMetaDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 35, color: const Color(0xffffdce8));
}

class _BeautyQrPattern extends StatelessWidget {
  const _BeautyQrPattern();

  @override
  Widget build(BuildContext context) => Container(
    width: 103,
    height: 103,
    padding: const EdgeInsets.all(7),
    color: Colors.white,
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 81,
      itemBuilder: (_, index) {
        final row = index ~/ 9;
        final column = index % 9;
        final dark = (row * 5 + column * 3 + row * column) % 4 != 0;
        return ColoredBox(color: dark ? _beautyNavy : Colors.white);
      },
    ),
  );
}

class _BeautyMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffffc9df)
      ..strokeWidth = 2;
    for (var y = 23.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 6), paint);
    }
    for (var x = 25.0; x < size.width; x += 62) {
      canvas.drawLine(Offset(x, 0), Offset(x - 28, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeautyBottomNav extends StatelessWidget {
  const _BeautyBottomNav();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x16000000), blurRadius: 10)],
      ),
      child: const Row(
        children: [
          _BeautyNavItem(Icons.home_rounded, 'الرئيسية', selected: true),
          _BeautyNavItem(Icons.explore_outlined, 'استكشف'),
          _BeautyNavItem(Icons.favorite_border_rounded, 'المفضلة'),
          _BeautyNavItem(Icons.calendar_month_outlined, 'حجوزاتي'),
          _BeautyNavItem(Icons.more_horiz_rounded, 'المزيد'),
        ],
      ),
    ),
  );
}

class _BeautyNavItem extends StatelessWidget {
  const _BeautyNavItem(this.icon, this.label, {this.selected = false});

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: selected ? _beautyPink : const Color(0xff9b8e9c)),
        LocalizedText(
          label,
          style: TextStyle(
            color: selected ? _beautyPink : const Color(0xff897d8a),
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

void _showBeautySection(
  BuildContext context,
  BeautyCenter center,
  String section,
) {
  final content = switch (section) {
    'من نحن' => center.description,
    'فريقنا' => center.specialists.join(' • '),
    'قبل وبعد' => 'معرض موثق لنتائج الحالات قبل وبعد، وتُضاف صوره من لوحة التحكم بعد موافقة العميل.',
    'أسئلة متكررة' => 'هل أحتاج استشارة؟ نعم لبعض الخدمات. كم عدد الجلسات؟ يحدده المختص بعد التقييم الأولي.',
    _ => 'يومياً من 9:00 صباحاً حتى 9:00 مساءً، مع إمكانية اختيار الموعد أثناء الحجز.',
  };
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Directionality(
      textDirection: localizedTextDirection,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BeautyHeading(section),
            const SizedBox(height: 10),
            LocalizedText(content, style: const TextStyle(height: 1.7)),
          ],
        ),
      ),
    ),
  );
}

BoxDecoration _beautyCard({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xffffdce9)),
  boxShadow: const [
    BoxShadow(color: Color(0x0d000000), blurRadius: 8, offset: Offset(0, 3)),
  ],
);

IconData _beautyServiceIcon(String name) => switch (name) {
  'face' => Icons.face_retouching_natural_rounded,
  'spa' => Icons.spa_rounded,
  'hair' => Icons.content_cut_rounded,
  'massage' => Icons.self_improvement_rounded,
  'laser' => Icons.flare_rounded,
  'nails' => Icons.back_hand_outlined,
  _ => Icons.auto_awesome_rounded,
};
