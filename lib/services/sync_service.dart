import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/database_helper.dart';
import 'auth_service.dart';
import '../utils/sync_timestamp.dart';

class SyncService {
  SyncService._();
  static final instance = SyncService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Public entry point
  // ---------------------------------------------------------------------------

  Future<void> syncAll() async {
    if (!AuthService.instance.isSignedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final familyId = AuthService.instance.familyId;
    final lastSync =
        prefs.getString('last_sync_at') ?? '2000-01-01T00:00:00.000Z';

    await _pushAll(familyId, lastSync);
    await _pullAll(familyId, lastSync);

    await prefs.setString('last_sync_at', SyncTimestamp.now());
  }

  // ---------------------------------------------------------------------------
  // Push orchestration
  // ---------------------------------------------------------------------------

  Future<void> _pushAll(String familyId, String since) async {
    await _pushProfiles(familyId, since);
    await _pushCompletions(familyId, since);
    await _pushMilestones(familyId, since);
    await _pushBadges(familyId, since);
    await _pushGrowth(familyId, since);
    await _pushPhotos(familyId, since);
  }

  // ---------------------------------------------------------------------------
  // Pull orchestration
  // ---------------------------------------------------------------------------

  Future<void> _pullAll(String familyId, String since) async {
    await _pullProfiles(familyId, since);
    await _pullCompletions(familyId, since);
    await _pullMilestones(familyId, since);
    await _pullBadges(familyId, since);
    await _pullGrowth(familyId, since);
    await _pullPhotos(familyId, since);
  }

  // ---------------------------------------------------------------------------
  // Push: child_profiles
  // ---------------------------------------------------------------------------

  Future<void> _pushProfiles(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'child_profiles',
      where: 'updated_at >= ?',
      whereArgs: [since],
    );

    if (rows.isEmpty) return;

    final payload = rows
        .map((r) {
          final uuid = r['uuid'] as String?;
          if (uuid == null) return null;
          return {
            'family_id': familyId,
            'profile_uuid': uuid,
            'name': r['name'],
            'date_of_birth': r['date_of_birth'],
            'created_at': r['created_at'],
            'updated_at': r['updated_at'],
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (payload.isEmpty) return;

    await _client
        .from('child_profiles')
        .upsert(payload, onConflict: 'family_id,profile_uuid');
  }

  // ---------------------------------------------------------------------------
  // Push: activity_completions
  // ---------------------------------------------------------------------------

  Future<void> _pushCompletions(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;
    final profiles = await db.query('child_profiles', columns: ['id', 'uuid']);

    for (final profile in profiles) {
      final profileId = profile['id'];
      final profileUuid = profile['uuid'] as String?;
      if (profileUuid == null) continue;

      final rows = await db.query(
        'activity_completions',
        where: 'profile_id = ? AND updated_at >= ?',
        whereArgs: [profileId, since],
      );

      if (rows.isEmpty) continue;

      final payload = rows
          .map((r) => {
                'family_id': familyId,
                'profile_uuid': profileUuid,
                'activity_id': r['activity_id'],
                'date_key': r['date_key'],
                'completed_at': r['completed_at'],
                'updated_at': r['updated_at'],
              })
          .toList();

      await _client
          .from('activity_completions')
          .upsert(payload, onConflict: 'family_id,profile_uuid,date_key');
    }
  }

  // ---------------------------------------------------------------------------
  // Push: milestone_achievements
  // ---------------------------------------------------------------------------

  Future<void> _pushMilestones(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;
    final profiles = await db.query('child_profiles', columns: ['id', 'uuid']);

    for (final profile in profiles) {
      final profileId = profile['id'];
      final profileUuid = profile['uuid'] as String?;
      if (profileUuid == null) continue;

      final rows = await db.query(
        'milestone_achievements',
        where: 'profile_id = ? AND updated_at >= ?',
        whereArgs: [profileId, since],
      );

      if (rows.isEmpty) continue;

      final payload = rows
          .map((r) => {
                'family_id': familyId,
                'profile_uuid': profileUuid,
                'milestone_id': r['milestone_id'],
                'achieved_date': r['achieved_date'],
                'notes': r['notes'],
                'updated_at': r['updated_at'],
              })
          .toList();

      await _client
          .from('milestone_achievements')
          .upsert(payload, onConflict: 'family_id,profile_uuid,milestone_id');
    }
  }

  // ---------------------------------------------------------------------------
  // Push: unlocked_badges
  // ---------------------------------------------------------------------------

  Future<void> _pushBadges(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;
    final profiles = await db.query('child_profiles', columns: ['id', 'uuid']);

    for (final profile in profiles) {
      final profileId = profile['id'];
      final profileUuid = profile['uuid'] as String?;
      if (profileUuid == null) continue;

      final rows = await db.query(
        'unlocked_badges',
        where: 'profile_id = ? AND updated_at >= ?',
        whereArgs: [profileId, since],
      );

      if (rows.isEmpty) continue;

      final payload = rows
          .map((r) => {
                'family_id': familyId,
                'profile_uuid': profileUuid,
                'badge_id': r['badge_id'],
                'unlocked_at': r['unlocked_at'],
                'updated_at': r['updated_at'],
              })
          .toList();

      await _client
          .from('unlocked_badges')
          .upsert(payload, onConflict: 'family_id,profile_uuid,badge_id');
    }
  }

  // ---------------------------------------------------------------------------
  // Push: growth_measurements
  // ---------------------------------------------------------------------------

  Future<void> _pushGrowth(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;
    final profiles = await db.query('child_profiles', columns: ['id', 'uuid']);

    for (final profile in profiles) {
      final profileId = profile['id'];
      final profileUuid = profile['uuid'] as String?;
      if (profileUuid == null) continue;

      final rows = await db.query(
        'growth_measurements',
        where: 'profile_id = ? AND updated_at >= ?',
        whereArgs: [profileId, since],
      );

      if (rows.isEmpty) continue;

      final payload = rows
          .map((r) => {
                'family_id': familyId,
                'profile_uuid': profileUuid,
                'local_id': r['id'],
                'metric': r['metric'],
                'value': r['value'],
                'measured_on': r['measured_on'],
                'notes': r['notes'],
                'updated_at': r['updated_at'],
              })
          .toList();

      await _client
          .from('growth_measurements')
          .upsert(payload, onConflict: 'family_id,profile_uuid,local_id');
    }
  }

  // ---------------------------------------------------------------------------
  // Push: photo_memories
  // ---------------------------------------------------------------------------

  Future<void> _pushPhotos(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;
    final profiles = await db.query('child_profiles', columns: ['id', 'uuid']);

    for (final profile in profiles) {
      final profileId = profile['id'];
      final profileUuid = profile['uuid'] as String?;
      if (profileUuid == null) continue;

      final rows = await db.query(
        'photo_memories',
        where: 'profile_id = ? AND updated_at >= ?',
        whereArgs: [profileId, since],
      );

      if (rows.isEmpty) continue;

      final payload = rows
          .map((r) => {
                'family_id': familyId,
                'profile_uuid': profileUuid,
                'local_id': r['id'],
                'reference_type': r['reference_type'],
                'reference_id': r['reference_id'],
                'image_path': r['image_path'],
                'caption': r['caption'],
                'captured_at': r['captured_at'],
                'updated_at': r['updated_at'],
              })
          .toList();

      await _client
          .from('photo_memories')
          .upsert(payload, onConflict: 'family_id,profile_uuid,local_id');
    }
  }

  // ---------------------------------------------------------------------------
  // Pull: child_profiles
  // ---------------------------------------------------------------------------

  Future<void> _pullProfiles(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;

    final remote = await _client
        .from('child_profiles')
        .select()
        .eq('family_id', familyId)
        .gte('updated_at', since);

    for (final row in remote) {
      final profileUuid = row['profile_uuid'] as String?;
      if (profileUuid == null) continue;

      final existing = await db.query(
        'child_profiles',
        where: 'uuid = ?',
        whereArgs: [profileUuid],
      );

      if (existing.isEmpty) {
        await db.insert('child_profiles', {
          'uuid': profileUuid,
          'name': row['name'],
          'date_of_birth': row['date_of_birth'],
          'created_at': row['created_at'],
          'updated_at': row['updated_at'],
        });
      } else {
        final local = existing.first;
        final remoteUpdatedAt = row['updated_at'] as String;
        final localUpdatedAt = local['updated_at'] as String?;
        if (SyncTimestamp.isRemoteNewer(remoteUpdatedAt, localUpdatedAt)) {
          await db.update(
            'child_profiles',
            {
              'name': row['name'],
              // date_of_birth was previously omitted, so correcting a child's
              // birth date on one device never reached the others.
              'date_of_birth': row['date_of_birth'],
              'updated_at': remoteUpdatedAt,
            },
            where: 'uuid = ?',
            whereArgs: [profileUuid],
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Pull: activity_completions
  // ---------------------------------------------------------------------------

  Future<void> _pullCompletions(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;

    final remote = await _client
        .from('activity_completions')
        .select()
        .eq('family_id', familyId)
        .gte('updated_at', since);

    for (final row in remote) {
      final profileUuid = row['profile_uuid'] as String?;
      if (profileUuid == null) continue;

      final profileRows = await db.query(
        'child_profiles',
        columns: ['id'],
        where: 'uuid = ?',
        whereArgs: [profileUuid],
      );
      if (profileRows.isEmpty) continue;
      final profileId = profileRows.first['id'];

      final dateKey = row['date_key'] as String;
      final existing = await db.query(
        'activity_completions',
        where: 'profile_id = ? AND date_key = ?',
        whereArgs: [profileId, dateKey],
      );

      if (existing.isEmpty) {
        await db.insert('activity_completions', {
          'profile_id': profileId,
          'activity_id': row['activity_id'],
          'date_key': dateKey,
          'completed_at': row['completed_at'],
          'updated_at': row['updated_at'],
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Pull: milestone_achievements
  // ---------------------------------------------------------------------------

  Future<void> _pullMilestones(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;

    final remote = await _client
        .from('milestone_achievements')
        .select()
        .eq('family_id', familyId)
        .gte('updated_at', since);

    for (final row in remote) {
      final profileUuid = row['profile_uuid'] as String?;
      if (profileUuid == null) continue;

      final profileRows = await db.query(
        'child_profiles',
        columns: ['id'],
        where: 'uuid = ?',
        whereArgs: [profileUuid],
      );
      if (profileRows.isEmpty) continue;
      final profileId = profileRows.first['id'];

      final milestoneId = row['milestone_id'] as String;
      final existing = await db.query(
        'milestone_achievements',
        where: 'profile_id = ? AND milestone_id = ?',
        whereArgs: [profileId, milestoneId],
      );

      if (existing.isEmpty) {
        await db.insert('milestone_achievements', {
          'profile_id': profileId,
          'milestone_id': milestoneId,
          'achieved_date': row['achieved_date'],
          'notes': row['notes'],
          'updated_at': row['updated_at'],
        });
      } else {
        final local = existing.first;
        final remoteUpdatedAt = row['updated_at'] as String;
        final localUpdatedAt = local['updated_at'] as String?;
        if (SyncTimestamp.isRemoteNewer(remoteUpdatedAt, localUpdatedAt)) {
          await db.update(
            'milestone_achievements',
            {
              'achieved_date': row['achieved_date'],
              'notes': row['notes'],
              'updated_at': remoteUpdatedAt,
            },
            where: 'profile_id = ? AND milestone_id = ?',
            whereArgs: [profileId, milestoneId],
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Pull: unlocked_badges
  // ---------------------------------------------------------------------------

  Future<void> _pullBadges(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;

    final remote = await _client
        .from('unlocked_badges')
        .select()
        .eq('family_id', familyId)
        .gte('updated_at', since);

    for (final row in remote) {
      final profileUuid = row['profile_uuid'] as String?;
      if (profileUuid == null) continue;

      final profileRows = await db.query(
        'child_profiles',
        columns: ['id'],
        where: 'uuid = ?',
        whereArgs: [profileUuid],
      );
      if (profileRows.isEmpty) continue;
      final profileId = profileRows.first['id'];

      await db.insert(
        'unlocked_badges',
        {
          'profile_id': profileId,
          'badge_id': row['badge_id'],
          'unlocked_at': row['unlocked_at'],
          'updated_at': row['updated_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pull: growth_measurements
  // ---------------------------------------------------------------------------

  Future<void> _pullGrowth(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;

    final remote = await _client
        .from('growth_measurements')
        .select()
        .eq('family_id', familyId)
        .gte('updated_at', since);

    for (final row in remote) {
      final profileUuid = row['profile_uuid'] as String?;
      if (profileUuid == null) continue;

      final profileRows = await db.query(
        'child_profiles',
        columns: ['id'],
        where: 'uuid = ?',
        whereArgs: [profileUuid],
      );
      if (profileRows.isEmpty) continue;
      final profileId = profileRows.first['id'];

      final metric = row['metric'] as String;
      final measuredOn = row['measured_on'] as String;

      final existing = await db.query(
        'growth_measurements',
        where: 'profile_id = ? AND metric = ? AND measured_on = ?',
        whereArgs: [profileId, metric, measuredOn],
      );

      if (existing.isEmpty) {
        await db.insert('growth_measurements', {
          'profile_id': profileId,
          'metric': metric,
          'value': row['value'],
          'measured_on': measuredOn,
          'notes': row['notes'],
          'updated_at': row['updated_at'],
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Pull: photo_memories
  // ---------------------------------------------------------------------------

  Future<void> _pullPhotos(String familyId, String since) async {
    final db = await DatabaseHelper.instance.database;

    final remote = await _client
        .from('photo_memories')
        .select()
        .eq('family_id', familyId)
        .gte('updated_at', since);

    for (final row in remote) {
      final profileUuid = row['profile_uuid'] as String?;
      if (profileUuid == null) continue;

      final profileRows = await db.query(
        'child_profiles',
        columns: ['id'],
        where: 'uuid = ?',
        whereArgs: [profileUuid],
      );
      if (profileRows.isEmpty) continue;
      final profileId = profileRows.first['id'];

      final referenceType = row['reference_type'] as String;
      final referenceId = row['reference_id'] as String;
      final capturedAt = row['captured_at'] as String;

      final existing = await db.query(
        'photo_memories',
        where:
            'profile_id = ? AND reference_type = ? AND reference_id = ? AND captured_at = ?',
        whereArgs: [profileId, referenceType, referenceId, capturedAt],
      );

      if (existing.isEmpty) {
        // image_path will be a stale path on this device — that's OK;
        // the app can re-download the image separately if needed.
        await db.insert('photo_memories', {
          'profile_id': profileId,
          'reference_type': referenceType,
          'reference_id': referenceId,
          'image_path': row['image_path'],
          'caption': row['caption'],
          'captured_at': capturedAt,
          'updated_at': row['updated_at'],
        });
      }
    }
  }
}
