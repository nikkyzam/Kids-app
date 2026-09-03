import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/data/milestone_context_data.dart';
import 'package:playsteps/data/milestones_data.dart';
import 'package:playsteps/data/red_flags_data.dart';

void main() {
  group('coverage', () {
    test('every milestone has context, so none ships as a bare checkbox', () {
      final missing = MilestonesData.all
          .where((m) => MilestoneContext.forMilestone(m) == null)
          .map((m) => m.id)
          .toList();
      expect(missing, isEmpty,
          reason: 'milestones with no "what to look for": $missing');
    });

    test('an unknown id returns nothing rather than throwing', () {
      expect(MilestoneContext.forId('m_not_a_milestone'), isNull);
    });
  });

  group('what to look for', () {
    test('is a real sentence, not a restatement of the description', () {
      for (final milestone in MilestonesData.all) {
        final ctx = MilestoneContext.forMilestone(milestone)!;
        expect(ctx.whatToLookFor.length, greaterThan(40),
            reason: '${milestone.id} is too short to be useful');
        expect(ctx.whatToLookFor.trim(), isNot(milestone.description),
            reason: '${milestone.id} just repeats the description');
      }
    });
  });

  group('when to talk to your pediatrician', () {
    test('never tells a parent something is wrong', () {
      // The note exists to say "mention it". Anything stronger would be a
      // diagnosis, which is explicitly out of scope for this app.
      const forbidden = [
        'delay',
        'delayed',
        'abnormal',
        'disorder',
        'diagnos',
        'behind',
        'should already',
        'concerning',
        'worry',
        'urgent',
        'immediately',
      ];
      for (final milestone in MilestonesData.all) {
        final note =
            MilestoneContext.forMilestone(milestone)!.whenToTalk.toLowerCase();
        for (final word in forbidden) {
          expect(note.contains(word), isFalse,
              reason: '${milestone.id} says "$word" in its doctor note');
        }
      }
    });

    test('names the CDC age for a milestone the CDC flags', () {
      final flagged = RedFlagsData.all.first;
      final ctx = MilestoneContext.forId(flagged.milestoneId)!;

      expect(ctx.isCdcActEarly, isTrue);
      expect(ctx.whenToTalk, contains('${flagged.redFlagAgeMonths} months'));
    });

    test('falls back to the wide-ranges note otherwise', () {
      final flaggedIds = RedFlagsData.all.map((f) => f.milestoneId).toSet();
      final unflagged =
          MilestonesData.all.firstWhere((m) => !flaggedIds.contains(m.id));
      final ctx = MilestoneContext.forMilestone(unflagged)!;

      expect(ctx.isCdcActEarly, isFalse);
      expect(ctx.whenToTalk, contains('Ranges here are wide'));
    });

    test('agrees with the red-flag table on every milestone', () {
      final flaggedIds = RedFlagsData.all.map((f) => f.milestoneId).toSet();
      for (final milestone in MilestonesData.all) {
        final ctx = MilestoneContext.forMilestone(milestone)!;
        expect(ctx.isCdcActEarly, flaggedIds.contains(milestone.id),
            reason: '${milestone.id} disagrees with RedFlagsData');
      }
    });
  });
}
