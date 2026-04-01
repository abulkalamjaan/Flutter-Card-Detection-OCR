// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:id_ocr_example/main.dart';

void main() {
  testWidgets('OCR App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts with the 'Start Scanning' button.
    expect(find.text('Start Scanning'), findsOneWidget);
    expect(find.text('Ready to scan your CNIC?'), findsOneWidget);

    // Verify the initial icon is present
    expect(find.byIcon(Icons.document_scanner), findsOneWidget);
  });
}
