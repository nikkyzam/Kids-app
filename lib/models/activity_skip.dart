/// Why a parent set an activity aside. Free-form reasons are deliberately not
/// accepted: a fixed set keeps the record useful for choosing a replacement
/// without turning the app into a place where a parent writes about their
/// child and then wonders where that text went.
enum SkipReason {
  tooEasy,
  tooHard,
  materialsUnavailable,
  notRightNow;

  String get label {
    switch (this) {
      case SkipReason.tooEasy:
        return 'Too easy';
      case SkipReason.tooHard:
        return 'Too hard';
      case SkipReason.materialsUnavailable:
        return "Don't have the materials";
      case SkipReason.notRightNow:
        return 'Not right now';
    }
  }

  static SkipReason? fromName(String? name) {
    if (name == null) return null;
    for (final r in SkipReason.values) {
      if (r.name == name) return r;
    }
    return null;
  }
}

class ActivitySkip {
  final int? id;
  final int profileId;
  final String activityId;
  final SkipReason? reason;
  final DateTime skippedAt;

  const ActivitySkip({
    this.id,
    required this.profileId,
    required this.activityId,
    this.reason,
    required this.skippedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'profile_id': profileId,
        'activity_id': activityId,
        'reason': reason?.name,
        'skipped_at': skippedAt.toIso8601String(),
      };

  factory ActivitySkip.fromMap(Map<String, dynamic> map) => ActivitySkip(
        id: map['id'] as int?,
        profileId: map['profile_id'] as int,
        activityId: map['activity_id'] as String,
        reason: SkipReason.fromName(map['reason'] as String?),
        skippedAt: DateTime.parse(map['skipped_at'] as String),
      );
}
