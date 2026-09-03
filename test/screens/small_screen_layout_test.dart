import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/data/milestones_data.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/screens/badges/badges_screen.dart';
import 'package:playsteps/screens/digest/weekly_digest_screen.dart';
import 'package:playsteps/screens/growth/growth_tracker_screen.dart';
import 'package:playsteps/screens/history/activity_history_screen.dart';
import 'package:playsteps/screens/home/home_screen.dart';
import 'package:playsteps/screens/insights/development_snapshot_screen.dart';
import 'package:playsteps/screens/insights/pediatrician_prep_screen.dart';
import 'package:playsteps/screens/leaps/developmental_leaps_screen.dart';
import 'package:playsteps/screens/library/activity_library_screen.dart';
import 'package:playsteps/screens/memories/memories_timeline_screen.dart';
import 'package:playsteps/screens/milestones/milestones_screen.dart';
import 'package:playsteps/screens/onboarding/onboarding_screen.dart';
import 'package:playsteps/screens/paywall/paywall_screen.dart';
import 'package:playsteps/screens/paywall/premium_plus_screen.dart';
import 'package:playsteps/screens/plan/activity_plan_screen.dart';
import 'package:playsteps/screens/settings/settings_screen.dart';

import '../support/harness.dart';

/// Every screen, at the two smallest supported viewports, with real content
/// and at a raised text scale.
///
/// Not `matchesGoldenFile`: a committed PNG has to be produced on the same
/// platform, font stack and renderer that CI uses, and when it drifts it fails
/// with "13,208 pixels differ" — which is a rewritten reference file far more
/// often than it is a fixed bug. What actually breaks on a small phone is
/// content that does not fit, and Flutter already reports that as a test
/// exception. These tests give the screens the real viewport height rather
/// than the tall canvas the other suites use, scroll each one end to end, and
/// fail on any overflow along the way.
void main() {
  Harness.initOnce();

  /// A 320×568 phone (iPhone SE, 1st gen) and a 360×640 Android — the two
  /// sizes the requirements name as the floor.
  const viewports = <String, Size>{
    '320x568': Size(320, 568),
    '360x640': Size(360, 640),
  };

  /// Well past the point where a fixed-height row stops fitting its text.
  const largeTextScale = 1.3;

  late ChildProfile child;

  setUp(() async {
    child = await Harness.reset();
    // Real content, not an empty database: an empty screen is exactly the one
    // that never overflows.
    await Harness.seedCompletions(child.id!, 12);
    await Harness.seedAchievements(
        child.id!, MilestonesData.all.take(8).map((m) => m.id).toList());
    await Harness.seedGrowth(
        child.id!, GrowthMetric.weight, const [4.1, 5.2, 6.0, 6.8, 7.3, 7.9]);
    await Harness.seedGrowth(
        child.id!, GrowthMetric.height, const [54, 58, 62, 65, 68, 70]);
    await Harness.seedPhotos(child.id!, 4);
    await Harness.seedBadges(child.id!, ['first_step', 'week_warrior']);
    await Harness.reload(child);
  });

  tearDown(Harness.tearDownClock);

  /// Renders [screen] at [size], scrolls it to the end, and returns any error
  /// Flutter reported on the way.
  Future<Object?> layoutAt(
    WidgetTester tester,
    Widget screen,
    Size size, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Harness.wrap(screen),
      ),
    );
    await Harness.settleAsync(tester, cycles: 8);
    await tester.pump(const Duration(milliseconds: 400));

    final overflow = tester.takeException();
    if (overflow != null) return overflow;

    // Overflow further down a list only shows up once that part is built, so
    // the page is dragged through rather than only rendered at the top.
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      for (int i = 0; i < 6; i++) {
        await tester.drag(scrollables.first, const Offset(0, -400));
        await tester.pump();
        final error = tester.takeException();
        if (error != null) return error;
      }
    }
    return null;
  }

  Map<String, Widget Function()> screens() => {
        'Home': () => const HomeScreen(),
        'Onboarding': () => const OnboardingScreen(),
        // A tab body rather than a page: in the app it sits inside
        // HomeScreen's Scaffold, and its chips need that Material ancestor.
        'Milestones': () => const Scaffold(body: MilestonesScreen()),
        'Activity history': () => const ActivityHistoryScreen(),
        'Activity library': () => const ActivityLibraryScreen(),
        'Memories': () => MemoriesTimelineScreen(profileId: child.id!),
        'Growth tracker': () => GrowthTrackerScreen(profileId: child.id!),
        'Badges': () => const BadgesScreen(),
        'Settings': () => const SettingsScreen(),
        'Paywall': () => const PaywallScreen(),
        'Premium Plus': () => const PremiumPlusScreen(),
        'Developmental leaps': () => const DevelopmentalLeapsScreen(),
        'Activity plan': () => const ActivityPlanScreen(),
        'Development snapshot': () => const DevelopmentSnapshotScreen(),
        'Pediatrician prep': () => const PediatricianPrepScreen(),
        'Weekly digest': () => const WeeklyDigestScreen(),
      };

  for (final viewport in viewports.entries) {
    group('at ${viewport.key}', () {
      screens().forEach((name, build) {
        testWidgets('$name lays out', (tester) async {
          expect(await layoutAt(tester, build(), viewport.value), isNull,
              reason: '$name overflows at ${viewport.key}');
        });
      });
    });
  }

  group('at 320x568 with larger text', () {
    screens().forEach((name, build) {
      testWidgets('$name lays out', (tester) async {
        // The narrowest phone at the largest text a parent is likely to have
        // set — where a row sized to its content stops fitting.
        expect(
          await layoutAt(tester, build(), const Size(320, 568),
              textScale: largeTextScale),
          isNull,
          reason: '$name overflows at 320x568 with $largeTextScale text scale',
        );
      });
    });
  });
}
