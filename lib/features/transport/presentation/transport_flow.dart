import '../../bookings/presentation/provider_booking_flow.dart';
import 'package:flutter/material.dart';
import '../../auth/presentation/booking_auth_gate.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/reviews/service_review.dart';
import '../domain/transport_models.dart';
import 'car_rental_flow.dart';
import 'freight_flow.dart';
import 'land_transport_flow.dart';

const transportBannerAsset = carRentalMasterBanner;
const transportImageAsset =
    'assets/Services images/تأجير السيارات والنقل الداخلي.jpg';

const _transportBlue = Color(0xff155fc5);
const _transportDark = Color(0xff253247);
const _transportGold = Color(0xffbc8638);
const _transportGreen = Color(0xff11aa63);
const _transportOrange = Color(0xffff9800);
const _transportSurface = Color(0xfffffaf3);

String _transportMoney(int value) => formatMoney(value);

String _transportDate(DateTime value) =>
    '${value.day}/${value.month}/${value.year}';

class TransportDiscoveryScreen extends StatefulWidget {
  const TransportDiscoveryScreen({super.key, required this.province});

  final String province;

  @override
  State<TransportDiscoveryScreen> createState() =>
      _TransportDiscoveryScreenState();
}

class _TransportDiscoveryScreenState extends State<TransportDiscoveryScreen> {
  TransportCategory? searchCategory;

  void _openCategory(TransportCategory category) {
    final screen = switch (category) {
      TransportCategory.carRental => CarRentalCompaniesScreen(
        province: widget.province,
      ),
      TransportCategory.passengerTransport => LandTransportHomeScreen(
        province: widget.province,
      ),
      TransportCategory.freight => FreightHomeScreen(province: widget.province),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _transportSurface,
      body: SafeArea(
        child: ListView(
          key: const Key('transport-discovery-list'),
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _TransportLandingHeader(
              province: widget.province,
              onBack: () => Navigator.pop(context),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(15, 13, 15, 18),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: _transportCard(radius: 18),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TransportCategory>(
                  key: const Key('transport-search-dropdown'),
                  value: searchCategory,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _transportBlue,
                  ),
                  hint: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: _transportBlue),
                      SizedBox(width: 10),
                      LocalizedText(
                        'عن ماذا تبحث؟',
                        style: TextStyle(
                          color: _transportDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TransportCategory.carRental,
                      child: LocalizedText('مكاتب تأجير السيارات'),
                    ),
                    DropdownMenuItem(
                      value: TransportCategory.passengerTransport,
                      child: LocalizedText('شركات ومكاتب النقل البري'),
                    ),
                    DropdownMenuItem(
                      value: TransportCategory.freight,
                      child: LocalizedText('شركات ومكاتب الشحن الداخلي'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => searchCategory = value);
                    _openCategory(value);
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 11),
              child: _TransportHeading('اختر خدمتك'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: TransportCategory.values
                    .map(
                      (category) => Expanded(
                        child: _TransportCategoryCard(
                          key: Key('transport-category-${category.name}'),
                          category: category,
                          selected: false,
                          onTap: () => _openCategory(category),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: _TransportHeading('خدمات أقرب إلى احتياجك'),
            ),
            const SizedBox(height: 10),
            _TransportPromotions(onOpen: _openCategory),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: _TransportHeading('العروض المميزة'),
            ),
            const SizedBox(height: 10),
            _TransportFeaturedOffers(onOpen: _openCategory),
          ],
        ),
      ),
    ),
  );
}

class _TransportLandingHeader extends StatelessWidget {
  const _TransportLandingHeader({required this.province, required this.onBack});

  final String province;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Row(
          children: [
            _TransportRoundButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocalizedText(
                    'تأجير السيارات والنقل البري والشحن الداخلي',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _transportDark,
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: _transportGold,
                      ),
                      const SizedBox(width: 3),
                      LocalizedText(
                        province,
                        style: const TextStyle(
                          color: Color(0xff667085),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _TransportRoundButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {},
            ),
          ],
        ),
      ),
      Container(
        height: 215,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220B2C57),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              carRentalMasterBanner,
              key: const Key('transport-main-banner'),
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    ],
  );
}

class _TransportPromotions extends StatelessWidget {
  const _TransportPromotions({required this.onOpen});

  final ValueChanged<TransportCategory> onOpen;

  static const items = [
    (
      TransportCategory.carRental,
      'سيارتك المناسبة أقرب إليك',
      'استعرض مكاتب التأجير وقارن السيارات والأسعار واحجز بسهولة.',
      Icons.directions_car_filled_rounded,
      Color(0xff155fc5),
    ),
    (
      TransportCategory.passengerTransport,
      'سافر براحة إلى وجهتك',
      'احجز الحافلات والباصات والسيارات الخاصة من أفضل شركات النقل.',
      Icons.directions_bus_filled_rounded,
      Color(0xff7447d9),
    ),
    (
      TransportCategory.freight,
      'شحن أسهل.. من الباب إلى الباب',
      'حلول متكاملة للشحن الداخلي مع متابعة مستمرة لشحنتك.',
      Icons.local_shipping_rounded,
      Color(0xff0d8b62),
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
        child: InkWell(
          onTap: () => onOpen(item.$1),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 166,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(transportImageAsset, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [item.$5.withValues(alpha: .94), Colors.black12],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              item.$2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                height: 1.25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            LocalizedText(
                              item.$3,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 55,
                        height: 55,
                        decoration: const BoxDecoration(
                          color: Color(0xddffffff),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.$4, color: item.$5, size: 30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _TransportFeaturedOffers extends StatelessWidget {
  const _TransportFeaturedOffers({required this.onOpen});

  final ValueChanged<TransportCategory> onOpen;

  static const offers = [
    (
      TransportCategory.carRental,
      'خصم 20%',
      'تأجير سيارة',
      'المدينة للتأجير',
      28000,
      22000,
      '3 أيام',
    ),
    (
      TransportCategory.passengerTransport,
      'خصم 15%',
      'رحلة VIP',
      'حجوزاتكم للنقل',
      21000,
      18000,
      '48 ساعة',
    ),
    (
      TransportCategory.freight,
      'خصم 25%',
      'شحن داخلي',
      'الأمان للشحن',
      40000,
      30000,
      'هذا الأسبوع',
    ),
    (
      TransportCategory.carRental,
      'خصم 12%',
      'سيارة عائلية',
      'إيلاف للتأجير',
      35000,
      30800,
      '5 أيام',
    ),
    (
      TransportCategory.passengerTransport,
      'خصم 10%',
      'رحلة مميزة',
      'الرواد للنقل',
      18000,
      16200,
      '72 ساعة',
    ),
    (
      TransportCategory.freight,
      'خصم 18%',
      'نقل أثاث',
      'الموثوق للشحن',
      52000,
      42600,
      '4 أيام',
    ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .72,
      ),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return InkWell(
          onTap: () => onOpen(offer.$1),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: _transportCard(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(transportImageAsset, fit: BoxFit.cover),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffe53935),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: LocalizedText(
                            offer.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        offer.$3,
                        style: const TextStyle(
                          color: _transportDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      LocalizedText(
                        offer.$4,
                        style: const TextStyle(
                          color: Color(0xff667085),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: LocalizedText(
                                '${_transportMoney(offer.$5)} ر.ي',
                                style: const TextStyle(
                                  color: Color(0xff98a2b3),
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            flex: 4,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: LocalizedText(
                                '${_transportMoney(offer.$6)} ر.ي',
                                style: const TextStyle(
                                  color: _transportBlue,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            flex: 3,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: LocalizedText(
                                offer.$7,
                                style: const TextStyle(
                                  color: _transportGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _TransportCategoryResultsScreen extends StatefulWidget {
  const _TransportCategoryResultsScreen({
    required this.province,
    required this.category,
  });

  final String province;
  final TransportCategory category;

  @override
  State<_TransportCategoryResultsScreen> createState() =>
      _TransportCategoryResultsScreenState();
}

class _TransportCategoryResultsScreenState
    extends State<_TransportCategoryResultsScreen> {
  String query = '';
  String filter = 'الكل';
  final favorites = <String>{};

  List<TransportListing> get results {
    final list = transportListings
        .where(
          (item) =>
              item.category == widget.category &&
              (item.title.contains(query) ||
                  item.provider.contains(query) ||
                  item.city.contains(query)),
        )
        .toList();
    if (filter == 'الأعلى تقييماً') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (filter == 'الأقل سعراً') {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _transportSurface,
      appBar: AppBar(
        backgroundColor: _transportSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: LocalizedText(
          widget.category.label,
          style: const TextStyle(
            color: _transportDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('transport-category-results-list'),
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            Container(
              height: 112,
              margin: const EdgeInsets.fromLTRB(15, 3, 15, 14),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(transportBannerAsset, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xdd0b2c57), Color(0x22155fc5)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _transportCategoryIcon(widget.category),
                          color: Colors.white,
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText(
                                widget.category.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              LocalizedText(
                                '${widget.province} • مزودون موثقون',
                                style: const TextStyle(color: Colors.white),
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: _transportCard(radius: 17),
              child: TextField(
                onChanged: (value) => setState(() => query = value.trim()),
                decoration: InputDecoration(
                  hintText: l10n('ابحث بالاسم أو المدينة'),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _transportBlue,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: ['الكل', 'الأعلى تقييماً', 'الأقل سعراً']
                    .map(
                      (label) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: LocalizedText(label),
                          selected: filter == label,
                          showCheckmark: false,
                          selectedColor: const Color(0xffffecd0),
                          side: BorderSide(
                            color: filter == label
                                ? _transportGold
                                : const Color(0xffe5d8c5),
                          ),
                          onSelected: (_) => setState(() => filter = label),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 18, 15, 10),
              child: _TransportHeading('${widget.category.label} المتاحة'),
            ),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(
                  child: LocalizedText('لا توجد نتائج مطابقة لبحثك'),
                ),
              )
            else
              ...results.map(
                (listing) => _TransportListingCard(
                  key: Key('transport-listing-${listing.id}'),
                  listing: listing,
                  favorite: favorites.contains(listing.id),
                  onFavorite: () => setState(() {
                    favorites.contains(listing.id)
                        ? favorites.remove(listing.id)
                        : favorites.add(listing.id);
                  }),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransportDetailsScreen(listing: listing),
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

class _TransportCategoryCard extends StatelessWidget {
  const _TransportCategoryCard({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TransportCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 126,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffffecd3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _transportGold : const Color(0xffeadfce),
            width: selected ? 1.7 : 1,
          ),
          boxShadow: const [BoxShadow(color: Color(0x0c000000), blurRadius: 7)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _transportCategoryIcon(category),
              color: selected ? _transportGold : _transportBlue,
              size: 34,
            ),
            const SizedBox(height: 6),
            LocalizedText(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: _transportDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TransportListingCard extends StatelessWidget {
  const _TransportListingCard({
    super.key,
    required this.listing,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final TransportListing listing;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(15, 0, 15, 11),
    decoration: _transportCard(radius: 19),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 135,
            height: 165,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(transportImageAsset, fit: BoxFit.cover),
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
                        color: _transportGreen,
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
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LocalizedText(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _transportDark,
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
                          color: favorite ? Colors.redAccent : _transportGold,
                        ),
                      ),
                    ],
                  ),
                  LocalizedText(
                    listing.provider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xff7f796f)),
                  ),
                  LocalizedText(
                    '★ ${listing.rating} ممتاز • ${listing.reviews} تقييم',
                    style: const TextStyle(
                      color: _transportOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LocalizedText(
                    listing.capacity,
                    style: const TextStyle(
                      color: _transportBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LocalizedText(
                    '${_transportMoney(listing.price)} ر.ي / ${listing.priceUnit}',
                    style: const TextStyle(
                      color: _transportGold,
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

class TransportDetailsScreen extends StatelessWidget {
  const TransportDetailsScreen({super.key, required this.listing});

  final TransportListing listing;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _transportSurface,
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
          child: Row(
            children: [
              Expanded(
                child: _TransportPrimaryButton(
                  key: const Key('transport-book-now'),
                  label: _bookLabel(listing.category),
                  onPressed: () => openProtectedBooking(
                    context,
                    nextScreen: TransportBookingScreen(listing: listing),
                    serviceTitle: 'تأجير السيارات والنقل البري والشحن الداخلي',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    '${_transportMoney(listing.price)} ر.ي',
                    style: const TextStyle(
                      color: _transportDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    'لكل ${listing.priceUnit}',
                    style: const TextStyle(color: Color(0xff7e786e)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('transport-detail-list'),
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Image.asset(
                  transportImageAsset,
                  width: double.infinity,
                  height: 310,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: _TransportRoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 14,
                  child: Row(
                    children: [
                      _TransportRoundButton(
                        icon: Icons.share_outlined,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(
                            text:
                                '${listing.title}\n${listing.provider}\n${_transportMoney(listing.price)} ر.ي لكل ${listing.priceUnit}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TransportRoundButton(
                        icon: Icons.favorite_border_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 13,
                  child: _TransportPill(
                    label: listing.category.label,
                    icon: _transportCategoryIcon(listing.category),
                    color: _transportGold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(17, 21, 17, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    listing.title,
                    style: const TextStyle(
                      color: _transportDark,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    '${listing.provider} • ${listing.city}',
                    style: const TextStyle(
                      color: Color(0xff7d776e),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 9,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LocalizedText(
                        '★ ${listing.rating} ممتاز • ${listing.reviews} تقييم',
                        style: const TextStyle(
                          color: _transportOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const _TransportPill(
                        label: 'مزود موثق',
                        icon: Icons.verified_rounded,
                        color: _transportGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _TransportQuickInfo(listing: listing),
                  const SizedBox(height: 23),
                  const _TransportHeading('تفاصيل الخدمة'),
                  const SizedBox(height: 7),
                  LocalizedText(
                    listing.description,
                    style: const TextStyle(
                      color: Color(0xff6f6b64),
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _TransportHeading('المميزات والخدمات'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.15,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: listing.features.length,
                    itemBuilder: (_, index) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _transportSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffeadfce)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: _transportBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: LocalizedText(
                              listing.features[index],
                              style: const TextStyle(
                                color: _transportDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 21),
                  const _TransportHeading('شروط الحجز'),
                  const SizedBox(height: 9),
                  const _TransportCondition(
                    Icons.event_available_rounded,
                    'إلغاء مجاني حتى 24 ساعة قبل الموعد',
                  ),
                  const _TransportCondition(
                    Icons.shield_outlined,
                    'تأمين يغطي الخدمة وفق الشروط الموضحة',
                  ),
                  const _TransportCondition(
                    Icons.support_agent_rounded,
                    'خدمة عملاء متاحة على مدار الساعة',
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

class TransportBookingScreen extends StatefulWidget {
  const TransportBookingScreen({super.key, required this.listing});

  final TransportListing listing;

  @override
  State<TransportBookingScreen> createState() => _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  late final TextEditingController origin;
  late final TextEditingController destination;
  DateTime startDate = DateTime.now().add(const Duration(days: 1));
  DateTime endDate = DateTime.now().add(const Duration(days: 4));
  int passengers = 1;
  double cargoWeight = 1;
  String cargoType = 'أثاث ومفروشات';
  String pickupTime = '09:00 صباحاً';
  bool withDriver = false;
  bool roundTrip = false;
  bool packaging = false;

  TransportCategory get category => widget.listing.category;

  @override
  void initState() {
    super.initState();
    origin = TextEditingController(text: widget.listing.city);
    destination = TextEditingController(
      text: category == TransportCategory.carRental ? widget.listing.city : '',
    );
  }

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    super.dispose();
  }

  int get days => endDate.difference(startDate).inDays.clamp(1, 30);

  int get subtotal => switch (category) {
    TransportCategory.carRental =>
      widget.listing.price * days + (withDriver ? 10000 * days : 0),
    TransportCategory.passengerTransport =>
      widget.listing.price * passengers * (roundTrip ? 2 : 1),
    TransportCategory.freight =>
      widget.listing.price +
          (cargoWeight > 1 ? ((cargoWeight - 1) * 5000).round() : 0) +
          (packaging ? 8000 : 0),
  };

  Future<void> _pickDate(bool isEnd) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isEnd ? endDate : startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      if (isEnd) {
        if (date.isAfter(startDate)) endDate = date;
      } else {
        startDate = date;
        if (!endDate.isAfter(startDate)) {
          endDate = startDate.add(const Duration(days: 1));
        }
      }
    });
  }

  TransportTripData _tripData() => TransportTripData(
    origin: origin.text.trim(),
    destination: destination.text.trim(),
    date: startDate,
    endDate: category == TransportCategory.carRental ? endDate : null,
    time: pickupTime,
    quantity: category == TransportCategory.carRental
        ? '$days أيام'
        : category == TransportCategory.passengerTransport
        ? '$passengers راكب'
        : '${cargoWeight.toStringAsFixed(1)} طن',
    option: category == TransportCategory.carRental
        ? (withDriver ? 'مع سائق' : 'بدون سائق')
        : category == TransportCategory.passengerTransport
        ? (roundTrip ? 'ذهاب وعودة' : 'ذهاب فقط')
        : '$cargoType${packaging ? ' • مع تغليف' : ''}',
  );

  @override
  Widget build(BuildContext context) => TransportBookingFrame(
    step: 2,
    title: 'تفاصيل الحجز',
    child: ListView(
      key: const Key('transport-booking-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _TransportSummary(listing: widget.listing),
        const SizedBox(height: 18),
        _TransportHeading(_bookingSectionTitle(category)),
        const SizedBox(height: 9),
        _TransportInput(
          controller: origin,
          label: _originLabel(category),
          icon: Icons.my_location_rounded,
        ),
        if (category != TransportCategory.carRental)
          _TransportInput(
            controller: destination,
            label: 'الوجهة أو موقع التسليم',
            icon: Icons.location_on_outlined,
          ),
        Row(
          children: [
            Expanded(
              child: _TransportDateTile(
                label: category == TransportCategory.carRental
                    ? 'تاريخ الاستلام'
                    : 'تاريخ الخدمة',
                value: _transportDate(startDate),
                onTap: () => _pickDate(false),
              ),
            ),
            if (category == TransportCategory.carRental) ...[
              const SizedBox(width: 9),
              Expanded(
                child: _TransportDateTile(
                  label: 'تاريخ الإعادة',
                  value: _transportDate(endDate),
                  onTap: () => _pickDate(true),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: pickupTime,
          decoration: _transportInputDecoration(
            Icons.access_time_rounded,
            'وقت الخدمة',
          ),
          items: ['09:00 صباحاً', '11:00 صباحاً', '02:00 ظهراً', '05:00 مساءً']
              .map(
                (time) =>
                    DropdownMenuItem(value: time, child: LocalizedText(time)),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => pickupTime = value ?? pickupTime),
        ),
        const SizedBox(height: 13),
        if (category == TransportCategory.carRental)
          _TransportOptionSwitch(
            key: const Key('transport-driver-option'),
            title: 'إضافة سائق محترف',
            subtitle: '10,000 ر.ي لكل يوم',
            value: withDriver,
            onChanged: (value) => setState(() => withDriver = value),
          ),
        if (category == TransportCategory.passengerTransport) ...[
          _TransportCounter(
            key: const Key('transport-passenger-count'),
            title: 'عدد الركاب',
            value: passengers,
            onMinus: passengers > 1 ? () => setState(() => passengers--) : null,
            onPlus: passengers < 10 ? () => setState(() => passengers++) : null,
          ),
          _TransportOptionSwitch(
            title: 'حجز رحلة ذهاب وعودة',
            subtitle: 'يشمل نفس عدد الركاب',
            value: roundTrip,
            onChanged: (value) => setState(() => roundTrip = value),
          ),
        ],
        if (category == TransportCategory.freight) ...[
          DropdownButtonFormField<String>(
            key: const Key('transport-cargo-type'),
            initialValue: cargoType,
            decoration: _transportInputDecoration(
              Icons.inventory_2_outlined,
              'نوع الشحنة',
            ),
            items:
                ['أثاث ومفروشات', 'مواد غذائية', 'أجهزة ومعدات', 'بضائع عامة']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: LocalizedText(type),
                      ),
                    )
                    .toList(),
            onChanged: (value) =>
                setState(() => cargoType = value ?? cargoType),
          ),
          const SizedBox(height: 13),
          Container(
            key: const Key('transport-cargo-weight'),
            padding: const EdgeInsets.all(14),
            decoration: _transportCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'الوزن التقريبي: ${cargoWeight.toStringAsFixed(1)} طن',
                  style: const TextStyle(
                    color: _transportDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: cargoWeight,
                  min: .5,
                  max: 8,
                  divisions: 15,
                  activeColor: _transportGold,
                  label: '${cargoWeight.toStringAsFixed(1)} طن',
                  onChanged: (value) => setState(() => cargoWeight = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _TransportOptionSwitch(
            title: 'خدمة تغليف احترافية',
            subtitle: 'حماية إضافية للشحنة',
            value: packaging,
            onChanged: (value) => setState(() => packaging = value),
          ),
        ],
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffffeed7),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            children: [
              _TransportInvoiceLine('نوع الخدمة', category.label),
              _TransportInvoiceLine('الكمية', _tripData().quantity),
              _TransportInvoiceLine(
                'الإجمالي المبدئي',
                '${_transportMoney(subtotal)} ر.ي',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _TransportPrimaryButton(
          key: const Key('transport-booking-continue'),
          label: 'متابعة إلى بيانات العميل',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransportCustomerScreen(
                listing: widget.listing,
                trip: _tripData(),
                subtotal: subtotal,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class TransportTripData {
  const TransportTripData({
    required this.origin,
    required this.destination,
    required this.date,
    required this.endDate,
    required this.time,
    required this.quantity,
    required this.option,
  });

  final String origin;
  final String destination;
  final DateTime date;
  final DateTime? endDate;
  final String time;
  final String quantity;
  final String option;
}

class TransportCustomerData {
  const TransportCustomerData({
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.documentNumber,
    required this.notes,
  });

  final String name;
  final String phone;
  final String whatsapp;
  final String documentNumber;
  final String notes;
}

class TransportCustomerScreen extends StatefulWidget {
  const TransportCustomerScreen({
    super.key,
    required this.listing,
    required this.trip,
    required this.subtotal,
  });

  final TransportListing listing;
  final TransportTripData trip;
  final int subtotal;

  @override
  State<TransportCustomerScreen> createState() =>
      _TransportCustomerScreenState();
}

class _TransportCustomerScreenState extends State<TransportCustomerScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();
  final document = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    whatsapp.dispose();
    document.dispose();
    notes.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransportPaymentScreen(
          listing: widget.listing,
          trip: widget.trip,
          subtotal: widget.subtotal,
          customer: TransportCustomerData(
            name: name.text.trim(),
            phone: phone.text.trim(),
            whatsapp: whatsapp.text.trim().isEmpty
                ? phone.text.trim()
                : whatsapp.text.trim(),
            documentNumber: document.text.trim(),
            notes: notes.text.trim(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TransportBookingFrame(
    step: 3,
    title: 'بيانات العميل',
    child: Form(
      key: formKey,
      child: ListView(
        key: const Key('transport-customer-list'),
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
        children: [
          _TransportSummary(listing: widget.listing),
          const SizedBox(height: 17),
          const _TransportHeading('بيانات التواصل والتحقق'),
          const SizedBox(height: 9),
          _TransportFormField(
            key: const Key('transport-customer-name'),
            controller: name,
            label: 'الاسم الكامل',
            hint: 'أدخل الاسم كما في الوثيقة',
            icon: Icons.person_outline_rounded,
            validator: (value) => (value?.trim().length ?? 0) < 4
                ? 'يرجى إدخال الاسم الكامل'
                : null,
          ),
          _TransportFormField(
            key: const Key('transport-customer-phone'),
            controller: phone,
            label: 'رقم الهاتف',
            hint: '967 7XX XXX XXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) => (value?.trim().length ?? 0) < 7
                ? 'يرجى إدخال رقم هاتف صحيح'
                : null,
          ),
          _TransportFormField(
            controller: whatsapp,
            label: 'رقم الواتساب (اختياري)',
            hint: 'اتركه فارغاً لاستخدام رقم الهاتف',
            icon: Icons.chat_outlined,
            keyboardType: TextInputType.phone,
          ),
          _TransportFormField(
            key: const Key('transport-customer-document'),
            controller: document,
            label: widget.listing.category == TransportCategory.freight
                ? 'رقم هوية المرسل'
                : 'رقم الهوية أو جواز السفر',
            hint: 'أدخل رقم الوثيقة',
            icon: Icons.badge_outlined,
            validator: (value) => (value?.trim().length ?? 0) < 4
                ? 'يرجى إدخال رقم الوثيقة'
                : null,
          ),
          _TransportFormField(
            controller: notes,
            label: 'ملاحظات إضافية (اختياري)',
            hint: 'أضف أي تفاصيل تساعد مزود الخدمة...',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffedf5ff),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: _transportBlue),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'بياناتك محفوظة وآمنة',
                        style: TextStyle(
                          color: _transportBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      LocalizedText(
                        'لن تتم مشاركة بياناتك خارج نطاق تنفيذ الحجز',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _TransportPrimaryButton(
            key: const Key('transport-customer-continue'),
            label: 'متابعة إلى الدفع',
            onPressed: _continue,
          ),
        ],
      ),
    ),
  );
}

class TransportPaymentScreen extends StatefulWidget {
  const TransportPaymentScreen({
    super.key,
    required this.listing,
    required this.trip,
    required this.subtotal,
    required this.customer,
  });

  final TransportListing listing;
  final TransportTripData trip;
  final int subtotal;
  final TransportCustomerData customer;

  @override
  State<TransportPaymentScreen> createState() => _TransportPaymentScreenState();
}

class _TransportPaymentScreenState extends State<TransportPaymentScreen> with ProviderBookingState<TransportPaymentScreen> {
  String selectedMethod = 'محفظة ون كاش';

  int get serviceFee => (widget.subtotal * .05).round();
  int get insurance => (widget.subtotal * .03).round();
  int get total => widget.subtotal + serviceFee + insurance;

  static const methods = [
    ('محفظة ون كاش', Icons.account_balance_wallet_rounded),
    ('جوالي', Icons.phone_android_rounded),
    ('جيب', Icons.wallet_rounded),
    ('فلوسك', Icons.account_balance_rounded),
    ('بطاقة ائتمانية', Icons.credit_card_rounded),
  ];

  @override
  Widget build(BuildContext context) => TransportBookingFrame(
    step: 4,
    title: 'إتمام الدفع',
    child: ListView(
      key: const Key('transport-payment-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _TransportSummary(listing: widget.listing),
        const SizedBox(height: 16),
        const _TransportHeading('ملخص الخدمة'),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: _transportCard(),
          child: Column(
            children: [
              _TransportInvoiceLine('من', widget.trip.origin),
              if (widget.trip.destination.isNotEmpty)
                _TransportInvoiceLine('إلى', widget.trip.destination),
              _TransportInvoiceLine(
                'التاريخ',
                _transportDate(widget.trip.date),
              ),
              _TransportInvoiceLine('الكمية', widget.trip.quantity),
              _TransportInvoiceLine('الخيار', widget.trip.option),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const _TransportHeading('تفاصيل السعر'),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _transportCard(),
          child: Column(
            children: [
              _TransportInvoiceLine(
                'سعر الخدمة',
                '${_transportMoney(widget.subtotal)} ر.ي',
              ),
              const Divider(),
              _TransportInvoiceLine(
                'رسوم الحجز',
                '${_transportMoney(serviceFee)} ر.ي',
              ),
              const Divider(),
              _TransportInvoiceLine(
                'التأمين',
                '${_transportMoney(insurance)} ر.ي',
              ),
              const Divider(),
              _TransportInvoiceLine(
                'الإجمالي الكلي',
                '${_transportMoney(total)} ر.ي',
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
              Icon(Icons.event_available_rounded, color: _transportGreen),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'إلغاء مجاني',
                      style: TextStyle(
                        color: _transportGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      'يمكنك إلغاء الحجز مجاناً وفق شروط مقدم الخدمة',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _TransportHeading('اختر طريقة الدفع'),
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
                      ? _transportBlue
                      : const Color(0xffe5d9c8),
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
                        ? _transportBlue
                        : const Color(0xff8f897e),
                  ),
                  const SizedBox(width: 9),
                  Icon(method.$2, color: _transportGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LocalizedText(
                      method.$1,
                      style: const TextStyle(
                        color: _transportDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const LocalizedText('دفع آمن'),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xffedf5ff),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: _transportBlue),
              SizedBox(width: 7),
              Flexible(
                child: LocalizedText(
                  'جميع معاملاتك مشفرة وآمنة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _transportBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _TransportPrimaryButton(
          key: const Key('transport-pay-button'),
          label: 'ادفع الآن • ${_transportMoney(total)} ر.ي',
          onPressed: () async {
            await submitProviderBooking(ProviderBookingSelection(module: widget.listing.category.name == 'carRental' ? 'car_rental' : widget.listing.category.name == 'passengerTransport' ? 'land_transport' : 'freight', serviceId:widget.listing.id, serviceName:widget.listing.title, providerName:widget.listing.provider, province:widget.listing.city));
          },
        ),
      ],
    ),
  );
}

class TransportBookingSuccessScreen extends StatelessWidget {
  const TransportBookingSuccessScreen({
    super.key,
    required this.listing,
    required this.trip,
    required this.customer,
    required this.method,
    required this.subtotal,
    required this.serviceFee,
    required this.insurance,
    required this.total,
  });

  final TransportListing listing;
  final TransportTripData trip;
  final TransportCustomerData customer;
  final String method;
  final int subtotal;
  final int serviceFee;
  final int insurance;
  final int total;

  String get bookingNumber => '${listing.category.bookingPrefix}-2026-000427';

  @override
  Widget build(BuildContext context) => TransportBookingFrame(
    step: 5,
    title: 'تم تأكيد الحجز',
    child: ListView(
      key: const Key('transport-success-list'),
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_transportDark, _transportBlue],
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 37,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.check_rounded,
                  color: _transportGreen,
                  size: 50,
                ),
              ),
              SizedBox(height: 12),
              LocalizedText(
                'تم تأكيد حجزك بنجاح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                'أرسلنا تفاصيل الحجز والتواصل إلى هاتفك',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _TransportSummary(listing: listing),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _transportCard(),
          child: Column(
            children: [
              _TransportInvoiceLine('رقم الحجز', bookingNumber),
              _TransportInvoiceLine('نوع الخدمة', listing.category.label),
              _TransportInvoiceLine('التاريخ', _transportDate(trip.date)),
              _TransportInvoiceLine('الكمية', trip.quantity),
              _TransportInvoiceLine('طريقة الدفع', method),
              const _TransportInvoiceLine(
                'حالة الحجز',
                'مؤكد ✓',
                success: true,
              ),
              _TransportInvoiceLine(
                'الإجمالي',
                '${_transportMoney(total)} ر.ي',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _TransportPrimaryButton(
          key: const Key('transport-show-invoice'),
          label: 'عرض تفاصيل الحجز والفاتورة',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransportInvoiceScreen(
                listing: listing,
                trip: trip,
                customer: customer,
                method: method,
                subtotal: subtotal,
                serviceFee: serviceFee,
                insurance: insurance,
                total: total,
                bookingNumber: bookingNumber,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransportRatingScreen(listing: listing),
            ),
          ),
          icon: const Icon(Icons.star_outline_rounded),
          label: const LocalizedText('تقييم الخدمة'),
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

class TransportInvoiceScreen extends StatelessWidget {
  const TransportInvoiceScreen({
    super.key,
    required this.listing,
    required this.trip,
    required this.customer,
    required this.method,
    required this.subtotal,
    required this.serviceFee,
    required this.insurance,
    required this.total,
    required this.bookingNumber,
  });

  final TransportListing listing;
  final TransportTripData trip;
  final TransportCustomerData customer;
  final String method;
  final int subtotal;
  final int serviceFee;
  final int insurance;
  final int total;
  final String bookingNumber;

  @override
  Widget build(BuildContext context) => TransportBookingFrame(
    step: 6,
    title: 'فاتورة الحجز',
    child: ListView(
      key: const Key('transport-invoice-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _TransportSummary(listing: listing),
        const SizedBox(height: 13),
        Row(
          children: [
            const Expanded(
              child: _TransportPill(
                label: 'حجز مؤكد',
                icon: Icons.verified_rounded,
                color: _transportGreen,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: LocalizedText(
                'رقم الحجز $bookingNumber',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _transportDark,
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
            color: const Color(0xffffefd9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const LocalizedText(
            'تم إرسال تفاصيل الحجز إلى رقم الواتساب المسجل',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _transportGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const _TransportHeading('تفاصيل الخدمة'),
        const SizedBox(height: 9),
        _TransportInvoiceGrid(
          entries: [
            ('التصنيف', listing.category.label),
            ('الخدمة', listing.title),
            ('من', trip.origin),
            ('إلى', trip.destination.isEmpty ? trip.origin : trip.destination),
            ('التاريخ', _transportDate(trip.date)),
            ('الوقت', trip.time),
            ('الكمية', trip.quantity),
            ('الخيار', trip.option),
          ],
        ),
        const SizedBox(height: 19),
        const _TransportHeading('بيانات العميل'),
        const SizedBox(height: 9),
        _TransportInvoiceGrid(
          entries: [
            ('الاسم', customer.name),
            ('رقم الهاتف', customer.phone),
            ('الواتساب', customer.whatsapp),
            ('رقم الوثيقة', customer.documentNumber),
          ],
        ),
        const SizedBox(height: 19),
        const _TransportHeading('تفاصيل الدفع'),
        const SizedBox(height: 9),
        _TransportInvoiceGrid(
          entries: [
            ('طريقة الدفع', method),
            ('سعر الخدمة', '${_transportMoney(subtotal)} ر.ي'),
            ('رسوم الحجز', '${_transportMoney(serviceFee)} ر.ي'),
            ('التأمين', '${_transportMoney(insurance)} ر.ي'),
            ('الإجمالي', '${_transportMoney(total)} ر.ي'),
            ('حالة الدفع', 'تم الدفع بنجاح'),
          ],
          successIndex: 5,
        ),
        const SizedBox(height: 19),
        const _TransportHeading('التتبع والموقع'),
        const SizedBox(height: 9),
        Container(
          height: 127,
          decoration: BoxDecoration(
            color: const Color(0xffedf5ff),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xffd9e6f5)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _TransportMapPainter()),
              ),
              const Icon(
                Icons.location_on_rounded,
                color: _transportBlue,
                size: 47,
              ),
              Positioned(
                right: 12,
                bottom: 8,
                child: LocalizedText(
                  trip.destination.isEmpty
                      ? trip.origin
                      : '${trip.origin} ← ${trip.destination}',
                  style: const TextStyle(
                    color: _transportDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _transportCard(),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'الفاتورة والتحقق',
                      style: TextStyle(
                        color: _transportDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    LocalizedText('رمز التحقق'),
                    LocalizedText(
                      'TR20458',
                      key: Key('transport-invoice-code'),
                      style: TextStyle(
                        color: _transportBlue,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const _TransportQrPattern(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ServiceCompletionFooter(
          serviceKey: 'تأجير السيارات والنقل البري والشحن الداخلي',
          serviceName: 'تأجير السيارات والنقل البري والشحن الداخلي',
          invoiceTitle: 'فاتورة ${listing.title}',
          invoiceReference: bookingNumber,
          invoiceStatus: 'تم الدفع بنجاح',
          invoiceDetails: [
            ('رقم الحجز', bookingNumber),
            ('التصنيف', listing.category.label),
            ('الخدمة', listing.title),
            ('من', trip.origin),
            ('إلى', trip.destination.isEmpty ? trip.origin : trip.destination),
            ('التاريخ', _transportDate(trip.date)),
            ('الوقت', trip.time),
            ('الكمية', trip.quantity),
            ('الخيار', trip.option),
            ('اسم العميل', customer.name),
            ('رقم الهاتف', customer.phone),
            ('الواتساب', customer.whatsapp),
            ('رقم الوثيقة', customer.documentNumber),
            ('طريقة الدفع', method),
            ('سعر الخدمة', '${_transportMoney(subtotal)} ر.ي'),
            ('رسوم الحجز', '${_transportMoney(serviceFee)} ر.ي'),
            ('التأمين', '${_transportMoney(insurance)} ر.ي'),
            ('الإجمالي', '${_transportMoney(total)} ر.ي'),
            ('حالة الدفع', 'تم الدفع بنجاح'),
            (
              'مسار التتبع',
              trip.destination.isEmpty
                  ? trip.origin
                  : '${trip.origin} ← ${trip.destination}',
            ),
            ('رمز التحقق', 'TR20458'),
          ],
          invoiceText:
              'فاتورة ${listing.title}\nرقم الحجز: $bookingNumber\nالإجمالي: ${_transportMoney(total)} ر.ي',
          rateButtonKey: const Key('transport-rate-from-invoice'),
          ratingScreenBuilder: (_) => TransportRatingScreen(listing: listing),
        ),
      ],
    ),
  );
}

class TransportRatingScreen extends StatefulWidget {
  const TransportRatingScreen({super.key, required this.listing});

  final TransportListing listing;

  @override
  State<TransportRatingScreen> createState() => _TransportRatingScreenState();
}

class _TransportRatingScreenState extends State<TransportRatingScreen> {
  int rating = 5;
  final categoryRatings = <String, int>{
    'جودة الخدمة': 5,
    'الالتزام بالوقت': 5,
    'التعامل والاحترافية': 5,
    'الأمان والنظافة': 5,
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
      'تأجير السيارات والنقل البري والشحن الداخلي',
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
      backgroundColor: _transportSurface,
      appBar: AppBar(title: const LocalizedText('تقييم خدمة النقل')),
      body: SafeArea(
        child: ListView(
          key: const Key('transport-rating-list'),
          padding: const EdgeInsets.all(16),
          children: [
            _TransportSummary(listing: widget.listing),
            const SizedBox(height: 20),
            const LocalizedText(
              'كيف كانت تجربتك؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _transportDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const LocalizedText(
              'تقييمك يساعدنا على تطوير جودة خدمات النقل',
              textAlign: TextAlign.center,
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
                    color: _transportOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...categoryRatings.entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: _transportCard(),
                child: Row(
                  children: [
                    Expanded(
                      child: LocalizedText(
                        entry.key,
                        style: const TextStyle(
                          color: _transportDark,
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
                            color: _transportOrange,
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
                hintText: l10n('اكتب ملاحظتك عن الخدمة والمزود...'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xffeadfce)),
                ),
              ),
            ),
            const SizedBox(height: 13),
            if (saved)
              Container(
                margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xffeafff3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: _transportGreen),
                    SizedBox(width: 8),
                    LocalizedText(
                      'تم حفظ تقييمك، شكراً لمشاركتنا تجربتك.',
                      style: TextStyle(
                        color: _transportGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            _TransportPrimaryButton(
              label: saved ? 'تحديث التقييم' : 'إرسال التقييم',
              onPressed: _saveReview,
            ),
          ],
        ),
      ),
    ),
  );
}

class TransportBookingFrame extends StatelessWidget {
  const TransportBookingFrame({
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
      backgroundColor: _transportSurface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 17),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_transportDark, _transportBlue],
                ),
              ),
              child: Row(
                children: [
                  _TransportRoundButton(
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
                          'نقلك بثقة، بخطوات سهلة وآمنة',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo_transparent.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            _TransportProgress(step: step),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _TransportProgress extends StatelessWidget {
  const _TransportProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'الخدمة',
      'الحجز',
      'بياناتك',
      'الدفع',
      'التأكيد',
      'الفاتورة',
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(3, 8, 3, 6),
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
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: done
                              ? _transportGreen
                              : active
                              ? _transportBlue
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done
                                ? _transportGreen
                                : active
                                ? _transportBlue
                                : const Color(0xffded6ca),
                          ),
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 17,
                                )
                              : LocalizedText(
                                  '$number',
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : const Color(0xff8d877d),
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
                          fontSize: 8,
                          color: done
                              ? _transportGreen
                              : active
                              ? _transportBlue
                              : const Color(0xff8a847a),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < labels.length - 1)
                  Container(
                    width: 4,
                    height: 2,
                    color: number < step
                        ? _transportGreen
                        : const Color(0xffded7cc),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TransportSummary extends StatelessWidget {
  const _TransportSummary({required this.listing});

  final TransportListing listing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: _transportCard(),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            transportImageAsset,
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
                listing.title,
                style: const TextStyle(
                  color: _transportDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                '${listing.provider} • ${listing.city}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xff7c766d)),
              ),
              LocalizedText(
                '★ ${listing.rating} ممتاز • ${listing.reviews} تقييم',
                style: const TextStyle(
                  color: _transportOrange,
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

class _TransportQuickInfo extends StatelessWidget {
  const _TransportQuickInfo({required this.listing});

  final TransportListing listing;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_transportCategoryIcon(listing.category), listing.category.label),
      (Icons.groups_outlined, listing.capacity),
      (Icons.location_on_outlined, listing.city),
      (Icons.shield_outlined, 'تأمين شامل'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.15,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _transportSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffeadfce)),
        ),
        child: Row(
          children: [
            Icon(items[index].$1, color: _transportBlue, size: 21),
            const SizedBox(width: 7),
            Expanded(
              child: LocalizedText(
                items[index].$2,
                maxLines: 2,
                style: const TextStyle(
                  color: _transportDark,
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

class _TransportInput extends StatelessWidget {
  const _TransportInput({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextField(
      controller: controller,
      decoration: _transportInputDecoration(icon, label),
    ),
  );
}

class _TransportDateTile extends StatelessWidget {
  const _TransportDateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: _transportCard(),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: _transportGold),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(label, style: const TextStyle(fontSize: 11)),
                LocalizedText(
                  value,
                  style: const TextStyle(
                    color: _transportDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TransportOptionSwitch extends StatelessWidget {
  const _TransportOptionSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: _transportCard(),
    child: Row(
      children: [
        const Icon(Icons.tune_rounded, color: _transportGold),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                title,
                style: const TextStyle(
                  color: _transportDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              LocalizedText(subtitle),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: _transportBlue,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _TransportCounter extends StatelessWidget {
  const _TransportCounter({
    super.key,
    required this.title,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String title;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: _transportCard(),
    child: Row(
      children: [
        const Icon(Icons.groups_outlined, color: _transportBlue),
        const SizedBox(width: 9),
        Expanded(
          child: LocalizedText(
            title,
            style: const TextStyle(
              color: _transportDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        LocalizedText(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );
}

class _TransportFormField extends StatelessWidget {
  const _TransportFormField({
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
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          label,
          style: const TextStyle(
            color: _transportDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: _transportInputDecoration(icon, hint),
        ),
      ],
    ),
  );
}

class _TransportInvoiceLine extends StatelessWidget {
  const _TransportInvoiceLine(
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
              color: highlight ? _transportDark : const Color(0xff7e786e),
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
                  ? _transportGreen
                  : highlight
                  ? _transportBlue
                  : _transportDark,
              fontSize: highlight ? 18 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TransportInvoiceGrid extends StatelessWidget {
  const _TransportInvoiceGrid({required this.entries, this.successIndex = -1});

  final List<(String, String)> entries;
  final int successIndex;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: entries.length,
    itemBuilder: (_, index) => Container(
      padding: const EdgeInsets.all(10),
      decoration: _transportCard(radius: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            entries[index].$1,
            style: const TextStyle(color: Color(0xff817b72)),
          ),
          LocalizedText(
            entries[index].$2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: index == successIndex ? _transportGreen : _transportDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TransportHeading extends StatelessWidget {
  const _TransportHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => LocalizedText(
    label,
    style: const TextStyle(
      color: _transportDark,
      fontSize: 22,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _TransportPrimaryButton extends StatelessWidget {
  const _TransportPrimaryButton({
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
      backgroundColor: _transportBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 53),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    ),
    child: LocalizedText(label),
  );
}

class _TransportRoundButton extends StatelessWidget {
  const _TransportRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 2,
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: _transportBlue),
    ),
  );
}

class _TransportPill extends StatelessWidget {
  const _TransportPill({
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
      color: color.withValues(alpha: .12),
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

class _TransportCondition extends StatelessWidget {
  const _TransportCondition(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: _transportGold),
        const SizedBox(width: 9),
        Expanded(child: LocalizedText(text)),
      ],
    ),
  );
}

class _TransportQrPattern extends StatelessWidget {
  const _TransportQrPattern();

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
        final dark = (row * 3 + column * 7 + row * column) % 4 != 0;
        return ColoredBox(color: dark ? _transportDark : Colors.white);
      },
    ),
  );
}

class _TransportMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffcbd9e9)
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

InputDecoration _transportInputDecoration(IconData icon, String label) =>
    InputDecoration(
      labelText: l10n(label),
      prefixIcon: Icon(icon, color: _transportGold),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffe6dac9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffe6dac9)),
      ),
    );

BoxDecoration _transportCard({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xffe7dccb)),
  boxShadow: const [
    BoxShadow(color: Color(0x0d000000), blurRadius: 8, offset: Offset(0, 3)),
  ],
);

IconData _transportCategoryIcon(TransportCategory category) =>
    switch (category) {
      TransportCategory.carRental => Icons.directions_car_filled_rounded,
      TransportCategory.passengerTransport => Icons.directions_bus_rounded,
      TransportCategory.freight => Icons.local_shipping_rounded,
    };

String _bookLabel(TransportCategory category) => switch (category) {
  TransportCategory.carRental => 'احجز السيارة الآن',
  TransportCategory.passengerTransport => 'احجز رحلتك الآن',
  TransportCategory.freight => 'احجز خدمة الشحن',
};

String _bookingSectionTitle(TransportCategory category) => switch (category) {
  TransportCategory.carRental => 'حدد الاستلام والإعادة',
  TransportCategory.passengerTransport => 'حدد مسار الرحلة والركاب',
  TransportCategory.freight => 'أدخل بيانات الشحنة والنقل',
};

String _originLabel(TransportCategory category) => switch (category) {
  TransportCategory.carRental => 'موقع استلام السيارة',
  TransportCategory.passengerTransport => 'مدينة أو نقطة الانطلاق',
  TransportCategory.freight => 'موقع استلام الشحنة',
};
