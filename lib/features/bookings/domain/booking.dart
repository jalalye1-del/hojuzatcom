import '../../../core/network/json_parsing.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }

class BookingDraft {
  const BookingDraft({
    required this.providerId,
    required this.serviceId,
    required this.total,
    required this.currency,
    this.quantity = 1,
    this.items = const [],
    this.serviceAvailabilityId,
    this.scheduledAt,
    this.expectedTotal,
    this.metadata = const {},
  });

  final String providerId;
  final String serviceId;
  final int total;
  final String currency;
  final int quantity;
  final String? serviceAvailabilityId;
  final List<Map<String, Object?>> items;
  final DateTime? scheduledAt;
  final int? expectedTotal;
  final JsonMap metadata;

  JsonMap toJson() => {
    'provider_id': providerId,
    'service_id': serviceId,
    'quantity': quantity,
    if (serviceAvailabilityId != null)
      'service_availability_id': serviceAvailabilityId,
    if (items.isNotEmpty) 'items': items,
    'total': total,
    'currency': currency,
    if (expectedTotal != null) 'expected_total': expectedTotal,
    if (scheduledAt != null)
      'scheduled_at': scheduledAt!.toUtc().toIso8601String(),
    'metadata': metadata,
  };
}

class Booking {
  const Booking({
    required this.id,
    required this.providerId,
    required this.serviceId,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String providerId;
  final String serviceId;
  final BookingStatus status;
  final int total;
  final String currency;
  final DateTime createdAt;
  final JsonMap metadata;

  factory Booking.fromJson(JsonMap json) => Booking(
    id: requiredString(json, 'id'),
    providerId: requiredString(json, 'provider_id'),
    serviceId: requiredString(json, 'service_id'),
    status: BookingStatus.values.firstWhere(
      (value) => value.name == requiredString(json, 'status'),
      orElse: () => BookingStatus.pending,
    ),
    total: requiredInt(json, 'total'),
    currency: requiredString(json, 'currency'),
    createdAt: requiredDateTime(json, 'created_at'),
    metadata: json['metadata'] is Map
        ? expectJsonMap(json['metadata'], context: 'booking metadata')
        : const {},
  );
}
