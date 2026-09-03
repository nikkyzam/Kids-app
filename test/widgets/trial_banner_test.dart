import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/screens/paywall/paywall_screen.dart';
import 'package:playsteps/widgets/activity_card.dart';
import 'package:playsteps/widgets/trial_banner.dart';

import '../support/harness.dart';

void main() {
  Harness.initOnce();

  // The frozen "today" the harness uses.
  final today = DateTime(2026, 5, 20, 10);

  tearDown(Harness.tearDownClock);

  group('TrialBanner', () {
    testWidgets('counts down during the trial', (tester) async {
      await Harness.resetInTest(tester,
          trialStartedAt: today.subtract(const Duration(days: 4)));
      await Harness.pump(tester, const Scaffold(body: TrialBanner()));

      expect(find.textContaining('10 days left'), findsOneWidget);
    });

    testWidgets('says so on the last day rather than counting to one',
        (tester) async {
      await Harness.resetInTest(tester,
          trialStartedAt: today.subtract(const Duration(days: 13, hours: 2)));
      await Harness.pump(tester, const Scaffold(body: TrialBanner()));

      expect(find.text('Last day of your free trial'), findsOneWidget);
    });

    testWidgets('disappears once the trial has ended', (tester) async {
      await Harness.resetInTest(tester,
          trialStartedAt: today.subtract(const Duration(days: 20)));
      await Harness.pump(tester, const Scaffold(body: TrialBanner()));

      expect(find.textContaining('free trial'), findsNothing);
    });

    testWidgets('stays out of the way for a parent who has paid',
        (tester) async {
      await Harness.resetInTest(
        tester,
        premium: true,
        trialStartedAt: today.subtract(const Duration(days: 2)),
      );
      await Harness.pump(tester, const Scaffold(body: TrialBanner()));

      expect(find.textContaining('free trial'), findsNothing);
    });
  });

  group('what the trial unlocks on screen', () {
    testWidgets("today's activity is not locked during the trial",
        (tester) async {
      final child = await Harness.resetInTest(tester,
          trialStartedAt: today.subtract(const Duration(days: 1)));
      await Harness.pump(tester, ActivityCard(profileId: child.id!));

      expect(find.text("Today's activity is Premium"), findsNothing);
      expect(find.text('Complete Challenge'), findsOneWidget);
    });

    testWidgets('and is locked again once it lapses', (tester) async {
      final child = await Harness.resetInTest(tester,
          trialStartedAt: today.subtract(const Duration(days: 30)));
      await Harness.pump(tester, ActivityCard(profileId: child.id!));

      // Emma is nine months old in the harness, so her activity is outside the
      // age-based free tier.
      expect(find.text("Today's activity is Premium"), findsOneWidget);
    });
  });

  group('PaywallScreen', () {
    testWidgets('opens during the trial instead of dismissing itself',
        (tester) async {
      await Harness.resetInTest(tester,
          trialStartedAt: today.subtract(const Duration(days: 3)));
      await Harness.pump(tester, const PaywallScreen());

      // Everything is unlocked mid-trial; if the paywall dismissed on that it
      // would be unreachable for the whole fortnight.
      expect(find.text('Unlock PlaySteps Premium'), findsOneWidget);
      expect(find.textContaining('11 days left'), findsOneWidget);
    });

    testWidgets('explains that nothing is lost when the trial has ended',
        (tester) async {
      await Harness.resetInTest(tester,
          trialStartedAt: today.subtract(const Duration(days: 30)));
      await Harness.pump(tester, const PaywallScreen());

      expect(find.textContaining('free trial has ended'), findsOneWidget);
      expect(find.textContaining('still'), findsWidgets);
    });

    testWidgets('promises future content packs to a paying parent',
        (tester) async {
      await Harness.resetInTest(tester);
      await Harness.pump(tester, const PaywallScreen());

      expect(find.text('Every Future Activity Pack'), findsOneWidget);
    });
  });
}
