import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/main.dart';

void main() {
  testWidgets('ينتقل التطبيق من الترحيب إلى الرئيسية', (tester) async {
    await tester.pumpWidget(const HujuzatApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
  });
}
