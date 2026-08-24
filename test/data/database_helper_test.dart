import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/models/milestone_achievement.dart';
import 'package:playsteps/models/photo_memory.dart';

ChildProfile _profile(String name) => ChildProfile(
      name: name,
      dateOfBirth: DateTime(2025, 1, 1),
      createdAt: DateTime(2025, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async => DatabaseHelper.instance.resetForTesting());

  final db = DatabaseHelper.instance;

  group('profiles', () {
    test('insert returns the row with its assigned id', () async {
      final saved = await db.insertProfile(_profile('Emma'));
      expect(saved.id, isNotNull);
      expect(saved.name, 'Emma');
    });

    test('insert assigns a uuid for sync', () async {
      final saved = await db.insertProfile(_profile('Emma'));
      expect(saved.uuid, isNotNull);
      expect(saved.uuid, isNotEmpty);
    });

    test('two profiles get distinct ids and uuids', () async {
      final a = await db.insertProfile(_profile('A'));
      final b = await db.insertProfile(_profile('B'));
      expect(a.id, isNot(b.id));
      expect(a.uuid, isNot(b.uuid));
    });

    test('update persists a changed name', () async {
      final saved = await db.insertProfile(_profile('Old'));
      await db.updateProfile(saved.copyWith(name: 'New'));

      final all = await db.getProfiles();
      expect(all.single.name, 'New');
    });

    test('a name with quotes and emoji round-trips intact', () async {
      const tricky = "Sam's 🐛 \"Bug\"";
      final saved = await db.insertProfile(ChildProfile(
        name: tricky,
        dateOfBirth: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
      ));

      final all = await db.getProfiles();
      expect(all.single.name, tricky);
      expect(saved.name, tricky);
    });

    test('deleting a profile removes it', () async {
      final saved = await db.insertProfile(_profile('Gone'));
      await db.deleteProfile(saved.id!);
      expect(await db.getProfiles(), isEmpty);
    });
  });

  group('deleting a child removes their data', () {
    // The schema declares ON DELETE CASCADE, but SQLite only honours foreign
    // keys when `PRAGMA foreign_keys = ON` is set on the connection. Without
    // it a deleted child's records linger: the parent believes the data is
    // gone, and sync would keep pushing the orphans.
    Future<int> countIn(String table, int profileId) async {
      final raw = await db.database;
      final rows = await raw
          .query(table, where: 'profile_id = ?', whereArgs: [profileId]);
      return rows.length;
    }

    late ChildProfile child;

    setUp(() async {
      child = await db.insertProfile(_profile('Temp'));
      await db.saveCompletion(ActivityCompletion(
        profileId: child.id!,
        activityId: 'act_0_1',
        dateKey: '2026-05-20',
        completedAt: DateTime(2026, 5, 20),
      ));
      await db.saveAchievement(MilestoneAchievement(
        profileId: child.id!,
        milestoneId: 'm_0_1',
        achievedDate: DateTime(2026, 5, 20),
      ));
      await db.saveBadge(child.id!, 'first_step');
      await db.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.weight,
        value: 7.2,
        measuredOn: DateTime(2026, 5, 20).toIso8601String(),
      ));
      await db.savePhoto(PhotoMemory(
        profileId: child.id!,
        referenceType: 'activity',
        referenceId: '2026-05-20',
        imagePath: '/tmp/x.jpg',
        capturedAt: DateTime(2026, 5, 20).toIso8601String(),
      ));
    });

    test('completions are removed', () async {
      await db.deleteProfile(child.id!);
      expect(await countIn('activity_completions', child.id!), 0);
    });

    test('milestone achievements are removed', () async {
      await db.deleteProfile(child.id!);
      expect(await countIn('milestone_achievements', child.id!), 0);
    });

    test('badges are removed', () async {
      await db.deleteProfile(child.id!);
      expect(await countIn('unlocked_badges', child.id!), 0);
    });

    test('growth measurements are removed', () async {
      await db.deleteProfile(child.id!);
      expect(await countIn('growth_measurements', child.id!), 0);
    });

    test('photo memories are removed', () async {
      await db.deleteProfile(child.id!);
      expect(await countIn('photo_memories', child.id!), 0);
    });

    test('a sibling keeps their data', () async {
      final sibling = await db.insertProfile(_profile('Sibling'));
      await db.saveCompletion(ActivityCompletion(
        profileId: sibling.id!,
        activityId: 'act_0_1',
        dateKey: '2026-05-20',
        completedAt: DateTime(2026, 5, 20),
      ));

      await db.deleteProfile(child.id!);

      expect(await countIn('activity_completions', sibling.id!), 1);
    });
  });

  group('completions', () {
    late ChildProfile child;
    setUp(() async => child = await db.insertProfile(_profile('C')));

    test('saving twice on one day replaces rather than duplicates', () async {
      for (var i = 0; i < 2; i++) {
        await db.saveCompletion(ActivityCompletion(
          profileId: child.id!,
          activityId: 'act_0_$i',
          dateKey: '2026-05-20',
          completedAt: DateTime(2026, 5, 20),
        ));
      }

      final all = await db.getCompletions(child.id!);
      expect(all, hasLength(1),
          reason: 'UNIQUE(profile_id, date_key) must collapse the duplicate');
      expect(all.single.activityId, 'act_0_1');
    });

    test('two children may complete the same day independently', () async {
      final other = await db.insertProfile(_profile('D'));
      for (final p in [child, other]) {
        await db.saveCompletion(ActivityCompletion(
          profileId: p.id!,
          activityId: 'act_0_1',
          dateKey: '2026-05-20',
          completedAt: DateTime(2026, 5, 20),
        ));
      }

      expect(await db.getCompletions(child.id!), hasLength(1));
      expect(await db.getCompletions(other.id!), hasLength(1));
    });

    test('getCompletion finds a specific day and misses others', () async {
      await db.saveCompletion(ActivityCompletion(
        profileId: child.id!,
        activityId: 'act_0_1',
        dateKey: '2026-05-20',
        completedAt: DateTime(2026, 5, 20),
      ));

      expect(await db.getCompletion(child.id!, '2026-05-20'), isNotNull);
      expect(await db.getCompletion(child.id!, '2026-05-21'), isNull);
    });

    test('deleting one day leaves the rest', () async {
      for (final key in ['2026-05-20', '2026-05-21']) {
        await db.saveCompletion(ActivityCompletion(
          profileId: child.id!,
          activityId: 'act_0_1',
          dateKey: key,
          completedAt: DateTime.parse(key),
        ));
      }

      await db.deleteCompletion(child.id!, '2026-05-20');

      final rest = await db.getCompletions(child.id!);
      expect(rest, hasLength(1));
      expect(rest.single.dateKey, '2026-05-21');
    });

    test('deleting a day that was never completed is a no-op', () async {
      await db.deleteCompletion(child.id!, '2026-01-01');
      expect(await db.getCompletions(child.id!), isEmpty);
    });
  });

  group('achievements', () {
    late ChildProfile child;
    setUp(() async => child = await db.insertProfile(_profile('C')));

    test('saving the same milestone twice does not duplicate', () async {
      for (var i = 0; i < 2; i++) {
        await db.saveAchievement(MilestoneAchievement(
          profileId: child.id!,
          milestoneId: 'm_0_1',
          achievedDate: DateTime(2026, 5, 20),
        ));
      }

      expect(await db.getAchievement(child.id!, 'm_0_1'), isNotNull);
      final all = await db.getAchievements(child.id!);
      expect(all.where((a) => a.milestoneId == 'm_0_1'), hasLength(1));
    });

    test('notes round-trip, including an empty string', () async {
      await db.saveAchievement(MilestoneAchievement(
        profileId: child.id!,
        milestoneId: 'm_0_1',
        achievedDate: DateTime(2026, 5, 20),
        notes: '',
      ));

      final saved = await db.getAchievement(child.id!, 'm_0_1');
      expect(saved?.notes, '');
    });

    test('deleting an achievement removes it', () async {
      await db.saveAchievement(MilestoneAchievement(
        profileId: child.id!,
        milestoneId: 'm_0_1',
        achievedDate: DateTime(2026, 5, 20),
      ));
      await db.deleteAchievement(child.id!, 'm_0_1');

      expect(await db.getAchievement(child.id!, 'm_0_1'), isNull);
    });
  });

  group('badges', () {
    late ChildProfile child;
    setUp(() async => child = await db.insertProfile(_profile('C')));

    test('saving the same badge twice keeps one row', () async {
      await db.saveBadge(child.id!, 'first_step');
      await db.saveBadge(child.id!, 'first_step');

      final ids = await db.getUnlockedBadgeIds(child.id!);
      expect(ids, ['first_step']);
    });

    test('badges are scoped to a child', () async {
      final other = await db.insertProfile(_profile('D'));
      await db.saveBadge(child.id!, 'first_step');

      expect(await db.getUnlockedBadgeIds(other.id!), isEmpty);
    });
  });

  group('growth measurements', () {
    late ChildProfile child;
    setUp(() async => child = await db.insertProfile(_profile('C')));

    test('are returned per metric, not mixed together', () async {
      await db.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.weight,
        value: 7.2,
        measuredOn: DateTime(2026, 5, 20).toIso8601String(),
      ));
      await db.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.height,
        value: 68,
        measuredOn: DateTime(2026, 5, 20).toIso8601String(),
      ));

      final weights =
          await db.getGrowthMeasurements(child.id!, GrowthMetric.weight);
      expect(weights, hasLength(1));
      expect(weights.single.value, 7.2);
    });

    test('a fractional value round-trips without loss', () async {
      await db.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.weight,
        value: 7.35,
        measuredOn: DateTime(2026, 5, 20).toIso8601String(),
      ));

      final saved =
          await db.getGrowthMeasurements(child.id!, GrowthMetric.weight);
      expect(saved.single.value, closeTo(7.35, 0.0001));
    });

    test('deleting one measurement leaves the others', () async {
      final first = await db.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.weight,
        value: 7.0,
        measuredOn: DateTime(2026, 5, 20).toIso8601String(),
      ));
      await db.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.weight,
        value: 7.5,
        measuredOn: DateTime(2026, 6, 20).toIso8601String(),
      ));

      await db.deleteGrowthMeasurement(first.id!);

      final rest =
          await db.getGrowthMeasurements(child.id!, GrowthMetric.weight);
      expect(rest, hasLength(1));
      expect(rest.single.value, 7.5);
    });
  });

  group('photo memories', () {
    late ChildProfile child;
    setUp(() async => child = await db.insertProfile(_profile('C')));

    test('save returns the row with an id', () async {
      final saved = await db.savePhoto(PhotoMemory(
        profileId: child.id!,
        referenceType: 'activity',
        referenceId: '2026-05-20',
        imagePath: '/tmp/a.jpg',
        capturedAt: DateTime(2026, 5, 20).toIso8601String(),
      ));

      expect(saved.id, isNotNull);
    });

    test('deleting removes only the requested photo', () async {
      final a = await db.savePhoto(PhotoMemory(
        profileId: child.id!,
        referenceType: 'activity',
        referenceId: 'r1',
        imagePath: '/tmp/a.jpg',
        capturedAt: DateTime(2026, 5, 20).toIso8601String(),
      ));
      await db.savePhoto(PhotoMemory(
        profileId: child.id!,
        referenceType: 'activity',
        referenceId: 'r2',
        imagePath: '/tmp/b.jpg',
        capturedAt: DateTime(2026, 5, 21).toIso8601String(),
      ));

      await db.deletePhoto(a.id!);

      final rest = await db.getPhotos(child.id!);
      expect(rest, hasLength(1));
      expect(rest.single.imagePath, '/tmp/b.jpg');
    });
  });
}
