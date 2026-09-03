import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/screens/onboarding/onboarding_screen.dart';
import 'package:playsteps/screens/settings/settings_screen.dart';
import 'package:playsteps/services/photo_storage.dart';

import '../support/harness.dart';
import '../support/parental_gate.dart';

void main() {
  Harness.initOnce();

  late Directory tempRoot;

  setUp(() async {
    await Harness.reset();
    tempRoot = await Directory.systemTemp.createTemp('playsteps_wipe');
    PhotoStorage.testRoot = tempRoot.path;
  });

  tearDown(() {
    Harness.tearDownClock();
    PhotoStorage.testRoot = null;
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await Harness.pump(tester, const SettingsScreen());
    await unlockSettings(tester);
    await tester.scrollUntilVisible(find.text('Delete All Data'), 200);
    await tester.tap(find.text('Delete All Data'));
    await tester.pumpAndSettle();
  }

  /// Types the confirmation and taps through, letting the real database and
  /// preference writes behind the tap complete.
  Future<void> confirmDelete(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).last, 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete everything'));
    await Harness.settleAsync(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('the row sits behind the parental gate', (tester) async {
    await Harness.pump(tester, const SettingsScreen());

    // Before the gate is passed there is no way to reach it at all.
    expect(find.text('Delete All Data'), findsNothing);
  });

  testWidgets('the confirm button stays disabled until DELETE is typed',
      (tester) async {
    await openDeleteDialog(tester);

    final button = find.widgetWithText(FilledButton, 'Delete everything');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'delete');
    await tester.pumpAndSettle();

    // Case-insensitive, because a parent typing it under duress should not be
    // fought by the keyboard.
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('backing out changes nothing', (tester) async {
    await openDeleteDialog(tester);

    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      expect(await DatabaseHelper.instance.getProfiles(), hasLength(1));
    });
  });

  testWidgets('confirming wipes the data and returns to onboarding',
      (tester) async {
    await openDeleteDialog(tester);

    await confirmDelete(tester);

    await tester.runAsync(() async {
      expect(await DatabaseHelper.instance.getProfiles(), isEmpty);
    });
    // Nothing else has anything to render with no profiles left, so staying on
    // a settings list built from deleted data would look like a crash.
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('a child can be added again immediately afterwards',
      (tester) async {
    await openDeleteDialog(tester);
    await confirmDelete(tester);

    await tester.runAsync(() async {
      final saved = await DatabaseHelper.instance.insertProfile(ChildProfile(
        name: 'Noah',
        dateOfBirth: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ));
      expect(saved.id, isNotNull);
    });
  });
}
