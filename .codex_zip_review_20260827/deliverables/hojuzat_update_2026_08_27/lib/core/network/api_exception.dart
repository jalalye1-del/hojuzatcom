class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code = 'unknown',
    this.statusCode,
    this.details,
  });

  final String message;
  final String code;
  final int? statusCode;
  final Object? details;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.network(Object error) => ApiException(
    message: 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مجددًا.',
    code: 'network_error',
    details: error.toString(),
  );

  @override
  String toString() =>
      'ApiException($code, status: $statusCode, message: $message)';
}
