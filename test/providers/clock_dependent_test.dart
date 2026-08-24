import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/utils/clock.dart';

/// Behaviour that depends on what time it is. Before [Clock] these could only
/// be exercised at whatever moment the suite happened to run, so the
/// interesting cases — midnight rollover, a birthday, 29 February — were
/// effectively untestable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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

  tearDown(Clock.reset);

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

  group('currentStreak around the day boundary', () {
    test('counts a run ending today', () async {
      Clock.freeze(DateTime(2026, 5, 20, 9, 0));
      final p = await providerWith(
        const ['2026-05-18', '2026-05-19', '2026-05-20'],
      );
      expect(p.currentStreak, 3);
    });

    test('survives today not being done yet', () async {
      // 00:01 — the user has not played today, but yesterday's run stands.
      Clock.freeze(DateTime(2026, 5, 20, 0, 1));
      final p = await providerWith(const ['2026-05-18', '2026-05-19']);
      expect(p.currentStreak, 2);
    });

    test('one second before midnight still counts today', () async {
      Clock.freeze(DateTime(2026, 5, 20, 23, 59, 59));
      final p = await providerWith(const ['2026-05-19', '2026-05-20']);
      expect(p.currentStreak, 2);
    });

    test('breaks once a full day has been missed', () async {
      // Nothing on the 19th or 20th, so the run ended on the 18th.
      Clock.freeze(DateTime(2026, 5, 20, 12, 0));
      final p = await providerWith(const ['2026-05-17', '2026-05-18']);
      expect(p.currentStreak, 0);
    });

    test('counts across a DST spring-forward', () async {
      Clock.freeze(DateTime(2026, 3, 9, 10, 0));
      final p = await providerWith(
        const ['2026-03-07', '2026-03-08', '2026-03-09'],
      );
      expect(p.currentStreak, 3);
    });

    test('counts across a month and year boundary', () async {
      Clock.freeze(DateTime(2027, 1, 1, 8, 0));
      final p = await providerWith(
        const ['2026-12-30', '2026-12-31', '2027-01-01'],
      );
      expect(p.currentStreak, 3);
    });
  });

  group('ChildProfile age', () {
    ChildProfile profileBornOn(DateTime dob) => ChildProfile(
          name: 'Test',
          dateOfBirth: dob,
          createdAt: dob,
        );

    test('is zero on the day of birth', () {
      Clock.freeze(DateTime(2026, 5, 20, 18, 0));
      final p = profileBornOn(DateTime(2026, 5, 20, 6, 0));
      expect(p.ageInDays, 0);
      expect(p.ageInWeeks, 0);
      expect(p.ageInMonths, 0);
    });

    test('does not tick over the month until the day before the birthday', () {
      final p = profileBornOn(DateTime(2026, 1, 15));

      Clock.freeze(DateTime(2026, 2, 14, 12, 0));
      expect(p.ageInMonths, 0, reason: 'one day short of one month');

      Clock.freeze(DateTime(2026, 2, 15, 12, 0));
      expect(p.ageInMonths, 1, reason: 'exactly one month');
    });

    test('handles a 31st-of-the-month birth date in a short month', () {
      // Born 31 Jan; February has no 31st.
      final p = profileBornOn(DateTime(2026, 1, 31));

      Clock.freeze(DateTime(2026, 2, 28, 12, 0));
      expect(p.ageInMonths, 0, reason: '28 Feb is not yet a full month');

      Clock.freeze(DateTime(2026, 3, 31, 12, 0));
      expect(p.ageInMonths, 2);
    });

    test('handles a 29 February birth date in a non-leap year', () {
      final p = profileBornOn(DateTime(2028, 2, 29));

      Clock.freeze(DateTime(2029, 2, 28, 12, 0));
      expect(p.ageInMonths, 11, reason: 'not yet a year in a non-leap year');

      Clock.freeze(DateTime(2029, 3, 1, 12, 0));
      expect(p.ageInMonths, 12);
    });

    test('clamps a future date of birth instead of going negative', () {
      // The picker prevents this, but a restored backup or a synced record
      // from a device with a wrong clock can carry one.
      Clock.freeze(DateTime(2026, 5, 20));
      final p = profileBornOn(DateTime(2026, 8, 1));

      expect(p.ageInMonths, greaterThanOrEqualTo(0));
      expect(p.ageBandWeeks, greaterThanOrEqualTo(0),
          reason: 'a negative age band would index activities out of range');
      expect(p.displayAge, isNot(startsWith('-')),
          reason: 'the UI must never show a negative age');
      expect(p.displayAge, '0 weeks');
    });
  });
}
