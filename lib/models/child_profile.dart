class ChildProfile {
  final int? id;
  final String? uuid;
  final String name;
  final DateTime dateOfBirth;
  final DateTime createdAt;

  const ChildProfile({
    this.id,
    this.uuid,
    required this.name,
    required this.dateOfBirth,
    required this.createdAt,
  });

  int get ageInDays => DateTime.now().difference(dateOfBirth).inDays;

  int get ageInWeeks => ageInDays ~/ 7;

  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (now.day < dateOfBirth.day) months--;
    return months.clamp(0, 999);
  }

  // Returns age in weeks (0–26 weeks) then months (6–36+ months)
  String get displayAge {
    if (ageInWeeks < 4) return '$ageInWeeks week${ageInWeeks == 1 ? '' : 's'}';
    if (ageInWeeks < 26) return '${ageInWeeks} weeks';
    final m = ageInMonths;
    if (m < 24) return '$m month${m == 1 ? '' : 's'}';
    final years = m ~/ 12;
    final rem = m % 12;
    if (rem == 0) return '$years year${years == 1 ? '' : 's'}';
    return '$years yr $rem mo';
  }

  // Age in whole weeks capped at 156 weeks (3 years)
  int get ageBandWeeks => ageInWeeks.clamp(0, 156);

  ChildProfile copyWith({int? id, String? uuid, String? name, DateTime? dateOfBirth}) => ChildProfile(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ChildProfile.fromMap(Map<String, dynamic> map) => ChildProfile(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        name: map['name'] as String,
        dateOfBirth: DateTime.parse(map['date_of_birth'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
