import '../../../core/network/json_parsing.dart';
import '../../../core/storage/secure_session_store.dart';

class LoginRequest {
  const LoginRequest({required this.phone, required this.password});

  final String phone;
  final String password;

  JsonMap toJson() => {'phone': phone, 'password': password};
}

class RegistrationRequest {
  const RegistrationRequest({
    required this.name,
    required this.phone,
    required this.password,
  });

  final String name;
  final String phone;
  final String password;

  JsonMap toJson() => {'name': name, 'phone': phone, 'password': password};
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;

  factory AuthUser.fromJson(JsonMap json) => AuthUser(
    id: requiredString(json, 'id'),
    name: requiredString(json, 'name'),
    phone: requiredString(json, 'phone'),
    email: optionalString(json, 'email'),
  );
}

class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final SessionTokens tokens;
}
