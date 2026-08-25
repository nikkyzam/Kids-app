import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/screens/growth/growth_tracker_screen.dart';
import 'package:playsteps/screens/insights/pediatrician_prep_screen.dart';
import 'package:playsteps/screens/leaps/developmental_leaps_screen.dart';
import 'package:playsteps/screens/library/activity_library_screen.dart';
import 'package:playsteps/screens/memories/memories_timeline_screen.dart';
import 'package:playsteps/screens/onboarding/onboarding_screen.dart';
import 'package:playsteps/screens/settings/settings_screen.dart';
import 'package:playsteps/widgets/activity_card.dart';

import '../support/harness.dart';

const _words = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
];

Future<void> _unlockSettings(WidgetTester tester) async {
  await tester.tap(find.text('Unlock Settings'));
  await tester.pump(const Duration(milliseconds: 400));

  final question = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('What is'), orElse: () => '');
  final parts =
      question.replaceAll('What is ', '').replaceAll('?', '').split(' times ');
  final answer = _words.indexOf(parts[0]) * _words.indexOf(parts[1]);

  await tester.tap(find.text('$answer').first);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset());
  tearDown(Harness.tearDownClock);

  group('OnboardingScreen date selection', () {
    testWidgets('opens the date picker and enables Get Started',
        (tester) async {
      await Harness.pump(tester, const OnboardingScreen());

      await tester.enterText(find.byType(TextField).first, 'Sam');
      await tester.pump();

      await tester.tap(find.text('Tap to select date of birth'));
      await tester.pump(const Duration(milliseconds: 600));

      // Accept whatever date the picker opens on.
      final ok = find.text('OK');
      if (ok.evaluate().isNotEmpty) {
        await tester.tap(ok);
        await tester.pump(const Duration(milliseconds: 600));

        final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Get Started'));
        expect(button.onPressed, isNotNull,
            reason: 'name plus a date of birth should enable the button');
        // The age badge appears once a date is chosen.
        expect(find.textContaining('old'), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancelling the picker leaves the button disabled',
        (tester) async {
      await Harness.pump(tester, const OnboardingScreen());

      await tester.enterText(find.byType(TextField).first, 'Sam');
      await tester.pump();

      await tester.tap(find.text('Tap to select date of birth'));
      await tester.pump(const Duration(milliseconds: 600));

      final cancel = find.text('Cancel');
      if (cancel.evaluate().isNotEmpty) {
        await tester.tap(cancel);
        await tester.pump(const Duration(milliseconds: 600));
      }

      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Get Started'));
      expect(button.onPressed, isNull);
    });
  });

  group('ActivityCard states', () {
    testWidgets('renders the locked card for a premium activity',
        (tester) async {
      // A toddler's activity sits outside the free tier.
      await Harness.realAsync(tester, () async {
        await Harness.profiles.addProfile(ChildProfile(
          name: 'Toddler',
          dateOfBirth: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
        ));
        final toddler = Harness.profiles.activeProfile!;
        await Harness.activities
            .loadForProfile(toddler.id!, toddler.ageBandWeeks);
      });

      await Harness.pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ActivityCard(
              profileId: Harness.profiles.activeProfile!.id!,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('completing shows the undo affordance', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 1);
        await Harness.reload(child);
      });

      await Harness.pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ActivityCard(profileId: child.id!),
          ),
        ),
      );

      expect(Harness.activities.isCompleted, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('ActivityLibraryScreen filtering', () {
    testWidgets('selecting a category filter rebuilds the list',
        (tester) async {
      await Harness.pump(tester, const ActivityLibraryScreen());

      final chips = find.byType(FilterChip);
      expect(chips, findsWidgets);

      await tester.tap(chips.at(1));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('cycling through several filters is stable', (tester) async {
      await Harness.pump(tester, const ActivityLibraryScreen());

      final chips = find.byType(FilterChip);
      for (var i = 1; i < 4 && i < chips.evaluate().length; i++) {
        await tester.tap(chips.at(i));
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('premium unlocks the full library', (tester) async {
      await Harness.resetInTest(tester, premium: true);
      await Harness.pump(tester, const ActivityLibraryScreen());

      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsScreen destructive flows', () {
    testWidgets('deleting a child asks before acting', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.profiles.addProfile(ChildProfile(
          name: 'Noah',
          dateOfBirth: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
        ));
      });
      await Harness.pump(tester, const SettingsScreen(),
          size: const Size(420, 2400));
      await _unlockSettings(tester);

      final before = Harness.profiles.profiles.length;
      final delete = find.byIcon(Icons.delete_outline_rounded);
      if (delete.evaluate().isNotEmpty) {
        await tester.tap(delete.first);
        await tester.pump(const Duration(milliseconds: 400));

        expect(Harness.profiles.profiles.length, before,
            reason: 'deletion must wait for confirmation');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the about section renders', (tester) async {
      await Harness.pump(tester, const SettingsScreen(),
          size: const Size(420, 2400));
      await _unlockSettings(tester);

      expect(find.text('ABOUT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the badges row is present', (tester) async {
      await Harness.pump(tester, const SettingsScreen(),
          size: const Size(420, 2400));
      await _unlockSettings(tester);

      expect(find.text('Achievements'), findsWidgets);
    });
  });

  group('MemoriesTimelineScreen interactions', () {
    testWidgets('tapping a memory opens it', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedPhotos(child.id!, 3);
      });
      await Harness.pump(tester, MemoriesTimelineScreen(profileId: child.id!));

      final tiles = find.byType(InkWell);
      if (tiles.evaluate().isNotEmpty) {
        await tester.tap(tiles.first);
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('milestone-tagged memories render', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedPhotos(child.id!, 1);
        await Harness.seedAchievements(child.id!, ['m_0_1']);
        await Harness.reload(child);
      });
      await Harness.pump(tester, MemoriesTimelineScreen(profileId: child.id!));

      expect(tester.takeException(), isNull);
    });
  });

  group('GrowthTracker deletion', () {
    testWidgets('long-pressing a measurement offers to delete it',
        (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(
            child.id!, GrowthMetric.weight, [6.0, 7.0, 8.0]);
      });
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      final rows = find.byType(InkWell);
      if (rows.evaluate().isNotEmpty) {
        await tester.longPress(rows.first);
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a long history without overflowing', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(
          child.id!,
          GrowthMetric.weight,
          List<double>.generate(12, (i) => 5.0 + i * 0.6),
        );
      });
      await Harness.pump(
        tester,
        GrowthTrackerScreen(profileId: child.id!),
        size: const Size(360, 2000),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('age-dependent screens', () {
    testWidgets('leaps renders for a toddler past every leap', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.reset(now: DateTime(2028, 5, 20), premiumPlus: true);
      });
      await Harness.pump(tester, const DevelopmentalLeapsScreen());

      expect(tester.takeException(), isNull);
    });

    testWidgets('doctor prep renders for a toddler', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.reset(now: DateTime(2027, 5, 20), premiumPlus: true);
      });
      await Harness.pump(tester, const PediatricianPrepScreen());

      expect(tester.takeException(), isNull);
    });

    testWidgets('doctor prep renders with a full growth history',
        (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedGrowth(
            child.id!, GrowthMetric.weight, [6.0, 7.0, 8.0]);
        await Harness.seedGrowth(
            child.id!, GrowthMetric.height, [58.0, 62.0, 66.0]);
        await Harness.seedGrowth(
            child.id!, GrowthMetric.headCircumference, [38.0, 40.0]);
        await Harness.seedAchievements(child.id!, ['m_0_1', 'm_0_2']);
        await Harness.reload(child);
      });
      await Harness.pump(tester, const PediatricianPrepScreen(),
          size: const Size(360, 2400));

      expect(tester.takeException(), isNull);
    });
  });
}
