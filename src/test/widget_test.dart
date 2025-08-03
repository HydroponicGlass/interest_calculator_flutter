// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interestcalculator/main.dart';

void main() {
  testWidgets('올인원 이자 계산기 app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InterestCalculatorApp());

    // Wait for any pending frame callbacks to complete
    await tester.pumpAndSettle();

    // Verify that the app starts with the main screen
    expect(find.text('이자계산'), findsOneWidget);
    expect(find.text('내 계좌'), findsOneWidget);
  });
}
