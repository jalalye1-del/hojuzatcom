import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/core/network/api_exception.dart';
import 'package:hojuzatcom/features/bookings/data/booking_repository.dart';
import 'package:hojuzatcom/features/bookings/domain/booking.dart';
import 'package:hojuzatcom/features/bookings/presentation/pending_booking_recovery.dart';

const attempt = PendingBookingAttempt(
  id: 'attempt',
  body: {
    'total': 50,
    'currency': 'YER',
    'metadata': {'service_name': 'غرفة مزدوجة', 'provider_name': 'الفندق'},
  },
);

void main() {
  testWidgets(
    'recovery waits for confirmation and blocks repeated taps while sending',
    (tester) async {
      var calls = 0;
      final response = Completer<Booking>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingBookingRecoveryDialog(
              attempt: attempt,
              retry: () {
                calls++;
                return response.future;
              },
            ),
          ),
        ),
      );
      expect(calls, 0);
      expect(find.text('غرفة مزدوجة'), findsOneWidget);
      expect(find.text('50 YER'), findsOneWidget);
      await tester.tap(find.text('متابعة المحاولة'));
      await tester.pump();
      await tester.tap(find.text('متابعة المحاولة'));
      expect(calls, 1);
      response.complete(
        Booking(
          id: 'server-booking-1',
          providerId: 'provider',
          serviceId: 'service',
          status: BookingStatus.pending,
          total: 50,
          currency: 'YER',
          createdAt: DateTime.utc(2026),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('server-booking-1'), findsOneWidget);
      expect(find.text('لم يتم تنفيذ أي دفع.'), findsOneWidget);
      expect(find.text('متابعة المحاولة'), findsNothing);
    },
  );

  testWidgets('failed recovery shows error and allows another attempt', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendingBookingRecoveryDialog(
            attempt: attempt,
            retry: () async {
              calls++;
              throw const ApiException(message: 'الخادم غير متاح');
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('متابعة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('الخادم غير متاح'), findsOneWidget);
    await tester.tap(find.text('متابعة المحاولة'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('لاحقًا'), findsOneWidget);
  });

  testWidgets(
    'legacy hotel 404 requires checking bookings before local discard',
    (tester) async {
      var retries = 0;
      var discards = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => PendingBookingRecoveryDialog(
                    attempt: const PendingBookingAttempt(
                      id: 'old-hotel',
                      body: {
                        'total': 30000,
                        'currency': 'YER',
                        'metadata': {'module': 'hotels'},
                      },
                    ),
                    retry: () async {
                      retries++;
                      throw StateError('must not retry');
                    },
                    lookup: () async => throw const ApiException(
                      message: 'Not found',
                      code: 'booking_not_found',
                      statusCode: 404,
                    ),
                    discard: () async {
                      discards++;
                    },
                  ),
                ),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      expect(find.textContaining('افحص «حجوزاتي» أولًا'), findsOneWidget);
      expect(find.text('30000 YER'), findsNothing);
      expect(find.text('متابعة المحاولة'), findsNothing);
      await tester.tap(find.text('فحصت حجوزاتي، احذف المحلي'));
      await tester.pumpAndSettle();
      expect(discards, 1);
      expect(retries, 0);
      expect(find.text('حجز فندق يحتاج معاينة سعر جديدة'), findsNothing);
    },
  );

  testWidgets('legacy hotel found on server offers only local cleanup', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendingBookingRecoveryDialog(
            attempt: const PendingBookingAttempt(
              id: 'old-hotel',
              body: {
                'metadata': {'module': 'hotels'},
              },
            ),
            retry: () async {
              retries++;
              throw StateError('must not retry');
            },
            lookup: () async => Booking(
              id: 'existing-booking',
              providerId: 'provider',
              serviceId: 'service',
              status: BookingStatus.pending,
              total: 30000,
              currency: 'YER',
              createdAt: DateTime.utc(2026),
            ),
            discard: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('existing-booking'), findsOneWidget);
    expect(
      find.text('الحجز موجود على الخادم. حذف المحاولة المحلية لا يلغي الحجز.'),
      findsOneWidget,
    );
    expect(find.text('حذف المحاولة المحلية'), findsOneWidget);
    expect(find.text('متابعة المحاولة'), findsNothing);
    expect(retries, 0);
  });

  testWidgets('uncertain hotel lookup keeps discard unavailable', (
    tester,
  ) async {
    var lookups = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendingBookingRecoveryDialog(
            attempt: const PendingBookingAttempt(
              id: 'old-hotel',
              body: {
                'metadata': {'module': 'hotels'},
              },
            ),
            retry: () async => throw StateError('must not retry'),
            lookup: () async {
              lookups++;
              throw const ApiException(
                message: 'Offline',
                code: 'network_error',
              );
            },
            discard: () async => throw StateError('must not discard'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('احتفظنا بالمحاولة ومفتاحها'), findsOneWidget);
    expect(find.text('حذف المحاولة المحلية'), findsNothing);
    expect(find.text('فحصت حجوزاتي، احذف المحلي'), findsNothing);
    await tester.tap(find.text('إعادة التحقق'));
    await tester.pumpAndSettle();
    expect(lookups, 2);
  });
}
