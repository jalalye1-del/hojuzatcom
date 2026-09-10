class AuthInputPolicy {
  const AuthInputPolicy._();

  static const minPasswordLength = 8;
  static const maxPasswordLength = 128;

  static String normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[\s()\-]'), '').trim();

  static bool isValidPhone(String value) =>
      RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalizePhone(value));

  static bool isValidPassword(String value) =>
      value.length >= minPasswordLength && value.length <= maxPasswordLength;
}
