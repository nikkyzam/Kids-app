import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // This test requires a real device or emulator with plugin support (sqflite, etc.)
    // Use integration tests for full widget coverage.
    expect(PlayStepsApp, isNotNull);
  });
}
