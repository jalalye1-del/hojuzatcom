import 'package:hojuzatcom/features/transport/presentation/land_transport_flow.dart'
    as land;
import 'package:hojuzatcom/features/travel/presentation/travel_flow.dart'
    as travel;
import 'package:hojuzatcom/features/travel/domain/travel_models.dart';
import 'package:hojuzatcom/features/transport/presentation/car_rental_flow.dart'
    as rental;
import 'package:hojuzatcom/features/catalog/domain/catalog_models.dart';
import 'package:hojuzatcom/features/delivery/presentation/delivery_basket.dart';
import 'package:hojuzatcom/features/transport/presentation/freight_flow.dart';
import 'package:hojuzatcom/features/halls/domain/hall_booking_details.dart';
import 'package:hojuzatcom/main.dart' as app;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/core/network/api_exception.dart';
import 'package:hojuzatcom/features/bookings/data/booking_repository.dart';
import 'package:hojuzatcom/features/bookings/presentation/provider_booking_flow.dart';
import 'package:hojuzatcom/features/catalog/data/catalog_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> service(
  String id, {
  String provider = 'provider-a',
  int price = 12000,
}) => {
  'id': id,
  'provider_id': provider,
  'service_category_id': 'category',
  'name_ar': 'خدمة مسجلة',
  'base_price': price,
  'currency': 'YER',
  'provider': {
    'id': provider,
    'display_name_ar': 'مقدم الخدمة',
    'province': 'صنعاء',
  },
};

http.Response json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ProviderBookingFlow flow(Future<http.Response> Function(http.Request) handler) {
  final api = ApiClient(
    baseUri: Uri.parse('https://example.test/api/'),
    accessTokenProvider: () async => 'test-token',
    httpClient: MockClient(handler),
  );
  return ProviderBookingFlow(
    catalog: RemoteCatalogRepository(api),
    bookings: RemoteBookingRepository(api),
  );
}

const selection = ProviderBookingSelection(
  module: 'hotels',
  serviceName: 'خدمة مسجلة',
  serviceId: 'service-a',
  province: 'صنعاء',
  quantity: 2,
);

void main() {
  test('availability filters transmit timezone-aware UTC bounds', () async {
    final from = DateTime.parse('2030-01-01T00:00:00+04:00');
    final to = DateTime.parse('2030-01-01T23:59:59+04:00');
    final backend = flow((request) async {
      expect(request.url.path, '/api/services/service-a/availabilities');
      expect(request.url.queryParameters['from'], '2029-12-31T20:00:00.000Z');
      expect(request.url.queryParameters['to'], '2030-01-01T19:59:59.000Z');
      return json({'data': []});
    });

    await backend.catalog.listAvailabilities('service-a', from: from, to: to);
  });

  for (final unit in ['per_day', 'per_night', 'per_booking']) {
    test(
      'calendar period uses provider date while $unit keeps the right schedule contract',
      () async {
        final catalogService = service('service-a')..['pricing_unit'] = unit;
        final arrival = DateTime(2030, 1, 2);
        final backend = flow((request) async {
          if (request.url.path.endsWith('/services')) {
            return json({
              'data': [catalogService],
            });
          }
          if (request.url.path.endsWith('/services/service-a')) {
            return json({'data': catalogService});
          }
          final body = jsonDecode(request.body) as Map;
          expect(body['metadata']['arrival'], '2030-01-02');
          expect(body['metadata']['departure'], '2030-01-05');
          if (unit == 'per_booking') {
            expect(body['scheduled_at'], arrival.toUtc().toIso8601String());
            expect(body['quantity'], 1);
          } else {
            expect(body.containsKey('scheduled_at'), isFalse);
            expect(body['quantity'], 3);
          }
          return json({
            'data': {
              'id': 'period-booking',
              'provider_id': 'provider-a',
              'service_id': 'service-a',
              'total': 36000,
              'currency': 'YER',
              'status': 'pending',
              'created_at': '2030-01-01T00:00:00Z',
            },
          }, 201);
        });
        final periodSelection = ProviderBookingSelection(
          module: 'hotels',
          serviceName: 'خدمة مسجلة',
          serviceId: 'service-a',
          quantity: 3,
          scheduledAt: arrival,
          metadata: const {'arrival': '2030-01-02', 'departure': '2030-01-05'},
        );
        final booking = await backend.create(periodSelection);
        expect(booking.id, 'period-booking');
        final slotBooking = await backend.create(
          periodSelection,
          availabilityId: 'period-slot',
        );
        expect(slotBooking.id, 'period-booking');
      },
    );
  }

  tearDown(() => ProviderBookingFlow.current = null);
  testWidgets('same-name hotels show only the selected providers rooms', (
    tester,
  ) async {
    final backend = flow((_) async => json({'data': []}));
    ProviderBookingFlow.current = backend;
    final first = service('room-a')..['name_ar'] = 'غرفة الفندق الأول';
    final second = service('room-b', provider: 'provider-b')
      ..['name_ar'] = 'غرفة الفندق الثاني';
    backend.snapshots['hotels'] = [
      CatalogService.fromJson(first),
      CatalogService.fromJson(second),
    ];
    app.appSession.language = 'العربية';
    await tester.pumpWidget(
      const MaterialApp(
        home: app.HotelDetailScreen(
          providerId: 'provider-b',
          title: 'مقدم الخدمة',
          address: 'صنعاء',
          price: '12000',
          image: 'assets/Services images/الفنادق.jpg',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('غرفة الفندق الثاني'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('غرفة الفندق الثاني'), findsOneWidget);
    expect(find.text('غرفة الفندق الأول'), findsNothing);
  });

  testWidgets('land passenger screen preserves selected travel date', (
    tester,
  ) async {
    final date = DateTime(2026, 10, 5);
    app.appSession.language = 'العربية';
    await tester.pumpWidget(
      MaterialApp(
        home: land.LandPassengerScreen(
          travelDate: date,
          seat: 'A1',
          trip: const land.LandTrip(
            type: land.LandVehicleType.coach,
            company: 'مقدم الخدمة',
            origin: 'صنعاء',
            destination: 'عدن',
            departure: '08:00',
            arrival: '16:00',
            price: 7000,
            remainingSeats: 10,
            serviceId: 'trip-a',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('استكمال الحجز والدفع'));
    await tester.pumpAndSettle();
    final payment = tester.widget<land.LandPaymentScreen>(
      find.byType(land.LandPaymentScreen),
    );
    expect(payment.travelDate, date);
    expect(payment.passengerDetails.length, 1);
  });

  testWidgets(
    'land booking submits selected trip and passengers without a wallet',
    (tester) async {
      var created = 0;
      final tripService = service('trip-a', price: 7000)
        ..['service_type'] = 'land_transport';
      ProviderBookingFlow.current = flow((request) async {
        if (request.url.path.endsWith('/availabilities')) {
          return json({'data': []});
        }
        if (request.url.path.endsWith('/services')) {
          return json({
            'data': [tripService],
          });
        }
        if (request.url.path.endsWith('/services/trip-a')) {
          return json({'data': tripService});
        }
        expect(request.url.path, '/api/bookings');
        final body = jsonDecode(request.body) as Map;
        expect(body['service_id'], 'trip-a');
        expect(body['quantity'], 2);
        expect(body['metadata']['origin'], 'صنعاء');
        expect(
          DateTime.parse(body['scheduled_at'] as String),
          DateTime(2026, 10, 5).toUtc(),
        );
        expect(body['metadata']['destination'], 'عدن');
        expect(body['metadata']['seat'], 'A1');
        expect(body['metadata']['passenger_name'], 'مسافر الاختبار');
        expect(body['metadata']['passengers'], [
          {'name': 'مسافر الاختبار', 'phone': '771000001'},
          {'name': 'مسافر ثان', 'phone': '771000002'},
        ]);
        created++;
        return json({
          'data': {
            'id': 'land-booking',
            'provider_id': 'provider-a',
            'service_id': 'trip-a',
            'total': 14000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-10T10:00:00Z',
          },
        }, 201);
      });
      app.appSession.language = 'العربية';
      await tester.pumpWidget(
        MaterialApp(
          home: land.LandPaymentScreen(
            travelDate: DateTime(2026, 10, 5),
            trip: land.LandTrip(
              type: land.LandVehicleType.coach,
              company: 'مقدم الخدمة',
              origin: 'صنعاء',
              destination: 'عدن',
              departure: '08:00',
              arrival: '16:00',
              price: 7000,
              remainingSeats: 10,
              serviceId: 'trip-a',
            ),
            seat: 'A1',
            passengerName: 'مسافر الاختبار',
            passengersCount: 2,
            passengerDetails: [
              {'name': 'مسافر الاختبار', 'phone': '771000001'},
              {'name': 'مسافر ثان', 'phone': '771000002'},
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('استكمال الدفع'));
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(find.text('رقم الحجز: land-booking'), findsOneWidget);
    },
  );

  for (final resort in [false, true]) {
    testWidgets('retreat checkout selects correct module: resort=$resort', (
      tester,
    ) async {
      final module = resort ? 'resorts' : 'chalets';
      final type = resort ? 'resort' : 'chalet';
      final record = service('stay-a')..['service_type'] = type;
      var created = 0;
      ProviderBookingFlow.current = flow((request) async {
        if (request.url.path.endsWith('/availabilities')) {
          return json({'data': []});
        }
        if (request.url.path.endsWith('/services')) {
          expect(request.url.queryParameters['service_type'], type);
          return json({
            'data': [record],
          });
        }
        if (request.url.path.endsWith('/services/stay-a')) {
          return json({'data': record});
        }
        expect(request.url.path, '/api/bookings');
        final body = jsonDecode(request.body) as Map;
        expect(body['quantity'], 2);
        expect(body['metadata']['module'], module);
        expect(body['metadata']['guests'], 4);
        expect(
          body['metadata']['departure'],
          DateTime(2026, 10, 3).toIso8601String(),
        );
        created++;
        return json({
          'data': {
            'id': 'stay-booking',
            'provider_id': 'provider-a',
            'service_id': 'stay-a',
            'total': 24000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-10T10:00:00Z',
          },
        }, 201);
      });
      final catalog = app.RetreatCatalog(
        entityLabel: resort ? 'المنتجع' : 'الشاليه',
        pluralLabel: resort ? 'منتجعات' : 'شاليهات',
        searchHint: '',
        featuredTitle: '',
        heroSubtitle: '',
        imageAsset: 'assets/images/hotel_booking_banner.png',
        bannerAsset: 'assets/images/hotel_booking_banner.png',
        favoritePrefix: module,
        bookingPrefix: resort ? 'RS' : 'CH',
        items: const [],
      );
      ProviderBookingFlow.current!.snapshots[module] = [
        CatalogService.fromJson(record),
      ];
      expect(catalog.providerItems.single.id, 'stay-a');
      app.appSession.language = 'العربية';
      await tester.pumpWidget(
        MaterialApp(
          home: app.ChaletPaymentScreen(
            catalog: catalog,
            chalet: catalog.providerItems.single,
            arrival: DateTime(2026, 10, 1),
            departure: DateTime(2026, 10, 3),
            guests: 4,
            total: 24000,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.textContaining('ادفع الآن');
      await tester.scrollUntilVisible(
        button,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(find.text('رقم الحجز: stay-booking'), findsOneWidget);
    });
  }

  for (final module in ['restaurants', 'delivery']) {
    test(
      '$module basket sends server item identifiers and quantities without paying',
      () async {
        final first = service('item-a', price: 5000)..['name_ar'] = 'صنف أول';
        final second = service('item-b', price: 7000)..['name_ar'] = 'صنف ثان';
        final backend = flow((request) async {
          if (request.url.path.endsWith('/services')) {
            return json({
              'data': [first, second],
            });
          }
          if (request.url.path.endsWith('/services/item-a')) {
            return json({'data': first});
          }
          expect(request.url.path, '/api/bookings');
          final body = jsonDecode(request.body) as Map;
          expect(body['provider_id'], 'provider-a');
          expect(body['items'], [
            {'service_id': 'item-a', 'quantity': 2},
            {'service_id': 'item-b', 'quantity': 1},
          ]);
          return json({
            'data': {
              'id': 'order-booking',
              'provider_id': 'provider-a',
              'service_id': 'item-a',
              'total': 17000,
              'currency': 'YER',
              'status': 'pending',
              'created_at': '2026-09-10T10:00:00Z',
            },
          }, 201);
        });
        final booking = await backend.create(
          ProviderBookingSelection(
            module: module,
            serviceName: 'طلب',
            providerId: 'provider-a',
            orderItems: module == 'restaurants'
                ? {'صنف أول': 2, 'صنف ثان': 1}
                : {'item-a': 2, 'item-b': 1},
          ),
        );
        expect(booking.total, 17000);
        expect(booking.id, 'order-booking');
      },
    );
  }
  test(
    'basket rejects ambiguous item names and items from another provider',
    () async {
      for (final ambiguous in [true, false]) {
        var posted = false;
        final first = service('item-a')..['name_ar'] = 'صنف متشابه';
        final second = service(
          'item-b',
          provider: ambiguous ? 'provider-a' : 'provider-b',
        )..['name_ar'] = 'صنف متشابه';
        final backend = flow((request) async {
          if (request.method == 'POST') posted = true;
          return json({
            'data': [first, second],
          });
        });
        await expectLater(
          backend.create(
            ProviderBookingSelection(
              module: 'restaurants',
              serviceName: 'طلب',
              providerId: 'provider-a',
              orderItems: {ambiguous ? 'صنف متشابه' : 'item-b': 1},
            ),
          ),
          throwsA(isA<ApiException>()),
        );
        expect(posted, isFalse);
      }
    },
  );

  for (final cancel in [false, true]) {
    testWidgets(
      'freight provider choice preserves selection or cancellation: $cancel',
      (tester) async {
        final backend = flow((_) async {
          fail('Selecting an office must not submit a booking');
        });
        ProviderBookingFlow.current = backend;
        final first = service('freight-a', price: 15000);
        first['provider'] = {
          'id': 'provider-a',
          'display_name_ar': 'مكتب الشحن الأول',
          'province': 'صنعاء',
        };
        final second = service(
          'freight-b',
          provider: 'provider-b',
          price: 23000,
        );
        second['provider'] = {
          'id': 'provider-b',
          'display_name_ar': 'مكتب الشحن الثاني',
          'province': 'صنعاء',
        };
        final other = service('freight-other', provider: 'provider-other');
        other['provider'] = {
          'id': 'provider-other',
          'display_name_ar': 'مكتب محافظة أخرى',
          'province': 'عدن',
        };
        backend.snapshots['freight'] = [
          first,
          second,
          other,
        ].map(CatalogService.fromJson).toList();
        app.appSession.language = 'العربية';
        await tester.pumpWidget(
          const MaterialApp(home: FreightHomeScreen(province: 'صنعاء')),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('شحن صغير'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('شحن صغير'));
        await tester.pumpAndSettle();
        final dialog = find.byType(SimpleDialog);
        expect(dialog, findsOneWidget);
        expect(
          find.descendant(of: dialog, matching: find.text('مكتب محافظة أخرى')),
          findsNothing,
        );
        if (cancel) {
          Navigator.of(tester.element(dialog)).pop();
          await tester.pumpAndSettle();
          expect(find.byType(FreightRequestScreen), findsNothing);
        } else {
          await tester.tap(
            find.descendant(
              of: dialog,
              matching: find.text('مكتب الشحن الثاني'),
            ),
          );
          await tester.pumpAndSettle();
          final request = tester.widget<FreightRequestScreen>(
            find.byType(FreightRequestScreen),
          );
          expect(request.draft.office.serviceId, 'freight-b');
          expect(request.draft.office.basePrice, 23000);
          expect(request.draft.size, FreightSize.small);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty freight catalog does not open a local booking', (
    tester,
  ) async {
    ProviderBookingFlow.current = flow((_) async => json({'data': []}));
    app.appSession.language = 'العربية';
    await tester.pumpWidget(
      const MaterialApp(home: FreightHomeScreen(province: 'صنعاء')),
    );
    await tester.pumpAndSettle();
    final size = find.text('شحن صغير');
    await tester.ensureVisible(size);
    await tester.pumpAndSettle();
    await tester.tap(size);
    await tester.pumpAndSettle();
    expect(
      find.text('لا توجد خدمات شحن متاحة في هذه المحافظة بعد.'),
      findsOneWidget,
    );
    expect(find.byType(FreightRequestScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'same-name halls keep the selected provider and service price',
    () async {
      final first = service('hall-a', price: 400000)
        ..['service_type'] = 'event_hall';
      final second = service('hall-b', provider: 'provider-b', price: 720000)
        ..['service_type'] = 'event_hall';
      final backend = flow((request) async {
        if (request.url.path.endsWith('/services')) {
          return json({
            'data': [first, second],
          });
        }
        if (request.url.path.endsWith('/services/hall-b')) {
          return json({'data': second});
        }
        expect(request.url.path, '/api/bookings');
        final body = jsonDecode(request.body) as Map;
        expect(body['service_id'], 'hall-b');
        expect(body['provider_id'], 'provider-b');
        return json({
          'data': {
            'id': 'hall-booking',
            'provider_id': 'provider-b',
            'service_id': 'hall-b',
            'total': 720000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-10T10:00:00Z',
          },
        }, 201);
      });
      ProviderBookingFlow.current = backend;
      backend.snapshots['halls'] = [
        CatalogService.fromJson(first),
        CatalogService.fromJson(second),
      ];
      final details = HallBookingDetails(
        serviceId: 'hall-b',
        name: 'خدمة مسجلة',
        province: 'صنعاء',
        date: DateTime(2026, 10, 1),
        period: 'مسائية',
        event: 'زفاف',
        guests: 100,
        package: 'الذهبية',
      );
      expect(details.total, 720000);
      final booking = await backend.create(
        ProviderBookingSelection(
          module: 'halls',
          serviceId: details.serviceId,
          serviceName: details.name,
          province: details.province,
        ),
      );
      expect(booking.serviceId, 'hall-b');
      expect(booking.total, details.total);
    },
  );

  for (final unit in ['per_booking', 'per_night']) {
    test(
      'hotel $unit booking reserves one room and uses the server total',
      () async {
        final room = service('service-a', price: 15000)
          ..['service_type'] = 'hotel_room'
          ..['pricing_unit'] = unit;
        final backend = flow((request) async {
          if (request.url.path.endsWith('/services')) {
            return json({
              'data': [room],
            });
          }
          if (request.url.path.endsWith('/services/service-a')) {
            return json({'data': room});
          }
          expect(request.url.path, '/api/bookings');
          final body = jsonDecode(request.body) as Map;
          expect(body['quantity'], 1);
          expect(body['total'], 15000);
          expect(body['expected_total'], 68000);
          expect(body.containsKey('scheduled_at'), isFalse);
          expect(body['metadata']['arrival'], '2030-01-02');
          expect(body['metadata']['departure'], '2030-01-06');
          expect(body['metadata']['nights'], 4);
          return json({
            'data': {
              'id': 'priced-booking',
              'provider_id': 'provider-a',
              'service_id': 'service-a',
              'total': 68000,
              'currency': 'YER',
              'status': 'pending',
              'created_at': '2026-09-10T10:00:00Z',
            },
          }, 201);
        });
        ProviderBookingFlow.current = backend;
        backend.snapshots['hotels'] = [CatalogService.fromJson(room)];
        expect(providerQuotedTotal('hotels', 'service-a', 15000, 4), 60000);
        final booking = await backend.create(
          const ProviderBookingSelection(
            module: 'hotels',
            serviceName: 'خدمة مسجلة',
            serviceId: 'service-a',
            quantity: 4,
            expectedTotal: 68000,
            metadata: {
              'arrival': '2030-01-02',
              'departure': '2030-01-06',
              'nights': 4,
            },
          ),
        );
        expect(booking.total, 68000);
      },
    );
  }

  test('hotel booking cannot post without an accepted server quote', () async {
    final room = service('service-a')..['service_type'] = 'hotel_room';
    var posted = false;
    final backend = flow((request) async {
      if (request.url.path.endsWith('/services')) {
        return json({
          'data': [room],
        });
      }
      if (request.url.path.endsWith('/services/service-a')) {
        return json({'data': room});
      }
      posted = true;
      return json({'data': {}});
    });
    await expectLater(
      backend.create(
        const ProviderBookingSelection(
          module: 'hotels',
          serviceName: 'خدمة مسجلة',
          serviceId: 'service-a',
          metadata: {'arrival': '2030-01-02', 'departure': '2030-01-05'},
        ),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(posted, isFalse);
  });

  for (final module in ['travel', 'car_rental']) {
    testWidgets(
      '$module checkout uses provider price without local surcharges or payment',
      (tester) async {
        var created = 0;
        final catalogService = service(
          'service-a',
        )..['pricing_unit'] = module == 'car_rental' ? 'per_day' : 'per_person';
        ProviderBookingFlow.current = flow((request) async {
          if (request.url.path.endsWith('/availabilities')) {
            return json({'data': []});
          }
          if (request.url.path.endsWith('/services')) {
            return json({
              'data': [catalogService],
            });
          }
          if (request.url.path.endsWith('/services/service-a')) {
            return json({'data': catalogService});
          }
          expect(request.url.path, '/api/bookings');
          final body = jsonDecode(request.body) as Map;
          expect(body['service_id'], 'service-a');
          expect(body['quantity'], 2);
          expect(body['total'], 24000);
          if (module == 'car_rental') {
            expect(
              body['metadata']['arrival'],
              DateTime(2030, 1, 2).toIso8601String(),
            );
            expect(
              body['metadata']['departure'],
              DateTime(2030, 1, 4).toIso8601String(),
            );
            expect(body.containsKey('scheduled_at'), isFalse);
          }
          created++;
          return json({
            'data': {
              'id': 'provider-booking',
              'provider_id': 'provider-a',
              'service_id': 'service-a',
              'total': 24000,
              'currency': 'YER',
              'status': 'pending',
              'created_at': '2026-09-10T10:00:00Z',
            },
          }, 201);
        });
        app.appSession.language = 'العربية';
        final Widget screen;
        if (module == 'travel') {
          screen = travel.TravelPaymentScreen(
            listing: const TravelListing(
              id: 'service-a',
              category: TravelCategory.flights,
              title: 'خدمة مسجلة',
              provider: 'مقدم الخدمة',
              destination: 'عدن',
              price: 12000,
              priceUnit: 'للمسافر',
              rating: 0,
              reviews: 0,
              processingTime: '',
              description: '',
              features: [],
              requirements: [],
            ),
            request: travel.TravelRequestData(
              origin: 'صنعاء',
              destination: 'عدن',
              startDate: DateTime.now().add(const Duration(days: 2)),
              returnDate: null,
              applicants: 2,
              option: 'مسجلة',
            ),
            subtotal: 24000,
            applicant: const travel.TravelApplicantData(
              name: 'مسافر',
              phone: '967700000000',
              email: '',
              documentNumber: '123',
              nationality: 'يمني',
              notes: '',
            ),
          );
        } else {
          screen = rental.CarPaymentScreen(
            office: rental.RentalOffice('مقدم الخدمة', 'صنعاء', 0, 1),
            car: rental.RentalCar(
              name: 'خدمة مسجلة',
              model: '',
              oldPrice: 12000,
              price: 12000,
              status: '',
              specs: {},
              serviceId: 'service-a',
            ),
            customerName: 'مستأجر',
            rentalStart: DateTime(2030, 1, 2),
            rentalEnd: DateTime(2030, 1, 4),
            selectedExtras: {'إضافة محلية': 1000},
          );
        }
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();
        expect(find.text('إضافة محلية'), findsNothing);
        expect(find.text('تأمين السفر'), findsNothing);
        final button = module == 'travel'
            ? find.byKey(const Key('travel-pay-button'))
            : find.text('استكمال الدفع');
        if (module == 'travel') {
          await tester.scrollUntilVisible(
            button,
            400,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
        }
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(created, 1);
        expect(find.text('رقم الحجز: provider-booking'), findsOneWidget);
      },
    );
  }

  test(
    'remote delivery, freight and halls do not add local fees or references',
    () {
      final backend = flow((_) async => json({'data': []}));
      ProviderBookingFlow.current = backend;
      final basket = DeliveryBasket()
        ..add(
          DeliveryCartItem(
            id: 'delivery-item',
            name: 'صنف مسجل',
            category: 'delivery',
            unitPrice: 2500,
            quantity: 2,
          ),
        );
      expect(basket.total, 5000);
      expect(basket.deliveryFee, 0);
      final freight = FreightDraft(
        office: const FreightOffice(
          'مقدم شحن',
          'شحن',
          0,
          0,
          'صنعاء',
          serviceId: 'freight-service',
          basePrice: 17500,
        ),
        quoteOnly: false,
      )..insurance = true;
      expect(freight.total, 17500);
      final hall = service('hall-service', price: 710000);
      hall['service_type'] = 'event_hall';
      backend.snapshots['halls'] = [CatalogService.fromJson(hall)];
      final booking = HallBookingDetails(
        name: 'خدمة مسجلة',
        province: 'صنعاء',
        date: DateTime(2026, 10, 1),
        period: 'مسائية',
        event: 'زفاف',
        guests: 100,
        package: 'الذهبية',
      );
      expect(booking.total, 710000);
      expect(booking.reference, 'يصدر بعد إرسال الطلب');
      backend.snapshots['halls'] = [];
      expect(booking.total, 0);
    },
  );

  testWidgets(
    'hotel checkout sends calendar dates and one room without a generic slot',
    (tester) async {
      final arrival = DateTime.now().add(const Duration(days: 3));
      final stay = app.HotelStay(
        arrival: arrival,
        departure: arrival.add(const Duration(days: 3)),
        adults: 3,
        children: 1,
      );
      var created = 0;
      final room = service('service-a')
        ..['service_type'] = 'hotel_room'
        ..['pricing_unit'] = 'per_night';
      ProviderBookingFlow.current = flow((request) async {
        if (request.url.path.endsWith('/hotel-stay-quote')) {
          expect(request.method, 'GET');
          expect(request.url.queryParameters['arrival'], stay.arrivalDate);
          expect(request.url.queryParameters['departure'], stay.departureDate);
          expect(request.url.queryParameters['rooms'], '1');
          return json({
            'data': {
              'total': 40000,
              'currency': 'YER',
              'nights': 3,
              'rooms': 1,
              'nightly_prices': [],
            },
          });
        }
        if (request.url.path.endsWith('/availabilities')) {
          fail('Hotel inventory must not use the generic slot picker.');
        }
        if (request.url.path.endsWith('/services')) {
          return json({
            'data': [room],
          });
        }
        if (request.url.path.endsWith('/services/service-a')) {
          return json({'data': room});
        }
        expect(request.url.path, '/api/bookings');
        final body = jsonDecode(request.body) as Map;
        expect(body['quantity'], 1);
        expect(body['expected_total'], 40000);
        expect(body.containsKey('scheduled_at'), isFalse);
        expect(body.containsKey('service_availability_id'), isFalse);
        expect(body['metadata']['arrival'], stay.arrivalDate);
        expect(body['metadata']['departure'], stay.departureDate);
        expect(body['metadata']['nights'], 3);
        expect(body['metadata']['adults'], 3);
        expect(body['metadata']['children'], 1);
        expect(body['metadata']['guest']['name'], 'ضيف الاختبار');
        created++;
        return json({
          'data': {
            'id': 'hotel-booking',
            'provider_id': 'provider-a',
            'service_id': 'service-a',
            'total': 41000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-09T10:00:00Z',
          },
        }, 201);
      });
      app.appSession.language = 'العربية';
      await tester.pumpWidget(
        MaterialApp(
          home: app.PaymentScreen(
            backendServiceId: 'service-a',
            roomName: 'خدمة مسجلة',
            price: '12000',
            image: 'assets/images/hotel_booking_banner.png',
            hotelStay: stay,
            guestDetails: const {'name': 'ضيف الاختبار'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('معاينة السعر الحالية: 40,000 YER'), findsOneWidget);
      expect(
        find.text('السعر النهائي والتوفر يحددهما الخادم عند إرسال طلب الحجز.'),
        findsOneWidget,
      );
      final state =
          tester.state(find.byType(app.PaymentScreen)) as ProviderBookingState;
      // Exercise the existing confirmation button, including its selected stay data.
      final button = find.text('تأكيد طلب الحجز');
      await tester.scrollUntilVisible(
        button,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(state.providerBooking?.id, 'hotel-booking');
      expect(state.providerBooking?.total, 41000);
      expect(find.text('الإجمالي المعتمد: 41000 YER'), findsOneWidget);
    },
  );

  testWidgets(
    'hotel booking retries a failed quote before allowing submission',
    (tester) async {
      final arrival = DateTime.now().add(const Duration(days: 4));
      final stay = app.HotelStay(
        arrival: arrival,
        departure: arrival.add(const Duration(days: 2)),
      );
      final room = service('service-a')
        ..['service_type'] = 'hotel_room'
        ..['pricing_unit'] = 'per_night';
      var created = 0;
      var quoteAttempts = 0;
      ProviderBookingFlow.current = flow((request) async {
        if (request.url.path.endsWith('/hotel-stay-quote')) {
          quoteAttempts++;
          if (quoteAttempts == 1) {
            return json({'message': 'Preview temporarily unavailable'}, 503);
          }
          return json({
            'data': {
              'total': 26000,
              'currency': 'YER',
              'nights': 2,
              'rooms': 1,
              'nightly_prices': [],
            },
          });
        }
        if (request.url.path.endsWith('/availabilities')) {
          fail('Hotel inventory must not use the generic slot picker.');
        }
        if (request.url.path.endsWith('/services')) {
          return json({
            'data': [room],
          });
        }
        if (request.url.path.endsWith('/services/service-a')) {
          return json({'data': room});
        }
        expect(request.url.path, '/api/bookings');
        final body = jsonDecode(request.body) as Map;
        expect(body['expected_total'], 26000);
        created++;
        return json({
          'data': {
            'id': 'hotel-fallback-booking',
            'provider_id': 'provider-a',
            'service_id': 'service-a',
            'total': 27000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-09T10:00:00Z',
          },
        }, 201);
      });
      app.appSession.language = 'العربية';
      await tester.pumpWidget(
        MaterialApp(
          home: app.PaymentScreen(
            backendServiceId: 'service-a',
            roomName: 'خدمة مسجلة',
            price: '12000',
            image: 'assets/images/hotel_booking_banner.png',
            hotelStay: stay,
            guestDetails: const {'name': 'ضيف الاختبار'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('السعر: بانتظار معاينة الخادم'), findsOneWidget);
      expect(find.textContaining('تعذرت معاينة السعر والتوفر'), findsOneWidget);
      expect(created, 0);
      final retry = find.text('إعادة معاينة السعر');
      await tester.scrollUntilVisible(
        retry,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(quoteAttempts, 2);
      expect(created, 0);
      expect(find.text('معاينة السعر الحالية: 26,000 YER'), findsOneWidget);
      final button = find.text('تأكيد طلب الحجز');
      await tester.scrollUntilVisible(
        button,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(find.text('الإجمالي المعتمد: 27000 YER'), findsOneWidget);
    },
  );

  testWidgets(
    'table booking uses the provider service identifier and current date',
    (tester) async {
      var created = 0;
      final table = service('table-a');
      table['name_ar'] = 'طاولة عائلية مسجلة';
      table['service_type'] = 'restaurant_table';
      ProviderBookingFlow.current = flow((request) async {
        if (request.url.path.endsWith('/availabilities')) {
          return json({'data': []});
        }
        if (request.url.path.endsWith('/services')) {
          return json({
            'data': [table],
          });
        }
        if (request.url.path.endsWith('/services/table-a')) {
          return json({'data': table});
        }
        expect(request.url.path, '/api/bookings');
        final body = jsonDecode(request.body) as Map;
        expect(body['service_id'], 'table-a');
        expect(body['provider_id'], 'provider-a');
        final date = DateTime.parse(body['scheduled_at'] as String).toLocal();
        expect(DateUtils.dateOnly(date), DateUtils.dateOnly(DateTime.now()));
        expect(date.hour, 12);
        expect(body['metadata']['guests'], 4);
        created++;
        return json({
          'data': {
            'id': 'table-booking',
            'provider_id': 'provider-a',
            'service_id': 'table-a',
            'total': 12000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-09T10:00:00Z',
          },
        }, 201);
      });
      app.appSession.language = 'العربية';
      await tester.pumpWidget(
        const MaterialApp(
          home: app.RestaurantTableBookingScreen(providerId: 'provider-a'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('تأكيد الحجز'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('تأكيد الحجز'));
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(find.text('رقم الحجز: table-booking'), findsOneWidget);
    },
  );

  test(
    'uses the selected server service, provider, currency and quantity',
    () async {
      final requests = <http.Request>[];
      final backend = flow((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/service-categories')) {
          return json({
            'data': [
              {'id': 'category', 'name_ar': 'فنادق', 'slug': 'hotels'},
            ],
          });
        }
        if (request.url.path.endsWith('/services')) {
          return json({
            'data': [service('service-a')],
            'meta': {'current_page': 1, 'last_page': 1},
          });
        }
        if (request.url.path.endsWith('/availabilities')) {
          return json({'data': []});
        }
        if (request.url.path.endsWith('/services/service-a')) {
          return json({'data': service('service-a', price: 15000)});
        }
        expect(request.url.path, '/api/bookings');
        expect(request.headers['Authorization'], 'Bearer test-token');
        final body = jsonDecode(request.body) as Map;
        expect(body['service_id'], 'service-a');
        expect(body['provider_id'], 'provider-a');
        expect(body['quantity'], 2);
        expect(body['service_availability_id'], 'slot-a');
        expect(body['total'], 30000);
        return json({
          'data': {
            'id': 'server-booking',
            'provider_id': 'provider-a',
            'service_id': 'service-a',
            'total': 30000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-08T08:00:00Z',
          },
        }, 201);
      });
      final booking = await backend.create(selection, availabilityId: 'slot-a');
      expect(booking.id, 'server-booking');
      expect(booking.total, 30000);
      expect(requests.where((r) => r.url.path.contains('payment')), isEmpty);
    },
  );

  test('does not substitute a different service or province', () async {
    var posted = false;
    final backend = flow((request) async {
      if (request.method == 'POST') posted = true;
      if (request.url.path.endsWith('/service-categories')) {
        return json({
          'data': [
            {'id': 'category', 'name_ar': 'فنادق'},
          ],
        });
      }
      final wrongProvince = service('service-a');
      wrongProvince['provider'] = {
        'id': 'provider-a',
        'display_name_ar': 'مقدم الخدمة',
        'province': 'عدن',
      };
      return json({
        'data': [service('service-b'), wrongProvince],
        'meta': {'current_page': 1, 'last_page': 1},
      });
    });
    await expectLater(backend.create(selection), throwsA(isA<ApiException>()));
    expect(posted, isFalse);
  });

  test(
    'loads later pages and does not fall back to local services when empty',
    () async {
      final backend = flow((request) async {
        if (request.url.path.endsWith('/service-categories')) {
          return json({
            'data': [
              {'id': 'category', 'name_ar': 'فنادق'},
            ],
          });
        }
        final page = int.parse(request.url.queryParameters['page']!);
        return json({
          'data': page == 1 ? <Object>[] : [service('service-a')],
          'meta': {'current_page': page, 'last_page': 2},
        });
      });
      await backend.load('hotels', province: 'صنعاء');
      expect(backend.loaded('hotels').single.id, 'service-a');
      expect(backend.loaded('restaurants'), isEmpty);
    },
  );

  for (final confirm in [true, false]) {
    testWidgets('available appointment requires an explicit choice: $confirm', (
      tester,
    ) async {
      var created = 0;
      ProviderBookingFlow.current = flow((request) async {
        if (request.url.path.endsWith('/services')) {
          return json({
            'data': [service('service-a')],
          });
        }
        if (request.url.path.endsWith('/services/service-a')) {
          return json({'data': service('service-a')});
        }
        if (request.url.path.endsWith('/availabilities')) {
          return json({
            'data': [
              {
                'id': 'slot-a',
                'service_id': 'service-a',
                'available_quantity': 2,
                'price': 17000,
                'currency': 'YER',
                'starts_at': '2026-10-01T10:00:00Z',
              },
              {
                'id': 'full-slot',
                'service_id': 'service-a',
                'available_quantity': 0,
                'price': 99999,
                'currency': 'YER',
              },
            ],
          });
        }
        expect(request.url.path, '/api/bookings');
        expect(jsonDecode(request.body)['service_availability_id'], 'slot-a');
        created++;
        return json({
          'data': {
            'id': 'scheduled-booking',
            'provider_id': 'provider-a',
            'service_id': 'service-a',
            'total': 34000,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2026-09-09T10:00:00Z',
          },
        }, 201);
      });
      await tester.pumpWidget(const MaterialApp(home: _Checkout()));
      await tester.tap(find.text('submit'));
      await tester.pumpAndSettle();
      expect(created, 0);
      expect(find.textContaining('99999'), findsNothing);
      if (confirm) {
        await tester.tap(find.textContaining('17000'));
        await tester.pumpAndSettle();
        expect(created, 1);
        expect(find.textContaining('34000'), findsOneWidget);
      } else {
        Navigator.of(tester.element(find.byType(SimpleDialog))).pop();
        await tester.pumpAndSettle();
        expect(created, 0);
      }
    });
  }

  testWidgets('repeated confirmation keeps the server booking and never pays', (
    tester,
  ) async {
    var created = 0;
    ProviderBookingFlow.current = flow((request) async {
      if (request.url.path.endsWith('/service-categories')) {
        return json({
          'data': [
            {'id': 'category', 'name_ar': 'فنادق'},
          ],
        });
      }
      if (request.url.path.endsWith('/services')) {
        return json({
          'data': [service('service-a')],
          'meta': {'current_page': 1, 'last_page': 1},
        });
      }
      if (request.url.path.endsWith('/availabilities')) {
        return json({'data': []});
      }
      if (request.url.path.endsWith('/services/service-a')) {
        return json({'data': service('service-a')});
      }
      expect(request.url.path, '/api/bookings');
      created++;
      return json({
        'data': {
          'id': 'server-booking',
          'provider_id': 'provider-a',
          'service_id': 'service-a',
          'total': 24000,
          'currency': 'YER',
          'status': 'pending',
          'created_at': '2026-09-08T08:00:00Z',
        },
      }, 201);
    });
    await tester.pumpWidget(const MaterialApp(home: _Checkout()));
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    expect(find.text('رقم الحجز: server-booking'), findsOneWidget);
    expect(find.textContaining('لم يتم خصم'), findsOneWidget);
    await tester.tap(find.text('حسنًا'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    expect(created, 1);
  });
}

class _Checkout extends StatefulWidget {
  const _Checkout();
  @override
  State<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<_Checkout>
    with ProviderBookingState<_Checkout> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: ElevatedButton(
      onPressed: () => submitProviderBooking(selection),
      child: const Text('submit'),
    ),
  );
}
