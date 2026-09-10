import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_session_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/bookings/data/booking_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/data/push_token_repository.dart';
import '../features/payments/data/payment_repository.dart';

class AppServices {
  AppServices._({
    required this.config,
    required this.sessionStore,
    this.apiClient,
    this.authRepository,
    this.bookingRepository,
    this.catalogRepository,
    this.notificationRepository,
    this.pushTokenRepository,
    this.paymentRepository,
  });

  final AppConfig config;
  final SecureSessionStore sessionStore;
  final ApiClient? apiClient;
  final AuthRepository? authRepository;
  final BookingRepository? bookingRepository;
  final CatalogRepository? catalogRepository;
  final NotificationRepository? notificationRepository;
  final PushTokenRepository? pushTokenRepository;
  final PaymentRepository? paymentRepository;

  bool get backendConfigured => apiClient != null;
  bool get localDemoAllowed => !kReleaseMode && !backendConfigured;

  factory AppServices.fromEnvironment({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  }) {
    final config = AppConfig.fromEnvironment();
    final sessionStore = FlutterSecureSessionStore(secureStorage);
    final baseUri = config.apiBaseUri;
    if (baseUri == null) {
      return AppServices._(config: config, sessionStore: sessionStore);
    }

    final apiClient = ApiClient(
      baseUri: baseUri,
      httpClient: httpClient,
      timeout: config.requestTimeout,
      accessTokenProvider: () async => (await sessionStore.read())?.accessToken,
    );
    return AppServices._(
      config: config,
      sessionStore: sessionStore,
      apiClient: apiClient,
      authRepository: RemoteAuthRepository(apiClient, sessionStore),
      bookingRepository: RemoteBookingRepository(apiClient),
      catalogRepository: RemoteCatalogRepository(apiClient),
      notificationRepository: RemoteNotificationRepository(apiClient),
      pushTokenRepository: RemotePushTokenRepository(apiClient),
      paymentRepository: RemotePaymentRepository(apiClient),
    );
  }

  void dispose() => apiClient?.close();
}
