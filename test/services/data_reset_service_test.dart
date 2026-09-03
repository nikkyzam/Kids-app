import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/activity_skip.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/models/milestone_achievement.dart';
import 'package:playsteps/models/photo_memory.dart';
import 'package:playsteps/services/data_reset_service.dart';
import 'package:playsteps/services/photo_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  final db = DatabaseHelper.instance;

  /// Fills every table, so a wipe that misses one is a failing test rather
  /// than data a parent believed was gone.
  Future<int> seedEverything() async {
    final child = await db.insertProfile(ChildProfile(
      name: 'Emma',
      dateOfBirth: DateTime(2025, 1, 1),
      dueDate: DateTime(2025, 2, 1),
      sex: ChildSex.female,
      createdAt: DateTime(2025, 1, 1),
    ));
    final id = child.id!;
    await db.saveCompletion(ActivityCompletion(
      profileId: id,
      activityId: 'act_0_1',
      dateKey: '2025-02-01',
      completedAt: DateTime(2025, 2, 1),
    ));
    await db.saveAchievement(MilestoneAchievement(
      profileId: id,
      milestoneId: 'm_2_gm_1',
      achievedDate: DateTime(2025, 3, 1),
      notes: 'a private note',
    ));
    await db.saveBadge(id, 'first_step');
    await db.saveGrowthMeasurement(GrowthMeasurement(
      profileId: id,
      metric: GrowthMetric.weight,
      value: 5.4,
      measuredOn: '2025-03-01',
    ));
    await db.savePhoto(PhotoMemory(
      profileId: id,
      referenceType: 'milestone',
      referenceId: 'm_2_gm_1',
      imagePath: '/tmp/nonexistent.jpg',
      capturedAt: DateTime(2025, 3, 1).toIso8601String(),
    ));
    await db.saveSkip(ActivitySkip(
      profileId: id,
      activityId: 'act_0_2',
      reason: SkipReason.tooHard,
      skippedAt: DateTime(2025, 3, 1),
    ));
    return id;
  }

  late Directory tempRoot;

  setUp(() async {
    await db.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    // path_provider has no platform implementation under `flutter test`, so
    // photo storage is pointed at a throwaway directory instead.
    tempRoot = await Directory.systemTemp.createTemp('playsteps_photos');
    PhotoStorage.testRoot = tempRoot.path;
  });

  tearDown(() {
    PhotoStorage.testRoot = null;
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  test('leaves no row behind in any table', () async {
    final id = await seedEverything();

    await DataResetService.deleteEverything();

    expect(await db.getProfiles(), isEmpty);
    expect(await db.getCompletions(id), isEmpty);
    expect(await db.getAchievements(id), isEmpty);
    expect(await db.getUnlockedBadgeIds(id), isEmpty);
    expect(await db.getGrowthMeasurements(id, GrowthMetric.weight), isEmpty);
    expect(await db.getPhotos(id), isEmpty);
    expect(await db.getSkips(id), isEmpty);
  });

  test('the app can be used again straight afterwards', () async {
    await seedEverything();
    await DataResetService.deleteEverything();

    // A wipe must not leave the schema unusable — this is the path a parent
    // takes right after deleting: onboarding a child again.
    final fresh = await db.insertProfile(ChildProfile(
      name: 'Noah',
      dateOfBirth: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    ));
    expect(fresh.id, isNotNull);
    expect(await db.getProfiles(), hasLength(1));
  });

  test('clears the settings a parent chose', () async {
    SharedPreferences.setMockInitialValues({
      'active_profile_id': 3,
      'reminder_enabled': true,
      'use_imperial': true,
    });
    await seedEverything();

    await DataResetService.deleteEverything();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('active_profile_id'), isNull);
    expect(prefs.getBool('reminder_enabled'), isNull);
    expect(prefs.getBool('use_imperial'), isNull);
  });

  test('keeps a purchase, which is not data the parent entered', () async {
    SharedPreferences.setMockInitialValues({
      'is_premium': true,
      'is_premium_plus': true,
      'active_profile_id': 1,
    });
    await seedEverything();

    await DataResetService.deleteEverything();

    // The store re-confirms on launch, but a parent who wipes their data
    // offline should not lose access to what they bought until they are back
    // online.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('is_premium'), isTrue);
    expect(prefs.getBool('is_premium_plus'), isTrue);
  });

  test('a wipe with nothing to wipe is not an error', () async {
    await DataResetService.deleteEverything();
    expect(await db.getProfiles(), isEmpty);
  });

  test('deletes the photo files, not just the rows that name them', () async {
    final id = await seedEverything();
    final stored = await PhotoStorage.persist(
      await _fakeImage(tempRoot, 'source.jpg'),
      id: 'photo-one',
    );
    await db.savePhoto(PhotoMemory(
      profileId: id,
      referenceType: 'activity',
      referenceId: '2025-02-01',
      imagePath: stored,
      capturedAt: DateTime(2025, 2, 1).toIso8601String(),
    ));
    expect(File(stored).existsSync(), isTrue);

    final photosDeleted = await DataResetService.deleteEverything();

    expect(photosDeleted, isTrue);
    expect(File(stored).existsSync(), isFalse);
  });

  group('photo storage', () {
    test('copies a picked image out of the cache the OS can purge', () async {
      final source = await _fakeImage(tempRoot, 'from_picker.jpg');

      final stored = await PhotoStorage.persist(source, id: 'abc');

      expect(stored, isNot(source));
      expect(File(stored).existsSync(), isTrue);
      expect(File(stored).readAsBytesSync(), File(source).readAsBytesSync());
    });

    test('keeps the original extension, and defaults to jpg', () async {
      final png = await _fakeImage(tempRoot, 'shot.png');
      expect(await PhotoStorage.persist(png, id: 'p1'), endsWith('.png'));

      final none = await _fakeImage(tempRoot, 'shot');
      expect(await PhotoStorage.persist(none, id: 'p2'), endsWith('.jpg'));
    });

    test('refuses to delete a file outside its own directory', () async {
      // An image path from an older build could point at the picker's cache or
      // at the user's own library; "delete my PlaySteps data" is not
      // permission to delete that.
      final outsider = await _fakeImage(tempRoot, 'not_ours.jpg');

      await PhotoStorage.delete(outsider);

      expect(File(outsider).existsSync(), isTrue);
    });

    test('reports room for a photo-sized write', () async {
      expect(await PhotoStorage.hasRoomFor(1024), isTrue);
    });

    test('leaves no probe file behind after checking for room', () async {
      await PhotoStorage.hasRoomFor(1024);

      final leftovers = Directory('${tempRoot.path}/photos')
          .listSync()
          .map((e) => e.path.split('/').last)
          .where((name) => name.startsWith('.'))
          .toList();
      expect(leftovers, isEmpty);
    });
  });
}

/// A small file standing in for something the camera produced.
Future<String> _fakeImage(Directory root, String name) async {
  final file = File('${root.path}/$name');
  await file.writeAsBytes(List<int>.generate(256, (i) => i % 256));
  return file.path;
}
