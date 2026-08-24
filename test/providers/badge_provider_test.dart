import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/badges_data.dart';
import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/providers/badge_provider.dart';
import 'package:playsteps/providers/milestone_provider.dart';
import 'package:playsteps/utils/clock.dart';

const _profileId = 1;

/// Seeds [count] completions on consecutive days ending on [lastDay].
Future<void> _seedRun(DateTime lastDay, int count,
    {String activityId = 'act_0_1'}) async {
  for (var i = 0; i < count; i++) {
    final day = DateTime(lastDay.year, lastDay.month, lastDay.day - i);
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    await DatabaseHelper.instance.saveCompletion(
      ActivityCompletion(
        profileId: _profileId,
        activityId: activityId,
        dateKey: key,
        completedAt: day,
      ),
    );
  }
}

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

  Future<(BadgeProvider, ActivityProvider, MilestoneProvider)> build() async {
    final prefs = await SharedPreferences.getInstance();
    final ap = ActivityProvider(prefs);
    final mp = MilestoneProvider();
    final bp = BadgeProvider();
    await ap.loadForProfile(_profileId, 8);
    await mp.loadForProfile(_profileId);
    await bp.loadBadges(_profileId);
    return (bp, ap, mp);
  }

  group('initial state', () {
    test('nothing is unlocked and the total matches the catalogue', () async {
      final (bp, _, _) = await build();
      expect(bp.unlockedCount, 0);
      expect(bp.totalCount, BadgesData.all.length);
      expect(bp.isUnlocked('first_step'), isFalse);
    });

    test('every badge id in the catalogue is unique', () {
      final ids = BadgesData.all.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'a duplicate id would make one badge unreachable');
    });

    test('every id the provider can unlock exists in the catalogue', () {
      // These are the literals used in checkAndUnlock; a typo would silently
      // never award the badge.
      const awarded = [
        'first_step',
        'week_warrior',
        'monthly_marvel',
        'century',
        'all_skills',
        'milestone_first',
        'milestone_25',
        'perfect_week',
        'gross_motor_10',
        'language_10',
        'cognitive_10',
        'social_10',
        'sensory_10',
        'fine_motor_10',
      ];
      for (final id in awarded) {
        expect(BadgesData.findById(id), isNotNull, reason: 'unknown id: $id');
      }
    });
  });

  group('threshold badges', () {
    test('a single completion earns first_step', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 1);
      final (bp, ap, mp) = await build();

      final newly =
          await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(newly.map((b) => b.id), contains('first_step'));
      expect(bp.isUnlocked('first_step'), isTrue);
    });

    test('six days is not yet a week_warrior', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 6);
      final (bp, ap, mp) = await build();

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('week_warrior'), isFalse,
          reason: 'the boundary is 7, not 6');
    });

    test('seven days earns week_warrior', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 7);
      final (bp, ap, mp) = await build();

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('week_warrior'), isTrue);
      expect(bp.isUnlocked('monthly_marvel'), isFalse);
    });

    test('thirty days earns both streak badges at once', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 30);
      final (bp, ap, mp) = await build();

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('week_warrior'), isTrue);
      expect(bp.isUnlocked('monthly_marvel'), isTrue);
    });

    test('one hundred completions earns century', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 100);
      final (bp, ap, mp) = await build();

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('century'), isTrue);
    });
  });

  group('idempotence', () {
    test('a second check awards nothing new', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 7);
      final (bp, ap, mp) = await build();

      final first =
          await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);
      expect(first, isNotEmpty);

      final second =
          await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);
      expect(second, isEmpty,
          reason: 're-awarding would re-show the unlock dialog every launch');
      expect(bp.unlockedCount, first.length);
    });

    test('unlocks survive a reload from the database', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 1);
      final (bp, ap, mp) = await build();
      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      final reloaded = BadgeProvider();
      await reloaded.loadBadges(_profileId);

      expect(reloaded.isUnlocked('first_step'), isTrue);
    });

    test('badges are scoped per child', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 1);
      final (bp, ap, mp) = await build();
      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      final sibling = BadgeProvider();
      await sibling.loadBadges(2);

      expect(sibling.unlockedCount, 0,
          reason: 'one child earning a badge must not award it to another');
    });

    test('notifies only when something is actually unlocked', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      await _seedRun(DateTime(2026, 5, 20), 1);
      final (bp, ap, mp) = await build();

      var notifications = 0;
      bp.addListener(() => notifications++);

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);
      expect(notifications, 1);

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);
      expect(notifications, 1, reason: 'no new badge, no notification');
    });
  });

  group('perfect_week', () {
    test('unlocks when the whole Mon-Sun week is complete', () async {
      // Sunday 24 May 2026; the week runs Mon 18th to Sun 24th.
      Clock.freeze(DateTime(2026, 5, 24, 20));
      await _seedRun(DateTime(2026, 5, 24), 7);
      final (bp, ap, mp) = await build();

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('perfect_week'), isTrue);
    });

    test('does not unlock with a gap in the week', () async {
      Clock.freeze(DateTime(2026, 5, 24, 20));
      // Everything except Wednesday the 20th.
      for (final day in [18, 19, 21, 22, 23, 24]) {
        await _seedRun(DateTime(2026, 5, day), 1);
      }
      final (bp, ap, mp) = await build();

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('perfect_week'), isFalse);
    });

    test('unlocks across a daylight-saving transition', () async {
      // US spring-forward is 08 March 2026 (a Sunday), so the week
      // Mon 09 - Sun 15 March follows it and Mon 02 - Sun 08 contains it.
      Clock.freeze(DateTime(2026, 3, 8, 20));
      await _seedRun(DateTime(2026, 3, 8), 7);
      final (bp, ap, mp) = await build();

      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('perfect_week'), isTrue,
          reason: 'a 23-hour day is still a day of the week');
    });
  });

  group('milestone badges', () {
    test('one achievement earns milestone_first', () async {
      Clock.freeze(DateTime(2026, 5, 20, 12));
      final (bp, ap, mp) = await build();

      await mp.toggleMilestone(_profileId, 'm_0_1');
      await bp.checkAndUnlock(profileId: _profileId, ap: ap, mp: mp);

      expect(bp.isUnlocked('milestone_first'), isTrue);
      expect(bp.isUnlocked('milestone_25'), isFalse);
    });
  });
}
