import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_session_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/bookings/data/booking_repository.dart';
import '../features/payments/data/payment_repository.dart';

class AppServices {
  AppServices._({
    required this.config,
    required this.sessionStore,
    this.apiClient,
    this.authRepository,
    this.bookingRepository,
    this.paymentRepository,
  });

  final AppConfig config;
  final SecureSessionStore sessionStore;
  final ApiClient? apiClient;
  final AuthRepository? authRepository;
  final BookingRepository? bookingRepository;
  final PaymentRepository? paymentRepository;

  bool get backendConfigured => apiClient != null;

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
      paymentRepository: RemotePaymentRepository(apiClient),
    );
  }

  void dispose() => apiClient?.close();
}
