import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/network/api_client.dart';
import 'package:hojuzatcom/features/bookings/data/booking_repository.dart';
import 'package:hojuzatcom/features/bookings/domain/booking.dart';
import 'package:hojuzatcom/features/bookings/presentation/booking_cancellation_button.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> bookingData(String status) => {
  'id': 'booking-test',
  'provider_id': 'provider-test',
  'service_id': 'service-test',
  'status': status,
  'total': 12000,
  'currency': 'YER',
  'created_at': '2026-09-29T12:00:00Z',
};

void main() {
  testWidgets('confirmation cancels only once and updates the booking', (
    tester,
  ) async {
    var requests = 0;
    Booking? updated;
    final repository = RemoteBookingRepository(
      ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        accessTokenProvider: () async => 'test-token',
        httpClient: MockClient((request) async {
          requests++;
          expect(request.method, 'POST');
          expect(request.url.path, '/api/bookings/booking-test/cancel');
          return http.Response(
            jsonEncode({'data': bookingData('cancelled')}),
            200,
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingCancellationButton(
            booking: Booking.fromJson(bookingData('confirmed')),
            repository: repository,
            onCancelled: (booking) => updated = booking,
          ),
        ),
      ),
    );

    await tester.tap(find.text('إلغاء الحجز'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.tap(find.text('الاحتفاظ بالحجز'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.tap(find.text('إلغاء الحجز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الإلغاء'));
    await tester.pumpAndSettle();

    expect(requests, 1);
    expect(updated?.status, BookingStatus.cancelled);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('server rejection leaves the cancellation action available', (
    tester,
  ) async {
    var changed = false;
    final repository = RemoteBookingRepository(
      ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        accessTokenProvider: () async => 'test-token',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'message': 'الإلغاء غير مسموح لهذه الخدمة'}),
            409,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingCancellationButton(
            booking: Booking.fromJson(bookingData('confirmed')),
            repository: repository,
            onCancelled: (_) => changed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('إلغاء الحجز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الإلغاء'));
    await tester.pumpAndSettle();

    expect(changed, isFalse);
    expect(find.text('الإلغاء غير مسموح لهذه الخدمة'), findsOneWidget);
    expect(find.text('إلغاء الحجز'), findsOneWidget);
  });
}
