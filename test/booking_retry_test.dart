import 'package:hojuzatcom/features/apartments/data/apartment_backend_bridge.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/core/network/api_exception.dart';
import 'package:hojuzatcom/features/bookings/data/booking_repository.dart';
import 'package:hojuzatcom/features/bookings/domain/booking.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const draft = BookingDraft(
  providerId: 'provider',
  serviceId: 'service',
  total: 10,
  currency: 'YER',
);
http.Response success() => http.Response(
  jsonEncode({
    'data': {
      'id': 'booking',
      'provider_id': 'provider',
      'service_id': 'service',
      'status': 'pending',
      'total': 10,
      'currency': 'YER',
      'created_at': '2026-09-18T12:00:00Z',
    },
  }),
  201,
  headers: {'content-type': 'application/json'},
);
RemoteBookingRepository repository(
  Future<http.Response> Function(http.Request) handler, {
  Future<String?> Function()? token,
}) => RemoteBookingRepository(
  ApiClient(
    baseUri: Uri.parse('https://example.test/api/'),
    accessTokenProvider: token ?? () async => 'session',
    httpClient: MockClient(handler),
  ),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final unit in ['per_day', 'per_night', 'per_booking']) {
    for (final slot in [null, 'slot-a']) {
      test(
        'apartment $unit period retains dates and quantity with slot $slot',
        () async {
          final request = ApartmentBackendBookingRequest(
            target: ApartmentBackendTarget(
              providerId: 'provider',
              serviceId: 'service',
              currency: 'YER',
              pricingUnit: unit,
            ),
            total: 10,
            quantity: unit == 'per_booking' ? 1 : 3,
            serviceAvailabilityId: slot,
            scheduledAt: DateTime(2030, 1, 2),
            metadata: const {
              'arrival': '2030-01-02',
              'departure': '2030-01-05',
            },
          );
          var calls = 0;
          final backend = repository((httpRequest) async {
            calls++;
            final body = jsonDecode(httpRequest.body) as Map;
            expect(body['provider_id'], 'provider');
            expect(body['service_id'], 'service');
            expect(body['service_availability_id'], slot);
            expect(body['quantity'], unit == 'per_booking' ? 1 : 3);
            expect(body['metadata'], {
              'arrival': '2030-01-02',
              'departure': '2030-01-05',
            });
            if (unit == 'per_booking') {
              expect(
                body['scheduled_at'],
                DateTime(2030, 1, 2).toUtc().toIso8601String(),
              );
            } else {
              expect(body.containsKey('scheduled_at'), isFalse);
            }
            return success();
          });
          expect(
            (await backend.create(request.toBookingDraft())).id,
            'booking',
          );
          expect(calls, 1);
        },
      );
    }
  }
  test(
    'pending key survives recreation and token refresh but stays account scoped',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final keys = <String>[];
      var token = 'old-token';
      var user = 'user-a';
      var fail = true;
      RemoteBookingRepository reopen() => RemoteBookingRepository(
        ApiClient(
          baseUri: Uri.parse('https://example.test/api/'),
          accessTokenProvider: () async => token,
          httpClient: MockClient((request) async {
            keys.add(jsonDecode(request.body)['idempotency_key'] as String);
            if (fail) throw http.ClientException('response lost');
            return success();
          }),
        ),
        retryStorage: storage,
        accountIdProvider: () => user,
      );
      await expectLater(reopen().create(draft), throwsA(isA<ApiException>()));
      expect((await storage.readAll()).length, 1);
      final pending = (await reopen().pendingAttempts()).single;
      expect(pending.body, draft.toJson());
      user = 'user-b';
      expect(await reopen().pendingAttempts(), isEmpty);
      await expectLater(
        reopen().retryPending(pending.id),
        throwsA(isA<ApiException>()),
      );
      expect(keys.length, 1);
      await expectLater(reopen().create(draft), throwsA(isA<ApiException>()));
      expect(keys[1], isNot(keys[0]));
      user = 'user-a';
      token = 'refreshed-token';
      fail = false;
      await reopen().retryPending(pending.id);
      expect(keys[2], keys[0]);
      expect(await reopen().pendingAttempts(), isEmpty);
      expect((await storage.readAll()).length, 1);
      await reopen().create(draft);
      expect(keys[3], isNot(keys[0]));
    },
  );

  test(
    'recovery preserves the complete submitted body and legacy keys remain reusable',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final requests = <Map<String, dynamic>>[];
      var fail = true;
      RemoteBookingRepository reopen() => RemoteBookingRepository(
        ApiClient(
          baseUri: Uri.parse('https://example.test/api/'),
          accessTokenProvider: () async => 'token',
          httpClient: MockClient((request) async {
            requests.add(jsonDecode(request.body) as Map<String, dynamic>);
            if (fail) throw http.ClientException('offline');
            return success();
          }),
        ),
        retryStorage: storage,
        accountIdProvider: () => 'account',
      );
      final fullDraft = BookingDraft(
        providerId: 'provider',
        serviceId: 'service',
        total: 20,
        currency: 'YER',
        quantity: 2,
        serviceAvailabilityId: 'slot',
        scheduledAt: DateTime.utc(2027, 1, 2),
        items: const [
          {'service_id': 'service', 'quantity': 2},
        ],
        metadata: const {
          'guest': 'Test Guest',
          'nested': {'rooms': 2},
        },
      );
      await expectLater(
        reopen().create(fullDraft),
        throwsA(isA<ApiException>()),
      );
      final recovered = (await reopen().pendingAttempts()).single;
      expect(recovered.body, fullDraft.toJson());
      fail = false;
      await reopen().retryPending(recovered.id);
      expect(requests[1], requests[0]);
      expect(await storage.readAll(), isEmpty);

      fail = true;
      await expectLater(reopen().create(draft), throwsA(isA<ApiException>()));
      final entry = (await storage.readAll()).entries.single;
      final oldKey = jsonDecode(entry.value)['key'] as String;
      await storage.write(key: entry.key, value: oldKey);
      expect(await reopen().pendingAttempts(), isEmpty);
      fail = false;
      await reopen().create(draft);
      expect(requests.last['idempotency_key'], oldKey);
      expect(await storage.readAll(), isEmpty);
    },
  );

  test(
    'lost response retries with same key; next successful booking uses new key',
    () async {
      final keys = <String>[];
      final repo = repository((request) async {
        keys.add(jsonDecode(request.body)['idempotency_key'] as String);
        if (keys.length == 1) throw http.ClientException('Response lost');
        return success();
      });
      await expectLater(repo.create(draft), throwsA(isA<ApiException>()));
      await repo.create(draft);
      await repo.create(draft);
      expect(keys[0], matches(RegExp(r'^[a-f0-9]{48}$')));
      expect(keys[1], keys[0]);
      expect(keys[2], isNot(keys[0]));
    },
  );
  test('simultaneous submissions share one request', () async {
    final received = Completer<void>();
    final response = Completer<http.Response>();
    var calls = 0;
    final repo = repository((_) async {
      calls++;
      received.complete();
      return response.future;
    });
    final first = repo.create(draft);
    await received.future;
    final second = repo.create(draft);
    await Future<void>.delayed(Duration.zero);
    response.complete(success());
    final results = await Future.wait([first, second]);
    expect(calls, 1);
    expect(results.map((booking) => booking.id), ['booking', 'booking']);
  });
  test(
    'changed booking and changed session do not reuse pending key',
    () async {
      var token = 'first-session';
      final keys = <String>[];
      final repo = repository((request) async {
        keys.add(jsonDecode(request.body)['idempotency_key'] as String);
        throw http.ClientException('offline');
      }, token: () async => token);
      await expectLater(repo.create(draft), throwsA(isA<ApiException>()));
      await expectLater(
        repo.create(
          const BookingDraft(
            providerId: 'provider',
            serviceId: 'other',
            total: 10,
            currency: 'YER',
          ),
        ),
        throwsA(isA<ApiException>()),
      );
      token = 'second-session';
      await expectLater(repo.create(draft), throwsA(isA<ApiException>()));
      expect(keys.toSet().length, 3);
    },
  );
  test('server failure keeps retry key', () async {
    final keys = <String>[];
    final repo = repository((request) async {
      keys.add(jsonDecode(request.body)['idempotency_key'] as String);
      return keys.length == 1 ? http.Response('{}', 500) : success();
    });
    await expectLater(repo.create(draft), throwsA(isA<ApiException>()));
    await repo.create(draft);
    expect(keys[0], keys[1]);
  });

  test(
    'legacy hotel lookup finds booking without reposting or clearing the key',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      var bookingPosts = 0;
      var lookups = 0;
      final backend = RemoteBookingRepository(
        ApiClient(
          baseUri: Uri.parse('https://example.test/api/'),
          accessTokenProvider: () async => 'token',
          httpClient: MockClient((request) async {
            if (request.url.path == '/api/bookings/lookup') {
              lookups++;
              final key = jsonDecode(request.body)['idempotency_key'];
              expect(key, isNotEmpty);
              expect(request.headers['authorization'], 'Bearer token');
              return success();
            }
            bookingPosts++;
            throw http.ClientException('response lost');
          }),
        ),
        retryStorage: storage,
        accountIdProvider: () => 'account',
      );
      const oldHotelDraft = BookingDraft(
        providerId: 'provider',
        serviceId: 'hotel-service',
        total: 30000,
        currency: 'YER',
        metadata: {'module': 'hotels', 'arrival': '2030-01-02'},
      );
      await expectLater(
        backend.create(oldHotelDraft),
        throwsA(isA<ApiException>()),
      );
      final attempt = (await backend.pendingAttempts()).single;
      expect(attempt.needsFreshHotelQuote, isTrue);
      expect(attempt.idempotencyKey, isNotEmpty);
      final found = await backend.lookupLegacyHotelAttempt(attempt.id);
      expect(found.id, 'booking');
      expect(lookups, 1);
      expect(bookingPosts, 1);
      await expectLater(
        backend.retryPending(attempt.id),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'hotel_quote_required',
          ),
        ),
      );
      expect(bookingPosts, 1);
      expect((await backend.pendingAttempts()).single.id, attempt.id);
    },
  );

  test(
    '404 and network uncertainty retain hotel key; local discard leaves other attempts',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      var bookingPosts = 0;
      var lookupMode = 'notFound';
      var offline = true;
      final backend = RemoteBookingRepository(
        ApiClient(
          baseUri: Uri.parse('https://example.test/api/'),
          accessTokenProvider: () async => 'token',
          httpClient: MockClient((request) async {
            if (request.url.path == '/api/bookings/lookup') {
              if (lookupMode == 'offline') {
                throw http.ClientException('offline');
              }
              return http.Response(
                jsonEncode({
                  'code': 'booking_not_found',
                  'message': 'Not found',
                }),
                404,
                headers: {'content-type': 'application/json'},
              );
            }
            bookingPosts++;
            if (offline) throw http.ClientException('offline');
            return success();
          }),
        ),
        retryStorage: storage,
        accountIdProvider: () => 'account',
      );
      await expectLater(
        backend.create(
          const BookingDraft(
            providerId: 'provider',
            serviceId: 'hotel-service',
            total: 30000,
            currency: 'YER',
            metadata: {'module': 'hotels'},
          ),
        ),
        throwsA(isA<ApiException>()),
      );
      await expectLater(backend.create(draft), throwsA(isA<ApiException>()));
      final attempts = await backend.pendingAttempts();
      final hotel = attempts.singleWhere((item) => item.needsFreshHotelQuote);
      final other = attempts.singleWhere((item) => !item.needsFreshHotelQuote);
      await expectLater(
        backend.lookupLegacyHotelAttempt(hotel.id),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'booking_not_found',
          ),
        ),
      );
      expect((await backend.pendingAttempts()).length, 2);
      lookupMode = 'offline';
      await expectLater(
        backend.lookupLegacyHotelAttempt(hotel.id),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'network_error',
          ),
        ),
      );
      expect(bookingPosts, 2);
      expect((await storage.readAll()).length, 2);
      await expectLater(
        backend.discardLegacyHotelAttempt(other.id),
        throwsA(isA<ApiException>()),
      );
      await backend.discardLegacyHotelAttempt(hotel.id);
      expect((await backend.pendingAttempts()).single.id, other.id);
      offline = false;
      await backend.retryPending(other.id);
      expect(bookingPosts, 3);
      expect(await backend.pendingAttempts(), isEmpty);
    },
  );
}
