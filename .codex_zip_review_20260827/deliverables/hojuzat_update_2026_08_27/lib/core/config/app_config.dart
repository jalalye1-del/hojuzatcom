class AppConfig {
  const AppConfig({
    required this.apiBaseUri,
    this.requestTimeout = const Duration(seconds: 20),
  });

  final Uri? apiBaseUri;
  final Duration requestTimeout;

  bool get hasRemoteApi => apiBaseUri != null;

  factory AppConfig.fromEnvironment() {
    const rawUrl = String.fromEnvironment('API_BASE_URL');
    final value = rawUrl.trim();
    if (value.isEmpty) return const AppConfig(apiBaseUri: null);

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
    if (uri.scheme != 'https' && !localHosts.contains(uri.host)) {
      throw const FormatException(
        'API_BASE_URL must use HTTPS outside local development.',
      );
    }
    return AppConfig(apiBaseUri: uri);
  }
}
