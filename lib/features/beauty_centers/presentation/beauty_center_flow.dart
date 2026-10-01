import '../../bookings/presentation/provider_booking_flow.dart';
import 'package:flutter/material.dart';
import '../../auth/presentation/booking_auth_gate.dart';
import '../data/beauty_backend_bridge.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/maps/app_map_launcher.dart';
import '../../../core/reviews/service_review.dart';
import '../domain/beauty_center.dart';

const beautyCenterBannerAsset =
    'assets/images/beauty_center_booking_banner.png';
const beautyCenterImageAsset = 'assets/Services images/مراكز تجميل.jpg';
const beautyMainLogoAsset = 'assets/images/hujozat_main_logo.png';

const _beautyPink = Color(0xffd92f76);
const _beautyDeepPink = Color(0xffa9185b);
const _beautyNavy = Color(0xff211132);
const _beautyGreen = Color(0xff12b86a);
const _beautyOrange = Color(0xffff9800);
const _beautyBrandBlue = Color(0xff1761d6);
const _beautyBrandOrange = Color(0xffd85b00);
const _beautyBackground = Color(0xfffff7fb);

const _beautyCurrentOffers = <(String, String, String, int)>[
  (
    'الجراحة التجميلية',
    'استشارة تجميلية متخصصة',
    'خصم على الاستشارة الأولى وخطة العلاج',
    20,
  ),
  (
    'الجراحة التجميلية',
    'باقة نحت وتنسيق القوام',
    'تقييم شامل وخطة متابعة مع الفريق الطبي',
    15,
  ),
  (
    'الجراحة التجميلية',
    'عرض تجميل الوجه',
    'استشارة وفحوصات أولية ضمن العرض',
    18,
  ),
  (
    'العناية بالبشرة والشعر',
    'باقة نضارة وعناية',
    'جلسة تقييم مع عناية متكاملة للبشرة',
    25,
  ),
  (
    'العناية بالبشرة والشعر',
    'برنامج تقوية الشعر',
    'تشخيص فروة الرأس وباقة جلسات متكاملة',
    20,
  ),
  (
    'العناية بالبشرة والشعر',
    'جلسة عناية ملكية',
    'تنظيف وترطيب ونضارة بإشراف مختص',
    22,
  ),
  (
    'الجلدية',
    'عرض جلسات الجلدية والليزر',
    'سعر خاص للحجز خلال هذا الأسبوع',
    18,
  ),
  ('الجلدية', 'باقة علاج التصبغات', 'تقييم الحالة وخطة جلسات مخصصة', 20),
  (
    'الجلدية',
    'عرض إزالة الشعر بالليزر',
    'خصم للحجز المبكر على الباقة الكاملة',
    25,
  ),
];

String _beautyMoney(int value) => formatMoney(value);

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
  bool _loadingCatalog = true;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadBeautyCatalog();
  }

  @override
  void didUpdateWidget(covariant BeautyCenterDiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.province != widget.province) {
      _loadBeautyCatalog();
    }
  }

  Future<void> _loadBeautyCatalog() async {
    final flow = ProviderBookingFlow.current;

    if (flow == null) {
      if (!mounted) return;
      setState(() {
        _loadingCatalog = false;
        _catalogError =
            'تعذر الاتصال بكتالوج مقدمي الخدمات. تحقق من الاتصال وحاول مجددًا.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loadingCatalog = true;
        _catalogError = null;
      });
    }

    try {
      await flow.load('beauty', province: widget.province);

      if (!mounted) return;

      setState(() {
        _loadingCatalog = false;
        _catalogError = null;
      });
    } on Object {
      if (!mounted) return;

      setState(() {
        _loadingCatalog = false;
        _catalogError =
            'تعذر تحميل مراكز التجميل من لوحة التحكم. تحقق من الاتصال ثم أعد المحاولة.';
      });
    }
  }

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
            if (ProviderBookingFlow.current == null) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 9),
                child: _BeautyHeading('العروض المميزة'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _BeautyOfferBanner(
                      'خصم 25% على جلسات البشرة',
                      'ينتهي العرض خلال 3 أيام',
                      () => _openBeautyOffer(context),
                    ),
                    _BeautyOfferBanner(
                      'استشارة تجميل مجانية',
                      'مع باقات العناية المتكاملة',
                      () => _openBeautyOffer(context),
                    ),
                    _BeautyOfferBanner(
                      'جلسة ليزر إضافية مجاناً',
                      'عند حجز الباقة الكاملة',
                      () => _openBeautyOffer(context),
                    ),
                  ],
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 22, 15, 10),
              child: _BeautyHeading('مراكز التجميل الموثوقة'),
            ),
            if (_loadingCatalog)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      LocalizedText(
                        'جاري تحميل مراكز التجميل من لوحة التحكم...',
                      ),
                    ],
                  ),
                ),
              ),
            if (!_loadingCatalog && _catalogError != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: _beautyPink,
                      size: 38,
                    ),
                    const SizedBox(height: 10),
                    LocalizedText(_catalogError!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _loadBeautyCatalog,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const LocalizedText('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            if (!_loadingCatalog && _catalogError == null && results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(
                  child: LocalizedText('لا توجد نتائج مطابقة لبحثك'),
                ),
              ),
            if (!_loadingCatalog && _catalogError == null && results.isNotEmpty)
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
          ],
        ),
      ),
    ),
  );

  void _openBeautyOffer(BuildContext context) {
    if (beautyCenters.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeautyCenterDetailsScreen(center: beautyCenters.first),
      ),
    );
  }
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
                LocalizedText(
                  subtitle,
                  style: const TextStyle(color: Colors.white),
                ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 12),
      decoration: _beautyCard(radius: 19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 158,
              height: 155,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(beautyCenterImageAsset, fit: BoxFit.cover),
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
                      center.reviews == 0
                          ? 'لا توجد تقييمات بعد'
                          : '★ ${center.rating} • ${center.reviews} تقييم',
                      style: const TextStyle(
                        color: _beautyOrange,
                        fontWeight: FontWeight.bold,
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
}

class BeautyCenterDetailsScreen extends StatelessWidget {
  const BeautyCenterDetailsScreen({super.key, required this.center});

  final BeautyCenter center;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _beautyBackground,
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
                        center.reviews == 0
                            ? 'لا توجد تقييمات بعد'
                            : '★ ${center.rating} • ${center.reviews} تقييم',
                        style: const TextStyle(
                          color: _beautyOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ProviderBookingFlow.current == null)
                        const _BeautyPill(
                          label: 'مركز موثق ومعتمد',
                          icon: Icons.verified_rounded,
                          color: _beautyGreen,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const columns = 3;
                      final cardWidth =
                          (constraints.maxWidth - ((columns - 1) * 9)) /
                          columns;
                      final cardHeight = constraints.maxWidth < 330
                          ? 72.0
                          : 78.0;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 6,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: cardWidth / cardHeight,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (_, index) {
                          const labels = [
                            'من نحن',
                            'فريقنا',
                            'قبل وبعد',
                            'أسئلة متكررة',
                            'مواعيدنا',
                            'تواصل معنا',
                          ];
                          final label = labels[index];
                          return _BeautyInfoCard(
                            key: ValueKey('beauty-info-$label'),
                            label: label,
                            icon: _beautyInfoIcon(label),
                            onTap: () =>
                                _showBeautySection(context, center, label),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 23),
                  const _BeautyHeading('أقسام المركز'),
                  const SizedBox(height: 23),
                  for (final category
                      in center.services
                          .map((service) => service.category)
                          .toSet()) ...[
                    _BeautySectionHeader(
                      key: ValueKey('beauty-department-$category'),
                      title: category.isEmpty ? 'الخدمات المتاحة' : category,
                      onTap: () =>
                          _openBeautyDepartment(context, center, category),
                    ),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BeautySectionHeader extends StatelessWidget {
  const _BeautySectionHeader({
    super.key,
    required this.title,
    required this.onTap,
  });
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _BeautyHeading(title)),
      TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const LocalizedText('استعراض القسم'),
      ),
    ],
  );
}

class _BeautyInfoCard extends StatelessWidget {
  const _BeautyInfoCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xfffff3f8)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xffffc9dd), width: 1.1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xffffe6f0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffffc4d9)),
                ),
                child: Icon(icon, color: _beautyPink, size: 17),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: LocalizedText(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _beautyNavy,
                    fontSize: 12.5,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

IconData _beautyInfoIcon(String label) => switch (label) {
  'من نحن' => Icons.info_outline_rounded,
  'فريقنا' => Icons.groups_2_outlined,
  'قبل وبعد' => Icons.compare_rounded,
  'أسئلة متكررة' => Icons.quiz_outlined,
  'مواعيدنا' => Icons.schedule_rounded,
  _ => Icons.contact_phone_outlined,
};

void _openBeautyDepartment(
  BuildContext context,
  BeautyCenter center,
  String category,
) {
  final serviceIndex = center.services.indexWhere(
    (service) => service.category == category,
  );
  openProtectedBooking(
    context,
    nextScreen: BeautyBookingScreen(
      center: center,
      initialServiceIndex: serviceIndex < 0 ? 0 : serviceIndex,
    ),
    serviceTitle: 'مراكز تجميل',
  );
}

class _BeautyDepartmentOfferBanner extends StatelessWidget {
  const _BeautyDepartmentOfferBanner({
    required this.offer,
    required this.onTap,
  });

  final (String, String, String, int) offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 104,
    margin: const EdgeInsets.only(top: 8, bottom: 10),
    clipBehavior: Clip.antiAlias,
    decoration: _beautyCard(radius: 15),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(beautyCenterBannerAsset, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xe6a9185b), Color(0x99901b58)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LocalizedText(
                          offer.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        LocalizedText(
                          offer.$3,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LocalizedText(
                      'خصم ${offer.$4}%',
                      style: const TextStyle(
                        color: _beautyDeepPink,
                        fontWeight: FontWeight.w900,
                      ),
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

class BeautyBookingScreen extends StatefulWidget {
  const BeautyBookingScreen({
    super.key,
    required this.center,
    this.initialServiceIndex = 0,
    this.selectedOffer,
  });

  final BeautyCenter center;
  final int initialServiceIndex;
  final String? selectedOffer;

  @override
  State<BeautyBookingScreen> createState() => _BeautyBookingScreenState();
}

class _BeautyBookingScreenState extends State<BeautyBookingScreen> {
  late int selectedService;
  String? selectedOffer;
  int selectedSpecialist = 0;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTime = '10:00 صباحاً';
  bool _creatingRemoteBooking = false;

  BeautyService get service => widget.center.services[selectedService];

  Future<void> _continueToRemotePayment() async {
    if (_creatingRemoteBooking) return;

    setState(() => _creatingRemoteBooking = true);

    try {
      final flow = ProviderBookingFlow.current;
      final remoteService = flow == null
          ? null
          : await flow.catalog.getService(service.id);
      final target = remoteService == null
          ? null
          : BeautyBackendTarget(
              providerId: remoteService.providerId,
              serviceId: remoteService.id,
              currency: remoteService.currency,
            );

      if (target == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(
              'خدمة مراكز التجميل غير مربوطة بكتالوج Laravel لهذه المحافظة.',
            ),
          ),
        );
        return;
      }

      final specialist = widget.center.specialists.isEmpty
          ? 'غير محدد'
          : widget.center.specialists[selectedSpecialist.clamp(
              0,
              widget.center.specialists.length - 1,
            )];
      // Laravel is the source of truth for booking totals.
      final serviceFee = 0;
      final total = service.price;
      final requiresPayment = remoteService?.requiresPayment ?? false;
      final profile = readBeautyProfile();

      if (!mounted || flow == null || remoteService == null) return;
      final choice = await selectProviderAvailability(
        context,
        flow,
        remoteService,
        scheduledAt: selectedDate,
      );
      if (choice.cancelled || !mounted) return;
      final booking = await createBeautyBackendBooking(
        BeautyBackendBookingRequest(
          target: target,
          serviceAvailabilityId: choice.id,
          total: total,
          scheduledAt: selectedDate,
          metadata: {
            'source': 'flutter_beauty_designed_flow',
            'module': 'beauty',
            'center_id': widget.center.id,
            'center_name': widget.center.name,
            'city': widget.center.city,
            'district': widget.center.district,
            'service_name': service.name,
            'service_category': service.category,
            'service_price': service.price,
            'service_fee': serviceFee,
            'duration_minutes': service.durationMinutes,
            'specialist': specialist,
            'appointment_date': selectedDate.toIso8601String(),
            'appointment_time': selectedTime,
            'selected_offer': selectedOffer,
            'account': {'full_name': profile?.name, 'phone': profile?.phone},
          },
        ),
      );

      if (!mounted) return;

      if (booking == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText('تعذر إنشاء حجز مركز التجميل في Laravel.'),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: LocalizedText(
            booking.status == 'confirmed'
                ? 'تم تأكيد الحجز'
                : 'تم إرسال طلب الحجز',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText('رقم الحجز: ${booking.id}'),
              const SizedBox(height: 8),
              LocalizedText('الإجمالي: ${booking.total} ${booking.currency}'),
              const SizedBox(height: 12),
              LocalizedText(
                booking.status == 'confirmed'
                    ? (requiresPayment
                          ? 'تم تأكيد الحجز فورًا. هذه الخدمة تتطلب دفعًا، ولم يتم خصم أي مبلغ حتى الآن.'
                          : 'تم تأكيد الحجز فورًا. هذه الخدمة لا تتطلب دفعًا إلكترونيًا.')
                    : (requiresPayment
                          ? 'بانتظار موافقة مقدم الخدمة. الدفع متوقف حتى ربط شركات الدفع، ولم يتم خصم أي مبلغ.'
                          : 'بانتظار موافقة مقدم الخدمة. هذه الخدمة لا تتطلب دفعًا إلكترونيًا، ولم يتم خصم أي مبلغ.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const LocalizedText('حسنًا'),
            ),
          ],
        ),
      );
    } on Object catch (error, stackTrace) {
      debugPrint('BEAUTY BOOKING ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(
              'تعذر إنشاء الحجز الحقيقي. تحقق من اتصال Laravel ثم حاول مجددًا.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingRemoteBooking = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selectedService = widget.initialServiceIndex
        .clamp(0, widget.center.services.length - 1)
        .toInt();
    selectedOffer = widget.selectedOffer;
  }

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
        if (ProviderBookingFlow.current == null) ...[
          const _BeautyHeading('عروضنا الحالية'),
          const SizedBox(height: 7),
          ..._beautyCurrentOffers
              .where((offer) => offer.$1 == service.category)
              .map(
                (offer) => _BeautyDepartmentOfferBanner(
                  offer: offer,
                  onTap: () {
                    final index = widget.center.services.indexWhere(
                      (item) => item.category == offer.$1,
                    );
                    setState(() {
                      if (index >= 0) selectedService = index;
                      selectedOffer = offer.$2;
                    });
                  },
                ),
              ),
        ],
        if (selectedOffer != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xffffe8f1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _beautyPink),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: _beautyPink),
                const SizedBox(width: 8),
                Expanded(
                  child: LocalizedText(
                    'العرض المختار: $selectedOffer',
                    style: const TextStyle(
                      color: _beautyNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.center.specialists.length,
            itemBuilder: (_, index) {
              final chosen = index == selectedSpecialist;
              return InkWell(
                onTap: () => setState(() => selectedSpecialist = index),
                child: Container(
                  width: 112,
                  margin: const EdgeInsets.only(left: 8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: chosen ? const Color(0xffffe8f1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: chosen ? _beautyPink : const Color(0xffffdce9),
                      width: chosen ? 1.7 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1c211132),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              beautyCenterImageAsset,
                              fit: BoxFit.cover,
                              alignment: Alignment(
                                ((index % 3) - 1).toDouble(),
                                0,
                              ),
                            ),
                            if (chosen)
                              const Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: CircleAvatar(
                                    radius: 11,
                                    backgroundColor: _beautyPink,
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 20,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: LocalizedText(
                              widget.center.specialists[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _beautyNavy,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
          label: 'إرسال طلب الحجز',
          onPressed: _continueToRemotePayment,
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
    required this.bookingId,
  });

  final BeautyCenter center;
  final BeautyService service;
  final String specialist;
  final DateTime date;
  final String time;
  final String bookingId;

  @override
  State<BeautyPaymentScreen> createState() => _BeautyPaymentScreenState();
}

class _BeautyPaymentScreenState extends State<BeautyPaymentScreen>
    with ProviderBookingState<BeautyPaymentScreen> {
  List<BeautyPaymentMethod> _paymentMethods = const [];
  String? _selectedPaymentMethodCode;
  String? _paymentMethodsError;
  bool _loadingPaymentMethods = true;
  bool _submittingRemotePayment = false;

  int get serviceFee => ProviderBookingFlow.current == null
      ? (widget.service.price * .05).round()
      : 0;
  int get total => widget.service.price + serviceFee;

  BeautyPaymentMethod? get _selectedPaymentMethod {
    final code = _selectedPaymentMethodCode;
    if (code == null) return null;

    for (final method in _paymentMethods) {
      if (method.code == code) return method;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    if (mounted) {
      setState(() {
        _loadingPaymentMethods = true;
        _paymentMethodsError = null;
      });
    }

    try {
      final methods = await loadBeautyPaymentMethods(
        currency: 'YER',
        amount: total,
      );

      if (!mounted) return;

      setState(() {
        _paymentMethods = methods;
        _selectedPaymentMethodCode = methods.isEmpty
            ? null
            : methods.first.code;
        _paymentMethodsError = null;
        _loadingPaymentMethods = false;
      });
    } on Object {
      if (!mounted) return;

      setState(() {
        _paymentMethods = const [];
        _selectedPaymentMethodCode = null;
        _paymentMethodsError =
            'تعذر تحميل وسائل الدفع حاليًا. تحقق من الاتصال ثم حاول مرة أخرى.';
        _loadingPaymentMethods = false;
      });
    }
  }

  IconData _paymentMethodIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'card':
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'bank':
      case 'bank_transfer':
        return Icons.account_balance_rounded;
      case 'mobile':
      case 'mobile_money':
        return Icons.phone_android_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Future<void> _submitRemotePayment() async {
    if (_submittingRemotePayment || _loadingPaymentMethods) return;

    final selectedMethod = _selectedPaymentMethod;

    if (selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText(
            'لا توجد وسيلة دفع مفعّلة حاليًا. لم يتم خصم أي مبلغ.',
          ),
        ),
      );
      return;
    }

    setState(() => _submittingRemotePayment = true);

    try {
      final result = await executeBeautyBackendPayment(
        widget.bookingId,
        selectedMethod.code,
      );

      if (!mounted) return;

      if (result.isPaid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BeautyBookingSuccessScreen(
              center: widget.center,
              service: widget.service,
              specialist: widget.specialist,
              date: widget.date,
              time: widget.time,
              method: selectedMethod.name,
              serviceFee: serviceFee,
              total: total,
              bookingNumber: widget.bookingId,
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: LocalizedText(result.message)));
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(
              'بوابة الدفع غير مربوطة فعليًا بعد. بقي الحجز محفوظًا في Laravel بحالة انتظار.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingRemotePayment = false);
      }
    }
  }

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
              LocalizedText(
                '1- يمكنكم إلغاء موعد الحجز مجاناً خلال 6 ساعات من تاريخ الحجز فقط.',
              ),
              Divider(),
              LocalizedText(
                '2- يخصم 50% من قيمة الحجز في حالة تأجيل الحجز إلى موعد آخر.',
              ),
              Divider(),
              LocalizedText(
                '3- لا يعاد مبلغ الحجز عند عدم حضور العميل في الموعد المحدد أو خلال مواعيد العمل في اليوم نفسه.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _BeautyHeading('اختر طريقة الدفع'),
        const SizedBox(height: 9),
        if (_loadingPaymentMethods)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _beautyCard(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: LocalizedText(
                    'جاري تحميل وسائل الدفع المتاحة...',
                    style: TextStyle(
                      color: _beautyNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_paymentMethods.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _beautyCard(),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _beautyPink,
                  size: 34,
                ),
                const SizedBox(height: 10),
                LocalizedText(
                  _paymentMethodsError ??
                      'لا توجد وسائل دفع مفعّلة حاليًا من لوحة التحكم. لم يتم خصم أي مبلغ.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _beautyNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _loadPaymentMethods(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const LocalizedText('إعادة المحاولة'),
                ),
              ],
            ),
          )
        else
          ..._paymentMethods.map((method) {
            final selected = _selectedPaymentMethodCode == method.code;

            return InkWell(
              onTap: () =>
                  setState(() => _selectedPaymentMethodCode = method.code),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _beautyPink : const Color(0xffffdce9),
                    width: selected ? 1.7 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? _beautyPink : const Color(0xff95889a),
                    ),
                    const SizedBox(width: 9),
                    Icon(_paymentMethodIcon(method.type), color: _beautyPink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LocalizedText(
                        method.name,
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
            );
          }),
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
          label: _loadingPaymentMethods
              ? 'جاري تحميل وسائل الدفع...'
              : _paymentMethods.isEmpty
              ? 'لا توجد وسيلة دفع متاحة'
              : _submittingRemotePayment
              ? 'جاري معالجة الدفع...'
              : 'ادفع الآن • ${_beautyMoney(total)} ر.ي',
          onPressed: _submitRemotePayment,
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

    required this.bookingNumber,
  });

  final String bookingNumber;

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
              _BeautyInvoiceLine('رقم الحجز', bookingNumber),
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
                bookingNumber: bookingNumber,
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

    required this.bookingNumber,
  });

  final BeautyCenter center;
  final BeautyService service;
  final String specialist;
  final DateTime date;
  final String time;
  final String method;
  final String bookingNumber;
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
                'رقم الحجز $bookingNumber',
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
                Positioned.fill(
                  child: CustomPaint(painter: _BeautyMapPainter()),
                ),
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
          invoiceTitle: 'فاتورة حجز ${center.name}',
          invoiceReference: bookingNumber,
          invoiceStatus: 'تم الدفع بنجاح',
          invoiceDetails: [
            ('رقم الحجز', bookingNumber),
            ('الخدمة', service.name),
            ('المختص', specialist),
            ('التاريخ', _beautyDate(date)),
            ('الوقت', time),
            ('المدة', '${service.durationMinutes} دقيقة'),
            ('المركز', center.name),
            ('طريقة الدفع', method),
            ('سعر الخدمة', '${_beautyMoney(service.price)} ر.ي'),
            ('رسوم الحجز', '${_beautyMoney(serviceFee)} ر.ي'),
            ('الإجمالي', '${_beautyMoney(total)} ر.ي'),
            ('حالة الدفع', 'تم الدفع بنجاح'),
            ('رقم العملية', 'PAY-BC-20458'),
            ('الموقع', '${center.district} • ${center.city}'),
            ('رمز التحقق', 'BC20458'),
          ],
          invoiceText:
              'فاتورة حجز ${center.name}\n${service.name}\nرقم الحجز: $bookingNumber\nالإجمالي: ${_beautyMoney(total)} ر.ي',
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
    if (!allowLocalReview(context)) return;
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
                      beautyMainLogoAsset,
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
                center.reviews == 0
                    ? 'لا توجد تقييمات بعد'
                    : '★ ${center.rating} • ${center.reviews} تقييم',
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
      fontSize: 18,
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

void _showBeautySection(
  BuildContext context,
  BeautyCenter center,
  String section,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => Directionality(
      textDirection: localizedTextDirection,
      child: SafeArea(
        child: FractionallySizedBox(
          heightFactor: _beautySheetHeight(section),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              if ({'فريقنا', 'قبل وبعد', 'أسئلة متكررة'}.contains(section)) ...[
                _BeautySectionBanner(center: center, section: section),
                const SizedBox(height: 16),
              ],
              _BeautyHeading(section),
              const SizedBox(height: 12),
              _beautySectionContent(center, section),
            ],
          ),
        ),
      ),
    ),
  );
}

double _beautySheetHeight(String section) => switch (section) {
  'تواصل معنا' => .94,
  'مواعيدنا' => .88,
  'قبل وبعد' => .92,
  'أسئلة متكررة' => .94,
  'فريقنا' => .90,
  _ => .74,
};

Widget _beautySectionContent(BeautyCenter center, String section) =>
    switch (section) {
      'من نحن' => _BeautyAboutContent(center: center),
      'فريقنا' => _BeautyTeamGrid(center: center),
      'قبل وبعد' => _BeautyBeforeAfterContent(center: center),
      'أسئلة متكررة' => const _BeautyFaqContent(),
      'مواعيدنا' => _BeautyHoursContent(center: center),
      _ => _BeautyContactContent(center: center),
    };

class _BeautySectionBanner extends StatelessWidget {
  const _BeautySectionBanner({required this.center, required this.section});

  final BeautyCenter center;
  final String section;

  IconData get icon => switch (section) {
    'فريقنا' => Icons.medical_services_outlined,
    'قبل وبعد' => Icons.compare_rounded,
    _ => Icons.quiz_outlined,
  };

  String get subtitle => switch (section) {
    'فريقنا' => 'خبرات متخصصة تمنحك عناية آمنة ونتائج موثوقة',
    'قبل وبعد' => 'نتائج موثقة لحالات مختارة بإشراف فريق المركز',
    _ => 'إجابات واضحة عن أكثر الأسئلة التي تهمك قبل الحجز',
  };

  @override
  Widget build(BuildContext context) => Container(
    height: 155,
    clipBehavior: Clip.antiAlias,
    decoration: _beautyCard(radius: 15),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(beautyCenterBannerAsset, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xe6211132), Color(0xb0a9185b)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .72),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 29),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      section,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    LocalizedText(
                      center.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    LocalizedText(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.35,
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
  );
}

class _BeautyAboutContent extends StatelessWidget {
  const _BeautyAboutContent({required this.center});

  final BeautyCenter center;

  static const values = <(String, String, IconData)>[
    (
      'الجودة',
      'نسعى لتقديم أعلى مستوى من الخدمة التي ترضي العميل وتحقق تطلعاته.',
      Icons.workspace_premium_rounded,
    ),
    (
      'المجتمع',
      'نعتني بصحة وجمال مجتمعنا ونقدم تجربة آمنة تراعي احتياجات الجميع.',
      Icons.groups_2_rounded,
    ),
    (
      'الإبداع',
      'نبتكر حلولاً عصرية ونستخدم تقنيات حديثة للوصول إلى أفضل النتائج.',
      Icons.auto_awesome_rounded,
    ),
    (
      'المصداقية',
      'نلتزم بالوضوح والأمانة في الاستشارة والخدمة والأسعار والنتائج المتوقعة.',
      Icons.verified_user_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _BeautySubheading('عن المركز'),
      LocalizedText(center.description, style: const TextStyle(height: 1.65)),
      const SizedBox(height: 14),
      const _BeautySubheading('تاريخ التأسيس'),
      const LocalizedText(
        'تأسس المركز عام 2018 ويستمر في تطوير خدماته وفريقه المتخصص.',
      ),
      const SizedBox(height: 14),
      const _BeautySubheading('رسالتنا'),
      const LocalizedText(
        'تقديم رعاية تجميلية موثوقة وآمنة تجعل كل عميل أكثر ثقة ورضاً.',
      ),
      const SizedBox(height: 14),
      const _BeautySubheading('رؤيتنا'),
      const LocalizedText(
        'أن نكون الوجهة الأولى لخدمات الجمال والعناية المتخصصة في اليمن.',
      ),
      const SizedBox(height: 18),
      const _BeautySubheading('قيمنا'),
      const SizedBox(height: 9),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: values.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.18,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (_, index) {
          final value = values[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: _beautyCard(radius: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(value.$3, color: _beautyPink, size: 25),
                const SizedBox(height: 7),
                LocalizedText(
                  value.$1,
                  style: const TextStyle(
                    color: _beautyNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: LocalizedText(
                    value.$2,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, height: 1.35),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _BeautyTeamGrid extends StatelessWidget {
  const _BeautyTeamGrid({required this.center});

  final BeautyCenter center;

  String _role(String name) =>
      name.startsWith('د.') ? 'طبيب متخصص' : 'أخصائية تجميل';

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: center.specialists.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      childAspectRatio: .56,
      crossAxisSpacing: 8,
      mainAxisSpacing: 12,
    ),
    itemBuilder: (_, index) {
      final specialist = center.specialists[index];
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: _beautyCard(radius: 12),
        child: Column(
          children: [
            Expanded(
              flex: 70,
              child: SizedBox.expand(
                child: Image.asset(
                  beautyCenterImageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment(((index % 3) - 1).toDouble(), 0),
                ),
              ),
            ),
            Expanded(
              flex: 15,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: LocalizedText(
                    specialist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _beautyNavy,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 15,
              child: Container(
                width: double.infinity,
                color: _beautyBrandBlue,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: LocalizedText(
                  _role(specialist),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _BeautyBeforeAfterContent extends StatelessWidget {
  const _BeautyBeforeAfterContent({required this.center});

  final BeautyCenter center;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _beautyCard(radius: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _BeautyCaseImage(
                    label: 'قبل',
                    labelColor: _beautyBrandBlue,
                    image: ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        .35,
                        .35,
                        .35,
                        0,
                        20,
                        .35,
                        .35,
                        .35,
                        0,
                        20,
                        .35,
                        .35,
                        .35,
                        0,
                        20,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: Image.asset(
                        beautyCenterImageAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BeautyCaseImage(
                    label: 'بعد',
                    labelColor: _beautyBrandOrange,
                    image: Image.asset(
                      beautyCenterImageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            LocalizedText(
              '${center.name}\nحالة علاج تصبغات وبهاق سطحي بعد خطة علاجية متدرجة ومتابعة منتظمة مع مختص الجلدية.',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.55, color: _beautyNavy),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfffff0f6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _beautyPink),
            SizedBox(width: 8),
            Expanded(
              child: LocalizedText(
                'النتائج تختلف من حالة إلى أخرى، وتُعرض الصور بعد موافقة العميل وتُدار من لوحة التحكم.',
                style: TextStyle(fontSize: 12, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BeautyCaseImage extends StatelessWidget {
  const _BeautyCaseImage({
    required this.label,
    required this.labelColor,
    required this.image,
  });

  final String label;
  final Color labelColor;
  final Widget image;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 185,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffffc6dc)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x420d1630),
              blurRadius: 14,
              spreadRadius: -2,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox.expand(child: image),
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: labelColor,
          borderRadius: BorderRadius.circular(9),
        ),
        child: LocalizedText(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _BeautyFaqContent extends StatelessWidget {
  const _BeautyFaqContent();

  static const questions = <(String, String)>[
    (
      'هل أحتاج إلى استشارة قبل الحجز؟',
      'نعم لبعض الخدمات الطبية والليزر لضمان اختيار الإجراء الأنسب لحالتك.',
    ),
    (
      'كم عدد الجلسات المتوقعة؟',
      'يختلف العدد حسب نوع الخدمة والحالة، ويحدده المختص بعد التقييم الأولي.',
    ),
    (
      'هل الأجهزة والمواد المستخدمة آمنة؟',
      'يستخدم المركز أجهزة معتمدة ومنتجات أصلية مع تطبيق إجراءات التعقيم.',
    ),
    (
      'هل يمكن تغيير موعد الحجز؟',
      'يمكن طلب تغيير الموعد وفق سياسة المركز وتوفر المواعيد البديلة.',
    ),
    (
      'هل تتوفر خصوصية للعميلات؟',
      'نعم، تتوفر غرف خاصة وفريق نسائي للخدمات المخصصة للسيدات.',
    ),
    (
      'متى تظهر نتائج الجلسة؟',
      'بعض النتائج فورية، بينما تحتاج خدمات أخرى إلى عدة جلسات ومتابعة.',
    ),
    (
      'هل الأسعار تشمل المتابعة؟',
      'توضح بطاقة كل خدمة ما يشمله السعر، ويمكن الاستفسار قبل تأكيد الحجز.',
    ),
    (
      'كيف أتواصل عند وجود ملاحظة؟',
      'يمكن التواصل عبر الهاتف أو واتساب أو نموذج الرسالة داخل التطبيق.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: questions
        .map(
          (item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: _beautyCard(radius: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xffffe4ef),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_mark_rounded,
                        color: _beautyPink,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: LocalizedText(
                        item.$1,
                        style: const TextStyle(
                          color: _beautyNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Divider(height: 1, color: Color(0xffffd6e5)),
                ),
                LocalizedText(
                  item.$2,
                  style: const TextStyle(
                    color: Color(0xff5f5364),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _BeautyHoursContent extends StatelessWidget {
  const _BeautyHoursContent({required this.center});

  final BeautyCenter center;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 175,
        clipBehavior: Clip.antiAlias,
        decoration: _beautyCard(radius: 12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(beautyCenterBannerAsset, fit: BoxFit.cover),
            Container(color: const Color(0x8872113f)),
            Center(
              child: LocalizedText(
                center.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const _BeautyHoursRow(
        'الفترة الصباحية',
        '9:00 ص – 1:00 م',
        Icons.wb_sunny_outlined,
      ),
      const _BeautyHoursRow(
        'الفترة المسائية',
        '2:00 م – 6:00 م',
        Icons.wb_twilight_outlined,
      ),
      const _BeautyHoursRow(
        'الفترة الليلية',
        '6:30 م – 9:00 م',
        Icons.nights_stay_outlined,
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xfffff0f6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BeautySubheading('الإجازات والملاحظات'),
            LocalizedText(
              'الجمعة: إجازة أسبوعية، والحجوزات الطارئة حسب توفر المختص.',
            ),
            SizedBox(height: 5),
            LocalizedText(
              'يرجى الحضور قبل الموعد بعشر دقائق لإتمام بيانات الاستقبال.',
            ),
          ],
        ),
      ),
    ],
  );
}

class _BeautyHoursRow extends StatelessWidget {
  const _BeautyHoursRow(this.label, this.time, this.icon);

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: _beautyCard(radius: 12),
    child: Row(
      children: [
        Icon(icon, color: _beautyPink),
        const SizedBox(width: 10),
        Expanded(
          child: LocalizedText(
            label,
            style: const TextStyle(
              color: _beautyNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        LocalizedText(
          time,
          style: const TextStyle(
            color: _beautyDeepPink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _BeautyContactContent extends StatelessWidget {
  const _BeautyContactContent({required this.center});

  final BeautyCenter center;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 155,
        clipBehavior: Clip.antiAlias,
        decoration: _beautyCard(radius: 12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(beautyCenterBannerAsset, fit: BoxFit.cover),
            Container(color: const Color(0x8872113f)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    center.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    '${center.district}، ${center.city}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.15,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        children: [
          _BeautyContactCard(
            label: 'مواقع التواصل',
            value: '@hujuzatcom',
            icon: Icons.public_rounded,
            onTap: () => _launchBeautyContact('https://www.hujuzat.com'),
          ),
          _BeautyContactCard(
            label: 'البريد الإلكتروني',
            value: 'info@hujuzat.com',
            icon: Icons.email_outlined,
            onTap: () => _launchBeautyContact('mailto:info@hujuzat.com'),
          ),
          _BeautyContactCard(
            label: 'واتساب',
            value: '70000001',
            icon: Icons.chat_outlined,
            onTap: () => _launchBeautyContact('https://wa.me/96770000001'),
          ),
          _BeautyContactCard(
            label: 'اتصل بنا',
            value: '70000000',
            icon: Icons.phone_outlined,
            onTap: () => _launchBeautyContact('tel:70000000'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const _BeautySubheading('أرسل لنا رسالة'),
      const SizedBox(height: 7),
      TextField(
        decoration: _beautyContactInput('الاسم', Icons.person_outline_rounded),
      ),
      const SizedBox(height: 9),
      TextField(
        keyboardType: TextInputType.emailAddress,
        decoration: _beautyContactInput(
          'البريد الإلكتروني (اختياري)',
          Icons.email_outlined,
        ),
      ),
      const SizedBox(height: 9),
      TextField(
        keyboardType: TextInputType.phone,
        decoration: _beautyContactInput(
          'رقم الجوال',
          Icons.phone_android_rounded,
        ),
      ),
      const SizedBox(height: 9),
      TextField(
        minLines: 4,
        maxLines: 6,
        decoration: _beautyContactInput(
          'اكتب رسالتك هنا',
          Icons.edit_note_rounded,
        ),
      ),
      const SizedBox(height: 11),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: LocalizedText('تم إرسال رسالتك إلى المركز بنجاح.'),
            ),
          ),
          icon: const Icon(Icons.send_rounded),
          label: const LocalizedText('إرسال الرسالة'),
        ),
      ),
    ],
  );
}

class _BeautyContactCard extends StatelessWidget {
  const _BeautyContactCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: _beautyCard(radius: 12),
        child: Row(
          children: [
            Icon(icon, color: _beautyPink),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _beautyNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _beautyDeepPink,
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

InputDecoration _beautyContactInput(String label, IconData icon) =>
    InputDecoration(
      labelText: l10n(label),
      prefixIcon: Icon(icon, color: _beautyPink),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffffdce9)),
      ),
    );

Future<void> _launchBeautyContact(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _BeautySubheading extends StatelessWidget {
  const _BeautySubheading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: LocalizedText(
      label,
      style: const TextStyle(
        color: _beautyNavy,
        fontSize: 16,
        fontWeight: FontWeight.w900,
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
