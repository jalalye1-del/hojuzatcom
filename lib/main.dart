import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'control_panel_data.dart';

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

/// سلة التوصيل المحلية؛ تُستبدل لاحقاً بمصدر بيانات السلة في لوحة التحكم.
final deliveryBasket = DeliveryBasket();

class DeliveryCartItem {
  DeliveryCartItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
    this.quantity = 1,
  });
  final String id;
  final String name;
  final String category;
  final int unitPrice;
  int quantity;
  int get total => unitPrice * quantity;
}

class DeliveryBasket extends ChangeNotifier {
  final List<DeliveryCartItem> items = [];

  /// عنوان التسليم يأتي من المستخدم أو من واجهة تحديد الموقع مستقبلاً.
  /// يُحفظ منفصلاً عن الأصناف حتى يمكن للوحة التحكم وإدارة الطلبات قراءته.
  String? deliveryLocation;

  void setDeliveryLocation(String value) {
    deliveryLocation = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  void add(DeliveryCartItem item) {
    final existing = items
        .where((element) => element.id == item.id)
        .firstOrNull;
    if (existing == null) {
      items.add(item);
    } else {
      existing.quantity += item.quantity;
    }
    notifyListeners();
  }

  void change(DeliveryCartItem item, int value) {
    item.quantity = value < 0 ? 0 : value;
    if (item.quantity == 0) items.remove(item);
    notifyListeners();
  }

  int get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get deliveryFee => items.isEmpty ? 0 : 600;
  int get total => subtotal + deliveryFee;
  void clear() {
    items.clear();
    notifyListeners();
  }
}

final controlPanelRepository = LocalControlPanelRepository();

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

class AppSession extends ChangeNotifier {
  bool isRegistered = false;
  // لا تُحفظ جلسة الدخول بين تشغيلات التطبيق. المستخدم المسجل يبدأ دائماً
  // من شاشة الدخول، بينما يستمر الزائر في التصفح فقط.
  bool isAuthenticated = false;
  bool biometricsEnabled = false;

  /// الحساب الذي منح الموافقة على استخدام بصمته للدخول. لا نخزن بيانات
  /// البصمة نفسها؛ نظام iOS / Android هو الوحيد الذي يديرها بشكل آمن.
  String biometricAccount = '';
  bool notificationsEnabled = true;
  bool googleLinked = false;
  String googleEmail = '';
  String notificationMode = 'all';
  String appearance = 'system';
  String language = 'العربية';
  String displayName = 'محمد أحمد';
  String phone = '700 000 000';
  final favoriteRestaurants = <String>{};

  String _accountKey(String value) => value.replaceAll(RegExp(r'[^0-9+]'), '');

  /// يضمن أن تفعيل البصمة يخص الحساب الحالي ولا ينتقل إلى حساب آخر على
  /// الهاتف نفسه. تبقى القيمة محفوظة حتى يوقفها المستخدم بنفسه.
  bool get canUseBiometrics =>
      biometricsEnabled &&
      biometricAccount.isNotEmpty &&
      biometricAccount == _accountKey(phone);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isRegistered = prefs.getBool('registered') ?? false;
    biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
    biometricAccount = prefs.getString('biometrics_account') ?? '';
    notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    googleLinked = prefs.getBool('google_linked') ?? false;
    googleEmail = prefs.getString('google_email') ?? '';
    notificationMode =
        prefs.getString('notification_mode') ??
        (notificationsEnabled ? 'all' : 'disabled');
    appearance = prefs.getString('appearance') ?? 'system';
    language = prefs.getString('language') == 'English' ? 'English' : 'العربية';
    displayName = prefs.getString('profile_name') ?? 'محمد أحمد';
    phone = prefs.getString('profile_phone') ?? '700 000 000';
    // ترحيل آمن للمستخدمين الذين فعّلوا البصمة قبل إضافة ربطها بالحساب.
    if (biometricsEnabled && biometricAccount.isEmpty) {
      biometricAccount = _accountKey(phone);
      await prefs.setString('biometrics_account', biometricAccount);
    }
    isAuthenticated = false;
  }

  Future<void> register({required String name, required String mobile}) async {
    final previousAccount = _accountKey(phone);
    final nextAccount = _accountKey(mobile);
    isRegistered = true;
    isAuthenticated = true;
    displayName = name;
    phone = mobile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('registered', true);
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_phone', mobile);
    // لا نسمح لحساب جديد باستعمال بصمة كانت مفعّلة لحساب سابق على الهاتف.
    if (biometricAccount.isNotEmpty &&
        biometricAccount != nextAccount &&
        previousAccount != nextAccount) {
      biometricsEnabled = false;
      biometricAccount = '';
      await prefs.setBool('biometrics_enabled', false);
      await prefs.remove('biometrics_account');
    }
    notifyListeners();
  }

  void authenticate() {
    isAuthenticated = true;
    notifyListeners();
  }

  void signOut() {
    isAuthenticated = false;
    notifyListeners();
  }

  Future<void> setBiometrics(bool value) async {
    biometricsEnabled = value;
    biometricAccount = value ? _accountKey(phone) : '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', value);
    if (value) {
      await prefs.setString('biometrics_account', biometricAccount);
    } else {
      await prefs.remove('biometrics_account');
    }
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    final selectedLanguage = value == 'English' ? 'English' : 'العربية';
    if (language == selectedLanguage) return;
    language = selectedLanguage;
    (await SharedPreferences.getInstance()).setString(
      'language',
      selectedLanguage,
    );
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    notificationMode = value ? 'all' : 'disabled';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    await prefs.setString('notification_mode', notificationMode);
    notifyListeners();
  }

  /// preference is persisted locally now and can be synchronized with the
  /// notification rules stored in the administration panel later.
  Future<void> setNotificationMode(String value) async {
    const validModes = {'all', 'silent', 'disabled', 'hidden'};
    notificationMode = validModes.contains(value) ? value : 'all';
    notificationsEnabled = notificationMode != 'disabled';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_mode', notificationMode);
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (appearance) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setAppearance(String value) async {
    appearance = {'system', 'light', 'dark'}.contains(value) ? value : 'system';
    await (await SharedPreferences.getInstance()).setString(
      'appearance',
      appearance,
    );
    notifyListeners();
  }

  Future<void> setProfile({
    required String name,
    required String mobile,
  }) async {
    final oldAccount = _accountKey(phone);
    final newAccount = _accountKey(mobile);
    displayName = name;
    phone = mobile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_phone', mobile);
    // تغيير رقم الحساب يتطلب تفعيل البصمة مرة أخرى من صاحب الحساب الجديد.
    if (biometricsEnabled && oldAccount != newAccount) {
      biometricsEnabled = false;
      biometricAccount = '';
      await prefs.setBool('biometrics_enabled', false);
      await prefs.remove('biometrics_account');
    }
    notifyListeners();
  }

  Future<void> setGoogleLinked(bool value, {String email = ''}) async {
    googleLinked = value;
    googleEmail = value ? email : '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_linked', value);
    await prefs.setString('google_email', googleEmail);
    notifyListeners();
  }

  void toggleRestaurantFavorite(String id) {
    favoriteRestaurants.contains(id)
        ? favoriteRestaurants.remove(id)
        : favoriteRestaurants.add(id);
    notifyListeners();
  }
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
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => appSession.isRegistered
                ? const LoginScreen()
                : const ProvincesScreen(),
          ),
        );
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
    MaterialPageRoute(builder: (_) => ServicesScreen(province: province)),
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
                    label: Text(localizedProvince(provinces[i])),
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
                            child: Text(
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
              Text(
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
    child: Text(
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
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
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
                title: Text(localizedProvince(p)),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'هذه مساحة بيانات الجهة المعلنة. عند الربط بلوحة التحكم ستصل هنا الصورة، الخصم، الوصف، رابط الحجز وبيانات التواصل.',
                'Advertiser details will appear here when the control panel is connected.',
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('استكشف العرض', 'Explore offer')),
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
      'تأجير سيارات ونقل',
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
                  Text(
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
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
  Widget _bigAd(BuildContext context) => InkWell(
    onTap: () => _providers(context, 'عرض تأجير السيارات'),
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
                      Text(
                        'خصم حتى 50%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 27,
                        ),
                      ),
                      Text(
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
          child: const Text(
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
    onTap: () => _providers(context, title),
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
                  Text(
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
                      Text(
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
                        child: Text(
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
                      Text(
                        '$price ر.ي',
                        style: const TextStyle(
                          color: blue,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$oldPrice ر.ي',
                        style: const TextStyle(
                          color: Color(0xff8a91a3),
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
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
  void _providers(BuildContext context, String service) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => service == 'فنادق'
          ? HotelListingsScreen(province: province)
          : service == 'مطاعم'
          ? RestaurantDiscoveryScreen(province: province)
          : service == 'التوصيل السريع'
          ? QuickDeliveryScreen(province: province)
          : service == 'قاعات أفراح ومناسبات'
          ? HallDiscoveryScreen(province: province)
          : service == 'شاليهات'
          ? ChaletDiscoveryScreen(province: province)
          : ProvidersScreen(service: service, province: province),
    ),
  );
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
              child: Text(
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
          child: Text(
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
    child: Text(
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
        Text(
          '30%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
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
                      Navigator.of(context).popUntil((route) => route.isFirst);
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
                        Text(
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
          content: Text(tr('اكتب ملاحظتك أولاً.', 'Write your note first.')),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
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
        title: Text(tr('الدعم والخط الساخن', 'Support & hotline')),
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
                  Text(
                    tr('كيف يمكننا مساعدتك؟', 'How can we help?'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
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
                  label: Text(tr('رسالة مباشرة', 'Direct message')),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp'),
                ),
                ButtonSegment(
                  value: 2,
                  icon: const Icon(Icons.call_rounded),
                  label: Text(tr('اتصال', 'Call')),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (value) => setState(() => tab = value.first),
            ),
            const SizedBox(height: 14),
            if (tab == 0) ...[
              Text(
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
                        label: Text(
                          tr('إرسال إلى الإدارة', 'Send to administration'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
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
                    title: Text(
                      tab == 1
                          ? 'WhatsApp ${index + 1}'
                          : '${tr('مركز الاتصال', 'Call center')} ${index + 1}',
                    ),
                    subtitle: Text(
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
    if (selectedFilter == 2)
      hotels.sort(
        (a, b) => int.parse(
          a.$4.replaceAll(',', ''),
        ).compareTo(int.parse(b.$4.replaceAll(',', ''))),
      );
    if (selectedFilter == 3)
      hotels.sort((a, b) => double.parse(b.$3).compareTo(double.parse(a.$3)));
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
                Text(
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
                hintText: 'إبحث عن فندق وأكثر...',
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
                  Text(
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
                  Text(
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
                        child: Text(
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
                      Text(
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
                      child: const Text(
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
                    child: Text(
                      '$price ر.ي',
                      maxLines: 1,
                      style: const TextStyle(
                        color: blue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
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
          Text(
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
                          content: Text('مشاركة الفندق قيد التجهيز'),
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
                          content: Text('تمت إضافة الفندق إلى المفضلة'),
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
                        Text(
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
                  hintText: 'إبحث عن نوع الغرفة أو الطيرمانة...',
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
                        child: Text(
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
                        child: const Text(
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
                      Text(
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
                  child: Text(
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
                child: Text(
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
                      SnackBar(content: Text('تم التحقق من توفر $name')),
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
                      child: Text(
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
                    child: Text(
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
                Text(
                  amount,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
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
                      child: Text(
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
                  Text(
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: minus,
              icon: const Icon(Icons.remove_circle_outline, color: blue),
            ),
            Text(
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
        [
              ('توصيل من المطار', Icons.airport_shuttle_rounded),
              ('وجبة الغداء', Icons.restaurant_rounded),
              ('ساونا وجاكوزي', Icons.hot_tub_rounded),
              ('صالة رياضية', Icons.fitness_center_rounded),
              ('منتجع صحي', Icons.spa_rounded),
              ('مسبح', Icons.pool_rounded),
            ]
            .map(
              (service) => InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تمت إضافة ${service.$1} إلى الحجز')),
                ),
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
                      Text(
                        service.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'اضغط للإضافة',
                        style: TextStyle(color: Colors.white70, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
  );
  Widget _bookingTotals() => Container(
    padding: const EdgeInsets.all(12),
    decoration: _whiteCard(),
    child: const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تكلفة الغرفة'),
            Text(
              '20,000 ر.ي',
              style: TextStyle(color: blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تكلفة الخدمات المضافة'),
            Text(
              '0 ر.ي',
              style: TextStyle(color: blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الإجمالي العام',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '20,000 ر.ي',
              style: TextStyle(
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
                    Text(
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
                    Text(
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
                    SnackBar(content: Text('${facility.$1} متوفرة في الفندق')),
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
                      Text(
                        facility.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
            ),
            const SizedBox(height: 4),
            ...lines.map(
              (line) => Text(
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
              const Text(
                'الخدمات المختارة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 7),
              if (services.isEmpty)
                const Text('لا توجد خدمات إضافية')
              else
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(service.icon, color: blue, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(service.name)),
                        Text(
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
            Text(
              label,
              style: TextStyle(
                fontSize: strong ? 17 : 14,
                fontWeight: strong ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
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
          content: Text('يرجى الموافقة على الأحكام وسياسة الخصوصية'),
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
                        Text(
                          tr('إنشاء حساب جديد', 'Create account'),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
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
                          title: Text(
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
                        Text(
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
        labelText: label,
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

class GuestDetailsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) => BookingFrame(
    step: 2,
    title: 'إدخال البيانات',
    image: image,
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
        _formField('الاسم الكامل', Icons.person_outline),
        _formField(
          'رقم الجوال (مفضل عليه الواتساب)',
          Icons.phone_rounded,
          type: TextInputType.phone,
        ),
        _formField(
          'البريد الإلكتروني (اختياري)',
          Icons.email_outlined,
          type: TextInputType.emailAddress,
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _whiteCard(),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'الجنسية',
              prefixIcon: Icon(Icons.public_rounded, color: blue),
              border: InputBorder.none,
            ),
            items: const [
              DropdownMenuItem(value: 'يمني', child: Text('يمني')),
              DropdownMenuItem(value: 'سعودي', child: Text('سعودي')),
              DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
            ],
            onChanged: (_) {},
          ),
        ),
        _formField('رقم الهوية / جواز السفر', Icons.badge_outlined),
        Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: _whiteCard(),
          child: const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'طلبات خاصة (اختياري)',
              hintText: 'اكتب أي طلبات أو ملاحظات خاصة...',
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
          child: const Text(
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
                roomName: roomName,
                price: price,
                image: image,
                services: services,
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
          content: Text(
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
                    Text(
                      widget.roomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('فندق سبأ صنعاء • ليلة واحدة'),
                    Text(
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
                title: Text(
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
                content: Text(
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
                    Text(
                      'تم تأكيد الحجز بنجاح',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
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
                        Text(
                          '4.6 ممتاز',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'فندق سبأ صنعاء',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
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
                        Text('صنعاء - شارع الخمسين'),
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
              const Text(
                'إجمالي المبلغ المدفوع',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: navy,
                ),
              ),
              const SizedBox(width: 10),
              Text(
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
                child: Text(
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
                  Text(
                    'تأكيد فوري',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: blue),
                  SizedBox(width: 5),
                  Text(
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
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الحجز مؤكد وجاهز للعرض في حجوزاتي')),
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
          icon: const Icon(Icons.download_rounded),
          label: const Text('تحميل الفاتورة'),
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
                    Text(
                      'تم الدفع بنجاح',
                      style: TextStyle(
                        fontSize: 18,
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('شكراً لك، تم استلام الدفع بنجاح'),
                    SizedBox(height: 5),
                    Text(
                      'رقم الفاتورة  001000253',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
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
                    Text(
                      'فندق سبأ صنعاء',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
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
                        Text('شارع الخمسين - صنعاء'),
                      ],
                    ),
                    Text(
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
                  Text(
                    'للمزيد من التفاصيل والعروض',
                    style: TextStyle(fontWeight: FontWeight.bold, color: navy),
                  ),
                  SizedBox(height: 3),
                  Text('امسح رمز QR لعرض الحجز أو إدارة الحجز عبر التطبيق.'),
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
                child: Text(
                  'تم الدفع بنجاح\nتم استلام المبلغ وقيد تأكيد الحجز، نتطلع لخدمتكم قريباً.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال الفاتورة إلى الطابعة عند توفرها.'),
                  ),
                ),
                icon: const Icon(Icons.print_rounded),
                label: const Text('طباعة الفاتورة'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم تنزيل نسخة PDF بعد ربط خدمة الفواتير.'),
                  ),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('تنزيل PDF'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تجهيز الفاتورة للمشاركة.')),
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('مشاركة'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BookingButton(
          'تقييم الإقامة',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RatingScreen(image: image)),
          ),
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

  void _saveRating() {
    setState(() {
      _savedAt = DateTime.now();
      _isSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ تقييمك بنجاح. يمكنك تعديله في أي وقت.'),
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
                child: Text(
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
              Text(
                'تاريخ التقييم: $_savedDate',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.schedule_rounded, color: blue),
              const SizedBox(width: 5),
              Text(
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
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
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
              Text(
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
            decoration: const InputDecoration(
              labelText: 'تقييم الفندق',
              hintText: 'اكتب تجربتك في الإقامة...',
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
                  child: Text(
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
                      child: Text(
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
                Text(
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
      child: Text(
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
      child: Text(
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
                  Text(
                    item.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
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
Widget _formField(String label, IconData icon, {TextInputType? type}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _whiteCard(),
      child: TextField(
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
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
              child: Text(
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
          child: Text(
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
        child: Text(
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
                hintText: 'ابحث عن اسم الصالة أو المنطقة',
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
    ).showSnackBar(SnackBar(content: Text('تم تفعيل تصنيف ${filters[i].$1}'))),
    child: Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: _whiteCard(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(filters[i].$2, color: blue, size: 28),
          const SizedBox(height: 5),
          Text(
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
            child: Text(
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
            child: Text(
              '★ 4.7 (128) · شارع الستين',
              style: TextStyle(color: blue, fontSize: 12),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(9, 5, 9, 9),
            child: Text(
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
    child: const Text(
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
                  const Text(
                    'قاعة تاج سبأ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const Text(
                    '★ 4.8 (156 تقييم)',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'التحرير - شارع الستين',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  const Text(
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
                    child: const Text('عرض التفاصيل'),
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
        child: Text(
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
                        child: Text(
                          '★ 4.7\n(128 تقييم)',
                          style: TextStyle(
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
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
                  Text(
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
                              Text(
                                '1,200,000 ريال يمني',
                                style: TextStyle(
                                  color: Color(0xff14a765),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 21,
                                ),
                              ),
                              Text('خصم 20% · أفضل الأسعار متاحة اليوم'),
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
                          child: const Text('احجز الآن'),
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
              child: const Text(
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
        Text(
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
                      label: Text(x),
                      selected: occasion == x,
                      selectedColor: const Color(0xffdce8ff),
                      onSelected: (_) => setState(() => occasion = x),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 9),
            TextField(
              decoration: const InputDecoration(
                labelText: 'اسم العريس والعروس (اختياري)',
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
                Text(
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
                const Text('عدد المدعوين التقريبي'),
              ],
            ),
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات خاصة (اختياري)',
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
                            label: Text(x),
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
          Text(
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
      Text(value, style: const TextStyle(fontSize: 12)),
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
            Text(
              name,
              style: const TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('$province - شارع الستين'),
            const Text(
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
        child: Text(
          'السعر الإجمالي\nخصم 20% مفعّل',
          style: TextStyle(color: navy, fontWeight: FontWeight.bold),
        ),
      ),
      Text(
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
                        child: Text(
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
                  Text(
                    'تم الحجز والدفع بنجاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
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
                            Text(
                              'فاتورة حجز ودفع',
                              style: const TextStyle(
                                fontSize: 22,
                                color: navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'INV-2024-0005687',
                              style: const TextStyle(color: blue),
                            ),
                            const Text(
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
                    child: const Text(
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة الفاتورة'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print),
                    label: const Text('طباعة الفاتورة'),
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

const _chaletImage = 'assets/Services images/شاليهات.jpg';
const _chaletBanner = 'assets/images/chalet_booking_banner.png';

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

class ChaletDiscoveryScreen extends StatefulWidget {
  const ChaletDiscoveryScreen({super.key, required this.province});
  final String province;
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
    var list = _chalets
        .where((x) => x.name.contains(query) || x.city.contains(query))
        .toList();
    if (filter == 'الأعلى تقييماً')
      list.sort((a, b) => b.rating.compareTo(a.rating));
    if (filter == 'الأقل سعراً')
      list.sort((a, b) => a.price.compareTo(b.price));
    if (filter == 'الأقرب إليك')
      list.sort((a, b) => a.city == widget.province ? -1 : 1);
    return list;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          children: [
            _chaletHero(context, province: widget.province),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن شاليه أو مدينة',
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
                separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                        Text(
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
            const SizedBox(height: 15),
            const _BookingSectionTitle('شاليهات مميزة'),
            ...results.map(
              (x) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _ChaletListCard(
                  chalet: x,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChaletDetailScreen(chalet: x),
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

Widget _chaletHero(BuildContext context, {required String province}) {
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
        Image.asset(_chaletBanner, fit: BoxFit.cover),
        Container(color: const Color(0x18001818)),
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
                const SnackBar(content: Text('لا توجد إشعارات جديدة')),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xff087370),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          right: 16,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شاليهات $province',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              const Text(
                'إقامات عائلية مميزة في أجمل المواقع',
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
  );
}

class _ChaletListCard extends StatelessWidget {
  const _ChaletListCard({required this.chalet, required this.onTap});
  final ChaletData chalet;
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
                Image.asset(_chaletImage, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => appSession.toggleRestaurantFavorite(
                        'chalet-${chalet.id}',
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
                  Text(
                    chalet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '⌖ ${chalet.city}',
                    style: const TextStyle(
                      color: Color(0xff087370),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
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
                            child: Text(
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
                  Text(
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
  const ChaletDetailScreen({super.key, required this.chalet});
  final ChaletData chalet;
  @override
  State<ChaletDetailScreen> createState() => _ChaletDetailScreenState();
}

class _ChaletDetailScreenState extends State<ChaletDetailScreen> {
  bool favorite = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.chalet;
    return Directionality(
      textDirection: appTextDirection,
      child: Scaffold(
        bottomNavigationBar: const HujuzatBottomNav(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            children: [
              _chaletDetailHero(
                context,
                c,
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
                          child: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 27,
                              color: Color(0xff087370),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff8edd7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'مميز',
                            style: TextStyle(
                              color: Color(0xffbd8431),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '⌖ ${c.city}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '★ ${c.rating}  (${c.reviews} تقييم)',
                      style: const TextStyle(
                        color: orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(c.description, style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.spaceAround,
                      runSpacing: 12,
                      children: [
                        _ChaletAmenity(Icons.pool_rounded, 'مسبح خاص'),
                        _ChaletAmenity(Icons.wifi_rounded, 'واي فاي'),
                        _ChaletAmenity(Icons.deck_rounded, 'جلسات خارجية'),
                        _ChaletAmenity(
                          Icons.local_parking_rounded,
                          'موقف سيارة',
                        ),
                        _ChaletAmenity(Icons.kitchen_rounded, 'مطبخ'),
                        ...c.features
                            .where(
                              (feature) => ![
                                'مسبح خاص',
                                'واي فاي',
                                'جلسات خارجية',
                                'موقف سيارة',
                                'مطبخ',
                              ].contains(feature),
                            )
                            .map(
                              (feature) => _ChaletAmenity(
                                Icons.check_circle_outline_rounded,
                                feature,
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _BookingSectionTitle('الميزات'),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: _whiteCard(),
                child: Wrap(
                  runSpacing: 12,
                  children: [
                    _ChaletTextFeature(
                      'إطلالة على الجبال والوادي',
                      Icons.landscape_rounded,
                    ),
                    _ChaletTextFeature('تكييف مركزي', Icons.ac_unit_rounded),
                    _ChaletTextFeature(
                      'جلسات عائلية واسعة',
                      Icons.groups_rounded,
                    ),
                    _ChaletTextFeature(
                      'خدمة تنظيف',
                      Icons.cleaning_services_rounded,
                    ),
                    _ChaletTextFeature(
                      'مناطق شواء',
                      Icons.outdoor_grill_rounded,
                    ),
                    _ChaletTextFeature(
                      'خصوصية تامة',
                      Icons.verified_user_outlined,
                    ),
                    ...c.additionalDetails.entries.map(
                      (entry) => _ChaletTextFeature(
                        '${entry.key}: ${entry.value}',
                        Icons.info_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _BookingSectionTitle('معرض الصور والفيديو'),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      c.galleryImages.length +
                      c.videoUrls.length +
                      (c.galleryImages.isEmpty ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final images = c.galleryImages.isEmpty
                        ? const [_chaletImage]
                        : c.galleryImages;
                    if (index < images.length) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          images[index],
                          width: 108,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return Container(
                      width: 108,
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
                          Text(
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
                          const Text(
                            'السعر لليلة',
                            style: TextStyle(color: Colors.black54),
                          ),
                          Text(
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
                            builder: (_) => ChaletBookingScreen(chalet: c),
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
              ? _chaletImage
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
                    const SnackBar(content: Text('تمت مشاركة رابط الشاليه')),
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
        Text(
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
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class ChaletBookingScreen extends StatefulWidget {
  const ChaletBookingScreen({super.key, required this.chalet});
  final ChaletData chalet;
  @override
  State<ChaletBookingScreen> createState() => _ChaletBookingScreenState();
}

class _ChaletBookingScreenState extends State<ChaletBookingScreen> {
  DateTime arrival = DateTime.now().add(const Duration(days: 2));
  DateTime departure = DateTime.now().add(const Duration(days: 5));
  int guests = 4;
  int rooms = 1;
  int get nights => departure.difference(arrival).inDays.clamp(1, 99);
  int get total => widget.chalet.price * nights;
  Future<void> pickDate(bool isArrival) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isArrival ? arrival : departure,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null)
      setState(() {
        if (isArrival) {
          arrival = date;
          if (!departure.isAfter(arrival))
            departure = arrival.add(const Duration(days: 1));
        } else if (date.isAfter(arrival))
          departure = date;
      });
  }

  String d(DateTime x) => '${x.day}/${x.month}/${x.year}';
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _chaletHero(context, province: widget.chalet.city),
            const SizedBox(height: 12),
            BookingProgress(step: 2),
            const SizedBox(height: 12),
            _chaletSummary(widget.chalet),
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
              ('عدد الغرف', '$rooms غرفة', Icons.bed_rounded),
              ('وقت الوصول', '03:00 عصراً', Icons.access_time_rounded),
            ]),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: guests > 1 ? () => setState(() => guests--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('ضيف'),
                ),
                Text(
                  '$guests ضيوف',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => guests++),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إضافة'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _hallPriceCard(total),
            const SizedBox(height: 12),
            _BookingButton('متابعة إلى الدفع', () {
              final next = ChaletPaymentScreen(
                chalet: widget.chalet,
                arrival: arrival,
                departure: departure,
                guests: guests,
                total: total,
              );
              if (!appSession.isRegistered) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignUpScreen(
                      roomName: widget.chalet.name,
                      price: '$total',
                      image: _chaletImage,
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
          Text(
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
                child: Text(
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

Widget _chaletSummary(ChaletData c) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: _whiteCard(),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            c.galleryImages.isEmpty ? _chaletImage : c.galleryImages.first,
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
              Text(
                c.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: navy,
                  fontSize: 18,
                ),
              ),
              Text('⌖ ${c.city}'),
              Text(
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
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.total,
  });
  final ChaletData chalet;
  final DateTime arrival, departure;
  final int guests, total;
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
          padding: const EdgeInsets.all(14),
          children: [
            _chaletHero(context, province: widget.chalet.city),
            const SizedBox(height: 12),
            BookingProgress(step: 4),
            const SizedBox(height: 12),
            _chaletSummary(widget.chalet),
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
                        child: Text(
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
            _hallPriceCard(widget.total),
            const SizedBox(height: 13),
            _BookingButton(
              'ادفع الآن · ${_money(widget.total)} ر.ي',
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ChaletSuccessScreen(
                    chalet: widget.chalet,
                    arrival: widget.arrival,
                    departure: widget.departure,
                    guests: widget.guests,
                    total: widget.total,
                    method: _chaletPaymentMethods[chosen].name,
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
    required this.arrival,
    required this.departure,
    required this.guests,
    required this.total,
    required this.method,
  });
  final ChaletData chalet;
  final DateTime arrival, departure;
  final int guests, total;
  final String method;
  String get range =>
      '${arrival.day}/${arrival.month}/${arrival.year} - ${departure.day}/${departure.month}/${departure.year}';
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
                  Text(
                    'تم تأكيد الحجز بنجاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'أرسلنا تفاصيل الحجز إلى هاتفك',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            _chaletSummary(chalet),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  _InvoiceLine('رقم الحجز', 'CH-2026-000245'),
                  _InvoiceLine('تاريخ الإقامة', range),
                  _InvoiceLine('عدد الضيوف', '$guests ضيوف'),
                  _InvoiceLine('طريقة الدفع', method),
                  _InvoiceLine('حالة الدفع', 'مؤكد ✓'),
                  const Divider(height: 25),
                  _InvoiceLine('إجمالي المبلغ', '${_money(total)} ر.ي'),
                ],
              ),
            ),
            const SizedBox(height: 13),
            _BookingButton(
              'عرض تفاصيل الحجز',
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تفاصيل الحجز أصبحت محفوظة في حجوزاتي'),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تجهيز الفاتورة للتنزيل'),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('تحميل الفاتورة'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'فاتورة حجز ${chalet.name}\nرقم الحجز: CH-2026-000245\nالإجمالي: ${_money(total)} ر.ي',
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('مشاركة الفاتورة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChaletRatingScreen(chalet: chalet),
                ),
              ),
              icon: const Icon(Icons.star_outline_rounded),
              label: const Text('تقييم الشاليه'),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_rounded),
              label: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// واجهة تقييم بسيطة قابلة للحفظ لاحقاً في لوحة التحكم لكل حجز وشاليه.
class ChaletRatingScreen extends StatefulWidget {
  const ChaletRatingScreen({super.key, required this.chalet});
  final ChaletData chalet;
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
      appBar: AppBar(title: const Text('تقييم الشاليه')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _chaletSummary(widget.chalet),
          const SizedBox(height: 18),
          const Text(
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
          Text(
            '$rating من 5 · ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: comment,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'اكتب تجربتك (اختياري)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          _BookingButton('إرسال التقييم', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('شكراً، تم حفظ تقييمك بنجاح')),
            );
            Navigator.pop(context);
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

class QuickDeliveryScreen extends StatelessWidget {
  const QuickDeliveryScreen({super.key, required this.province});
  final String province;

  static const _categories = <QuickDeliveryServiceConfig>[
    QuickDeliveryServiceConfig(
      id: 'market',
      name: 'سوبر ماركت',
      icon: Icons.shopping_cart_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'beauty',
      name: 'العطور وأدوات التجميل',
      icon: Icons.spa_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'fashion',
      name: 'ملابس ومفروشات',
      icon: Icons.checkroom_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'spices',
      name: 'بهارات وأعشاب',
      icon: Icons.eco_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'meat',
      name: 'اللحوم والدواجن',
      icon: Icons.restaurant_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'bakery',
      name: 'مخبوزات وحلويات',
      icon: Icons.bakery_dining_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'gifts',
      name: 'هدايا وورود',
      icon: Icons.card_giftcard_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'stationery',
      name: 'مكتبات وقرطاسية',
      icon: Icons.menu_book_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'produce',
      name: 'الخضروات والفواكه',
      icon: Icons.apple_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'home',
      name: 'الأدوات المنزلية',
      icon: Icons.kitchen_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'pharmacy',
      name: 'صيدليات',
      icon: Icons.medical_services_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'building',
      name: 'الكهرباء ومواد بناء',
      icon: Icons.electrical_services_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'appliances',
      name: 'الأجهزة الكهربائية',
      icon: Icons.devices_other_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'online',
      name: 'المتاجر الإلكترونية',
      icon: Icons.storefront_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'cars',
      name: 'تجهيز الكوش وزينة السيارات',
      icon: Icons.car_repair_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'computers',
      name: 'الكمبيوترات ومستلزماتها',
      icon: Icons.laptop_mac_rounded,
    ),
    QuickDeliveryServiceConfig(
      id: 'other',
      name: 'احتياجات أخرى',
      icon: Icons.edit_note_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: appTextDirection,
    child: Scaffold(
      bottomNavigationBar: const HujuzatBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
          children: [
            _quickDeliveryHero(context),
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
                          Text(
                            'عروض التوصيل الحصرية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
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
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisExtent: 148,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
              ),
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _categories[i].id == 'other'
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
                            category: _categories[i].name,
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
                          service: _categories[i],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          _categories[i].name,
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
          errorBuilder: (_, __, ___) =>
              Icon(service.icon, color: blue, size: 31),
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
          errorBuilder: (_, __, ___) =>
              Icon(service.icon, color: blue, size: 31),
        ),
      );
    }
    return Icon(service.icon, color: blue, size: 31);
  }
}

Widget _quickDeliveryHero(BuildContext context) => Container(
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
              const SnackBar(content: Text('لا توجد إشعارات جديدة للتوصيل.')),
            ),
            icon: const Icon(Icons.notifications_none_rounded, color: blue),
          ),
        ),
      ),
    ],
  ),
);

/// قائمة المتاجر ومنتجاتها مصدرها في المستقبل واجهة لوحة التحكم.
class DeliveryStoresScreen extends StatelessWidget {
  const DeliveryStoresScreen({
    super.key,
    required this.province,
    required this.category,
  });
  final String province;
  final String category;
  static const _stores = [
    'هايبر سما مول',
    'سوبر ماركت المدينة',
    'متجر الوفاء',
    'ماركت الخير',
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
            _quickDeliveryHero(context),
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
                        Text(
                          'عروض $category',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Text(
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
              itemCount: _stores.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .92,
              ),
              itemBuilder: (context, index) {
                final store = _stores[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeliveryProductsScreen(
                        province: province,
                        category: category,
                        store: store,
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
                            'assets/images/quick_delivery_banner.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: navy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$category · متاح الآن',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: blue,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                '25 - 35 دقيقة · ★ 4.8',
                                style: TextStyle(
                                  fontSize: 10,
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
              label: Text('تعديل السلة (${deliveryBasket.items.length})'),
            ),
          ],
        ),
      ),
    ),
  );
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
      SnackBar(content: Text('تمت إضافة ${product.$1} إلى السلة')),
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
            _quickDeliveryHero(context),
            const SizedBox(height: 10),
            _BookingSectionTitle('${widget.store} · ${widget.category}'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _whiteCard(),
              child: const Text(
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
                            child: Text(
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
                        child: Text(
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
                            label: const Text('أضف'),
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
      child: Text(
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
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'اسم المنتج',
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
            decoration: const InputDecoration(
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
            decoration: const InputDecoration(
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
            child: Text(
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
            _quickDeliveryHero(context),
            const SizedBox(height: 12),
            const _BookingSectionTitle('احتياجات أخرى'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  const Text(
                    'اكتب طلبك وسيتولى مندوبنا شراؤه من المكان المحدد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: navy, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: place,
                    decoration: const InputDecoration(
                      labelText: 'مكان الطلب وموقعه',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deliveryLocation,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'موقع التوصيل الحالي',
                      prefixIcon: Icon(Icons.my_location_rounded),
                      hintText: 'أدخل موقع التوصيل الحالي',
                      suffixIcon: IconButton(
                        tooltip: 'استخدام موقعي الحالي',
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
                    child: Text(
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
                      label: const Text('إضافة منتج آخر'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BookingButton('أضف المنتجات إلى السلة', () {
                    if (place.text.trim().isEmpty ||
                        deliveryLocation.text.trim().isEmpty ||
                        _items.any((item) => !item.isValid)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
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
            _quickDeliveryHero(context),
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
            const _BookingSectionTitle('قائمة المشتريات'),
            AnimatedBuilder(
              animation: deliveryBasket,
              builder: (context, _) => Container(
                padding: const EdgeInsets.all(8),
                decoration: _whiteCard(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _deliveryCartHeading('المنتج', flex: 4),
                        _deliveryCartHeading('الكمية'),
                        _deliveryCartHeading('سعر الوحدة', flex: 2),
                        _deliveryCartHeading('الإجمالي', flex: 2),
                      ],
                    ),
                    const Divider(),
                    if (deliveryBasket.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'السلة فارغة. اختر منتجات من أحد الأقسام أولاً.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...deliveryBasket.items.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xfff8faff),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => deliveryBasket.change(
                                        item,
                                        item.quantity - 1,
                                      ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: blue,
                                        size: 20,
                                      ),
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => deliveryBasket.change(
                                        item,
                                        item.quantity + 1,
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: blue,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${_money(item.unitPrice)} ر.ي',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: blue,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
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
                ),
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
                  const SnackBar(content: Text('أضف منتجات إلى السلة أولاً.')),
                );
                return;
              }
              final next = DeliveryPaymentScreen(
                province: widget.province,
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
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
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
    child: Text(
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
          Text(
            title,
            style: TextStyle(
              fontSize: strong ? 19 : 15,
              fontWeight: strong ? FontWeight.bold : FontWeight.normal,
              color: navy,
            ),
          ),
          const Spacer(),
          Text(
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
    required this.total,
  });
  final String province;
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
            _quickDeliveryHero(context),
            const SizedBox(height: 14),
            const _BookingSectionTitle('اختيار طريقة الدفع'),
            const Text(
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
                        child: Text(
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
    required this.payment,
    required this.total,
  });
  final String province;
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
            _quickDeliveryHero(context),
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
                  Text(
                    'تم تأكيد طلبك بنجاح',
                    style: TextStyle(
                      fontSize: 28,
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تجهيز فاتورة الطلب للتنزيل'),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('تحميل الفاتورة'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'فاتورة طلب التوصيل\nرقم الطلب: 4654654646\nالإجمالي: ${_money(total)} ر.ي',
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('مشاركة الفاتورة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeliveryRatingScreen()),
              ),
              icon: const Icon(Icons.star_outline_rounded),
              label: const Text('تقييم خدمة التوصيل'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_rounded),
              label: const Text('العودة للرئيسية'),
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
      appBar: AppBar(title: const Text('تقييم خدمة التوصيل')),
      bottomNavigationBar: const HujuzatBottomNav(),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(Icons.delivery_dining_rounded, size: 68, color: blue),
          const SizedBox(height: 12),
          const Text(
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
            decoration: const InputDecoration(
              labelText: 'ملاحظاتك (اختياري)',
              hintText: 'اكتب تقييمك للخدمة',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          _BookingButton('إرسال التقييم', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('شكرًا لتقييمك، تم حفظه بنجاح.')),
            );
            Navigator.pop(context);
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
      appBar: AppBar(title: Text('$service في $province')),
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
            title: Text('الجهة المسجلة ${i + 1}'),
            subtitle: const Text('متاح للحجز الآن · تقييم 4.8 ★'),
            trailing: ElevatedButton(
              onPressed: () {},
              child: const Text('احجز'),
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
                hintText: 'ابحث عن نوع المطعم أو اسمه...',
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                suffixIcon: IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
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
                        Text(
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
                      child: Text(
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
                child: const Text(
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
              label: const Text(
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
            child: Text(
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
                        child: Text(
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
                      Text(
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
                        child: Text(
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
                        Text(
                          ' ${restaurant.deliveryMinutes} - ${restaurant.deliveryMinutes + 10} دقيقة',
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: blue,
                        ),
                        Text(' ${restaurant.distance} كم'),
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
                              child: Text('عرض المنيو', maxLines: 1),
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
                              child: Text(
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
                      Text(
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
                        child: Text(
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
                          child: Text(
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
        child: Text(
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
  child: Text(
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
        const SnackBar(content: Text('تعذر فتح خرائط Google على هذا الجهاز.')),
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
        title: Text('خريطة مطاعم ${widget.province}'),
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
                Text(
                  'خريطة Google لمطاعم ${widget.province}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
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
                title: Text(
                  restaurant,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${widget.province} - اليمن'),
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
    if (!opened && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح المشاركة على هذا الجهاز.')),
      );
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 7),
                Text(detail, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('حسناً'),
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
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
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
                    child: const Text('عرض المنيو'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => menu = false),
                    style: FilledButton.styleFrom(
                      backgroundColor: menu ? const Color(0xffffc221) : blue,
                    ),
                    child: const Text('العروض'),
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
              label: Text(
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
        ).showSnackBar(const SnackBar(content: Text('تم تحديث المفضلة.')));
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
          Text(
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
                    Text(
                      dish.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
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
                                child: Text(
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
                        title: Text(
                          item.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('5,000 ر.ي'),
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
                            Text(
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
              child: const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات الطلب (اختياري)',
                  hintText: 'اكتب ملاحظاتك هنا',
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
                        child: Text(
                          selectedWallet == null
                              ? 'اختر المحفظة المالية المناسبة لإتمام الدفع'
                              : 'المحفظة المختارة: $selectedWallet',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectWallet,
                        child: Text(
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
          child: Text(
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
                const Text(
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
                    title: Text(
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
          Text(
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
      Text(
        title,
        style: TextStyle(
          fontSize: strong ? 18 : 15,
          fontWeight: strong ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
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
                        Text(
                          'تفاصيل حجز طاولة',
                          style: TextStyle(
                            fontSize: 21,
                            color: navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
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
                    title: const Text(
                      'تاريخ الحجز',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: TextButton(
                      onPressed: _pickDate,
                      child: Text(
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
                    title: const Text(
                      'وقت الحجز',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
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
                            label: Text(value),
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
                      const Text(
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
                      Text(
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
                          Text(
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
                decoration: const InputDecoration(
                  hintText: 'اكتب أي طلب خاص أو ملاحظات للمطعم...',
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
                        Text(
                          'متاح 6 طاولات في هذا الوقت',
                          style: TextStyle(
                            color: navy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
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
                        Text(
                          'سيتم تأكيد الحجز فوراً عند توفر الطاولة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        Text(
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
                    child: const Text(
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
              child: Text(
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
            Text(
              _restaurantName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
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
                Text(' صنعاء - شارع التحرير'),
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
                Text(
                  'تم تأكيد الحجز بنجاح',
                  style: TextStyle(
                    fontSize: 25,
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
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
              child: Text(
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
      child: Text(
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
          Text(
            'تم تأكيد الطلب بنجاح',
            style: TextStyle(
              fontSize: 24,
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
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
      label: const Text('عرض تفاصيل الفاتورة'),
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
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Divider(color: Color(0xffe5e1d7))),
        Text(
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
                Text(
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
            Text(
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
              const Text(
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
                decoration: const InputDecoration(
                  hintText: 'اكتب ملاحظتك عن خدمة التوصيل (اختياري)',
                ),
              ),
              const SizedBox(height: 12),
              _BookingButton('إرسال التقييم', () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('شكراً لتقييمك، تم حفظه بنجاح.'),
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
      appBar: AppBar(title: const Text('تتبع الطلب')),
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
                          child: Text(
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
                        Text(
                          'مندوب التوصيل: ${tracking.driverName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
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
                      child: Text(
                        'التتبع المباشر عبر GPS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, color: blue),
                    const SizedBox(width: 6),
                    Text(
                      'طلب ${tracking.orderId}',
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ستصل إحداثيات المندوب وحالة الطلب مباشرة من لوحة التحكم عند ربط نظام التتبع.',
              textAlign: TextAlign.center,
              style: TextStyle(color: navy),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _showRating(context),
              icon: const Icon(Icons.star_rate_rounded),
              label: const Text('تقييم خدمة التوصيل'),
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
              Text(
                title,
                style: TextStyle(
                  color: completed ? navy : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
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
                    Text(
                      'الفاتورة',
                      style: TextStyle(
                        fontSize: 24,
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم إرسال الفاتورة إلى خدمة الطباعة في جهازك',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('طباعة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ستتوفر نسخة PDF عند ربط خدمة الفوترة'),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تجهيز الفاتورة للمشاركة'),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('مشاركة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BookingButton(
              'تقييم المطعم',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestaurantRatingScreen(),
                ),
              ),
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
                  Text(
                    'مطعم القلعة السياحي',
                    style: TextStyle(
                      fontSize: 19,
                      color: blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'فاتورة مدفوعة',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('طريقة الدفع: محفظة جيب', style: TextStyle(color: navy)),
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
                      child: Text(
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
              Text(
                'معلومات التوصيل',
                style: TextStyle(fontWeight: FontWeight.bold, color: blue),
              ),
              SizedBox(height: 3),
              Text(
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
        Text(
          title,
          style: TextStyle(
            fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            color: navy,
            fontSize: strong ? 19 : 15,
          ),
        ),
        const Spacer(),
        Text(
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
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: navy),
        ),
        const SizedBox(height: 3),
        Text(
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
      child: Text(
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
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xffe4dfd2))),
        Text(
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
  DateTime date = DateTime.now();

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
                      child: Text(
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
                    Text(entry.value.toStringAsFixed(1)),
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
            Text(
              '${tr('تاريخ التقييم', 'Review date')}: ${date.year}/${date.month}/${date.day}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _BookingButton(tr('حفظ / تعديل التقييم', 'Save / edit review'), () {
              setState(() => date = DateTime.now());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    tr('تم حفظ تقييمك بنجاح', 'Your review has been saved.'),
                  ),
                ),
              );
            }),
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
          content: Text(
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
          content: Text('فعّل الدخول بالبصمة أولاً من نافذة حسابي.'),
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
              content: Text('لا توجد بصمة أو Face ID مسجلة في الهاتف.'),
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
            content: Text('تعذر تشغيل المصادقة البيومترية على هذا الجهاز.'),
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
                            child: const Text('العربية'),
                          ),
                          const Text('|'),
                          TextButton(
                            onPressed: () => appSession.setLanguage('English'),
                            child: const Text('English'),
                          ),
                        ],
                      ),
                      Text(
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
                          child: Text(tr('نسيت كلمة السر', 'Forgot password?')),
                        ),
                      ),
                      _BookingButton(tr('تسجيل الدخول', 'Sign in'), _signIn),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _biometric,
                        icon: const Icon(Icons.fingerprint, size: 30),
                        label: Text(
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
                        child: Text(
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
        appBar: AppBar(title: const Text('المفضلة')),
        bottomNavigationBar: const HujuzatBottomNav(selectedIndex: 1),
        body: appSession.favoriteRestaurants.isEmpty
            ? const Center(
                child: Text(
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
                        title: Text(name),
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
      appBar: AppBar(title: Text(tr('حجوزاتي', 'My bookings'))),
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
                      Text(
                        _restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(tr('طلب/حجز مؤكد', 'Confirmed order / booking')),
                      Text(
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
                  child: Text(tr('التفاصيل', 'Details')),
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
          const SnackBar(content: Text('تم إيقاف الدخول بالبصمة لهذا الحساب.')),
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
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'سجّل بصمة أو Face ID في إعدادات الهاتف أولاً، ثم أعد المحاولة.',
              ),
            ),
          );
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
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تفعيل الدخول بالبصمة بنجاح.')),
          );
      }
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تفعيل البيومتري على هذا الجهاز.')),
        );
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final name = TextEditingController(text: appSession.displayName);
    final phone = TextEditingController(text: appSession.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل بيانات الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true &&
        name.text.trim().isNotEmpty &&
        phone.text.trim().isNotEmpty)
      await appSession.setProfile(
        name: name.text.trim(),
        mobile: phone.text.trim(),
      );
    name.dispose();
    phone.dispose();
  }

  Future<void> _changePassword(BuildContext context) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تغيير كلمة السر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة السر الجديدة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة السر'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تحديث'),
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
      ).showSnackBar(SnackBar(content: Text(message)));
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
            content: Text(
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
            content: Text(
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
            content: Text(
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
                  title: Text(
                    tr('إعدادات الإشعارات', 'Notification settings'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'all',
                  title: Text(tr('استقبال الإشعارات', 'Receive notifications')),
                  subtitle: Text(
                    tr(
                      'الحجوزات والطلبات والعروض',
                      'Bookings, orders, and offers',
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'silent',
                  title: Text(tr('صامت', 'Silent')),
                  subtitle: Text(
                    tr('بدون صوت أو اهتزاز', 'Without sound or vibration'),
                  ),
                ),
                RadioListTile<String>(
                  value: 'disabled',
                  title: Text(
                    tr('عدم استقبال الإشعارات', 'Do not receive notifications'),
                  ),
                ),
                RadioListTile<String>(
                  value: 'hidden',
                  title: Text(
                    tr(
                      'عدم ظهور تفاصيل الإشعارات',
                      'Hide notification details',
                    ),
                  ),
                  subtitle: Text(
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
                  title: Text(
                    tr('المظهر', 'Appearance'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'system',
                  title: Text(tr('تلقائي حسب الجهاز', 'Match device settings')),
                ),
                RadioListTile<String>(
                  value: 'light',
                  title: Text(tr('فاتح', 'Light')),
                ),
                RadioListTile<String>(
                  value: 'dark',
                  title: Text(tr('داكن', 'Dark')),
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
            content: Text(
              tr(
                'سيتاح التقييم بعد نشر التطبيق في المتجر.',
                'Rating will be available after the app is published in the store.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تعذر فتح نافذة التقييم حالياً.',
                'Unable to open the rating dialog right now.',
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appSession,
    builder: (_, _) => Directionality(
      textDirection: appTextDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
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
                                  content: Text(
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
                        Text(
                          appSession.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          appSession.phone,
                          style: const TextStyle(color: blue),
                        ),
                        Text(
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
                    title: Text(
                      tr('تعديل بيانات الحساب', 'Edit account details'),
                    ),
                    subtitle: Text(
                      tr('الاسم ورقم الهاتف', 'Name and phone number'),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _editProfile(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: blue),
                    title: Text(tr('تغيير كلمة السر', 'Change password')),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _changePassword(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.g_mobiledata_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      tr('التسجيل عبر Google', 'Sign in with Google'),
                    ),
                    subtitle: Text(
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
                    title: Text(tr('الإشعارات', 'Notifications')),
                    subtitle: Text(_notificationSubtitle()),
                    trailing: const Icon(Icons.tune_rounded, color: blue),
                    onTap: () => _notificationSettings(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: blue),
                    title: Text(
                      tr('تسجيل الدخول بالبيومتري', 'Biometric sign-in'),
                    ),
                    subtitle: Text(
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
                    title: Text(tr('المظهر', 'Appearance')),
                    subtitle: Text(
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
                    title: Text(tr('لغة التطبيق', 'App language')),
                    subtitle: Text(
                      appSession.language == 'English' ? 'English' : 'العربية',
                    ),
                    trailing: DropdownButton<String>(
                      value: appSession.language,
                      items: const [
                        DropdownMenuItem(
                          value: 'العربية',
                          child: Text('العربية'),
                        ),
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          appSession.setLanguage(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
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
                    title: Text(tr('تقييم التطبيق', 'Rate the app')),
                    subtitle: Text(
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
                    title: Text(tr('مشاركة التطبيق', 'Share the app')),
                    subtitle: Text(
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
                    title: Text(tr('المفضلة', 'Favorites')),
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
                    title: Text(tr('حجوزاتي', 'My bookings')),
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
