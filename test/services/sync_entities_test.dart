import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/models/milestone_achievement.dart';
import 'package:playsteps/models/photo_memory.dart';
import 'package:playsteps/services/sync_service.dart';
import 'package:playsteps/utils/clock.dart';
import 'package:playsteps/utils/sync_timestamp.dart';

import 'sync_service_test.dart' show FakeBackend;

const _familyId = 'fam-1';
const _epoch = '2000-01-01T00:00:00.000Z';

/// Sync covers six record types through the same push/pull shape. These check
/// each one round-trips and that a row naming an unknown child is dropped
/// rather than attached to the wrong profile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackend backend;
  late ChildProfile child;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    Clock.freeze(DateTime.utc(2026, 5, 20, 12));
    await DatabaseHelper.instance.resetForTesting();
    backend = FakeBackend();
    SyncService.instance.backend = backend;

    child = await DatabaseHelper.instance.insertProfile(ChildProfile(
      name: 'Emma',
      dateOfBirth: DateTime(2025, 8, 20),
      createdAt: DateTime(2025, 8, 20),
    ));
  });

  tearDown(() {
    SyncService.instance.resetBackend();
    Clock.reset();
  });

  Future<void> sync() =>
      SyncService.instance.syncWith(familyId: _familyId, since: _epoch);

  final stamp = SyncTimestamp.from(DateTime.utc(2026, 5, 19));

  Future<int> countIn(String table) async {
    final db = await DatabaseHelper.instance.database;
    return (await db.query(table)).length;
  }

  group('activity completions', () {
    test('pull inserts a remote completion', () async {
      backend.remote['activity_completions'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'activity_id': 'act_0_1',
          'date_key': '2026-05-19',
          'completed_at': DateTime(2026, 5, 19).toIso8601String(),
          'updated_at': stamp,
        }
      ];

      await sync();

      final rows = await DatabaseHelper.instance.getCompletions(child.id!);
      expect(rows.map((c) => c.dateKey), contains('2026-05-19'));
    });

    test('a completion for an unknown child is dropped', () async {
      backend.remote['activity_completions'] = [
        {
          'family_id': _familyId,
          'profile_uuid': 'no-such-child',
          'activity_id': 'act_0_1',
          'date_key': '2026-05-19',
          'completed_at': DateTime(2026, 5, 19).toIso8601String(),
          'updated_at': stamp,
        }
      ];

      await sync();

      expect(await countIn('activity_completions'), 0,
          reason: 'an orphan row must not be attached to another child');
    });

    test('push sends a local completion', () async {
      await DatabaseHelper.instance.saveCompletion(ActivityCompletion(
        profileId: child.id!,
        activityId: 'act_0_1',
        dateKey: '2026-05-20',
        completedAt: DateTime(2026, 5, 20),
      ));

      await sync();

      expect(backend.pushedTo('activity_completions'), hasLength(1));
    });
  });

  group('milestone achievements', () {
    test('pull inserts a remote achievement with its notes', () async {
      backend.remote['milestone_achievements'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'milestone_id': 'm_0_1',
          'achieved_date': DateTime(2026, 5, 19).toIso8601String(),
          'notes': 'First smile!',
          'updated_at': stamp,
        }
      ];

      await sync();

      final saved =
          await DatabaseHelper.instance.getAchievement(child.id!, 'm_0_1');
      expect(saved, isNotNull);
      expect(saved!.notes, 'First smile!');
    });

    test('a newer remote note replaces an older local one', () async {
      await DatabaseHelper.instance.saveAchievement(MilestoneAchievement(
        profileId: child.id!,
        milestoneId: 'm_0_1',
        achievedDate: DateTime(2026, 5, 18),
        notes: 'old note',
      ));
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'milestone_achievements',
        {'updated_at': SyncTimestamp.from(DateTime.utc(2026, 5, 18))},
        where: 'profile_id = ?',
        whereArgs: [child.id],
      );

      backend.remote['milestone_achievements'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'milestone_id': 'm_0_1',
          'achieved_date': DateTime(2026, 5, 19).toIso8601String(),
          'notes': 'new note',
          'updated_at': stamp,
        }
      ];

      await sync();

      final saved =
          await DatabaseHelper.instance.getAchievement(child.id!, 'm_0_1');
      expect(saved!.notes, 'new note');
    });

    test('an older remote note does not overwrite a newer local one', () async {
      await DatabaseHelper.instance.saveAchievement(MilestoneAchievement(
        profileId: child.id!,
        milestoneId: 'm_0_1',
        achievedDate: DateTime(2026, 5, 20),
        notes: 'local latest',
      ));

      backend.remote['milestone_achievements'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'milestone_id': 'm_0_1',
          'achieved_date': DateTime(2026, 5, 10).toIso8601String(),
          'notes': 'stale remote',
          'updated_at': SyncTimestamp.from(DateTime.utc(2026, 5, 10)),
        }
      ];

      await sync();

      final saved =
          await DatabaseHelper.instance.getAchievement(child.id!, 'm_0_1');
      expect(saved!.notes, 'local latest');
    });
  });

  group('badges', () {
    test('pull inserts a remote badge', () async {
      backend.remote['unlocked_badges'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'badge_id': 'first_step',
          'unlocked_at': DateTime(2026, 5, 19).toIso8601String(),
          'updated_at': stamp,
        }
      ];

      await sync();

      final ids = await DatabaseHelper.instance.getUnlockedBadgeIds(child.id!);
      expect(ids, contains('first_step'));
    });

    test('pulling the same badge twice keeps one row', () async {
      backend.remote['unlocked_badges'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'badge_id': 'first_step',
          'unlocked_at': DateTime(2026, 5, 19).toIso8601String(),
          'updated_at': stamp,
        }
      ];

      await sync();
      await sync();

      final ids = await DatabaseHelper.instance.getUnlockedBadgeIds(child.id!);
      expect(ids.where((i) => i == 'first_step'), hasLength(1));
    });

    test('push sends a local badge', () async {
      await DatabaseHelper.instance.saveBadge(child.id!, 'week_warrior');

      await sync();

      expect(backend.pushedTo('unlocked_badges'), hasLength(1));
    });
  });

  group('growth measurements', () {
    test('pull inserts a remote measurement', () async {
      backend.remote['growth_measurements'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'local_id': 1,
          'metric': GrowthMetric.weight.name,
          'value': 7.4,
          'measured_on': DateTime(2026, 5, 19).toIso8601String(),
          'notes': null,
          'updated_at': stamp,
        }
      ];

      await sync();

      final saved = await DatabaseHelper.instance
          .getGrowthMeasurements(child.id!, GrowthMetric.weight);
      expect(saved, hasLength(1));
      expect(saved.single.value, closeTo(7.4, 0.001));
    });

    test('push sends a local measurement', () async {
      await DatabaseHelper.instance.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.height,
        value: 68.5,
        measuredOn: DateTime(2026, 5, 20).toIso8601String(),
      ));

      await sync();

      expect(backend.pushedTo('growth_measurements'), hasLength(1));
    });
  });

  group('photo memories', () {
    test('pull inserts a remote memory', () async {
      backend.remote['photo_memories'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'local_id': 1,
          'reference_type': 'activity',
          'reference_id': '2026-05-19',
          'image_path': '/tmp/remote.jpg',
          'caption': 'A good day',
          'captured_at': DateTime(2026, 5, 19).toIso8601String(),
          'updated_at': stamp,
        }
      ];

      await sync();

      final saved = await DatabaseHelper.instance.getPhotos(child.id!);
      expect(saved, hasLength(1));
      expect(saved.single.caption, 'A good day');
    });

    test('push sends a local memory', () async {
      await DatabaseHelper.instance.savePhoto(PhotoMemory(
        profileId: child.id!,
        referenceType: 'milestone',
        referenceId: 'm_0_1',
        imagePath: '/tmp/local.jpg',
        capturedAt: DateTime(2026, 5, 20).toIso8601String(),
      ));

      await sync();

      expect(backend.pushedTo('photo_memories'), hasLength(1));
    });
  });

  group('a full sync of everything', () {
    test('pushes every populated table in one cycle', () async {
      await DatabaseHelper.instance.saveCompletion(ActivityCompletion(
        profileId: child.id!,
        activityId: 'act_0_1',
        dateKey: '2026-05-20',
        completedAt: DateTime(2026, 5, 20),
      ));
      await DatabaseHelper.instance.saveAchievement(MilestoneAchievement(
        profileId: child.id!,
        milestoneId: 'm_0_1',
        achievedDate: DateTime(2026, 5, 20),
      ));
      await DatabaseHelper.instance.saveBadge(child.id!, 'first_step');
      await DatabaseHelper.instance.saveGrowthMeasurement(GrowthMeasurement(
        profileId: child.id!,
        metric: GrowthMetric.weight,
        value: 7.0,
        measuredOn: DateTime(2026, 5, 20).toIso8601String(),
      ));
      await DatabaseHelper.instance.savePhoto(PhotoMemory(
        profileId: child.id!,
        referenceType: 'activity',
        referenceId: '2026-05-20',
        imagePath: '/tmp/a.jpg',
        capturedAt: DateTime(2026, 5, 20).toIso8601String(),
      ));

      await sync();

      final tables = backend.pushes.map((p) => p.table).toSet();
      expect(
        tables,
        containsAll(<String>[
          'child_profiles',
          'activity_completions',
          'milestone_achievements',
          'unlocked_badges',
          'growth_measurements',
          'photo_memories',
        ]),
      );
    });
  });
}
