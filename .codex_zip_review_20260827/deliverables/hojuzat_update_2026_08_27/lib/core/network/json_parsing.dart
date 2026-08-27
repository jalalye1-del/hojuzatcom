typedef JsonMap = Map<String, Object?>;

JsonMap expectJsonMap(Object? value, {String context = 'response'}) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw FormatException('Expected a JSON object for $context.');
}

Object? unwrapApiData(Object? value) {
  if (value is Map && value.containsKey('data')) return value['data'];
  return value;
}

String requiredString(JsonMap json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Missing required string: $key.');
}

String? optionalString(JsonMap json, String key) {
  final value = json[key];
  return value is String && value.trim().isNotEmpty ? value : null;
}

int requiredInt(JsonMap json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Missing required integer: $key.');
}

DateTime requiredDateTime(JsonMap json, String key) {
  final value = requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid date: $key.');
  return parsed;
}
