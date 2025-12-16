// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'helpers/db_test_helper.dart';

import '../lib/app/app.dart';

void main() {
  setUpAll(() {
    initializeTestDatabase();
  });

  testWidgets('Timeline app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: UsersTimelineApp()));

    // Wait for initial frame
    await tester.pump();
    
    // The app should show either loading state or the main app
    // Both are valid states during initialization
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Wait a bit more for potential state changes
    await tester.pump(const Duration(milliseconds: 100));
    
    // Verify that the app structure is present
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // The app should load successfully without throwing exceptions
    // This is a basic smoke test to ensure the app structure is sound
  });
}
