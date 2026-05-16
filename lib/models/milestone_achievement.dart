class MilestoneAchievement {
  final int? id;
  final int profileId;
  final String milestoneId;
  final DateTime achievedDate;
  final String? notes;

  const MilestoneAchievement({
    this.id,
    required this.profileId,
    required this.milestoneId,
    required this.achievedDate,
    this.notes,
  });

  MilestoneAchievement copyWith({String? notes}) => MilestoneAchievement(
        id: id,
        profileId: profileId,
        milestoneId: milestoneId,
        achievedDate: achievedDate,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'profile_id': profileId,
        'milestone_id': milestoneId,
        'achieved_date': achievedDate.toIso8601String(),
        'notes': notes,
      };

  factory MilestoneAchievement.fromMap(Map<String, dynamic> map) => MilestoneAchievement(
        id: map['id'] as int?,
        profileId: map['profile_id'] as int,
        milestoneId: map['milestone_id'] as String,
        achievedDate: DateTime.parse(map['achieved_date'] as String),
        notes: map['notes'] as String?,
      );
}
