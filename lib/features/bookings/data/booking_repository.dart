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
  Future<Booking> getById(String id) =>
      _bookingFrom(_api.get('bookings/${Uri.encodeComponent(id)}'));

  @override
  Future<Booking> create(BookingDraft draft) =>
      _bookingFrom(_api.post('bookings', body: draft.toJson()));

  @override
  Future<Booking> cancel(String id, {String? reason}) => _bookingFrom(
    _api.post(
      'bookings/${Uri.encodeComponent(id)}/cancel',
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    ),
  );

  Future<Booking> _bookingFrom(Future<Object?> request) async =>
      Booking.fromJson(
        expectJsonMap(unwrapApiData(await request), context: 'booking'),
      );
}
