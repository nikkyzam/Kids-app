class PhotoMemory {
  final int? id;
  final int profileId;
  final String referenceType; // 'activity' | 'milestone'
  final String referenceId; // date_key for activity, milestone_id for milestone
  final String imagePath;
  final String? caption;
  final String capturedAt;

  const PhotoMemory({
    this.id,
    required this.profileId,
    required this.referenceType,
    required this.referenceId,
    required this.imagePath,
    this.caption,
    required this.capturedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'image_path': imagePath,
        'caption': caption,
        'captured_at': capturedAt,
      };

  static PhotoMemory fromMap(Map<String, dynamic> map) => PhotoMemory(
        id: map['id'] as int?,
        profileId: map['profile_id'] as int,
        referenceType: map['reference_type'] as String,
        referenceId: map['reference_id'] as String,
        imagePath: map['image_path'] as String,
        caption: map['caption'] as String?,
        capturedAt: map['captured_at'] as String,
      );

  DateTime get capturedAtDate => DateTime.parse(capturedAt);
}
