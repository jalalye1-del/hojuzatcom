import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession extends ChangeNotifier {
  static String currentLanguage = 'العربية';
  static final ValueNotifier<String> languageListenable =
      ValueNotifier<String>('العربية');
  static String currentUserIdentity = 'guest';

  bool isRegistered = false;
  bool isAuthenticated = false;
  bool biometricsEnabled = false;
  String biometricAccount = '';
  bool notificationsEnabled = true;
  bool googleLinked = false;
  String googleEmail = '';
  String notificationMode = 'all';
  String appearance = 'system';
  String _language = 'العربية';
  String get language => _language;
  set language(String value) {
    _language = value == 'English' ? 'English' : 'العربية';
    currentLanguage = _language;
    if (languageListenable.value != _language) {
      languageListenable.value = _language;
    }
  }
  String displayName = 'محمد أحمد';
  String phone = '700 000 000';
  final favoriteRestaurants = <String>{};

  String _accountKey(String value) => value.replaceAll(RegExp(r'[^0-9+]'), '');

  void _syncCurrentUserIdentity() {
    final account = _accountKey(phone);
    currentUserIdentity = isRegistered && account.isNotEmpty
        ? account
        : 'guest';
  }

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
    _syncCurrentUserIdentity();
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
    _syncCurrentUserIdentity();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('registered', true);
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_phone', mobile);
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
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      'language',
      selectedLanguage,
    );
  }

  Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    notificationMode = value ? 'all' : 'disabled';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    await prefs.setString('notification_mode', notificationMode);
    notifyListeners();
  }

  Future<void> setNotificationMode(String value) async {
    const validModes = {'all', 'silent', 'disabled', 'hidden'};
    notificationMode = validModes.contains(value) ? value : 'all';
    notificationsEnabled = notificationMode != 'disabled';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_mode', notificationMode);
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    notifyListeners();
  }

  ThemeMode get themeMode => switch (appearance) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

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
    _syncCurrentUserIdentity();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_phone', mobile);
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
