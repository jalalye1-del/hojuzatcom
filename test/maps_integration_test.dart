import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/maps/app_map_launcher.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/features/catalog/data/catalog_repository.dart';
import 'package:hojuzatcom/features/catalog/domain/catalog_models.dart';
import 'package:hojuzatcom/features/transport/presentation/transport_tracking_card.dart';
import 'package:hojuzatcom/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSession.language = 'العربية';
  });

  test('provider coordinates take priority over the registered address', () {
    expect(
      AppMapLauncher.providerQuery(
        const CatalogProvider(
          id: 'p',
          displayNameAr: 'فندق',
          latitude: 15.3694,
          longitude: 44.191,
          address: 'عنوان',
          city: 'صنعاء',
          province: 'صنعاء',
        ),
      ),
      '15.3694,44.191',
    );
  });

  test(
    'invalid or incomplete coordinates fall back only to a recorded address',
    () {
      for (final latitude in [null, 91.0, double.nan, double.infinity]) {
        expect(
          AppMapLauncher.providerQuery(
            CatalogProvider(
              id: 'p',
              displayNameAr: 'فندق',
              latitude: latitude,
              longitude: 44,
              address: ' شارع الزبيري ',
              city: 'صنعاء',
            ),
          ),
          'شارع الزبيري، صنعاء',
        );
      }
      expect(
        AppMapLauncher.providerQuery(
          const CatalogProvider(
            id: 'p',
            displayNameAr: 'فندق',
            latitude: 15,
            longitude: 181,
          ),
        ),
        isNull,
      );
      expect(
        AppMapLauncher.providerQuery(
          const CatalogProvider(id: 'p', displayNameAr: 'فندق', city: 'صنعاء'),
        ),
        isNull,
      );
      expect(
        AppMapLauncher.providerQuery(
          const CatalogProvider(
            id: 'p',
            displayNameAr: 'فندق',
            latitude: 0,
            longitude: 0,
          ),
        ),
        '0.0,0.0',
      );
    },
  );

  for (final scenario in ['coordinates', 'missing', 'offline']) {
    testWidgets('provider map handles $scenario without an invented location', (
      tester,
    ) async {
      final launched = <String>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'launch') {
          launched.add((call.arguments as Map)['url'] as String);
        }
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      var requested = 0;
      final catalog = RemoteCatalogRepository(
        ApiClient(
          baseUri: Uri.parse('https://example.test/api/'),
          httpClient: MockClient((request) async {
            requested++;
            expect(request.url.path, '/api/providers/provider-a');
            if (scenario == 'offline') throw http.ClientException('offline');
            return http.Response(
              jsonEncode({
                'data': {
                  'id': 'provider-a',
                  'display_name_ar': 'فندق',
                  if (scenario == 'coordinates') ...{
                    'latitude': '15.3694',
                    'longitude': '44.191',
                  },
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppMapLauncher.openProvider(
                  context,
                  catalog: catalog,
                  providerId: 'provider-a',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(requested, 1);
      if (scenario == 'coordinates') {
        expect(launched, hasLength(1));
        expect(
          Uri.parse(launched.single).queryParameters['query'],
          '15.3694,44.191',
        );
      } else {
        expect(launched, isEmpty);
        expect(
          find.text(
            scenario == 'missing'
                ? 'لم يحدد مقدم الخدمة موقعه بعد.'
                : 'تعذر تحميل موقع مقدم الخدمة. حاول مجددًا.',
          ),
          findsOneWidget,
        );
      }
    });
  }

  testWidgets(
    'unconfigured tracking does not expose a driver, ETA or fake coordinates',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DeliveryTrackingScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('التتبع المباشر غير متاح حاليًا'), findsOneWidget);
      expect(find.textContaining('أحمد محمد'), findsNothing);
      expect(find.textContaining('18 دقيقة'), findsNothing);
      expect(find.text('التتبع المباشر عبر GPS'), findsNothing);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransportTrackingCard(
              title: 'مركبة الشحن',
              distance: '12 كم',
              rating: 4.9,
              status: 'في الطريق',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12 كم • 4.9 ★'), findsNothing);
      expect(find.text('في الطريق'), findsNothing);
      expect(find.text('التتبع المباشر غير متاح حاليًا'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
