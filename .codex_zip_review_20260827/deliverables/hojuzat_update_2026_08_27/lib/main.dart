import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app/app_services.dart';
import 'core/localization/app_locale.dart';
import 'core/maps/app_map_launcher.dart';
import 'core/reviews/service_review.dart';
import 'features/auth/presentation/app_session.dart';
import 'features/apartments/presentation/apartment_flow.dart';
import 'features/beauty_centers/presentation/beauty_center_flow.dart';
import 'features/catalog/data/control_panel_repository.dart';
import 'features/delivery/presentation/delivery_basket.dart';
import 'features/transport/presentation/transport_flow.dart';
import 'features/halls/presentation/premium_hall_flow.dart';
import 'features/travel/presentation/travel_flow.dart';

const blue = Color(0xff2455e9);
const orange = Color(0xffff9600);
const navy = Color(0xff12345e);

bool _googleSignInInitialized = false;

Future<GoogleSignInAccount> _requestGoogleAccount() async {
  final signIn = GoogleSignIn.instance;
  if (!_googleSignInInitialized) {
    await signIn.initialize();
    _googleSignInInitialized = true;
  }
  if (!signIn.supportsAuthenticate()) {
    throw StateError('Google sign-in is not supported on this device.');
  }
  return signIn.authenticate();
}

/// يمثل هذا النموذج بيانات الخدمة القادمة لاحقاً من لوحة التحكم لكل فندق.
class HotelExtraService {
  const HotelExtraService({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
  });
  final String id;
  final String name;
  final int price;
  final IconData icon;
}

int _moneyValue(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
String _money(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

final appSession = AppSession();

/// نقطة تهيئة الخدمات البعيدة. تبقى الواجهات المحلية الحالية عاملة عندما
/// لا يمرر عنوان API، وتصبح المستودعات البعيدة جاهزة بمجرد تمريره.
final appServices = AppServices.fromEnvironment();

/// سلة التوصيل المحلية؛ تُستبدل لاحقاً بمصدر بيانات السلة في لوحة التحكم.
final deliveryBasket = DeliveryBasket();

final controlPanelRepository = localControlPanelRepository;

/// النصوص الأساسية التي تظهر في مسار الاستخدام اليومي. تُستبدل مستقبلاً
/// بترجمات لوحة التحكم أو ملفات الترجمة دون الحاجة لتغيير الواجهات.
bool get isEnglish => appSession.language == 'English';
TextDirection get appTextDirection =>
    isEnglish ? TextDirection.ltr : TextDirection.rtl;
String tr(String arabic, String english) => isEnglish ? english : arabic;

String localizedProvince(String name) {
  const names = {
    'عدن': 'Aden',
    'سقطرى': 'Socotra',
    'حضرموت': 'Hadramout',
    'إب': 'Ibb',
    'أبين': 'Abyan',
    'البيضاء': 'Al Bayda',
    'الجوف': 'Al Jawf',
    'الحديدة': 'Al Hudaydah',
    'الضالع': 'Al Dhale',
    'المحويت': 'Al Mahwit',
    'المهرة': 'Al Mahrah',
    'تعز': 'Taiz',
    'حجة': 'Hajjah',
    'ذمار': 'Dhamar',
    'ريمة': 'Raymah',
    'شبوة': 'Shabwah',
    'صعدة': 'Saada',
    'صنعاء': 'Sanaa',
    'عمران': 'Amran',
    'لحج': 'Lahij',
    'مأرب': 'Marib',
  };
  return isEnglish ? (names[name] ?? name) : name;
}

String localizedService(String name) {
  const names = {
    'فنادق': 'Hotels',
    'مطاعم': 'Restaurants',
    'التوصيل السريع': 'Quick delivery',
    'شقق مفروشة': 'Furnished apartments',
    'تأجير السيارات والنقل البري والشحن الداخلي':
        'Car rental, land transport & local freight',
    'تأجير سيارات ونقل': 'Car rental & transport',
    'قاعات أفراح ومناسبات': 'Event halls',
    'سفريات وسياحة': 'Travel & tourism',
    'شاليهات': 'Chalets',
    'منتجعات': 'Resorts',
    'مراكز تجميل': 'Beauty centers',
  };
  return isEnglish ? (names[name] ?? name) : name;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSession.load();
  runApp(const HujuzatApp());
}

class HujuzatApp extends StatelessWidget {
  const HujuzatApp({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appSession,
    builder: (_, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: isEnglish ? 'Hujuzatcom' : 'حجوزاتكم',
      locale: Locale(isEnglish ? 'en' : 'ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Directionality(
        textDirection: appTextDirection,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: isEnglish ? null : 'Mohammad',
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xfff4f7ff),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: isEnglish ? null : 'Mohammad',
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: appSession.themeMode,
      home: const WelcomeScreen(),
    ),
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => appSession.isRegistered
                ? const LoginScreen()
                : const ProvincesScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Image.asset('assets/images/welcome.png', fit: BoxFit.cover),
  );
}

final provinces = controlPanelRepository.provinces
    .where((province) => province.enabled)
    .map((province) => province.name)
    .toList(growable: false);

class ProvincesScreen extends StatefulWidget {
  const ProvincesScreen({super.key});
  @override
  State<ProvincesScreen> createState() => _ProvincesScreenState();
}

class _ProvincesScreenState extends State<ProvincesScreen> {
  final controller = PageController(viewportFraction: .82);
  int current = 18;
  void open(String province) => Navigator.push(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: 'services-home'),
      builder: (_) => ServicesScreen(province: province),
    ),
  );
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          children: [
            _top(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
              child: TextField(
                readOnly: true,
                onTap: () => _picker(context),
                decoration: InputDecoration(
                  hintText: tr(
                    'اختر وجهتك القادمة...',
                    'Choose your next destination...',
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: blue,
                    size: 32,
                  ),
                  suffixIcon: const Icon(Icons.mic_rounded, color: blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: provinces.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: ChoiceChip(
                    label: LocalizedText(localizedProvince(provinces[i])),
                    selected: i == current,
                    selectedColor: orange,
                    labelStyle: TextStyle(
                      color: i == current ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() => current = i);
                      controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 227,
              child: PageView.builder(
                controller: controller,
                itemCount: provinces.length,
                onPageChanged: (i) => setState(() => current = i),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => open(provinces[i]),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      image: DecorationImage(
                        image: AssetImage(_imageFor(provinces[i])),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .72),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x54071436),
                          blurRadius: 16,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Container(color: Colors.black12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(11),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .40),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .65),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: LocalizedText(
                              tr(
                                'محافظة ${provinces[i]}',
                                '${localizedProvince(provinces[i])} Governorate',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
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
            ),
            _section(tr('إعلانات وعروض', 'Ads & offers')),
            _ad(
              tr('عروض الفنادق', 'Hotel offers'),
              tr(
                'إقامة فاخرة بأفضل الأسعار',
                'Luxury stays at the best prices',
              ),
              Icons.hotel_rounded,
              () => _adSheet(context, tr('عروض الفنادق', 'Hotel offers')),
            ),
            _ad(
              tr('عروض تأجير السيارات', 'Car rental offers'),
              tr('استمتع بالقيادة براحة وأمان', 'Drive comfortably and safely'),
              Icons.directions_car_filled_rounded,
              () => _adSheet(
                context,
                tr('عروض تأجير السيارات', 'Car rental offers'),
              ),
            ),
            _ad(
              tr('عروض المطاعم الشهية', 'Restaurant offers'),
              tr('أفضل الأجواء والمذاقات', 'Great ambience and flavour'),
              Icons.restaurant_rounded,
              () => _adSheet(
                context,
                tr('عروض المطاعم الشهية', 'Restaurant offers'),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    ),
  );
  Widget _top(BuildContext context) => Container(
    height: 190,
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_imageFor(provinces[current]), fit: BoxFit.cover),
        Container(color: Colors.black26),
        Positioned(
          right: 12,
          top: 12,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white),
              const SizedBox(width: 4),
              LocalizedText(
                localizedProvince(provinces[current]),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 12,
          top: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.notifications_none_rounded, color: blue),
          ),
        ),
      ],
    ),
  );
  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 9),
    child: LocalizedText(
      title,
      style: const TextStyle(
        color: blue,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  Widget _ad(String title, String subtitle, IconData icon, VoidCallback tap) =>
      InkWell(
        onTap: tap,
        child: Container(
          height: 113,
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xff102d75), Color(0xff265ee9)],
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white24,
                child: Icon(icon, color: Colors.white, size: 31),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocalizedText(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const LocalizedText(
                      'احجز الآن',
                      style: TextStyle(
                        color: Colors.white,
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
  void _picker(BuildContext context) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => Directionality(
      textDirection: appTextDirection,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: provinces
            .map(
              (p) => ListTile(
                title: LocalizedText(localizedProvince(p)),
                leading: const Icon(Icons.location_city, color: blue),
                onTap: () {
                  Navigator.pop(context);
                  open(p);
                },
              ),
            )
            .toList(),
      ),
    ),
  );
  void _adSheet(BuildContext context, String title) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => Directionality(
      textDirection: appTextDirection,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              tr(
                'هذه مساحة بيانات الجهة المعلنة. عند الربط بلوحة التحكم ستصل هنا الصورة، الخصم، الوصف، رابط الحجز وبيانات التواصل.',
                'Advertiser details will appear here when the control panel is connected.',
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: LocalizedText(tr('استكشف العرض', 'Explore offer')),
            ),
          ],
        ),
      ),
    ),
  );
  String _imageFor(String p) {
    const files = {
      'عدن': 'عدن.jpg',
      'سقطرى': 'سقطرى.jpg',
      'حضرموت': 'حضرموت.jpg',
      'إب': 'محافظة اب.jpg',
      'أبين': 'محافظة ابين.jpg',
      'البيضاء': 'محافظة البيضاء.jpg',
      'الجوف': 'محافظة الجوف.jpg',
      'الحديدة': 'محافظة الحديدة.jpg',
      'الضالع': 'محافظة الضالع.jpg',
      'المحويت': 'محافظة المحويت.jpg',
      'المهرة': 'محافظة المهرة.jpg',
      'تعز': 'محافظة تعز.jpg',
      'حجة': 'محافظة حجة.jpg',
      'ذمار': 'محافظة ذمار.jpg',
      'ريمة': 'محافظة ريمة.jpg',
      'شبوة': 'محافظة شبوة.jpg',
      'صعدة': 'محافظة صعدة.jpg',
      'صنعاء': 'محافظة صنعاء.jpg',
      'عمران': 'محافظة عمران.jpg',
      'لحج': 'محافظة لحج.jpg',
      'مأرب': 'محافظة مأرب.jpg',
    };
    return 'assets/images/${files[p] ?? 'home_ar.jpg'}';
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, required this.province});
  final String province;
  // كل خدمة تحمل صورة مستقلة؛ تُستبدل هذه المسارات لاحقاً بصور لوحة التحكم.
  static const entries = [
    ('فنادق', Icons.hotel_rounded, 'assets/Services images/الفنادق.jpg'),
    ('مطاعم', Icons.restaurant_rounded, 'assets/Services images/مطاعم.jpg'),
    (
      'التوصيل السريع',
      Icons.two_wheeler_rounded,
      'assets/Services images/التوصيل السريع.jpg',
    ),
    (
      'شقق مفروشة',
      Icons.apartment_rounded,
      'assets/Services images/الشقق المفروشة.jpg',
    ),
    (
      'تأجير السيارات والنقل البري والشحن الداخلي',
      Icons.local_shipping_rounded,
      'assets/Services images/تأجير السيارات والنقل الداخلي.jpg',
    ),
    (
      'قاعات أفراح ومناسبات',
      Icons.celebration_rounded,
      'assets/Services images/قاعات الافراح والمناسبات.jpg',
    ),
    (
      'سفريات وسياحة',
      Icons.flight_rounded,
      'assets/Services images/سفريات وسياحة.jpg',
    ),
    ('شاليهات', Icons.villa_rounded, 'assets/Services images/شاليهات.jpg'),
    (
      'منتجعات',
      Icons.beach_access_rounded,
      'assets/Services images/منتجعات.jpg',
    ),
    (
      'مراكز تجميل',
      Icons.spa_rounded,
      'assets/Services images/مراكز تجميل.jpg',
    ),
  ];
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: navy),
                  ),
                  const Spacer(),
                  LocalizedText(
                    tr(
                      '$province - اليمن',
                      '${localizedProvince(province)} - Yemen',
                    ),
                    style: const TextStyle(
                      color: navy,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: navy,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 189,
              margin: const EdgeInsets.fromLTRB(12, 2, 12, 5),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_provinceImage(), fit: BoxFit.cover),
                  Container(color: Colors.black38),
                  Positioned(
                    bottom: -14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/images/services_banner_internal_logo.png',
                        width: 192,
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: tr(
                    'ابحث عن فندق أو مطعم أو سيارة...',
                    'Search for a hotel, restaurant, or car...',
                  ),
                  prefixIcon: const Icon(Icons.search, color: blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            _serviceGrid(context),
            _roundServices(context),
            _bigAd(context),
            _exclusiveOffers(context),
            _featuredServiceOffers(context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
  Widget _bigAd(BuildContext context) => InkWell(
    onTap: () => _providers(
      context,
      'تأجير السيارات والنقل البري والشحن الداخلي',
    ),
    child: Container(
      height: 150,
      margin: const EdgeInsets.fromLTRB(16, 3, 16, 7),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x36000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/Services images/تأجير السيارات والنقل الداخلي.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xdd102b77), Color(0x44275bea)],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LocalizedText(
                        'خصم حتى 50%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 27,
                        ),
                      ),
                      LocalizedText(
                        'عروض خاصة لتأجير السيارات',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      _OfferButton('احجز الآن'),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: CircleAvatar(
                    backgroundColor: Color(0xccffffff),
                    child: Icon(Icons.favorite, color: Color(0xff8d8d8d)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _exclusiveOffers(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(right: 16, bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: const BoxDecoration(
            color: blue,
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(14),
              left: Radius.circular(4),
            ),
          ),
          child: const LocalizedText(
            'عروض حصرية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      SizedBox(
        height: 248,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            _offerCard(
              context,
              'فندق ماريوت صنعاء',
              'شارع الخمسين',
              '4.6',
              '20,000',
              '30,000',
              'assets/Services images/الفنادق.jpg',
              'احجز الآن',
            ),
            _offerCard(
              context,
              'فندق دار السلام صنعاء',
              'شارع صنعاء القديمة',
              '3.5',
              '15,000',
              '20,000',
              'assets/Services images/الفنادق.jpg',
              'احجز الآن',
            ),
            _offerCard(
              context,
              'مطاعم الخطيب بروستر',
              'شارع الستين',
              '4.9',
              '8,000',
              '10,000',
              'assets/Services images/مطاعم.jpg',
              'اطلب الآن',
            ),
          ],
        ),
      ),
    ],
  );
  Widget _featuredServiceOffers(BuildContext context) {
    final offers = controlPanelRepository.promotions
        .where((item) => item.enabled)
        .take(4)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 9),
          child: LocalizedText(
            'عروض مميزة',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: offers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .82,
          ),
          itemBuilder: (_, index) {
            final offer = offers[index];
            return Card(
              elevation: 6,
              shadowColor: blue.withValues(alpha: .20),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                onTap: () {
                  final service = controlPanelRepository.services.firstWhere(
                    (item) => item.id == offer.serviceId,
                  );
                  _providers(context, service.name);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Image.asset(offer.imagePath, fit: BoxFit.cover),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LocalizedText(
                              offer.title,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            LocalizedText(
                              controlPanelRepository.services
                                  .firstWhere(
                                    (item) => item.id == offer.serviceId,
                                  )
                                  .name,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 10, color: blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _offerCard(
    BuildContext context,
    String title,
    String place,
    String rating,
    String price,
    String oldPrice,
    String image,
    String action,
  ) => InkWell(
    onTap: () => _providers(
      context,
      image.contains('الفنادق') ? 'فنادق' : 'مطاعم',
    ),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 170,
      margin: const EdgeInsets.only(left: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd5dcf0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(image, fit: BoxFit.cover),
                const Positioned(
                  top: 7,
                  right: 7,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xddeeeeee),
                    child: Icon(Icons.favorite, color: Colors.white, size: 21),
                  ),
                ),
                const Positioned(top: 7, left: 7, child: _DiscountBadge()),
                Positioned(
                  bottom: 5,
                  left: 10,
                  right: 10,
                  child: _OfferButton(action),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 4, 9, 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      LocalizedText(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffc400),
                        size: 18,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: orange,
                        size: 15,
                      ),
                      Expanded(
                        child: LocalizedText(
                          place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: LocalizedText(
                            '$price ر.ي',
                            style: const TextStyle(
                              color: blue,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: LocalizedText(
                            '$oldPrice ر.ي',
                            style: const TextStyle(
                              color: Color(0xff8a91a3),
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
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
        ],
      ),
    ),
  );
  Future<void> _providers(BuildContext context, String service) async {
    if (await serviceReviewStore.hasPendingReview(service)) {
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceRatingScreen(
            serviceKey: service,
            serviceName: service,
            isAutomaticPrompt: true,
          ),
        ),
      );
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => service == 'فنادق'
          ? HotelListingsScreen(province: province)
          : service == 'مطاعم'
          ? RestaurantDiscoveryScreen(province: province)
          : service == 'التوصيل السريع'
          ? QuickDeliveryScreen(province: province)
          : service == 'قاعات أفراح ومناسبات'
          ? PremiumHallHomeScreen(province: province)
          : service == 'شاليهات'
          ? ChaletDiscoveryScreen(province: province)
          : service == 'منتجعات'
          ? ResortDiscoveryScreen(province: province)
          : service == 'شقق مفروشة'
          ? ApartmentDiscoveryScreen(
              province: province,
              appBottomNavigationBar: const HujuzatBottomNav(),
            )
          : service == 'مراكز تجميل'
          ? BeautyCenterDiscoveryScreen(province: province)
          : service == 'تأجير السيارات والنقل البري والشحن الداخلي' ||
                service == 'تأجير سيارات ونقل'
          ? TransportDiscoveryScreen(province: province)
          : service == 'سفريات وسياحة'
          ? TravelDiscoveryScreen(province: province)
          : ProvidersScreen(service: service, province: province),
      ),
    );
  }
  String _provinceImage() {
    const files = {
      'عدن': 'عدن.jpg',
      'سقطرى': 'سقطرى.jpg',
      'حضرموت': 'حضرموت.jpg',
      'إب': 'محافظة اب.jpg',
      'أبين': 'محافظة ابين.jpg',
      'البيضاء': 'محافظة البيضاء.jpg',
      'الجوف': 'محافظة الجوف.jpg',
      'الحديدة': 'محافظة الحديدة.jpg',
      'الضالع': 'محافظة الضالع.jpg',
      'المحويت': 'محافظة المحويت.jpg',
      'المهرة': 'محافظة المهرة.jpg',
      'تعز': 'محافظة تعز.jpg',
      'حجة': 'محافظة حجة.jpg',
      'ذمار': 'محافظة ذمار.jpg',
      'ريمة': 'محافظة ريمة.jpg',
      'شبوة': 'محافظة شبوة.jpg',
      'صعدة': 'محافظة صعدة.jpg',
      'صنعاء': 'محافظة صنعاء.jpg',
      'عمران': 'محافظة عمران.jpg',
      'لحج': 'محافظة لحج.jpg',
      'مأرب': 'محافظة مأرب.jpg',
    };
    return 'assets/images/${files[province] ?? 'services.jpg'}';
  }

  Widget _serviceGrid(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(12),
    crossAxisCount: 3,
    childAspectRatio: .78,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    children: List.generate(6, (i) => _serviceTile(context, i)),
  );
  Widget _serviceTile(BuildContext context, int i) => InkWell(
    onTap: () => _providers(context, entries[i].$1),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Image.asset(
                entries[i].$3,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: LocalizedText(
                localizedService(entries[i].$1),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _roundServices(BuildContext context) => SizedBox(
    height: 133,
    child: Row(
      children: List.generate(
        4,
        (i) => Expanded(child: _roundTile(context, i)),
      ),
    ),
  );
  Widget _roundTile(BuildContext context, int i) => InkWell(
    onTap: () => _providers(context, entries[i + 6].$1),
    child: Column(
      children: [
        Container(
          width: 84,
          height: 84,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xffeaf1ff),
            boxShadow: [
              BoxShadow(
                color: Color(0x35000000),
                blurRadius: 12,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(entries[i + 6].$3, fit: BoxFit.cover),
              Container(color: const Color(0x16000000)),
              Center(
                child: Icon(
                  entries[i + 6].$2,
                  color: Colors.white,
                  size: 34,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 5)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: LocalizedText(
            localizedService(entries[i + 6].$1),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OfferButton extends StatelessWidget {
  const _OfferButton(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xff2858e9),
      borderRadius: BorderRadius.circular(5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: LocalizedText(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xff2462e5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalizedText(
          '30%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        LocalizedText(
          'OFF',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 8,
          ),
        ),
      ],
    ),
  );
}

class HujuzatBottomNav extends StatelessWidget {
  const HujuzatBottomNav({super.key, this.selectedIndex = 0});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, tr('الرئيسية', 'Home')),
      (Icons.favorite_rounded, tr('المفضلة', 'Favorites')),
      (Icons.receipt_long_rounded, tr('حجوزاتي', 'Bookings')),
      (Icons.person_rounded, tr('حسابي', 'Account')),
      (Icons.support_agent_rounded, tr('الدعم', 'Support')),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff5423a8), Color(0xff2858e9), Color(0xff143ec5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x42000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(
              items.length,
              (i) => Expanded(
                child: InkWell(
                  onTap: () {
                    if (i == 0) {
                      Navigator.of(context).popUntil(
                        (route) =>
                            route.settings.name == 'services-home' ||
                            route.isFirst,
                      );
                    } else {
                      final page = switch (i) {
                        1 => const FavoritesScreen(),
                        2 => const MyBookingsScreen(),
                        3 => const AccountScreen(),
                        _ => const SupportScreen(),
                      };
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => page),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? Colors.white.withValues(alpha: .20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      border: i == selectedIndex
                          ? Border.all(
                              color: Colors.white.withValues(alpha: .46),
                            )
                          : null,
                      boxShadow: i == selectedIndex
                          ? const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].$1, color: Colors.white, size: 22),
                        const SizedBox(height: 1),
                        LocalizedText(
                          items[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: i == selectedIndex
                                ? const Color(0xffffd94a)
                                : Colors.white,
                            fontSize: 9,
                            fontWeight: i == selectedIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final note = TextEditingController();
  int tab = 0;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _saveMessage() {
    if (note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(tr('اكتب ملاحظتك أولاً.', 'Write your note first.')),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LocalizedText(
          tr(
            'تم حفظ رسالتك لتُرسل للإدارة عند ربط مركز الدعم.',
            'Your message is ready to be sent when support is connected.',
          ),
        ),
      ),
    );
    setState(note.clear);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      appBar: AppBar(
        title: LocalizedText(tr('الدعم والخط الساخن', 'Support & hotline')),
      ),
      bottomNavigationBar: const HujuzatBottomNav(selectedIndex: 4),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff12345e), Color(0xff2858e9)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                  const SizedBox(height: 8),
                  LocalizedText(
                    tr('كيف يمكننا مساعدتك؟', 'How can we help?'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LocalizedText(
                    tr(
                      'اختر وسيلة التواصل المناسبة لك',
                      'Choose your preferred way to contact us',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: LocalizedText(tr('رسالة مباشرة', 'Direct message')),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.chat_rounded),
                  label: const LocalizedText('WhatsApp'),
                ),
                ButtonSegment(
                  value: 2,
                  icon: const Icon(Icons.call_rounded),
                  label: LocalizedText(tr('اتصال', 'Call')),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (value) => setState(() => tab = value.first),
            ),
            const SizedBox(height: 14),
            if (tab == 0) ...[
              LocalizedText(
                tr('رسالة إلى الإدارة', 'Message to administration'),
                style: const TextStyle(
                  fontSize: 19,
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _whiteCard(),
                child: Column(
                  children: [
                    TextField(
                      controller: note,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: tr(
                          'اكتب أي ملاحظة أو شكوى أو اقتراح...',
                          'Write a note, complaint, or suggestion...',
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveMessage,
                        icon: const Icon(Icons.send_rounded),
                        label: LocalizedText(
                          tr('إرسال إلى الإدارة', 'Send to administration'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              LocalizedText(
                tab == 1
                    ? tr('أرقام واتساب للدعم', 'WhatsApp support numbers')
                    : tr('أرقام مركز الاتصال', 'Call-center numbers'),
                style: const TextStyle(
                  fontSize: 19,
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  decoration: _whiteCard(),
                  child: ListTile(
                    leading: Icon(
                      tab == 1 ? Icons.chat_rounded : Icons.call_rounded,
                      color: tab == 1 ? const Color(0xff25d366) : blue,
                    ),
                    title: LocalizedText(
                      tab == 1
                          ? 'WhatsApp ${index + 1}'
                          : '${tr('مركز الاتصال', 'Call center')} ${index + 1}',
                    ),
                    subtitle: LocalizedText(
                      tr(
                        'سيُضاف الرقم من لوحة التحكم',
                        'Number will be added from the control panel',
                      ),
                    ),
                    trailing: const Icon(
                      Icons.settings_suggest_rounded,
                      color: blue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class HotelListingsScreen extends StatefulWidget {
  const HotelListingsScreen({super.key, required this.province});
  final String province;
  @override
  State<HotelListingsScreen> createState() => _HotelListingsScreenState();
}

class _HotelListingsScreenState extends State<HotelListingsScreen> {
  int selectedFilter = 0;
  static const _hotels = [
    ('فندق ماريوت صنعاء', 'شارع الخمسين - صنعاء', '4.6', '20,000', 1.8, 2010),
    ('فندق موفنبيك صنعاء', 'شارع الزبيري - صنعاء', '4.8', '26,000', 4.1, 2024),
    (
      'فندق البوابة الملكية',
      'شارع الخمسين - صنعاء',
      '4.5',
      '18,000',
      2.4,
      2021,
    ),
    (
      'فندق دار السلام صنعاء',
      'صنعاء القديمة - صنعاء',
      '4.9',
      '15,000',
      5.5,
      2025,
    ),
    ('فندق بلازا صنعاء', 'شارع حدة - صنعاء', '4.3', '14,000', 3.2, 2023),
  ];
  List<(String, String, String, String, double, int)> get _orderedHotels {
    final hotels = List<(String, String, String, String, double, int)>.from(
      _hotels,
    );
    if (selectedFilter == 0) hotels.sort((a, b) => a.$5.compareTo(b.$5));
    if (selectedFilter == 1) hotels.sort((a, b) => b.$6.compareTo(a.$6));
    if (selectedFilter == 2) {
      hotels.sort(
        (a, b) => int.parse(
          a.$4.replaceAll(',', ''),
        ).compareTo(int.parse(b.$4.replaceAll(',', ''))),
      );
    }
    if (selectedFilter == 3) {
      hotels.sort((a, b) => double.parse(b.$3).compareTo(double.parse(a.$3)));
    }
    return hotels;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: navy),
                ),
                const Spacer(),
                LocalizedText(
                  'فنادق ${widget.province}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: navy,
                  ),
                ),
              ],
            ),
            Container(
              height: 205,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/hotel_booking_banner.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              decoration: InputDecoration(
                hintText: l10n('إبحث عن فندق وأكثر...'),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: blue,
                  size: 30,
                ),
                suffixIcon: const Icon(Icons.mic_rounded, color: blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xffd6dced)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _HotelFilter(
                    'الأقرب إليك',
                    Icons.location_on_rounded,
                    selected: selectedFilter == 0,
                    onTap: () => setState(() => selectedFilter = 0),
                  ),
                  _HotelFilter(
                    'المفتتح حديثاً',
                    Icons.new_releases_rounded,
                    selected: selectedFilter == 1,
                    onTap: () => setState(() => selectedFilter = 1),
                  ),
                  _HotelFilter(
                    'الأقل سعراً',
                    Icons.price_check_rounded,
                    selected: selectedFilter == 2,
                    onTap: () => setState(() => selectedFilter = 2),
                  ),
                  _HotelFilter(
                    'الأعلى تقييماً',
                    Icons.star_rounded,
                    selected: selectedFilter == 3,
                    onTap: () => setState(() => selectedFilter = 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._orderedHotels.map(
              (hotel) => _hotelCard(
                context,
                hotel.$1,
                hotel.$2,
                hotel.$3,
                hotel.$4,
                'assets/Services images/الفنادق.jpg',
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, color: blue),
                  SizedBox(width: 6),
                  LocalizedText(
                    'أسعار موثوقة وحجز آمن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffa28078),
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

  Widget _hotelCard(
    BuildContext context,
    String title,
    String address,
    String rating,
    String price,
    String image,
  ) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelDetailScreen(
          title: title,
          address: address,
          price: price,
          image: image,
        ),
      ),
    ),
    borderRadius: BorderRadius.circular(17),
    child: Container(
      height: 164,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffd8dbe5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              height: double.infinity,
            ),
          ),
          Expanded(
            flex: 13,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 11, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: const [
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 22,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 22,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 22,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 22,
                      ),
                      Icon(
                        Icons.star_border_rounded,
                        color: Color(0xffffbe00),
                        size: 22,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: orange,
                        size: 18,
                      ),
                      Expanded(
                        child: LocalizedText(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffc23b),
                        size: 18,
                      ),
                      LocalizedText(
                        '$rating ممتاز',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotelDetailScreen(
                            title: title,
                            address: address,
                            price: price,
                            image: image,
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff498ae2),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const LocalizedText(
                        'احجز الآن',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 15, 4, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: LocalizedText(
                      '$price ر.ي',
                      maxLines: 1,
                      style: const TextStyle(
                        color: blue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const LocalizedText(
                    'لكل ليلة',
                    style: TextStyle(
                      color: Color(0xff8b96ae),
                      fontSize: 12,
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

class _HotelFilter extends StatelessWidget {
  const _HotelFilter(
    this.label,
    this.icon, {
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(11),
    child: Container(
      margin: const EdgeInsets.only(left: 9),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffe9efff) : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: selected ? blue : const Color(0xffd6d9e2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: icon == Icons.star_rounded ? const Color(0xffffc23b) : blue,
            size: 20,
          ),
          const SizedBox(width: 5),
          LocalizedText(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? blue : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}

class HotelDetailScreen extends StatelessWidget {
  const HotelDetailScreen({
    super.key,
    required this.title,
    required this.address,
    required this.price,
    required this.image,
  });
  final String title;
  final String address;
  final String price;
  final String image;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            SizedBox(
              height: 245,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(image, fit: BoxFit.cover),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0x77000000), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 14,
                    child: _RoundAction(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 72,
                    child: _RoundAction(
                      icon: Icons.share_rounded,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: LocalizedText('مشاركة الفندق قيد التجهيز'),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    child: _RoundAction(
                      icon: Icons.favorite_border_rounded,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: LocalizedText('تمت إضافة الفندق إلى المفضلة'),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 12,
                    right: 16,
                    child: Row(
                      children: [
                        Icon(Icons.photo_library_outlined, color: Colors.white),
                        SizedBox(width: 4),
                        LocalizedText(
                          '1/10',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n('إبحث عن نوع الغرفة أو الطيرمانة...'),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: blue,
                    size: 30,
                  ),
                  suffixIcon: const Icon(Icons.mic_rounded, color: blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LocalizedText(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xffd8dce8)),
                        ),
                        child: const LocalizedText(
                          '4.6 ممتاز ⭐',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 23,
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 23,
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 23,
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffbe00),
                        size: 23,
                      ),
                      const Icon(
                        Icons.star_border_rounded,
                        color: Color(0xffffbe00),
                        size: 23,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: orange),
                      LocalizedText(
                        address,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _HotelFacilities(
              onOpenServices: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HotelServicesScreen(
                    roomName: 'غرفة ديلوكس',
                    price: price,
                    image: image,
                  ),
                ),
              ),
              onOpenMap: () => showModalBottomSheet(
                context: context,
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: LocalizedText(
                    'سيتم فتح خريطة Google وعرض الفنادق القريبة بعد إضافة مفتاح Google Maps ورابط الربط الرسمي.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 7),
              child: Align(
                alignment: Alignment.centerRight,
                child: LocalizedText(
                  '• خيارات متاحة :',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ),
            ),
            _roomCard(context, 'غرفة ديلوكس', '20,000', image, const [
              Icons.king_bed_rounded,
              Icons.wifi_rounded,
              Icons.shower_rounded,
            ]),
            _roomCard(context, 'غرفة عائلية', '20,000', image, const [
              Icons.bed_rounded,
              Icons.wifi_rounded,
              Icons.bathtub_rounded,
            ]),
            _roomCard(context, 'جناح متكامل', '20,000', image, const [
              Icons.weekend_rounded,
              Icons.wifi_rounded,
              Icons.local_laundry_service_rounded,
            ]),
            _roomCard(context, 'غرفة جماعية', '30,000', image, const [
              Icons.bedroom_parent_rounded,
              Icons.wifi_rounded,
              Icons.shower_rounded,
            ]),
          ],
        ),
      ),
    ),
  );

  Widget _roomCard(
    BuildContext context,
    String name,
    String amount,
    String roomImage,
    List<IconData> amenities,
  ) => Container(
    height: 154,
    margin: const EdgeInsets.fromLTRB(15, 4, 15, 8),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xffd9dce5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 112,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(roomImage, fit: BoxFit.cover),
              const Positioned(
                top: 7,
                right: 7,
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: amenities
                      .map(
                        (icon) => Icon(
                          icon,
                          color: const Color(0xff416bc5),
                          size: 25,
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: LocalizedText('تم التحقق من توفر $name')),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xff4b8fe4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: LocalizedText(
                        'تحقق من التوفر',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 119,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 17, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    alignment: Alignment.centerRight,
                    fit: BoxFit.scaleDown,
                    child: LocalizedText(
                      name,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                LocalizedText(
                  amount,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const LocalizedText(
                  'ريال/ليلة',
                  style: TextStyle(
                    color: Color(0xff8e99b3),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomBookingScreen(
                          roomName: name,
                          price: amount,
                          image: roomImage,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff7180a5),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: LocalizedText(
                        'احجز الآن',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(28),
    child: CircleAvatar(
      radius: 25,
      backgroundColor: Colors.white,
      child: Icon(icon, color: blue, size: 29),
    ),
  );
}

class _HotelFacilities extends StatelessWidget {
  const _HotelFacilities({
    required this.onOpenServices,
    required this.onOpenMap,
  });
  final VoidCallback onOpenServices;
  final VoidCallback onOpenMap;
  @override
  Widget build(BuildContext context) {
    const facilities = [
      (Icons.map_rounded, 'موقع الفندق'),
      (Icons.shower_rounded, 'مياه ساخنة'),
      (Icons.wifi_rounded, 'واي فاي مجاني'),
      (Icons.pool_rounded, 'مسبح'),
      (Icons.apps_rounded, 'المرافق والخدمات'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 8, 15, 0),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2a000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          facilities.length,
          (i) => Expanded(
            child: InkWell(
              onTap: i == 0
                  ? onOpenMap
                  : i == 4
                  ? onOpenServices
                  : null,
              child: Column(
                children: [
                  Icon(
                    facilities[i].$1,
                    color: const Color(0xff3a61b7),
                    size: 29,
                  ),
                  LocalizedText(
                    facilities[i].$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
  });
  final String roomName;
  final String price;
  final String image;
  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  int adults = 2;
  int children = 0;
  final selectedPreviewServices = <String>{};
  static const previewServices = [
    ('توصيل من المطار', Icons.airport_shuttle_rounded, 10000),
    ('وجبة الغداء', Icons.restaurant_rounded, 6000),
    ('ساونا وجاكوزي', Icons.hot_tub_rounded, 2000),
    ('صالة رياضية', Icons.fitness_center_rounded, 3000),
    ('منتجع صحي', Icons.spa_rounded, 8000),
    ('مسبح', Icons.pool_rounded, 2000),
  ];
  int get previewServicesTotal => previewServices
      .where((service) => selectedPreviewServices.contains(service.$1))
      .fold(0, (total, service) => total + service.$3);
  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 1,
    title: widget.roomName,
    image: widget.image,
    child: Column(
      children: [
        _bookingInfoGrid([
          ('تاريخ الوصول', 'الخميس 2026/5/22', Icons.calendar_month_rounded),
          ('تاريخ المغادرة', 'الجمعة 2026/5/23', Icons.calendar_month_rounded),
          ('عدد الليالي', '1', Icons.nights_stay_rounded),
          ('نوع السرير', 'سرير مزدوج', Icons.bed_rounded),
        ]),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _counter(
                'البالغين',
                adults,
                Icons.people_rounded,
                () => setState(() => adults++),
                () => setState(() => adults = adults > 1 ? adults - 1 : 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _counter(
                'الأطفال',
                children,
                Icons.child_care_rounded,
                () => setState(() => children++),
                () =>
                    setState(() => children = children > 0 ? children - 1 : 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _BookingSectionTitle('الخدمات المضافة'),
        _servicePreview(),
        const SizedBox(height: 10),
        _bookingTotals(),
        const SizedBox(height: 10),
        _BookingButton(
          'اختيار الخدمات والمرافق',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HotelServicesScreen(
                roomName: widget.roomName,
                price: widget.price,
                image: widget.image,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _counter(
    String label,
    int value,
    IconData icon,
    VoidCallback plus,
    VoidCallback minus,
  ) => Container(
    padding: const EdgeInsets.all(10),
    decoration: _whiteCard(),
    child: Column(
      children: [
        Icon(icon, color: blue),
        LocalizedText(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: minus,
              icon: const Icon(Icons.remove_circle_outline, color: blue),
            ),
            LocalizedText(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: plus,
              icon: const Icon(Icons.add_circle, color: blue),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _servicePreview() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    crossAxisSpacing: 7,
    mainAxisSpacing: 7,
    children:
        previewServices
            .map(
              (service) => InkWell(
                onTap: () => setState(() {
                  selectedPreviewServices.contains(service.$1)
                      ? selectedPreviewServices.remove(service.$1)
                      : selectedPreviewServices.add(service.$1);
                }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff0757bd),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(service.$2, color: Colors.white, size: 27),
                      LocalizedText(
                        service.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      LocalizedText(
                        '${_money(service.$3)} ر.ي',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(
                        selectedPreviewServices.contains(service.$1)
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: Colors.white70,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
  );
  Widget _bookingTotals() {
    final roomTotal = _moneyValue(widget.price);
    final grandTotal = roomTotal + previewServicesTotal;
    return Container(
    padding: const EdgeInsets.all(12),
    decoration: _whiteCard(),
    child: Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText('تكلفة الغرفة'),
            LocalizedText('حسب الغرفة', style: TextStyle(color: blue, fontWeight: FontWeight.bold)),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText('تكلفة الخدمات المضافة'),
            LocalizedText(
              '${_money(previewServicesTotal)} ر.ي',
              style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText(
              'الإجمالي العام',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            LocalizedText(
              '${_money(grandTotal)} ر.ي',
              style: const TextStyle(
                color: blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  }
}

class HotelServicesScreen extends StatefulWidget {
  const HotelServicesScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
  });
  final String roomName;
  final String price;
  final String image;
  @override
  State<HotelServicesScreen> createState() => _HotelServicesScreenState();
}

class _HotelServicesScreenState extends State<HotelServicesScreen> {
  final selected = <String>{};
  // تُحمّل هذه القوائم لاحقاً من لوحة التحكم بحسب الفندق بدلاً من هذه البيانات التجريبية.
  // مصدر تجريبي مطابق لشكل بيانات لوحة التحكم: المعرّف، الاسم، السعر والأيقونة.
  // عند الربط تستبدل هذه القائمة بخدمات الفندق المختار القادمة من الواجهة البرمجية.
  final services = const [
    HotelExtraService(
      id: 'airport',
      name: 'توصيل من وإلى المطار',
      price: 10000,
      icon: Icons.airport_shuttle_rounded,
    ),
    HotelExtraService(
      id: 'lunch',
      name: 'وجبة الغداء',
      price: 6000,
      icon: Icons.restaurant_rounded,
    ),
    HotelExtraService(
      id: 'pool',
      name: 'مسبح',
      price: 2000,
      icon: Icons.pool_rounded,
    ),
    HotelExtraService(
      id: 'spa',
      name: 'منتجع صحي',
      price: 8000,
      icon: Icons.spa_rounded,
    ),
    HotelExtraService(
      id: 'gym',
      name: 'صالة رياضية',
      price: 3000,
      icon: Icons.fitness_center_rounded,
    ),
    HotelExtraService(
      id: 'sauna',
      name: 'ساونا وجاكوزي',
      price: 2000,
      icon: Icons.hot_tub_rounded,
    ),
    HotelExtraService(
      id: 'car',
      name: 'سيارة خاصة',
      price: 12000,
      icon: Icons.directions_car_rounded,
    ),
    HotelExtraService(
      id: 'bed',
      name: 'سرير إضافي',
      price: 5000,
      icon: Icons.bed_rounded,
    ),
  ];
  final generalFacilities = const [
    ('ممر ذوو الاحتياجات', Icons.accessible_rounded),
    ('التوصيل من وإلى المطار', Icons.flight_rounded),
    ('موقف سيارات', Icons.local_parking_rounded),
    ('إنترنت عالي السرعة', Icons.wifi_rounded),
    ('استقبال 24/7', Icons.support_agent_rounded),
    ('كاميرات مراقبة', Icons.videocam_rounded),
    ('مرافق عامة نظيفة', Icons.cleaning_services_rounded),
    ('حرّاس أمن مشددة', Icons.security_rounded),
    ('قاعة مناسبات', Icons.storefront_rounded),
    ('بوفيه للإفطار والعشاء', Icons.restaurant_rounded),
    ('مغسلة ملابس', Icons.local_laundry_service_rounded),
    ('خدمة توصيل', Icons.delivery_dining_rounded),
    ('صالة انتظار فاخرة', Icons.weekend_rounded),
    ('مصاعد حديثة', Icons.elevator_rounded),
    ('خدمة غرف 24 ساعة', Icons.room_service_rounded),
    ('خزنة عامة', Icons.lock_rounded),
  ];
  final roomFacilities = const [
    ('سرير مريح', Icons.bed_rounded),
    ('واي فاي قوي', Icons.wifi_rounded),
    ('تكييف مركزي', Icons.ac_unit_rounded),
    ('تلفاز ذكي', Icons.tv_rounded),
    ('خزنة آمنة', Icons.lock_rounded),
    ('إضاءة مريحة', Icons.lightbulb_outline_rounded),
    ('خدمة غرف 24 ساعة', Icons.room_service_rounded),
    ('مستلزمات استحمام', Icons.bathtub_rounded),
    ('مكتب للأعمال', Icons.desk_rounded),
    ('هاتف للخدمات', Icons.phone_in_talk_rounded),
    ('ستائر معتمة', Icons.curtains_rounded),
    ('استبدال يومي', Icons.cleaning_services_rounded),
  ];
  final recreationFacilities = const [
    ('مسبح', Icons.pool_rounded),
    ('منتجع صحي', Icons.spa_rounded),
    ('صالة رياضية', Icons.fitness_center_rounded),
    ('قاعات مؤتمرات', Icons.groups_rounded),
    ('مطاعم متنوعة', Icons.restaurant_rounded),
    ('ساونا وجاكوزي', Icons.hot_tub_rounded),
    ('ملاعب رياضية', Icons.sports_soccer_rounded),
    ('كافيه شيشة', Icons.local_cafe_rounded),
    ('مركز دعم الأعمال', Icons.business_center_rounded),
    ('طباعة وتصوير', Icons.print_rounded),
    ('اجتماعات خاصة', Icons.meeting_room_rounded),
    ('مساعدة تنظيم الفعاليات', Icons.support_agent_rounded),
  ];
  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 1,
    title: 'الخدمات والمرافق',
    image: widget.image,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _facilityGrid('الخدمات والمرافق العامة', generalFacilities),
        const SizedBox(height: 10),
        _facilityGrid('وسائل الراحة في الغرفة', roomFacilities),
        const SizedBox(height: 10),
        _facilityGrid('وسائل الترفيه الفندقي', recreationFacilities),
        const SizedBox(height: 10),
        const _BookingSectionTitle('الخدمات الإضافية للحجز'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.02,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7,
          children: services.map((service) {
            final isSelected = selected.contains(service.id);
            return InkWell(
              onTap: () => setState(
                () => isSelected
                    ? selected.remove(service.id)
                    : selected.add(service.id),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? blue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: blue),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      service.icon,
                      color: isSelected ? Colors.white : blue,
                      size: 25,
                    ),
                    const SizedBox(height: 3),
                    LocalizedText(
                      service.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      '${_money(service.price)} ر.ي',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 142,
          child: Row(
            children: [
              Expanded(
                child: _infoPanel('أوقات العمل', const [
                  'استقبال وخدمات: 24 ساعة',
                  'تسجيل الوصول: 3:00 مساءً',
                  'تسجيل المغادرة: 12:00 ظهراً',
                ], Icons.schedule_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoPanel('سياستنا', const [
                  'ضيافة بمعايير عالية',
                  'نظافة وسلامة على مدار الساعة',
                  'رضا الضيف هدفنا',
                ], Icons.verified_user_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoPanel('طرق الدفع', const [
                  'جوالى • جيب • فلوسك',
                  'بطاقات فيزا وماستر',
                ], Icons.account_balance_wallet_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        _BookingButton('متابعة طلب الحجز (${selected.length} خدمات)', () {
          final selectedServices = services
              .where((service) => selected.contains(service.id))
              .toList();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingRequestScreen(
                roomName: widget.roomName,
                price: widget.price,
                image: widget.image,
                services: selectedServices,
              ),
            ),
          );
        }),
      ],
    ),
  );

  Widget _facilityGrid(
    String title,
    List<(String, IconData)> facilities,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _BookingSectionTitle(title),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: _whiteCard(),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: .78,
          crossAxisSpacing: 6,
          mainAxisSpacing: 7,
          children: facilities
              .map(
                (facility) => InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: LocalizedText('${facility.$1} متوفرة في الفندق')),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(facility.$2, color: Colors.white, size: 27),
                      ),
                      const SizedBox(height: 3),
                      LocalizedText(
                        facility.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const LocalizedText(
                        'مجانية',
                        style: TextStyle(
                          fontSize: 8,
                          color: Color(0xff15935f),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );

  Widget _infoPanel(String title, List<String> lines, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(7),
        decoration: _whiteCard(),
        child: Column(
          children: [
            Icon(icon, color: blue, size: 26),
            const SizedBox(height: 3),
            LocalizedText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
            ),
            const SizedBox(height: 4),
            ...lines.map(
              (line) => LocalizedText(
                line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: title == 'سياستنا' ? 7.3 : 8.3),
              ),
            ),
          ],
        ),
      );
}

class BookingRequestScreen extends StatelessWidget {
  const BookingRequestScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
    required this.services,
  });
  final String roomName;
  final String price;
  final String image;
  final List<HotelExtraService> services;
  int get roomTotal => _moneyValue(price);
  int get servicesTotal =>
      services.fold(0, (sum, service) => sum + service.price);
  int get grandTotal => roomTotal + servicesTotal;
  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 2,
    title: 'طلب الحجز',
    image: image,
    child: Column(
      children: [
        const _BookingSectionTitle('ملخص الحجز'),
        _bookingInfoGrid([
          ('الغرفة', roomName, Icons.bed_rounded),
          ('الوصول', '2026/5/22', Icons.calendar_month_rounded),
          ('المغادرة', '2026/5/23', Icons.calendar_month_rounded),
          ('الأشخاص', '2 بالغين', Icons.people_rounded),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: _whiteCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LocalizedText(
                'الخدمات المختارة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 7),
              if (services.isEmpty)
                const LocalizedText('لا توجد خدمات إضافية')
              else
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(service.icon, color: blue, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: LocalizedText(service.name)),
                        LocalizedText(
                          '${_money(service.price)} ر.ي',
                          style: const TextStyle(
                            color: blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(),
              _summaryRow('تكلفة الغرفة', '${_money(roomTotal)} ر.ي'),
              _summaryRow('تكلفة الخدمات', '${_money(servicesTotal)} ر.ي'),
              const Divider(),
              _summaryRow(
                'الإجمالي المتوقع',
                '${_money(grandTotal)} ر.ي',
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _BookingButton('إدخال بيانات الحجز', () {
          // الزائر يسجل قبل متابعة الحجز، والمستخدم المسجل لا يستطيع تجاوزه
          // إلا بعد تحقق الدخول في هذه الجلسة.
          final page = !appSession.isRegistered
              ? SignUpScreen(
                  roomName: roomName,
                  price: price,
                  image: image,
                  services: services,
                )
              : !appSession.isAuthenticated
              ? const LoginScreen()
              : GuestDetailsScreen(
                  roomName: roomName,
                  price: price,
                  image: image,
                  services: services,
                );
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }),
      ],
    ),
  );

  Widget _summaryRow(String label, String value, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText(
              label,
              style: TextStyle(
                fontSize: strong ? 17 : 14,
                fontWeight: strong ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            LocalizedText(
              value,
              style: TextStyle(
                fontSize: strong ? 18 : 14,
                color: blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
    this.services = const [],
    this.restaurantFlow = false,
    this.tableBooking = false,
    this.nextScreen,
  });
  final String roomName;
  final String price;
  final String image;
  final List<HotelExtraService> services;
  final bool restaurantFlow;
  final bool tableBooking;
  final Widget? nextScreen;
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool agree = false;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('يرجى الموافقة على الأحكام وسياسة الخصوصية'),
        ),
      );
      return;
    }
    if (formKey.currentState!.validate()) {
      await appSession.register(
        name: name.text.trim(),
        mobile: phone.text.trim(),
      );
      if (!mounted) return;
      if (widget.nextScreen != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => widget.nextScreen!),
        );
      } else if (widget.restaurantFlow) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantConfirmationScreen(
              tableBooking: widget.tableBooking,
              image: widget.image,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuestDetailsScreen(
              roomName: widget.roomName,
              price: widget.price,
              image: widget.image,
              services: widget.services,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/signup_background.png', fit: BoxFit.cover),
          Container(color: Colors.white.withValues(alpha: .30)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo_transparent.png',
                    width: 230,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .84),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        LocalizedText(
                          tr('إنشاء حساب جديد', 'Create account'),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LocalizedText(
                          tr('مرحباً بك في حجوزاتكم', 'Welcome to Hujuzatcom'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff6057bc),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _signupField(
                          name,
                          tr('الاسم الكامل', 'Full name'),
                          Icons.person_outline,
                          (v) => v == null || v.trim().isEmpty
                              ? tr('الاسم مطلوب', 'Name is required')
                              : null,
                        ),
                        _signupField(
                          phone,
                          tr('رقم الهاتف', 'Phone number'),
                          Icons.phone_android_rounded,
                          (v) => v == null || v.trim().length < 7
                              ? tr(
                                  'رقم هاتف صحيح مطلوب',
                                  'A valid phone number is required',
                                )
                              : null,
                          type: TextInputType.phone,
                        ),
                        _signupField(
                          password,
                          tr('كلمة المرور', 'Password'),
                          Icons.lock_outline,
                          (v) => v == null || v.length < 6
                              ? tr('6 أحرف على الأقل', 'At least 6 characters')
                              : null,
                          obscure: true,
                        ),
                        CheckboxListTile(
                          value: agree,
                          onChanged: (v) => setState(() => agree = v ?? false),
                          title: LocalizedText(
                            tr(
                              'أوافق على الأحكام والشروط وسياسة الخصوصية',
                              'I agree to the terms and privacy policy',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 8),
                        _BookingButton(
                          tr(
                            'إنشاء حساب واستكمال الحجز',
                            'Create account and continue',
                          ),
                          submit,
                        ),
                        const SizedBox(height: 10),
                        LocalizedText(
                          tr(
                            'لديك حساب بالفعل؟ تسجيل الدخول',
                            'Already have an account? Sign in',
                          ),
                          style: const TextStyle(
                            color: blue,
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
        ],
      ),
    ),
  );
  Widget _signupField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType? type,
    bool obscure = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: l10n(label),
        prefixIcon: Icon(icon, color: blue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class GuestDetailsScreen extends StatefulWidget {
  const GuestDetailsScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
    this.services = const [],
  });
  final String roomName;
  final String price;
  final String image;
  final List<HotelExtraService> services;
  @override
  State<GuestDetailsScreen> createState() => _GuestDetailsScreenState();
}

class _GuestDetailsScreenState extends State<GuestDetailsScreen> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  final emailController = TextEditingController();
  final additionalGuests = <int>[];
  int nextGuestId = 1;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: appSession.displayName);
    phoneController = TextEditingController(text: appSession.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 2,
    title: 'إدخال البيانات',
    image: widget.image,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BookingSectionTitle('معلومات الحجز'),
        _bookingInfoGrid([
          ('تاريخ الوصول', '2026/5/22', Icons.calendar_month_rounded),
          ('تاريخ المغادرة', '2026/5/23', Icons.calendar_month_rounded),
          ('مدة الإقامة', 'ليلة واحدة', Icons.nights_stay_rounded),
          ('عدد الأشخاص', '2 بالغين', Icons.people_rounded),
        ]),
        const SizedBox(height: 12),
        const _BookingSectionTitle('المعلومات الشخصية'),
        _formField(
          'الاسم الكامل',
          Icons.person_outline,
          controller: nameController,
        ),
        _formField(
          'رقم الجوال (مفضل عليه الواتساب)',
          Icons.phone_rounded,
          type: TextInputType.phone,
          controller: phoneController,
        ),
        _formField(
          'البريد الإلكتروني (اختياري)',
          Icons.email_outlined,
          type: TextInputType.emailAddress,
          controller: emailController,
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _whiteCard(),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: l10n('الجنسية'),
              prefixIcon: Icon(Icons.public_rounded, color: blue),
              border: InputBorder.none,
            ),
            items: const [
              DropdownMenuItem(value: 'يمني', child: LocalizedText('يمني')),
              DropdownMenuItem(value: 'سعودي', child: LocalizedText('سعودي')),
              DropdownMenuItem(value: 'أخرى', child: LocalizedText('أخرى')),
            ],
            onChanged: (_) {},
          ),
        ),
        _formField('رقم الهوية / جواز السفر', Icons.badge_outlined),
        const SizedBox(height: 4),
        const _BookingSectionTitle('بيانات النزلاء الآخرين (اختياري)'),
        ...additionalGuests.map(
          (guestId) => Container(
            key: ValueKey(guestId),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: _whiteCard(),
            child: Column(
              children: [
                Row(
                  children: [
                    LocalizedText(
                      'النزيل ${additionalGuests.indexOf(guestId) + 2}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: l10n('حذف'),
                      onPressed: () => setState(
                        () => additionalGuests.remove(guestId),
                      ),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
                _formField('الاسم الكامل', Icons.person_outline),
                _formField('رقم الهوية / جواز السفر', Icons.badge_outlined),
                _formField(
                  'رقم الجوال',
                  Icons.phone_outlined,
                  type: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() => additionalGuests.add(nextGuestId++)),
          icon: const Icon(Icons.person_add_alt_1),
          label: const LocalizedText('إضافة نزيل آخر'),
        ),
        const SizedBox(height: 10),
        Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n('طلبات خاصة (اختياري)'),
              hintText: l10n('اكتب أي طلبات أو ملاحظات خاصة...'),
              border: InputBorder.none,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xfffffbdf),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const LocalizedText(
            'خصوصيتك ومعلوماتك آمنة. نستخدم بياناتك فقط لإتمام الحجز.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        _BookingButton(
          'استكمال الحجز (الدفع)',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                roomName: widget.roomName,
                price: widget.price,
                image: widget.image,
                services: widget.services,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
    this.services = const [],
  });
  final String roomName;
  final String price;
  final String image;
  final List<HotelExtraService> services;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String method = 'جوالى';
  Future<void> _openWallet() async {
    // تُستبدل هذه الروابط الرسمية من لوحة التحكم عند توقيع اتفاقية الربط مع كل محفظة.
    const links = {
      'جوالى': 'jwali://payment',
      'جيب': 'jeeb://payment',
      'فلوسك': 'floosk://payment',
      'ون كاش': 'onecash://payment',
      'الكريمي جوال': 'alkuraimi://payment',
    };
    final rawLink = links[method];
    if (rawLink == null) return;
    final opened = await launchUrl(
      Uri.parse(rawLink),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(
            'تطبيق $method غير متوفر على هذا الجهاز. اختر طريقة دفع أخرى.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 3,
    title: 'تأكيد وسداد الحجز',
    image: widget.image,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      widget.roomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const LocalizedText('فندق سبأ صنعاء • ليلة واحدة'),
                    LocalizedText(
                      '${_money(_moneyValue(widget.price) + widget.services.fold(0, (sum, service) => sum + service.price))} ر.ي',
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  widget.image,
                  width: 95,
                  height: 75,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _BookingSectionTitle('اختيار طريقة الدفع'),
        for (final item in [
          'جوالى',
          'جيب',
          'فلوسك',
          'ون كاش',
          'الكريمي جوال',
          'فيزا كارد',
          'ماستر كارد',
        ])
          InkWell(
            onTap: () => setState(() => method = item),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: _whiteCard(),
              child: ListTile(
                title: LocalizedText(
                  item,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: Icon(
                  item == 'فيزا كارد'
                      ? Icons.credit_card_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: blue,
                ),
                trailing: Icon(
                  method == item
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: method == item ? blue : const Color(0xffaeb6c8),
                ),
              ),
            ),
          ),
        _BookingButton('فتح $method وإتمام الدفع', () async {
          await _openWallet();
          if (!context.mounted) return;
          if (method == 'فيزا كارد' || method == 'ماستر كارد') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: LocalizedText(
                  'سيتم فتح بوابة الدفع الآمنة بعد ربط مزود البطاقات.',
                ),
              ),
            );
          }
        }),
        const SizedBox(height: 8),
        _BookingButton(
          'تم الدفع — تأكيد الحجز',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                roomName: widget.roomName,
                price: widget.price,
                image: widget.image,
                method: method,
                services: widget.services,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
    required this.method,
    this.services = const [],
  });
  final String roomName;
  final String price;
  final String image;
  final String method;
  final List<HotelExtraService> services;
  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 4,
    title: 'تأكيد الحجز',
    image: image,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: _whiteCard(),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: blue, size: 58),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'تم تأكيد الحجز بنجاح',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    SizedBox(height: 3),
                    LocalizedText(
                      'تم إرسال تفاصيل الحجز إلى هاتفك وبريدك الإلكتروني',
                      style: TextStyle(color: blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(9),
          decoration: _whiteCard(),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  image,
                  width: 126,
                  height: 104,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xffffbd13),
                        ),
                        SizedBox(width: 3),
                        LocalizedText(
                          '4.6 ممتاز',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    LocalizedText(
                      'فندق سبأ صنعاء',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    LocalizedText(
                      '★★★★★',
                      style: TextStyle(
                        letterSpacing: 2,
                        color: Color(0xffffbd13),
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: orange,
                          size: 17,
                        ),
                        SizedBox(width: 3),
                        LocalizedText('صنعاء - شارع الخمسين'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _bookingInfoGrid([
          ('نوع الغرفة', roomName, Icons.bed_rounded),
          ('عدد الأشخاص', '3', Icons.groups_rounded),
          ('تاريخ الوصول', '2026/5/22', Icons.calendar_month_rounded),
          ('تاريخ المغادرة', '2026/5/23', Icons.calendar_month_rounded),
          ('طريقة الدفع', method, Icons.account_balance_wallet_rounded),
          ('حالة الدفع', 'مؤكد', Icons.verified_rounded),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xffdbe7ff),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payments_rounded, color: navy),
              const SizedBox(width: 8),
              const LocalizedText(
                'إجمالي المبلغ المدفوع',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: navy,
                ),
              ),
              const SizedBox(width: 10),
              LocalizedText(
                '${_money(_moneyValue(price) + services.fold(0, (sum, service) => sum + service.price))} ر.ي',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 82, color: navy),
              const SizedBox(width: 12),
              const Expanded(
                child: LocalizedText(
                  'أبرز هذا الرمز عند الوصول',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: navy,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: blue),
                  SizedBox(width: 5),
                  LocalizedText(
                    'تأكيد فوري',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: blue),
                  SizedBox(width: 5),
                  LocalizedText(
                    'يمكنك الإلغاء قبل 24 ساعة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _BookingButton(
          'عرض الحجز',
          () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            (route) => route.isFirst,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceScreen(
                roomName: roomName,
                price: price,
                image: image,
                method: method,
                services: services,
              ),
            ),
          ),
          icon: const Icon(Icons.receipt_long_rounded),
          label: const LocalizedText('عرض الفاتورة'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: navy,
            side: const BorderSide(color: Color(0xffd0d7e6)),
          ),
        ),
      ],
    ),
  );
}

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({
    super.key,
    required this.roomName,
    required this.price,
    required this.image,
    required this.method,
    this.services = const [],
  });
  final String roomName;
  final String price;
  final String image;
  final String method;
  final List<HotelExtraService> services;
  int get roomTotal => _moneyValue(price);
  int get servicesTotal =>
      services.fold(0, (sum, service) => sum + service.price);
  int get grandTotal => roomTotal + servicesTotal;
  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 5,
    title: 'فاتورة حجوزاتكم',
    image: image,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'تم الدفع بنجاح',
                      style: TextStyle(
                        fontSize: 18,
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    LocalizedText('شكراً لك، تم استلام الدفع بنجاح'),
                    SizedBox(height: 5),
                    LocalizedText(
                      'رقم الفاتورة  001000253',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      'تاريخ الإصدار  2026/5/24 - 10:56 م',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.task_alt_rounded, color: navy, size: 55),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: _whiteCard(),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  image,
                  width: 92,
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'فندق سبأ صنعاء',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      '★★★★★',
                      style: TextStyle(
                        letterSpacing: 2,
                        color: Color(0xffffbd13),
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: orange,
                          size: 17,
                        ),
                        SizedBox(width: 3),
                        LocalizedText('شارع الخمسين - صنعاء'),
                      ],
                    ),
                    LocalizedText(
                      '4.6 ممتاز',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _BookingSectionTitle('معلومات الحجز'),
        _bookingInfoGrid([
          ('رقم الحجز', 'TH-202225', Icons.confirmation_number_rounded),
          ('نوع الغرفة', roomName, Icons.bed_rounded),
          ('تسجيل المغادرة', '2026-5-23', Icons.calendar_month_rounded),
          ('عدد الليالي', '2', Icons.nights_stay_rounded),
          ('عدد النزلاء', '3', Icons.groups_rounded),
        ]),
        const SizedBox(height: 12),
        const _BookingSectionTitle('تفاصيل الفاتورة'),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: _whiteCard(),
          child: Table(
            border: TableBorder.symmetric(
              inside: const BorderSide(color: Color(0xffe1e5ee)),
            ),
            columnWidths: const {
              0: FlexColumnWidth(2.25),
              1: FlexColumnWidth(1.55),
              2: FlexColumnWidth(.65),
              3: FlexColumnWidth(1.15),
            },
            children: [
              _invoiceTableRow([
                'البند',
                'التفاصيل',
                'العدد',
                'الإجمالي',
              ], true),
              _invoiceTableRow([
                'سعر الغرفة',
                roomName,
                '1',
                _money(roomTotal),
              ]),
              ...services.map(
                (service) => _invoiceTableRow([
                  service.name,
                  'خدمة إضافية',
                  '1',
                  _money(service.price),
                ]),
              ),
              if (services.isEmpty)
                _invoiceTableRow(['لا توجد خدمات مضافة', '-', '-', '0']),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _invoiceTotal(
                'إجمالي سعر الغرفة',
                '${_money(roomTotal)} ر.ي',
                const Color(0xffdbe7ff),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _invoiceTotal(
                'إجمالي الخدمات المضافة',
                '${_money(servicesTotal)} ر.ي',
                const Color(0xffeef2fb),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _invoiceTotal(
          'الإجمالي العام',
          '${_money(grandTotal)} ر.ي',
          const Color(0xff7888ac),
          emphasized: true,
        ),
        const SizedBox(height: 12),
        const _BookingSectionTitle('تفاصيل الدفع'),
        _bookingInfoGrid([
          ('طريقة الدفع', method, Icons.account_balance_wallet_rounded),
          ('اسم المحفظة', method, Icons.wallet_rounded),
          ('رقم العملية', 'TH-202225', Icons.receipt_long_rounded),
          ('تاريخ ووقت الدفع', '2026-5-28 · 10:56 م', Icons.schedule_rounded),
          (
            'المبلغ المدفوع',
            '${_money(grandTotal)} ر.ي',
            Icons.payments_rounded,
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 78, color: navy),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'للمزيد من التفاصيل والعروض',
                    style: TextStyle(fontWeight: FontWeight.bold, color: navy),
                  ),
                  SizedBox(height: 3),
                  LocalizedText('امسح رمز QR لعرض الحجز أو إدارة الحجز عبر التطبيق.'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: orange, size: 48),
              SizedBox(width: 10),
              Expanded(
                child: LocalizedText(
                  'تم الدفع بنجاح\nتم استلام المبلغ وقيد تأكيد الحجز، نتطلع لخدمتكم قريباً.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ServiceCompletionFooter(
          serviceKey: 'فنادق',
          serviceName: 'فنادق',
          invoiceText:
              'فاتورة حجز $roomName\nرقم الفاتورة: 001000253\nالإجمالي: ${_money(grandTotal)} ر.ي',
          ratingScreenBuilder: (_) => RatingScreen(image: image),
        ),
      ],
    ),
  );
}

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.image});
  final String image;
  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final TextEditingController _commentController = TextEditingController();
  final Map<String, double> _scores = {
    'الموقع': 4,
    'الخدمة': 4,
    'النظافة': 4,
    'السعر': 4,
  };
  DateTime _savedAt = DateTime.now();
  bool _isSaved = false;

  double get _overall =>
      _scores.values.reduce((a, b) => a + b) / _scores.length;
  String get _savedDate =>
      '${_savedAt.year}/${_savedAt.month.toString().padLeft(2, '0')}/${_savedAt.day.toString().padLeft(2, '0')}';
  String get _savedTime =>
      '${_savedAt.hour.toString().padLeft(2, '0')}:${_savedAt.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveRating() async {
    await serviceReviewStore.saveReview(
      'فنادق',
      rating: _overall.round(),
      comment: _commentController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _savedAt = DateTime.now();
      _isSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: LocalizedText('تم حفظ تقييمك بنجاح. يمكنك تعديله في أي وقت.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BookingFrame(
    step: 5,
    title: 'تقييم الإقامة',
    image: widget.image,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: const Row(
            children: [
              Icon(Icons.hotel_rounded, color: blue, size: 46),
              SizedBox(width: 10),
              Expanded(
                child: LocalizedText(
                  'فندق سبأ صنعاء\nصنعاء - شارع الخمسين',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.verified_rounded, color: orange),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: _whiteCard(),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: blue),
              const SizedBox(width: 5),
              LocalizedText(
                'تاريخ التقييم: $_savedDate',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.schedule_rounded, color: blue),
              const SizedBox(width: 5),
              LocalizedText(
                'الوقت: $_savedTime',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._scores.entries.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: _whiteCard(),
            child: Row(
              children: [
                Icon(_ratingIcon(entry.key), color: blue),
                const SizedBox(width: 7),
                Expanded(
                  child: LocalizedText(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                LocalizedText(
                  '${entry.value.toStringAsFixed(1)} / 5',
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                ...List.generate(
                  5,
                  (index) => InkWell(
                    onTap: () =>
                        setState(() => _scores[entry.key] = index + 1.0),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        index < entry.value
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xffffbd00),
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: _whiteCard(),
          child: Column(
            children: [
              LocalizedText(
                'التقييم العام ${_overall.toStringAsFixed(1)} / 5',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              Slider(
                value: _overall,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: const Color(0xffffbd00),
                onChanged: (value) =>
                    setState(() => _scores.updateAll((key, _) => value)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < _overall.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xffffbd00),
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 145,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: _whiteCard(),
          child: TextField(
            controller: _commentController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n('تقييم الفندق'),
              hintText: l10n('اكتب تجربتك في الإقامة...'),
              suffixIcon: Icon(Icons.rate_review_rounded, color: blue),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_isSaved)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xffe9f8ee),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: LocalizedText(
                    'تم التقييم. استخدم زر تعديل التقييم لحفظ أي تغييرات جديدة.',
                  ),
                ),
              ],
            ),
          ),
        _BookingButton(
          _isSaved ? 'تعديل التقييم وحفظه' : 'إرسال التقييم',
          _saveRating,
        ),
      ],
    ),
  );

  IconData _ratingIcon(String label) => switch (label) {
    'الموقع' => Icons.location_on_rounded,
    'الخدمة' => Icons.support_agent_rounded,
    'النظافة' => Icons.cleaning_services_rounded,
    _ => Icons.sell_rounded,
  };
}

class BookingFrame extends StatelessWidget {
  const BookingFrame({
    super.key,
    required this.step,
    required this.title,
    required this.image,
    required this.child,
  });
  final int step;
  final String title;
  final String image;
  final Widget child;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          children: [
            Container(
              height: 170,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(image, fit: BoxFit.cover),
                  Container(color: Colors.black26),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, color: blue),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: blue.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: LocalizedText(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            BookingProgress(step: step),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}

class BookingProgress extends StatelessWidget {
  const BookingProgress({super.key, required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    const labels = [
      'اختيار الغرفة',
      'إدخال البيانات',
      'الدفع',
      'إتمام الحجز',
      'فاتورة الحجز',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: _whiteCard(),
      child: Row(
        children: List.generate(
          5,
          (i) => Expanded(
            child: Column(
              children: [
                Icon(
                  i + 1 <= step
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: i + 1 <= step ? blue : const Color(0xffa0a8bb),
                  size: 25,
                ),
                LocalizedText(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    color: i + 1 <= step ? blue : navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingSectionTitle extends StatelessWidget {
  const _BookingSectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: LocalizedText(
        '• $text',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: navy,
        ),
      ),
    ),
  );
}

class _BookingButton extends StatelessWidget {
  const _BookingButton(this.text, this.onTap);
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff0757bd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: LocalizedText(
        text,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

BoxDecoration _whiteCard() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: const Color(0xffd8deec)),
  boxShadow: const [
    BoxShadow(color: Color(0x28000000), blurRadius: 6, offset: Offset(0, 3)),
  ],
);
Widget _bookingInfoGrid(List<(String, String, IconData)> items) =>
    GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: items.length > 3 ? 2 : items.length,
      childAspectRatio: 1.45,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(8),
              decoration: _whiteCard(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$3, color: blue, size: 24),
                  LocalizedText(
                    item.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  LocalizedText(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
Widget _formField(
  String label,
  IconData icon, {
  TextInputType? type,
  TextEditingController? controller,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _whiteCard(),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: l10n(label),
          prefixIcon: Icon(icon, color: blue),
          border: InputBorder.none,
        ),
      ),
    );
TableRow _invoiceTableRow(List<String> values, [bool header = false]) =>
    TableRow(
      children: values
          .map(
            (value) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: LocalizedText(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: header ? 12 : 11,
                  fontWeight: header ? FontWeight.bold : FontWeight.w600,
                  color: header ? navy : const Color(0xff405272),
                ),
              ),
            ),
          )
          .toList(),
    );
Widget _invoiceTotal(
  String title,
  String value,
  Color color, {
  bool emphasized = false,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    children: [
      Expanded(
        child: FittedBox(
          alignment: Alignment.centerRight,
          fit: BoxFit.scaleDown,
          child: LocalizedText(
            title,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: emphasized ? Colors.white : navy,
              fontWeight: FontWeight.bold,
              fontSize: emphasized ? 16 : 12,
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: LocalizedText(
          value,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: emphasized ? Colors.white : blue,
            fontWeight: FontWeight.bold,
            fontSize: emphasized ? 18 : 13,
          ),
        ),
      ),
    ],
  ),
);
const _hallImage = 'assets/Services images/قاعات الافراح والمناسبات.jpg';

class HallDiscoveryScreen extends StatelessWidget {
  const HallDiscoveryScreen({super.key, required this.province});
  final String province;
  static const filters = [
    ('كل التصنيفات', Icons.grid_view_rounded),
    ('مناسبات خاصة', Icons.celebration_rounded),
    ('حفلات تخرج', Icons.school_rounded),
    ('قاعات مؤتمرات', Icons.groups_rounded),
    ('حفلات خطوبة', Icons.local_florist_rounded),
    ('قاعات أفراح', Icons.diamond_rounded),
  ];
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _hallHero(context, 'احجز أفضل الصالات وقاعات الأفراح في $province'),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: l10n('ابحث عن اسم الصالة أو المنطقة'),
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 91,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (_, i) => _hallFilter(context, i),
              ),
            ),
            const SizedBox(height: 16),
            const _BookingSectionTitle('أقوى العروض'),
            SizedBox(
              height: 218,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    const ['قاعة بلقيس', 'قاعة زفاف صنعاء', 'قاعة الأندلس']
                        .map((name) => name)
                        .map((name) => _HallOffer(name: name))
                        .toList(),
              ),
            ),
            const SizedBox(height: 14),
            const _BookingSectionTitle('صالات مميزة'),
            _HallFeaturedCard(province: province),
          ],
        ),
      ),
    ),
  );

  Widget _hallFilter(BuildContext context, int i) => InkWell(
    onTap: () => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: LocalizedText('تم تفعيل تصنيف ${filters[i].$1}'))),
    child: Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: _whiteCard(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(filters[i].$2, color: blue, size: 28),
          const SizedBox(height: 5),
          LocalizedText(
            filters[i].$1,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

class _HallOffer extends StatelessWidget {
  const _HallOffer({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HallDetailScreen(province: 'صنعاء', name: name),
      ),
    ),
    child: Container(
      width: 188,
      margin: const EdgeInsets.only(left: 10),
      clipBehavior: Clip.antiAlias,
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_hallImage, fit: BoxFit.cover),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.white,
                  ),
                ),
                const Positioned(top: 8, left: 8, child: _HallDiscount()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: LocalizedText(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: navy,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: LocalizedText(
              '★ 4.7 (128) · شارع الستين',
              style: TextStyle(color: blue, fontSize: 12),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(9, 5, 9, 9),
            child: LocalizedText(
              '1,200,000 ريال',
              style: TextStyle(
                color: Color(0xff14a765),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HallDiscount extends StatelessWidget {
  const _HallDiscount();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xff16ad65),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const LocalizedText(
      'خصم 20%',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );
}

class _HallFeaturedCard extends StatelessWidget {
  const _HallFeaturedCard({required this.province});
  final String province;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HallDetailScreen(province: province, name: 'قاعة تاج سبأ'),
      ),
    ),
    child: Container(
      height: 178,
      clipBehavior: Clip.antiAlias,
      decoration: _whiteCard(),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Image.asset(
              _hallImage,
              fit: BoxFit.cover,
              height: double.infinity,
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocalizedText(
                    'قاعة تاج سبأ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const LocalizedText(
                    '★ 4.8 (156 تقييم)',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const LocalizedText(
                    'التحرير - شارع الستين',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  const LocalizedText(
                    '2,000,000 ريال',
                    style: TextStyle(
                      color: Color(0xff14a765),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HallDetailScreen(
                          province: province,
                          name: 'قاعة تاج سبأ',
                        ),
                      ),
                    ),
                    child: const LocalizedText('عرض التفاصيل'),
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

Widget _hallHero(BuildContext context, String title) => Container(
  height: 195,
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    boxShadow: const [
      BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
  ),
  child: Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(_hallImage, fit: BoxFit.cover),
      Container(color: const Color(0x72061d68)),
      Positioned(
        top: 12,
        right: 12,
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: navy),
          ),
        ),
      ),
      Positioned(
        bottom: 18,
        right: 18,
        left: 18,
        child: LocalizedText(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
      ),
    ],
  ),
);

class HallDetailScreen extends StatelessWidget {
  const HallDetailScreen({
    super.key,
    required this.province,
    required this.name,
  });
  final String province;
  final String name;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _hallHero(context, ''),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _whiteCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: LocalizedText(
                          '★ 4.7\n(128 تقييم)',
                          style: TextStyle(
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: LocalizedText(
                          name,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 25,
                            color: navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  LocalizedText(
                    '$province - شارع الستين',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 10,
                    children: [
                      _HallFeature(
                        Icons.workspace_premium_rounded,
                        'خدمة مميزة',
                      ),
                      _HallFeature(Icons.chair_rounded, 'غرفة عروس VIP'),
                      _HallFeature(Icons.ac_unit_rounded, 'تكييف مركزي'),
                      _HallFeature(Icons.directions_car_rounded, 'مواقف واسعة'),
                      _HallFeature(Icons.groups_rounded, '900 شخص'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xfff0fbf5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText(
                                '1,200,000 ريال يمني',
                                style: TextStyle(
                                  color: Color(0xff14a765),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 21,
                                ),
                              ),
                              LocalizedText('خصم 20% · أفضل الأسعار متاحة اليوم'),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HallBookingScreen(
                                province: province,
                                name: name,
                              ),
                            ),
                          ),
                          child: const LocalizedText('احجز الآن'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const _BookingSectionTitle('نبذة عن القاعة'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _whiteCard(),
              child: const LocalizedText(
                'قاعة راقية بتصميم فاخر وخدمة احترافية لتجعل يومك مميزاً لا ينسى. باقات قابلة للتخصيص من لوحة التحكم.',
              ),
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('المميزات والخدمات'),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: _whiteCard(),
              child: const Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 14,
                children: [
                  _HallFeature(Icons.speaker_rounded, 'أنظمة صوت'),
                  _HallFeature(Icons.groups_rounded, 'فريق تنظيم'),
                  _HallFeature(Icons.wifi_rounded, 'إنترنت مجاني'),
                  _HallFeature(Icons.person_rounded, 'خدمة ضيافة'),
                  _HallFeature(Icons.local_parking_rounded, 'مواقف سيارات'),
                  _HallFeature(Icons.lightbulb_rounded, 'إضاءة حديثة'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BookingButton(
              'تحقق من التوفر',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HallBookingScreen(province: province, name: name),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HallFeature extends StatelessWidget {
  const _HallFeature(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 86,
    child: Column(
      children: [
        Icon(icon, color: blue, size: 28),
        const SizedBox(height: 4),
        LocalizedText(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class HallBookingScreen extends StatefulWidget {
  const HallBookingScreen({
    super.key,
    required this.province,
    required this.name,
  });
  final String province;
  final String name;
  @override
  State<HallBookingScreen> createState() => _HallBookingScreenState();
}

class _HallBookingScreenState extends State<HallBookingScreen> {
  int guests = 500;
  String occasion = 'زفاف';
  final extras = <String>{'غرفة عروس VIP', 'إضاءة ذكية'};
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _hallHero(context, 'حجز القاعة · إكمال بيانات الحجز'),
            const SizedBox(height: 12),
            _hallCard(widget.name, widget.province),
            const SizedBox(height: 12),
            const _BookingSectionTitle('اختر التاريخ والوقت'),
            Row(
              children: [
                Expanded(
                  child: _hallField(
                    'تاريخ المناسبة',
                    'الجمعة، 24 مايو 2026',
                    Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _hallField(
                    'وقت البداية',
                    '07:00 مساءً',
                    Icons.access_time_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('تفاصيل المناسبة'),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: ['زفاف', 'خطوبة', 'ملكة', 'حفلة تخرج', 'أخرى']
                  .map(
                    (x) => ChoiceChip(
                      label: LocalizedText(x),
                      selected: occasion == x,
                      selectedColor: const Color(0xffdce8ff),
                      onSelected: (_) => setState(() => occasion = x),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 9),
            TextField(
              decoration: InputDecoration(
                labelText: l10n('اسم العريس والعروس (اختياري)'),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                IconButton(
                  onPressed: guests > 50
                      ? () => setState(() => guests -= 50)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, color: blue),
                ),
                LocalizedText(
                  '$guests شخص',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => guests += 50),
                  icon: const Icon(Icons.add_circle_outline, color: blue),
                ),
                const Spacer(),
                const LocalizedText('عدد المدعوين التقريبي'),
              ],
            ),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n('ملاحظات خاصة (اختياري)'),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('الخدمات والإضافات'),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: _whiteCard(),
              child: Wrap(
                children:
                    [
                          'تكييف مركزي كامل',
                          'شاشة LED',
                          'فريق تنظيم محترف',
                          'غرفة عروس VIP',
                          'صوت خفيف للزفة',
                          'إضاءة ذكية',
                        ]
                        .map(
                          (x) => FilterChip(
                            label: LocalizedText(x),
                            selected: extras.contains(x),
                            onSelected: (v) => setState(
                              () => v ? extras.add(x) : extras.remove(x),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _hallPriceCard(1200000 + extras.length * 60000),
            const SizedBox(height: 12),
            _BookingButton(
              'مراجعة الحجز',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HallReviewScreen(
                    province: widget.province,
                    name: widget.name,
                    guests: guests,
                    occasion: occasion,
                    total: 1200000 + extras.length * 60000,
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

Widget _hallField(String label, String value, IconData icon) => Container(
  padding: const EdgeInsets.all(11),
  decoration: _whiteCard(),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: blue, size: 20),
          const SizedBox(width: 4),
          LocalizedText(
            label,
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      LocalizedText(value, style: const TextStyle(fontSize: 12)),
    ],
  ),
);
Widget _hallCard(String name, String province) => Container(
  padding: const EdgeInsets.all(11),
  decoration: _whiteCard(),
  child: Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          _hallImage,
          width: 120,
          height: 88,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              name,
              style: const TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            LocalizedText('$province - شارع الستين'),
            const LocalizedText(
              '900 شخص · غرفتا عروس · موقف خاص',
              style: TextStyle(color: blue, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  ),
);
Widget _hallPriceCard(int total) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: const Color(0xfff0fbf5),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      const Expanded(
        child: LocalizedText(
          'السعر الإجمالي\nخصم 20% مفعّل',
          style: TextStyle(color: navy, fontWeight: FontWeight.bold),
        ),
      ),
      LocalizedText(
        '${_money(total)} ريال',
        style: const TextStyle(
          color: Color(0xff14a765),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
);

class HallReviewScreen extends StatelessWidget {
  const HallReviewScreen({
    super.key,
    required this.province,
    required this.name,
    required this.guests,
    required this.occasion,
    required this.total,
  });
  final String province;
  final String name;
  final int guests;
  final String occasion;
  final int total;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _hallHero(context, 'حجز القاعة · مراجعة الحجز'),
            const SizedBox(height: 12),
            _hallCard(name, province),
            const SizedBox(height: 12),
            const _BookingSectionTitle('تفاصيل الحجز'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  _InvoiceLine('تاريخ المناسبة', 'الجمعة، 24 مايو 2026'),
                  _InvoiceLine('وقت البداية', '07:00 مساءً'),
                  _InvoiceLine('وقت النهاية', '12:00 منتصف الليل'),
                  _InvoiceLine('نوع المناسبة', occasion),
                  _InvoiceLine('عدد المدعوين', '$guests شخص'),
                  _InvoiceLine(
                    'الخدمات والإضافات',
                    'تكييف · شاشة LED · تنظيم · غرفة عروس',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _hallPriceCard(total),
            const SizedBox(height: 12),
            _BookingButton('إتمام الحجز والدفع', () {
              final next = HallPaymentScreen(
                province: province,
                name: name,
                total: total,
              );
              if (!appSession.isRegistered) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignUpScreen(
                      roomName: 'حجز قاعة',
                      price: '$total',
                      image: _hallImage,
                      nextScreen: next,
                    ),
                  ),
                );
              } else if (!appSession.isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => next),
                );
              }
            }),
          ],
        ),
      ),
    ),
  );
}

class HallPaymentScreen extends StatefulWidget {
  const HallPaymentScreen({
    super.key,
    required this.province,
    required this.name,
    required this.total,
  });
  final String province;
  final String name;
  final int total;
  @override
  State<HallPaymentScreen> createState() => _HallPaymentScreenState();
}

class _HallPaymentScreenState extends State<HallPaymentScreen> {
  int choice = 0;
  final options = const ['محفظة ون كاش', 'محفظة جوالي', 'محفظة جيب', 'الكريمي'];
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _hallHero(context, 'حجز القاعة · إتمام الدفع'),
            const SizedBox(height: 12),
            _hallCard(widget.name, widget.province),
            const SizedBox(height: 12),
            const _BookingSectionTitle('اختر طريقة الدفع'),
            ...List.generate(
              options.length,
              (i) => InkWell(
                onTap: () => setState(() => choice = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: _whiteCard(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LocalizedText(
                          options[i],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Icon(
                        choice == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _hallPriceCard(widget.total),
            const SizedBox(height: 12),
            _BookingButton(
              'ادفع الآن · ${_money(widget.total)} ريال',
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HallInvoiceScreen(
                    province: widget.province,
                    name: widget.name,
                    total: widget.total,
                    method: options[choice],
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

class HallInvoiceScreen extends StatelessWidget {
  const HallInvoiceScreen({
    super.key,
    required this.province,
    required this.name,
    required this.total,
    required this.method,
  });
  final String province;
  final String name;
  final int total;
  final String method;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 25, 12, 22),
              decoration: BoxDecoration(
                color: const Color(0xff103b99),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 58),
                  SizedBox(height: 8),
                  LocalizedText(
                    'تم الحجز والدفع بنجاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LocalizedText(
                    'شكراً لاختيارك قاعة بلقيس للمناسبات',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _hallImage,
                          width: 88,
                          height: 75,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              'فاتورة حجز ودفع',
                              style: const TextStyle(
                                fontSize: 22,
                                color: navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            LocalizedText(
                              'INV-2024-0005687',
                              style: const TextStyle(color: blue),
                            ),
                            const LocalizedText(
                              'مدفوعة ✓',
                              style: TextStyle(
                                color: Color(0xff14a765),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _InvoiceLine('رقم الحجز', 'BK-2024-0005687'),
                  _InvoiceLine('القاعة', name),
                  _InvoiceLine('المناسبة', 'زفاف · 500 شخص'),
                  _InvoiceLine(
                    'التاريخ والوقت',
                    'الجمعة 24 مايو · 07:00 مساءً',
                  ),
                  _InvoiceLine('الموقع', '$province - شارع الستين'),
                  _InvoiceLine('طريقة الدفع', method),
                  const Divider(height: 28),
                  _InvoiceLine(
                    'سعر القاعة والخدمات',
                    '${_money(total - 270000)} ريال',
                  ),
                  _InvoiceLine('ضريبة القيمة المضافة', '270,000 ريال'),
                  _InvoiceLine('خصم خاص', '-300,000 ريال'),
                  _InvoiceLine('الإجمالي الكلي', '${_money(total)} ريال'),
                  const SizedBox(height: 14),
                  Container(
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xfff4f7ff),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const LocalizedText(
                      '|||| |||| |||| |||| ||||\nBK5687 240524 084512',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ServiceCompletionFooter(
              serviceKey: 'قاعات أفراح ومناسبات',
              serviceName: 'قاعات أفراح ومناسبات',
              invoiceText:
                  'فاتورة حجز $name\nرقم الحجز: BK-2024-0005687\nالإجمالي: ${_money(total)} ريال',
            ),
          ],
        ),
      ),
    ),
  );
}

const _chaletImage = 'assets/Services images/شاليهات.jpg';
const _chaletBanner = 'assets/images/chalet_booking_banner.png';
const _resortImage = 'assets/Services images/منتجعات.jpg';
const _resortBanner = 'assets/images/resort_booking_banner.png';

class RetreatExtraService {
  const RetreatExtraService({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
  });
  final String id;
  final String name;
  final int price;
  final IconData icon;
}

const _retreatExtraServices = <RetreatExtraService>[
  RetreatExtraService(
    id: 'daily_cleaning',
    name: 'تنظيف يومي',
    price: 3000,
    icon: Icons.cleaning_services_rounded,
  ),
  RetreatExtraService(
    id: 'breakfast',
    name: 'وجبة إفطار',
    price: 5000,
    icon: Icons.breakfast_dining_rounded,
  ),
  RetreatExtraService(
    id: 'airport_transfer',
    name: 'توصيل من المطار',
    price: 10000,
    icon: Icons.airport_shuttle_rounded,
  ),
  RetreatExtraService(
    id: 'barbecue',
    name: 'تجهيز منطقة الشواء',
    price: 2500,
    icon: Icons.outdoor_grill_rounded,
  ),
];

class ChaletData {
  const ChaletData({
    required this.id,
    required this.name,
    required this.city,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.features,
    this.description =
        'شاليه فاخر بإطلالة مميزة، مصمم لقضاء أجمل الأوقات مع العائلة والخصوصية التامة.',
    this.galleryImages = const [],
    this.videoUrls = const [],
    this.additionalDetails = const {},
    this.extraServices = _retreatExtraServices,
  });
  final String id, name, city;
  final int price;
  final double rating;
  final int reviews;
  final List<String> features;

  /// حقول المحتوى التي تغذيها لوحة التحكم: صور، فيديوهات، وصف ومعلومات إضافية.
  final String description;
  final List<String> galleryImages;
  final List<String> videoUrls;
  final Map<String, String> additionalDetails;
  final List<RetreatExtraService> extraServices;
}

/// إعدادات تجربة الإقامة المشتركة. تسمح للمنتجعات والشاليهات باستخدام جميع
/// الشاشات والآليات نفسها مع محتوى وصور وهوية مستقلة لكل بطاقة.
class RetreatCatalog {
  const RetreatCatalog({
    required this.entityLabel,
    required this.pluralLabel,
    required this.searchHint,
    required this.featuredTitle,
    required this.heroSubtitle,
    required this.imageAsset,
    required this.bannerAsset,
    required this.favoritePrefix,
    required this.bookingPrefix,
    required this.items,
    this.showHeroCopy = true,
  });

  final String entityLabel;
  final String pluralLabel;
  final String searchHint;
  final String featuredTitle;
  final String heroSubtitle;
  final String imageAsset;
  final String bannerAsset;
  final String favoritePrefix;
  final String bookingPrefix;
  final List<ChaletData> items;
  final bool showHeroCopy;
}

const _chalets = <ChaletData>[
  ChaletData(
    id: 'green-mountain',
    name: 'شاليه الجبل الأخضر',
    city: 'صنعاء',
    price: 28000,
    rating: 4.8,
    reviews: 124,
    features: ['مسبح خاص', 'واي فاي', 'جلسات خارجية', 'موقف سيارة'],
    galleryImages: [_chaletImage],
    videoUrls: [],
    additionalDetails: {'الإطلالة': 'الجبال والوادي', 'الخصوصية': 'تامة'},
  ),
  ChaletData(
    id: 'cloud',
    name: 'شاليه السحاب',
    city: 'إب',
    price: 24000,
    rating: 4.7,
    reviews: 98,
    features: ['مسبح', 'مطبخ', 'مكيف', 'واي فاي'],
    galleryImages: [_chaletImage],
  ),
  ChaletData(
    id: 'fog',
    name: 'شاليه الضباب',
    city: 'تعز',
    price: 22000,
    rating: 4.6,
    reviews: 76,
    features: ['مسبح', 'مطبخ', 'جلسات عائلية', 'موقف خاص'],
    galleryImages: [_chaletImage],
  ),
  ChaletData(
    id: 'sea',
    name: 'شاليه البحر',
    city: 'عدن',
    price: 30000,
    rating: 4.8,
    reviews: 110,
    features: ['إطلالة بحرية', 'مكيف', 'واي فاي', 'مسبح'],
    galleryImages: [_chaletImage],
  ),
];

const _resorts = <ChaletData>[
  ChaletData(
    id: 'aden-lagoon',
    name: 'منتجع لاجون عدن',
    city: 'عدن',
    price: 58000,
    rating: 4.9,
    reviews: 186,
    features: ['شاطئ خاص', 'مسبح إنفينيتي', 'واي فاي', 'مطاعم'],
    description:
        'منتجع ساحلي فاخر بإطلالة مباشرة على البحر، يجمع الخصوصية والراحة مع مرافق متكاملة للعائلات والأزواج.',
    galleryImages: [_resortImage],
    additionalDetails: {
      'الإطلالة': 'البحر وخليج عدن',
      'الإلغاء': 'مجاني حتى 48 ساعة',
      'الاستقبال': 'على مدار الساعة',
    },
  ),
  ChaletData(
    id: 'socotra-pearl',
    name: 'منتجع لؤلؤة سقطرى',
    city: 'سقطرى',
    price: 62000,
    rating: 4.9,
    reviews: 142,
    features: ['إطلالة بحرية', 'رحلات سياحية', 'مطعم', 'نقل المطار'],
    description:
        'تجربة إقامة هادئة وسط طبيعة سقطرى الفريدة، مع فلل مستقلة وخدمات رحلات ونقل مخصصة للضيوف.',
    galleryImages: [_resortImage],
    additionalDetails: {'نوع الإقامة': 'فلل وأجنحة', 'الوجبات': 'إفطار مشمول'},
  ),
  ChaletData(
    id: 'hadramout-oasis',
    name: 'منتجع واحة حضرموت',
    city: 'حضرموت',
    price: 46000,
    rating: 4.8,
    reviews: 119,
    features: ['مسبح عائلي', 'نادي أطفال', 'سبا', 'موقف خاص'],
    description:
        'منتجع عائلي متكامل مستوحى من العمارة الحضرمية، يوفر مساحات خضراء ومرافق ترفيهية وخدمة ضيافة راقية.',
    galleryImages: [_resortImage],
    additionalDetails: {
      'التصنيف': 'خمس نجوم',
      'مناسب لـ': 'العائلات والمناسبات',
    },
  ),
  ChaletData(
    id: 'ibb-green-hills',
    name: 'منتجع تلال إب الخضراء',
    city: 'إب',
    price: 39000,
    rating: 4.7,
    reviews: 97,
    features: ['إطلالة جبلية', 'جلسات خارجية', 'مطعم', 'واي فاي'],
    description:
        'إقامة جبلية وسط الطبيعة الخضراء والطقس المعتدل، مع جلسات بانورامية ومطعم يقدم المأكولات المحلية.',
    galleryImages: [_resortImage],
    additionalDetails: {
      'الإطلالة': 'الجبال والمدرجات الزراعية',
      'الخصوصية': 'أجنحة مستقلة',
    },
  ),
];

const _chaletCatalog = RetreatCatalog(
  entityLabel: 'الشاليه',
  pluralLabel: 'شاليهات',
  searchHint: 'ابحث عن شاليه أو مدينة',
  featuredTitle: 'شاليهات مسجلة',
  heroSubtitle: 'إقامات عائلية مميزة في أجمل المواقع',
  imageAsset: _chaletImage,
  bannerAsset: _chaletBanner,
  favoritePrefix: 'chalet',
  bookingPrefix: 'CH',
  items: _chalets,
);

const _resortCatalog = RetreatCatalog(
  entityLabel: 'المنتجع',
  pluralLabel: 'منتجعات',
  searchHint: 'ابحث عن منتجع أو مدينة',
  featuredTitle: 'منتجعات مسجلة',
  heroSubtitle: 'منتجعات فاخرة وخيارات تناسب الجميع',
  imageAsset: _resortImage,
  bannerAsset: _resortBanner,
  favoritePrefix: 'resort',
  bookingPrefix: 'RS',
  items: _resorts,
  showHeroCopy: false,
);

class ResortDiscoveryScreen extends StatelessWidget {
  const ResortDiscoveryScreen({super.key, required this.province});

  final String province;

  @override
  Widget build(BuildContext context) =>
      ChaletDiscoveryScreen(province: province, catalog: _resortCatalog);
}

class ChaletDiscoveryScreen extends StatefulWidget {
  const ChaletDiscoveryScreen({
    super.key,
    required this.province,
    this.catalog = _chaletCatalog,
  });
  final String province;
  final RetreatCatalog catalog;
  @override
  State<ChaletDiscoveryScreen> createState() => _ChaletDiscoveryScreenState();
}

class _ChaletDiscoveryScreenState extends State<ChaletDiscoveryScreen> {
  String query = '';
  String filter = 'الكل';
  final filters = const [
    ('الكل', Icons.grid_view_rounded),
    ('عائلي', Icons.groups_rounded),
    ('مع مسبح', Icons.pool_rounded),
    ('الأقرب إليك', Icons.location_on_outlined),
    ('الأعلى تقييماً', Icons.workspace_premium_outlined),
    ('الأقل سعراً', Icons.sell_outlined),
  ];
  List<ChaletData> get results {
    var list = widget.catalog.items
        .where((x) => x.name.contains(query) || x.city.contains(query))
        .toList();
    if (filter == 'الأعلى تقييماً') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    if (filter == 'الأقل سعراً') {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    if (filter == 'الأقرب إليك') {
      list.sort((a, b) => a.city == widget.province ? -1 : 1);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          key: const Key('retreat-discovery-list'),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          children: [
            _chaletHero(
              context,
              province: widget.province,
              catalog: widget.catalog,
            ),
            const SizedBox(height: 12),
            LocalizedText(
              '${widget.catalog.pluralLabel} ${widget.province}',
              style: const TextStyle(
                color: navy,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            LocalizedText(
              widget.catalog.heroSubtitle,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: l10n(widget.catalog.searchHint),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xff087370),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => setState(() => filter = filters[i].$1),
                  child: Container(
                    width: 91,
                    decoration: BoxDecoration(
                      color: filter == filters[i].$1
                          ? const Color(0xff087370)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1a000000),
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filters[i].$2,
                          color: filter == filters[i].$1
                              ? Colors.white
                              : const Color(0xff087370),
                          size: 27,
                        ),
                        const SizedBox(height: 5),
                        LocalizedText(
                          filters[i].$1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: filter == filters[i].$1
                                ? Colors.white
                                : navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _BookingSectionTitle('العروض المميزة'),
            _RetreatOfferBanner(
              catalog: widget.catalog,
              title: 'خصم 20% للحجز المبكر',
              subtitle: 'احجز قبل الموعد بسبعة أيام واستفد من العرض',
              onTap: () => _openRetreatOffer(context),
            ),
            _RetreatOfferBanner(
              catalog: widget.catalog,
              title: 'ليلة إضافية بسعر أقل',
              subtitle: 'عرض خاص للإقامات العائلية الطويلة',
              onTap: () => _openRetreatOffer(context),
            ),
            _RetreatOfferBanner(
              catalog: widget.catalog,
              title: 'خدمة التوصيل مجاناً',
              subtitle: 'لفترة محدودة على الحجوزات المؤهلة',
              onTap: () => _openRetreatOffer(context),
            ),
            const SizedBox(height: 15),
            _BookingSectionTitle(widget.catalog.featuredTitle),
            ...results.map(
              (x) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _ChaletListCard(
                  chalet: x,
                  catalog: widget.catalog,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChaletDetailScreen(
                        chalet: x,
                        catalog: widget.catalog,
                      ),
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

  void _openRetreatOffer(BuildContext context) {
    final item = widget.catalog.items.first;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChaletDetailScreen(chalet: item, catalog: widget.catalog),
      ),
    );
  }
}

Widget _chaletHero(
  BuildContext context, {
  required String province,
  RetreatCatalog catalog = _chaletCatalog,
}) {
  return Container(
    height: 205,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(catalog.bannerAsset, fit: BoxFit.cover),
        Positioned(
          top: 10,
          right: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xff087370),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: LocalizedText('لا توجد إشعارات جديدة')),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xff087370),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RetreatOfferBanner extends StatelessWidget {
  const _RetreatOfferBanner({
    required this.catalog,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final RetreatCatalog catalog;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 128,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: _whiteCard(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(catalog.imageAsset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xdd064c4b), Color(0x55064c4b)],
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
                  maxLines: 2,
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

class _ChaletListCard extends StatelessWidget {
  const _ChaletListCard({
    required this.chalet,
    required this.catalog,
    required this.onTap,
  });
  final ChaletData chalet;
  final RetreatCatalog catalog;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 170,
      clipBehavior: Clip.antiAlias,
      decoration: _whiteCard(),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  chalet.galleryImages.isEmpty
                      ? catalog.imageAsset
                      : chalet.galleryImages.first,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => appSession.toggleRestaurantFavorite(
                        '${catalog.favoritePrefix}-${chalet.id}',
                      ),
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xff087370),
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    chalet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LocalizedText(
                    '⌖ ${chalet.city}',
                    style: const TextStyle(
                      color: Color(0xff087370),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LocalizedText(
                    '★ ${chalet.rating}  (${chalet.reviews})',
                    style: const TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: chalet.features
                        .take(3)
                        .map(
                          (f) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffedf7f5),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: LocalizedText(
                              f,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xff087370),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const Spacer(),
                  LocalizedText(
                    'من ${_money(chalet.price)} ر.ي / الليلة',
                    style: const TextStyle(
                      color: Color(0xff087370),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

class ChaletDetailScreen extends StatefulWidget {
  const ChaletDetailScreen({
    super.key,
    required this.chalet,
    this.catalog = _chaletCatalog,
  });
  final ChaletData chalet;
  final RetreatCatalog catalog;
  @override
  State<ChaletDetailScreen> createState() => _ChaletDetailScreenState();
}

class _ChaletDetailScreenState extends State<ChaletDetailScreen> {
  bool favorite = false;
  final selectedExtras = <String>{};
  List<RetreatExtraService> get selectedExtraServices => widget
      .chalet.extraServices
      .where((service) => selectedExtras.contains(service.id))
      .toList();
  @override
  Widget build(BuildContext context) {
    final c = widget.chalet;
    return Directionality(
      textDirection: appTextDirection,
      child: Scaffold(
        bottomNavigationBar: const HujuzatBottomNav(),
        body: SafeArea(
          child: ListView(
            key: const Key('retreat-detail-list'),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            children: [
              _chaletDetailHero(
                context,
                c,
                widget.catalog,
                favorite,
                () => setState(() => favorite = !favorite),
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: _whiteCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LocalizedText(
                            c.name,
                            style: const TextStyle(
                              fontSize: 27,
                              color: Color(0xff087370),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => AppMapLauncher.open(
                            context,
                            query: '${c.name} ${c.city} اليمن',
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const LocalizedText('الموقع على الخارطة'),
                        ),
                      ],
                    ),
                    LocalizedText(
                      '⌖ ${c.city}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    LocalizedText(
                      '★ ${c.rating}  (${c.reviews} تقييم)',
                      style: const TextStyle(
                        color: orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LocalizedText(c.description, style: const TextStyle(height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _BookingSectionTitle('مميزات ${widget.catalog.entityLabel}'),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: _whiteCard(),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  runSpacing: 12,
                  children: c.features
                      .map(
                        (feature) => _ChaletAmenity(
                          Icons.check_circle_outline_rounded,
                          feature,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              const _BookingSectionTitle('الميزات الإضافية'),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: _whiteCard(),
                child: Column(
                  children: c.extraServices
                      .map(
                        (service) => CheckboxListTile(
                          value: selectedExtras.contains(service.id),
                          controlAffinity: ListTileControlAffinity.leading,
                          secondary: Icon(
                            service.icon,
                            color: const Color(0xff087370),
                          ),
                          title: LocalizedText(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: LocalizedText(
                            '${_money(service.price)} ر.ي',
                            style: const TextStyle(color: Color(0xff087370)),
                          ),
                          onChanged: (_) => setState(() {
                            selectedExtras.contains(service.id)
                                ? selectedExtras.remove(service.id)
                                : selectedExtras.add(service.id);
                          }),
                        ),
                      ),
                      .toList(),
                ),
              ),
              if (c.additionalDetails.isNotEmpty) ...[
                const SizedBox(height: 14),
                const _BookingSectionTitle('معلومات إضافية'),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: _whiteCard(),
                  child: Wrap(
                    runSpacing: 12,
                    children: c.additionalDetails.entries
                        .map(
                          (entry) => _ChaletTextFeature(
                            '${entry.key}: ${entry.value}',
                            Icons.info_outline_rounded,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const _BookingSectionTitle('معرض الصور والفيديو'),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      c.galleryImages.length +
                      c.videoUrls.length +
                      (c.galleryImages.isEmpty ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final images = c.galleryImages.isEmpty
                        ? [widget.catalog.imageAsset]
                        : c.galleryImages;
                    if (index < images.length) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          images[index],
                          width: 180,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return Container(
                      width: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xff0b766f),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 4),
                          LocalizedText(
                            'فيديو',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xfff0faf8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LocalizedText(
                            'السعر لليلة',
                            style: TextStyle(color: Colors.black54),
                          ),
                          LocalizedText(
                            '${_money(c.price)} ر.ي',
                            style: const TextStyle(
                              color: Color(0xff087370),
                              fontWeight: FontWeight.bold,
                              fontSize: 23,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _BookingButton(
                        'احجز الآن',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChaletBookingScreen(
                              chalet: c,
                              catalog: widget.catalog,
                              extras: selectedExtraServices,
                            ),
                          ),
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
}

Widget _chaletDetailHero(
  BuildContext context,
  ChaletData chalet,
  RetreatCatalog catalog,
  bool favorite,
  VoidCallback onFavorite,
) {
  return Container(
    height: 255,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          chalet.galleryImages.isEmpty
              ? catalog.imageAsset
              : chalet.galleryImages.first,
          fit: BoxFit.cover,
        ),
        Container(color: Colors.black12),
        Positioned(
          top: 10,
          right: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xff087370),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: LocalizedText('تمت مشاركة رابط ${catalog.entityLabel}'),
                    ),
                  ),
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    color: Color(0xff087370),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: const Color(0xff087370),
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

class _ChaletAmenity extends StatelessWidget {
  const _ChaletAmenity(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    child: Column(
      children: [
        Icon(icon, size: 27, color: const Color(0xff087370)),
        const SizedBox(height: 4),
        LocalizedText(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _ChaletTextFeature extends StatelessWidget {
  const _ChaletTextFeature(this.text, this.icon);
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 155,
    child: Row(
      children: [
        Icon(icon, color: const Color(0xff087370), size: 21),
        const SizedBox(width: 6),
        Expanded(child: LocalizedText(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class ChaletBookingScreen extends StatefulWidget {
  const ChaletBookingScreen({
    super.key,
    required this.chalet,
    this.catalog = _chaletCatalog,
    this.extras = const [],
  });
  final ChaletData chalet;
  final RetreatCatalog catalog;
  final List<RetreatExtraService> extras;
  @override
  State<ChaletBookingScreen> createState() => _ChaletBookingScreenState();
}

class _ChaletBookingScreenState extends State<ChaletBookingScreen> {
  DateTime arrival = DateTime.now().add(const Duration(days: 2));
  DateTime departure = DateTime.now().add(const Duration(days: 5));
  int guests = 4;
  int get nights => departure.difference(arrival).inDays.clamp(1, 99);
  int get extrasTotal => widget.extras.fold(0, (sum, item) => sum + item.price);
  int get total => widget.chalet.price * nights + extrasTotal;
  Future<void> pickDate(bool isArrival) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isArrival ? arrival : departure,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isArrival) {
          arrival = date;
          if (!departure.isAfter(arrival)) {
            departure = arrival.add(const Duration(days: 1));
          }
        } else if (date.isAfter(arrival)) {
          departure = date;
        }
      });
    }
  }

  String d(DateTime x) => '${x.day}/${x.month}/${x.year}';
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          key: const Key('retreat-booking-list'),
          padding: const EdgeInsets.all(14),
          children: [
            _chaletHero(
              context,
              province: widget.chalet.city,
              catalog: widget.catalog,
            ),
            const SizedBox(height: 12),
            BookingProgress(step: 2),
            const SizedBox(height: 12),
            _chaletSummary(widget.chalet, widget.catalog),
            const SizedBox(height: 12),
            const _BookingSectionTitle('اختر تاريخ الوصول والمغادرة'),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: _whiteCard(),
              child: Row(
                children: [
                  Expanded(
                    child: _dateBox(
                      'تاريخ الوصول',
                      d(arrival),
                      () => pickDate(true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xff087370),
                    ),
                  ),
                  Expanded(
                    child: _dateBox(
                      'تاريخ المغادرة',
                      d(departure),
                      () => pickDate(false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _bookingInfoGrid([
              ('عدد الضيوف', '$guests ضيوف', Icons.groups_rounded),
              ('عدد الليالي', '$nights ليالٍ', Icons.nights_stay_rounded),
              (
                'عدد الخدمات المضافة',
                widget.extras.isEmpty ? 'لا يوجد' : '${widget.extras.length}',
                Icons.room_service_rounded,
              ),
              ('وقت الوصول', '03:00 عصراً', Icons.access_time_rounded),
            ]),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: guests > 1 ? () => setState(() => guests--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const LocalizedText('ضيف'),
                ),
                LocalizedText(
                  '$guests ضيوف',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => guests++),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const LocalizedText('إضافة'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.extras.isNotEmpty) ...[
              const _BookingSectionTitle('الميزات الإضافية المختارة'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _whiteCard(),
                child: Column(
                  children: widget.extras
                      .map(
                        (item) => _InvoiceLine(
                          item.name,
                          '${_money(item.price)} ر.ي',
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 9),
            ],
            _hallPriceCard(total),
            const SizedBox(height: 12),
            _BookingButton('متابعة إلى الدفع', () {
              final next = ChaletPaymentScreen(
                chalet: widget.chalet,
                catalog: widget.catalog,
                arrival: arrival,
                departure: departure,
                guests: guests,
                total: total,
                extras: widget.extras,
              );
              if (!appSession.isRegistered) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignUpScreen(
                      roomName: widget.chalet.name,
                      price: '$total',
                      image: widget.catalog.imageAsset,
                      nextScreen: next,
                    ),
                  ),
                );
              } else if (!appSession.isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => next),
                );
              }
            }),
          ],
        ),
      ),
    ),
  );
}

Widget _dateBox(String title, String value, VoidCallback tap) {
  return InkWell(
    onTap: tap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfff6faf9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          LocalizedText(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: Color(0xff087370),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: LocalizedText(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _chaletSummary(ChaletData c, [RetreatCatalog catalog = _chaletCatalog]) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: _whiteCard(),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            c.galleryImages.isEmpty
                ? catalog.imageAsset
                : c.galleryImages.first,
            width: 105,
            height: 76,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                c.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: navy,
                  fontSize: 18,
                ),
              ),
              LocalizedText('⌖ ${c.city}'),
              LocalizedText(
                '★ ${c.rating} (${c.reviews})',
                style: const TextStyle(
                  color: orange,
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

/// بيانات وسائل الدفع قابلة للاستبدال مباشرة ببيانات لوحة التحكم.
class ChaletPaymentMethod {
  const ChaletPaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    this.subtitle = 'محفظة مالية محلية',
  });
  final String id;
  final String name;
  final IconData icon;
  final String subtitle;
}

const _chaletPaymentMethods = <ChaletPaymentMethod>[
  ChaletPaymentMethod(
    id: 'one_cash',
    name: 'محفظة ون كاش',
    icon: Icons.account_balance_wallet_rounded,
  ),
  ChaletPaymentMethod(
    id: 'jawali',
    name: 'محفظة جوالي',
    icon: Icons.phone_android_rounded,
  ),
  ChaletPaymentMethod(
    id: 'jeeb',
    name: 'محفظة جيب',
    icon: Icons.wallet_rounded,
  ),
  ChaletPaymentMethod(
    id: 'floosaak',
    name: 'محفظة فلوسك',
    icon: Icons.account_balance_rounded,
  ),
  ChaletPaymentMethod(
    id: 'kareemy',
    name: 'الكريمي جوال',
    icon: Icons.account_balance_wallet_outlined,
  ),
  ChaletPaymentMethod(
    id: 'visa',
    name: 'فيزا كارد',
    icon: Icons.credit_card_rounded,
    subtitle: 'بطاقة ائتمانية',
  ),
  ChaletPaymentMethod(
    id: 'mastercard',
    name: 'ماستر كارد',
    icon: Icons.credit_card_rounded,
    subtitle: 'بطاقة ائتمانية',
  ),
];

class ChaletPaymentScreen extends StatefulWidget {
  const ChaletPaymentScreen({
    super.key,
    required this.chalet,
    this.catalog = _chaletCatalog,
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.total,
    this.extras = const [],
  });
  final ChaletData chalet;
  final RetreatCatalog catalog;
  final DateTime arrival, departure;
  final int guests, total;
  final List<RetreatExtraService> extras;
  @override
  State<ChaletPaymentScreen> createState() => _ChaletPaymentScreenState();
}

class _ChaletPaymentScreenState extends State<ChaletPaymentScreen> {
  int chosen = 0;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          key: const Key('retreat-payment-list'),
          padding: const EdgeInsets.all(14),
          children: [
            _chaletHero(
              context,
              province: widget.chalet.city,
              catalog: widget.catalog,
            ),
            const SizedBox(height: 12),
            BookingProgress(step: 4),
            const SizedBox(height: 12),
            _chaletSummary(widget.chalet, widget.catalog),
            const SizedBox(height: 12),
            const _BookingSectionTitle('اختر طريقة الدفع'),
            ...List.generate(
              _chaletPaymentMethods.length,
              (i) => InkWell(
                onTap: () => setState(() => chosen = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: _whiteCard(),
                  child: Row(
                    children: [
                      Icon(
                        _chaletPaymentMethods[i].icon,
                        color: Color(0xff087370),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LocalizedText(
                          _chaletPaymentMethods[i].name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        chosen == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: const Color(0xff087370),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.extras.isNotEmpty) ...[
              const _BookingSectionTitle('الميزات الإضافية'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _whiteCard(),
                child: Column(
                  children: widget.extras
                      .map(
                        (item) => _InvoiceLine(
                          item.name,
                          '${_money(item.price)} ر.ي',
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _hallPriceCard(widget.total),
            const SizedBox(height: 13),
            _BookingButton(
              'ادفع الآن · ${_money(widget.total)} ر.ي',
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ChaletSuccessScreen(
                    chalet: widget.chalet,
                    catalog: widget.catalog,
                    arrival: widget.arrival,
                    departure: widget.departure,
                    guests: widget.guests,
                    total: widget.total,
                    method: _chaletPaymentMethods[chosen].name,
                    extras: widget.extras,
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

class ChaletSuccessScreen extends StatelessWidget {
  const ChaletSuccessScreen({
    super.key,
    required this.chalet,
    this.catalog = _chaletCatalog,
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.total,
    required this.method,
    this.extras = const [],
  });
  final ChaletData chalet;
  final RetreatCatalog catalog;
  final DateTime arrival, departure;
  final int guests, total;
  final String method;
  final List<RetreatExtraService> extras;
  String get range =>
      '${arrival.day}/${arrival.month}/${arrival.year} - ${departure.day}/${departure.month}/${departure.year}';
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          key: const Key('retreat-success-list'),
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(23),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff087370), Color(0xff0c9d91)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_rounded, size: 61, color: Colors.white),
                  SizedBox(height: 9),
                  LocalizedText(
                    'تم تأكيد الحجز بنجاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  LocalizedText(
                    'أرسلنا تفاصيل الحجز إلى هاتفك',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            _chaletSummary(chalet, catalog),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  _InvoiceLine(
                    'رقم الحجز',
                    '${catalog.bookingPrefix}-2026-000245',
                  ),
                  _InvoiceLine('تاريخ الإقامة', range),
                  _InvoiceLine('عدد الضيوف', '$guests ضيوف'),
                  _InvoiceLine('طريقة الدفع', method),
                  _InvoiceLine('حالة الدفع', 'مؤكد ✓'),
                  ...extras.map(
                    (item) => _InvoiceLine(
                      item.name,
                      '${_money(item.price)} ر.ي',
                    ),
                  ),
                  const Divider(height: 25),
                  _InvoiceLine('إجمالي المبلغ', '${_money(total)} ر.ي'),
                ],
              ),
            ),
            const SizedBox(height: 13),
            ServiceCompletionFooter(
              serviceKey: catalog.pluralLabel,
              serviceName: catalog.pluralLabel,
              invoiceText:
                  'فاتورة حجز ${chalet.name}\nرقم الحجز: ${catalog.bookingPrefix}-2026-000245\n${extras.map((item) => '${item.name}: ${_money(item.price)} ر.ي').join('\n')}\nالإجمالي: ${_money(total)} ر.ي',
              ratingScreenBuilder: (_) =>
                  ChaletRatingScreen(chalet: chalet, catalog: catalog),
            ),
          ],
        ),
      ),
    ),
  );
}

/// واجهة تقييم بسيطة قابلة للحفظ لاحقاً في لوحة التحكم لكل حجز وشاليه.
class ChaletRatingScreen extends StatefulWidget {
  const ChaletRatingScreen({
    super.key,
    required this.chalet,
    this.catalog = _chaletCatalog,
  });
  final ChaletData chalet;
  final RetreatCatalog catalog;
  @override
  State<ChaletRatingScreen> createState() => _ChaletRatingScreenState();
}

class _ChaletRatingScreenState extends State<ChaletRatingScreen> {
  int rating = 5;
  final comment = TextEditingController();
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      appBar: AppBar(title: LocalizedText('تقييم ${widget.catalog.entityLabel}')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _chaletSummary(widget.chalet, widget.catalog),
          const SizedBox(height: 18),
          const LocalizedText(
            'كيف كانت إقامتك؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => rating = index + 1),
                icon: Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: orange,
                  size: 38,
                ),
              ),
            ),
          ),
          LocalizedText(
            '$rating من 5 · ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: comment,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n('اكتب تجربتك (اختياري)'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          _BookingButton('إرسال التقييم', () async {
            await serviceReviewStore.saveReview(
              widget.catalog.pluralLabel,
              rating: rating,
              comment: comment.text.trim(),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: LocalizedText('شكراً، تم حفظ تقييمك بنجاح')),
            );
            Navigator.pop(context, true);
          }),
        ],
      ),
    ),
  );
}

/// نموذج بطاقة خدمة التوصيل. تدعم لوحة التحكم لاحقاً تغيير الأيقونة أو
/// إرفاق صورة محلية/رابط صورة دون إعادة تصميم الشاشة.
class QuickDeliveryServiceConfig {
  const QuickDeliveryServiceConfig({
    required this.id,
    required this.name,
    required this.icon,
    this.imageAsset,
    this.imageUrl,
  });
  final String id;
  final String name;
  final IconData icon;
  final String? imageAsset;
  final String? imageUrl;
}

class QuickDeliveryScreen extends StatefulWidget {
  const QuickDeliveryScreen({super.key, required this.province});
  final String province;

  @override
  State<QuickDeliveryScreen> createState() => _QuickDeliveryScreenState();
}

class _QuickDeliveryScreenState extends State<QuickDeliveryScreen> {
  String query = '';

  List<QuickDeliveryServiceConfig> get categories => controlPanelRepository
      .deliveryCategories
      .where((item) => item.enabled && item.name.contains(query))
      .map(
        (item) => QuickDeliveryServiceConfig(
          id: item.id,
          name: item.name,
          icon: _deliveryCategoryIcon(item.iconKey),
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final province = widget.province;
    final visibleCategories = categories;
    return Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
          children: [
            _quickDeliveryHero(context),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => query = value.trim()),
              decoration: InputDecoration(
                hintText: l10n('ابحث عن نوع الخدمة التي تحتاجها'),
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: Color(0xffd8e2f0)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _BookingSectionTitle('طلباتك واحتياجاتك في مكان واحد'),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryCartScreen(
                    province: province,
                    category: 'سوبر ماركت',
                  ),
                ),
              ),
              child: Container(
                height: 188,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x35000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/quick_delivery_banner.png',
                      fit: BoxFit.cover,
                    ),
                    Container(color: const Color(0x6601245f)),
                    const Positioned(
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            'عروض التوصيل الحصرية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          LocalizedText(
                            'خصومات يومية من المتاجر القريبة منك',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleCategories.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisExtent: 148,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
              ),
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => visibleCategories[i].id == 'other'
                    ? Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FreeDeliveryRequestScreen(province: province),
                        ),
                      )
                    : Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryStoresScreen(
                            province: province,
                            categoryId: visibleCategories[i].id,
                            category: visibleCategories[i].name,
                          ),
                        ),
                      ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffd8e2f0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1d0b2343),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xffe7f1ff),
                        child: _QuickDeliveryServiceVisual(
                          service: visibleCategories[i],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: LocalizedText(
                          visibleCategories[i].name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                      ),
                    ],
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
}

IconData _deliveryCategoryIcon(String key) => switch (key) {
  'cart' => Icons.shopping_cart_rounded,
  'spa' => Icons.spa_rounded,
  'fashion' => Icons.checkroom_rounded,
  'nature' => Icons.eco_rounded,
  'food' => Icons.restaurant_rounded,
  'bakery' => Icons.bakery_dining_rounded,
  'gift' => Icons.card_giftcard_rounded,
  'book' => Icons.menu_book_rounded,
  'produce' => Icons.apple_rounded,
  'home' => Icons.kitchen_rounded,
  'pharmacy' => Icons.medical_services_rounded,
  'building' => Icons.electrical_services_rounded,
  'devices' => Icons.devices_other_rounded,
  'store' => Icons.storefront_rounded,
  'car' => Icons.car_repair_rounded,
  'computer' => Icons.laptop_mac_rounded,
  _ => Icons.edit_note_rounded,
};

class _QuickDeliveryServiceVisual extends StatelessWidget {
  const _QuickDeliveryServiceVisual({required this.service});
  final QuickDeliveryServiceConfig service;
  @override
  Widget build(BuildContext context) {
    if (service.imageUrl != null && service.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          service.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(service.icon, color: blue, size: 31),
        ),
      );
    }
    if (service.imageAsset != null && service.imageAsset!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          service.imageAsset!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(service.icon, color: blue, size: 31),
        ),
      );
    }
    return Icon(service.icon, color: blue, size: 31);
  }
}

Widget _quickDeliveryHero(
  BuildContext context, {
  String? category,
  String? province,
}) => Container(
  height: 205,
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: const [
      BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
  ),
  child: Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/images/quick_delivery_banner.png', fit: BoxFit.cover),
      Positioned(
        top: 9,
        right: 9,
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: .92),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: blue),
          ),
        ),
      ),
      Positioned(
        top: 9,
        left: 9,
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: .92),
          child: IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: LocalizedText('لا توجد إشعارات جديدة للتوصيل.')),
            ),
            icon: const Icon(Icons.notifications_none_rounded, color: blue),
          ),
        ),
      ),
      if (category != null)
        Positioned(
          left: 10,
          bottom: 10,
          child: Material(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => AppMapLauncher.open(
                context,
                query: '$category ${province ?? ''} اليمن',
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.near_me_rounded, color: blue, size: 21),
                    SizedBox(width: 6),
                    LocalizedText(
                      'الأقرب إليك',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  ),
);

/// قائمة المتاجر ومنتجاتها مصدرها في المستقبل واجهة لوحة التحكم.
class DeliveryStoresScreen extends StatefulWidget {
  const DeliveryStoresScreen({
    super.key,
    required this.province,
    required this.categoryId,
    required this.category,
  });
  final String province;
  final String categoryId;
  final String category;

  @override
  State<DeliveryStoresScreen> createState() => _DeliveryStoresScreenState();
}

class _DeliveryStoresScreenState extends State<DeliveryStoresScreen> {
  String query = '';

  List<DeliveryStoreRecord> get stores => controlPanelRepository.deliveryStores
      .where(
        (item) =>
            item.enabled &&
            (item.categoryId == 'all' ||
                item.categoryId == widget.categoryId) &&
            (item.provinceId == 'all' ||
                item.provinceId == widget.province) &&
            (query.isEmpty ||
                item.name.contains(query) ||
                item.address.contains(query)),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final province = widget.province;
    final visibleStores = stores;
    return Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _quickDeliveryHero(
              context,
              category: category,
              province: province,
            ),
            const SizedBox(height: 12),
            _BookingSectionTitle(category),
            TextField(
              onChanged: (value) => setState(() => query = value.trim()),
              decoration: InputDecoration(
                hintText: l10n('ابحث عن متجر أو عنوان داخل $category'),
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                suffixIcon: IconButton(
                  tooltip: l10n('الأقرب إليك'),
                  onPressed: () => AppMapLauncher.open(
                    context,
                    query: '$category $province اليمن',
                  ),
                  icon: const Icon(Icons.map_outlined, color: blue),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xffd8e2f0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 124,
              clipBehavior: Clip.antiAlias,
              decoration: _whiteCard(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/quick_delivery_banner.png',
                    fit: BoxFit.cover,
                  ),
                  Container(color: const Color(0x7701245f)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'عروض $category',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const LocalizedText(
                          'خصومات وخيارات مختارة بالقرب منك',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BookingSectionTitle('متاجر $category المسجلة'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleStores.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .92,
              ),
              itemBuilder: (context, index) {
                final store = visibleStores[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeliveryProductsScreen(
                        province: province,
                        category: category,
                        store: store.name,
                      ),
                    ),
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: _whiteCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.asset(
                            store.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText(
                                store.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: navy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              LocalizedText(
                                '${store.address} · $category',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: blue,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: LocalizedText(
                                      '★ ${store.rating} · متاح الآن',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => AppMapLauncher.directions(
                                      context,
                                      destination:
                                          '${store.name} ${store.address} $province اليمن',
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.route_rounded, size: 15, color: blue),
                                        SizedBox(width: 3),
                                        LocalizedText(
                                          'المسافة',
                                          style: TextStyle(
                                            color: blue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryCartScreen(
                    province: province,
                    category: category,
                  ),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: LocalizedText('تعديل السلة (${deliveryBasket.items.length})'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class DeliveryProductsScreen extends StatefulWidget {
  const DeliveryProductsScreen({
    super.key,
    required this.province,
    required this.category,
    required this.store,
  });
  final String province;
  final String category;
  final String store;
  @override
  State<DeliveryProductsScreen> createState() => _DeliveryProductsScreenState();
}

class _DeliveryProductsScreenState extends State<DeliveryProductsScreen> {
  static const _products = [
    ('مياه معدنية 1.5 لتر', 200),
    ('حليب كامل الدسم', 450),
    ('أرز بسمتي فاخر', 1200),
    ('مناديل ورقية', 350),
    ('عصير طبيعي', 500),
    ('منظفات منزلية', 800),
  ];
  void _add((String, int) product) {
    deliveryBasket.add(
      DeliveryCartItem(
        id: '${widget.category}-${product.$1}',
        name: product.$1,
        category: widget.category,
        unitPrice: product.$2,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: LocalizedText('تمت إضافة ${product.$1} إلى السلة')),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _quickDeliveryHero(
              context,
              category: widget.category,
              province: widget.province,
            ),
            const SizedBox(height: 10),
            _BookingSectionTitle('${widget.store} · ${widget.category}'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _whiteCard(),
              child: const LocalizedText(
                'اختر المنتجات وأضفها إلى سلتك. يمكنك الانتقال إلى قسم آخر والاحتفاظ بكل اختياراتك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: navy),
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: .56,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, index) {
                final product = _products[index];
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: _whiteCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.asset(
                          'assets/images/quick_delivery_banner.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(9, 7, 9, 0),
                        child: SizedBox(
                          height: 34,
                          child: Center(
                            child: LocalizedText(
                              product.$1,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.15,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: LocalizedText(
                          '${_money(product.$2)} ر.ي',
                          style: const TextStyle(
                            color: blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7),
                        child: SizedBox(
                          height: 30,
                          child: FilledButton.icon(
                            onPressed: () => _add(product),
                            icon: const Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 16,
                            ),
                            label: const LocalizedText('أضف'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _BookingButton(
              'تعديل السلة (${deliveryBasket.items.length})',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryCartScreen(
                    province: widget.province,
                    category: widget.category,
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

class _FreeDeliveryItemDraft {
  _FreeDeliveryItemDraft()
    : product = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      price = TextEditingController();

  final TextEditingController product;
  final TextEditingController quantity;
  final TextEditingController price;

  int get count => (int.tryParse(quantity.text) ?? 1).clamp(1, 999).toInt();
  int get unitPrice => int.tryParse(price.text) ?? 0;
  int get total => unitPrice * count;
  bool get isValid => product.text.trim().isNotEmpty && unitPrice > 0;

  void dispose() {
    product.dispose();
    quantity.dispose();
    price.dispose();
  }
}

class FreeDeliveryRequestScreen extends StatefulWidget {
  const FreeDeliveryRequestScreen({super.key, required this.province});
  final String province;
  @override
  State<FreeDeliveryRequestScreen> createState() =>
      _FreeDeliveryRequestScreenState();
}

class _FreeDeliveryRequestScreenState extends State<FreeDeliveryRequestScreen> {
  final place = TextEditingController();
  final List<_FreeDeliveryItemDraft> _items = [_FreeDeliveryItemDraft()];
  late final TextEditingController deliveryLocation;
  @override
  void initState() {
    super.initState();
    deliveryLocation = TextEditingController();
  }

  @override
  void dispose() {
    place.dispose();
    for (final item in _items) {
      item.dispose();
    }
    deliveryLocation.dispose();
    super.dispose();
  }

  Widget _tableHeading(String text, {int flex = 1}) => Expanded(
    flex: flex,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: LocalizedText(
        text,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
      ),
    ),
  );

  Widget _itemRow(_FreeDeliveryItemDraft item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: item.product,
            onChanged: (_) => setState(() {}),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n('اسم المنتج'),
              border: InputBorder.none,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: TextField(
            controller: item.quantity,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: '1',
              border: InputBorder.none,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: TextField(
            controller: item.price,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              border: InputBorder.none,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: LocalizedText(
              '${_money(item.total)} ر.ي',
              maxLines: 1,
              style: const TextStyle(
                color: blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _quickDeliveryHero(
              context,
              category: 'احتياجات أخرى',
              province: widget.province,
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('احتياجات أخرى'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  const LocalizedText(
                    'اكتب طلبك وسيتولى مندوبنا شراؤه من المكان المحدد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: navy, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: place,
                    decoration: InputDecoration(
                      labelText: l10n('مكان الطلب وموقعه'),
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deliveryLocation,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n('موقع التوصيل الحالي'),
                      prefixIcon: Icon(Icons.my_location_rounded),
                      hintText: l10n('أدخل موقع التوصيل الحالي'),
                      suffixIcon: IconButton(
                        tooltip: l10n('استخدام موقعي الحالي'),
                        onPressed: () => setState(
                          () => deliveryLocation.text =
                              'موقعي الحالي - ${widget.province}',
                        ),
                        icon: const Icon(Icons.gps_fixed_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: LocalizedText(
                      'تفاصيل الطلب',
                      style: TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xfff7faff),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffdbe2f0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _tableHeading('المنتج', flex: 4),
                            _tableHeading('الكمية', flex: 2),
                            _tableHeading('السعر', flex: 2),
                            _tableHeading('الإجمالي', flex: 2),
                          ],
                        ),
                        const Divider(height: 13),
                        ..._items.map(_itemRow),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _items.add(_FreeDeliveryItemDraft())),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const LocalizedText('إضافة منتج آخر'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BookingButton('أضف المنتجات إلى السلة', () {
                    if (place.text.trim().isEmpty ||
                        deliveryLocation.text.trim().isEmpty ||
                        _items.any((item) => !item.isValid)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: LocalizedText(
                            'يرجى إدخال مكان الطلب وموقع التوصيل وبيانات كل منتج وسعره.',
                          ),
                        ),
                      );
                      return;
                    }
                    for (var index = 0; index < _items.length; index++) {
                      final item = _items[index];
                      deliveryBasket.add(
                        DeliveryCartItem(
                          id: 'custom-${DateTime.now().millisecondsSinceEpoch}-$index',
                          name:
                              '${item.product.text.trim()} · ${place.text.trim()}',
                          category: 'احتياجات أخرى',
                          unitPrice: item.unitPrice,
                          quantity: item.count,
                        ),
                      );
                    }
                    deliveryBasket.setDeliveryLocation(deliveryLocation.text);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryCartScreen(
                          province: widget.province,
                          category: 'احتياجات أخرى',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DeliveryCartScreen extends StatefulWidget {
  const DeliveryCartScreen({
    super.key,
    required this.province,
    required this.category,
  });
  final String province;
  final String category;
  @override
  State<DeliveryCartScreen> createState() => _DeliveryCartScreenState();
}

class _DeliveryCartScreenState extends State<DeliveryCartScreen> {
  int get subtotal => deliveryBasket.subtotal;
  int get total => deliveryBasket.total;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _quickDeliveryHero(
              context,
              category: widget.category,
              province: widget.province,
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('بيانات الطلب'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.75,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              children: [
                _DeliveryInfoTile(
                  Icons.location_on_rounded,
                  'عنوان التوصيل',
                  deliveryBasket.deliveryLocation ?? 'حدد موقع التوصيل الحالي',
                ),
                const _DeliveryInfoTile(
                  Icons.notes_rounded,
                  'ملاحظات الطلب',
                  'لا توجد ملاحظات',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _BookingSectionTitle(tr('قائمة المشتريات', 'Shopping list')),
            AnimatedBuilder(
              animation: deliveryBasket,
              builder: (context, _) => Container(
                padding: const EdgeInsets.all(8),
                decoration: _whiteCard(),
                child: _deliveryCartContents(),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: deliveryBasket,
              builder: (_, _) => _deliveryTotals(subtotal, total),
            ),
            const SizedBox(height: 12),
            _BookingButton('متابعة الطلب', () {
              if (deliveryBasket.items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: LocalizedText('أضف منتجات إلى السلة أولاً.')),
                );
                return;
              }
              final next = DeliveryPaymentScreen(
                province: widget.province,
                category: widget.category,
                total: total,
              );
              if (!appSession.isRegistered) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignUpScreen(
                      roomName: 'طلب توصيل',
                      price: '$total',
                      image: 'assets/images/quick_delivery_banner.png',
                      nextScreen: next,
                    ),
                  ),
                );
              } else if (!appSession.isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => next),
                );
              }
            }),
          ],
        ),
      ),
    ),
  );

  Widget _deliveryCartContents() {
    if (deliveryBasket.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: LocalizedText(
          'السلة فارغة. اختر منتجات من أحد الأقسام أولاً.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact) {
          return Column(
            children: deliveryBasket.items
                .map(
                  (item) => Container(
                    key: ValueKey('delivery-item-${item.id}'),
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8faff),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffe1e7f4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LocalizedText(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _deliveryCompactValue(
                                tr('الكمية', 'Quantity'),
                                _deliveryQuantityField(item),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _deliveryCompactValue(
                                tr('سعر الوحدة', 'Unit price'),
                                LocalizedText(
                                  '${_money(item.unitPrice)} ر.ي',
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: blue),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _deliveryCompactValue(
                                tr('الإجمالي', 'Total'),
                                LocalizedText(
                                  '${_money(item.total)} ر.ي',
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: blue,
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
                )
                .toList(),
          );
        }
        return Column(
          children: [
            Row(
              children: [
                _deliveryCartHeading(tr('المنتج', 'Product'), flex: 4),
                _deliveryCartHeading(tr('الكمية', 'Quantity'), flex: 2),
                _deliveryCartHeading(
                  tr('سعر الوحدة', 'Unit price'),
                  flex: 2,
                ),
                _deliveryCartHeading(tr('الإجمالي', 'Total'), flex: 2),
              ],
            ),
            const Divider(),
            ...deliveryBasket.items.map(
              (item) => Container(
                key: ValueKey('delivery-item-${item.id}'),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xfff8faff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: LocalizedText(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _deliveryQuantityField(item),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: LocalizedText(
                        '${_money(item.unitPrice)} ر.ي',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: blue, fontSize: 11),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: LocalizedText(
                        '${_money(item.total)} ر.ي',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _deliveryCompactValue(String label, Widget value) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LocalizedText(
        label,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xff667085),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 5),
      SizedBox(height: 40, child: Center(child: value)),
    ],
  );

  Widget _deliveryQuantityField(DeliveryCartItem item) => TextFormField(
    key: ValueKey('delivery-quantity-${item.id}'),
    initialValue: '${item.quantity}',
    keyboardType: TextInputType.number,
    textAlign: TextAlign.center,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
    onChanged: (value) {
      final quantity = int.tryParse(value);
      if (quantity == null || quantity < 1) return;
      deliveryBasket.change(item, quantity.clamp(1, 999));
    },
    decoration: InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xffcfd9ef)),
      ),
    ),
  );
}

class _DeliveryInfoTile extends StatelessWidget {
  const _DeliveryInfoTile(this.icon, this.title, this.value);
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: _whiteCard(),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: blue, size: 27),
        const SizedBox(height: 3),
        LocalizedText(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        LocalizedText(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    ),
  );
}

Widget _deliveryCartHeading(String text, {int flex = 1}) => Expanded(
  flex: flex,
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: LocalizedText(
      text,
      maxLines: 1,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: navy,
      ),
    ),
  ),
);

Widget _deliveryTotals(int subtotal, int total) => Container(
  padding: const EdgeInsets.all(12),
  decoration: _whiteCard(),
  child: Column(
    children: [
      _deliveryTotal('قيمة الفاتورة', '$subtotal ر.ي'),
      _deliveryTotal('تكلفة التوصيل', '600 ر.ي'),
      _deliveryTotal('رسوم الخدمة', '0 ر.ي'),
      const Divider(),
      _deliveryTotal('الإجمالي', '$total ر.ي', strong: true),
    ],
  ),
);
Widget _deliveryTotal(String title, String value, {bool strong = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          LocalizedText(
            title,
            style: TextStyle(
              fontSize: strong ? 19 : 15,
              fontWeight: strong ? FontWeight.bold : FontWeight.normal,
              color: navy,
            ),
          ),
          const Spacer(),
          LocalizedText(
            value,
            style: TextStyle(
              fontSize: strong ? 19 : 15,
              fontWeight: FontWeight.bold,
              color: strong ? navy : blue,
            ),
          ),
        ],
      ),
    );

class DeliveryPaymentScreen extends StatefulWidget {
  const DeliveryPaymentScreen({
    super.key,
    required this.province,
    required this.category,
    required this.total,
  });
  final String province;
  final String category;
  final int total;
  @override
  State<DeliveryPaymentScreen> createState() => _DeliveryPaymentScreenState();
}

class _DeliveryPaymentScreenState extends State<DeliveryPaymentScreen> {
  int selected = 1;
  final methods = const [
    ('جوالي', Icons.account_balance_wallet_rounded),
    ('جيب', Icons.wallet_rounded),
    ('فلوسك', Icons.payments_rounded),
    ('ون كاش', Icons.account_balance_rounded),
    ('الكريمي جوال', Icons.phone_android_rounded),
    ('فيزا كارد', Icons.credit_card_rounded),
    ('مستر كارد', Icons.credit_score_rounded),
  ];
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _quickDeliveryHero(
              context,
              category: widget.category,
              province: widget.province,
            ),
            const SizedBox(height: 14),
            const _BookingSectionTitle('اختيار طريقة الدفع'),
            const LocalizedText(
              'جميع طرق الدفع آمنة ومشفرة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 9),
            ...List.generate(
              methods.length,
              (i) => InkWell(
                onTap: () => setState(() => selected = i),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: _whiteCard(),
                  child: Row(
                    children: [
                      Icon(methods[i].$2, color: blue, size: 29),
                      const SizedBox(width: 14),
                      Expanded(
                        child: LocalizedText(
                          methods[i].$1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                      ),
                      Icon(
                        selected == i
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected == i ? blue : const Color(0xffd8dee9),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _deliveryTotals(widget.total - 600, widget.total),
            const SizedBox(height: 15),
            _BookingButton(
              'متابعة تنفيذ الطلب',
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryOrderSuccessScreen(
                    province: widget.province,
                    category: widget.category,
                    payment: methods[selected].$1,
                    total: widget.total,
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

class DeliveryOrderSuccessScreen extends StatelessWidget {
  const DeliveryOrderSuccessScreen({
    super.key,
    required this.province,
    required this.category,
    required this.payment,
    required this.total,
  });
  final String province;
  final String category;
  final String payment;
  final int total;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _quickDeliveryHero(
              context,
              category: category,
              province: province,
            ),
            const SizedBox(height: 18),
            const Icon(
              Icons.verified_rounded,
              size: 82,
              color: Color(0xff3397f0),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _whiteCard(),
              child: const Column(
                children: [
                  LocalizedText(
                    'تم تأكيد طلبك بنجاح',
                    style: TextStyle(
                      fontSize: 28,
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  LocalizedText(
                    'جارٍ شراء المتطلبات وتجهيزها للتوصيل',
                    style: TextStyle(color: blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _whiteCard(),
              child: const Column(
                children: [
                  _InvoiceLine('رقم الطلب', '4654654646'),
                  _InvoiceLine('زمن التوصيل المتوقع', '25 - 35 دقيقة'),
                  _InvoiceLine('المتجر أو نقطة الشراء', 'هايبر سما مول'),
                  _InvoiceLine('عنوان التوصيل', 'شارع الستين - صنعاء'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _deliveryTotals(total - 600, total),
            const SizedBox(height: 14),
            _BookingButton(
              'تتبع الطلب مباشرة',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeliveryTrackingScreen(
                    tracking: DeliveryTrackingData(
                      orderId: '4654654646',
                      driverName: 'جمال أحمد',
                      driverPhone: '+967700000000',
                      latitude: 15.3694,
                      longitude: 44.1910,
                      status: 'جارٍ شراء وتجهيز الطلب',
                      estimatedMinutes: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryInvoiceScreen(
                    province: province,
                    category: category,
                    payment: payment,
                    total: total,
                  ),
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const LocalizedText('عرض الفاتورة'),
            ),
          ],
        ),
      ),
    ),
  );
}

class DeliveryInvoiceScreen extends StatelessWidget {
  const DeliveryInvoiceScreen({
    super.key,
    required this.province,
    required this.category,
    required this.payment,
    required this.total,
  });
  final String province;
  final String category;
  final String payment;
  final int total;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      appBar: AppBar(title: const LocalizedText('فاتورة التوصيل السريع')),
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _quickDeliveryHero(
              context,
              category: category,
              province: province,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  const _InvoiceLine('رقم الطلب', '4654654646'),
                  _InvoiceLine('المحافظة', province),
                  const _InvoiceLine('عنوان التوصيل', 'شارع الستين'),
                  _InvoiceLine('طريقة الدفع', payment),
                  _InvoiceLine('الإجمالي', '${_money(total)} ر.ي'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ServiceCompletionFooter(
              serviceKey: 'التوصيل السريع',
              serviceName: 'التوصيل السريع',
              invoiceText:
                  'فاتورة طلب التوصيل\nرقم الطلب: 4654654646\nالمحافظة: $province\nطريقة الدفع: $payment\nالإجمالي: ${_money(total)} ر.ي',
              ratingScreenBuilder: (_) => const DeliveryRatingScreen(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// تقييم محفوظ كنموذج جاهز للربط لاحقاً مع الطلب وبيانات لوحة التحكم.
class DeliveryRatingScreen extends StatefulWidget {
  const DeliveryRatingScreen({super.key});
  @override
  State<DeliveryRatingScreen> createState() => _DeliveryRatingScreenState();
}

class _DeliveryRatingScreenState extends State<DeliveryRatingScreen> {
  int rating = 5;
  final comment = TextEditingController();

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      appBar: AppBar(title: const LocalizedText('تقييم خدمة التوصيل')),
      bottomNavigationBar: const HujuzatBottomNav(),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(Icons.delivery_dining_rounded, size: 68, color: blue),
          const SizedBox(height: 12),
          const LocalizedText(
            'كيف كانت تجربة التوصيل؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => rating = index + 1),
                icon: Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 38,
                  color: orange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: comment,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n('ملاحظاتك (اختياري)'),
              hintText: l10n('اكتب تقييمك للخدمة'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          _BookingButton('إرسال التقييم', () async {
            await serviceReviewStore.saveReview(
              'التوصيل السريع',
              rating: rating,
              comment: comment.text.trim(),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: LocalizedText('شكرًا لتقييمك، تم حفظه بنجاح.')),
            );
            Navigator.pop(context, true);
          }),
        ],
      ),
    ),
  );
}

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({
    super.key,
    required this.service,
    required this.province,
  });
  final String service;
  final String province;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      appBar: AppBar(title: LocalizedText('$service في $province')),
      bottomNavigationBar: const HujuzatBottomNav(),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xffeaf1ff),
              child: Icon(Icons.storefront_rounded, color: blue),
            ),
            title: LocalizedText('الجهة المسجلة ${i + 1}'),
            subtitle: const LocalizedText('متاح للحجز الآن · تقييم 4.8 ★'),
            trailing: ElevatedButton(
              onPressed: () {},
              child: const LocalizedText('احجز'),
            ),
          ),
        ),
      ),
    ),
  );
}

const _restaurantImage = 'assets/Services images/مطاعم.jpg';
const _restaurantName = 'مطعم القلعة السياحي';

/// نموذج جاهز لاستقبال بيانات المطاعم وميزاتها من لوحة التحكم لاحقاً.
class RestaurantSummary {
  const RestaurantSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.deliveryMinutes,
    required this.rating,
    required this.isNew,
    required this.hasOffer,
    required this.features,
  });
  final String id;
  final String name;
  final String category;
  final double distance;
  final int deliveryMinutes;
  final double rating;
  final bool isNew;
  final bool hasOffer;
  final List<String> features;
}

class RestaurantDiscoveryScreen extends StatefulWidget {
  const RestaurantDiscoveryScreen({super.key, required this.province});
  final String province;
  @override
  State<RestaurantDiscoveryScreen> createState() =>
      _RestaurantDiscoveryScreenState();
}

class _RestaurantDiscoveryScreenState extends State<RestaurantDiscoveryScreen> {
  int? filter;
  String category = '';
  String searchQuery = '';
  final restaurants = const [
    RestaurantSummary(
      id: 'yemeni-home',
      name: 'مطعم البيت اليمني',
      category: 'مأكولات شعبية',
      distance: 1.2,
      deliveryMinutes: 25,
      rating: 4.6,
      isNew: false,
      hasOffer: true,
      features: ['توصيل مجاناً'],
    ),
    RestaurantSummary(
      id: 'castle',
      name: 'مطعم القلعة السياحي',
      category: 'مأكولات شعبية',
      distance: 2.5,
      deliveryMinutes: 35,
      rating: 4.8,
      isNew: true,
      hasOffer: true,
      features: ['جلسات عائلية'],
    ),
    RestaurantSummary(
      id: 'happy-yemen',
      name: 'مطعم اليمن السعيد',
      category: 'مشاوي',
      distance: .8,
      deliveryMinutes: 20,
      rating: 4.9,
      isNew: false,
      hasOffer: false,
      features: ['توصيل مجاناً'],
    ),
    RestaurantSummary(
      id: 'popular-taste',
      name: 'مطعم المذاق الشعبي',
      category: 'شوارما وسندوتشات',
      distance: 3.4,
      deliveryMinutes: 30,
      rating: 4.4,
      isNew: true,
      hasOffer: true,
      features: ['خصم 20%'],
    ),
    RestaurantSummary(
      id: 'asian-house',
      name: 'بيت آسيا للمأكولات',
      category: 'مأكولات آسيوية',
      distance: 1.8,
      deliveryMinutes: 28,
      rating: 4.7,
      isNew: false,
      hasOffer: false,
      features: ['توصيل مجاناً'],
    ),
    RestaurantSummary(
      id: 'sweet-time',
      name: 'وقت الحلوى',
      category: 'إيسكريم وحلويات',
      distance: 2.1,
      deliveryMinutes: 18,
      rating: 4.5,
      isNew: true,
      hasOffer: true,
      features: ['عرض اليوم'],
    ),
    RestaurantSummary(
      id: 'fresh-juice',
      name: 'عصائر الفاكهة الطازجة',
      category: 'عصائر',
      distance: 1.0,
      deliveryMinutes: 15,
      rating: 4.6,
      isNew: false,
      hasOffer: false,
      features: ['توصيل مجاناً'],
    ),
  ];

  /// تصنيفات توصيف الخدمة؛ تُستبدل لاحقاً من لوحة التحكم.
  final filters = const [
    ('المفضلة', Icons.favorite_rounded),
    ('الأقرب إليك', Icons.location_on_rounded),
    ('الأسرع توصيلاً', Icons.bolt_rounded),
    ('الأعلى تقييماً', Icons.star_rounded),
    ('المفتوحة حديثاً', Icons.new_releases_rounded),
    ('العروض اليومية', Icons.sell_rounded),
  ];

  /// أنواع المطاعم، منفصلة تماماً عن توصيف الخدمة.
  final categories = const [
    'مأكولات شعبية',
    'مشاوي',
    'بيتزا ومعجنات',
    'مأكولات بحرية',
    'بروست وبرجر',
    'شوارما وسندوتشات',
    'إيسكريم وحلويات',
    'عصائر',
  ];

  List<RestaurantSummary> get visibleRestaurants {
    var items = restaurants.where((item) {
      final matchesCategory =
          category.isEmpty || category == 'الكل' || item.category == category;
      final term = searchQuery.trim();
      final matchesSearch =
          term.isEmpty ||
          item.name.contains(term) ||
          item.category.contains(term);
      return matchesCategory && matchesSearch;
    }).toList();
    switch (filter) {
      case 0:
        items = items
            .where((item) => appSession.favoriteRestaurants.contains(item.id))
            .toList();
        break;
      case 1:
        items.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 2:
        items.sort((a, b) => a.deliveryMinutes.compareTo(b.deliveryMinutes));
        break;
      case 3:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 4:
        items = items.where((item) => item.isNew).toList();
        break;
      case 5:
        items = items.where((item) => item.hasOffer).toList();
        break;
    }
    return items;
  }

  void setFilter(int value) {
    setState(() => filter = filter == value ? null : value);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          children: [
            _discoveryHero(context),
            const SizedBox(height: 9),
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: l10n('ابحث عن نوع المطعم أو اسمه...'),
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                suffixIcon: IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: LocalizedText(
                        'استخدم حقل البحث لكتابة اسم المطعم أو نوعه.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.mic_rounded, color: blue),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 9),
            const _BookingSectionTitle('تصفية حسب الخدمة'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.24,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              children: filters.asMap().entries.map((entry) {
                final active = filter == entry.key;
                return InkWell(
                  onTap: () => setFilter(entry.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active ? blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? blue : const Color(0xffdbe2f0),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          entry.value.$2,
                          size: 20,
                          color: active ? Colors.white : blue,
                        ),
                        const SizedBox(height: 2),
                        LocalizedText(
                          entry.value.$1,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? Colors.white : navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('نوع المطعم'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.72,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              children: categories.map((item) {
                final active = category == item;
                return InkWell(
                  onTap: () => setState(() => category = active ? '' : item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xffffc221) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? const Color(0xffffc221)
                            : const Color(0xffdbe2f0),
                      ),
                    ),
                    child: Center(
                      child: LocalizedText(
                        item,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            _sectionLabel('مطاعم مميزة'),
            const RestaurantAdvertisementBanners(),
            const SizedBox(height: 8),
            if (visibleRestaurants.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: _whiteCard(),
                child: const LocalizedText(
                  'لا توجد مطاعم مطابقة لهذا التصنيف حالياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: navy, fontWeight: FontWeight.bold),
                ),
              )
            else
              ...visibleRestaurants.map(
                (restaurant) => _restaurantListCard(context, restaurant),
              ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RestaurantMapScreen(province: widget.province),
                ),
              ),
              icon: const Icon(Icons.map_rounded),
              label: const LocalizedText(
                'خريطة المطاعم',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _discoveryHero(BuildContext context) => Container(
    height: 220,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x38000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/restaurant_discovery_banner.png',
          fit: BoxFit.cover,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: blue),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(14),
            ),
            child: LocalizedText(
              'مطاعم ${widget.province}',
              style: const TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _restaurantListCard(
    BuildContext context,
    RestaurantSummary restaurant,
  ) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(name: restaurant.name),
      ),
    ),
    child: Container(
      height: 154,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _whiteCard(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 138,
            child: Image.asset(_restaurantImage, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedText(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () => setState(
                          () => appSession.toggleRestaurantFavorite(
                            restaurant.id,
                          ),
                        ),
                        icon: Icon(
                          appSession.favoriteRestaurants.contains(restaurant.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: blue,
                          size: 23,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      LocalizedText(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Color(0xffffbd00),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: LocalizedText(
                          'يمني · ${restaurant.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    alignment: Alignment.centerRight,
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: blue,
                        ),
                        LocalizedText(
                          ' ${restaurant.deliveryMinutes} - ${restaurant.deliveryMinutes + 10} دقيقة',
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: blue,
                        ),
                        LocalizedText(' ${restaurant.distance} كم'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 31,
                          child: FilledButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailScreen(
                                  name: restaurant.name,
                                ),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: LocalizedText('عرض المنيو', maxLines: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: SizedBox(
                          height: 31,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xffffdf59),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: LocalizedText(
                                restaurant.features.isEmpty
                                    ? 'ميزة خاصة'
                                    : restaurant.features.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: navy,
                                  fontWeight: FontWeight.bold,
                                ),
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
        ],
      ),
    ),
  );
}

/// بنرات العروض الإعلانية للمطاعم. القائمة قابلة للتمديد بلا حد من لوحة التحكم.
class RestaurantAdvertisementBanners extends StatelessWidget {
  const RestaurantAdvertisementBanners({super.key});

  static const banners = [
    ('مطعم البيت اليمني', 'خصم حتى 30% على الوجبات العائلية', 'اطلب الآن'),
    (
      'مطعم القلعة السياحي',
      'عرض خاص على أشهى المأكولات اليمنية',
      'اكتشف العرض',
    ),
    ('مطعم اليمن السعيد', 'توصيل مجاني داخل المدينة', 'اطلب الآن'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(banners.length, (index) {
      final banner = banners[index];
      return Padding(
        padding: EdgeInsets.only(bottom: index == banners.length - 1 ? 0 : 10),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(name: banner.$1),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 126,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x25000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_restaurantImage, fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xdd032d69), Color(0x30032d69)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        banner.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: LocalizedText(
                          banner.$2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffffc221),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: LocalizedText(
                            banner.$3,
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.bold,
                            ),
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
    }),
  );
}

Future<void> _shareRestaurant(BuildContext context, String title) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      title: title,
      text: 'اكتشف $title عبر تطبيق حجوزاتكم.',
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

Widget _restaurantHero(BuildContext context, String title) => Container(
  height: 190,
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
  child: Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(_restaurantImage, fit: BoxFit.cover),
      Container(color: Colors.black38),
      Positioned(
        top: 8,
        right: 8,
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: blue),
          ),
        ),
      ),
      Positioned(
        top: 8,
        left: 8,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                onPressed: () => _shareRestaurant(context, title),
                icon: const Icon(Icons.share_rounded, color: blue),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                onPressed: () =>
                    appSession.toggleRestaurantFavorite(_restaurantName),
                icon: const Icon(Icons.favorite_rounded, color: blue),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        bottom: 11,
        right: 12,
        child: LocalizedText(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 5)],
          ),
        ),
      ),
    ],
  ),
);
Widget _sectionLabel(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: LocalizedText(
    '• $text',
    style: const TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.bold,
      color: navy,
    ),
  ),
);

class RestaurantMapScreen extends StatefulWidget {
  const RestaurantMapScreen({super.key, required this.province});
  final String province;
  @override
  State<RestaurantMapScreen> createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  final registeredRestaurants = const [
    'مطعم البيت اليمني',
    'مطعم القلعة السياحي',
    'مطعم اليمن السعيد',
    'بيت آسيا للمأكولات',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openGoogleMaps());
  }

  Future<void> _openGoogleMaps([String? restaurant]) async {
    final query = restaurant == null
        ? 'مطاعم ${widget.province} اليمن'
        : '$restaurant، ${widget.province} اليمن';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('تعذر فتح خرائط Google على هذا الجهاز.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: LocalizedText('خريطة مطاعم ${widget.province}'),
        actions: [
          IconButton(
            onPressed: _openGoogleMaps,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _whiteCard(),
            child: Column(
              children: [
                const Icon(Icons.map_rounded, color: blue, size: 60),
                const SizedBox(height: 8),
                LocalizedText(
                  'خريطة Google لمطاعم ${widget.province}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 5),
                const LocalizedText(
                  'يمكنك تصفح الخريطة والبحث عن المطاعم أو استخدام موقعك الحالي داخل خرائط Google.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _BookingButton('فتح خرائط Google', _openGoogleMaps),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _BookingSectionTitle('المطاعم المسجلة'),
          ...registeredRestaurants.map(
            (restaurant) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: _whiteCard(),
              child: ListTile(
                leading: const Icon(Icons.restaurant_rounded, color: blue),
                title: LocalizedText(
                  restaurant,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: LocalizedText('${widget.province} - اليمن'),
                trailing: const Icon(Icons.location_on_rounded, color: orange),
                onTap: () => _openGoogleMaps(restaurant),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.name});
  final String name;
  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool menu = true;
  final cart = <String, int>{};
  final dishes = const [
    ('لحم مندي', '5,000', Icons.rice_bowl_rounded),
    ('لحم حنيذ', '5,000', Icons.restaurant_rounded),
    ('بنت الصحن', '5,000', Icons.bakery_dining_rounded),
    ('وجبة عائلية', '12,000', Icons.dinner_dining_rounded),
    ('مندي دجاج', '4,000', Icons.lunch_dining_rounded),
    ('مشاوي مشكلة', '7,000', Icons.outdoor_grill_rounded),
  ];
  final offers = const [
    ('عرض مندي العائلة', '12,000', Icons.dinner_dining_rounded),
    ('وجبة الحنيذ الخاصة', '9,000', Icons.restaurant_rounded),
    ('عرض بنت الصحن', '3,500', Icons.bakery_dining_rounded),
  ];
  void add(String item) => setState(() => cart[item] = (cart[item] ?? 0) + 1);
  Future<void> _shareRestaurant() async {
    final link =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${widget.name} صنعاء اليمن')}';
    final opened = await launchUrl(
      Uri(
        scheme: 'sms',
        queryParameters: {'body': 'أرشح لك ${widget.name} عبر حجوزاتكم: $link'},
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('تعذر فتح المشاركة على هذا الجهاز.')),
      );
    }
  }

  void _showDetail(String title, String detail, IconData icon) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: appTextDirection,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: blue),
                const SizedBox(height: 10),
                LocalizedText(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 7),
                LocalizedText(detail, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const LocalizedText('حسناً'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
          children: [
            _restaurantHero(context, widget.name),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  LocalizedText(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const LocalizedText(
                    'يمني · مأكولات شعبية',
                    style: TextStyle(color: blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _detailActions(context),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => menu = true),
                    style: FilledButton.styleFrom(
                      backgroundColor: menu ? blue : const Color(0xffffc221),
                    ),
                    child: const LocalizedText('عرض المنيو'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => menu = false),
                    style: FilledButton.styleFrom(
                      backgroundColor: menu ? const Color(0xffffc221) : blue,
                    ),
                    child: const LocalizedText('العروض'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: .60,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: (menu ? dishes : offers)
                  .map((dish) => _dishCard(dish, isOffer: !menu))
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantOrderScreen(items: cart),
                ),
              ),
              backgroundColor: const Color(0xffffc221),
              icon: const Icon(
                Icons.shopping_cart_checkout_rounded,
                color: navy,
              ),
              label: LocalizedText(
                'إتمام الطلب (${cart.values.fold(0, (a, b) => a + b)})',
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    ),
  );
  Widget _detailActions(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    childAspectRatio: 1.12,
    crossAxisSpacing: 7,
    mainAxisSpacing: 7,
    children: [
      _detailAction(
        Icons.access_time_rounded,
        'وقت التوصيل',
        () => _showDetail(
          'وقت التوصيل',
          'الوقت المتوقع لوصول الطلب من 25 إلى 35 دقيقة، ويمكن متابعته بعد تأكيد الطلب.',
          Icons.access_time_rounded,
        ),
      ),
      _detailAction(
        Icons.location_on_rounded,
        'الموقع',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RestaurantMapScreen(province: 'صنعاء'),
          ),
        ),
      ),
      _detailAction(
        Icons.star_rounded,
        'التقييم',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RestaurantRatingScreen()),
        ),
      ),
      _detailAction(
        Icons.table_restaurant_rounded,
        'احجز طاولة',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RestaurantTableBookingScreen(),
          ),
        ),
      ),
      _detailAction(Icons.favorite_rounded, 'المفضلة', () {
        setState(() => appSession.toggleRestaurantFavorite(widget.name));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: LocalizedText('تم تحديث المفضلة.')));
      }),
      _detailAction(
        Icons.call_rounded,
        'اتصال',
        () => launchUrl(Uri.parse('tel:+967700000000')),
      ),
      _detailAction(Icons.share_rounded, 'مشاركة', _shareRestaurant),
      _detailAction(
        Icons.sell_rounded,
        'العروض',
        () => setState(() => menu = false),
      ),
    ],
  );
  Widget _detailAction(IconData icon, String text, VoidCallback tap) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      decoration: _whiteCard(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: blue, size: 23),
          const SizedBox(height: 3),
          LocalizedText(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    ),
  );
  Widget _dishCard((String, String, IconData) dish, {bool isOffer = false}) =>
      Container(
        decoration: _whiteCard(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_restaurantImage, fit: BoxFit.cover),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: blue,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            appSession.toggleRestaurantFavorite(dish.$1),
                        icon: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    LocalizedText(
                      dish.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      isOffer
                          ? 'عرض خاص لفترة محدودة'
                          : 'أرز يمني مع مكونات طازجة',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, color: navy),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 34,
                      child: Stack(
                        children: [
                          Positioned(
                            left: -5,
                            bottom: -7,
                            child: IconButton(
                              onPressed: () => add(dish.$1),
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                color: blue,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 7,
                            bottom: 5,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 82),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: LocalizedText(
                                  '${dish.$2} ر.ي',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: const TextStyle(
                                    color: blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
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
          ],
        ),
      );
}

class RestaurantOrderScreen extends StatefulWidget {
  const RestaurantOrderScreen({super.key, required this.items});
  final Map<String, int> items;
  @override
  State<RestaurantOrderScreen> createState() => _RestaurantOrderScreenState();
}

class _RestaurantOrderScreenState extends State<RestaurantOrderScreen> {
  late final Map<String, int> items = Map.of(widget.items);
  String mode = 'توصيل';
  String payment = 'محفظة مالية محلية';
  String? selectedWallet;
  static const localWallets = [
    'جوالى',
    'جيب',
    'فلوسك',
    'ون كاش',
    'الكريمي جوال',
  ];
  int get total => items.values.fold(0, (sum, count) => sum + count * 5000);
  void confirm() {
    if (!appSession.isRegistered) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SignUpScreen(
            roomName: 'طلب مطعم',
            price: '0',
            image: _restaurantImage,
            restaurantFlow: true,
          ),
        ),
      );
    } else if (!appSession.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RestaurantConfirmationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _restaurantHero(context, 'إتمام الطلب'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  _orderModeButton(
                    'احجز طاولتك',
                    Icons.table_restaurant_rounded,
                  ),
                  const SizedBox(width: 6),
                  _orderModeButton('توصيل', Icons.delivery_dining_rounded),
                  const SizedBox(width: 6),
                  _orderModeButton('استلام', Icons.shopping_bag_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: _whiteCard(),
              child: Column(
                children: items.entries
                    .map(
                      (item) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            _restaurantImage,
                            width: 65,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: LocalizedText(
                          item.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const LocalizedText('5,000 ر.ي'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => setState(() {
                                if (item.value > 1) {
                                  items[item.key] = item.value - 1;
                                } else {
                                  items.remove(item.key);
                                }
                              }),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: blue,
                              ),
                            ),
                            LocalizedText(
                              '${item.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(
                                () => items[item.key] = item.value + 1,
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 105,
              padding: const EdgeInsets.all(10),
              decoration: _whiteCard(),
              child: TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n('ملاحظات الطلب (اختياري)'),
                  hintText: l10n('اكتب ملاحظاتك هنا'),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _BookingSectionTitle('اختيار طريقة الدفع'),
            Row(
              children: [
                Expanded(
                  child: _paymentCard(
                    'محفظة مالية محلية',
                    Icons.account_balance_wallet_rounded,
                    payment == 'محفظة مالية محلية',
                    _selectWallet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _paymentCard(
                    'بطاقة ائتمان',
                    Icons.credit_card_rounded,
                    payment == 'بطاقة ائتمان',
                    () => setState(() {
                      payment = 'بطاقة ائتمان';
                      selectedWallet = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _paymentCard(
                    'الدفع عند الاستلام',
                    Icons.payments_rounded,
                    payment == 'الدفع عند الاستلام',
                    () => setState(() {
                      payment = 'الدفع عند الاستلام';
                      selectedWallet = null;
                    }),
                  ),
                ),
              ],
            ),
            if (payment == 'محفظة مالية محلية')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: _whiteCard(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: blue,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: LocalizedText(
                          selectedWallet == null
                              ? 'اختر المحفظة المالية المناسبة لإتمام الدفع'
                              : 'المحفظة المختارة: $selectedWallet',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectWallet,
                        child: LocalizedText(
                          selectedWallet == null ? 'اختيار' : 'تغيير',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  _totalRow('المجموع الفرعي', '$total ر.ي'),
                  _totalRow(
                    'رسوم التوصيل',
                    mode == 'توصيل' ? '1,000 ر.ي' : '0 ر.ي',
                  ),
                  _totalRow('طريقة الدفع', selectedWallet ?? payment),
                  const Divider(),
                  _totalRow(
                    'الإجمالي',
                    '${total + (mode == 'توصيل' ? 1000 : 0)} ر.ي',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BookingButton('تأكيد الطلب', confirm),
          ],
        ),
      ),
    ),
  );
  Widget _orderModeButton(String value, IconData icon) => Expanded(
    child: SizedBox(
      height: 43,
      child: FilledButton.icon(
        onPressed: () {
          if (value == 'احجز طاولتك') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RestaurantTableBookingScreen(),
              ),
            );
          } else {
            setState(() => mode = value);
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: mode == value ? blue : Colors.white,
          foregroundColor: mode == value ? Colors.white : navy,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          side: const BorderSide(color: Color(0xffdbe2f0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: LocalizedText(
            value,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
  Future<void> _selectWallet() async {
    final wallet = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: appTextDirection,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LocalizedText(
                  'اختر المحفظة المالية',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                ...localWallets.map(
                  (wallet) => ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: blue,
                    ),
                    title: LocalizedText(
                      wallet,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: selectedWallet == wallet
                        ? const Icon(Icons.check_circle_rounded, color: blue)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, wallet),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (wallet != null && mounted) {
      setState(() {
        payment = 'محفظة مالية محلية';
        selectedWallet = wallet;
      });
    }
  }

  Widget _paymentCard(
    String title,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffe5efff) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? blue : const Color(0xffd5dcea),
          width: selected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: blue, size: 32),
          const SizedBox(height: 6),
          LocalizedText(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: blue, size: 16),
        ],
      ),
    ),
  );
  Widget _totalRow(String title, String value, {bool strong = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      LocalizedText(
        title,
        style: TextStyle(
          fontSize: strong ? 18 : 15,
          fontWeight: strong ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      LocalizedText(
        value,
        style: TextStyle(
          color: blue,
          fontSize: strong ? 20 : 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

class RestaurantTableBookingScreen extends StatefulWidget {
  const RestaurantTableBookingScreen({super.key});

  @override
  State<RestaurantTableBookingScreen> createState() =>
      _RestaurantTableBookingScreenState();
}

class _RestaurantTableBookingScreenState
    extends State<RestaurantTableBookingScreen> {
  int guests = 4;
  String seating = 'جلسة داخلية';
  String time = '12:00 م';
  DateTime bookingDate = DateTime(2026, 5, 22);
  final notesController = TextEditingController();
  static const times = [
    '12:00 م',
    '1:00 م',
    '2:00 م',
    '7:00 م',
    '8:00 م',
    '9:00 م',
  ];
  static const seatingOptions = [
    ('جلسة داخلية', Icons.weekend_rounded),
    ('جلسة خارجية', Icons.deck_rounded),
    ('جلسة عربية', Icons.grid_view_rounded),
    ('جلسة عائلية', Icons.family_restroom_rounded),
    ('جلسة VIP', Icons.workspace_premium_rounded),
  ];

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: bookingDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) setState(() => bookingDate = picked);
  }

  void confirm() {
    if (appSession.isRegistered && appSession.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const RestaurantConfirmationScreen(tableBooking: true),
        ),
      );
    } else if (!appSession.isRegistered) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SignUpScreen(
            roomName: 'حجز طاولة',
            price: '0',
            image: _restaurantImage,
            restaurantFlow: true,
            tableBooking: true,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  String get dateLabel =>
      '${bookingDate.day} ${_arabicMonth(bookingDate.month)} ${bookingDate.year}';
  String _arabicMonth(int month) => const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ][month - 1];

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _restaurantHero(context, 'تفاصيل حجز طاولة'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: _whiteCard(),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: blue, size: 32),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'تفاصيل حجز طاولة',
                          style: TextStyle(
                            fontSize: 21,
                            color: navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LocalizedText(
                          'اختر التفاصيل المناسبة لإتمام الحجز',
                          style: TextStyle(color: blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _restaurantInfoCard(),
            const SizedBox(height: 12),
            const _BookingSectionTitle('تفاصيل الحجز'),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month_rounded,
                      color: blue,
                    ),
                    title: const LocalizedText(
                      'تاريخ الحجز',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: TextButton(
                      onPressed: _pickDate,
                      child: LocalizedText(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time_rounded, color: blue),
                    title: const LocalizedText(
                      'وقت الحجز',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: LocalizedText(
                      time,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: times
                        .map(
                          (value) => ChoiceChip(
                            label: LocalizedText(value),
                            selected: time == value,
                            selectedColor: blue,
                            labelStyle: TextStyle(
                              color: time == value ? Colors.white : navy,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setState(() => time = value),
                          ),
                        )
                        .toList(),
                  ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, color: blue),
                      const SizedBox(width: 10),
                      const LocalizedText(
                        'عدد الأشخاص',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(
                          () => guests = guests > 1 ? guests - 1 : 1,
                        ),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: blue,
                        ),
                      ),
                      LocalizedText(
                        '$guests',
                        style: const TextStyle(
                          fontSize: 21,
                          color: navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => guests++),
                        icon: const Icon(Icons.add_circle_outline, color: blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('نوع الجلسة'),
            SizedBox(
              height: 105,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: seatingOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final option = seatingOptions[index];
                  final selected = seating == option.$1;
                  return InkWell(
                    onTap: () => setState(() => seating = option.$1),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 112,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xffedf4ff)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? blue : const Color(0xffd8dee9),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            option.$2,
                            color: selected ? blue : const Color(0xff8f46e8),
                            size: 35,
                          ),
                          const SizedBox(height: 7),
                          LocalizedText(
                            option.$1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? blue : navy,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const _BookingSectionTitle('ملاحظات الحجز (اختياري)'),
            Container(
              height: 110,
              decoration: _whiteCard(),
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n('اكتب أي طلب خاص أو ملاحظات للمطعم...'),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _whiteCard(),
              child: const Row(
                children: [
                  Icon(
                    Icons.table_restaurant_rounded,
                    size: 38,
                    color: Color(0xff8f46e8),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'متاح 6 طاولات في هذا الوقت',
                          style: TextStyle(
                            color: navy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LocalizedText(
                          'احجز الآن لضمان توفر طاولتك المفضلة',
                          style: TextStyle(
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.verified_rounded, color: blue, size: 34),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: _whiteCard(),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: blue, size: 34),
                  SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'سيتم تأكيد الحجز فوراً عند توفر الطاولة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        LocalizedText(
                          'ستصلك رسالة تأكيد مباشرة إلى جوالك بتفاصيل الحجز',
                          style: TextStyle(fontSize: 12, color: orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: orange,
                      side: const BorderSide(color: orange),
                    ),
                    child: const LocalizedText(
                      'رجوع',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _BookingButton('تأكيد الحجز', confirm),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Center(
              child: LocalizedText(
                'حجزك آمن ومضمون',
                style: TextStyle(
                  color: orange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _restaurantInfoCard() => Container(
  padding: const EdgeInsets.all(9),
  decoration: _whiteCard(),
  child: Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          _restaurantImage,
          width: 130,
          height: 85,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              _restaurantName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            LocalizedText(
              '★★★★★',
              style: TextStyle(
                color: Color(0xffffbd00),
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: orange, size: 17),
                LocalizedText(' صنعاء - شارع التحرير'),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
);

class RestaurantConfirmationScreen extends StatelessWidget {
  const RestaurantConfirmationScreen({
    super.key,
    this.tableBooking = false,
    this.image = _restaurantImage,
  });
  final bool tableBooking;
  final String image;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: tableBooking
              ? _tableBookingContent(context)
              : _orderContent(context),
        ),
      ),
    ),
  );

  List<Widget> _tableBookingContent(BuildContext context) => [
    _restaurantHero(context, 'تم تأكيد الحجز'),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(15),
      decoration: _whiteCard(),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'تم تأكيد الحجز بنجاح',
                  style: TextStyle(
                    fontSize: 25,
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                LocalizedText(
                  'تم حجز طاولتك بنجاح ... منتظرين حضوركم في الوقت المحدد',
                  style: TextStyle(color: blue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          const Icon(Icons.verified_user_rounded, size: 72, color: blue),
        ],
      ),
    ),
    const SizedBox(height: 12),
    _restaurantInfoCard(),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(13),
      decoration: _whiteCard(),
      child: Column(
        children: [
          _bookingDetail('رقم الحجز', 'RT-202225'),
          _bookingDetail('التاريخ', '2026/5/22'),
          _bookingDetail('الوقت', '12:00 م'),
          _bookingDetail('عدد الأشخاص', '4'),
          _bookingDetail('نوع الجلسة', 'جلسة داخلية'),
        ],
      ),
    ),
    const SizedBox(height: 14),
    Row(
      children: [
        Expanded(
          child: _statusBox(
            'تم التأكيد',
            'تم استلام حجزك بنجاح',
            Icons.verified_rounded,
            blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statusBox(
            'موعد الحجز',
            'بإنتظاركم في الموعد المحدد',
            Icons.calendar_month_rounded,
            orange,
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: _whiteCard(),
      child: const Row(
        children: [
          Icon(Icons.phone_android_rounded, color: blue),
          SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: LocalizedText(
                'سيتم إرسال رسالة تأكيد إلى جوالك مع تفاصيل الحجز',
                maxLines: 1,
                style: TextStyle(
                  color: blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const Center(
      child: LocalizedText(
        'طلبك آمن ومضمون',
        style: TextStyle(
          fontSize: 21,
          color: orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    const SizedBox(height: 10),
    _BookingButton(
      'عرض تفاصيل الحجز',
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RestaurantInvoiceScreen(tableBooking: true),
        ),
      ),
    ),
  ];

  List<Widget> _orderContent(BuildContext context) => [
    _restaurantHero(context, 'تم تأكيد الطلب'),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteCard(),
      child: const Column(
        children: [
          Icon(Icons.verified_user_rounded, size: 70, color: blue),
          LocalizedText(
            'تم تأكيد الطلب بنجاح',
            style: TextStyle(
              fontSize: 24,
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          LocalizedText(
            'تم استلام طلبك بنجاح، وسيتم التواصل معك قريباً',
            textAlign: TextAlign.center,
            style: TextStyle(color: blue),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    _restaurantInfoCard(),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: _whiteCard(),
      child: Column(
        children: [
          _bookingDetail('رقم الطلب', 'RE-202225'),
          _bookingDetail('التاريخ', '2026/5/22'),
          _bookingDetail('الوقت', '09:41 ص'),
          _bookingDetail('عدد الأصناف', '3'),
          _bookingDetail('طريقة الاستلام', 'توصيل'),
        ],
      ),
    ),
    const SizedBox(height: 12),
    _BookingButton(
      'تتبع الطلب',
      () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryTrackingScreen()),
      ),
    ),
    const SizedBox(height: 10),
    OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RestaurantInvoiceScreen()),
      ),
      icon: const Icon(Icons.receipt_long_rounded),
      label: const LocalizedText('عرض تفاصيل الفاتورة'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: blue,
      ),
    ),
  ];

  Widget _bookingDetail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        LocalizedText(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Divider(color: Color(0xffe5e1d7))),
        LocalizedText(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, color: blue),
        ),
      ],
    ),
  );

  Widget _statusBox(String title, String detail, IconData icon, Color color) =>
      Container(
        height: 105,
        padding: const EdgeInsets.all(10),
        decoration: _whiteCard(),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 5),
                LocalizedText(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            LocalizedText(
              detail,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

/// بيانات التتبع الحالية؛ تستبدل لاحقاً بإحداثيات السائق الفعلية القادمة من GPS/لوحة التحكم.
class DeliveryTrackingData {
  const DeliveryTrackingData({
    required this.orderId,
    required this.driverName,
    required this.driverPhone,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.estimatedMinutes,
  });

  final String orderId;
  final String driverName;
  final String driverPhone;
  final double latitude;
  final double longitude;
  final String status;
  final int estimatedMinutes;
}

class DeliveryTrackingScreen extends StatelessWidget {
  const DeliveryTrackingScreen({
    super.key,
    this.tracking = const DeliveryTrackingData(
      orderId: 'RE-202225',
      driverName: 'أحمد محمد',
      driverPhone: '+967700000000',
      latitude: 15.3694,
      longitude: 44.1910,
      status: 'الطلب في الطريق إليك',
      estimatedMinutes: 18,
    ),
  });

  final DeliveryTrackingData tracking;

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${tracking.latitude},${tracking.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showRating(BuildContext context) {
    var rating = 5;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LocalizedText(
                'تقييم خدمة التوصيل',
                style: TextStyle(
                  fontSize: 21,
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setSheetState(() => rating = index + 1),
                    icon: Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xffffbd00),
                      size: 34,
                    ),
                  ),
                ),
              ),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n('اكتب ملاحظتك عن خدمة التوصيل (اختياري)'),
                ),
              ),
              const SizedBox(height: 12),
              _BookingButton('إرسال التقييم', () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: LocalizedText('شكراً لتقييمك، تم حفظه بنجاح.'),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      appBar: AppBar(title: const LocalizedText('تتبع الطلب')),
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              height: 215,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xffe9efff),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/quick_delivery_banner.png',
                      fit: BoxFit.cover,
                      color: Colors.white.withValues(alpha: .72),
                      colorBlendMode: BlendMode.lighten,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 31,
                          backgroundColor: blue,
                          child: Icon(
                            Icons.delivery_dining_rounded,
                            color: Colors.white,
                            size: 39,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: LocalizedText(
                            tracking.status,
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _whiteCard(),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 27,
                    backgroundColor: blue,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 33,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'مندوب التوصيل: ${tracking.driverName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LocalizedText(
                          'الوصول المتوقع خلال ${tracking.estimatedMinutes} دقيقة',
                          style: const TextStyle(
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        launchUrl(Uri.parse('tel:${tracking.driverPhone}')),
                    icon: const Icon(Icons.call_rounded, color: blue, size: 30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _BookingSectionTitle('حالة الطلب'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  _trackStep(
                    Icons.receipt_long_rounded,
                    'تم استلام الطلب',
                    'تم استلام طلبك من المطعم',
                    true,
                  ),
                  _trackStep(
                    Icons.restaurant_rounded,
                    'جارٍ تحضير الطلب',
                    'يجري تجهيز طلبك الآن',
                    true,
                  ),
                  _trackStep(
                    Icons.delivery_dining_rounded,
                    tracking.status,
                    'موقع المندوب يتحدث من نظام GPS عند الربط',
                    true,
                  ),
                  _trackStep(
                    Icons.home_rounded,
                    'تم التسليم',
                    'سيظهر عند وصول الطلب إليك',
                    false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _whiteCard(),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: navy),
                  const SizedBox(width: 8),
                  const LocalizedText(
                    'رقم الطلب',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  LocalizedText(
                    tracking.orderId,
                    style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _openGoogleMaps,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: _whiteCard(),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, color: blue),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: LocalizedText(
                        'التتبع المباشر عبر GPS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, color: blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const LocalizedText(
              'ستصل إحداثيات المندوب وحالة الطلب مباشرة من لوحة التحكم عند ربط نظام التتبع.',
              textAlign: TextAlign.center,
              style: TextStyle(color: navy),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _showRating(context),
              icon: const Icon(Icons.star_rate_rounded),
              label: const LocalizedText('تقييم خدمة التوصيل'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _trackStep(
    IconData icon,
    String title,
    String detail,
    bool completed,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: completed ? blue : const Color(0xffd8dee9),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                title,
                style: TextStyle(
                  color: completed ? navy : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              LocalizedText(
                detail,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        if (completed) const Icon(Icons.check_circle_rounded, color: blue),
      ],
    ),
  );
}

class RestaurantInvoiceScreen extends StatelessWidget {
  const RestaurantInvoiceScreen({super.key, this.tableBooking = false});
  final bool tableBooking;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _restaurantHero(context, 'الفاتورة'),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 9,
                ),
                decoration: _whiteCard(),
                child: const Column(
                  children: [
                    LocalizedText(
                      'الفاتورة',
                      style: TextStyle(
                        fontSize: 24,
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LocalizedText(
                      'راجع تفاصيل الفاتورة ... واحتفظ بنسخة منها',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _invoiceHeader(),
            const SizedBox(height: 12),
            const _BookingSectionTitle('تفاصيل الفاتورة'),
            _invoiceDetails(),
            const SizedBox(height: 12),
            const _BookingSectionTitle('تفاصيل الطلب'),
            _orderItems(),
            const SizedBox(height: 10),
            _totals(),
            const SizedBox(height: 12),
            _deliveryInfo(),
            const SizedBox(height: 14),
            ServiceCompletionFooter(
              serviceKey: 'مطاعم',
              serviceName: 'مطاعم',
              invoiceText:
                  'فاتورة مطعم القلعة السياحي\nرقم الفاتورة: INV-010101',
              ratingScreenBuilder: (_) => const RestaurantRatingScreen(),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _invoiceHeader() => Container(
    padding: const EdgeInsets.all(11),
    decoration: _whiteCard(),
    child: Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                _restaurantImage,
                width: 112,
                height: 75,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'مطعم القلعة السياحي',
                    style: TextStyle(
                      fontSize: 19,
                      color: blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LocalizedText(
                    'فاتورة مدفوعة',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LocalizedText('طريقة الدفع: محفظة جيب', style: TextStyle(color: navy)),
                ],
              ),
            ),
          ],
        ),
        const Divider(),
        const Row(
          children: [
            Expanded(child: _InvoiceHeaderValue('رقم الطلب', 'RE-010101')),
            Expanded(child: _InvoiceHeaderValue('رقم الفاتورة', 'INV-010101')),
            Expanded(child: _InvoiceHeaderValue('التاريخ', '2026/5/22')),
            Expanded(child: _InvoiceHeaderValue('الوقت', '09:41 ص')),
          ],
        ),
      ],
    ),
  );

  Widget _invoiceDetails() => Container(
    padding: const EdgeInsets.all(12),
    decoration: _whiteCard(),
    child: const Column(
      children: [
        _InvoiceLine('اسم المطعم', 'مطعم القلعة السياحي'),
        _InvoiceLine('رقم الطلب', 'RE-010101'),
        _InvoiceLine('رقم الفاتورة', 'INV-010101'),
        _InvoiceLine('تاريخ الإصدار', '2026/5/22 - 09:41 ص'),
        _InvoiceLine('اسم العميل', 'محمد أحمد'),
        _InvoiceLine('طريقة الدفع', 'محفظة جيب'),
        _InvoiceLine('حالة الفاتورة', 'مدفوعة'),
      ],
    ),
  );

  Widget _orderItems() => Container(
    padding: const EdgeInsets.all(7),
    decoration: _whiteCard(),
    child: Table(
      columnWidths: const {
        0: FlexColumnWidth(3.4),
        1: FlexColumnWidth(1.15),
        2: FlexColumnWidth(1.8),
        3: FlexColumnWidth(1.9),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          children: [
            _InvoiceTableText('المنتج', bold: true),
            _InvoiceTableText('الكمية', bold: true),
            _InvoiceTableText('سعر الوحدة', bold: true),
            _InvoiceTableText('الإجمالي', bold: true),
          ],
        ),
        ...const ['لحم مندي', 'لحم حنيذ', 'بنت الصحن', 'وجبة عائلية'].map(
          (name) => TableRow(
            decoration: const BoxDecoration(color: Color(0xfff8faff)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        _restaurantImage,
                        width: 30,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: LocalizedText(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _InvoiceTableText('1'),
              const _InvoiceTableText('5,000 ر.ي'),
              const _InvoiceTableText('5,000 ر.ي'),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _totals() => Container(
    padding: const EdgeInsets.all(12),
    decoration: _whiteCard(),
    child: Column(
      children: [
        _total('المجموع الفرعي', '15,000 ر.ي'),
        _total('رسوم التوصيل', tableBooking ? '0 ر.ي' : '1,000 ر.ي'),
        _total('الخصم', '0 ر.ي'),
        const Divider(),
        _total('الإجمالي', tableBooking ? '0 ر.ي' : '16,000 ر.ي', strong: true),
      ],
    ),
  );

  Widget _deliveryInfo() => Container(
    padding: const EdgeInsets.all(12),
    decoration: _whiteCard(),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_rounded, color: orange),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                'معلومات التوصيل',
                style: TextStyle(fontWeight: FontWeight.bold, color: blue),
              ),
              SizedBox(height: 3),
              LocalizedText(
                'عنوان التوصيل: شارع التحرير - جوار مدرسة جمال عبد الناصر - صنعاء',
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _total(String title, String amount, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        LocalizedText(
          title,
          style: TextStyle(
            fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            color: navy,
            fontSize: strong ? 19 : 15,
          ),
        ),
        const Spacer(),
        LocalizedText(
          amount,
          style: TextStyle(
            color: strong ? navy : blue,
            fontSize: strong ? 20 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _InvoiceHeaderValue extends StatelessWidget {
  const _InvoiceHeaderValue(this.title, this.value);
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Column(
      children: [
        LocalizedText(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: navy),
        ),
        const SizedBox(height: 3),
        LocalizedText(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _InvoiceTableText extends StatelessWidget {
  const _InvoiceTableText(this.value, {this.bold = false});
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: LocalizedText(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          fontSize: bold ? 10 : 11,
          color: bold ? navy : blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        LocalizedText(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xffe4dfd2))),
        LocalizedText(
          value,
          style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class RestaurantRatingScreen extends StatefulWidget {
  const RestaurantRatingScreen({super.key});
  @override
  State<RestaurantRatingScreen> createState() => _RestaurantRatingScreenState();
}

class _RestaurantRatingScreenState extends State<RestaurantRatingScreen> {
  final scores = <String, double>{
    'الأجواء': 4,
    'الموقع': 4,
    'الخدمة': 4,
    'النظافة': 4,
    'الطعم': 4,
    'السعر': 4,
  };
  final comment = TextEditingController();
  DateTime date = DateTime.now();

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    final overall =
        scores.values.reduce((value, score) => value + score) / scores.length;
    await serviceReviewStore.saveReview(
      'مطاعم',
      rating: overall.round(),
      comment: comment.text.trim(),
    );
    if (!mounted) return;
    setState(() => date = DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LocalizedText(
          tr('تم حفظ تقييمك بنجاح', 'Your review has been saved.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _restaurantHero(context, tr('تقييم المطعم', 'Restaurant rating')),
            const SizedBox(height: 12),
            _restaurantInfoCard(),
            const SizedBox(height: 12),
            ...scores.entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(9),
                decoration: _whiteCard(),
                child: Row(
                  children: [
                    Expanded(
                      child: LocalizedText(
                        isEnglish
                            ? {
                                'الأجواء': 'Ambience',
                                'الموقع': 'Location',
                                'الخدمة': 'Service',
                                'النظافة': 'Cleanliness',
                                'الطعم': 'Taste',
                                'السعر': 'Value',
                              }[entry.key]!
                            : entry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    LocalizedText(entry.value.toStringAsFixed(1)),
                    const SizedBox(width: 8),
                    ...List.generate(
                      5,
                      (i) => InkWell(
                        onTap: () =>
                            setState(() => scores[entry.key] = i + 1.0),
                        child: Icon(
                          i < entry.value
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xffffbd00),
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 150,
              padding: const EdgeInsets.all(10),
              decoration: _whiteCard(),
              child: TextField(
                controller: comment,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: tr('تقييم المطعم', 'Restaurant review'),
                  hintText: tr(
                    'اكتب تجربتك...',
                    'Write about your experience...',
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              '${tr('تاريخ التقييم', 'Review date')}: ${date.year}/${date.month}/${date.day}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _BookingButton(
              tr('حفظ / تعديل التقييم', 'Save / edit review'),
              _saveReview,
            ),
          ],
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  void _signIn() {
    if (phone.text.trim().length < 7 || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(
            tr(
              'أدخل رقم الهاتف وكلمة مرور صحيحة للمتابعة.',
              'Enter a valid phone number and password to continue.',
            ),
          ),
        ),
      );
      return;
    }
    appSession.authenticate();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProvincesScreen()),
    );
  }

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (!appSession.canUseBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('فعّل الدخول بالبصمة أولاً من نافذة حسابي.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final auth = LocalAuthentication();
      final supported =
          await auth.isDeviceSupported() && await auth.canCheckBiometrics;
      final available = await auth.getAvailableBiometrics();
      if (!supported || available.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: LocalizedText('لا توجد بصمة أو Face ID مسجلة في الهاتف.'),
            ),
          );
        }
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: 'أكد هويتك للدخول إلى حجوزاتكم',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      if (authenticated && mounted) {
        appSession.authenticate();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProvincesScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText('تعذر تشغيل المصادقة البيومترية على هذا الجهاز.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/signup_background.png', fit: BoxFit.cover),
          Container(color: Colors.white.withValues(alpha: .25)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo_transparent.png',
                    height: 210,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .80),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => appSession.setLanguage('العربية'),
                            child: const LocalizedText('العربية'),
                          ),
                          const LocalizedText('|'),
                          TextButton(
                            onPressed: () => appSession.setLanguage('English'),
                            child: const LocalizedText('English'),
                          ),
                        ],
                      ),
                      LocalizedText(
                        tr('مرحباً بك في حجوزاتكم', 'Welcome to Hujuzatcom'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: tr('رقم الهاتف', 'Phone number'),
                          prefixIcon: const Icon(
                            Icons.phone_android,
                            color: blue,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: tr('كلمة المرور', 'Password'),
                          prefixIcon: const Icon(Icons.lock, color: blue),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: () {},
                          child: LocalizedText(tr('نسيت كلمة السر', 'Forgot password?')),
                        ),
                      ),
                      _BookingButton(tr('تسجيل الدخول', 'Sign in'), _signIn),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _biometric,
                        icon: const Icon(Icons.fingerprint, size: 30),
                        label: LocalizedText(
                          appSession.canUseBiometrics
                              ? tr('الدخول بالبصمة', 'Sign in with biometrics')
                              : tr(
                                  'فعّل الدخول بالبصمة من حسابي',
                                  'Enable biometrics in Account',
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(
                              roomName: '',
                              price: '',
                              image: _restaurantImage,
                              nextScreen: ProvincesScreen(),
                            ),
                          ),
                        ),
                        child: LocalizedText(
                          tr('إنشاء حساب جديد', 'Create a new account'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
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
  );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appSession,
    builder: (_, _) => Directionality(
      textDirection: appTextDirection,
      child: Scaffold(
        appBar: AppBar(title: const LocalizedText('المفضلة')),
        bottomNavigationBar: const HujuzatBottomNav(selectedIndex: 1),
        body: appSession.favoriteRestaurants.isEmpty
            ? const Center(
                child: LocalizedText(
                  'لا توجد عناصر في المفضلة بعد',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(14),
                children: appSession.favoriteRestaurants
                    .map(
                      (name) => ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: Colors.white,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            _restaurantImage,
                            width: 58,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: LocalizedText(name),
                        trailing: IconButton(
                          onPressed: () =>
                              appSession.toggleRestaurantFavorite(name),
                          icon: const Icon(Icons.favorite, color: Colors.red),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(name: name),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    ),
  );
}

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      appBar: AppBar(title: LocalizedText(tr('حجوزاتي', 'My bookings'))),
      bottomNavigationBar: const HujuzatBottomNav(selectedIndex: 2),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _whiteCard(),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    _restaurantImage,
                    width: 95,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        _restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      LocalizedText(tr('طلب/حجز مؤكد', 'Confirmed order / booking')),
                      LocalizedText(
                        '22 May 2026 · 09:41',
                        style: const TextStyle(color: blue),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RestaurantInvoiceScreen(),
                    ),
                  ),
                  child: LocalizedText(tr('التفاصيل', 'Details')),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _toggleBiometric(BuildContext context, bool value) async {
    if (!value) {
      await appSession.setBiometrics(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LocalizedText('تم إيقاف الدخول بالبصمة لهذا الحساب.')),
        );
      }
      return;
    }
    try {
      final auth = LocalAuthentication();
      final supported =
          await auth.isDeviceSupported() && await auth.canCheckBiometrics;
      final available = await auth.getAvailableBiometrics();
      if (!supported || available.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: LocalizedText(
                'سجّل بصمة أو Face ID في إعدادات الهاتف أولاً، ثم أعد المحاولة.',
              ),
            ),
          );
        }
        return;
      }
      final confirmed = await auth.authenticate(
        localizedReason: 'أكد هويتك لتفعيل الدخول بالبصمة إلى حجوزاتكم',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      if (confirmed) {
        await appSession.setBiometrics(true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: LocalizedText('تم تفعيل الدخول بالبصمة بنجاح.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LocalizedText('تعذر تفعيل البيومتري على هذا الجهاز.')),
        );
      }
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final name = TextEditingController(text: appSession.displayName);
    final phone = TextEditingController(text: appSession.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LocalizedText('تعديل بيانات الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: l10n('الاسم الكامل'),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n('رقم الهاتف'),
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const LocalizedText('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const LocalizedText('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true &&
        name.text.trim().isNotEmpty &&
        phone.text.trim().isNotEmpty) {
      await appSession.setProfile(
        name: name.text.trim(),
        mobile: phone.text.trim(),
      );
    }
    name.dispose();
    phone.dispose();
  }

  Future<void> _changePassword(BuildContext context) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LocalizedText('تغيير كلمة السر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n('كلمة السر الجديدة')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n('تأكيد كلمة السر')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const LocalizedText('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const LocalizedText('تحديث'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      final message = password.text.length < 6
          ? 'كلمة السر يجب أن تتكون من 6 أحرف على الأقل.'
          : password.text != confirmation.text
          ? 'كلمتا السر غير متطابقتين.'
          : 'تم تحديث كلمة السر بنجاح.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: LocalizedText(message)));
    }
    password.dispose();
    confirmation.dispose();
  }

  Future<void> _googleAccount(BuildContext context) async {
    if (appSession.googleLinked) {
      await appSession.setGoogleLinked(false);
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(
              tr('تم إلغاء ربط حساب Google.', 'Google account unlinked.'),
            ),
          ),
        );
      }
      return;
    }
    try {
      final account = await _requestGoogleAccount();
      await appSession.setGoogleLinked(true, email: account.email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(
              tr(
                'تم ربط ${account.email} بنجاح.',
                '${account.email} is linked.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(
              tr(
                'تعذر فتح اختيار حساب Google. تأكد من إعداد OAuth الرسمي للتطبيق وحسابات Google على الهاتف.',
                'Could not open Google account selection. Check the app OAuth setup and Google accounts on the phone.',
              ),
            ),
          ),
        );
      }
    }
  }

  String _notificationSubtitle() {
    switch (appSession.notificationMode) {
      case 'silent':
        return tr(
          'تصل الإشعارات دون صوت أو اهتزاز',
          'Notifications arrive without sound or vibration',
        );
      case 'disabled':
        return tr('عدم استقبال الإشعارات', 'Do not receive notifications');
      case 'hidden':
        return tr(
          'لا تظهر معاينات الإشعارات على الشاشة',
          'Hide notification previews on screen',
        );
      default:
        return tr(
          'العروض وحالة الطلب والحجوزات',
          'Offers, order status, and bookings',
        );
    }
  }

  Future<void> _notificationSettings(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Directionality(
          textDirection: appTextDirection,
          child: RadioGroup<String>(
            groupValue: appSession.notificationMode,
            onChanged: (value) => Navigator.pop(sheetContext, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: LocalizedText(
                    tr('إعدادات الإشعارات', 'Notification settings'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'all',
                  title: LocalizedText(tr('استقبال الإشعارات', 'Receive notifications')),
                  subtitle: LocalizedText(
                    tr(
                      'الحجوزات والطلبات والعروض',
                      'Bookings, orders, and offers',
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'silent',
                  title: LocalizedText(tr('صامت', 'Silent')),
                  subtitle: LocalizedText(
                    tr('بدون صوت أو اهتزاز', 'Without sound or vibration'),
                  ),
                ),
                RadioListTile<String>(
                  value: 'disabled',
                  title: LocalizedText(
                    tr('عدم استقبال الإشعارات', 'Do not receive notifications'),
                  ),
                ),
                RadioListTile<String>(
                  value: 'hidden',
                  title: LocalizedText(
                    tr(
                      'عدم ظهور تفاصيل الإشعارات',
                      'Hide notification details',
                    ),
                  ),
                  subtitle: LocalizedText(
                    tr(
                      'تصل الإشعارات مع إخفاء المعاينة',
                      'Notifications arrive with previews hidden',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) await appSession.setNotificationMode(selected);
  }

  Future<void> _appearanceSettings(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Directionality(
          textDirection: appTextDirection,
          child: RadioGroup<String>(
            groupValue: appSession.appearance,
            onChanged: (value) => Navigator.pop(sheetContext, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: LocalizedText(
                    tr('المظهر', 'Appearance'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'system',
                  title: LocalizedText(tr('تلقائي حسب الجهاز', 'Match device settings')),
                ),
                RadioListTile<String>(
                  value: 'light',
                  title: LocalizedText(tr('فاتح', 'Light')),
                ),
                RadioListTile<String>(
                  value: 'dark',
                  title: LocalizedText(tr('داكن', 'Dark')),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) await appSession.setAppearance(selected);
  }

  Future<void> _shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: tr(
          'جرّب تطبيق حجوزاتكم لحجوزات الفنادق والمطاعم والخدمات في اليمن.',
          'Try Hujuzatcom for hotels, restaurants, and services in Yemen.',
        ),
        title: tr('مشاركة تطبيق حجوزاتكم', 'Share Hujuzatcom'),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(
              tr(
                'سيتاح التقييم بعد نشر التطبيق في المتجر.',
                'Rating will be available after the app is published in the store.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(
              tr(
                'تعذر فتح نافذة التقييم حالياً.',
                'Unable to open the rating dialog right now.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appSession,
    builder: (_, _) => Directionality(
      textDirection: appTextDirection,
      child: Scaffold(
        appBar: AppBar(
          title: LocalizedText(
            appSession.language == 'English' ? 'My account' : 'حسابي',
          ),
        ),
        bottomNavigationBar: const HujuzatBottomNav(selectedIndex: 3),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _whiteCard(),
              child: Row(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 33,
                        backgroundColor: blue,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        left: -4,
                        child: IconButton(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: LocalizedText(
                                    'إضافة الصورة الشخصية ستكون متاحة عند ربط تخزين الصور بلوحة التحكم.',
                                  ),
                                ),
                              ),
                          icon: const CircleAvatar(
                            radius: 13,
                            backgroundColor: orange,
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          appSession.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LocalizedText(
                          appSession.phone,
                          style: const TextStyle(color: blue),
                        ),
                        LocalizedText(
                          tr(
                            'إدارة بيانات الحساب والأمان',
                            'Manage your profile and security',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editProfile(context),
                    icon: const Icon(Icons.edit_rounded, color: blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BookingSectionTitle(tr('الحساب والأمان', 'Account & security')),
            Container(
              decoration: _whiteCard(),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.manage_accounts_rounded,
                      color: blue,
                    ),
                    title: LocalizedText(
                      tr('تعديل بيانات الحساب', 'Edit account details'),
                    ),
                    subtitle: LocalizedText(
                      tr('الاسم ورقم الهاتف', 'Name and phone number'),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _editProfile(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: blue),
                    title: LocalizedText(tr('تغيير كلمة السر', 'Change password')),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _changePassword(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.g_mobiledata_rounded,
                      color: Colors.red,
                    ),
                    title: LocalizedText(
                      tr('التسجيل عبر Google', 'Sign in with Google'),
                    ),
                    subtitle: LocalizedText(
                      appSession.googleLinked
                          ? (appSession.googleEmail.isEmpty
                                ? tr('الحساب مرتبط', 'Account linked')
                                : appSession.googleEmail)
                          : tr(
                              'اختر حساباً من الهاتف أو أضف حساباً آخر',
                              'Choose a phone account or add another one',
                            ),
                    ),
                    trailing: Switch(
                      value: appSession.googleLinked,
                      onChanged: (_) => _googleAccount(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BookingSectionTitle(tr('الإعدادات', 'Settings')),
            Container(
              decoration: _whiteCard(),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_active_rounded,
                      color: blue,
                    ),
                    title: LocalizedText(tr('الإشعارات', 'Notifications')),
                    subtitle: LocalizedText(_notificationSubtitle()),
                    trailing: const Icon(Icons.tune_rounded, color: blue),
                    onTap: () => _notificationSettings(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: blue),
                    title: LocalizedText(
                      tr('تسجيل الدخول بالبيومتري', 'Biometric sign-in'),
                    ),
                    subtitle: LocalizedText(
                      appSession.canUseBiometrics
                          ? tr(
                              'مفعّل لهذا الحساب وسيبقى محفوظاً حتى توقفه',
                              'Enabled for this account and stays on until you disable it',
                            )
                          : tr(
                              'البصمة أو Face ID عند توفره',
                              'Fingerprint or Face ID when available',
                            ),
                    ),
                    trailing: Switch(
                      value: appSession.canUseBiometrics,
                      onChanged: (value) => _toggleBiometric(context, value),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.brightness_6_rounded,
                      color: blue,
                    ),
                    title: LocalizedText(tr('المظهر', 'Appearance')),
                    subtitle: LocalizedText(
                      appSession.appearance == 'dark'
                          ? tr('داكن', 'Dark')
                          : appSession.appearance == 'light'
                          ? tr('فاتح', 'Light')
                          : tr('تلقائي حسب الجهاز', 'Match device settings'),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _appearanceSettings(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: blue),
                    title: LocalizedText(tr('لغة التطبيق', 'App language')),
                    subtitle: LocalizedText(
                      appSession.language == 'English' ? 'English' : 'العربية',
                    ),
                    trailing: DropdownButton<String>(
                      value: appSession.language,
                      items: const [
                        DropdownMenuItem(
                          value: 'العربية',
                          child: LocalizedText('العربية'),
                        ),
                        DropdownMenuItem(
                          value: 'English',
                          child: LocalizedText('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          appSession.setLanguage(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: LocalizedText(
                                value == 'English'
                                    ? 'Language changed to English.'
                                    : 'تم تغيير اللغة إلى العربية.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BookingSectionTitle(tr('تطبيق حجوزاتكم', 'Hujuzatcom app')),
            Container(
              decoration: _whiteCard(),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.star_rate_rounded, color: orange),
                    title: LocalizedText(tr('تقييم التطبيق', 'Rate the app')),
                    subtitle: LocalizedText(
                      tr(
                        'شاركنا رأيك في المتجر',
                        'Share your feedback in the store',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _rateApp(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded, color: blue),
                    title: LocalizedText(tr('مشاركة التطبيق', 'Share the app')),
                    subtitle: LocalizedText(
                      tr(
                        'أرسل التطبيق إلى من تحب',
                        'Send the app to people you know',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _shareApp(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: _whiteCard(),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.favorite_rounded, color: blue),
                    title: LocalizedText(tr('المفضلة', 'Favorites')),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long_rounded,
                      color: blue,
                    ),
                    title: LocalizedText(tr('حجوزاتي', 'My bookings')),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyBookingsScreen(),
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
