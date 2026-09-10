import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/features/halls/presentation/premium_hall_flow.dart';
import 'package:hojuzatcom/features/transport/presentation/car_rental_flow.dart';
import 'package:hojuzatcom/main.dart';

void main() {
  testWidgets('غرف الفندق تعرض معرضاً يتضمن الفيديو', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HotelDetailScreen(
          title: 'فندق الاختبار',
          address: 'صنعاء',
          price: '20,000',
          image: 'assets/Services images/الفنادق.jpg',
        ),
      ),
    );

    final gallery = find.byKey(const Key('hotel-room-deluxe-gallery'));
    await tester.scrollUntilVisible(
      gallery,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(gallery, findsOneWidget);
    await tester.tap(find.byKey(const Key('hotel-room-deluxe-open-video')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('hotel-room-deluxe-video-player')),
      findsOneWidget,
    );
  });

  testWidgets('تفاصيل القاعة تعرض الصور والفيديو في المعرض الرئيسي', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HallVenueScreen(name: 'قاعة الاختبار', province: 'صنعاء'),
      ),
    );

    expect(find.byKey(const Key('hall-details-gallery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hall-details-open-video')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hall-details-video-player')), findsOneWidget);
  });

  testWidgets('البنر الرئيسي لتفاصيل السيارة يتضمن الفيديو', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CarDetailsScreen(
          office: rentalOffices.first,
          car: rentalCars.first,
        ),
      ),
    );

    expect(find.byKey(const Key('car-details-gallery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('car-details-open-video')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('car-details-video-player')), findsOneWidget);
  });
}
