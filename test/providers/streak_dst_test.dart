import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/child_profile.dart';

/// Streaks are counted in calendar days, but a `Duration` is always exactly
/// 24 hours. On the days around a daylight-saving transition those two things
/// disagree, which previously broke a user's streak once a year.
///
/// These dates bracket the US spring-forward (02:00 on 8 March 2026). Run the
/// suite under `TZ=America/New_York` to exercise the transition; under UTC the
/// assertions still hold, they just do not stress DST.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Without this the helper opens a real file and rows leak between tests.
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.instance.resetForTesting();
    // Foreign keys are enforced, so rows must belong to a real child.
    // AUTOINCREMENT makes this profile id 1, which the tests below use.
    await DatabaseHelper.instance.insertProfile(ChildProfile(
      name: 'Test Child',
      dateOfBirth: DateTime(2025, 1, 1),
      createdAt: DateTime(2025, 1, 1),
    ));
  });

  Future<ActivityProvider> providerWith(List<String> dateKeys) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = ActivityProvider(prefs);
    for (final key in dateKeys) {
      await DatabaseHelper.instance.saveCompletion(
        ActivityCompletion(
          profileId: 1,
          activityId: 'act_0_1',
          dateKey: key,
          completedAt: DateTime.parse(key),
        ),
      );
    }
    await provider.loadForProfile(1, 8);
    return provider;
  }

  test('longestStreak counts consecutive days across a DST spring-forward',
      () async {
    // 7th -> 8th -> 9th March 2026: the 8th->9th gap is only 23 hours locally.
    final provider = await providerWith(
      const ['2026-03-07', '2026-03-08', '2026-03-09'],
    );

    expect(provider.longestStreak, 3,
        reason: 'a 23-hour calendar day is still one day');
  });

  test('longestStreak counts consecutive days across a DST fall-back',
      () async {
    // 1 November 2026 is 25 hours long in US timezones.
    final provider = await providerWith(
      const ['2026-10-31', '2026-11-01', '2026-11-02'],
    );

    expect(provider.longestStreak, 3,
        reason: 'a 25-hour calendar day is still one day');
  });

  test('longestStreak still breaks on a genuine gap', () async {
    final provider = await providerWith(
      const ['2026-03-07', '2026-03-08', '2026-03-12', '2026-03-13'],
    );

    expect(provider.longestStreak, 2);
  });

  test('longestStreak spans a month boundary', () async {
    final provider = await providerWith(
      const ['2026-01-30', '2026-01-31', '2026-02-01'],
    );

    expect(provider.longestStreak, 3);
  });

  test('longestStreak spans a leap day', () async {
    // 2028 is a leap year, so 28 Feb -> 29 Feb -> 1 Mar is consecutive.
    final provider = await providerWith(
      const ['2028-02-28', '2028-02-29', '2028-03-01'],
    );

    expect(provider.longestStreak, 3);
  });

  test('duplicate completions on one day do not inflate the streak', () async {
    final provider = await providerWith(
      const ['2026-05-01', '2026-05-01', '2026-05-02'],
    );

    expect(provider.longestStreak, 2);
  });
}
