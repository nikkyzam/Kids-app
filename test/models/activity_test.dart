import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/models/activity.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/milestone.dart';
import 'package:playsteps/models/milestone_achievement.dart';

void main() {
  group('SkillCategory.label', () {
    test('every category has a non-empty label', () {
      for (final cat in SkillCategory.values) {
        expect(cat.label, isNotEmpty);
      }
    });

    test('labels are human-readable strings', () {
      expect(SkillCategory.grossMotor.label, 'Gross Motor');
      expect(SkillCategory.fineMotor.label, 'Fine Motor');
      expect(SkillCategory.language.label, 'Language');
      expect(SkillCategory.cognitive.label, 'Cognitive');
      expect(SkillCategory.socialEmotional.label, 'Social & Emotional');
      expect(SkillCategory.sensory.label, 'Sensory');
    });
  });

  group('PlayActivity.isInFreeTier', () {
    test('true when ageBandMinWeeks is 0', () {
      const act = PlayActivity(
        id: 'a',
        ageBandMinWeeks: 0,
        ageBandMaxWeeks: 4,
        title: 'T',
        durationMins: 5,
        materials: [],
        instructions: [],
        skillTargeted: 'S',
        skillCategory: SkillCategory.sensory,
      );
      expect(act.isInFreeTier, isTrue);
    });

    test('true when ageBandMinWeeks is 1', () {
      const act = PlayActivity(
        id: 'a',
        ageBandMinWeeks: 1,
        ageBandMaxWeeks: 4,
        title: 'T',
        durationMins: 5,
        materials: [],
        instructions: [],
        skillTargeted: 'S',
        skillCategory: SkillCategory.sensory,
      );
      expect(act.isInFreeTier, isTrue);
    });

    test('false when ageBandMinWeeks is 4', () {
      const act = PlayActivity(
        id: 'b',
        ageBandMinWeeks: 4,
        ageBandMaxWeeks: 8,
        title: 'T',
        durationMins: 5,
        materials: [],
        instructions: [],
        skillTargeted: 'S',
        skillCategory: SkillCategory.grossMotor,
      );
      expect(act.isInFreeTier, isFalse);
    });

    test('false for premium age bands', () {
      const act = PlayActivity(
        id: 'c',
        ageBandMinWeeks: 48,
        ageBandMaxWeeks: 65,
        title: 'T',
        durationMins: 5,
        materials: [],
        instructions: [],
        skillTargeted: 'S',
        skillCategory: SkillCategory.cognitive,
      );
      expect(act.isInFreeTier, isFalse);
    });
  });

  group('ActivityCompletion serialization', () {
    test('toMap/fromMap roundtrip', () {
      final now = DateTime(2024, 5, 10, 12, 0);
      final original = ActivityCompletion(
        id: 7,
        profileId: 1,
        activityId: 'act_0_1',
        dateKey: '2024-05-10',
        completedAt: now,
      );
      final restored = ActivityCompletion.fromMap(original.toMap());
      expect(restored.id, 7);
      expect(restored.profileId, 1);
      expect(restored.activityId, 'act_0_1');
      expect(restored.dateKey, '2024-05-10');
      expect(restored.completedAt.toIso8601String(), now.toIso8601String());
    });
  });

  group('MilestoneDomain.label', () {
    test('every domain has a non-empty label', () {
      for (final d in MilestoneDomain.values) {
        expect(d.label, isNotEmpty);
      }
    });

    test('labels are correct', () {
      expect(MilestoneDomain.grossMotor.label, 'Gross Motor');
      expect(MilestoneDomain.fineMotor.label, 'Fine Motor');
      expect(MilestoneDomain.language.label, 'Language');
      expect(MilestoneDomain.cognitive.label, 'Cognitive');
      expect(MilestoneDomain.socialEmotional.label, 'Social & Emotional');
    });
  });

  group('MilestoneAchievement serialization', () {
    test('toMap/fromMap roundtrip with notes', () {
      final date = DateTime(2024, 4, 20);
      final original = MilestoneAchievement(
        id: 3,
        profileId: 1,
        milestoneId: 'm_2_gm_1',
        achievedDate: date,
        notes: 'First smile today!',
      );
      final restored = MilestoneAchievement.fromMap(original.toMap());
      expect(restored.id, 3);
      expect(restored.milestoneId, 'm_2_gm_1');
      expect(restored.notes, 'First smile today!');
      expect(restored.achievedDate.toIso8601String(), date.toIso8601String());
    });

    test('toMap/fromMap roundtrip without notes', () {
      final original = MilestoneAchievement(
        profileId: 1,
        milestoneId: 'm_4_la_1',
        achievedDate: DateTime(2024, 5, 1),
      );
      final restored = MilestoneAchievement.fromMap(original.toMap());
      expect(restored.notes, isNull);
    });

    test('copyWith updates notes', () {
      final original = MilestoneAchievement(
        profileId: 1,
        milestoneId: 'm_6_gm_1',
        achievedDate: DateTime.now(),
        notes: 'Old note',
      );
      final updated = original.copyWith(notes: 'New note');
      expect(updated.notes, 'New note');
      expect(updated.milestoneId, original.milestoneId);
    });
  });
}
