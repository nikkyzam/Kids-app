import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/data/activities_data.dart';
import 'package:playsteps/models/activity.dart';

void main() {
  group('ActivitiesData.all', () {
    test('contains activities', () {
      expect(ActivitiesData.all, isNotEmpty);
    });

    test('all activities have non-empty titles', () {
      for (final act in ActivitiesData.all) {
        expect(act.title, isNotEmpty, reason: 'Activity ${act.id} has empty title');
      }
    });

    test('all activities have at least one material', () {
      for (final act in ActivitiesData.all) {
        expect(act.materials, isNotEmpty, reason: 'Activity ${act.id} has no materials');
      }
    });

    test('all activities have at most 3 instruction steps', () {
      for (final act in ActivitiesData.all) {
        expect(act.instructions.length, lessThanOrEqualTo(3),
            reason: 'Activity ${act.id} exceeds 3-step limit');
      }
    });

    test('all activities have at least 1 instruction step', () {
      for (final act in ActivitiesData.all) {
        expect(act.instructions, isNotEmpty, reason: 'Activity ${act.id} has no steps');
      }
    });

    test('all activity IDs are unique', () {
      final ids = ActivitiesData.all.map((a) => a.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('all activities have positive duration', () {
      for (final act in ActivitiesData.all) {
        expect(act.durationMins, greaterThan(0));
      }
    });

    test('free tier activities exist (ageBandMinWeeks == 0)', () {
      final free = ActivitiesData.all.where((a) => a.isInFreeTier);
      expect(free, isNotEmpty);
    });

    test('premium activities exist (ageBandMinWeeks >= 4)', () {
      final premium = ActivitiesData.all.where((a) => !a.isInFreeTier);
      expect(premium, isNotEmpty);
    });

    test('all skill categories are represented', () {
      final categories = ActivitiesData.all.map((a) => a.skillCategory).toSet();
      for (final cat in SkillCategory.values) {
        expect(categories, contains(cat), reason: 'No activity for ${cat.label}');
      }
    });
  });

  group('ActivitiesData.forAgeBandWeeks', () {
    test('returns activities for week 0', () {
      final results = ActivitiesData.forAgeBandWeeks(0);
      expect(results, isNotEmpty);
      expect(results.every((a) => a.ageBandMinWeeks <= 0 && 0 < a.ageBandMaxWeeks), isTrue);
    });

    test('returns activities for week 8', () {
      final results = ActivitiesData.forAgeBandWeeks(8);
      expect(results, isNotEmpty);
      expect(results.every((a) => a.ageBandMinWeeks <= 8 && 8 < a.ageBandMaxWeeks), isTrue);
    });

    test('returns empty list for out-of-range age', () {
      // No activities go beyond 156 weeks
      final results = ActivitiesData.forAgeBandWeeks(200);
      expect(results, isEmpty);
    });

    test('does not mix activities from different age bands', () {
      final results = ActivitiesData.forAgeBandWeeks(4);
      for (final act in results) {
        expect(act.ageBandMinWeeks <= 4, isTrue);
        expect(4 < act.ageBandMaxWeeks, isTrue);
      }
    });
  });

  group('ActivitiesData.todayActivity', () {
    test('returns non-null for week 0 (newborn)', () {
      expect(ActivitiesData.todayActivity(0), isNotNull);
    });

    test('returns non-null for week 24', () {
      expect(ActivitiesData.todayActivity(24), isNotNull);
    });

    test('returns non-null for week 100', () {
      expect(ActivitiesData.todayActivity(100), isNotNull);
    });

    test('returns null for age with no activities', () {
      expect(ActivitiesData.todayActivity(200), isNull);
    });

    test('returned activity is within the correct age band', () {
      const ageInWeeks = 12;
      final activity = ActivitiesData.todayActivity(ageInWeeks);
      expect(activity, isNotNull);
      expect(activity!.ageBandMinWeeks <= ageInWeeks, isTrue);
      expect(ageInWeeks < activity.ageBandMaxWeeks, isTrue);
    });

    test('deterministic — same result on same day for same age', () {
      final a = ActivitiesData.todayActivity(0);
      final b = ActivitiesData.todayActivity(0);
      expect(a?.id, b?.id);
    });
  });
}
