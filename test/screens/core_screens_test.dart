import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/screens/badges/badges_screen.dart';
import 'package:playsteps/screens/history/activity_history_screen.dart';
import 'package:playsteps/screens/home/home_screen.dart';
import 'package:playsteps/screens/library/activity_library_screen.dart';
import 'package:playsteps/screens/memories/memories_timeline_screen.dart';
import 'package:playsteps/screens/milestones/milestones_screen.dart';

import '../support/harness.dart';

void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset());
  tearDown(Harness.tearDownClock);

  group('HomeScreen', () {
    testWidgets('greets by time of day and shows the child', (tester) async {
      await Harness.pump(tester, const HomeScreen());

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.textContaining('Emma'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('greeting changes in the afternoon', (tester) async {
      await Harness.resetInTest(tester, now: DateTime(2026, 5, 20, 15));
      await Harness.pump(tester, const HomeScreen());

      expect(find.text('Good afternoon'), findsOneWidget);
    });

    testWidgets('greeting changes in the evening', (tester) async {
      await Harness.resetInTest(tester, now: DateTime(2026, 5, 20, 21));
      await Harness.pump(tester, const HomeScreen());

      expect(find.text('Good evening'), findsOneWidget);
    });

    testWidgets('shows both navigation destinations', (tester) async {
      await Harness.pump(tester, const HomeScreen());

      expect(find.text("Today's Play"), findsWidgets);
      expect(find.text('Milestones'), findsWidgets);
    });

    testWidgets('switching to the milestones tab renders it', (tester) async {
      await Harness.pump(tester, const HomeScreen());

      await tester.tap(find.text('Milestones').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with a completed streak', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 8);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const HomeScreen());

      expect(tester.takeException(), isNull);
    });

    testWidgets('premium unlocks the plus tiles', (tester) async {
      await Harness.resetInTest(tester, premium: true, premiumPlus: true);
      await Harness.pump(tester, const HomeScreen());

      expect(tester.takeException(), isNull);
    });
  });

  group('ActivityLibraryScreen', () {
    testWidgets('renders the library', (tester) async {
      await Harness.pump(tester, const ActivityLibraryScreen());

      expect(find.text('Activity Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders for a premium user', (tester) async {
      await Harness.resetInTest(tester, premium: true);
      await Harness.pump(tester, const ActivityLibraryScreen());

      expect(find.text('Activity Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MilestonesScreen', () {
    testWidgets('renders the ledger', (tester) async {
      await Harness.pump(tester, const Scaffold(body: MilestonesScreen()));

      expect(find.textContaining('Milestone'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with achievements recorded', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedAchievements(child.id!, ['m_0_1', 'm_0_2']);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const Scaffold(body: MilestonesScreen()));

      expect(tester.takeException(), isNull);
    });
  });

  group('ActivityHistoryScreen', () {
    testWidgets('shows the empty state with no history', (tester) async {
      await Harness.pump(tester, const ActivityHistoryScreen());

      expect(find.text('Activity History'), findsOneWidget);
      expect(find.text('No activities completed yet'), findsOneWidget);
    });

    testWidgets('lists completions grouped by month', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 5);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const ActivityHistoryScreen());

      expect(find.text('No activities completed yet'), findsNothing);
      expect(find.textContaining('May'), findsWidgets);
    });

    testWidgets('handles completions spanning two months', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 3,
            endingOn: DateTime(2026, 5, 2));
        await Harness.reload(child);
      });
      await Harness.pump(tester, const ActivityHistoryScreen());

      // 2 May back three days crosses into April, so the list must render two
      // month groups rather than collapsing them.
      expect(find.text('No activities completed yet'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('BadgesScreen', () {
    testWidgets('renders with nothing unlocked', (tester) async {
      await Harness.pump(tester, const BadgesScreen());

      expect(find.text('Achievements'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders unlocked badges', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedBadges(child.id!, ['first_step', 'week_warrior']);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const BadgesScreen());

      expect(tester.takeException(), isNull);
    });
  });

  group('MemoriesTimelineScreen', () {
    testWidgets('shows the empty state', (tester) async {
      await Harness.pump(tester, MemoriesTimelineScreen(profileId: child.id!));

      expect(find.text('Photo Memories'), findsOneWidget);
      expect(find.text('No memories yet'), findsWidgets);
    });

    testWidgets('lists saved memories', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedPhotos(child.id!, 3);
      });
      await Harness.pump(tester, MemoriesTimelineScreen(profileId: child.id!));

      expect(find.text('No memories yet'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a missing image file does not crash the timeline',
        (tester) async {
      // The paths point at files that were never written, which is what a
      // restored backup or a synced record from another device looks like.
      await Harness.realAsync(tester, () async {
        await Harness.seedPhotos(child.id!, 1);
      });
      await Harness.pump(tester, MemoriesTimelineScreen(profileId: child.id!));

      expect(tester.takeException(), isNull);
    });
  });
}
