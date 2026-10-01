import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/features/bookings/data/booking_repository.dart';
import 'package:hojuzatcom/features/bookings/presentation/provider_booking_flow.dart';
import 'package:hojuzatcom/features/catalog/data/catalog_repository.dart';

class SectorBackendFixture {
  SectorBackendFixture({
    required List<Map<String, Object?>> services,
    required int total,
  }) {
    final previous = ProviderBookingFlow.current;
    final api = ApiClient(
      baseUri: Uri.parse('https://example.test/api/'),
      accessTokenProvider: () async => 'sector-token',
      httpClient: MockClient((request) async {
        http.Response response(Object data, [int status = 200]) =>
            http.Response(
              jsonEncode(data),
              status,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
        if (request.url.path.endsWith('/availabilities')) {
          return response({'data': []});
        }
        if (request.url.path.endsWith('/services')) {
          return response({
            'data': services
                .where(
                  (s) =>
                      s['service_type'] ==
                      request.url.queryParameters['service_type'],
                )
                .toList(),
          });
        }
        if (request.url.path.contains('/services/')) {
          final id = Uri.decodeComponent(
            request.url.path.split('/services/').last,
          );
          return response({'data': services.singleWhere((s) => s['id'] == id)});
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/api/bookings');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(body);
        expect(body['idempotency_key'], isNotEmpty);
        return response({
          'data': {
            'id': 'server-booking',
            'provider_id': body['provider_id'],
            'service_id': body['service_id'],
            'total': total,
            'currency': 'YER',
            'status': 'pending',
            'created_at': '2030-01-01T00:00:00Z',
          },
        }, 201);
      }),
    );
    ProviderBookingFlow.current = ProviderBookingFlow(
      catalog: RemoteCatalogRepository(api),
      bookings: RemoteBookingRepository(api),
    );
    addTearDown(() {
      ProviderBookingFlow.current = previous;
      api.close();
    });
  }
  final requests = <Map<String, dynamic>>[];
  static Map<String, Object?> service({
    required String id,
    required String name,
    required String type,
    required String province,
    required int price,
    String provider = 'provider-a',
    String providerName = 'مقدم الخدمة',
  }) => {
    'id': id,
    'name_ar': name,
    'service_type': type,
    'provider_id': provider,
    'service_category_id': 'category-a',
    'base_price': price,
    'pricing_unit': 'per_booking',
    'currency': 'YER',
    'provider': {
      'id': provider,
      'display_name_ar': providerName,
      'province': province,
    },
  };
}
