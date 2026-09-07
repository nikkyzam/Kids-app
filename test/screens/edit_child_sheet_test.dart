import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/screens/settings/edit_child_sheet.dart';
import 'package:playsteps/utils/clock.dart';

/// The edit sheet is the only way to correct a birthday or add a due date
/// after onboarding, and both of its date pickers are opened with whatever is
/// already stored. `showDatePicker` asserts that the initial date lies inside
/// the range it is given, so a stored value the range does not cover is not a
/// bad default — it is a crash on the way in.
void main() {
  final today = DateTime(2026, 5, 20, 10);

  setUp(() => Clock.freeze(today));
  tearDown(Clock.reset);

  Future<void> openSheet(WidgetTester tester, ChildProfile profile) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EditChildSheet(profile: profile)),
    ));
    await tester.pumpAndSettle();
  }

  ChildProfile child({required DateTime dob, DateTime? due}) => ChildProfile(
        id: 1,
        name: 'Emma',
        dateOfBirth: dob,
        dueDate: due,
        createdAt: dob,
      );

  testWidgets('opens the birthday picker for a child older than the range',
      (tester) async {
    // The picker only offers the last ten years. A profile restored from a
    // backup — or synced from a device with a wrong clock — can sit outside
    // that, and the sheet still has to open.
    await openSheet(tester, child(dob: DateTime(2010, 3, 4)));

    await tester.tap(
        find.text(DateFormat('MMMM d, yyyy').format(DateTime(2010, 3, 4))));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the birthday picker for a date in the future',
      (tester) async {
    await openSheet(tester, child(dob: DateTime(2030, 1, 1)));

    await tester.tap(
        find.text(DateFormat('MMMM d, yyyy').format(DateTime(2030, 1, 1))));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the due-date picker for a gap wider than the cap',
      (tester) async {
    // A corrupt row claiming the baby was a year early. The picker offers the
    // same 17 weeks the model clamps to, so the stored date is outside it.
    final dob = DateTime(2026, 1, 10);
    await openSheet(tester, child(dob: dob, due: DateTime(2027, 1, 10)));

    await tester.tap(
        find.text(DateFormat('MMMM d, yyyy').format(DateTime(2027, 1, 10))));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drops a due date that no longer follows the birth date',
      (tester) async {
    // Correcting the birthday forward past the due date would leave a profile
    // that claims prematurity while correcting nothing.
    final dob = DateTime(2026, 1, 10);
    await openSheet(tester, child(dob: dob, due: DateTime(2026, 1, 12)));

    expect(find.text(DateFormat('MMMM d, yyyy').format(DateTime(2026, 1, 12))),
        findsOneWidget);

    await tester.tap(
        find.text(DateFormat('MMMM d, yyyy').format(DateTime(2026, 1, 10))));
    await tester.pumpAndSettle();
    // Pick a birthday after the stored due date.
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(DateFormat('MMMM d, yyyy').format(DateTime(2026, 1, 15))),
        findsOneWidget);
    expect(find.text(DateFormat('MMMM d, yyyy').format(DateTime(2026, 1, 12))),
        findsNothing);
  });
}
