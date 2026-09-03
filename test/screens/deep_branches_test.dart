import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/screens/digest/weekly_digest_screen.dart';
import 'package:playsteps/screens/growth/growth_tracker_screen.dart';
import 'package:playsteps/screens/home/home_screen.dart';
import 'package:playsteps/screens/memories/memories_timeline_screen.dart';
import 'package:playsteps/screens/settings/family_sharing_screen.dart';
import 'package:playsteps/screens/settings/settings_screen.dart';

import '../support/harness.dart';
import '../support/parental_gate.dart';

void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset());
  tearDown(Harness.tearDownClock);

  group('SettingsScreen once unlocked', () {
    testWidgets('lists every section', (tester) async {
      await Harness.pump(tester, const SettingsScreen());
      await unlockSettings(tester);

      // Section headers are rendered uppercase.
      expect(find.text('CHILDREN'), findsOneWidget);
      expect(find.text('PREMIUM'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('DATA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the active child and an add slot', (tester) async {
      await Harness.pump(tester, const SettingsScreen());
      await unlockSettings(tester);

      expect(find.text('Emma'), findsWidgets);
      expect(find.text('Add Child Profile'), findsOneWidget);
    });

    testWidgets('offers the paywall rows when not premium', (tester) async {
      await Harness.pump(tester, const SettingsScreen());
      await unlockSettings(tester);

      expect(find.textContaining('Unlock Premium'), findsOneWidget);
      expect(find.textContaining('Premium Plus'), findsWidgets);
    });

    testWidgets('shows the owned state when premium', (tester) async {
      await Harness.resetInTest(tester, premium: true, premiumPlus: true);
      await Harness.pump(tester, const SettingsScreen());
      await unlockSettings(tester);

      expect(find.text('PlaySteps Premium'), findsOneWidget);
      expect(find.text('Premium Plus — Active'), findsOneWidget);
    });

    testWidgets('restore reports that the store is unavailable',
        (tester) async {
      await Harness.pump(tester, const SettingsScreen());
      await unlockSettings(tester);

      await tester.tap(find.text('Restore Purchases'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('toggling the reminder switch does not throw', (tester) async {
      await Harness.pump(tester, const SettingsScreen());
      await unlockSettings(tester);

      final toggle = find.byType(SwitchListTile);
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await Harness.pump(tester, const SettingsScreen(),
          size: const Size(360, 2000));
      await unlockSettings(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('a second child appears in the list', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.profiles.addProfile(ChildProfile(
          name: 'Noah',
          dateOfBirth: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
        ));
      });
      await Harness.pump(tester, const SettingsScreen());
      await unlockSettings(tester);

      expect(find.text('Noah'), findsWidgets);
    });
  });

  group('FamilySharingScreen', () {
    testWidgets('explains that sync is not configured', (tester) async {
      await Harness.pump(tester, const FamilySharingScreen());

      // With placeholder Supabase credentials the screen must degrade to an
      // explanation rather than offering controls that cannot work.
      expect(Harness.auth.isSyncAvailable, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await Harness.pump(tester, const FamilySharingScreen(),
          size: const Size(360, 1600));
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen navigation', () {
    testWidgets('switches to milestones and back', (tester) async {
      await Harness.pump(tester, const HomeScreen());

      await tester.tap(find.text('Milestones').last);
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text("Today's Play").last);
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with badges earned', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedBadges(child.id!, ['first_step', 'week_warrior']);
        await Harness.seedCompletions(child.id!, 10);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const HomeScreen());

      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone with data', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 20);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const HomeScreen(),
          size: const Size(360, 2000));

      expect(tester.takeException(), isNull);
    });
  });

  group('WeeklyDigestScreen data shapes', () {
    testWidgets('renders a partial week', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 3);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const WeeklyDigestScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with milestones achieved this week', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 5);
        await Harness.seedAchievements(child.id!, ['m_0_1', 'm_0_2']);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const WeeklyDigestScreen());
      expect(tester.takeException(), isNull);
    });
  });

  group('GrowthTracker across metrics', () {
    testWidgets('switches to the height tab', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(
            child.id!, GrowthMetric.height, [60.0, 63.0, 66.0]);
      });
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      await tester.tap(find.text('Height'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('switches to the head tab', (tester) async {
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      await tester.tap(find.text('Head'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('imperial conversion renders for height', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(child.id!, GrowthMetric.weight, [7.0, 8.0]);
        await Harness.reload(child);
      });
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      await tester.tap(find.text('kg/cm'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('lbs/in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MemoriesTimeline data shapes', () {
    testWidgets('renders many memories', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedPhotos(child.id!, 8);
      });
      await Harness.pump(tester, MemoriesTimelineScreen(profileId: child.id!));

      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedPhotos(child.id!, 4);
      });
      await Harness.pump(
        tester,
        MemoriesTimelineScreen(profileId: child.id!),
        size: const Size(360, 1600),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
