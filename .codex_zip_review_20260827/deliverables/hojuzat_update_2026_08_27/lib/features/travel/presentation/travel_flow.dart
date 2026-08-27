import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/maps/app_map_launcher.dart';
import '../../../core/reviews/service_review.dart';
import '../../catalog/data/control_panel_repository.dart';
import '../domain/travel_models.dart';

const travelBannerAsset = 'assets/images/travel_booking_banner.png';
const travelImageAsset = 'assets/Services images/سفريات وسياحة.jpg';

const _travelPurple = Color(0xff5b2588);
const _travelDeep = Color(0xff2e1550);
const _travelViolet = Color(0xff8844ae);
const _travelBlue = Color(0xff315bd4);
const _travelGreen = Color(0xff10af65);
const _travelOrange = Color(0xffff9800);
const _travelSurface = Color(0xfffaf7ff);

String _travelMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

String _travelDate(DateTime value) =>
    '${value.day}/${value.month}/${value.year}';

class TravelDiscoveryScreen extends StatefulWidget {
  const TravelDiscoveryScreen({super.key, required this.province});

  final String province;

  @override
  State<TravelDiscoveryScreen> createState() => _TravelDiscoveryScreenState();
}

class _TravelDiscoveryScreenState extends State<TravelDiscoveryScreen> {
  TravelCategory selectedCategory = TravelCategory.flights;
  String query = '';
  String filter = 'الكل';
  final favorites = <String>{};
  List<ProviderRecord> get travelOffices => localControlPanelRepository.providers
      .where((item) => item.serviceId == 'travel' && item.enabled)
      .toList();
  List<PromotionRecord> get travelPromotions =>
      localControlPanelRepository.promotions
          .where((item) => item.enabled && item.serviceId == 'travel')
          .toList();

  List<TravelListing> get results {
    var list = travelListings
        .where(
          (item) =>
              item.category == selectedCategory &&
              (item.title.contains(query) ||
                  item.provider.contains(query) ||
                  item.destination.contains(query)),
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
      backgroundColor: _travelSurface,
      bottomNavigationBar: const _TravelBottomNav(),
      body: SafeArea(
        child: ListView(
          key: const Key('travel-discovery-list'),
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xfff1e8fb),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      travelBannerAsset,
                      key: const Key('travel-main-banner'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: _TravelRoundButton(
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
                decoration: _travelCard(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LocalizedText(
                      'خطط لسفرك ومعاملاتك بسهولة',
                      style: TextStyle(
                        color: _travelDeep,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextField(
                      key: const Key('travel-search-field'),
                      onChanged: (value) =>
                          setState(() => query = value.trim()),
                      decoration: InputDecoration(
                        hintText: l10n('ابحث عن رحلة، دولة، تأشيرة أو معاملة'),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _travelPurple,
                        ),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: _travelPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                          ),
                        ),
                        filled: true,
                        fillColor: _travelSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xffe3d4ef),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xffe3d4ef),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _TravelMeta(
                          Icons.location_on_outlined,
                          widget.province,
                        ),
                        const _TravelMetaDivider(),
                        const _TravelMeta(
                          Icons.verified_user_outlined,
                          'مكاتب موثقة',
                        ),
                        const _TravelMetaDivider(),
                        const _TravelMeta(
                          Icons.support_agent_rounded,
                          'دعم 24/7',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 9),
              child: _TravelHeading('التصنيفات'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                ),
                itemCount: TravelCategory.values.length,
                itemBuilder: (_, index) {
                  final category = TravelCategory.values[index];
                  return _TravelCategoryCard(
                    key: Key('travel-category-${category.name}'),
                    category: category,
                    selected: selectedCategory == category,
                    onTap: () => setState(() {
                      selectedCategory = category;
                      filter = 'الكل';
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 17),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.near_me_outlined, size: 18),
                      label: const LocalizedText('الأقرب إليك'),
                      onPressed: () => AppMapLauncher.open(
                        context,
                        query: 'مكاتب سفريات وسياحة ${widget.province} اليمن',
                      ),
                    ),
                  ),
                  ...['الكل', 'الأعلى تقييماً', 'الأقل سعراً'].map(
                      (label) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: LocalizedText(label),
                          selected: filter == label,
                          showCheckmark: false,
                          selectedColor: const Color(0xffeee3fa),
                          side: BorderSide(
                            color: filter == label
                                ? _travelPurple
                                : const Color(0xffded1e9),
                          ),
                          labelStyle: TextStyle(
                            color: filter == label
                                ? _travelPurple
                                : _travelDeep,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => filter = label),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
              child: const _TravelHeading('العروض المميزة'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: travelPromotions
                    .map((promotion) => _TravelPromotionBanner(promotion: promotion))
                    .toList(),
              ),
            ),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(child: LocalizedText('لا توجد نتائج مطابقة لبحثك')),
              )
            else
              ...results.map(
                (listing) => _TravelListingCard(
                  key: Key('travel-listing-${listing.id}'),
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
                      builder: (_) => TravelDetailsScreen(listing: listing),
                    ),
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 22, 15, 10),
              child: _TravelHeading('شركات ومكاتب السفريات والسياحة'),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: travelOffices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .78,
              ),
              itemBuilder: (_, index) => _TravelOfficeCard(
                name: travelOffices[index].name,
                imagePath: travelOffices[index].imagePath,
                visits: 120 + index * 37,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TravelOfficeScreen(
                      name: travelOffices[index].name,
                      province: widget.province,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(15, 10, 15, 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_travelDeep, _travelPurple],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.public_rounded, color: Colors.white, size: 44),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'سافر والباقي علينا',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        LocalizedText(
                          'أسعار مميزة، متابعة مستمرة، ومعاملات آمنة',
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
}

class _TravelPromotionBanner extends StatelessWidget {
  const _TravelPromotionBanner({required this.promotion});
  final PromotionRecord promotion;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TravelDetailsScreen(listing: travelListings.first),
      ),
    ),
    borderRadius: BorderRadius.circular(19),
    child: Container(
      height: 128,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: _travelCard(radius: 19),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(promotion.imagePath, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xdd2e1550), Color(0x552e1550)],
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
                  promotion.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                LocalizedText(
                  'خصم ${promotion.discountPercent}% • اضغط لعرض الخدمة',
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

class _TravelOfficeCard extends StatefulWidget {
  const _TravelOfficeCard({
    required this.name,
    required this.imagePath,
    required this.visits,
    required this.onTap,
  });
  final String name;
  final String imagePath;
  final int visits;
  final VoidCallback onTap;

  @override
  State<_TravelOfficeCard> createState() => _TravelOfficeCardState();
}

class _TravelOfficeCardState extends State<_TravelOfficeCard> {
  bool favorite = false;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 6,
    shadowColor: _travelPurple.withValues(alpha: .25),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: InkWell(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.imagePath, fit: BoxFit.cover),
                PositionedDirectional(
                  top: 5,
                  end: 5,
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => favorite = !favorite),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? Colors.red : _travelPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalizedText(
                    widget.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _travelDeep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    '${widget.visits} زيارة',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
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

class TravelOfficeScreen extends StatelessWidget {
  const TravelOfficeScreen({
    super.key,
    required this.name,
    required this.province,
  });
  final String name;
  final String province;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _travelSurface,
      appBar: AppBar(title: LocalizedText(name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 28),
        children: [
          Container(
            height: 210,
            clipBehavior: Clip.antiAlias,
            decoration: _travelCard(radius: 23),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(travelImageAsset, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xcc2e1550)],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LocalizedText(
                      '$name • $province',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _TravelHeading('التصنيفات'),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: TravelCategory.values.map((category) => OutlinedButton.icon(
              onPressed: () => _openCategory(context, category),
              icon: const Icon(Icons.travel_explore),
              label: FittedBox(child: LocalizedText(category.label)),
            )).toList(),
          ),
          const SizedBox(height: 18),
          const _TravelHeading('الخدمات'),
          const SizedBox(height: 8),
          ...TravelCategory.values.map(
            (category) => Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                onTap: () => _openCategory(context, category),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xffeee3fa),
                  child: Icon(Icons.assignment_outlined, color: _travelPurple),
                ),
                title: LocalizedText('طلب ${category.label}'),
                subtitle: LocalizedText(category.description),
                trailing: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _openCategory(BuildContext context, TravelCategory category) {
    final listing = travelListings.firstWhere((item) => item.category == category);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TravelDetailsScreen(listing: listing)),
    );
  }
}

class _TravelCategoryCard extends StatelessWidget {
  const _TravelCategoryCard({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TravelCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffeee3fa) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _travelPurple : const Color(0xffe2d5ed),
          width: selected ? 1.7 : 1,
        ),
        boxShadow: const [BoxShadow(color: Color(0x0c000000), blurRadius: 7)],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? _travelPurple : const Color(0xfff1e8f8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _travelCategoryIcon(category),
              color: selected ? Colors.white : _travelViolet,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: LocalizedText(
              category.label,
              maxLines: 2,
              style: const TextStyle(
                color: _travelDeep,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TravelListingCard extends StatelessWidget {
  const _TravelListingCard({
    super.key,
    required this.listing,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final TravelListing listing;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(15, 0, 15, 11),
    decoration: _travelCard(radius: 19),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 135,
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(travelImageAsset, fit: BoxFit.cover),
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
                    child: LocalizedText(
                      l10n('موثق', 'Verified'),
                      style: const TextStyle(
                        color: _travelGreen,
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
                          l10n(listing.title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _travelDeep,
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
                          color: favorite ? Colors.redAccent : _travelPurple,
                        ),
                      ),
                    ],
                  ),
                  LocalizedText(
                    l10n(listing.provider),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xff7d7284)),
                  ),
                  LocalizedText(
                    '★ ${listing.rating} ${l10n('ممتاز', 'Excellent')} • ${listing.reviews} ${l10n('تقييم', 'reviews')}',
                    style: const TextStyle(
                      color: _travelOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LocalizedText(
                    l10n(listing.processingTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _travelBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LocalizedText(
                    '${_travelMoney(listing.price)} ${l10n('ر.ي', 'YER')} / ${l10n(listing.priceUnit)}',
                    style: const TextStyle(
                      color: _travelPurple,
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

class TravelDetailsScreen extends StatelessWidget {
  const TravelDetailsScreen({super.key, required this.listing});

  final TravelListing listing;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _travelSurface,
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
                child: _TravelPrimaryButton(
                  key: const Key('travel-start-request'),
                  label: _travelActionLabel(listing.category),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TravelRequestScreen(listing: listing),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    '${_travelMoney(listing.price)} ر.ي',
                    style: const TextStyle(
                      color: _travelDeep,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    listing.priceUnit,
                    style: const TextStyle(color: Color(0xff7b7182)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('travel-detail-list'),
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Image.asset(
                  travelImageAsset,
                  width: double.infinity,
                  height: 310,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: _TravelRoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 14,
                  child: Row(
                    children: [
                      _TravelRoundButton(
                        icon: Icons.share_outlined,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(
                            text:
                                '${listing.title}\n${listing.provider}\n${_travelMoney(listing.price)} ر.ي',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TravelRoundButton(
                        icon: Icons.favorite_border_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 13,
                  child: _TravelPill(
                    label: listing.category.label,
                    icon: _travelCategoryIcon(listing.category),
                    color: _travelPurple,
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
                      color: _travelDeep,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    '${listing.provider} • ${listing.destination}',
                    style: const TextStyle(
                      color: Color(0xff7e7485),
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
                          color: _travelOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const _TravelPill(
                        label: 'مزود موثق',
                        icon: Icons.verified_rounded,
                        color: _travelGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),
                  _TravelQuickInfo(listing: listing),
                  const SizedBox(height: 23),
                  const _TravelHeading('تفاصيل الخدمة'),
                  const SizedBox(height: 7),
                  LocalizedText(
                    listing.description,
                    style: const TextStyle(
                      color: Color(0xff706779),
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _TravelHeading('المميزات'),
                  const SizedBox(height: 10),
                  _TravelStringGrid(
                    values: listing.features,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(height: 22),
                  const _TravelHeading('المتطلبات الأساسية'),
                  const SizedBox(height: 10),
                  ...listing.requirements.asMap().entries.map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: _travelCard(),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color(0xffeee2f8),
                            child: LocalizedText(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: _travelPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LocalizedText(
                              entry.value,
                              style: const TextStyle(
                                color: _travelDeep,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  const _TravelCondition(
                    Icons.security_rounded,
                    'تتم مراجعة جميع الوثائق قبل تقديم الطلب',
                  ),
                  const _TravelCondition(
                    Icons.notifications_active_outlined,
                    'تصلك تحديثات فورية عند تغير حالة الطلب',
                  ),
                  const _TravelCondition(
                    Icons.support_agent_rounded,
                    'دعم ومتابعة من فريق مختص حتى اكتمال الخدمة',
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

class TravelRequestScreen extends StatefulWidget {
  const TravelRequestScreen({super.key, required this.listing});

  final TravelListing listing;

  @override
  State<TravelRequestScreen> createState() => _TravelRequestScreenState();
}

class _TravelRequestScreenState extends State<TravelRequestScreen> {
  late final TextEditingController origin;
  late final TextEditingController destination;
  final profession = TextEditingController();
  final employer = TextEditingController();
  DateTime startDate = DateTime.now().add(const Duration(days: 14));
  DateTime returnDate = DateTime.now().add(const Duration(days: 21));
  int applicants = 1;
  bool roundTrip = true;
  String travelClass = 'الدرجة الاقتصادية';
  String nationality = 'يمني';
  String visaDuration = '30 يوماً';
  String workService = 'تأشيرة جديدة';
  String authority = 'وزارة الخارجية';
  String urgency = 'عادي';

  TravelCategory get category => widget.listing.category;

  @override
  void initState() {
    super.initState();
    origin = TextEditingController(text: 'صنعاء');
    destination = TextEditingController(text: widget.listing.destination);
  }

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    profession.dispose();
    employer.dispose();
    super.dispose();
  }

  int get subtotal {
    final base = widget.listing.price * applicants;
    if (category == TravelCategory.flights && roundTrip) return base * 2;
    if (category == TravelCategory.administrative && urgency == 'عاجل') {
      return base + 15000;
    }
    return base;
  }

  Future<void> _pickDate(bool isReturn) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isReturn ? returnDate : startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null) return;
    setState(() {
      if (isReturn) {
        if (date.isAfter(startDate)) returnDate = date;
      } else {
        startDate = date;
        if (!returnDate.isAfter(startDate)) {
          returnDate = startDate.add(const Duration(days: 7));
        }
      }
    });
  }

  TravelRequestData _requestData() => TravelRequestData(
    origin: origin.text.trim(),
    destination: destination.text.trim(),
    startDate: startDate,
    returnDate: category == TravelCategory.flights && roundTrip
        ? returnDate
        : null,
    applicants: applicants,
    option: switch (category) {
      TravelCategory.flights =>
        '${roundTrip ? 'ذهاب وعودة' : 'ذهاب فقط'} • $travelClass',
      TravelCategory.touristVisa => '$nationality • $visaDuration',
      TravelCategory.workVisa =>
        '${profession.text.trim().isEmpty ? 'المهنة غير محددة' : profession.text.trim()} • $workService',
      TravelCategory.administrative => '$authority • $urgency',
    },
  );

  @override
  Widget build(BuildContext context) => TravelBookingFrame(
    step: 2,
    title: 'تفاصيل الطلب',
    child: ListView(
      key: const Key('travel-request-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _TravelSummary(listing: widget.listing),
        const SizedBox(height: 18),
        _TravelHeading(_travelRequestTitle(category)),
        const SizedBox(height: 9),
        if (category == TravelCategory.flights) ...[
          _TravelInput(
            controller: origin,
            label: 'مدينة أو مطار المغادرة',
            icon: Icons.flight_takeoff_rounded,
          ),
          _TravelInput(
            controller: destination,
            label: 'مدينة أو مطار الوصول',
            icon: Icons.flight_land_rounded,
          ),
          _TravelOptionSwitch(
            title: 'رحلة ذهاب وعودة',
            subtitle: 'يمكنك اختيار تاريخ العودة',
            value: roundTrip,
            onChanged: (value) => setState(() => roundTrip = value),
          ),
          Row(
            children: [
              Expanded(
                child: _TravelDateTile(
                  label: 'تاريخ المغادرة',
                  value: _travelDate(startDate),
                  onTap: () => _pickDate(false),
                ),
              ),
              if (roundTrip) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _TravelDateTile(
                    label: 'تاريخ العودة',
                    value: _travelDate(returnDate),
                    onTap: () => _pickDate(true),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: travelClass,
            decoration: _travelInputDecoration(
              Icons.airline_seat_recline_extra_rounded,
              'درجة السفر',
            ),
            items: ['الدرجة الاقتصادية', 'اقتصادية مميزة', 'درجة رجال الأعمال']
                .map(
                  (value) => DropdownMenuItem(value: value, child: LocalizedText(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => travelClass = value ?? travelClass),
          ),
          const SizedBox(height: 11),
          _TravelCounter(
            key: const Key('travel-flight-passengers'),
            title: 'عدد المسافرين',
            value: applicants,
            onMinus: applicants > 1 ? () => setState(() => applicants--) : null,
            onPlus: applicants < 9 ? () => setState(() => applicants++) : null,
          ),
        ],
        if (category == TravelCategory.touristVisa) ...[
          DropdownButtonFormField<String>(
            key: const Key('travel-tourist-nationality'),
            initialValue: nationality,
            decoration: _travelInputDecoration(
              Icons.public_rounded,
              'جنسية مقدم الطلب',
            ),
            items: ['يمني', 'سعودي', 'عماني', 'أخرى']
                .map(
                  (value) => DropdownMenuItem(value: value, child: LocalizedText(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => nationality = value ?? nationality),
          ),
          const SizedBox(height: 11),
          _TravelInput(
            controller: destination,
            label: 'الدولة المطلوبة',
            icon: Icons.location_on_outlined,
          ),
          DropdownButtonFormField<String>(
            initialValue: visaDuration,
            decoration: _travelInputDecoration(
              Icons.event_note_rounded,
              'مدة التأشيرة',
            ),
            items: ['30 يوماً', '60 يوماً', '90 يوماً', 'دخول متعدد']
                .map(
                  (value) => DropdownMenuItem(value: value, child: LocalizedText(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => visaDuration = value ?? visaDuration),
          ),
          const SizedBox(height: 11),
          _TravelDateTile(
            label: 'تاريخ السفر المتوقع',
            value: _travelDate(startDate),
            onTap: () => _pickDate(false),
          ),
          const SizedBox(height: 10),
          _TravelCounter(
            title: 'عدد المتقدمين',
            value: applicants,
            onMinus: applicants > 1 ? () => setState(() => applicants--) : null,
            onPlus: applicants < 6 ? () => setState(() => applicants++) : null,
          ),
        ],
        if (category == TravelCategory.workVisa) ...[
          _TravelInput(
            controller: destination,
            label: 'دولة العمل',
            icon: Icons.public_rounded,
          ),
          _TravelInput(
            key: const Key('travel-work-profession'),
            controller: profession,
            label: 'المهنة المطلوبة',
            icon: Icons.work_outline_rounded,
          ),
          _TravelInput(
            controller: employer,
            label: 'اسم جهة العمل أو الكفيل',
            icon: Icons.business_outlined,
          ),
          DropdownButtonFormField<String>(
            initialValue: workService,
            decoration: _travelInputDecoration(
              Icons.assignment_ind_outlined,
              'نوع الخدمة',
            ),
            items: ['تأشيرة جديدة', 'نقل كفالة', 'تجديد إقامة', 'تصريح عمل']
                .map(
                  (value) => DropdownMenuItem(value: value, child: LocalizedText(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => workService = value ?? workService),
          ),
          const SizedBox(height: 11),
          _TravelCounter(
            title: 'عدد المتقدمين',
            value: applicants,
            onMinus: applicants > 1 ? () => setState(() => applicants--) : null,
            onPlus: applicants < 6 ? () => setState(() => applicants++) : null,
          ),
        ],
        if (category == TravelCategory.administrative) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _travelCard(),
            child: _TravelInvoiceLine('نوع المعاملة', widget.listing.title),
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            initialValue: authority,
            decoration: _travelInputDecoration(
              Icons.account_balance_outlined,
              'الجهة المختصة',
            ),
            items:
                [
                      'وزارة الخارجية',
                      'مصلحة الهجرة والجوازات',
                      'السفارة',
                      'جهة أخرى',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: LocalizedText(value)),
                    )
                    .toList(),
            onChanged: (value) =>
                setState(() => authority = value ?? authority),
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            key: const Key('travel-admin-urgency'),
            initialValue: urgency,
            decoration: _travelInputDecoration(
              Icons.speed_rounded,
              'سرعة الإنجاز',
            ),
            items: ['عادي', 'عاجل']
                .map(
                  (value) => DropdownMenuItem(value: value, child: LocalizedText(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => urgency = value ?? urgency),
          ),
          const SizedBox(height: 11),
          _TravelCounter(
            title: 'عدد المعاملات أو الوثائق',
            value: applicants,
            onMinus: applicants > 1 ? () => setState(() => applicants--) : null,
            onPlus: applicants < 10 ? () => setState(() => applicants++) : null,
          ),
        ],
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffeee5f8),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            children: [
              _TravelInvoiceLine('نوع الخدمة', category.label),
              _TravelInvoiceLine(
                category == TravelCategory.flights
                    ? 'المسافرون'
                    : 'عدد الطلبات',
                '$applicants',
              ),
              _TravelInvoiceLine(
                'الإجمالي المبدئي',
                '${_travelMoney(subtotal)} ر.ي',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _TravelPrimaryButton(
          key: const Key('travel-request-continue'),
          label: 'متابعة إلى بيانات مقدم الطلب',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TravelApplicantScreen(
                listing: widget.listing,
                request: _requestData(),
                subtotal: subtotal,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class TravelRequestData {
  const TravelRequestData({
    required this.origin,
    required this.destination,
    required this.startDate,
    required this.returnDate,
    required this.applicants,
    required this.option,
  });

  final String origin;
  final String destination;
  final DateTime startDate;
  final DateTime? returnDate;
  final int applicants;
  final String option;
}

class TravelApplicantData {
  const TravelApplicantData({
    required this.name,
    required this.phone,
    required this.email,
    required this.documentNumber,
    required this.nationality,
    required this.notes,
  });

  final String name;
  final String phone;
  final String email;
  final String documentNumber;
  final String nationality;
  final String notes;
}

class TravelApplicantScreen extends StatefulWidget {
  const TravelApplicantScreen({
    super.key,
    required this.listing,
    required this.request,
    required this.subtotal,
  });

  final TravelListing listing;
  final TravelRequestData request;
  final int subtotal;

  @override
  State<TravelApplicantScreen> createState() => _TravelApplicantScreenState();
}

class _TravelApplicantScreenState extends State<TravelApplicantScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final document = TextEditingController();
  final notes = TextEditingController();
  String nationality = 'يمني';
  late final List<bool> uploaded;

  @override
  void initState() {
    super.initState();
    uploaded = List<bool>.filled(widget.listing.requirements.length, false);
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    document.dispose();
    notes.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TravelPaymentScreen(
          listing: widget.listing,
          request: widget.request,
          subtotal: widget.subtotal,
          applicant: TravelApplicantData(
            name: name.text.trim(),
            phone: phone.text.trim(),
            email: email.text.trim(),
            documentNumber: document.text.trim(),
            nationality: nationality,
            notes: notes.text.trim(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TravelBookingFrame(
    step: 3,
    title: 'بيانات مقدم الطلب',
    child: Form(
      key: formKey,
      child: ListView(
        key: const Key('travel-applicant-list'),
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
        children: [
          _TravelSummary(listing: widget.listing),
          const SizedBox(height: 17),
          const _TravelHeading('البيانات الشخصية'),
          const SizedBox(height: 9),
          _TravelFormField(
            key: const Key('travel-applicant-name'),
            controller: name,
            label: 'الاسم الكامل حسب الوثيقة',
            hint: 'أدخل الاسم الرباعي',
            icon: Icons.person_outline_rounded,
            validator: (value) => (value?.trim().length ?? 0) < 4
                ? 'يرجى إدخال الاسم الكامل'
                : null,
          ),
          _TravelFormField(
            key: const Key('travel-applicant-phone'),
            controller: phone,
            label: 'رقم الهاتف والواتساب',
            hint: '967 7XX XXX XXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) => (value?.trim().length ?? 0) < 7
                ? 'يرجى إدخال رقم هاتف صحيح'
                : null,
          ),
          _TravelFormField(
            controller: email,
            label: 'البريد الإلكتروني',
            hint: 'name@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          DropdownButtonFormField<String>(
            initialValue: nationality,
            decoration: _travelInputDecoration(Icons.public_rounded, 'الجنسية'),
            items: ['يمني', 'سعودي', 'عماني', 'أخرى']
                .map(
                  (value) => DropdownMenuItem(value: value, child: LocalizedText(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => nationality = value ?? nationality),
          ),
          const SizedBox(height: 12),
          _TravelFormField(
            key: const Key('travel-applicant-document'),
            controller: document,
            label: widget.listing.category == TravelCategory.administrative
                ? 'رقم الهوية أو الوثيقة'
                : 'رقم جواز السفر',
            hint: 'أدخل رقم الوثيقة',
            icon: Icons.badge_outlined,
            validator: (value) => (value?.trim().length ?? 0) < 4
                ? 'يرجى إدخال رقم الوثيقة'
                : null,
          ),
          const SizedBox(height: 4),
          const _TravelHeading('رفع المستندات المطلوبة'),
          const SizedBox(height: 6),
          const LocalizedText(
            'يمكنك تحديد المستندات المجهزة الآن وإكمال الرفع الفعلي عند ربط خدمة الملفات.',
            style: TextStyle(color: Color(0xff786e80)),
          ),
          const SizedBox(height: 10),
          ...widget.listing.requirements.asMap().entries.map(
            (entry) => InkWell(
              onTap: () =>
                  setState(() => uploaded[entry.key] = !uploaded[entry.key]),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: uploaded[entry.key]
                      ? const Color(0xffeafff3)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: uploaded[entry.key]
                        ? _travelGreen
                        : const Color(0xffdfd2e9),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      uploaded[entry.key]
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_outlined,
                      color: uploaded[entry.key] ? _travelGreen : _travelPurple,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: LocalizedText(
                        entry.value,
                        style: const TextStyle(
                          color: _travelDeep,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    LocalizedText(
                      uploaded[entry.key] ? 'جاهز' : 'إضافة',
                      style: TextStyle(
                        color: uploaded[entry.key]
                            ? _travelGreen
                            : _travelPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          _TravelFormField(
            controller: notes,
            label: 'ملاحظات إضافية (اختياري)',
            hint: 'أضف أي تفاصيل تساعد المختص على مراجعة طلبك...',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xfff0e9f8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: _travelPurple),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'مستنداتك وبياناتك محمية',
                        style: TextStyle(
                          color: _travelPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      LocalizedText('لا تتم مشاركتها إلا مع الجهة المعنية بتنفيذ الطلب'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _TravelPrimaryButton(
            key: const Key('travel-applicant-continue'),
            label: 'متابعة إلى الدفع',
            onPressed: _continue,
          ),
        ],
      ),
    ),
  );
}

class TravelPaymentScreen extends StatefulWidget {
  const TravelPaymentScreen({
    super.key,
    required this.listing,
    required this.request,
    required this.subtotal,
    required this.applicant,
  });

  final TravelListing listing;
  final TravelRequestData request;
  final int subtotal;
  final TravelApplicantData applicant;

  @override
  State<TravelPaymentScreen> createState() => _TravelPaymentScreenState();
}

class _TravelPaymentScreenState extends State<TravelPaymentScreen> {
  String selectedMethod = 'محفظة ون كاش';

  int get serviceFee => (widget.subtotal * .05).round();
  int get insurance => widget.listing.category == TravelCategory.flights
      ? (widget.subtotal * .03).round()
      : 0;
  int get total => widget.subtotal + serviceFee + insurance;

  static const methods = [
    ('محفظة ون كاش', Icons.account_balance_wallet_rounded),
    ('جوالي', Icons.phone_android_rounded),
    ('جيب', Icons.wallet_rounded),
    ('فلوسك', Icons.account_balance_rounded),
    ('بطاقة ائتمانية', Icons.credit_card_rounded),
  ];

  @override
  Widget build(BuildContext context) => TravelBookingFrame(
    step: 4,
    title: 'إتمام الدفع',
    child: ListView(
      key: const Key('travel-payment-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _TravelSummary(listing: widget.listing),
        const SizedBox(height: 16),
        const _TravelHeading('ملخص الطلب'),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: _travelCard(),
          child: Column(
            children: [
              _TravelInvoiceLine('التصنيف', widget.listing.category.label),
              _TravelInvoiceLine('الخدمة', widget.listing.title),
              _TravelInvoiceLine(
                'تاريخ الطلب أو السفر',
                _travelDate(widget.request.startDate),
              ),
              _TravelInvoiceLine(
                'عدد المتقدمين',
                '${widget.request.applicants}',
              ),
              _TravelInvoiceLine('الخيار', widget.request.option),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const _TravelHeading('تفاصيل السعر'),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _travelCard(),
          child: Column(
            children: [
              _TravelInvoiceLine(
                'سعر الخدمة',
                '${_travelMoney(widget.subtotal)} ر.ي',
              ),
              const Divider(),
              _TravelInvoiceLine(
                'رسوم المعالجة والحجز',
                '${_travelMoney(serviceFee)} ر.ي',
              ),
              if (insurance > 0) ...[
                const Divider(),
                _TravelInvoiceLine(
                  'تأمين السفر',
                  '${_travelMoney(insurance)} ر.ي',
                ),
              ],
              const Divider(),
              _TravelInvoiceLine(
                'الإجمالي الكلي',
                '${_travelMoney(total)} ر.ي',
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
              Icon(Icons.fact_check_outlined, color: _travelGreen),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'مراجعة قبل التقديم',
                      style: TextStyle(
                        color: _travelGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      'يراجع فريقنا الطلب والوثائق قبل إرسالها للجهة المختصة',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _TravelHeading('اختر طريقة الدفع'),
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
                      ? _travelPurple
                      : const Color(0xffdfd2e9),
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
                        ? _travelPurple
                        : const Color(0xff908696),
                  ),
                  const SizedBox(width: 9),
                  Icon(method.$2, color: _travelViolet),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LocalizedText(
                      method.$1,
                      style: const TextStyle(
                        color: _travelDeep,
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
            color: const Color(0xfff0e8f8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: _travelPurple),
              SizedBox(width: 7),
              Flexible(
                child: LocalizedText(
                  'جميع معاملاتك مشفرة وآمنة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _travelPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _TravelPrimaryButton(
          key: const Key('travel-pay-button'),
          label: 'ادفع الآن • ${_travelMoney(total)} ر.ي',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TravelRequestSuccessScreen(
                listing: widget.listing,
                request: widget.request,
                applicant: widget.applicant,
                method: selectedMethod,
                subtotal: widget.subtotal,
                serviceFee: serviceFee,
                insurance: insurance,
                total: total,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class TravelRequestSuccessScreen extends StatelessWidget {
  const TravelRequestSuccessScreen({
    super.key,
    required this.listing,
    required this.request,
    required this.applicant,
    required this.method,
    required this.subtotal,
    required this.serviceFee,
    required this.insurance,
    required this.total,
  });

  final TravelListing listing;
  final TravelRequestData request;
  final TravelApplicantData applicant;
  final String method;
  final int subtotal;
  final int serviceFee;
  final int insurance;
  final int total;

  String get bookingNumber => '${listing.category.bookingPrefix}-2026-000512';

  @override
  Widget build(BuildContext context) => TravelBookingFrame(
    step: 5,
    title: 'تم استلام طلبك',
    child: ListView(
      key: const Key('travel-success-list'),
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_travelDeep, _travelPurple],
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 37,
                backgroundColor: Colors.white,
                child: Icon(Icons.check_rounded, color: _travelGreen, size: 50),
              ),
              SizedBox(height: 12),
              LocalizedText(
                'تم تأكيد طلبك بنجاح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                'سنرسل لك تحديثات الطلب عبر الهاتف والواتساب',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _TravelSummary(listing: listing),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _travelCard(),
          child: Column(
            children: [
              _TravelInvoiceLine('رقم الطلب', bookingNumber),
              _TravelInvoiceLine('التصنيف', listing.category.label),
              _TravelInvoiceLine('الخدمة', listing.title),
              _TravelInvoiceLine('مقدم الطلب', applicant.name),
              _TravelInvoiceLine('طريقة الدفع', method),
              const _TravelInvoiceLine(
                'حالة الطلب',
                'تم الاستلام ✓',
                success: true,
              ),
              _TravelInvoiceLine(
                'الإجمالي',
                '${_travelMoney(total)} ر.ي',
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _TravelPrimaryButton(
          key: const Key('travel-show-invoice'),
          label: 'عرض الفاتورة وتتبع الطلب',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TravelInvoiceTrackingScreen(
                listing: listing,
                request: request,
                applicant: applicant,
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
              builder: (_) => TravelRatingScreen(listing: listing),
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

class TravelInvoiceTrackingScreen extends StatelessWidget {
  const TravelInvoiceTrackingScreen({
    super.key,
    required this.listing,
    required this.request,
    required this.applicant,
    required this.method,
    required this.subtotal,
    required this.serviceFee,
    required this.insurance,
    required this.total,
    required this.bookingNumber,
  });

  final TravelListing listing;
  final TravelRequestData request;
  final TravelApplicantData applicant;
  final String method;
  final int subtotal;
  final int serviceFee;
  final int insurance;
  final int total;
  final String bookingNumber;

  @override
  Widget build(BuildContext context) => TravelBookingFrame(
    step: 6,
    title: 'الفاتورة وتتبع الطلب',
    child: ListView(
      key: const Key('travel-invoice-list'),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
      children: [
        _TravelSummary(listing: listing),
        const SizedBox(height: 13),
        Row(
          children: [
            const Expanded(
              child: _TravelPill(
                label: 'قيد المراجعة',
                icon: Icons.fact_check_outlined,
                color: _travelGreen,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: LocalizedText(
                'رقم الطلب $bookingNumber',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _travelDeep,
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
            color: const Color(0xffeee5f8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const LocalizedText(
            'تم إرسال الفاتورة ورابط تتبع الطلب إلى رقم الواتساب المسجل',
            textAlign: TextAlign.center,
            style: TextStyle(color: _travelPurple, fontWeight: FontWeight.bold),
          ),
        ),
        const _TravelHeading('حالة الطلب'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: _travelCard(),
          child: const Column(
            children: [
              _TravelTrackingStep(
                title: 'تم استلام الطلب والدفع',
                subtitle: 'اكتملت الخطوة بنجاح',
                complete: true,
              ),
              _TravelTrackingStep(
                title: 'مراجعة البيانات والوثائق',
                subtitle: 'يقوم المختص بمراجعة ملفك الآن',
                active: true,
              ),
              _TravelTrackingStep(
                title: 'التقديم إلى الجهة المختصة',
                subtitle: 'تبدأ بعد اكتمال المراجعة',
              ),
              _TravelTrackingStep(
                title: 'اكتمال الطلب والتسليم',
                subtitle: 'سنبلغك فور صدور النتيجة',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        const _TravelHeading('تفاصيل الطلب'),
        const SizedBox(height: 9),
        _TravelInvoiceGrid(
          entries: [
            ('التصنيف', listing.category.label),
            ('الخدمة', listing.title),
            ('الوجهة', request.destination),
            ('التاريخ', _travelDate(request.startDate)),
            ('عدد المتقدمين', '${request.applicants}'),
            ('الخيار', request.option),
          ],
        ),
        const SizedBox(height: 19),
        const _TravelHeading('بيانات مقدم الطلب'),
        const SizedBox(height: 9),
        _TravelInvoiceGrid(
          entries: [
            ('الاسم', applicant.name),
            ('رقم الهاتف', applicant.phone),
            ('البريد', applicant.email.isEmpty ? 'غير مسجل' : applicant.email),
            ('الجنسية', applicant.nationality),
            ('رقم الوثيقة', applicant.documentNumber),
            ('عدد المستندات', '${listing.requirements.length} مستندات'),
          ],
        ),
        const SizedBox(height: 19),
        const _TravelHeading('تفاصيل الدفع'),
        const SizedBox(height: 9),
        _TravelInvoiceGrid(
          entries: [
            ('طريقة الدفع', method),
            ('سعر الخدمة', '${_travelMoney(subtotal)} ر.ي'),
            ('رسوم المعالجة', '${_travelMoney(serviceFee)} ر.ي'),
            ('التأمين', '${_travelMoney(insurance)} ر.ي'),
            ('الإجمالي', '${_travelMoney(total)} ر.ي'),
            ('حالة الدفع', 'تم الدفع بنجاح'),
          ],
          successIndex: 5,
        ),
        const SizedBox(height: 19),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _travelCard(),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'الفاتورة والتحقق',
                      style: TextStyle(
                        color: _travelDeep,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    LocalizedText('رمز التحقق'),
                    LocalizedText(
                      'TVL20512',
                      key: Key('travel-invoice-code'),
                      style: TextStyle(
                        color: _travelPurple,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _TravelQrPattern(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ServiceCompletionFooter(
          serviceKey: 'سفريات وسياحة',
          serviceName: 'سفريات وسياحة',
          invoiceText:
              'فاتورة ${listing.title}\nرقم الطلب: $bookingNumber\nالإجمالي: ${_travelMoney(total)} ر.ي',
          rateButtonKey: const Key('travel-rate-from-invoice'),
          ratingScreenBuilder: (_) => TravelRatingScreen(listing: listing),
        ),
      ],
    ),
  );
}

class TravelRatingScreen extends StatefulWidget {
  const TravelRatingScreen({super.key, required this.listing});

  final TravelListing listing;

  @override
  State<TravelRatingScreen> createState() => _TravelRatingScreenState();
}

class _TravelRatingScreenState extends State<TravelRatingScreen> {
  int rating = 5;
  final categoryRatings = <String, int>{
    'سهولة الإجراءات': 5,
    'سرعة الإنجاز': 5,
    'التعامل والاحترافية': 5,
    'وضوح التحديثات': 5,
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
      'سفريات وسياحة',
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
      backgroundColor: _travelSurface,
      appBar: AppBar(title: const LocalizedText('تقييم خدمة السفريات')),
      body: SafeArea(
        child: ListView(
          key: const Key('travel-rating-list'),
          padding: const EdgeInsets.all(16),
          children: [
            _TravelSummary(listing: widget.listing),
            const SizedBox(height: 20),
            const LocalizedText(
              'كيف كانت تجربتك؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _travelDeep,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const LocalizedText(
              'تقييمك يساعدنا على تطوير خدمات السفر والمعاملات',
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
                    color: _travelOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...categoryRatings.entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: _travelCard(),
                child: Row(
                  children: [
                    Expanded(
                      child: LocalizedText(
                        entry.key,
                        style: const TextStyle(
                          color: _travelDeep,
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
                            color: _travelOrange,
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
                hintText: l10n('اكتب ملاحظتك عن الخدمة والمكتب...'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xffdfd2e9)),
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
                    Icon(Icons.check_circle_rounded, color: _travelGreen),
                    SizedBox(width: 8),
                    LocalizedText(
                      'تم حفظ تقييمك، شكراً لمشاركتنا تجربتك.',
                      style: TextStyle(
                        color: _travelGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            _TravelPrimaryButton(
              label: saved ? 'تحديث التقييم' : 'إرسال التقييم',
              onPressed: _saveReview,
            ),
          ],
        ),
      ),
    ),
  );
}

class TravelBookingFrame extends StatelessWidget {
  const TravelBookingFrame({
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
      backgroundColor: _travelSurface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 17),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_travelDeep, _travelPurple]),
              ),
              child: Row(
                children: [
                  _TravelRoundButton(
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
                          'سافر والباقي علينا، بخطوات سهلة وآمنة',
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
            _TravelProgress(step: step),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _TravelProgress extends StatelessWidget {
  const _TravelProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['الخدمة', 'الطلب', 'بياناتك', 'الدفع', 'التأكيد', 'التتبع'];
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
                              ? _travelGreen
                              : active
                              ? _travelPurple
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done
                                ? _travelGreen
                                : active
                                ? _travelPurple
                                : const Color(0xffded2e7),
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
                                        : const Color(0xff8c8292),
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
                              ? _travelGreen
                              : active
                              ? _travelPurple
                              : const Color(0xff8a8090),
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
                        ? _travelGreen
                        : const Color(0xffddd1e6),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TravelSummary extends StatelessWidget {
  const _TravelSummary({required this.listing});

  final TravelListing listing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: _travelCard(),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            travelImageAsset,
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
                l10n(listing.title),
                style: const TextStyle(
                  color: _travelDeep,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LocalizedText(
                '${l10n(listing.provider)} • ${l10n(listing.destination)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xff7d7284)),
              ),
              LocalizedText(
                '★ ${listing.rating} ${l10n('ممتاز', 'Excellent')} • ${listing.reviews} ${l10n('تقييم', 'reviews')}',
                style: const TextStyle(
                  color: _travelOrange,
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

class _TravelQuickInfo extends StatelessWidget {
  const _TravelQuickInfo({required this.listing});

  final TravelListing listing;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_travelCategoryIcon(listing.category), listing.category.label),
      (Icons.schedule_rounded, listing.processingTime),
      (Icons.location_on_outlined, listing.destination),
      (Icons.shield_outlined, 'خدمة موثوقة'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.05,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: _travelSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffe2d5ed)),
        ),
        child: Row(
          children: [
            Icon(items[index].$1, color: _travelPurple, size: 21),
            const SizedBox(width: 7),
            Expanded(
              child: LocalizedText(
                l10n(items[index].$2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _travelDeep,
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

class _TravelStringGrid extends StatelessWidget {
  const _TravelStringGrid({required this.values, required this.icon});

  final List<String> values;
  final IconData icon;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 3.15,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: values.length,
    itemBuilder: (_, index) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _travelSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2d5ed)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _travelPurple, size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: LocalizedText(
              l10n(values[index]),
              style: const TextStyle(
                color: _travelDeep,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TravelInput extends StatelessWidget {
  const _TravelInput({
    super.key,
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
      decoration: _travelInputDecoration(icon, label),
    ),
  );
}

class _TravelDateTile extends StatelessWidget {
  const _TravelDateTile({
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
      decoration: _travelCard(),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: _travelPurple),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(l10n(label), style: const TextStyle(fontSize: 11)),
                LocalizedText(
                  l10n(value),
                  style: const TextStyle(
                    color: _travelDeep,
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

class _TravelOptionSwitch extends StatelessWidget {
  const _TravelOptionSwitch({
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
    decoration: _travelCard(),
    child: Row(
      children: [
        const Icon(Icons.sync_alt_rounded, color: _travelPurple),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                l10n(title),
                style: const TextStyle(
                  color: _travelDeep,
                  fontWeight: FontWeight.bold,
                ),
              ),
              LocalizedText(l10n(subtitle)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: _travelPurple,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _TravelCounter extends StatelessWidget {
  const _TravelCounter({
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
    decoration: _travelCard(),
    child: Row(
      children: [
        const Icon(Icons.groups_outlined, color: _travelPurple),
        const SizedBox(width: 9),
        Expanded(
          child: LocalizedText(
            l10n(title),
            style: const TextStyle(
              color: _travelDeep,
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

class _TravelFormField extends StatelessWidget {
  const _TravelFormField({
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
          l10n(label),
          style: const TextStyle(
            color: _travelDeep,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: _travelInputDecoration(icon, l10n(hint)),
        ),
      ],
    ),
  );
}

class _TravelInvoiceLine extends StatelessWidget {
  const _TravelInvoiceLine(
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
            l10n(label),
            style: TextStyle(
              color: highlight ? _travelDeep : const Color(0xff7b7182),
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Flexible(
          child: LocalizedText(
            l10n(value),
            textAlign: TextAlign.end,
            style: TextStyle(
              color: success
                  ? _travelGreen
                  : highlight
                  ? _travelPurple
                  : _travelDeep,
              fontSize: highlight ? 18 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TravelInvoiceGrid extends StatelessWidget {
  const _TravelInvoiceGrid({required this.entries, this.successIndex = -1});

  final List<(String, String)> entries;
  final int successIndex;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 2.05,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: entries.length,
    itemBuilder: (_, index) => Container(
      padding: const EdgeInsets.all(10),
      decoration: _travelCard(radius: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            l10n(entries[index].$1),
            style: const TextStyle(color: Color(0xff807687)),
          ),
          LocalizedText(
            l10n(entries[index].$2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: index == successIndex ? _travelGreen : _travelDeep,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TravelTrackingStep extends StatelessWidget {
  const _TravelTrackingStep({
    required this.title,
    required this.subtitle,
    this.complete = false,
    this.active = false,
    this.last = false,
  });

  final String title;
  final String subtitle;
  final bool complete;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: complete
                  ? _travelGreen
                  : active
                  ? _travelPurple
                  : const Color(0xffebe3ef),
              shape: BoxShape.circle,
            ),
            child: Icon(
              complete
                  ? Icons.check_rounded
                  : active
                  ? Icons.sync_rounded
                  : Icons.circle_outlined,
              color: complete || active
                  ? Colors.white
                  : const Color(0xff998e9d),
              size: 18,
            ),
          ),
          if (!last)
            Container(
              width: 2,
              height: 38,
              color: complete ? _travelGreen : const Color(0xffddd2e5),
            ),
        ],
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                l10n(title),
                style: TextStyle(
                  color: complete || active
                      ? _travelDeep
                      : const Color(0xff8d8391),
                  fontWeight: FontWeight.bold,
                ),
              ),
              LocalizedText(l10n(subtitle)),
            ],
          ),
        ),
      ),
    ],
  );
}

class _TravelHeading extends StatelessWidget {
  const _TravelHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => LocalizedText(
    l10n(label),
    style: const TextStyle(
      color: _travelDeep,
      fontSize: 22,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _TravelPrimaryButton extends StatelessWidget {
  const _TravelPrimaryButton({
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
      backgroundColor: _travelPurple,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 53),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    ),
    child: LocalizedText(l10n(label)),
  );
}

class _TravelRoundButton extends StatelessWidget {
  const _TravelRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 2,
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: _travelPurple),
    ),
  );
}

class _TravelPill extends StatelessWidget {
  const _TravelPill({
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
            l10n(label),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _TravelCondition extends StatelessWidget {
  const _TravelCondition(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: _travelPurple),
        const SizedBox(width: 9),
        Expanded(child: LocalizedText(l10n(text))),
      ],
    ),
  );
}

class _TravelMeta extends StatelessWidget {
  const _TravelMeta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: _travelPurple, size: 19),
        const SizedBox(height: 3),
        LocalizedText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _travelDeep,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _TravelMetaDivider extends StatelessWidget {
  const _TravelMetaDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 35, color: const Color(0xffe1d5ea));
}

class _TravelQrPattern extends StatelessWidget {
  const _TravelQrPattern();

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
        final dark = (row * 7 + column * 3 + row * column) % 4 != 0;
        return ColoredBox(color: dark ? _travelDeep : Colors.white);
      },
    ),
  );
}

class _TravelBottomNav extends StatelessWidget {
  const _TravelBottomNav();

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
          _TravelNavItem(Icons.home_rounded, 'الرئيسية', selected: true),
          _TravelNavItem(Icons.explore_outlined, 'استكشف'),
          _TravelNavItem(Icons.favorite_border_rounded, 'المفضلة'),
          _TravelNavItem(Icons.calendar_month_outlined, 'طلباتي'),
          _TravelNavItem(Icons.more_horiz_rounded, 'المزيد'),
        ],
      ),
    ),
  );
}

class _TravelNavItem extends StatelessWidget {
  const _TravelNavItem(this.icon, this.label, {this.selected = false});

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: selected ? _travelPurple : const Color(0xff93899a)),
        LocalizedText(
          label,
          style: TextStyle(
            color: selected ? _travelPurple : const Color(0xff817788),
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

InputDecoration _travelInputDecoration(IconData icon, String label) =>
    InputDecoration(
      labelText: l10n(label),
      prefixIcon: Icon(icon, color: _travelPurple),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffe0d3ea)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffe0d3ea)),
      ),
    );

BoxDecoration _travelCard({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xffe2d5ed)),
  boxShadow: const [
    BoxShadow(color: Color(0x0d000000), blurRadius: 8, offset: Offset(0, 3)),
  ],
);

IconData _travelCategoryIcon(TravelCategory category) => switch (category) {
  TravelCategory.flights => Icons.flight_takeoff_rounded,
  TravelCategory.touristVisa => Icons.public_rounded,
  TravelCategory.workVisa => Icons.work_outline_rounded,
  TravelCategory.administrative => Icons.assignment_outlined,
};

String _travelActionLabel(TravelCategory category) => switch (category) {
  TravelCategory.flights => 'احجز تذكرتك الآن',
  TravelCategory.touristVisa => 'ابدأ طلب الفيزا السياحية',
  TravelCategory.workVisa => 'ابدأ طلب فيزا العمل',
  TravelCategory.administrative => 'ابدأ المعاملة الآن',
};

String _travelRequestTitle(TravelCategory category) => switch (category) {
  TravelCategory.flights => 'حدد مسار الرحلة والمسافرين',
  TravelCategory.touristVisa => 'بيانات التأشيرة السياحية',
  TravelCategory.workVisa => 'بيانات فيزا العمل',
  TravelCategory.administrative => 'تفاصيل المعاملة الإدارية',
};
