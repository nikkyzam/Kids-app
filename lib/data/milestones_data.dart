import '../models/milestone.dart';

class MilestonesData {
  MilestonesData._();

  static const List<Milestone> all = [
    // ─── 2 Months ─────────────────────────────────────────────────────────────
    Milestone(id: 'm_2_gm_1', ageGroupMonths: 2, domain: MilestoneDomain.grossMotor, description: 'Holds head up momentarily when on tummy'),
    Milestone(id: 'm_2_gm_2', ageGroupMonths: 2, domain: MilestoneDomain.grossMotor, description: 'Moves both arms and legs equally'),
    Milestone(id: 'm_2_fm_1', ageGroupMonths: 2, domain: MilestoneDomain.fineMotor, description: 'Opens and closes hands in response to stimulation'),
    Milestone(id: 'm_2_la_1', ageGroupMonths: 2, domain: MilestoneDomain.language, description: 'Makes cooing and gurgling sounds'),
    Milestone(id: 'm_2_la_2', ageGroupMonths: 2, domain: MilestoneDomain.language, description: 'Turns head toward familiar sounds'),
    Milestone(id: 'm_2_cg_1', ageGroupMonths: 2, domain: MilestoneDomain.cognitive, description: 'Pays attention to faces'),
    Milestone(id: 'm_2_cg_2', ageGroupMonths: 2, domain: MilestoneDomain.cognitive, description: 'Follows moving objects with eyes'),
    Milestone(id: 'm_2_se_1', ageGroupMonths: 2, domain: MilestoneDomain.socialEmotional, description: 'Begins to smile at people (social smile)'),
    Milestone(id: 'm_2_se_2', ageGroupMonths: 2, domain: MilestoneDomain.socialEmotional, description: 'Calms down when spoken to or picked up'),

    // ─── 4 Months ─────────────────────────────────────────────────────────────
    Milestone(id: 'm_4_gm_1', ageGroupMonths: 4, domain: MilestoneDomain.grossMotor, description: 'Holds head steady without support when held upright'),
    Milestone(id: 'm_4_gm_2', ageGroupMonths: 4, domain: MilestoneDomain.grossMotor, description: 'Pushes down on legs when feet are on a firm surface'),
    Milestone(id: 'm_4_fm_1', ageGroupMonths: 4, domain: MilestoneDomain.fineMotor, description: 'Brings hands to mouth'),
    Milestone(id: 'm_4_fm_2', ageGroupMonths: 4, domain: MilestoneDomain.fineMotor, description: 'Bats at dangling objects'),
    Milestone(id: 'm_4_la_1', ageGroupMonths: 4, domain: MilestoneDomain.language, description: 'Babbles with expression using varied sounds'),
    Milestone(id: 'm_4_la_2', ageGroupMonths: 4, domain: MilestoneDomain.language, description: 'Copies sounds they hear (e.g., coos, ahhs)'),
    Milestone(id: 'm_4_cg_1', ageGroupMonths: 4, domain: MilestoneDomain.cognitive, description: 'Recognises familiar people at a distance'),
    Milestone(id: 'm_4_cg_2', ageGroupMonths: 4, domain: MilestoneDomain.cognitive, description: 'Shows curiosity about things and tries to get them'),
    Milestone(id: 'm_4_se_1', ageGroupMonths: 4, domain: MilestoneDomain.socialEmotional, description: 'Smiles spontaneously, especially at people'),
    Milestone(id: 'm_4_se_2', ageGroupMonths: 4, domain: MilestoneDomain.socialEmotional, description: 'Enjoys playing with people and may cry when play stops'),

    // ─── 6 Months ─────────────────────────────────────────────────────────────
    Milestone(id: 'm_6_gm_1', ageGroupMonths: 6, domain: MilestoneDomain.grossMotor, description: 'Rolls over in both directions (front to back and back to front)'),
    Milestone(id: 'm_6_gm_2', ageGroupMonths: 6, domain: MilestoneDomain.grossMotor, description: 'Begins to sit without support for short periods'),
    Milestone(id: 'm_6_fm_1', ageGroupMonths: 6, domain: MilestoneDomain.fineMotor, description: 'Passes objects from one hand to the other'),
    Milestone(id: 'm_6_fm_2', ageGroupMonths: 6, domain: MilestoneDomain.fineMotor, description: 'Rakes objects toward themselves using fingers'),
    Milestone(id: 'm_6_la_1', ageGroupMonths: 6, domain: MilestoneDomain.language, description: 'Responds to own name by looking up'),
    Milestone(id: 'm_6_la_2', ageGroupMonths: 6, domain: MilestoneDomain.language, description: 'Makes sounds to show joy and displeasure'),
    Milestone(id: 'm_6_cg_1', ageGroupMonths: 6, domain: MilestoneDomain.cognitive, description: 'Explores objects with hands and mouth'),
    Milestone(id: 'm_6_cg_2', ageGroupMonths: 6, domain: MilestoneDomain.cognitive, description: 'Looks around at nearby things with curiosity'),
    Milestone(id: 'm_6_se_1', ageGroupMonths: 6, domain: MilestoneDomain.socialEmotional, description: 'Knows familiar faces and begins to recognise strangers'),
    Milestone(id: 'm_6_se_2', ageGroupMonths: 6, domain: MilestoneDomain.socialEmotional, description: 'Likes to play with others, especially parents'),

    // ─── 9 Months ─────────────────────────────────────────────────────────────
    Milestone(id: 'm_9_gm_1', ageGroupMonths: 9, domain: MilestoneDomain.grossMotor, description: 'Stands while holding on to something'),
    Milestone(id: 'm_9_gm_2', ageGroupMonths: 9, domain: MilestoneDomain.grossMotor, description: 'Can pull to a sitting position from lying down'),
    Milestone(id: 'm_9_fm_1', ageGroupMonths: 9, domain: MilestoneDomain.fineMotor, description: 'Picks up small objects using pincer grip (thumb and index finger)'),
    Milestone(id: 'm_9_fm_2', ageGroupMonths: 9, domain: MilestoneDomain.fineMotor, description: 'Bangs objects together intentionally'),
    Milestone(id: 'm_9_la_1', ageGroupMonths: 9, domain: MilestoneDomain.language, description: 'Understands the word "no"'),
    Milestone(id: 'm_9_la_2', ageGroupMonths: 9, domain: MilestoneDomain.language, description: 'Makes many different consonant sounds (ba, da, ma)'),
    Milestone(id: 'm_9_cg_1', ageGroupMonths: 9, domain: MilestoneDomain.cognitive, description: 'Looks for partially hidden objects'),
    Milestone(id: 'm_9_cg_2', ageGroupMonths: 9, domain: MilestoneDomain.cognitive, description: 'Watches the path of something as it falls'),
    Milestone(id: 'm_9_se_1', ageGroupMonths: 9, domain: MilestoneDomain.socialEmotional, description: 'May be clingy with familiar adults (separation anxiety begins)'),
    Milestone(id: 'm_9_se_2', ageGroupMonths: 9, domain: MilestoneDomain.socialEmotional, description: 'Has favourite toys and shows preferences'),

    // ─── 12 Months ────────────────────────────────────────────────────────────
    Milestone(id: 'm_12_gm_1', ageGroupMonths: 12, domain: MilestoneDomain.grossMotor, description: 'Pulls up to stand and may take first independent steps'),
    Milestone(id: 'm_12_gm_2', ageGroupMonths: 12, domain: MilestoneDomain.grossMotor, description: 'Gets to sitting position without help'),
    Milestone(id: 'm_12_fm_1', ageGroupMonths: 12, domain: MilestoneDomain.fineMotor, description: 'Puts objects into a container and takes them out'),
    Milestone(id: 'm_12_fm_2', ageGroupMonths: 12, domain: MilestoneDomain.fineMotor, description: 'Uses thumb and forefinger to pick up very small objects'),
    Milestone(id: 'm_12_la_1', ageGroupMonths: 12, domain: MilestoneDomain.language, description: 'Says "mama" and "dada" with meaning'),
    Milestone(id: 'm_12_la_2', ageGroupMonths: 12, domain: MilestoneDomain.language, description: 'Uses simple gestures (waves bye-bye, shakes head for "no")'),
    Milestone(id: 'm_12_cg_1', ageGroupMonths: 12, domain: MilestoneDomain.cognitive, description: 'Finds hidden objects under a cover'),
    Milestone(id: 'm_12_cg_2', ageGroupMonths: 12, domain: MilestoneDomain.cognitive, description: 'Explores objects in many different ways (shaking, banging, throwing)'),
    Milestone(id: 'm_12_se_1', ageGroupMonths: 12, domain: MilestoneDomain.socialEmotional, description: 'Shows shy or anxious behaviour with strangers'),
    Milestone(id: 'm_12_se_2', ageGroupMonths: 12, domain: MilestoneDomain.socialEmotional, description: 'Repeats actions to get attention'),

    // ─── 15 Months ────────────────────────────────────────────────────────────
    Milestone(id: 'm_15_gm_1', ageGroupMonths: 15, domain: MilestoneDomain.grossMotor, description: 'Walks alone'),
    Milestone(id: 'm_15_gm_2', ageGroupMonths: 15, domain: MilestoneDomain.grossMotor, description: 'Can squat down and stand back up'),
    Milestone(id: 'm_15_fm_1', ageGroupMonths: 15, domain: MilestoneDomain.fineMotor, description: 'Stacks two blocks'),
    Milestone(id: 'm_15_fm_2', ageGroupMonths: 15, domain: MilestoneDomain.fineMotor, description: 'Scribbles with a crayon'),
    Milestone(id: 'm_15_la_1', ageGroupMonths: 15, domain: MilestoneDomain.language, description: 'Says several single words (3 or more)'),
    Milestone(id: 'm_15_la_2', ageGroupMonths: 15, domain: MilestoneDomain.language, description: 'Points to show others something interesting'),
    Milestone(id: 'm_15_cg_1', ageGroupMonths: 15, domain: MilestoneDomain.cognitive, description: 'Explores alone but with parent close by'),
    Milestone(id: 'm_15_cg_2', ageGroupMonths: 15, domain: MilestoneDomain.cognitive, description: 'Hands book to adult to be read'),
    Milestone(id: 'm_15_se_1', ageGroupMonths: 15, domain: MilestoneDomain.socialEmotional, description: 'Points to show needs and desires'),
    Milestone(id: 'm_15_se_2', ageGroupMonths: 15, domain: MilestoneDomain.socialEmotional, description: 'Shows affection to familiar people'),

    // ─── 18 Months ────────────────────────────────────────────────────────────
    Milestone(id: 'm_18_gm_1', ageGroupMonths: 18, domain: MilestoneDomain.grossMotor, description: 'Walks up steps with help'),
    Milestone(id: 'm_18_gm_2', ageGroupMonths: 18, domain: MilestoneDomain.grossMotor, description: 'Kicks a ball forward'),
    Milestone(id: 'm_18_fm_1', ageGroupMonths: 18, domain: MilestoneDomain.fineMotor, description: 'Stacks four or more blocks'),
    Milestone(id: 'm_18_fm_2', ageGroupMonths: 18, domain: MilestoneDomain.fineMotor, description: 'Turns pages of a book (may be several at once)'),
    Milestone(id: 'm_18_la_1', ageGroupMonths: 18, domain: MilestoneDomain.language, description: 'Uses at least 6–10 words spontaneously'),
    Milestone(id: 'm_18_la_2', ageGroupMonths: 18, domain: MilestoneDomain.language, description: 'Points to at least one body part when named'),
    Milestone(id: 'm_18_cg_1', ageGroupMonths: 18, domain: MilestoneDomain.cognitive, description: 'Knows what ordinary objects are for (phone, brush, spoon)'),
    Milestone(id: 'm_18_cg_2', ageGroupMonths: 18, domain: MilestoneDomain.cognitive, description: 'Points to get the attention of others'),
    Milestone(id: 'm_18_se_1', ageGroupMonths: 18, domain: MilestoneDomain.socialEmotional, description: 'Likes to hand things to others as play'),
    Milestone(id: 'm_18_se_2', ageGroupMonths: 18, domain: MilestoneDomain.socialEmotional, description: 'May have temper tantrums'),

    // ─── 24 Months ────────────────────────────────────────────────────────────
    Milestone(id: 'm_24_gm_1', ageGroupMonths: 24, domain: MilestoneDomain.grossMotor, description: 'Walks up and down stairs, holding rail'),
    Milestone(id: 'm_24_gm_2', ageGroupMonths: 24, domain: MilestoneDomain.grossMotor, description: 'Runs fairly well'),
    Milestone(id: 'm_24_fm_1', ageGroupMonths: 24, domain: MilestoneDomain.fineMotor, description: 'Builds tower of 4 or more blocks'),
    Milestone(id: 'm_24_fm_2', ageGroupMonths: 24, domain: MilestoneDomain.fineMotor, description: 'Copies a straight line drawn by adult'),
    Milestone(id: 'm_24_la_1', ageGroupMonths: 24, domain: MilestoneDomain.language, description: 'Uses 2-word phrases ("more milk", "daddy go")'),
    Milestone(id: 'm_24_la_2', ageGroupMonths: 24, domain: MilestoneDomain.language, description: 'Points to pictures in books when named'),
    Milestone(id: 'm_24_cg_1', ageGroupMonths: 24, domain: MilestoneDomain.cognitive, description: 'Follows simple 2-step instructions'),
    Milestone(id: 'm_24_cg_2', ageGroupMonths: 24, domain: MilestoneDomain.cognitive, description: 'Sorts objects by shape or colour'),
    Milestone(id: 'm_24_se_1', ageGroupMonths: 24, domain: MilestoneDomain.socialEmotional, description: 'Shows increasingly independent behaviour'),
    Milestone(id: 'm_24_se_2', ageGroupMonths: 24, domain: MilestoneDomain.socialEmotional, description: 'Gets excited when around other children'),

    // ─── 30 Months ────────────────────────────────────────────────────────────
    Milestone(id: 'm_30_gm_1', ageGroupMonths: 30, domain: MilestoneDomain.grossMotor, description: 'Jumps in place with both feet'),
    Milestone(id: 'm_30_gm_2', ageGroupMonths: 30, domain: MilestoneDomain.grossMotor, description: 'Throws a ball overhand'),
    Milestone(id: 'm_30_fm_1', ageGroupMonths: 30, domain: MilestoneDomain.fineMotor, description: 'Turns book pages one at a time'),
    Milestone(id: 'm_30_fm_2', ageGroupMonths: 30, domain: MilestoneDomain.fineMotor, description: 'Holds pencil in adult grip (still developing)'),
    Milestone(id: 'm_30_la_1', ageGroupMonths: 30, domain: MilestoneDomain.language, description: 'Uses 2–3 word sentences regularly'),
    Milestone(id: 'm_30_la_2', ageGroupMonths: 30, domain: MilestoneDomain.language, description: 'Names items in picture books'),
    Milestone(id: 'm_30_cg_1', ageGroupMonths: 30, domain: MilestoneDomain.cognitive, description: 'Plays make-believe (feeds doll, talks to stuffed animal)'),
    Milestone(id: 'm_30_cg_2', ageGroupMonths: 30, domain: MilestoneDomain.cognitive, description: 'Understands concept of "two" vs "many"'),
    Milestone(id: 'm_30_se_1', ageGroupMonths: 30, domain: MilestoneDomain.socialEmotional, description: 'Shows concern for a crying friend'),
    Milestone(id: 'm_30_se_2', ageGroupMonths: 30, domain: MilestoneDomain.socialEmotional, description: 'Plays alongside (parallel play) rather than with other children'),

    // ─── 36 Months ────────────────────────────────────────────────────────────
    Milestone(id: 'm_36_gm_1', ageGroupMonths: 36, domain: MilestoneDomain.grossMotor, description: 'Climbs well and runs easily'),
    Milestone(id: 'm_36_gm_2', ageGroupMonths: 36, domain: MilestoneDomain.grossMotor, description: 'Pedals a tricycle'),
    Milestone(id: 'm_36_fm_1', ageGroupMonths: 36, domain: MilestoneDomain.fineMotor, description: 'Copies a circle'),
    Milestone(id: 'm_36_fm_2', ageGroupMonths: 36, domain: MilestoneDomain.fineMotor, description: 'Builds tower of 6 or more blocks'),
    Milestone(id: 'm_36_la_1', ageGroupMonths: 36, domain: MilestoneDomain.language, description: 'Speaks in sentences of 3 or more words'),
    Milestone(id: 'm_36_la_2', ageGroupMonths: 36, domain: MilestoneDomain.language, description: 'Follows 3-step instructions'),
    Milestone(id: 'm_36_cg_1', ageGroupMonths: 36, domain: MilestoneDomain.cognitive, description: 'Understands "same" and "different" concepts'),
    Milestone(id: 'm_36_cg_2', ageGroupMonths: 36, domain: MilestoneDomain.cognitive, description: 'Plays make-believe with dolls, animals, and people'),
    Milestone(id: 'm_36_se_1', ageGroupMonths: 36, domain: MilestoneDomain.socialEmotional, description: 'Shows a wide range of emotions'),
    Milestone(id: 'm_36_se_2', ageGroupMonths: 36, domain: MilestoneDomain.socialEmotional, description: 'Can separate from parents more easily than at 2 years'),
  ];

  static List<int> get ageGroups => [2, 4, 6, 9, 12, 15, 18, 24, 30, 36];

  static List<Milestone> forAgeGroup(int months) =>
      all.where((m) => m.ageGroupMonths == months).toList();

  static List<Milestone> filterByDomain(List<Milestone> milestones, MilestoneDomain? domain) {
    if (domain == null) return milestones;
    return milestones.where((m) => m.domain == domain).toList();
  }
}
