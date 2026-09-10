import '../../../core/network/json_parsing.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
    this.providerId,
    this.readAt,
    this.payload = const {},
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? bookingId;
  final String? providerId;
  final JsonMap payload;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead, DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    bookingId: bookingId,
    providerId: providerId,
    payload: payload,
    isRead: isRead ?? this.isRead,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(JsonMap json) => AppNotification(
    id: requiredString(json, 'id'),
    type: optionalString(json, 'type') ?? 'notification',
    title: optionalString(json, 'title') ?? 'إشعار من حجوزاتكم',
    body: optionalString(json, 'body') ?? '',
    bookingId: optionalString(json, 'booking_id'),
    providerId: optionalString(json, 'provider_id'),
    payload: json['payload'] is Map
        ? expectJsonMap(json['payload'], context: 'notification payload')
        : const {},
    isRead: json['is_read'] == true,
    readAt: _optionalDateTime(json['read_at']),
    createdAt: requiredDateTime(json, 'created_at'),
  );

  static DateTime? _optionalDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

class AppNotificationPage {
  const AppNotificationPage({
    required this.notifications,
    required this.unreadCount,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final int currentPage;
  final int lastPage;
  final int total;
}
