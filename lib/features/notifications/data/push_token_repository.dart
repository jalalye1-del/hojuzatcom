import '../../../core/network/api_client.dart';
import '../../../core/network/json_parsing.dart';

abstract interface class PushTokenRepository {
  Future<String> register({required String token, required String platform});

  Future<void> disable(String id);
}

class RemotePushTokenRepository implements PushTokenRepository {
  RemotePushTokenRepository(this._api);

  final ApiClient _api;

  @override
  Future<String> register({
    required String token,
    required String platform,
  }) async {
    final normalizedToken = token.trim();
    if (normalizedToken.length < 20) {
      throw ArgumentError.value(token, 'token', 'Invalid Firebase token.');
    }
    if (platform != 'android' && platform != 'ios') {
      throw ArgumentError.value(platform, 'platform', 'Unsupported platform.');
    }

    final root = expectJsonMap(
      await _api.post(
        'push-tokens',
        body: {'token': normalizedToken, 'platform': platform},
      ),
      context: 'push token response',
    );
    final data = expectJsonMap(root['data'], context: 'push token data');
    final pushToken = expectJsonMap(
      data['push_token'],
      context: 'registered push token',
    );
    final id = pushToken['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Expected a registered push token id.');
    }

    return id;
  }

  @override
  Future<void> disable(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty || normalizedId.length > 128) {
      throw ArgumentError.value(id, 'id', 'Invalid push token identifier.');
    }
    await _api.delete('push-tokens/${Uri.encodeComponent(normalizedId)}');
  }
}
