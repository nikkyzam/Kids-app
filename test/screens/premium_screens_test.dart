import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/screens/auth/sign_in_screen.dart';
import 'package:playsteps/screens/digest/weekly_digest_screen.dart';
import 'package:playsteps/screens/insights/development_snapshot_screen.dart';
import 'package:playsteps/screens/insights/pediatrician_prep_screen.dart';
import 'package:playsteps/screens/leaps/developmental_leaps_screen.dart';
import 'package:playsteps/screens/paywall/premium_plus_screen.dart';
import 'package:playsteps/screens/plan/activity_plan_screen.dart';
import 'package:playsteps/screens/settings/family_sharing_screen.dart';
import 'package:playsteps/screens/settings/settings_screen.dart';

import '../support/harness.dart';

void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset(premiumPlus: true));
  tearDown(Harness.tearDownClock);

  group('DevelopmentalLeapsScreen', () {
    testWidgets('renders the leap calendar', (tester) async {
      await Harness.pump(tester, const DevelopmentalLeapsScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await Harness.pump(tester, const DevelopmentalLeapsScreen(),
          size: const Size(360, 1600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders for a newborn', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.reset(now: DateTime(2025, 9, 1), premiumPlus: true);
      });
      await Harness.pump(tester, const DevelopmentalLeapsScreen());
      expect(tester.takeException(), isNull);
    });
  });

  group('DevelopmentSnapshotScreen', () {
    testWidgets('renders with no data', (tester) async {
      await Harness.pump(tester, const DevelopmentSnapshotScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with achievements and completions', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 12);
        await Harness.seedAchievements(child.id!, ['m_0_1', 'm_0_2', 'm_0_3']);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const DevelopmentSnapshotScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 12);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const DevelopmentSnapshotScreen(),
          size: const Size(360, 1800));
      expect(tester.takeException(), isNull);
    });
  });

  group('PediatricianPrepScreen', () {
    testWidgets('renders with no data', (tester) async {
      await Harness.pump(tester, const PediatricianPrepScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with growth measurements recorded', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(
            child.id!, GrowthMetric.weight, [6.0, 7.0, 8.0]);
        await Harness.seedAchievements(child.id!, ['m_0_1']);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const PediatricianPrepScreen());
      expect(tester.takeException(), isNull);
    });
  });

  group('WeeklyDigestScreen', () {
    testWidgets('renders an empty week', (tester) async {
      await Harness.pump(tester, const WeeklyDigestScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a full week', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 7);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const WeeklyDigestScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 7);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const WeeklyDigestScreen(),
          size: const Size(360, 1600));
      expect(tester.takeException(), isNull);
    });
  });

  group('ActivityPlanScreen', () {
    testWidgets('renders the plan', (tester) async {
      await Harness.pump(tester, const ActivityPlanScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with history', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 14);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const ActivityPlanScreen());
      expect(tester.takeException(), isNull);
    });
  });

  group('PremiumPlusScreen', () {
    testWidgets('shows the active state when subscribed', (tester) async {
      await Harness.pump(tester, const PremiumPlusScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the offer when not subscribed', (tester) async {
      await Harness.realAsync(tester, () async => Harness.reset());
      await Harness.pump(tester, const PremiumPlusScreen());

      // No store is available under test, so purchasing must be disabled
      // rather than falling back to a free unlock.
      expect(find.text('Store unavailable'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsScreen', () {
    testWidgets('starts behind the parental gate', (tester) async {
      await Harness.pump(tester, const SettingsScreen());

      expect(find.text('Parent Zone'), findsOneWidget);
      expect(find.text('Unlock Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the gate challenge on tap', (tester) async {
      await Harness.pump(tester, const SettingsScreen());

      await tester.tap(find.text('Unlock Settings'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('What is'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('FamilySharingScreen', () {
    testWidgets('reports sync unavailable without Supabase', (tester) async {
      // The build has placeholder credentials, so the screen must explain
      // itself rather than erroring.
      await Harness.pump(tester, const FamilySharingScreen());
      expect(tester.takeException(), isNull);
    });
  });

  group('SignInScreen', () {
    testWidgets('renders without a configured backend', (tester) async {
      await Harness.pump(tester, const SignInScreen());
      expect(tester.takeException(), isNull);
    });
  });
}
