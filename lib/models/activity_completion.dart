class ActivityCompletion {
  final int? id;
  final int profileId;
  final String activityId;
  final String dateKey; // YYYY-MM-DD
  final DateTime completedAt;

  const ActivityCompletion({
    this.id,
    required this.profileId,
    required this.activityId,
    required this.dateKey,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'profile_id': profileId,
        'activity_id': activityId,
        'date_key': dateKey,
        'completed_at': completedAt.toIso8601String(),
      };

  factory ActivityCompletion.fromMap(Map<String, dynamic> map) => ActivityCompletion(
        id: map['id'] as int?,
        profileId: map['profile_id'] as int,
        activityId: map['activity_id'] as String,
        dateKey: map['date_key'] as String,
        completedAt: DateTime.parse(map['completed_at'] as String),
      );
}
