import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/services/sync_backend.dart';
import 'package:playsteps/services/sync_service.dart';
import 'package:playsteps/utils/clock.dart';
import 'package:playsteps/utils/sync_timestamp.dart';

/// Records what was pushed and serves canned rows for pulls.
class FakeBackend implements SyncBackend {
  final Map<String, List<Map<String, dynamic>>> remote = {};
  final List<({String table, List<Map<String, dynamic>> rows})> pushes = [];

  /// Set to throw from the next fetch, simulating a dropped connection.
  Object? failWith;

  @override
  Future<List<Map<String, dynamic>>> fetchSince(
    String table, {
    required String familyId,
    required String since,
  }) async {
    if (failWith != null) throw failWith!;
    return (remote[table] ?? const [])
        .where((r) => (r['family_id'] as String?) == familyId)
        .where((r) =>
            (r['updated_at'] as String).compareTo(since) >= 0 ||
            since.startsWith('2000'))
        .toList();
  }

  @override
  Future<void> upsertAll(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
  }) async {
    if (rows.isEmpty) return;
    pushes.add((table: table, rows: rows));
  }

  List<Map<String, dynamic>> pushedTo(String table) =>
      pushes.where((p) => p.table == table).expand((p) => p.rows).toList();
}

const _familyId = 'fam-1';
const _epoch = '2000-01-01T00:00:00.000Z';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackend backend;

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
  });

  tearDown(() {
    SyncService.instance.resetBackend();
    Clock.reset();
  });

  Future<ChildProfile> seedChild({String name = 'Emma'}) =>
      DatabaseHelper.instance.insertProfile(ChildProfile(
        name: name,
        dateOfBirth: DateTime(2025, 8, 20),
        createdAt: DateTime(2025, 8, 20),
      ));

  Future<void> sync() =>
      SyncService.instance.syncWith(familyId: _familyId, since: _epoch);

  group('push', () {
    test('sends local profiles tagged with the family id', () async {
      final child = await seedChild();

      await sync();

      final pushed = backend.pushedTo('child_profiles');
      expect(pushed, hasLength(1));
      expect(pushed.single['family_id'], _familyId);
      expect(pushed.single['name'], 'Emma');
      expect(pushed.single['profile_uuid'], child.uuid);
    });

    test('sends completions', () async {
      final child = await seedChild();
      await DatabaseHelper.instance.saveCompletion(ActivityCompletion(
        profileId: child.id!,
        activityId: 'act_0_1',
        dateKey: '2026-05-20',
        completedAt: DateTime(2026, 5, 20),
      ));

      await sync();

      expect(backend.pushedTo('activity_completions'), hasLength(1));
    });

    test('pushes nothing when there is nothing local', () async {
      await sync();
      expect(backend.pushes, isEmpty,
          reason: 'an empty upsert is a wasted round trip');
    });

    test('a profile with no uuid is skipped rather than pushed as null',
        () async {
      final db = await DatabaseHelper.instance.database;
      await db.insert('child_profiles', {
        'name': 'Legacy',
        'date_of_birth': DateTime(2025, 1, 1).toIso8601String(),
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
        'updated_at': SyncTimestamp.now(),
        // uuid deliberately absent, as in rows written before sync existed
      });

      await sync();

      expect(backend.pushedTo('child_profiles'), isEmpty);
    });
  });

  group('pull: new records', () {
    test('inserts a profile that only exists remotely', () async {
      backend.remote['child_profiles'] = [
        {
          'family_id': _familyId,
          'profile_uuid': 'uuid-remote',
          'name': 'Remote Child',
          'date_of_birth': DateTime(2025, 3, 1).toIso8601String(),
          'created_at': DateTime(2025, 3, 1).toIso8601String(),
          'updated_at': SyncTimestamp.from(DateTime.utc(2026, 5, 19)),
        }
      ];

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.map((p) => p.name), contains('Remote Child'));
    });

    test('ignores rows belonging to another family', () async {
      backend.remote['child_profiles'] = [
        {
          'family_id': 'someone-else',
          'profile_uuid': 'uuid-other',
          'name': 'Not Ours',
          'date_of_birth': DateTime(2025, 3, 1).toIso8601String(),
          'created_at': DateTime(2025, 3, 1).toIso8601String(),
          'updated_at': SyncTimestamp.from(DateTime.utc(2026, 5, 19)),
        }
      ];

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.map((p) => p.name), isNot(contains('Not Ours')));
    });

    test('a row with no profile_uuid is skipped, not inserted blank', () async {
      backend.remote['child_profiles'] = [
        {
          'family_id': _familyId,
          'profile_uuid': null,
          'name': 'Broken',
          'date_of_birth': DateTime(2025, 3, 1).toIso8601String(),
          'created_at': DateTime(2025, 3, 1).toIso8601String(),
          'updated_at': SyncTimestamp.from(DateTime.utc(2026, 5, 19)),
        }
      ];

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local, isEmpty);
    });
  });

  group('pull: conflict resolution', () {
    Future<ChildProfile> localChildEditedAt(DateTime when) async {
      final child = await seedChild(name: 'Local Name');
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'child_profiles',
        {'updated_at': SyncTimestamp.from(when)},
        where: 'id = ?',
        whereArgs: [child.id],
      );
      return child;
    }

    Future<void> remoteEdit(String uuid, String name, DateTime when) async {
      backend.remote['child_profiles'] = [
        {
          'family_id': _familyId,
          'profile_uuid': uuid,
          'name': name,
          'date_of_birth': DateTime(2025, 8, 20).toIso8601String(),
          'created_at': DateTime(2025, 8, 20).toIso8601String(),
          'updated_at': SyncTimestamp.from(when),
        }
      ];
    }

    test('a newer remote edit wins', () async {
      final child = await localChildEditedAt(DateTime.utc(2026, 5, 18));
      await remoteEdit(child.uuid!, 'Remote Name', DateTime.utc(2026, 5, 19));

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.single.name, 'Remote Name');
    });

    test('an older remote edit does not clobber a newer local one', () async {
      final child = await localChildEditedAt(DateTime.utc(2026, 5, 19));
      await remoteEdit(child.uuid!, 'Stale Name', DateTime.utc(2026, 5, 18));

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.single.name, 'Local Name');
    });

    test('an identical timestamp leaves the local row alone', () async {
      final when = DateTime.utc(2026, 5, 19);
      final child = await localChildEditedAt(when);
      await remoteEdit(child.uuid!, 'Tie Name', when);

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.single.name, 'Local Name');
    });

    test('a later edit made further west still wins', () async {
      // The regression that made this refactor worthwhile: comparing the
      // timestamps as text ranked the UTC+10 device above a genuinely later
      // edit from UTC-5.
      final child = await localChildEditedAt(DateTime.utc(2026, 5, 20, 23, 0));
      await remoteEdit(
          child.uuid!, 'Later Remote', DateTime.utc(2026, 5, 20, 23, 30));

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.single.name, 'Later Remote');
    });

    test('a corrupt remote timestamp never overwrites local data', () async {
      final child = await localChildEditedAt(DateTime.utc(2026, 5, 18));
      backend.remote['child_profiles'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'name': 'Corrupt',
          'date_of_birth': DateTime(2025, 8, 20).toIso8601String(),
          'created_at': DateTime(2025, 8, 20).toIso8601String(),
          // Rolls over to 2027 under DateTime.parse.
          'updated_at': '2026-13-45T99:99:99Z',
        }
      ];

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.single.name, 'Local Name');
    });

    test('a newer remote edit propagates the date of birth too', () async {
      final child = await localChildEditedAt(DateTime.utc(2026, 5, 18));
      backend.remote['child_profiles'] = [
        {
          'family_id': _familyId,
          'profile_uuid': child.uuid,
          'name': 'Local Name',
          'date_of_birth': DateTime(2025, 9, 9).toIso8601String(),
          'created_at': DateTime(2025, 8, 20).toIso8601String(),
          'updated_at': SyncTimestamp.from(DateTime.utc(2026, 5, 19)),
        }
      ];

      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.single.dateOfBirth.month, 9,
          reason: 'correcting a birth date must reach the other devices');
    });
  });

  group('failure handling', () {
    test('a backend error propagates rather than silently half-syncing',
        () async {
      await seedChild();
      backend.failWith = Exception('network down');

      expect(sync(), throwsA(isA<Exception>()));
    });

    test('local data survives a failed sync', () async {
      await seedChild();
      backend.failWith = Exception('network down');

      try {
        await sync();
      } catch (_) {
        // expected
      }

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local, hasLength(1));
    });
  });

  group('idempotence', () {
    test('syncing twice does not duplicate pulled rows', () async {
      backend.remote['child_profiles'] = [
        {
          'family_id': _familyId,
          'profile_uuid': 'uuid-remote',
          'name': 'Remote Child',
          'date_of_birth': DateTime(2025, 3, 1).toIso8601String(),
          'created_at': DateTime(2025, 3, 1).toIso8601String(),
          'updated_at': SyncTimestamp.from(DateTime.utc(2026, 5, 19)),
        }
      ];

      await sync();
      await sync();

      final local = await DatabaseHelper.instance.getProfiles();
      expect(local.where((p) => p.name == 'Remote Child'), hasLength(1));
    });
  });
}
