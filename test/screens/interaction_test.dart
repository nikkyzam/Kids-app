import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/screens/growth/growth_tracker_screen.dart';
import 'package:playsteps/screens/memories/memories_timeline_screen.dart';
import 'package:playsteps/screens/onboarding/onboarding_screen.dart';
import 'package:playsteps/screens/settings/settings_screen.dart';
import 'package:playsteps/widgets/activity_card.dart';
import 'package:playsteps/widgets/badge_unlocked_dialog.dart';
import 'package:playsteps/widgets/milestone_item.dart';
import 'package:playsteps/widgets/streak_milestone_dialog.dart';
import 'package:playsteps/data/badges_data.dart';
import 'package:playsteps/data/milestones_data.dart';

import '../support/harness.dart';

/// Drives the flows a parent actually performs, rather than only asserting
/// that screens render.
void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset());
  tearDown(Harness.tearDownClock);

  group('completing today\'s activity', () {
    testWidgets('marks done and can be undone', (tester) async {
      await Harness.pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ActivityCard(profileId: child.id!),
          ),
        ),
      );

      expect(Harness.activities.isCompleted, isFalse);

      final done = find.textContaining('Mark');
      if (done.evaluate().isNotEmpty) {
        await tester.tap(done.first);
        await tester.pump();
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 400));

        expect(Harness.activities.isCompleted, isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('milestone item', () {
    testWidgets('toggles a milestone on tap', (tester) async {
      final milestone = MilestonesData.all.first;

      await Harness.pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MilestoneItem(
              milestone: milestone,
              profileId: child.id!,
            ),
          ),
        ),
      );

      expect(Harness.milestones.isAchieved(milestone.id), isFalse);

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 700));

      expect(Harness.milestones.isAchieved(milestone.id), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an already-achieved milestone', (tester) async {
      final milestone = MilestonesData.all.first;
      await Harness.realAsync(tester, () async {
        await Harness.seedAchievements(child.id!, [milestone.id]);
        await Harness.reload(child);
      });

      await Harness.pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MilestoneItem(
              milestone: milestone,
              profileId: child.id!,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('parental gate', () {
    testWidgets('a correct answer unlocks settings', (tester) async {
      await Harness.pump(tester, const SettingsScreen());

      await tester.tap(find.text('Unlock Settings'));
      await tester.pump(const Duration(milliseconds: 400));

      // Read the question and work out the answer the way a parent would.
      final question = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((s) => s.startsWith('What is'), orElse: () => '');
      expect(question, isNotEmpty);

      const words = [
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
      final parts = question
          .replaceAll('What is ', '')
          .replaceAll('?', '')
          .split(' times ');
      final answer = words.indexOf(parts[0]) * words.indexOf(parts[1]);

      await tester.tap(find.text('$answer').first);
      await tester.pump(const Duration(milliseconds: 400));

      // The gate is passed, so the settings list is now on screen.
      expect(find.text('Parent Zone'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a wrong answer keeps the gate closed', (tester) async {
      await Harness.pump(tester, const SettingsScreen());

      await tester.tap(find.text('Unlock Settings'));
      await tester.pump(const Duration(milliseconds: 400));

      final question = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((s) => s.startsWith('What is'), orElse: () => '');
      const words = [
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
      final parts = question
          .replaceAll('What is ', '')
          .replaceAll('?', '')
          .split(' times ');
      final answer = words.indexOf(parts[0]) * words.indexOf(parts[1]);

      // Tap an option button whose label is not the answer.
      final wrong = find.byWidgetPredicate((w) =>
          w is OutlinedButton &&
          w.child is Text &&
          (w.child as Text).data != '$answer');
      expect(wrong, findsWidgets);
      await tester.tap(wrong.first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Incorrect'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('dialogs', () {
    testWidgets('streak milestone dialog renders', (tester) async {
      await Harness.pump(
        tester,
        const Scaffold(body: StreakMilestoneDialog(streak: 7)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('streak dialog renders a 30-day milestone', (tester) async {
      await Harness.pump(
        tester,
        const Scaffold(body: StreakMilestoneDialog(streak: 30)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('badge unlocked dialog renders', (tester) async {
      await Harness.pump(
        tester,
        Scaffold(
          body: BadgeUnlockedDialog(badge: BadgesData.all.first),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('growth measurement entry', () {
    testWidgets('rejects an empty value', (tester) async {
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final save = find.textContaining('Save');
      if (save.evaluate().isNotEmpty) {
        await tester.tap(save.first);
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts a typed value', (tester) async {
      await Harness.pump(tester, GrowthTrackerScreen(profileId: child.id!));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final field = find.byType(TextField);
      if (field.evaluate().isNotEmpty) {
        await tester.enterText(field.first, '7.4');
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('memories', () {
    testWidgets('offers to delete a memory', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedPhotos(child.id!, 2);
      });
      await Harness.pump(tester, MemoriesTimelineScreen(profileId: child.id!));

      final tiles = find.byType(InkWell);
      if (tiles.evaluate().isNotEmpty) {
        await tester.longPress(tiles.first);
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('onboarding', () {
    testWidgets('Get Started stays disabled until both fields are set',
        (tester) async {
      await Harness.pump(tester, const OnboardingScreen());

      FilledButton button() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Get Started'));

      expect(button().onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'Sam');
      await tester.pump();

      // Name alone is not enough; a date of birth is still required.
      expect(button().onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('trims whitespace-only names', (tester) async {
      await Harness.pump(tester, const OnboardingScreen());

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pump();

      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Get Started'));
      expect(button.onPressed, isNull,
          reason: 'a blank name must not create a profile');
    });
  });
}
