import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hojuzatcom/main.dart';

void main() {
  testWidgets('يعرض التطبيق إعادة المحاولة عند تعذر تحميل المحتوى المركزي', (
    tester,
  ) async {
    await tester.pumpWidget(const HujuzatApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.byType(ProvincesScreen), findsNothing);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
