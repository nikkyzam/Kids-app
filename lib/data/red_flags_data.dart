import '../models/milestone.dart';

class RedFlag {
  final String milestoneId;
  final int redFlagAgeMonths;
  final String concern;
  final MilestoneDomain domain;

  const RedFlag({
    required this.milestoneId,
    required this.redFlagAgeMonths,
    required this.concern,
    required this.domain,
  });
}

/// CDC "Learn the Signs, Act Early" — milestones that warrant a doctor
/// conversation if not achieved by the specified age.
class RedFlagsData {
  static const List<RedFlag> all = [
    // By 2 months
    RedFlag(
        milestoneId: 'm_2_se_1',
        redFlagAgeMonths: 2,
        domain: MilestoneDomain.socialEmotional,
        concern: "Doesn't smile at people"),
    RedFlag(
        milestoneId: 'm_2_la_1',
        redFlagAgeMonths: 2,
        domain: MilestoneDomain.language,
        concern: "Doesn't make cooing or gurgling sounds"),
    RedFlag(
        milestoneId: 'm_2_cg_2',
        redFlagAgeMonths: 2,
        domain: MilestoneDomain.cognitive,
        concern: "Doesn't follow moving objects with eyes"),

    // By 4 months
    RedFlag(
        milestoneId: 'm_4_se_1',
        redFlagAgeMonths: 4,
        domain: MilestoneDomain.socialEmotional,
        concern: "Doesn't smile spontaneously at people"),
    RedFlag(
        milestoneId: 'm_4_la_1',
        redFlagAgeMonths: 4,
        domain: MilestoneDomain.language,
        concern: "Doesn't babble or make sounds"),
    RedFlag(
        milestoneId: 'm_4_gm_1',
        redFlagAgeMonths: 4,
        domain: MilestoneDomain.grossMotor,
        concern: "Can't hold head steady"),

    // By 6 months
    RedFlag(
        milestoneId: 'm_6_la_1',
        redFlagAgeMonths: 6,
        domain: MilestoneDomain.language,
        concern: "Doesn't respond to own name"),
    RedFlag(
        milestoneId: 'm_6_se_1',
        redFlagAgeMonths: 6,
        domain: MilestoneDomain.socialEmotional,
        concern: "Doesn't recognise familiar faces"),
    RedFlag(
        milestoneId: 'm_6_gm_1',
        redFlagAgeMonths: 6,
        domain: MilestoneDomain.grossMotor,
        concern: "Doesn't roll over in either direction"),

    // By 9 months
    RedFlag(
        milestoneId: 'm_9_la_2',
        redFlagAgeMonths: 9,
        domain: MilestoneDomain.language,
        concern: "Doesn't babble (ba, da, ma sounds)"),
    RedFlag(
        milestoneId: 'm_9_cg_1',
        redFlagAgeMonths: 9,
        domain: MilestoneDomain.cognitive,
        concern: "Doesn't look for hidden objects"),
    RedFlag(
        milestoneId: 'm_9_se_1',
        redFlagAgeMonths: 9,
        domain: MilestoneDomain.socialEmotional,
        concern: "Shows no attachment to caregivers"),

    // By 12 months
    RedFlag(
        milestoneId: 'm_12_la_1',
        redFlagAgeMonths: 12,
        domain: MilestoneDomain.language,
        concern: "Doesn't say 'mama' or 'dada' with meaning"),
    RedFlag(
        milestoneId: 'm_12_la_2',
        redFlagAgeMonths: 12,
        domain: MilestoneDomain.language,
        concern: "Doesn't use gestures like waving or pointing"),
    RedFlag(
        milestoneId: 'm_12_gm_1',
        redFlagAgeMonths: 12,
        domain: MilestoneDomain.grossMotor,
        concern: "Can't pull up to stand"),

    // By 18 months
    RedFlag(
        milestoneId: 'm_18_la_1',
        redFlagAgeMonths: 18,
        domain: MilestoneDomain.language,
        concern: "Doesn't say at least 6 words"),
    RedFlag(
        milestoneId: 'm_18_gm_1',
        redFlagAgeMonths: 18,
        domain: MilestoneDomain.grossMotor,
        concern: "Can't walk independently"),
    RedFlag(
        milestoneId: 'm_18_se_1',
        redFlagAgeMonths: 18,
        domain: MilestoneDomain.socialEmotional,
        concern: "Doesn't notice or care when caregiver leaves"),

    // By 24 months
    RedFlag(
        milestoneId: 'm_24_la_1',
        redFlagAgeMonths: 24,
        domain: MilestoneDomain.language,
        concern: "Doesn't use 2-word phrases"),
    RedFlag(
        milestoneId: 'm_24_cg_1',
        redFlagAgeMonths: 24,
        domain: MilestoneDomain.cognitive,
        concern: "Doesn't follow simple 2-step instructions"),
  ];

  /// Returns red flags relevant to the child's current age (past due but not achieved).
  static List<RedFlag> activeFor(int ageMonths, Set<String> achievedIds) {
    return all
        .where((rf) =>
            ageMonths >= rf.redFlagAgeMonths &&
            !achievedIds.contains(rf.milestoneId))
        .toList();
  }
}
