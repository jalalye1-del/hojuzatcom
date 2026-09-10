import '../../bookings/presentation/provider_booking_flow.dart';
import 'package:flutter/material.dart';
import '../../auth/presentation/booking_auth_gate.dart';
import '../data/apartment_backend_bridge.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/maps/app_map_launcher.dart';
import '../../../core/reviews/service_review.dart';
import '../domain/apartment.dart';

const apartmentBannerAsset = 'assets/images/apartment_booking_banner.png';
const apartmentImageAsset = 'assets/Services images/الشقق المفروشة.jpg';

const _apartmentBlue = Color(0xff1559f5);
const _apartmentDarkBlue = Color(0xff0b3f9f);
const _apartmentNavy = Color(0xff07143d);
const _apartmentGreen = Color(0xff10b866);
const _apartmentOrange = Color(0xffffa000);
const _apartmentSurface = Color(0xfff5f7ff);

// صيغة مؤقتة مطابقة لبيانات لوحة التحكم: يمكن للخادم تغيير السعر والحالة
// أو إضافة خدمة جديدة من دون تعديل تصميم البطاقة.
const _apartmentUtilityPrices = <String, int>{
  'الماء': 0,
  'الكهرباء': 0,
  'المغسلة الخارجية': 3500,
  'النظافة الداخلية': 2500,
  'الإنترنت': 0,
  'الغاز': 1500,
};

String _apartmentMoney(int value) => formatMoney(value);

String _apartmentDate(DateTime value) =>
    '${value.day}/${value.month}/${value.year}';

class ApartmentDiscoveryScreen extends StatefulWidget {
  const ApartmentDiscoveryScreen({
    super.key,
    required this.province,
    this.appBottomNavigationBar,
  });

  final String province;
  final Widget? appBottomNavigationBar;

  @override
  State<ApartmentDiscoveryScreen> createState() =>
      _ApartmentDiscoveryScreenState();
}

class _ApartmentDiscoveryScreenState extends State<ApartmentDiscoveryScreen> {
  String query = '';
  String sortMode = '';
  final favorites = <String>{};

  List<Apartment> get visibleApartments {
    var result = apartments
        .where(
          (apartment) =>
              apartment.name.contains(query) ||
              apartment.city.contains(query) ||
              apartment.neighborhood.contains(query),
        )
        .toList();
    if (sortMode == 'الأقل سعراً') {
      result.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
    } else if (sortMode == 'المفتوحة حديثاً') {
      result = result.reversed.toList();
    }
    return result;
  }

  void _openApartment(Apartment apartment, {String? officeName}) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApartmentHostListingsScreen(
            hostApartment: apartment,
            officeName:
                ProviderBookingFlow.current?.providerFor(
                  'apartments',
                  apartment.id,
                ) ??
                officeName ??
                'نواره للشقق المفروشة',
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _apartmentSurface,
      bottomNavigationBar: widget.appBottomNavigationBar,
      body: SafeArea(
        child: ListView(
          key: const Key('apartment-home-list'),
          padding: EdgeInsets.zero,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xffeaf3ff),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      apartmentBannerAsset,
                      key: const Key('apartment-main-banner'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: _RoundAction(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
                decoration: _apartmentCard(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      l10n('ابحث عن شقة مفروشة'),
                      style: const TextStyle(
                        color: _apartmentNavy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextField(
                      key: const Key('apartment-search-field'),
                      onChanged: (value) =>
                          setState(() => query = value.trim()),
                      decoration: InputDecoration(
                        hintText: l10n('المنطقة، اسم الشقة، أو معلم قريب'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: _apartmentBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                          ),
                        ),
                        filled: true,
                        fillColor: _apartmentSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xffdce3f3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xffdce3f3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ApartmentQuickFilter(
                            icon: Icons.near_me_outlined,
                            label: 'الأقرب إليك',
                            selected: false,
                            onPressed: () => AppMapLauncher.open(
                              context,
                              query: 'شقق مفروشة ${widget.province} اليمن',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ApartmentQuickFilter(
                            icon: Icons.sell_outlined,
                            label: 'الأقل سعراً',
                            selected: sortMode == 'الأقل سعراً',
                            onPressed: () =>
                                setState(() => sortMode = 'الأقل سعراً'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ApartmentQuickFilter(
                            icon: Icons.new_releases_outlined,
                            label: 'المفتوحة حديثاً',
                            selected: sortMode == 'المفتوحة حديثاً',
                            onPressed: () =>
                                setState(() => sortMode = 'المفتوحة حديثاً'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 22, 16, 10),
              child: _ApartmentHeading(l10n('عروض مميزة')),
            ),
            if (visibleApartments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: LocalizedText(l10n('لا توجد شقق مطابقة لبحثك')),
                ),
              )
            else
              Padding(
                key: const Key('apartment-featured-offers'),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: visibleApartments
                      .map(
                        (apartment) => SizedBox(
                          height: 312,
                          child: _ApartmentOfferCard(
                            key: Key('apartment-card-${apartment.id}'),
                            width: double.infinity,
                            apartment: apartment,
                            isFavorite: favorites.contains(apartment.id),
                            onFavorite: () => setState(() {
                              favorites.contains(apartment.id)
                                  ? favorites.remove(apartment.id)
                                  : favorites.add(apartment.id);
                            }),
                            onTap: () => _openApartment(apartment),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
              child: _ApartmentHeading(l10n('مكاتب الشقق المسجلة والمعتمدة')),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visibleApartments.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .9,
              ),
              itemBuilder: (_, index) {
                final apartment = visibleApartments[index];
                const officeNames = [
                  'نواره للشقق المفروشة',
                  'روابي حدة للشقق',
                  'أجنحة نقم الفندقية',
                  'دار عدن المفروشة',
                ];
                final officeName = officeNames[index % officeNames.length];
                return _ApartmentOfficeCard(
                  apartment: apartment,
                  officeName: officeName,
                  onTap: () =>
                      _openApartment(apartment, officeName: officeName),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

class _ApartmentOfferCard extends StatelessWidget {
  const _ApartmentOfferCard({
    super.key,
    required this.apartment,
    required this.width,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final Apartment apartment;
  final double width;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      margin: const EdgeInsets.only(left: 12, bottom: 5),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  apartmentImageAsset,
                  height: 116,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffeafff3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: LocalizedText(
                      l10n('متاح الآن'),
                      style: const TextStyle(
                        color: _apartmentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 7,
                  left: 7,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.redAccent : _apartmentNavy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      l10n(apartment.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _apartmentNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    LocalizedText(
                      '${l10n(apartment.neighborhood)} • ${l10n(apartment.city)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xff7f8aa8)),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: _apartmentOrange,
                          size: 17,
                        ),
                        LocalizedText(
                          '${apartment.rating} (${apartment.reviews})',
                          style: const TextStyle(
                            color: _apartmentOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfffff1d6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const LocalizedText(
                        'خصم 25% لحجز 10 أيام فأكثر',
                        style: TextStyle(
                          fontSize: 9,
                          color: _apartmentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    LocalizedText(
                      '${_apartmentMoney(apartment.oldPrice)} ريال',
                      style: const TextStyle(
                        color: Color(0xff8b95ad),
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    LocalizedText(
                      '${_apartmentMoney(apartment.pricePerNight)} ريال',
                      style: const TextStyle(
                        color: _apartmentNavy,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    LocalizedText(
                      l10n('لليلة'),
                      style: const TextStyle(color: Color(0xff8b95ad)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ApartmentQuickFilter extends StatelessWidget {
  const _ApartmentQuickFilter({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xffe4edff) : Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _apartmentBlue : const Color(0xffdce3f3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: _apartmentBlue),
            const SizedBox(height: 2),
            LocalizedText(
              l10n(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _apartmentNavy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ApartmentOfficeCard extends StatelessWidget {
  const _ApartmentOfficeCard({
    required this.apartment,
    required this.officeName,
    required this.onTap,
  });

  final Apartment apartment;
  final String officeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 5,
    shadowColor: const Color(0x330b3f9f),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              apartmentImageAsset,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalizedText(
                    officeName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _apartmentNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LocalizedText(
                    '★ ${apartment.rating} (${apartment.reviews})',
                    style: const TextStyle(
                      color: _apartmentOrange,
                      fontSize: 11,
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

class ApartmentHostListingsScreen extends StatefulWidget {
  const ApartmentHostListingsScreen({
    super.key,
    required this.hostApartment,
    required this.officeName,
  });

  final Apartment hostApartment;
  final String officeName;

  @override
  State<ApartmentHostListingsScreen> createState() =>
      _ApartmentHostListingsScreenState();
}

class _ApartmentHostListingsScreenState
    extends State<ApartmentHostListingsScreen> {
  String selectedType = 'الكل';

  List<Apartment> get units => apartments.where((item) {
    final flow = ProviderBookingFlow.current;
    final sameProvider =
        flow == null ||
        flow.providerFor('apartments', item.id) == widget.officeName;
    return sameProvider &&
        (selectedType == 'الكل' || item.unitType == selectedType);
  }).toList();

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _apartmentSurface,
      appBar: AppBar(
        backgroundColor: _apartmentSurface,
        title: LocalizedText(
          widget.officeName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('apartment-host-list'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 165),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_apartmentDarkBlue, _apartmentBlue],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      apartmentImageAsset,
                      width: 112,
                      height: 132,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          l10n(widget.officeName, 'Verified Hujuzatcom host'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        LocalizedText(
                          l10n('اختر الوحدة المناسبة لإقامتك'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 43,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['الكل', 'عائلية', 'متوسطة', 'صغيرة', 'استوديو']
                    .map(
                      (type) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          key: Key('apartment-unit-type-$type'),
                          label: LocalizedText(
                            type == 'الكل' ? l10n('الكل', 'All') : l10n(type),
                          ),
                          selected: selectedType == type,
                          showCheckmark: false,
                          selectedColor: const Color(0xffe7efff),
                          side: BorderSide(
                            color: selectedType == type
                                ? _apartmentBlue
                                : const Color(0xffdce3f1),
                          ),
                          onSelected: (_) =>
                              setState(() => selectedType = type),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            ...units.map(
              (apartment) => _ApartmentHostUnitCard(
                key: Key('apartment-host-unit-${apartment.id}'),
                apartment: apartment,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ApartmentDetailsScreen(apartment: apartment),
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

class _ApartmentHostUnitCard extends StatelessWidget {
  const _ApartmentHostUnitCard({
    super.key,
    required this.apartment,
    required this.onTap,
  });

  final Apartment apartment;
  final VoidCallback onTap;
  bool get available => apartment.id != 'bait-baws-family';

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: InkWell(
      onTap: available
          ? onTap
          : () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: LocalizedText(
                  'هذه الشقة غير متاحة حالياً. يمكنك تفعيل التنبيه.',
                ),
              ),
            ),
      child: Row(
        children: [
          Image.asset(
            apartmentImageAsset,
            width: MediaQuery.sizeOf(context).width * .30,
            height: 170,
            fit: BoxFit.cover,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ApartmentPill(
                        text: l10n(apartment.unitType),
                        icon: Icons.category_outlined,
                        color: _apartmentBlue,
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n('إعلمني عند توفرها'),
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: LocalizedText(
                                  available
                                      ? 'الشقة متاحة الآن'
                                      : 'تم تفعيل التنبيه، سنعلمك عند توفر الشقة',
                                ),
                              ),
                            ),
                        icon: Icon(
                          available
                              ? Icons.notifications_none_rounded
                              : Icons.notifications_active_rounded,
                          color: _apartmentOrange,
                        ),
                      ),
                      LocalizedText(
                        '★ ${apartment.rating}',
                        style: const TextStyle(
                          color: _apartmentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LocalizedText(
                    l10n(apartment.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _apartmentNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _ApartmentPill(
                    text: available
                        ? l10n('متاحة')
                        : l10n('غير متاحة لمدة يومين'),
                    icon: available ? Icons.check_circle : Icons.schedule,
                    color: available ? _apartmentGreen : _apartmentOrange,
                  ),
                  LocalizedText(
                    '${apartment.bedrooms} ${l10n('غرف نوم', 'bedrooms')} • ${apartment.area} م²',
                    style: const TextStyle(color: Color(0xff7e89a4)),
                  ),
                  const SizedBox(height: 5),
                  LocalizedText(
                    '${_apartmentMoney(apartment.pricePerNight)} ${l10n('ريال', 'YER')}',
                    style: const TextStyle(
                      color: _apartmentBlue,
                      fontSize: 17,
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

class _ApartmentMediaGallery extends StatefulWidget {
  const _ApartmentMediaGallery({required this.apartment});

  final Apartment apartment;

  @override
  State<_ApartmentMediaGallery> createState() => _ApartmentMediaGalleryState();
}

class _ApartmentMediaGalleryState extends State<_ApartmentMediaGallery> {
  final controller = PageController();
  int selected = 0;
  bool playing = false;

  static const media = <({bool video, String label})>[
    (video: false, label: 'صور'),
    (video: false, label: 'صور'),
    (video: false, label: 'صور'),
    (video: true, label: 'فيديو'),
    (video: true, label: 'فيديو'),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() {
      selected = index;
      playing = false;
    });
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: Stack(
      children: [
        PageView.builder(
          key: const Key('apartment-media-gallery'),
          controller: controller,
          itemCount: media.length,
          onPageChanged: (index) => setState(() {
            selected = index;
            playing = false;
          }),
          itemBuilder: (context, index) {
            final item = media[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(apartmentImageAsset, fit: BoxFit.cover),
                if (item.video) ...[
                  Container(color: const Color(0x6607143d)),
                  Center(
                    child: InkWell(
                      key: Key('apartment-video-${index - 2}'),
                      onTap: () => setState(() => playing = !playing),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _apartmentBlue,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 78,
                    child: Column(
                      children: [
                        LocalizedText(
                          l10n('جولة فيديو للشقة'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if (playing)
                          TweenAnimationBuilder<double>(
                            key: ValueKey('video-progress-$index-$playing'),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(seconds: 8),
                            builder: (_, value, _) => LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              color: Colors.white,
                              backgroundColor: Colors.white38,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          )
                        else
                          LocalizedText(
                            l10n('اضغط لتشغيل الجولة'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        PositionedDirectional(
          top: 12,
          start: 14,
          child: _RoundAction(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        PositionedDirectional(
          top: 12,
          end: 14,
          child: Row(
            children: [
              _RoundAction(
                icon: Icons.share_outlined,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${widget.apartment.name}\n${widget.apartment.neighborhood}، ${widget.apartment.city}\n${_apartmentMoney(widget.apartment.pricePerNight)} ريال لليلة',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RoundAction(
                icon: Icons.favorite_border_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              media.length,
              (index) => InkWell(
                key: Key('apartment-media-thumb-$index'),
                onTap: () => _select(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 55,
                  height: 45,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected == index ? _apartmentBlue : Colors.white,
                      width: selected == index ? 3 : 1.5,
                    ),
                    image: media[index].video
                        ? null
                        : const DecorationImage(
                            image: AssetImage(apartmentImageAsset),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: media[index].video
                      ? const Icon(
                          Icons.play_circle_fill_rounded,
                          color: _apartmentBlue,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ApartmentDetailsScreen extends StatelessWidget {
  const ApartmentDetailsScreen({super.key, required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _apartmentSurface,
      bottomNavigationBar: _ApartmentBookingBar(
        apartment: apartment,
        onBook: () => openProtectedBooking(
          context,
          nextScreen: ApartmentBookingDetailsScreen(apartment: apartment),
          serviceTitle: 'شقق مفروشة',
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('apartment-detail-list'),
          padding: EdgeInsets.zero,
          children: [
            _ApartmentMediaGallery(apartment: apartment),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    l10n(apartment.name),
                    style: const TextStyle(
                      color: _apartmentNavy,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    '${l10n(apartment.neighborhood)} • ${l10n(apartment.city)}',
                    style: const TextStyle(
                      color: Color(0xff7f8aa8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LocalizedText(
                        '★ ${apartment.rating} ممتاز • ${apartment.reviews} تقييم',
                        style: const TextStyle(
                          color: _apartmentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const _ApartmentPill(
                        text: 'موثّق ومعتمد',
                        icon: Icons.verified_rounded,
                        color: _apartmentGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ApartmentFeatureGrid(apartment: apartment),
                  const SizedBox(height: 23),
                  const _ApartmentHeading('السعر'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      LocalizedText(
                        '${_apartmentMoney(apartment.pricePerNight)} ريال',
                        style: const TextStyle(
                          color: _apartmentBlue,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const LocalizedText(
                        ' / الليلة',
                        style: TextStyle(color: Color(0xff7f8aa8)),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          LocalizedText(
                            '${_apartmentMoney(apartment.oldPrice)} ريال',
                            style: const TextStyle(
                              color: Color(0xff98a1b6),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const _ApartmentPill(
                            text: 'خصم 20٪',
                            icon: Icons.local_offer_outlined,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 23),
                  _ApartmentHeading(l10n('تفاصيل الشقة')),
                  const SizedBox(height: 7),
                  LocalizedText(
                    l10n(apartment.description),
                    style: const TextStyle(
                      color: Color(0xff64708d),
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const _ApartmentInfoChip(
                        Icons.login_rounded,
                        'تسجيل ذاتي',
                      ),
                      _ApartmentInfoChip(
                        Icons.layers_outlined,
                        apartment.floor,
                      ),
                      const _ApartmentInfoChip(
                        Icons.elevator_outlined,
                        'مصعد متوفر',
                      ),
                      _ApartmentInfoChip(
                        Icons.square_foot_rounded,
                        '${apartment.area} م²',
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _ApartmentHeading(l10n('المميزات والخدمات')),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.4,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 9,
                        ),
                    itemCount: apartment.amenities.length,
                    itemBuilder: (_, index) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: _apartmentSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffe0e5f1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _amenityIcon(apartment.amenities[index]),
                            color: _apartmentBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LocalizedText(
                              l10n(apartment.amenities[index]),
                              style: const TextStyle(
                                color: _apartmentNavy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _ApartmentHeading(l10n('الخدمات المدفوعة')),
                  const SizedBox(height: 12),
                  GridView.builder(
                    key: const Key('apartment-utilities-grid'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.25,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 9,
                        ),
                    itemCount: apartment.utilities.length,
                    itemBuilder: (context, index) {
                      final utility = apartment.utilities.entries.elementAt(
                        index,
                      );
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: utility.value
                              ? const Color(0xffeafff3)
                              : const Color(0xfffff1f1),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: utility.value
                                ? _apartmentGreen
                                : Colors.redAccent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _utilityIcon(utility.key),
                              color: utility.value
                                  ? _apartmentGreen
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LocalizedText(
                                    l10n(utility.key),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _apartmentNavy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  LocalizedText(
                                    utility.value
                                        ? l10n('شامل')
                                        : '${_apartmentMoney(_apartmentUtilityPrices[utility.key] ?? 0)} ريال',
                                    style: TextStyle(
                                      color: utility.value
                                          ? _apartmentGreen
                                          : Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

class ApartmentBookingDetailsScreen extends StatefulWidget {
  const ApartmentBookingDetailsScreen({super.key, required this.apartment});

  final Apartment apartment;

  @override
  State<ApartmentBookingDetailsScreen> createState() =>
      _ApartmentBookingDetailsScreenState();
}

class _ApartmentBookingDetailsScreenState
    extends State<ApartmentBookingDetailsScreen> {
  DateTime arrival = DateTime.now().add(const Duration(days: 2));
  DateTime departure = DateTime.now().add(const Duration(days: 5));
  int guests = 2;

  int get nights => departure.difference(arrival).inDays.clamp(1, 30);
  int get subtotal => providerQuotedTotal(
    'apartments',
    widget.apartment.id,
    widget.apartment.pricePerNight,
    nights,
  );

  Future<void> _pickDate(bool isArrival) async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: isArrival ? arrival : departure,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (chosen == null) return;
    setState(() {
      if (isArrival) {
        arrival = chosen;
        if (!departure.isAfter(arrival)) {
          departure = arrival.add(const Duration(days: 1));
        }
      } else if (chosen.isAfter(arrival)) {
        departure = chosen;
      }
    });
  }

  @override
  Widget build(BuildContext context) => ApartmentBookingScaffold(
    step: 1,
    title: 'احجز شقتك',
    subtitle: 'أنت على وشك حجز شقة رائعة',
    child: ListView(
      key: const Key('apartment-booking-details-list'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _ApartmentSummary(apartment: widget.apartment),
        const SizedBox(height: 20),
        const _ApartmentHeading('تفاصيل الحجز'),
        const SizedBox(height: 10),
        _BookingValueTile(
          title: 'تاريخ الوصول',
          value: _apartmentDate(arrival),
          icon: Icons.login_rounded,
          onTap: () => _pickDate(true),
        ),
        _BookingValueTile(
          title: 'وقت الوصول',
          value: '11:00 ظهراً',
          icon: Icons.access_time_rounded,
        ),
        _BookingValueTile(
          title: 'تاريخ المغادرة',
          value: _apartmentDate(departure),
          icon: Icons.logout_rounded,
          onTap: () => _pickDate(false),
        ),
        const _BookingValueTile(
          title: 'وقت المغادرة',
          value: '12:00 ظهراً',
          icon: Icons.schedule_rounded,
        ),
        _BookingValueTile(
          title: 'عدد الليالي',
          value: '$nights ليالٍ',
          icon: Icons.nights_stay_outlined,
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(14),
          decoration: _apartmentCard(),
          child: Row(
            children: [
              const Icon(Icons.group_outlined, color: _apartmentBlue),
              const SizedBox(width: 10),
              const Expanded(
                child: LocalizedText(
                  'عدد الضيوف',
                  style: TextStyle(
                    color: _apartmentNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: guests > 1 ? () => setState(() => guests--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              LocalizedText(
                '$guests',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: guests < 8 ? () => setState(() => guests++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xffeaf1ff),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _PriceLine(
                label:
                    '${_apartmentMoney(widget.apartment.pricePerNight)} ريال × $nights ليالٍ',
                value: '${_apartmentMoney(subtotal)} ريال',
              ),
              const SizedBox(height: 8),
              _PriceLine(
                label: 'الإجمالي المبدئي',
                value: '${_apartmentMoney(subtotal)} ريال',
                highlight: true,
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: LocalizedText(
                  'سنكمل بياناتك في الخطوة التالية',
                  style: TextStyle(color: Color(0xff7c88a5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ApartmentPrimaryButton(
          key: const Key('apartment-booking-continue'),
          label: 'متابعة',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApartmentRenterInformationScreen(
                apartment: widget.apartment,
                arrival: arrival,
                departure: departure,
                guests: guests,
                subtotal: subtotal,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ApartmentRenterInformationScreen extends StatefulWidget {
  const ApartmentRenterInformationScreen({
    super.key,
    required this.apartment,
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.subtotal,
  });

  final Apartment apartment;
  final DateTime arrival;
  final DateTime departure;
  final int guests;
  final int subtotal;

  @override
  State<ApartmentRenterInformationScreen> createState() =>
      _ApartmentRenterInformationScreenState();
}

class _ApartmentRenterInformationScreenState
    extends State<ApartmentRenterInformationScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();
  final email = TextEditingController();
  final documentNumber = TextEditingController();
  final notes = TextEditingController();
  String documentType = 'بطاقة شخصية';
  String arrivalTime = '11:00 ظهراً';
  bool _creatingRemoteBooking = false;

  @override
  void initState() {
    super.initState();
    final profile = readApartmentProfile();
    if (profile != null) {
      final profileName = profile.name.trim();
      final profilePhone = profile.phone.trim();

      if (profileName.isNotEmpty) {
        name.text = profileName;
      }
      if (profilePhone.isNotEmpty) {
        phone.text = profilePhone;
        whatsapp.text = profilePhone;
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    whatsapp.dispose();
    email.dispose();
    documentNumber.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_creatingRemoteBooking) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final renter = ApartmentRenterData(
      fullName: name.text.trim(),
      phone: phone.text.trim(),
      whatsapp: whatsapp.text.trim().isEmpty
          ? phone.text.trim()
          : whatsapp.text.trim(),
      email: email.text.trim(),
      documentType: documentType,
      documentNumber: documentNumber.text.trim(),
      arrivalTime: arrivalTime,
      notes: notes.text.trim(),
    );

    setState(() => _creatingRemoteBooking = true);

    try {
      final flow = ProviderBookingFlow.current;
      final service = flow == null
          ? null
          : await flow.catalog.getService(widget.apartment.id);
      final target = service == null
          ? null
          : ApartmentBackendTarget(
              providerId: service.providerId,
              serviceId: service.id,
              currency: service.currency,
            );

      if (target == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(
              'خدمة الشقق غير مربوطة بكتالوج Laravel لهذه المحافظة.',
            ),
          ),
        );
        return;
      }

      const serviceFee = 0;
      const tax = 0;
      final total = widget.subtotal + serviceFee + tax;
      final nights = widget.departure
          .difference(widget.arrival)
          .inDays
          .clamp(1, 30);

      if (!mounted || flow == null || service == null) return;
      final choice = await selectProviderAvailability(
        context,
        flow,
        service,
        quantity: flow.quantityFor(service, nights),
        scheduledAt: widget.arrival,
      );
      if (choice.cancelled || !mounted) return;
      final booking = await createApartmentBackendBooking(
        ApartmentBackendBookingRequest(
          target: target,
          serviceAvailabilityId: choice.id,
          quantity: flow.quantityFor(service, nights),
          total: total,
          scheduledAt: widget.arrival,
          metadata: {
            'source': 'flutter_provider_booking',
            'module': 'apartments',
            'apartment_id': widget.apartment.id,
            'apartment_name': widget.apartment.name,
            'city': widget.apartment.city,
            'neighborhood': widget.apartment.neighborhood,
            'price_per_night': widget.apartment.pricePerNight,
            'arrival': widget.arrival.toIso8601String(),
            'departure': widget.departure.toIso8601String(),
            'nights': nights,
            'guests': widget.guests,
            'service_fee': serviceFee,
            'tax': tax,
            'renter': {
              'full_name': renter.fullName,
              'phone': renter.phone,
              'whatsapp': renter.whatsapp,
              'email': renter.email,
              'document_type': renter.documentType,
              'document_number': renter.documentNumber,
              'arrival_time': renter.arrivalTime,
              'notes': renter.notes,
            },
          },
        ),
      );

      if (!mounted) return;

      if (booking == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText('تعذر إنشاء طلب الحجز في Laravel.'),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApartmentPaymentScreen(
            apartment: widget.apartment,
            arrival: widget.arrival,
            departure: widget.departure,
            guests: widget.guests,
            subtotal: widget.subtotal,
            renter: renter,
            bookingId: booking.id,
          ),
        ),
      );
    } on Object {
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
  Widget build(BuildContext context) => ApartmentBookingScaffold(
    step: 2,
    title: 'بيانات المستأجر',
    subtitle: 'أكمل بياناتك كما تظهر في وثيقتك',
    child: Form(
      key: formKey,
      child: ListView(
        key: const Key('apartment-renter-list'),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          _ApartmentTextField(
            key: const Key('renter-name'),
            controller: name,
            label: 'الاسم الرباعي حسب الوثيقة الشخصية',
            hint: 'أدخل الاسم الرباعي كاملاً',
            icon: Icons.person_outline_rounded,
            validator: (value) => (value?.trim().length ?? 0) < 4
                ? 'يرجى إدخال الاسم الكامل'
                : null,
          ),
          _ApartmentTextField(
            key: const Key('renter-phone'),
            controller: phone,
            label: 'رقم الهاتف',
            hint: '967 7XX XXX XXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) => (value?.trim().length ?? 0) < 7
                ? 'يرجى إدخال رقم هاتف صحيح'
                : null,
          ),
          _ApartmentTextField(
            controller: whatsapp,
            label: 'رقم الواتساب',
            hint: 'اتركه فارغاً لاستخدام رقم الهاتف',
            icon: Icons.chat_outlined,
            keyboardType: TextInputType.phone,
          ),
          _ApartmentTextField(
            controller: email,
            label: 'البريد الإلكتروني (اختياري)',
            hint: 'name@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 6),
          const _ApartmentHeading('الوثيقة التعريفية'),
          const SizedBox(height: 9),
          Row(
            key: const Key('apartment-document-types'),
            children: ['بطاقة شخصية', 'جواز سفر', 'بطاقة عائلية', 'أخرى']
                .map(
                  (type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 5),
                      child: ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: LocalizedText(
                              l10n(type),
                              maxLines: 1,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        selected: documentType == type,
                        showCheckmark: false,
                        selectedColor: const Color(0xffe7efff),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        labelStyle: TextStyle(
                          color: documentType == type
                              ? _apartmentBlue
                              : _apartmentNavy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => documentType = type),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          _ApartmentTextField(
            key: const Key('renter-id'),
            controller: documentNumber,
            label: 'رقم الوثيقة التعريفية',
            hint: 'أدخل رقم الوثيقة',
            icon: Icons.badge_outlined,
            validator: (value) => (value?.trim().length ?? 0) < 4
                ? 'يرجى إدخال رقم الوثيقة'
                : null,
          ),
          const LocalizedText(
            'وقت الوصول التقريبي',
            style: TextStyle(
              color: _apartmentNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: arrivalTime,
            decoration: _fieldDecoration(Icons.access_time_outlined, null),
            items: ['11:00 ظهراً', '01:00 ظهراً', '03:00 عصراً', '06:00 مساءً']
                .map(
                  (time) =>
                      DropdownMenuItem(value: time, child: LocalizedText(time)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => arrivalTime = value ?? arrivalTime),
          ),
          const SizedBox(height: 15),
          _ApartmentTextField(
            controller: notes,
            label: 'ملاحظات خاصة (اختياري)',
            hint: 'أخبرنا بأي ملاحظات أو متطلبات خاصة...',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 17),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xffeaf1ff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: _apartmentBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'نحن نضمن حماية بياناتك الشخصية',
                        style: TextStyle(
                          color: _apartmentBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      LocalizedText(
                        'لن تتم مشاركة معلوماتك مع أي جهة خارجية',
                        style: TextStyle(color: Color(0xff7d89a7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _ApartmentPrimaryButton(
                  key: const Key('renter-continue'),
                  label: 'متابعة الدفع',
                  onPressed: _continue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                  ),
                  child: const LocalizedText('رجوع'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class ApartmentRenterData {
  const ApartmentRenterData({
    required this.fullName,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.documentType,
    required this.documentNumber,
    required this.arrivalTime,
    required this.notes,
  });

  final String fullName;
  final String phone;
  final String whatsapp;
  final String email;
  final String documentType;
  final String documentNumber;
  final String arrivalTime;
  final String notes;
}

class ApartmentPaymentWallet {
  const ApartmentPaymentWallet({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final bool enabled;
}

const apartmentPaymentWallets = <ApartmentPaymentWallet>[
  ApartmentPaymentWallet(
    id: 'one-cash',
    name: 'محفظة ون كاش',
    subtitle: 'محفظة إلكترونية',
    icon: Icons.account_balance_wallet_rounded,
  ),
  ApartmentPaymentWallet(
    id: 'jawali',
    name: 'جوالي',
    subtitle: 'محفظة إلكترونية',
    icon: Icons.phone_android_rounded,
  ),
  ApartmentPaymentWallet(
    id: 'jeeb',
    name: 'جيب',
    subtitle: 'محفظة إلكترونية',
    icon: Icons.wallet_rounded,
  ),
  ApartmentPaymentWallet(
    id: 'floosk',
    name: 'فلوسك',
    subtitle: 'محفظة إلكترونية',
    icon: Icons.account_balance_rounded,
  ),
  ApartmentPaymentWallet(
    id: 'yemen-wallet',
    name: 'يمن والت',
    subtitle: 'محفظة إلكترونية',
    icon: Icons.payment_rounded,
  ),
  ApartmentPaymentWallet(
    id: 'rial-mobile',
    name: 'ريال موبايل',
    subtitle: 'محفظة إلكترونية',
    icon: Icons.smartphone_rounded,
  ),
];

class ApartmentPaymentScreen extends StatefulWidget {
  const ApartmentPaymentScreen({
    super.key,
    required this.apartment,
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.subtotal,
    required this.renter,
    required this.bookingId,
    this.wallets = apartmentPaymentWallets,
  });

  final Apartment apartment;
  final DateTime arrival;
  final DateTime departure;
  final int guests;
  final int subtotal;
  final ApartmentRenterData renter;
  final String bookingId;
  final List<ApartmentPaymentWallet> wallets;

  @override
  State<ApartmentPaymentScreen> createState() => _ApartmentPaymentScreenState();
}

class _ApartmentPaymentScreenState extends State<ApartmentPaymentScreen> {
  late String paymentMethod;
  bool _submittingRemotePayment = false;

  int get serviceFee =>
      ProviderBookingFlow.current == null ? (widget.subtotal * .05).round() : 0;
  int get tax =>
      ProviderBookingFlow.current == null ? (widget.subtotal * .15).round() : 0;
  int get total => widget.subtotal + serviceFee + tax;

  List<ApartmentPaymentWallet> get methods =>
      widget.wallets.where((wallet) => wallet.enabled).toList();

  @override
  void initState() {
    super.initState();
    paymentMethod = methods.isEmpty ? '' : methods.first.name;
  }

  Future<void> _submitRemotePayment() async {
    if (_submittingRemotePayment) return;

    if (methods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('لا توجد وسيلة دفع متاحة حاليًا.'),
        ),
      );
      return;
    }

    final selectedMethod = methods.firstWhere(
      (method) => method.name == paymentMethod,
      orElse: () => methods.first,
    );

    setState(() => _submittingRemotePayment = true);

    try {
      final result = await executeApartmentBackendPayment(
        widget.bookingId,
        selectedMethod.id,
      );

      if (!mounted) return;

      if (result.isPaid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ApartmentBookingSuccessScreen(
              apartment: widget.apartment,
              arrival: widget.arrival,
              departure: widget.departure,
              guests: widget.guests,
              subtotal: widget.subtotal,
              serviceFee: serviceFee,
              tax: tax,
              total: total,
              renter: widget.renter,
              paymentMethod: paymentMethod,
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
  Widget build(BuildContext context) => ApartmentBookingScaffold(
    step: 3,
    title: 'أكمل الدفع',
    subtitle: 'بياناتك محمية ومعاملاتك آمنة',
    child: ListView(
      key: const Key('apartment-payment-list'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        _ApartmentSummary(apartment: widget.apartment),
        const SizedBox(height: 20),
        const _ApartmentHeading('تفاصيل السعر'),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: _apartmentCard(),
          child: Column(
            children: [
              _PriceLine(
                label: 'سعر الإقامة',
                value: '${_apartmentMoney(widget.subtotal)} ريال',
              ),
              const Divider(),
              _PriceLine(
                label: 'رسوم الخدمة',
                value: '${_apartmentMoney(serviceFee)} ريال',
              ),
              const Divider(),
              _PriceLine(
                label: 'الضريبة',
                value: '${_apartmentMoney(tax)} ريال',
              ),
              const Divider(),
              _PriceLine(
                label: 'الإجمالي الكلي',
                value: '${_apartmentMoney(total)} ريال يمني',
                highlight: true,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffeafff3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.event_available_rounded, color: _apartmentGreen),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'إلغاء مجاني',
                      style: TextStyle(
                        color: _apartmentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      'يمكنك إلغاء الحجز مجاناً خلال 24 ساعة من وقت الحجز',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _ApartmentHeading('اختر طريقة الدفع'),
        const SizedBox(height: 9),
        ...methods.map(
          (method) => InkWell(
            key: Key('apartment-wallet-${method.id}'),
            onTap: () => setState(() => paymentMethod = method.name),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: paymentMethod == method.name
                      ? _apartmentBlue
                      : const Color(0xffdce2ef),
                  width: paymentMethod == method.name ? 1.7 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    paymentMethod == method.name
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: paymentMethod == method.name
                        ? _apartmentBlue
                        : const Color(0xff8c97af),
                  ),
                  const SizedBox(width: 10),
                  Icon(method.icon, color: _apartmentBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LocalizedText(
                      l10n(method.name),
                      style: const TextStyle(
                        color: _apartmentNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  LocalizedText(
                    l10n(method.subtitle),
                    style: const TextStyle(color: Color(0xff8a95ad)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffeaf1ff),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: _apartmentBlue),
              SizedBox(width: 8),
              Flexible(
                child: LocalizedText(
                  'نلتزم بأعلى معايير الأمان • جميع معاملاتك مشفرة وآمنة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _apartmentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ApartmentPrimaryButton(
          key: const Key('apartment-pay-button'),
          label: 'إتمام الدفع • ${_apartmentMoney(total)} ريال',
          onPressed: _submitRemotePayment,
        ),
      ],
    ),
  );
}

class ApartmentBookingSuccessScreen extends StatelessWidget {
  const ApartmentBookingSuccessScreen({
    super.key,
    required this.apartment,
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.subtotal,
    required this.serviceFee,
    required this.tax,
    required this.total,
    required this.renter,
    required this.paymentMethod,
    required this.bookingNumber,
  });
  final Apartment apartment;
  final DateTime arrival;
  final DateTime departure;
  final int guests;
  final int subtotal;
  final int serviceFee;
  final int tax;
  final int total;
  final ApartmentRenterData renter;
  final String paymentMethod;
  final String bookingNumber;

  @override
  Widget build(BuildContext context) => ApartmentBookingScaffold(
    step: 4,
    title: 'تم الحجز بنجاح',
    subtitle: 'استعد لإقامة مريحة ومميزة',
    child: ListView(
      key: const Key('apartment-success-list'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_apartmentDarkBlue, _apartmentBlue],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.check_rounded,
                  size: 50,
                  color: _apartmentGreen,
                ),
              ),
              SizedBox(height: 13),
              LocalizedText(
                'تم تأكيد حجزك بنجاح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                'أرسلنا تفاصيل الحجز إلى رقم الواتساب المسجل',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ApartmentSummary(apartment: apartment),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: _apartmentCard(),
          child: Column(
            children: [
              _InvoiceValue('رقم الحجز', bookingNumber),
              _InvoiceValue('تاريخ الوصول', _apartmentDate(arrival)),
              _InvoiceValue('تاريخ المغادرة', _apartmentDate(departure)),
              _InvoiceValue('عدد الضيوف', '$guests ضيف'),
              _InvoiceValue('طريقة الدفع', paymentMethod),
              const _InvoiceValue('حالة الحجز', 'مؤكد', success: true),
              _InvoiceValue('الإجمالي', '${_apartmentMoney(total)} ريال'),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _ApartmentPrimaryButton(
          key: const Key('apartment-show-invoice'),
          label: 'عرض تفاصيل الحجز والفاتورة',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApartmentInvoiceScreen(
                apartment: apartment,
                arrival: arrival,
                departure: departure,
                guests: guests,
                subtotal: subtotal,
                serviceFee: serviceFee,
                tax: tax,
                total: total,
                renter: renter,
                paymentMethod: paymentMethod,
                bookingNumber: bookingNumber,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
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

class ApartmentInvoiceScreen extends StatelessWidget {
  const ApartmentInvoiceScreen({
    super.key,
    required this.apartment,
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.subtotal,
    required this.serviceFee,
    required this.tax,
    required this.total,
    required this.renter,
    required this.paymentMethod,
    required this.bookingNumber,
  });

  final Apartment apartment;
  final DateTime arrival;
  final DateTime departure;
  final int guests;
  final int subtotal;
  final int serviceFee;
  final int tax;
  final int total;
  final ApartmentRenterData renter;
  final String paymentMethod;
  final String bookingNumber;

  int get nights => departure.difference(arrival).inDays.clamp(1, 30);

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _apartmentSurface,
      appBar: AppBar(
        backgroundColor: _apartmentSurface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              'تفاصيل الحجز',
              style: TextStyle(
                color: _apartmentNavy,
                fontWeight: FontWeight.w900,
              ),
            ),
            LocalizedText(
              'كل معلومات الحجز في مكان واحد',
              style: TextStyle(color: Color(0xff8791a9), fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('apartment-invoice-list'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            _ApartmentSummary(apartment: apartment),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: _ApartmentPill(
                    text: 'مؤكد',
                    icon: Icons.verified_rounded,
                    color: _apartmentGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LocalizedText(
                    'رقم الحجز ${bookingNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _apartmentNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffeaf1ff),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const LocalizedText(
                'تم إرسال تفاصيل الحجز إلى رقم الواتساب المسجل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _apartmentBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const _ApartmentHeading('ملخص الحجز'),
            const SizedBox(height: 9),
            _InvoiceGrid(
              entries: [
                ('تاريخ الدخول', _apartmentDate(arrival)),
                ('نوع الإقامة', 'شقة مفروشة'),
                ('مدة الإقامة', '$nights ليالٍ'),
                ('وقت الدخول', renter.arrivalTime),
                ('المغادرة', '12:00 ظهراً'),
                ('عدد السكان', '$guests ضيف'),
              ],
            ),
            const SizedBox(height: 20),
            const _ApartmentHeading('بيانات المستأجر'),
            const SizedBox(height: 9),
            _InvoiceGrid(
              entries: [
                ('الاسم الرباعي', renter.fullName),
                ('رقم الهاتف', renter.phone),
                ('الواتساب', renter.whatsapp),
                ('البريد', renter.email.isEmpty ? 'غير مسجل' : renter.email),
                ('نوع الوثيقة', renter.documentType),
                ('رقم الوثيقة', renter.documentNumber),
              ],
            ),
            const SizedBox(height: 20),
            const _ApartmentHeading(
              'تفاصيل الدفع',
              key: Key('apartment-invoice-payment-heading'),
            ),
            const SizedBox(height: 9),
            _InvoiceGrid(
              entries: [
                ('طريقة الدفع', paymentMethod),
                ('سعر الإقامة', '${_apartmentMoney(subtotal)} ريال'),
                ('الرسوم', '${_apartmentMoney(serviceFee)} ريال'),
                ('الضريبة', '${_apartmentMoney(tax)} ريال'),
                ('الإجمالي', '${_apartmentMoney(total)} ريال'),
                ('حالة الدفع', 'تم الدفع بنجاح'),
              ],
              successLast: true,
            ),
            const SizedBox(height: 20),
            const _ApartmentHeading('الموقع'),
            const SizedBox(height: 9),
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xffedf3fb),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffd8e1ef)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _ApartmentMapPainter()),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    color: _apartmentBlue,
                    size: 48,
                  ),
                  Positioned(
                    right: 13,
                    bottom: 8,
                    child: LocalizedText(
                      'شارع الستين • ${apartment.city}',
                      style: const TextStyle(
                        color: _apartmentNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: _apartmentCard(),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'الفاتورة والتحقق',
                          style: TextStyle(
                            color: _apartmentNavy,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        LocalizedText('رمز التحقق'),
                        LocalizedText(
                          'APT20458',
                          key: Key('apartment-invoice-code'),
                          style: TextStyle(
                            color: _apartmentBlue,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LocalizedText('استخدم الرمز للتحقق من صحة الحجز'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
                  _QrPattern(),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ServiceCompletionFooter(
              serviceKey: 'شقق مفروشة',
              serviceName: 'شقق مفروشة',
              invoiceTitle: 'فاتورة حجز ${apartment.name}',
              invoiceReference: bookingNumber,
              invoiceStatus: 'تم الدفع بنجاح',
              invoiceDetails: [
                ('الشقة', apartment.name),
                ('الموقع', '${apartment.neighborhood} • ${apartment.city}'),
                ('حالة الحجز', 'مؤكد'),
                ('رقم الحجز', bookingNumber),
                ('تاريخ الدخول', _apartmentDate(arrival)),
                ('نوع الإقامة', 'شقة مفروشة'),
                ('مدة الإقامة', '$nights ليالٍ'),
                ('وقت الدخول', renter.arrivalTime),
                ('المغادرة', '12:00 ظهراً'),
                ('عدد السكان', '$guests ضيف'),
                ('الاسم الرباعي', renter.fullName),
                ('رقم الهاتف', renter.phone),
                ('الواتساب', renter.whatsapp),
                ('البريد', renter.email.isEmpty ? 'غير مسجل' : renter.email),
                ('نوع الوثيقة', renter.documentType),
                ('رقم الوثيقة', renter.documentNumber),
                ('طريقة الدفع', paymentMethod),
                ('سعر الإقامة', '${_apartmentMoney(subtotal)} ريال'),
                ('الرسوم', '${_apartmentMoney(serviceFee)} ريال'),
                ('الضريبة', '${_apartmentMoney(tax)} ريال'),
                ('الإجمالي', '${_apartmentMoney(total)} ريال'),
                ('حالة الدفع', 'تم الدفع بنجاح'),
                ('عنوان الموقع', 'شارع الستين • ${apartment.city}'),
                ('رمز التحقق', 'APT20458'),
              ],
              invoiceText:
                  'فاتورة ${apartment.name}\nرقم الحجز: ${bookingNumber}\nالإجمالي: ${_apartmentMoney(total)} ريال',
            ),
          ],
        ),
      ),
    ),
  );
}

class ApartmentBookingScaffold extends StatelessWidget {
  const ApartmentBookingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int step;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _apartmentSurface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 21),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [_apartmentDarkBlue, _apartmentBlue],
                ),
              ),
              child: Row(
                children: [
                  _RoundAction(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          l10n(title),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        LocalizedText(
                          l10n(subtitle),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo_transparent.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            _ApartmentBookingProgress(step: step),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _ApartmentBookingProgress extends StatelessWidget {
  const _ApartmentBookingProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['تفاصيل الحجز', 'بياناتك', 'الدفع', 'تأكيد الحجز'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          final number = index + 1;
          final complete = number < step;
          final active = number == step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: complete
                              ? _apartmentGreen
                              : active
                              ? _apartmentBlue
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: complete
                                ? _apartmentGreen
                                : active
                                ? _apartmentBlue
                                : const Color(0xffd7deec),
                          ),
                        ),
                        child: Center(
                          child: complete
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : LocalizedText(
                                  '$number',
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : const Color(0xff8a95ad),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      LocalizedText(
                        l10n(labels[index]),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          color: complete
                              ? _apartmentGreen
                              : active
                              ? _apartmentBlue
                              : const Color(0xff8893aa),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < labels.length - 1)
                  Container(
                    width: 15,
                    height: 2,
                    color: number < step
                        ? _apartmentGreen
                        : const Color(0xffdce2ee),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ApartmentSummary extends StatelessWidget {
  const _ApartmentSummary({required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: _apartmentCard(),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            apartmentImageAsset,
            width: 105,
            height: 85,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                l10n(apartment.name),
                style: const TextStyle(
                  color: _apartmentNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                '${l10n(apartment.neighborhood)} • ${l10n(apartment.city)}',
                style: const TextStyle(color: Color(0xff7d88a3)),
              ),
              LocalizedText(
                '★ ${apartment.rating} ${l10n('ممتاز', 'Excellent')} • ${apartment.reviews} ${l10n('تقييم', 'reviews')}',
                style: const TextStyle(
                  color: _apartmentOrange,
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

class _ApartmentTextField extends StatelessWidget {
  const _ApartmentTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          l10n(label),
          style: const TextStyle(
            color: _apartmentNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: _fieldDecoration(icon, l10n(hint)),
        ),
      ],
    ),
  );
}

InputDecoration _fieldDecoration(IconData icon, String? hint) =>
    InputDecoration(
      hintText: hint == null ? null : l10n(hint),
      prefixIcon: Icon(icon, color: _apartmentBlue),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffdbe2ef)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffdbe2ef)),
      ),
    );

class _BookingValueTile extends StatelessWidget {
  const _BookingValueTile({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: _apartmentCard(),
      child: Row(
        children: [
          Icon(icon, color: _apartmentBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  l10n(title),
                  style: const TextStyle(color: Color(0xff8792aa)),
                ),
                LocalizedText(
                  l10n(value),
                  style: const TextStyle(
                    color: _apartmentNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.edit_calendar_outlined, color: _apartmentBlue),
        ],
      ),
    ),
  );
}

class _ApartmentBookingBar extends StatelessWidget {
  const _ApartmentBookingBar({required this.apartment, required this.onBook});

  final Apartment apartment;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
      child: Row(
        children: [
          Expanded(
            child: _ApartmentPrimaryButton(
              key: const Key('apartment-book-now-button'),
              label: 'احجز الآن',
              onPressed: onBook,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalizedText(
                '${_apartmentMoney(apartment.pricePerNight)} ريال',
                style: const TextStyle(
                  color: _apartmentNavy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                l10n('لليلة'),
                style: const TextStyle(color: Color(0xff8792a8)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ApartmentPrimaryButton extends StatelessWidget {
  const _ApartmentPrimaryButton({
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
      backgroundColor: _apartmentBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    ),
    child: LocalizedText(l10n(label)),
  );
}

class _ApartmentFeatureGrid extends StatelessWidget {
  const _ApartmentFeatureGrid({required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.weekend_outlined, 'صالة'),
      (Icons.bathtub_outlined, '${apartment.bathrooms} حمام'),
      (Icons.bed_outlined, '${apartment.bedrooms} غرف نوم'),
      (Icons.local_parking_outlined, 'موقف خاص'),
      (Icons.wifi_rounded, 'واي فاي مجاني'),
      (Icons.kitchen_outlined, 'مطبخ مجهز'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.15,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _apartmentSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffe0e6f1)),
        ),
        child: Row(
          children: [
            Icon(items[index].$1, color: _apartmentBlue, size: 20),
            const SizedBox(width: 5),
            Expanded(
              child: LocalizedText(
                l10n(items[index].$2),
                maxLines: 1,
                style: const TextStyle(
                  color: _apartmentNavy,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApartmentHeading extends StatelessWidget {
  const _ApartmentHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => LocalizedText(
    l10n(text),
    style: const TextStyle(
      color: _apartmentNavy,
      fontSize: 22,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _ApartmentPill extends StatelessWidget {
  const _ApartmentPill({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        LocalizedText(
          l10n(text),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _ApartmentInfoChip extends StatelessWidget {
  const _ApartmentInfoChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xffeaf1ff),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _apartmentBlue),
        const SizedBox(width: 6),
        LocalizedText(
          l10n(label),
          style: const TextStyle(color: _apartmentNavy),
        ),
      ],
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 2,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: _apartmentBlue),
    ),
  );
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: LocalizedText(
            l10n(label),
            style: TextStyle(
              color: highlight ? _apartmentNavy : const Color(0xff77829e),
              fontWeight: highlight ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
        ),
        LocalizedText(
          l10n(value),
          style: TextStyle(
            color: highlight ? _apartmentBlue : _apartmentNavy,
            fontSize: highlight ? 19 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _InvoiceValue extends StatelessWidget {
  const _InvoiceValue(this.label, this.value, {this.success = false});

  final String label;
  final String value;
  final bool success;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: LocalizedText(
            l10n(label),
            style: const TextStyle(color: Color(0xff7e89a4)),
          ),
        ),
        LocalizedText(
          l10n(value),
          style: TextStyle(
            color: success ? _apartmentGreen : _apartmentNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _InvoiceGrid extends StatelessWidget {
  const _InvoiceGrid({required this.entries, this.successLast = false});

  final List<(String, String)> entries;
  final bool successLast;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 2.25,
      crossAxisSpacing: 9,
      mainAxisSpacing: 9,
    ),
    itemCount: entries.length,
    itemBuilder: (_, index) => Container(
      padding: const EdgeInsets.all(11),
      decoration: _apartmentCard(radius: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LocalizedText(
            l10n(entries[index].$1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff8a95ad), fontSize: 11),
          ),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: LocalizedText(
                l10n(entries[index].$2),
                maxLines: 1,
                style: TextStyle(
                  color: successLast && index == entries.length - 1
                      ? _apartmentGreen
                      : _apartmentNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QrPattern extends StatelessWidget {
  const _QrPattern();

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 104,
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
        final dark = (row * 3 + column * 5 + row * column) % 4 != 0;
        return ColoredBox(color: dark ? _apartmentNavy : Colors.white);
      },
    ),
  );
}

class _ApartmentMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffcad7e9)
      ..strokeWidth = 2;
    for (var y = 25.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 7), paint);
    }
    for (var x = 20.0; x < size.width; x += 65) {
      canvas.drawLine(Offset(x, 0), Offset(x - 30, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _apartmentCard({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xffdfe5f0)),
  boxShadow: const [
    BoxShadow(color: Color(0x0d000000), blurRadius: 8, offset: Offset(0, 3)),
  ],
);

IconData _amenityIcon(String amenity) {
  if (amenity.contains('مطبخ')) return Icons.kitchen_outlined;
  if (amenity.contains('تلفزيون')) return Icons.tv_outlined;
  if (amenity.contains('غسالة')) return Icons.local_laundry_service_outlined;
  if (amenity.contains('تكييف')) return Icons.ac_unit_rounded;
  if (amenity.contains('مصعد')) return Icons.elevator_outlined;
  if (amenity.contains('إنترنت')) return Icons.wifi_rounded;
  if (amenity.contains('مياه')) return Icons.hot_tub_outlined;
  if (amenity.contains('موقف')) return Icons.local_parking_outlined;
  if (amenity.contains('دخول')) return Icons.lock_open_outlined;
  return Icons.cleaning_services_outlined;
}

IconData _utilityIcon(String utility) => switch (utility) {
  'الماء' => Icons.water_drop_outlined,
  'الكهرباء' => Icons.bolt_outlined,
  'المغسلة الخارجية' => Icons.local_laundry_service_outlined,
  'النظافة الداخلية' => Icons.cleaning_services_outlined,
  'الإنترنت' => Icons.wifi_rounded,
  'الغاز' => Icons.local_fire_department_outlined,
  _ => Icons.check_circle_outline_rounded,
};
