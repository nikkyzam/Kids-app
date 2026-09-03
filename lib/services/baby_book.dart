import '../data/database_helper.dart';
import '../data/milestones_data.dart';
import '../models/growth_measurement.dart';
import '../models/milestone_achievement.dart';
import '../models/photo_memory.dart';

enum BabyBookEntryKind { photo, milestone, growth }

/// One line in the baby book.
///
/// Everything is flattened to the same shape — a date, a heading, an optional
/// note, an optional image — so the book reads as one story rather than three
/// tables stapled together.
class BabyBookEntry {
  final BabyBookEntryKind kind;
  final DateTime date;
  final String title;
  final String? detail;
  final String? note;
  final String? imagePath;
  final PhotoMemory? photo;

  const BabyBookEntry({
    required this.kind,
    required this.date,
    required this.title,
    this.detail,
    this.note,
    this.imagePath,
    this.photo,
  });
}

/// Gathers a child's photos, milestones and measurements into one
/// chronological story.
///
/// Completed activities are deliberately left out. There is one nearly every
/// day, and a book where 300 identical "did today's activity" lines bury the
/// first steps is not a keepsake — the activity history screen is where that
/// belongs.
class BabyBook {
  BabyBook._();

  /// Reference type for a memory that stands on its own — a first smile, a
  /// nap in a sunbeam — rather than hanging off an activity or a milestone.
  static const String standaloneReference = 'moment';

  static Future<List<BabyBookEntry>> load(int profileId) async {
    final db = DatabaseHelper.instance;

    final photos = await db.getPhotos(profileId);
    final achievements = await db.getAchievements(profileId);
    final measurements = <GrowthMeasurement>[];
    for (final metric in GrowthMetric.values) {
      measurements.addAll(await db.getGrowthMeasurements(profileId, metric));
    }

    // A photo attached to a milestone is shown on the milestone's own entry,
    // so it is not also listed on its own — one moment, one line.
    final milestonePhotos = <String, PhotoMemory>{};
    for (final photo in photos) {
      if (photo.referenceType == 'milestone') {
        milestonePhotos.putIfAbsent(photo.referenceId, () => photo);
      }
    }

    final entries = <BabyBookEntry>[];

    for (final photo in photos) {
      if (photo.referenceType == 'milestone' &&
          milestonePhotos[photo.referenceId] == photo) {
        continue;
      }
      entries.add(BabyBookEntry(
        kind: BabyBookEntryKind.photo,
        date: photo.capturedAtDate,
        title: _photoTitle(photo),
        note: photo.caption,
        imagePath: photo.imagePath,
        photo: photo,
      ));
    }

    for (final achievement in achievements) {
      entries.add(BabyBookEntry(
        kind: BabyBookEntryKind.milestone,
        date: achievement.achievedDate,
        title: _milestoneTitle(achievement),
        detail: 'Milestone',
        note: achievement.notes,
        imagePath: milestonePhotos[achievement.milestoneId]?.imagePath,
        photo: milestonePhotos[achievement.milestoneId],
      ));
    }

    for (final measurement in measurements) {
      entries.add(BabyBookEntry(
        kind: BabyBookEntryKind.growth,
        date: measurement.measuredOnDate,
        title: '${measurement.metric.label}: '
            '${_trim(measurement.value)} ${measurement.metric.unit}',
        detail: 'Growth',
        note: measurement.notes,
      ));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static String _photoTitle(PhotoMemory photo) {
    switch (photo.referenceType) {
      case 'milestone':
        final milestone = MilestonesData.all
            .where((m) => m.id == photo.referenceId)
            .firstOrNull;
        return milestone?.description ?? 'A milestone';
      case 'activity':
        return 'A moment from play';
      default:
        return 'A moment';
    }
  }

  static String _milestoneTitle(MilestoneAchievement achievement) {
    final milestone = MilestonesData.all
        .where((m) => m.id == achievement.milestoneId)
        .firstOrNull;
    // A milestone id from a newer build, restored into an older one, must read
    // as something rather than as a raw identifier.
    return milestone?.description ?? 'A milestone';
  }

  /// Drops a trailing ".0" so 7 kilos reads as "7" rather than "7.0", while
  /// 7.4 keeps its decimal.
  static String _trim(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }
}
