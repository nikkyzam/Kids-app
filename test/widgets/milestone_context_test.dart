import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/data/milestones_data.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/widgets/milestone_item.dart';

import '../support/harness.dart';

void main() {
  Harness.initOnce();

  late ChildProfile child;
  setUp(() async => child = await Harness.reset());
  tearDown(Harness.tearDownClock);

  final milestone = MilestonesData.all.first;

  testWidgets('the info button opens the context sheet', (tester) async {
    await Harness.pump(
        tester, MilestoneItem(milestone: milestone, profileId: child.id!));

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('WHAT TO LOOK FOR'), findsOneWidget);
    expect(find.text('WHEN TO TALK TO YOUR PEDIATRICIAN'), findsOneWidget);
  });

  testWidgets('reading the context does not tick the milestone',
      (tester) async {
    await Harness.pump(
        tester, MilestoneItem(milestone: milestone, profileId: child.id!));

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    // The row itself toggles the milestone, so the info button sitting inside
    // it must not fall through to the row.
    expect(Harness.milestones.isAchieved(milestone.id), isFalse);
  });

  testWidgets('the sheet always carries the not-medical-advice line',
      (tester) async {
    await Harness.pump(
        tester, MilestoneItem(milestone: milestone, profileId: child.id!));

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('not a medical opinion'), findsOneWidget);
  });
}
