import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/screens/growth/growth_tracker_screen.dart';
import 'package:playsteps/screens/settings/edit_child_sheet.dart';

import '../support/harness.dart';

void main() {
  Harness.initOnce();

  tearDown(Harness.tearDownClock);

  /// Emma in the harness is born 20 August 2025 with "today" frozen at 20 May
  /// 2026, so measurements dated in early 2026 land inside the WHO tables.
  Future<ChildProfile> childWithMeasurements(
    WidgetTester tester, {
    ChildSex? sex,
  }) async {
    final child = await Harness.resetInTest(tester);
    await tester.runAsync(() async {
      await Harness.seedGrowth(
        child.id!,
        GrowthMetric.weight,
        const [7.0, 7.6, 8.1, 8.5],
        startingOn: DateTime(2026, 1, 15),
      );
      if (sex != null) {
        await Harness.profiles.updateProfile(child.copyWith(sex: sex));
      }
      await Harness.profiles.loadProfiles();
    });
    return Harness.profiles.profiles.first;
  }

  group('the percentile overlay', () {
    testWidgets('reports where the latest measurement sits', (tester) async {
      final child = await childWithMeasurements(tester, sex: ChildSex.female);
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      expect(find.textContaining('percentile for weight'), findsOneWidget);
      expect(find.textContaining('same age and sex'), findsOneWidget);
    });

    testWidgets('always carries the not-a-verdict line', (tester) async {
      final child = await childWithMeasurements(tester, sex: ChildSex.male);
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      // A percentile is the number in this app most likely to be read as a
      // grade, so the qualifier sits next to it rather than in a help screen.
      expect(find.textContaining('Shown for context only'), findsOneWidget);
      expect(find.textContaining('their own curves'), findsOneWidget);
    });

    testWidgets('says what is missing when no sex is recorded', (tester) async {
      final child = await childWithMeasurements(tester);
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      // The curves are sex-specific, so without it there is no honest curve —
      // and the screen says how to fix that rather than showing nothing.
      expect(find.textContaining('percentile for weight'), findsNothing);
      expect(find.textContaining('WHO growth curves'), findsOneWidget);
      expect(find.textContaining('Settings'), findsWidgets);
    });

    testWidgets('explains the adjusted age for a baby born early',
        (tester) async {
      final child = await childWithMeasurements(tester, sex: ChildSex.female);
      await tester.runAsync(() async {
        await Harness.profiles.updateProfile(child.copyWith(
          dueDate: child.dateOfBirth.add(const Duration(days: 56)),
        ));
        await Harness.profiles.loadProfiles();
      });
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      expect(find.textContaining('adjusted age'), findsOneWidget);
    });

    testWidgets('renders the chart with the curves without throwing',
        (tester) async {
      final child = await childWithMeasurements(tester, sex: ChildSex.female);
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('EditChildSheet', () {
    testWidgets('records a sex that onboarding never asked for',
        (tester) async {
      final child = await Harness.resetInTest(tester);
      expect(child.sex, isNull);

      await Harness.pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => EditChildSheet.show(context, child),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Girl'), findsOneWidget);
      expect(find.text('Boy'), findsOneWidget);
      expect(find.textContaining('WHO growth curves'), findsOneWidget);
    });

    testWidgets('hands back the edited profile', (tester) async {
      final child = await Harness.resetInTest(tester);
      ChildProfile? result;

      await Harness.pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await EditChildSheet.show(context, child),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Girl'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.sex, ChildSex.female);
      expect(result!.id, child.id);
      expect(result!.name, child.name);
    });

    testWidgets('lets an answer be taken back', (tester) async {
      final child = await Harness.resetInTest(tester);
      ChildProfile? result;

      await Harness.pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await EditChildSheet.show(
                  context, child.copyWith(sex: ChildSex.male)),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tapping the selected chip clears it: a parent who answered by accident
      // must be able to unanswer.
      await tester.tap(find.text('Boy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result!.sex, isNull);
    });

    testWidgets('backing out changes nothing', (tester) async {
      final child = await Harness.resetInTest(tester);
      ChildProfile? result;

      await Harness.pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await EditChildSheet.show(context, child),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
