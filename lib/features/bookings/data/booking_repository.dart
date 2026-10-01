import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_exception.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_parsing.dart';
import '../domain/booking.dart';

class PendingBookingAttempt {
  const PendingBookingAttempt({
    required this.id,
    required this.body,
    this.idempotencyKey,
  });
  final String id;
  final JsonMap body;
  final String? idempotencyKey;

  bool get needsFreshHotelQuote {
    final metadata = body['metadata'];
    return metadata is Map &&
        metadata['module'] == 'hotels' &&
        body['expected_total'] == null;
  }
}

abstract interface class BookingRepository {
  Future<List<Booking>> list({BookingStatus? status});
  Future<BookingPage> listPage({
    int page = 1,
    int perPage = 20,
    BookingStatus? status,
  });
  Future<Booking> getById(String id);
  Future<Booking> create(BookingDraft draft);
  Future<Booking> cancel(String id, {String? reason});
}

class BookingPage {
  const BookingPage({
    required this.bookings,
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMore,
  });

  final List<Booking> bookings;
  final int page;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMore;

  BookingPage withBookings(List<Booking> updatedBookings) => BookingPage(
    bookings: updatedBookings,
    page: page,
    perPage: perPage,
    total: total,
    lastPage: lastPage,
    hasMore: hasMore,
  );
}

class RemoteBookingRepository implements BookingRepository {
  RemoteBookingRepository(
    this._api, {
    this._retryStorage,
    this._accountIdProvider,
  });

  final ApiClient _api;
  final FlutterSecureStorage? _retryStorage;
  final String? Function()? _accountIdProvider;
  final Map<String, String> _pendingKeys = {};
  final Map<String, Future<Booking>> _pendingRequests = {};
  final Random _random = Random.secure();

  @override
  Future<List<Booking>> list({BookingStatus? status}) async {
    return (await listPage(perPage: 100, status: status)).bookings;
  }

  @override
  Future<BookingPage> listPage({
    int page = 1,
    int perPage = 20,
    BookingStatus? status,
  }) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'Must be at least 1.');
    }
    if (perPage < 1 || perPage > 100) {
      throw ArgumentError.value(perPage, 'perPage', 'Must be between 1 and 100.');
    }
    final response = await _api.get('bookings', query: {
      'status': status?.name,
      'page': page,
      'per_page': perPage,
    });
    final payload = unwrapApiData(response);
    final items = payload is Map ? expectJsonMap(payload)['bookings'] : payload;
    if (items is! List) {
      throw const FormatException('Expected a bookings list.');
    }
    final bookings = items
        .map(
          (item) => Booking.fromJson(expectJsonMap(item, context: 'booking')),
        )
        .toList(growable: false);
    final meta = response is Map ? response['meta'] : null;
    if (meta == null) {
      return BookingPage(
        bookings: bookings,
        page: page,
        perPage: perPage,
        total: bookings.length,
        lastPage: page,
        hasMore: false,
      );
    }
    final values = expectJsonMap(meta, context: 'booking pagination');
    final hasMore = values['has_more'];
    if (hasMore is! bool) {
      throw const FormatException('Expected booking pagination has_more.');
    }
    return BookingPage(
      bookings: bookings,
      page: requiredInt(values, 'page'),
      perPage: requiredInt(values, 'per_page'),
      total: requiredInt(values, 'total'),
      lastPage: requiredInt(values, 'last_page'),
      hasMore: hasMore,
    );
  }

  @override
  Future<Booking> getById(String id) {
    _validateId(id, 'id');
    return _bookingFrom(_api.get('bookings/${Uri.encodeComponent(id)}'));
  }

  @override
  Future<Booking> create(BookingDraft draft) async {
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
    final token = await _api.accessTokenProvider?.call();
    final account = _accountIdProvider == null ? token : _accountIdProvider();
    if (account == null || account.isEmpty || token == null || token.isEmpty) {
      throw const ApiException(
        message: 'سجل الدخول قبل إرسال الحجز.',
        code: 'missing_access_token',
        statusCode: 401,
      );
    }
    final body = draft.toJson();
    final fingerprint = sha256
        .convert(
          utf8.encode(
            jsonEncode([
              _api.baseUri.toString(),
              account,
              _canonicalJson(body),
            ]),
          ),
        )
        .toString();
    final running = _pendingRequests[fingerprint];
    if (running != null) return running;
    final request = _sendBooking(fingerprint, body, _scope(account));
    _pendingRequests[fingerprint] = request;
    return request;
  }

  String _scope(String account) => sha256
      .convert(utf8.encode(jsonEncode([_api.baseUri.toString(), account])))
      .toString();

  Future<String> _currentScope() async {
    final token = await _api.accessTokenProvider?.call();
    final account = _accountIdProvider == null ? token : _accountIdProvider();
    if (token == null || token.isEmpty || account == null || account.isEmpty) {
      throw const ApiException(
        message: 'سجل الدخول لمتابعة الحجز.',
        statusCode: 401,
      );
    }
    return _scope(account);
  }

  Future<List<PendingBookingAttempt>> pendingAttempts() async {
    final scope = await _currentScope();
    final entries = await _retryStorage?.readAll() ?? <String, String>{};
    final attempts = <PendingBookingAttempt>[];
    for (final entry in entries.entries) {
      if (!entry.key.startsWith('booking.pending.v1.')) continue;
      try {
        final value = jsonDecode(entry.value);
        if (value is! Map || value['scope'] != scope || value['body'] is! Map) {
          continue;
        }
        attempts.add(
          PendingBookingAttempt(
            id: entry.key.substring('booking.pending.v1.'.length),
            body: expectJsonMap(value['body']),
            idempotencyKey: value['key'] is String
                ? value['key'] as String
                : null,
          ),
        );
      } on FormatException {
        // Earlier versions saved only the key and cannot restore the form.
      }
    }
    if (await _currentScope() != scope) return [];
    return attempts;
  }

  Future<Booking> retryPending(String id) async {
    final scope = await _currentScope();
    final attempts = await pendingAttempts();
    final matches = attempts.where((attempt) => attempt.id == id);
    if (matches.isEmpty || await _currentScope() != scope) {
      throw const ApiException(message: 'هذه المحاولة غير متاحة لهذا الحساب.');
    }
    if (matches.single.needsFreshHotelQuote) {
      throw const ApiException(
        code: 'hotel_quote_required',
        message:
            'هذه محاولة فندق قديمة. ابدأ حجزًا جديدًا لمعاينة السعر الحالي.',
      );
    }
    final running = _pendingRequests[id];
    if (running != null) return running;
    final request = _sendBooking(id, matches.single.body, scope);
    _pendingRequests[id] = request;
    return request;
  }

  Future<Booking> lookupLegacyHotelAttempt(String id) async {
    final scope = await _currentScope();
    final attempts = await pendingAttempts();
    final matches = attempts.where((attempt) => attempt.id == id);
    if (matches.isEmpty || await _currentScope() != scope) {
      throw const ApiException(message: 'هذه المحاولة غير متاحة لهذا الحساب.');
    }
    final attempt = matches.single;
    final key = attempt.idempotencyKey;
    if (!attempt.needsFreshHotelQuote || key == null || key.isEmpty) {
      throw const ApiException(message: 'لا يمكن التحقق من محاولة الفندق هذه.');
    }
    final booking = await _bookingFrom(
      _api.post('bookings/lookup', body: {'idempotency_key': key}),
    );
    if (await _currentScope() != scope) {
      throw const ApiException(
        message: 'تغيّر الحساب. أعد تسجيل الدخول للمتابعة.',
      );
    }
    return booking;
  }

  Future<void> discardLegacyHotelAttempt(String id) async {
    final scope = await _currentScope();
    final attempts = await pendingAttempts();
    final matches = attempts.where((attempt) => attempt.id == id);
    if (matches.isEmpty || await _currentScope() != scope) {
      throw const ApiException(message: 'هذه المحاولة غير متاحة لهذا الحساب.');
    }
    if (!matches.single.needsFreshHotelQuote ||
        _pendingRequests.containsKey(id)) {
      throw const ApiException(message: 'لا يمكن حذف هذه المحاولة من هنا.');
    }
    await _retryStorage?.delete(key: 'booking.pending.v1.$id');
    _pendingKeys.remove(id);
  }

  Future<Booking> _sendBooking(
    String fingerprint,
    JsonMap body,
    String scope,
  ) async {
    final storageKey = 'booking.pending.v1.$fingerprint';
    try {
      final stored = await _retryStorage?.read(key: storageKey);
      final storedKey = stored != null && stored.startsWith('{')
          ? expectJsonMap(jsonDecode(stored))['key'] as String
          : stored;
      final key = _pendingKeys.putIfAbsent(
        fingerprint,
        () =>
            storedKey ??
            List.generate(
              24,
              (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
            ).join(),
      );
      await _retryStorage?.write(
        key: storageKey,
        value: jsonEncode({'scope': scope, 'key': key, 'body': body}),
      );
      if (await _currentScope() != scope) {
        throw const ApiException(
          message: 'تغيّر الحساب. أعد تسجيل الدخول للمتابعة.',
          statusCode: 401,
        );
      }
      final booking = await _bookingFrom(
        _api.post('bookings', body: {...body, 'idempotency_key': key}),
      );
      await _retryStorage?.delete(key: storageKey);
      _pendingKeys.remove(fingerprint);
      return booking;
    } finally {
      _pendingRequests.remove(fingerprint);
    }
  }

  Object? _canonicalJson(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return {for (final key in keys) key: _canonicalJson(value[key])};
    }
    if (value is List) return value.map(_canonicalJson).toList();
    return value;
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
