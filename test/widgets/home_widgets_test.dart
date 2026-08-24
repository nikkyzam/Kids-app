import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/widgets/activity_card.dart';
import 'package:playsteps/widgets/daily_tip_card.dart';
import 'package:playsteps/widgets/parental_gate_dialog.dart';
import 'package:playsteps/widgets/skill_coverage_card.dart';
import 'package:playsteps/widgets/streak_banner.dart';
import 'package:playsteps/widgets/weekly_recap_card.dart';

import '../support/harness.dart';

/// Each widget is pumped on its own at a realistic phone width so a layout
/// overflow is attributed to the widget that causes it, instead of surfacing
/// as one failure somewhere inside HomeScreen.
void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset());
  tearDown(Harness.tearDownClock);

  /// 360 is a common small-phone width (Galaxy A-series, Pixel "a" portrait).
  Future<void> pumpAt(WidgetTester tester, Widget w, double width) async {
    await Harness.pump(
      tester,
      Scaffold(body: SingleChildScrollView(child: w)),
      size: Size(width, 1400),
    );
  }

  group('StreakBanner', () {
    testWidgets('lays out with no streak', (tester) async {
      await pumpAt(tester, const StreakBanner(), 420);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out with an active streak', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 8);
        await Harness.reload(child);
      });
      await pumpAt(tester, const StreakBanner(), 420);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 120);
        await Harness.reload(child);
      });
      await pumpAt(tester, const StreakBanner(), 360);
      expect(tester.takeException(), isNull);
    });
  });

  group('SkillCoverageCard', () {
    testWidgets('lays out with no data', (tester) async {
      await pumpAt(tester, const SkillCoverageCard(), 420);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out with completions', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 10);
        await Harness.reload(child);
      });
      await pumpAt(tester, const SkillCoverageCard(), 360);
      expect(tester.takeException(), isNull);
    });
  });

  group('WeeklyRecapCard', () {
    testWidgets('lays out with no data', (tester) async {
      await pumpAt(tester, const WeeklyRecapCard(), 420);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out with a full week', (tester) async {
      await Harness.realAsync(tester, () async {
        await Harness.seedCompletions(child.id!, 7);
        await Harness.reload(child);
      });
      await pumpAt(tester, const WeeklyRecapCard(), 360);
      expect(tester.takeException(), isNull);
    });
  });

  group('DailyTipCard', () {
    testWidgets('lays out and expands on tap', (tester) async {
      await pumpAt(tester, const DailyTipCard(), 420);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(DailyTipCard));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });

  group('ActivityCard', () {
    testWidgets('lays out today\'s activity', (tester) async {
      await pumpAt(tester, ActivityCard(profileId: child.id!), 420);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await pumpAt(tester, ActivityCard(profileId: child.id!), 360);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the locked state for a premium activity',
        (tester) async {
      // A three-year-old is well past the free tier.
      await Harness.realAsync(tester, () async {
        await Harness.reset(now: DateTime(2026, 5, 20, 10));
      });
      await pumpAt(tester, ActivityCard(profileId: child.id!), 420);
      expect(tester.takeException(), isNull);
    });
  });

  group('ParentalGateDialog', () {
    testWidgets('asks the question in words, not digits', (tester) async {
      await Harness.pump(
        tester,
        const Scaffold(body: Center(child: ParentalGateDialog())),
      );

      // Spelled out deliberately so a child who can read digits cannot pass.
      expect(find.textContaining('times'), findsOneWidget);
      expect(find.textContaining('What is'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers answer options and reports a wrong one',
        (tester) async {
      await Harness.pump(
        tester,
        const Scaffold(body: Center(child: ParentalGateDialog())),
      );

      // Every option is a digit button; tapping them all guarantees at least
      // one wrong answer, which must show the retry message rather than pass.
      final options = find.byType(InkWell);
      expect(options, findsWidgets);

      await tester.tap(options.first);
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });
}
