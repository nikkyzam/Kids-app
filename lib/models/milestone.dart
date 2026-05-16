enum MilestoneDomain {
  grossMotor,
  fineMotor,
  language,
  cognitive,
  socialEmotional;

  String get label {
    switch (this) {
      case MilestoneDomain.grossMotor: return 'Gross Motor';
      case MilestoneDomain.fineMotor: return 'Fine Motor';
      case MilestoneDomain.language: return 'Language';
      case MilestoneDomain.cognitive: return 'Cognitive';
      case MilestoneDomain.socialEmotional: return 'Social & Emotional';
    }
  }
}

class Milestone {
  final String id;
  final int ageGroupMonths;
  final MilestoneDomain domain;
  final String description;

  const Milestone({
    required this.id,
    required this.ageGroupMonths,
    required this.domain,
    required this.description,
  });
}
