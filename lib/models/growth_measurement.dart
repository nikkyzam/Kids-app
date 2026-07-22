enum GrowthMetric { weight, height, headCircumference }

extension GrowthMetricX on GrowthMetric {
  String get label {
    switch (this) {
      case GrowthMetric.weight:
        return 'Weight';
      case GrowthMetric.height:
        return 'Height / Length';
      case GrowthMetric.headCircumference:
        return 'Head Circumference';
    }
  }

  String get unit => this == GrowthMetric.weight ? 'kg' : 'cm';
  String get unitImperial => this == GrowthMetric.weight ? 'lbs' : 'in';
}

class GrowthMeasurement {
  final int? id;
  final int profileId;
  final GrowthMetric metric;
  final double value; // always stored in metric (kg / cm)
  final String measuredOn; // yyyy-MM-dd
  final String? notes;

  const GrowthMeasurement({
    this.id,
    required this.profileId,
    required this.metric,
    required this.value,
    required this.measuredOn,
    this.notes,
  });

  DateTime get measuredOnDate => DateTime.parse(measuredOn);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'metric': metric.name,
        'value': value,
        'measured_on': measuredOn,
        'notes': notes,
      };

  static GrowthMeasurement fromMap(Map<String, dynamic> map) =>
      GrowthMeasurement(
        id: map['id'] as int?,
        profileId: map['profile_id'] as int,
        metric: GrowthMetric.values.firstWhere((m) => m.name == map['metric']),
        value: (map['value'] as num).toDouble(),
        measuredOn: map['measured_on'] as String,
        notes: map['notes'] as String?,
      );
}
