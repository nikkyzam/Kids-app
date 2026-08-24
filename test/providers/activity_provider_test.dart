import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';

import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/activity.dart';
import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/services/purchase_service.dart';

String _dateKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

Future<ChildProfile> _insertTestProfile() async {
  return DatabaseHelper.instance.insertProfile(
    ChildProfile(
        name: 'Test',
        dateOfBirth: DateTime(2024, 1, 1),
        createdAt: DateTime.now()),
  );
}

Future<void> _insertCompletion(int profileId, DateTime day,
    {String activityId = 'act_0_1'}) async {
  await DatabaseHelper.instance.saveCompletion(ActivityCompletion(
    profileId: profileId,
    activityId: activityId,
    dateKey: _dateKey(day),
    completedAt: day,
  ));
}

void main() {
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

  group('ActivityProvider — initial state', () {
    test('starts with no activity and not loading', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      expect(provider.todayActivity, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isCompleted, isFalse);
      expect(provider.isPremium, isFalse);
    });

    test('currentStreak is 0 when no completions', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      expect(provider.currentStreak, 0);
    });

    test('totalCompletions is 0 when no completions', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      expect(provider.totalCompletions, 0);
    });
  });

  group('ActivityProvider — premium', () {
    test('isPremium reads false from empty prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(ActivityProvider(prefs).isPremium, isFalse);
    });

    test('isPremium reads true when saved', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});
      final prefs = await SharedPreferences.getInstance();
      expect(ActivityProvider(prefs).isPremium, isTrue);
    });

    test('grantEntitlement(premium) persists to prefs', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      await provider.grantEntitlement(Entitlement.premium);
      expect(provider.isPremium, isTrue);
      expect(prefs.getBool('is_premium'), isTrue);
    });

    test('grantEntitlement(premiumPlus) persists to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      await provider.grantEntitlement(Entitlement.premiumPlus);
      expect(provider.isPremiumPlus, isTrue);
      expect(prefs.getBool('is_premium_plus'), isTrue);
    });

    test('granting premium does not imply premiumPlus', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      await provider.grantEntitlement(Entitlement.premium);
      expect(provider.isPremium, isTrue);
      expect(provider.isPremiumPlus, isFalse);
    });

    test('activityRequiresPremium is false for free tier activity', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      const free = PlayActivity(
        id: 'f',
        ageBandMinWeeks: 0,
        ageBandMaxWeeks: 4,
        title: 'T',
        durationMins: 5,
        materials: [],
        instructions: [],
        skillTargeted: 'S',
        skillCategory: SkillCategory.sensory,
      );
      expect(provider.activityRequiresPremium(free), isFalse);
    });

    test(
        'activityRequiresPremium is true for premium activity without subscription',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      const premium = PlayActivity(
        id: 'p',
        ageBandMinWeeks: 8,
        ageBandMaxWeeks: 12,
        title: 'T',
        durationMins: 5,
        materials: [],
        instructions: [],
        skillTargeted: 'S',
        skillCategory: SkillCategory.grossMotor,
      );
      expect(provider.activityRequiresPremium(premium), isTrue);
    });

    test(
        'activityRequiresPremium is false for premium activity with subscription',
        () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      const premium = PlayActivity(
        id: 'p',
        ageBandMinWeeks: 8,
        ageBandMaxWeeks: 12,
        title: 'T',
        durationMins: 5,
        materials: [],
        instructions: [],
        skillTargeted: 'S',
        skillCategory: SkillCategory.grossMotor,
      );
      expect(provider.activityRequiresPremium(premium), isFalse);
    });
  });

  group('ActivityProvider — streak calculation', () {
    test('currentStreak is 1 for a single completion today', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      await _insertCompletion(profile.id!, DateTime.now());

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.currentStreak, 1);
    });

    test('currentStreak is 3 for 3 consecutive days ending today', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      final today = DateTime.now();
      await _insertCompletion(profile.id!, today);
      await _insertCompletion(
          profile.id!, today.subtract(const Duration(days: 1)));
      await _insertCompletion(
          profile.id!, today.subtract(const Duration(days: 2)));

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.currentStreak, 3);
    });

    test('currentStreak counts yesterday if today is not yet done', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dayBefore = DateTime.now().subtract(const Duration(days: 2));
      await _insertCompletion(profile.id!, yesterday);
      await _insertCompletion(profile.id!, dayBefore);

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.currentStreak, 2);
    });

    test('currentStreak breaks at a gap', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      final today = DateTime.now();
      await _insertCompletion(profile.id!, today);
      // Gap: skip yesterday
      await _insertCompletion(
          profile.id!, today.subtract(const Duration(days: 2)));

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.currentStreak, 1);
    });

    test('currentStreak is 0 when no completions at all', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.currentStreak, 0);
    });
  });

  group('ActivityProvider — longestStreak', () {
    test('longestStreak is 0 for no completions', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      expect(provider.longestStreak, 0);
    });

    test('longestStreak is 1 for single completion', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      await _insertCompletion(profile.id!, DateTime.now());

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.longestStreak, 1);
    });

    test('longestStreak finds the longest run among multiple runs', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      final today = DateTime.now();

      // Run of 3 (today, yesterday, day before)
      await _insertCompletion(profile.id!, today);
      await _insertCompletion(
          profile.id!, today.subtract(const Duration(days: 1)));
      await _insertCompletion(
          profile.id!, today.subtract(const Duration(days: 2)));

      // Gap of 2 days

      // Earlier run of 2
      await _insertCompletion(
          profile.id!, today.subtract(const Duration(days: 5)));
      await _insertCompletion(
          profile.id!, today.subtract(const Duration(days: 6)));

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.longestStreak, 3);
    });
  });

  group('ActivityProvider — completedOnDay', () {
    test('returns true for a day with completion', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      final today = DateTime.now();
      await _insertCompletion(profile.id!, today);

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.completedOnDay(today), isTrue);
    });

    test('returns false for a day without completion', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      await _insertCompletion(profile.id!, DateTime.now());

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(provider.completedOnDay(twoDaysAgo), isFalse);
    });
  });

  group('ActivityProvider — skillCoverage', () {
    test('empty when no completions', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);
      expect(provider.skillCoverage, isEmpty);
    });

    test('counts skill category from known activity id', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      // act_0_3 is SkillCategory.grossMotor (Tummy Time on Chest)
      await _insertCompletion(profile.id!, DateTime.now(),
          activityId: 'act_0_3');
      await _insertCompletion(
          profile.id!, DateTime.now().subtract(const Duration(days: 1)),
          activityId: 'act_0_3');

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.skillCoverage[SkillCategory.grossMotor], 2);
    });

    test('ignores completions with unknown activity ids', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();
      await _insertCompletion(profile.id!, DateTime.now(),
          activityId: 'nonexistent_id');

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.skillCoverage, isEmpty);
    });
  });

  group('ActivityProvider — toggleCompletion', () {
    test('marks today as completed', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      expect(provider.isCompleted, isFalse);
      await provider.toggleCompletion(profile.id!);
      expect(provider.isCompleted, isTrue);
      expect(provider.totalCompletions, 1);
    });

    test('toggling twice marks as not completed', () async {
      final prefs = await SharedPreferences.getInstance();
      final profile = await _insertTestProfile();

      final provider = ActivityProvider(prefs);
      await provider.loadForProfile(profile.id!, 0);

      await provider.toggleCompletion(profile.id!);
      expect(provider.isCompleted, isTrue);
      await provider.toggleCompletion(profile.id!);
      expect(provider.isCompleted, isFalse);
      expect(provider.totalCompletions, 0);
    });
  });
}
