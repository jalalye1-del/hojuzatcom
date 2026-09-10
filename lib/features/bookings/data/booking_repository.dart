import '../../../core/network/api_client.dart';
import '../../../core/network/json_parsing.dart';
import '../domain/booking.dart';

abstract interface class BookingRepository {
  Future<List<Booking>> list({BookingStatus? status});
  Future<Booking> getById(String id);
  Future<Booking> create(BookingDraft draft);
  Future<Booking> cancel(String id, {String? reason});
}

class RemoteBookingRepository implements BookingRepository {
  RemoteBookingRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Booking>> list({BookingStatus? status}) async {
    final payload = unwrapApiData(
      await _api.get('bookings', query: {'status': status?.name}),
    );
    final items = payload is Map ? expectJsonMap(payload)['bookings'] : payload;
    if (items is! List) {
      throw const FormatException('Expected a bookings list.');
    }
    return items
        .map(
          (item) => Booking.fromJson(expectJsonMap(item, context: 'booking')),
        )
        .toList(growable: false);
  }

  @override
  Future<Booking> getById(String id) {
    _validateId(id, 'id');
    return _bookingFrom(_api.get('bookings/${Uri.encodeComponent(id)}'));
  }

  @override
  Future<Booking> create(BookingDraft draft) {
    _validateId(draft.providerId, 'providerId');
    _validateId(draft.serviceId, 'serviceId');
    if (draft.total < 0) {
      throw ArgumentError.value(draft.total, 'total', 'Must not be negative.');
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(draft.currency)) {
      throw ArgumentError.value(
        draft.currency,
        'currency',
        'Must be a three-letter ISO currency code.',
      );
    }
    return _bookingFrom(_api.post('bookings', body: draft.toJson()));
  }

  @override
  Future<Booking> cancel(String id, {String? reason}) {
    _validateId(id, 'id');
    if (reason != null && reason.length > 500) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Must not exceed 500 characters.',
      );
    }
    return _bookingFrom(
      _api.post(
        'bookings/${Uri.encodeComponent(id)}/cancel',
        body: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      ),
    );
  }

  Future<Booking> _bookingFrom(Future<Object?> request) async =>
      Booking.fromJson(
        expectJsonMap(unwrapApiData(await request), context: 'booking'),
      );

  void _validateId(String value, String name) {
    if (value.trim().isEmpty || value.length > 128) {
      throw ArgumentError.value(value, name, 'Invalid identifier.');
    }
  }
}
