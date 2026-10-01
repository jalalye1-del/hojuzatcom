import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/features/catalog/data/remote_control_panel_repository.dart';
import 'package:hojuzatcom/features/catalog/presentation/application_content_gate.dart';

Map<String, Object?> content(String title) => {
  'data': {
    'version': 1,
    'provinces': [
      {'id': 'aden', 'name': title, 'enabled': true, 'image_path': null},
    ],
    'support': {
      'title': 'الدعم',
      'subtitle': '',
      'address': '',
      'call_numbers': ['12345'],
      'whatsapp_numbers': [],
    },
    'promotions': [],
    'event_banner': null,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'separate clients read the same published changes without local sample inventory',
    () async {
      var title = 'عدن';
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/app-content');
          expect(request.headers.containsKey('authorization'), isFalse);
          return http.Response(
            jsonEncode(content(title)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final first = RemoteControlPanelRepository(client);
      final second = RemoteControlPanelRepository(client);
      await first.load();
      await second.load();
      expect(first.provinces.single.name, second.provinces.single.name);
      title = 'صنعاء';
      await first.load();
      await second.load();
      expect(first.provinces.single.name, 'صنعاء');
      expect(second.provinces.single.name, 'صنعاء');
      expect(first.providers, isEmpty);
      expect(first.promotions, isEmpty);
      expect(first.hotelRoomExtras, isEmpty);
      expect(first.paymentMethods, isEmpty);
      client.close();
    },
  );

  testWidgets('failure displays retry instead of local demo content', (
    tester,
  ) async {
    var fails = true;
    final client = ApiClient(
      baseUri: Uri.parse('https://example.test/api/'),
      httpClient: MockClient(
        (_) async => fails
            ? http.Response('{"message":"Unavailable"}', 503)
            : http.Response(
                jsonEncode(content('عدن')),
                200,
                headers: {'content-type': 'application/json'},
              ),
      ),
    );
    final repository = RemoteControlPanelRepository(client);
    await tester.pumpWidget(
      MaterialApp(
        home: ApplicationContentGate(
          repository: repository,
          child: const Text('published home'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('published home'), findsNothing);
    expect(repository.provinces, isEmpty);
    fails = false;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('published home'), findsOneWidget);
    client.close();
  });

  testWidgets(
    'refresh keeps the current screen mounted and publishes new content',
    (tester) async {
      var title = 'عدن';
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode(content(title)),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      final repository = RemoteControlPanelRepository(client);
      await tester.pumpWidget(
        MaterialApp(
          home: ApplicationContentGate(
            repository: repository,
            child: const Scaffold(body: TextField()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'حجز قيد الإكمال');
      title = 'صنعاء';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repository.provinces.single.name, 'صنعاء');
      expect(find.text('حجز قيد الإكمال'), findsOneWidget);
      expect(tester.takeException(), isNull);
      client.close();
    },
  );
  test(
    'malformed response cannot partially replace published content',
    () async {
      var malformed = false;
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        httpClient: MockClient((_) async {
          final data = content(malformed ? 'incorrect' : 'عدن');
          if (malformed) {
            (data['data'] as Map<String, Object?>)['support'] = null;
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = RemoteControlPanelRepository(client);
      await repository.load();
      malformed = true;
      await expectLater(repository.load(), throwsA(anything));
      expect(repository.provinces.single.name, 'عدن');
      client.close();
    },
  );
}
