enum SkillCategory {
  grossMotor,
  fineMotor,
  language,
  cognitive,
  socialEmotional,
  sensory;

  String get label {
    switch (this) {
      case SkillCategory.grossMotor:
        return 'Gross Motor';
      case SkillCategory.fineMotor:
        return 'Fine Motor';
      case SkillCategory.language:
        return 'Language';
      case SkillCategory.cognitive:
        return 'Cognitive';
      case SkillCategory.socialEmotional:
        return 'Social & Emotional';
      case SkillCategory.sensory:
        return 'Sensory';
    }
  }
}

class PlayActivity {
  final String id;
  final int ageBandMinWeeks;
  final int ageBandMaxWeeks;
  final String title;
  final int durationMins;
  final List<String> materials;
  final List<String> instructions;
  final String skillTargeted;
  final SkillCategory skillCategory;

  const PlayActivity({
    required this.id,
    required this.ageBandMinWeeks,
    required this.ageBandMaxWeeks,
    required this.title,
    required this.durationMins,
    required this.materials,
    required this.instructions,
    required this.skillTargeted,
    required this.skillCategory,
  });

  bool get isInFreeTier => ageBandMinWeeks < 4;
}
