import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/data/activities_data.dart';
import 'package:playsteps/data/activities_draft_data.dart';
import 'package:playsteps/models/activity.dart';

void main() {
  group('ActivitiesData.all', () {
    test('contains activities', () {
      expect(ActivitiesData.all, isNotEmpty);
    });

    test('all activities have non-empty titles', () {
      for (final act in ActivitiesData.all) {
        expect(act.title, isNotEmpty,
            reason: 'Activity ${act.id} has empty title');
      }
    });

    test('all activities have at least one material', () {
      for (final act in ActivitiesData.all) {
        expect(act.materials, isNotEmpty,
            reason: 'Activity ${act.id} has no materials');
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
        expect(act.instructions, isNotEmpty,
            reason: 'Activity ${act.id} has no steps');
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
        expect(categories, contains(cat),
            reason: 'No activity for ${cat.label}');
      }
    });
  });

  group('ActivitiesData.forAgeBandWeeks', () {
    test('returns activities for week 0', () {
      final results = ActivitiesData.forAgeBandWeeks(0);
      expect(results, isNotEmpty);
      expect(
          results.every((a) => a.ageBandMinWeeks <= 0 && 0 < a.ageBandMaxWeeks),
          isTrue);
    });

    test('returns activities for week 8', () {
      final results = ActivitiesData.forAgeBandWeeks(8);
      expect(results, isNotEmpty);
      expect(
          results.every((a) => a.ageBandMinWeeks <= 8 && 8 < a.ageBandMaxWeeks),
          isTrue);
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

  group('daily rotation depth', () {
    // todayActivity picks band[dayOfYear % band.length], so a band holding N
    // activities repeats every N days. Four per band meant a parent saw the
    // same four activities all month.
    test('every age band offers at least ten activities', () {
      final bands = <String, int>{};
      for (final a in ActivitiesData.all) {
        final key = '${a.ageBandMinWeeks}-${a.ageBandMaxWeeks}';
        bands[key] = (bands[key] ?? 0) + 1;
      }

      expect(bands, isNotEmpty);
      bands.forEach((band, count) {
        expect(count, greaterThanOrEqualTo(10),
            reason: 'band $band has only $count activities, so the daily '
                'activity repeats every $count days');
      });
    });

    test('activity ids are unique', () {
      final ids = ActivitiesData.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'a duplicate id would make one activity unreachable');
    });

    test('every band is covered with no gaps from 0 to 156 weeks', () {
      for (var week = 0; week < 156; week += 1) {
        expect(ActivitiesData.forAgeBandWeeks(week), isNotEmpty,
            reason: 'no activity available at $week weeks');
      }
    });

    test('drafted activities are separable from reviewed ones', () {
      // The draft batch has not been professionally reviewed; keeping the two
      // lists distinct is what makes it removable.
      expect(ActivitiesData.reviewed, isNotEmpty);
      expect(
        ActivitiesData.all.length,
        ActivitiesData.reviewed.length +
            ActivitiesDraftData.pendingReview.length,
      );
    });
  });
}
