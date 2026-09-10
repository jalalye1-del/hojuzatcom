import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/data/push_token_repository.dart';

typedef PushNotificationCallback = Future<void> Function();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class FirebasePushNotificationService {
  FirebasePushNotificationService(
    this._pushTokenRepository, {
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  static const androidChannelId = 'high_importance_channel';
  static const _serverTokenIdKey = 'firebase.server_push_token_id';
  static const _firebaseTokenKey = 'firebase.device_token';
  static const _androidChannel = AndroidNotificationChannel(
    androidChannelId,
    'الإشعارات الفورية',
    description: 'تحديثات الحجوزات والطلبات والعروض المهمة',
    importance: Importance.high,
  );

  final PushTokenRepository? _pushTokenRepository;
  final FlutterLocalNotificationsPlugin _localNotifications;

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  PushNotificationCallback? _onNotificationReceived;
  PushNotificationCallback? _onNotificationOpened;
  RemoteMessage? _pendingInitialMessage;
  bool _initialized = false;
  bool _authenticatedSyncEnabled = false;

  bool get initialized => _initialized;

  Future<bool> initialize({
    PushNotificationCallback? onNotificationReceived,
    PushNotificationCallback? onNotificationOpened,
  }) async {
    if (_initialized) return true;
    if (!_supportsFirebaseMessaging) return false;

    _onNotificationReceived = onNotificationReceived;
    _onNotificationOpened = onNotificationOpened;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (_) => _notifyOpened(),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (_) => _notifyOpened(),
      );
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        _registerRefreshedToken,
      );
      _pendingInitialMessage = await messaging.getInitialMessage();
      _initialized = true;

      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase push initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> syncForAuthenticatedUser({required bool enabled}) async {
    _authenticatedSyncEnabled = enabled;
    final messaging = _messaging;
    final repository = _pushTokenRepository;
    if (!_initialized || messaging == null || repository == null) return false;

    if (!enabled) {
      return unregisterCurrentDevice();
    }

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await unregisterCurrentDevice();
        return false;
      }

      final token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) return false;
      await _registerToken(token);
      await _consumeInitialMessage();
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase push token synchronization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> unregisterCurrentDevice() async {
    _authenticatedSyncEnabled = false;
    final repository = _pushTokenRepository;
    if (repository == null) return false;

    final preferences = await SharedPreferences.getInstance();
    final serverTokenId = preferences.getString(_serverTokenIdKey);
    if (serverTokenId == null || serverTokenId.trim().isEmpty) {
      await preferences.remove(_firebaseTokenKey);
      return true;
    }

    try {
      await repository.disable(serverTokenId);
      await preferences.remove(_serverTokenIdKey);
      await preferences.remove(_firebaseTokenKey);
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase push token removal failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _registerRefreshedToken(String token) async {
    if (!_authenticatedSyncEnabled || _pushTokenRepository == null) return;
    try {
      await _registerToken(token);
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase refreshed token registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _registerToken(String token) async {
    final repository = _pushTokenRepository;
    if (repository == null) return;

    final normalizedToken = token.trim();
    final preferences = await SharedPreferences.getInstance();
    final previousToken = preferences.getString(_firebaseTokenKey);
    final previousServerTokenId = preferences.getString(_serverTokenIdKey);
    if (previousToken != null &&
        previousToken != normalizedToken &&
        previousServerTokenId != null &&
        previousServerTokenId.isNotEmpty) {
      try {
        await repository.disable(previousServerTokenId);
      } on Object {
        // تسجيل الرمز الجديد أهم من تعطيل رمز انتهت صلاحيته بالفعل.
      }
    }

    final serverTokenId = await repository.register(
      token: normalizedToken,
      platform: _platform,
    );
    await preferences.setString(_firebaseTokenKey, normalizedToken);
    await preferences.setString(_serverTokenIdKey, serverTokenId);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || !_authenticatedSyncEnabled) return;

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          'الإشعارات الفورية',
          channelDescription: 'تحديثات الحجوزات والطلبات والعروض المهمة',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
    await _onNotificationReceived?.call();
  }

  Future<void> _consumeInitialMessage() async {
    if (_pendingInitialMessage == null) return;
    _pendingInitialMessage = null;
    await _notifyOpened();
  }

  Future<void> _notifyOpened() async {
    if (!_authenticatedSyncEnabled) return;
    await _onNotificationOpened?.call();
  }

  bool get _supportsFirebaseMessaging =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }
}
