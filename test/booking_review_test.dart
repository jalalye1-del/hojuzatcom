import 'package:hojuzatcom/core/notifications/interaction_notification_center.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/core/reviews/booking_review_screen.dart';
import 'package:hojuzatcom/core/reviews/service_review.dart';

void main() {
  test('legacy interest calls do not create fake notifications', () {
    final center = InteractionNotificationCenter.instance;
    final count = center.items.length;
    final unread = center.unreadCount;
    center.recordInterest('خدمة');
    expect(center.items.length, count);
    expect(center.unreadCount, unread);
  });
  testWidgets('central review persists once and is visible on a second visit', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    var posts = 0;
    final api = ApiClient(
      baseUri: Uri.parse('https://example.test/api/'),
      accessTokenProvider: () async => 'token',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/bookings/booking-a/review');
        expect(request.headers['Authorization'], 'Bearer token');
        if (request.method == 'POST') {
          posts++;
          saved = jsonDecode(request.body) as Map<String, dynamic>;
        }
        return http.Response(
          jsonEncode({'data': saved}),
          request.method == 'POST' ? 201 : 200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BookingReviewScreen(api: api, bookingId: 'booking-a'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-review-star-4')));
    await tester.enterText(find.byType(TextField), 'خدمة جيدة');
    await tester.tap(find.text('حفظ التقييم'));
    await tester.pumpAndSettle();
    expect(saved, {'rating': 4, 'comment': 'خدمة جيدة'});
    expect(find.text('تقييمك محفوظ لهذا الحجز'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: BookingReviewScreen(api: api, bookingId: 'booking-a'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('خدمة جيدة'), findsOneWidget);
    expect(find.text('حفظ التقييم'), findsNothing);
    expect(posts, 1);
    api.close();
  });
  testWidgets(
    'failed load retries and failed submission preserves entered review',
    (tester) async {
      var offline = true;
      final api = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        accessTokenProvider: () async => 'token',
        httpClient: MockClient((request) async {
          if (offline || request.method == 'POST') {
            return http.Response('{"message":"Unavailable"}', 503);
          }
          return http.Response('{"data":null}', 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BookingReviewScreen(api: api, bookingId: 'booking-a'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('حفظ التقييم'), findsNothing);
      offline = false;
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'يبقى تعليقي');
      await tester.tap(find.text('حفظ التقييم'));
      await tester.pumpAndSettle();
      expect(find.text('يبقى تعليقي'), findsOneWidget);
      expect(find.text('تقييمك محفوظ لهذا الحجز'), findsNothing);
      expect(find.byKey(const Key('review-error')), findsOneWidget);
      api.close();
    },
  );
  test(
    'connected mode cannot mark local completion or save a local review',
    () async {
      final store = ServiceReviewStore()..centralOnly = true;
      await store.markCompleted('فنادق');
      expect(await store.hasUsed('فنادق'), isFalse);
      expect(await store.hasPendingReview('فنادق'), isFalse);
      await expectLater(
        store.saveReview('فنادق', rating: 5, comment: ''),
        throwsStateError,
      );
    },
  );
}
