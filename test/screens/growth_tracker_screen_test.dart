import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/screens/growth/growth_tracker_screen.dart';

import '../support/harness.dart';

void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset());
  tearDown(Harness.tearDownClock);

  Future<void> open(WidgetTester tester) =>
      Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

  group('empty state', () {
    testWidgets('offers to log the first measurement', (tester) async {
      await open(tester);

      expect(find.text('Growth Tracker'), findsOneWidget);
      expect(find.text('No measurements yet'), findsWidgets);
      expect(find.text('Tap + to log your first measurement'), findsWidgets);
    });

    testWidgets('renders the three metric tabs', (tester) async {
      await open(tester);

      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Head'), findsOneWidget);
    });

    testWidgets('starts in metric units', (tester) async {
      await open(tester);
      expect(find.text('kg/cm'), findsOneWidget);
    });
  });

  group('with measurements', () {
    setUp(() async {
      await Harness.seedGrowth(
        child.id!,
        GrowthMetric.weight,
        [6.0, 6.8, 7.4, 8.1],
      );
      await Harness.reload(child);
    });

    testWidgets('renders the chart instead of the empty state', (tester) async {
      await open(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No measurements yet'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('lists the logged values', (tester) async {
      await open(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('8.1'), findsWidgets);
    });

    testWidgets('switching to imperial changes the unit label', (tester) async {
      await open(tester);
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('kg/cm'));
      await tester.pump();

      expect(find.text('lbs/in'), findsOneWidget);
    });
  });

  group('single and degenerate data sets', () {
    testWidgets('a single measurement does not crash the chart',
        (tester) async {
      // One point means a zero-width date range and a zero value range; the
      // painter must not divide by zero.
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(child.id!, GrowthMetric.weight, [7.0]);
        await Harness.reload(child);
      });

      await open(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('identical values do not crash the chart', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(
            child.id!, GrowthMetric.weight, [7.0, 7.0, 7.0]);
        await Harness.reload(child);
      });

      await open(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a very large value still lays out', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(child.id!, GrowthMetric.weight, [7.0, 999.9]);
        await Harness.reload(child);
      });

      await open(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });

  group('add measurement sheet', () {
    testWidgets('opens from the floating action button', (tester) async {
      await open(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('opens from the app bar action', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Add measurement'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TextField), findsWidgets);
    });
  });
}
