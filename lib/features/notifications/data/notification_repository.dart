import '../../../core/network/api_client.dart';
import '../../../core/network/json_parsing.dart';
import '../domain/app_notification.dart';

abstract interface class NotificationRepository {
  Future<AppNotificationPage> list({
    int page = 1,
    int perPage = 20,
    String? status,
  });

  Future<int> unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);
}

class RemoteNotificationRepository implements NotificationRepository {
  RemoteNotificationRepository(this._api);

  final ApiClient _api;

  @override
  Future<AppNotificationPage> list({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    final root = expectJsonMap(
      await _api.get(
        'notifications',
        query: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
        },
      ),
      context: 'notifications response',
    );
    final data = expectJsonMap(root['data'], context: 'notifications data');
    final rawItems = data['notifications'];
    if (rawItems is! List) {
      throw const FormatException('Expected a notifications list.');
    }
    final meta = root['meta'] is Map
        ? expectJsonMap(root['meta'], context: 'notifications meta')
        : const <String, Object?>{};

    return AppNotificationPage(
      notifications: rawItems
          .map(
            (item) => AppNotification.fromJson(
              expectJsonMap(item, context: 'notification'),
            ),
          )
          .toList(growable: false),
      unreadCount: _intValue(data['unread_count']),
      currentPage: _intValue(meta['current_page'], fallback: page),
      lastPage: _intValue(meta['last_page'], fallback: 1),
      total: _intValue(meta['total'], fallback: rawItems.length),
    );
  }

  @override
  Future<int> unreadCount() async {
    final data = expectJsonMap(
      unwrapApiData(await _api.get('notifications/unread-count')),
      context: 'unread count',
    );
    return _intValue(data['unread_count']);
  }

  @override
  Future<void> markRead(String id) async {
    _validateId(id);
    await _api.post('notifications/${Uri.encodeComponent(id)}/read');
  }

  @override
  Future<void> markAllRead() async {
    await _api.post('notifications/read-all');
  }

  @override
  Future<void> delete(String id) async {
    _validateId(id);
    await _api.delete('notifications/${Uri.encodeComponent(id)}');
  }

  static int _intValue(Object? value, {int fallback = 0}) =>
      value is int ? value : int.tryParse('$value') ?? fallback;

  static void _validateId(String id) {
    if (id.trim().isEmpty || id.length > 128) {
      throw ArgumentError.value(id, 'id', 'Invalid notification identifier.');
    }
  }
}
