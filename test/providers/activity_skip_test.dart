import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/activities_data.dart';
import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/activity_skip.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/utils/clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  late ChildProfile child;
  late ActivityProvider provider;

  setUp(() async {
    Clock.freeze(DateTime(2026, 5, 20, 10));
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.instance.resetForTesting();
    child = await DatabaseHelper.instance.insertProfile(ChildProfile(
      name: 'Emma',
      dateOfBirth: DateTime(2025, 8, 20),
      createdAt: DateTime(2025, 8, 20),
    ));
    provider = ActivityProvider(await SharedPreferences.getInstance());
    await provider.loadForProfile(child.id!, child.contentAgeBandWeeks);
  });

  tearDown(Clock.reset);

  group('dismissing an activity', () {
    test('swaps in a different activity straight away', () async {
      final original = provider.todayActivity!;

      final swapped =
          await provider.dismissTodayActivity(child.id!, SkipReason.tooHard);

      expect(swapped, isTrue);
      expect(provider.todayActivity, isNotNull);
      expect(provider.todayActivity!.id, isNot(original.id));
    });

    test('records the reason on the device', () async {
      final original = provider.todayActivity!;

      await provider.dismissTodayActivity(
          child.id!, SkipReason.materialsUnavailable);

      final stored = await DatabaseHelper.instance.getSkips(child.id!);
      expect(stored, hasLength(1));
      expect(stored.single.activityId, original.id);
      expect(stored.single.reason, SkipReason.materialsUnavailable);
    });

    test('accepts no reason at all', () async {
      await provider.dismissTodayActivity(child.id!, null);

      final stored = await DatabaseHelper.instance.getSkips(child.id!);
      expect(stored.single.reason, isNull);
    });

    test('keeps the activity out of the rotation on later days', () async {
      final original = provider.todayActivity!;
      await provider.dismissTodayActivity(child.id!, SkipReason.tooEasy);

      // Walk a full year of dates: the dismissed activity must not reappear on
      // any of them, otherwise "not for us" only ever meant "not today".
      for (int i = 1; i <= 365; i++) {
        final day = DateTime(2026, 5, 20 + i);
        final activity = ActivitiesData.activityForDate(
          day,
          child.contentAgeInWeeksOn(day),
          dismissed: provider.dismissedActivityIds,
        );
        expect(activity?.id, isNot(original.id));
      }
    });

    test('survives a reload', () async {
      final original = provider.todayActivity!;
      await provider.dismissTodayActivity(child.id!, SkipReason.tooHard);
      final replacement = provider.todayActivity!;

      await provider.loadForProfile(child.id!, child.contentAgeBandWeeks);

      expect(provider.dismissedActivityIds, contains(original.id));
      expect(provider.todayActivity!.id, replacement.id);
    });

    test('refuses to discard an activity that is already completed', () async {
      await provider.toggleCompletion(child.id!);
      final done = provider.todayActivity!;

      final swapped =
          await provider.dismissTodayActivity(child.id!, SkipReason.tooHard);

      expect(swapped, isFalse);
      expect(provider.todayActivity!.id, done.id);
      expect(await DatabaseHelper.instance.getSkips(child.id!), isEmpty);
    });
  });

  group('restoring', () {
    test('puts a single activity back', () async {
      final original = provider.todayActivity!;
      await provider.dismissTodayActivity(child.id!, SkipReason.tooHard);

      await provider.restoreActivity(child.id!, original.id);

      expect(provider.dismissedActivityIds, isEmpty);
      expect(provider.todayActivity!.id, original.id);
    });

    test('clears every dismissal for the child', () async {
      await provider.dismissTodayActivity(child.id!, SkipReason.tooHard);
      await provider.dismissTodayActivity(child.id!, SkipReason.tooEasy);
      expect(provider.dismissedActivityIds, hasLength(2));

      await provider.restoreAllActivities(child.id!);

      expect(provider.dismissedActivityIds, isEmpty);
      expect(await DatabaseHelper.instance.getSkips(child.id!), isEmpty);
    });
  });

  group('never runs out of activities', () {
    test('dismissing the whole band still offers something', () async {
      // Dismiss until nothing is left; the parent must still be shown an
      // activity rather than an empty card.
      for (int i = 0; i < 200; i++) {
        final swapped = await provider.dismissTodayActivity(child.id!, null);
        if (!swapped) break;
        if (provider.dismissedActivityIds.length >
            ActivitiesData.forAgeBandWeeks(child.contentAgeBandWeeks).length) {
          break;
        }
      }
      expect(provider.todayActivity, isNotNull);
    });
  });

  group('browsing past days', () {
    test('reports the activity actually completed on that day', () async {
      await DatabaseHelper.instance.saveCompletion(ActivityCompletion(
        profileId: child.id!,
        activityId: 'act_0_1',
        dateKey: '2026-05-10',
        completedAt: DateTime(2026, 5, 10, 9),
      ));
      await provider.loadForProfile(child.id!, child.contentAgeBandWeeks);

      final activity = provider.activityForDay(child, DateTime(2026, 5, 10));
      expect(activity?.id, 'act_0_1');
    });

    test('recomputes an untouched day from the age the child was then', () {
      // Emma was 13 weeks old on 20 November 2025, not 39 weeks as she is on
      // the frozen "today", so the day must resolve into the younger band.
      final day = DateTime(2025, 11, 20);
      final activity = provider.activityForDay(child, day);

      expect(activity, isNotNull);
      final weeksThen = child.contentAgeInWeeksOn(day);
      expect(activity!.ageBandMinWeeks, lessThanOrEqualTo(weeksThen));
      expect(activity.ageBandMaxWeeks, greaterThan(weeksThen));
    });

    test('is stable — the same day always gives the same activity', () {
      final day = DateTime(2026, 3, 3);
      final first = provider.activityForDay(child, day);
      final second = provider.activityForDay(child, day);
      expect(first?.id, second?.id);
    });
  });

  group('day-of-year is counted from the calendar', () {
    test('is 0 on 1 January and 364 on 31 December in a common year', () {
      expect(ActivitiesData.dayOfYear(DateTime(2026, 1, 1)), 0);
      expect(ActivitiesData.dayOfYear(DateTime(2026, 12, 31)), 364);
    });

    test('accounts for the leap day', () {
      expect(ActivitiesData.dayOfYear(DateTime(2024, 2, 28)), 58);
      expect(ActivitiesData.dayOfYear(DateTime(2024, 2, 29)), 59);
      expect(ActivitiesData.dayOfYear(DateTime(2024, 3, 1)), 60);
      expect(ActivitiesData.dayOfYear(DateTime(2024, 12, 31)), 365);
      // 1900 was not a leap year; 2000 was.
      expect(ActivitiesData.dayOfYear(DateTime(1900, 3, 1)), 59);
      expect(ActivitiesData.dayOfYear(DateTime(2000, 3, 1)), 60);
    });
  });
}
