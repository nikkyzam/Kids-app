import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/activity_skip.dart';
import 'package:playsteps/models/child_profile.dart';

/// Schema upgrades run against a database that a real user already has data
/// in. These tests build the *old* schema by hand, write rows into it, then
/// open it through [DatabaseHelper] — which triggers the upgrade path — and
/// check that the rows are still there and the new columns are usable.
///
/// An in-memory database cannot be used here: it is discarded when the first
/// connection closes, so there would be nothing left to upgrade.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('playsteps_migration');
    DatabaseHelper.testDatabasePath = '${tempDir.path}/playsteps.db';
    await DatabaseHelper.instance.resetForTesting();
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTesting();
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// The schema exactly as version 5 shipped it.
  Future<void> createV5(Database db) async {
    await db.execute('''
      CREATE TABLE child_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        name TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE activity_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        activity_id TEXT NOT NULL,
        date_key TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (profile_id) REFERENCES child_profiles(id) ON DELETE CASCADE,
        UNIQUE(profile_id, date_key)
      )
    ''');
    await db.execute('''
      CREATE TABLE milestone_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        milestone_id TEXT NOT NULL,
        achieved_date TEXT NOT NULL,
        notes TEXT,
        updated_at TEXT,
        FOREIGN KEY (profile_id) REFERENCES child_profiles(id) ON DELETE CASCADE,
        UNIQUE(profile_id, milestone_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE unlocked_badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        badge_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (profile_id) REFERENCES child_profiles(id) ON DELETE CASCADE,
        UNIQUE(profile_id, badge_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE growth_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        metric TEXT NOT NULL,
        value REAL NOT NULL,
        measured_on TEXT NOT NULL,
        notes TEXT,
        updated_at TEXT,
        FOREIGN KEY (profile_id) REFERENCES child_profiles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE photo_memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        reference_type TEXT NOT NULL,
        reference_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        caption TEXT,
        captured_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (profile_id) REFERENCES child_profiles(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> seedV5() async {
    final db = await databaseFactory.openDatabase(
      DatabaseHelper.testDatabasePath!,
      options:
          OpenDatabaseOptions(version: 5, onCreate: (db, _) => createV5(db)),
    );
    await db.insert('child_profiles', {
      'uuid': 'existing-uuid',
      'name': 'Emma',
      'date_of_birth': '2025-01-01T00:00:00.000',
      'created_at': '2025-01-01T00:00:00.000',
      'updated_at': '2025-01-01T00:00:00.000',
    });
    await db.insert('activity_completions', {
      'profile_id': 1,
      'activity_id': 'act_0_1',
      'date_key': '2025-02-01',
      'completed_at': '2025-02-01T09:00:00.000',
      'updated_at': '2025-02-01T09:00:00.000',
    });
    await db.close();
  }

  test('upgrading from v5 keeps the data that was already there', () async {
    await seedV5();

    final profiles = await DatabaseHelper.instance.getProfiles();
    expect(profiles, hasLength(1));
    expect(profiles.single.name, 'Emma');
    expect(profiles.single.uuid, 'existing-uuid');

    final completions = await DatabaseHelper.instance.getCompletions(1);
    expect(completions, hasLength(1));
    expect(completions.single.activityId, 'act_0_1');
  });

  test('a profile upgraded from v5 reads as a term birth', () async {
    await seedV5();

    final profile = (await DatabaseHelper.instance.getProfiles()).single;
    expect(profile.dueDate, isNull);
    expect(profile.sex, isNull);
    expect(profile.usesAdjustedAge, isFalse);
  });

  test('the new columns are writable straight after the upgrade', () async {
    await seedV5();

    final profile = (await DatabaseHelper.instance.getProfiles()).single;
    await DatabaseHelper.instance.updateProfile(profile.copyWith(
      dueDate: DateTime(2025, 3, 1),
      sex: ChildSex.female,
    ));

    final reloaded = (await DatabaseHelper.instance.getProfiles()).single;
    expect(reloaded.dueDate, DateTime(2025, 3, 1));
    expect(reloaded.sex, ChildSex.female);
  });

  test('the activity_skips table is created by the upgrade', () async {
    await seedV5();

    await DatabaseHelper.instance.saveSkip(ActivitySkip(
      profileId: 1,
      activityId: 'act_0_1',
      reason: SkipReason.tooHard,
      skippedAt: DateTime(2025, 2, 2),
    ));

    final skips = await DatabaseHelper.instance.getSkips(1);
    expect(skips, hasLength(1));
    expect(skips.single.reason, SkipReason.tooHard);
  });

  test('a fresh install lands on the same schema as an upgraded one', () async {
    // No seeding: this opens at the current version through _onCreate.
    final saved = await DatabaseHelper.instance.insertProfile(ChildProfile(
      name: 'Noah',
      dateOfBirth: DateTime(2025, 1, 1),
      dueDate: DateTime(2025, 2, 15),
      sex: ChildSex.male,
      createdAt: DateTime(2025, 1, 1),
    ));

    final reloaded = (await DatabaseHelper.instance.getProfiles()).single;
    expect(reloaded.id, saved.id);
    expect(reloaded.dueDate, DateTime(2025, 2, 15));
    expect(reloaded.sex, ChildSex.male);

    await DatabaseHelper.instance.saveSkip(ActivitySkip(
      profileId: saved.id!,
      activityId: 'act_0_2',
      skippedAt: DateTime(2025, 2, 2),
    ));
    expect(await DatabaseHelper.instance.getSkips(saved.id!), hasLength(1));
  });
}
