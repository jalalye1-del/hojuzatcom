import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUri,
    this.requestTimeout = const Duration(seconds: 20),
  });

  final Uri? apiBaseUri;
  final Duration requestTimeout;

  bool get hasRemoteApi => apiBaseUri != null;

  factory AppConfig.fromEnvironment() {
    const rawUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: kDebugMode ? 'http://10.0.2.2:8000/api' : '',
    );
    return AppConfig(
      apiBaseUri: parseApiBaseUri(rawUrl, allowLocalHttp: kDebugMode),
    );
  }

  static Uri? parseApiBaseUri(String rawUrl, {required bool allowLocalHttp}) {
    final value = rawUrl.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const FormatException(
        'API_BASE_URL must be a valid HTTP or HTTPS URL.',
      );
    }
    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
    if (uri.scheme != 'https' &&
        (!allowLocalHttp || !localHosts.contains(uri.host))) {
      throw const FormatException(
        'API_BASE_URL must use HTTPS outside debug local development.',
      );
    }
    return uri;
  }
}
