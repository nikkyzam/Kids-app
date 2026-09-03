import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/models/milestone_achievement.dart';
import 'package:playsteps/models/photo_memory.dart';
import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/providers/auth_provider.dart';
import 'package:playsteps/providers/badge_provider.dart';
import 'package:playsteps/providers/milestone_provider.dart';
import 'package:playsteps/providers/profile_provider.dart';
import 'package:playsteps/services/trial_service.dart';
import 'package:playsteps/theme/app_theme.dart';
import 'package:playsteps/utils/clock.dart';

/// Shared setup for screen tests: an in-memory database, mocked preferences,
/// and the provider graph every screen expects.
class Harness {
  Harness._();

  static late ProfileProvider profiles;
  static late ActivityProvider activities;
  static late MilestoneProvider milestones;
  static late BadgeProvider badges;
  static late AuthProvider auth;

  /// Call once per test file, inside `setUpAll`.
  static void initOnce() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  }

  /// Call in `setUp`. Returns the seeded child (id 1).
  ///
  /// The clock is frozen so screens that render dates, ages or streaks produce
  /// the same output on every run.
  static Future<ChildProfile> reset({
    DateTime? now,
    bool premium = false,
    bool premiumPlus = false,
    DateTime? trialStartedAt,
  }) async {
    Clock.freeze(now ?? DateTime(2026, 5, 20, 10, 0));
    SharedPreferences.setMockInitialValues({
      if (premium) 'is_premium': true,
      if (premiumPlus) 'is_premium_plus': true,
      // Absent by default, so tests see the post-trial free tier — the state
      // the paywall and lock screens exist for.
      if (trialStartedAt != null)
        TrialService.firstLaunchKey: trialStartedAt.toIso8601String(),
    });
    await DatabaseHelper.instance.resetForTesting();

    final child = await DatabaseHelper.instance.insertProfile(
      ChildProfile(
        name: 'Emma',
        dateOfBirth: DateTime(2025, 8, 20),
        createdAt: DateTime(2025, 8, 20),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    profiles = ProfileProvider(prefs);
    activities = ActivityProvider(prefs);
    milestones = MilestoneProvider();
    badges = BadgeProvider();
    auth = AuthProvider();

    await profiles.loadProfiles();
    await activities.loadForProfile(child.id!, child.contentAgeBandWeeks);
    await milestones.loadForProfile(child.id!);
    await badges.loadBadges(child.id!);

    return child;
  }

  /// Reloads every provider after seeding data directly into the database.
  static Future<void> reload(ChildProfile child) async {
    await profiles.loadProfiles();
    await activities.loadForProfile(child.id!, child.contentAgeBandWeeks);
    await milestones.loadForProfile(child.id!);
    await badges.loadBadges(child.id!);
  }

  static void tearDownClock() => Clock.reset();

  /// Lets a chain of awaited database and preference writes — started by a tap
  /// rather than by `initState` — actually run to completion.
  ///
  /// `testWidgets` runs in a fake-async zone. Real I/O completes only while
  /// [WidgetTester.runAsync] turns the real event loop, but the continuation it
  /// schedules lands on the fake zone's queue and runs only on the next
  /// [WidgetTester.pump]. One of each therefore advances one `await`, so a
  /// multi-step operation needs them interleaved.
  static Future<void> settleAsync(WidgetTester tester,
      {int cycles = 30}) async {
    for (int i = 0; i < cycles; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  /// Wraps [child] in the provider graph and the real app theme.
  static Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profiles),
        ChangeNotifierProvider<ActivityProvider>.value(value: activities),
        ChangeNotifierProvider<MilestoneProvider>.value(value: milestones),
        ChangeNotifierProvider<BadgeProvider>.value(value: badges),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: child,
      ),
    );
  }

  /// Pumps [screen] on a tall surface so long pages lay out without
  /// overflowing, then settles animations.
  static Future<void> pump(WidgetTester tester, Widget screen,
      {Size size = const Size(420, 1400)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(screen));
    await tester.pump();

    // Most screens kick off a database read in initState. `testWidgets` runs
    // in a fake-async zone where that real I/O never completes, so the screen
    // would stay on its loading spinner forever. [settleAsync] steps outside
    // the fake zone and back, once per awaited step, so a screen that reads
    // several tables before it can render still gets there.
    await settleAsync(tester, cycles: 8);
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// [reset] for use from inside a `testWidgets` body, where a bare call would
  /// hang on the fake-async zone. Prefer plain [reset] in `setUp`; use this
  /// when a single test needs different starting conditions.
  static Future<ChildProfile> resetInTest(
    WidgetTester tester, {
    DateTime? now,
    bool premium = false,
    bool premiumPlus = false,
    DateTime? trialStartedAt,
  }) async {
    late ChildProfile child;
    await tester.runAsync(() async {
      child = await reset(
          now: now,
          premium: premium,
          premiumPlus: premiumPlus,
          trialStartedAt: trialStartedAt);
    });
    return child;
  }

  /// Runs real asynchronous work (database I/O) from inside a `testWidgets`
  /// body.
  ///
  /// `testWidgets` executes in a fake-async zone where real I/O never
  /// completes, so seeding the database directly inside a test hangs it
  /// forever rather than failing. Seed in `setUp`, or wrap the work in this.
  static Future<void> realAsync(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    await tester.runAsync(body);
  }

  // --- seeding helpers ------------------------------------------------------

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> seedCompletions(int profileId, int count,
      {DateTime? endingOn, String activityId = 'act_0_1'}) async {
    final last = endingOn ?? Clock.today();
    for (var i = 0; i < count; i++) {
      final day = DateTime(last.year, last.month, last.day - i);
      await DatabaseHelper.instance.saveCompletion(
        ActivityCompletion(
          profileId: profileId,
          activityId: activityId,
          dateKey: dateKey(day),
          completedAt: day,
        ),
      );
    }
  }

  static Future<void> seedAchievements(
      int profileId, List<String> milestoneIds) async {
    for (final id in milestoneIds) {
      await DatabaseHelper.instance.saveAchievement(
        MilestoneAchievement(
          profileId: profileId,
          milestoneId: id,
          achievedDate: Clock.now(),
        ),
      );
    }
  }

  static Future<void> seedGrowth(
    int profileId,
    GrowthMetric metric,
    List<double> values, {
    DateTime? startingOn,
  }) async {
    final start = startingOn ?? DateTime(2026, 1, 1);
    for (var i = 0; i < values.length; i++) {
      await DatabaseHelper.instance.saveGrowthMeasurement(
        GrowthMeasurement(
          profileId: profileId,
          metric: metric,
          value: values[i],
          measuredOn: DateTime(start.year, start.month + i, start.day)
              .toIso8601String(),
        ),
      );
    }
  }

  static Future<void> seedPhotos(int profileId, int count) async {
    for (var i = 0; i < count; i++) {
      await DatabaseHelper.instance.savePhoto(
        PhotoMemory(
          profileId: profileId,
          referenceType: 'activity',
          referenceId: 'ref_$i',
          imagePath: '/tmp/photo_$i.jpg',
          caption: 'Memory $i',
          capturedAt: DateTime(2026, 5, 20 - i).toIso8601String(),
        ),
      );
    }
  }

  static Future<void> seedBadges(int profileId, List<String> ids) async {
    for (final id in ids) {
      await DatabaseHelper.instance.saveBadge(profileId, id);
    }
  }
}
