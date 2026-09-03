import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/data/milestones_data.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/activity_completion.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/models/milestone_achievement.dart';
import 'package:playsteps/models/photo_memory.dart';
import 'package:playsteps/services/baby_book.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  final db = DatabaseHelper.instance;
  late int profileId;

  setUp(() async {
    await db.resetForTesting();
    final child = await db.insertProfile(ChildProfile(
      name: 'Emma',
      dateOfBirth: DateTime(2025, 1, 1),
      createdAt: DateTime(2025, 1, 1),
    ));
    profileId = child.id!;
  });

  final milestone = MilestonesData.all.first;

  Future<void> addMilestone(DateTime on, {String? notes}) =>
      db.saveAchievement(MilestoneAchievement(
        profileId: profileId,
        milestoneId: milestone.id,
        achievedDate: on,
        notes: notes,
      ));

  Future<void> addGrowth(GrowthMetric metric, double value, String on) =>
      db.saveGrowthMeasurement(GrowthMeasurement(
        profileId: profileId,
        metric: metric,
        value: value,
        measuredOn: on,
      ));

  Future<void> addPhoto(
    String type,
    String reference,
    DateTime on, {
    String? caption,
  }) =>
      db.savePhoto(PhotoMemory(
        profileId: profileId,
        referenceType: type,
        referenceId: reference,
        imagePath: '/tmp/$reference.jpg',
        caption: caption,
        capturedAt: on.toIso8601String(),
      ));

  test('gathers photos, milestones and measurements into one story', () async {
    await addMilestone(DateTime(2025, 3, 1));
    await addGrowth(GrowthMetric.weight, 5.4, '2025-04-01');
    await addPhoto(
        BabyBook.standaloneReference, '2025-05-01', DateTime(2025, 5, 1));

    final story = await BabyBook.load(profileId);

    expect(story.map((e) => e.kind), [
      BabyBookEntryKind.photo,
      BabyBookEntryKind.growth,
      BabyBookEntryKind.milestone,
    ]);
  });

  test('reads newest first', () async {
    await addGrowth(GrowthMetric.weight, 5.0, '2025-02-01');
    await addGrowth(GrowthMetric.weight, 6.0, '2025-06-01');
    await addMilestone(DateTime(2025, 4, 1));

    final story = await BabyBook.load(profileId);

    final dates = story.map((e) => e.date).toList();
    expect(dates, [
      DateTime(2025, 6, 1),
      DateTime(2025, 4, 1),
      DateTime(2025, 2, 1),
    ]);
  });

  test('shows a milestone photo on the milestone, not twice', () async {
    await addMilestone(DateTime(2025, 3, 1), notes: 'She did it!');
    await addPhoto('milestone', milestone.id, DateTime(2025, 3, 1));

    final story = await BabyBook.load(profileId);

    // One moment, one line: the photo hangs off the milestone rather than
    // appearing again on its own.
    expect(story, hasLength(1));
    expect(story.single.kind, BabyBookEntryKind.milestone);
    expect(story.single.title, milestone.description);
    expect(story.single.note, 'She did it!');
    expect(story.single.imagePath, isNotNull);
  });

  test('keeps a standalone memory as its own entry', () async {
    await addPhoto(
        BabyBook.standaloneReference, '2025-05-01', DateTime(2025, 5, 1),
        caption: 'First real smile');

    final story = await BabyBook.load(profileId);

    expect(story.single.kind, BabyBookEntryKind.photo);
    expect(story.single.note, 'First real smile');
  });

  test('leaves completed activities out', () async {
    // There is one nearly every day; 300 identical lines would bury the first
    // steps, and the activity history screen already covers them.
    await db.saveCompletion(ActivityCompletion(
      profileId: profileId,
      activityId: 'act_0_1',
      dateKey: '2025-03-02',
      completedAt: DateTime(2025, 3, 2),
    ));
    await addMilestone(DateTime(2025, 3, 1));

    final story = await BabyBook.load(profileId);

    expect(story, hasLength(1));
    expect(story.single.kind, BabyBookEntryKind.milestone);
  });

  test('names every growth metric with its unit', () async {
    await addGrowth(GrowthMetric.weight, 7.0, '2025-04-01');
    await addGrowth(GrowthMetric.height, 68.5, '2025-04-02');
    await addGrowth(GrowthMetric.headCircumference, 43.0, '2025-04-03');

    final titles = (await BabyBook.load(profileId)).map((e) => e.title);

    // A trailing ".0" is dropped, so seven kilos reads as "7 kg".
    expect(
        titles,
        containsAll(<String>[
          'Weight: 7 kg',
          'Height / Length: 68.5 cm',
          'Head Circumference: 43 cm',
        ]));
  });

  test('an unknown milestone id reads as something, not an identifier',
      () async {
    // What a backup restored from a newer build looks like.
    await db.saveAchievement(MilestoneAchievement(
      profileId: profileId,
      milestoneId: 'm_from_the_future',
      achievedDate: DateTime(2025, 3, 1),
    ));

    final story = await BabyBook.load(profileId);

    expect(story.single.title, 'A milestone');
    expect(story.single.title, isNot(contains('m_from_the_future')));
  });

  test('is empty for a child with nothing recorded', () async {
    expect(await BabyBook.load(profileId), isEmpty);
  });

  test('is scoped to one child', () async {
    await addMilestone(DateTime(2025, 3, 1));
    final sibling = await db.insertProfile(ChildProfile(
      name: 'Noah',
      dateOfBirth: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    ));

    expect(await BabyBook.load(sibling.id!), isEmpty);
    expect(await BabyBook.load(profileId), hasLength(1));
  });
}
