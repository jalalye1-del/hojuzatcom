import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_parsing.dart';
import '../../../core/storage/secure_session_store.dart';
import '../domain/auth_input_policy.dart';
import '../domain/auth_models.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login(LoginRequest request);
  Future<AuthSession> register(RegistrationRequest request);
  Future<AuthSession?> restoreSession();
  Future<AuthSession> refresh();
  Future<void> logout();
  Future<void> requestPasswordReset(String phone);

  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api, this._sessionStore);

  final ApiClient _api;
  final SecureSessionStore _sessionStore;
  @override
  Future<void> requestPasswordReset(String phone) async {
    _validatePhone(phone);

    await _api.post(
      'auth/forgot-password',
      body: {'phone': phone},
      authenticated: false,
    );
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    _validatePhone(phone);
    _validatePassword(newPassword);

    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      throw ArgumentError('Invalid reset code.', 'code');
    }

    await _api.post(
      'auth/reset-password',
      body: {'phone': phone, 'code': code, 'password': newPassword},
      authenticated: false,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _validatePassword(currentPassword);
    _validatePassword(newPassword);

    await _api.post(
      'auth/change-password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );

    await _sessionStore.clear();
  }

  @override
  Future<AuthSession> login(LoginRequest request) async {
    _validatePhone(request.phone);
    _validatePassword(request.password);
    return _startSession(
      await _api.post(
        'auth/login',
        body: request.toJson(),
        authenticated: false,
      ),
    );
  }

  @override
  Future<AuthSession> register(RegistrationRequest request) async {
    final name = request.name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final nameParts = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final hasDigits = RegExp(r'[0-9٠-٩]').hasMatch(name);
    final hasInvalidPart = nameParts.any(
      (part) => !RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(part),
    );

    if (name.isEmpty ||
        name.length > 100 ||
        nameParts.length < 4 ||
        hasDigits ||
        hasInvalidPart) {
      throw ArgumentError(
        'Full legal name must contain at least four parts as shown on the ID.',
        'name',
      );
    }
    _validatePhone(request.phone);
    _validatePassword(request.password);
    return _startSession(
      await _api.post(
        'auth/register',
        body: request.toJson(),
        authenticated: false,
      ),
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    var tokens = await _sessionStore.read();
    if (tokens == null) return null;
    if (tokens.isExpired) {
      if (tokens.refreshToken == null) {
        await _sessionStore.clear();
        return null;
      }
      return refresh();
    }

    try {
      final payload = await _api.get('auth/me');
      final user = AuthUser.fromJson(
        expectJsonMap(unwrapApiData(payload), context: 'auth user'),
      );
      return AuthSession(user: user, tokens: tokens);
    } on ApiException catch (error) {
      if (!error.isUnauthorized) rethrow;
      await _sessionStore.clear();
      return null;
    }
  }

  @override
  Future<AuthSession> refresh() async {
    final current = await _sessionStore.read();
    final refreshToken = current?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(
        message: 'انتهت الجلسة. سجل الدخول من جديد.',
        code: 'missing_refresh_token',
        statusCode: 401,
      );
    }
    return _startSession(
      await _api.post(
        'auth/refresh',
        body: {'refresh_token': refreshToken},
        authenticated: false,
      ),
    );
  }

  @override
  Future<void> logout() async {
    final tokens = await _sessionStore.read();
    try {
      if (tokens != null) {
        await _api.post(
          'auth/logout',
          body: {'refresh_token': tokens.refreshToken},
        );
      }
    } finally {
      await _sessionStore.clear();
    }
  }

  Future<AuthSession> _startSession(Object? payload) async {
    final json = expectJsonMap(unwrapApiData(payload), context: 'auth session');
    final user = AuthUser.fromJson(
      expectJsonMap(json['user'], context: 'auth user'),
    );
    final tokenJson = json['tokens'] == null
        ? json
        : expectJsonMap(json['tokens'], context: 'auth tokens');
    final accessToken =
        optionalString(tokenJson, 'access_token') ??
        optionalString(tokenJson, 'accessToken');
    if (accessToken == null) {
      throw const FormatException(
        'The authentication response has no access token.',
      );
    }
    final refreshToken =
        optionalString(tokenJson, 'refresh_token') ??
        optionalString(tokenJson, 'refreshToken');
    final expiresAt = _readExpiry(tokenJson);
    final tokens = SessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
    await _sessionStore.write(tokens);
    return AuthSession(user: user, tokens: tokens);
  }

  DateTime? _readExpiry(JsonMap json) {
    final absolute =
        optionalString(json, 'expires_at') ?? optionalString(json, 'expiresAt');
    if (absolute != null) return DateTime.tryParse(absolute)?.toUtc();
    final rawSeconds = json['expires_in'] ?? json['expiresIn'];
    final seconds = rawSeconds is num
        ? rawSeconds.toInt()
        : int.tryParse(rawSeconds?.toString() ?? '');
    return seconds == null
        ? null
        : DateTime.now().toUtc().add(Duration(seconds: seconds));
  }

  void _validatePhone(String value) {
    if (!AuthInputPolicy.isValidPhone(value)) {
      throw ArgumentError('Invalid phone number.', 'phone');
    }
  }

  void _validatePassword(String value) {
    if (!AuthInputPolicy.isValidPassword(value)) {
      throw ArgumentError('Invalid password length.', 'password');
    }
  }
}
