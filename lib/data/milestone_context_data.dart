import '../models/milestone.dart';
import 'red_flags_data.dart';

/// What a parent can actually see for a milestone, and when it is worth
/// mentioning to a doctor.
///
/// The ledger on its own is a checklist: a row is either ticked or it is not,
/// and an untickable row reads as a verdict. These two notes give the row back
/// its context — what the behaviour looks like in a real living room, and the
/// fact that not seeing it yet is usually nothing. Neither is clinical advice
/// and neither ever tells a parent what is wrong; the second one only ever
/// says "mention it", because that is the whole of what an app can honestly
/// say.
class MilestoneContext {
  /// A concrete, observable description — what the parent would notice.
  final String whatToLookFor;

  /// When to raise it with a pediatrician.
  final String whenToTalk;

  /// True when the CDC's "Learn the Signs, Act Early" programme lists this
  /// milestone as one to discuss if it has not appeared by a given age. The UI
  /// uses this only to choose wording, never to raise an alarm.
  final bool isCdcActEarly;

  const MilestoneContext({
    required this.whatToLookFor,
    required this.whenToTalk,
    required this.isCdcActEarly,
  });

  static MilestoneContext? forMilestone(Milestone milestone) =>
      forId(milestone.id);

  static MilestoneContext? forId(String milestoneId) {
    final look = _whatToLookFor[milestoneId];
    if (look == null) return null;
    return MilestoneContext(
      whatToLookFor: look,
      whenToTalk: _whenToTalk(milestoneId),
      isCdcActEarly: _actEarlyAgeFor(milestoneId) != null,
    );
  }

  static int? _actEarlyAgeFor(String milestoneId) {
    for (final flag in RedFlagsData.all) {
      if (flag.milestoneId == milestoneId) return flag.redFlagAgeMonths;
    }
    return null;
  }

  static String _whenToTalk(String milestoneId) {
    final actEarlyAge = _actEarlyAgeFor(milestoneId);
    if (actEarlyAge != null) {
      return 'The CDC lists this as one to bring up if you are not seeing it '
          'by $actEarlyAge months. Bringing it up early is routine, not '
          'alarming — it is what check-ups are for.';
    }
    return 'Ranges here are wide, and arriving late at one thing says very '
        'little on its own. If it still has not appeared in a couple of '
        'months, add it to the list for your next check-up.';
  }

  /// Every milestone in [MilestonesData] has an entry here; a test asserts it,
  /// so a new milestone cannot ship as a bare checkbox.
  static const Map<String, String> _whatToLookFor = {
    // ─── 2 months ───────────────────────────────────────────────────────────
    'm_2_gm_1':
        'During tummy time, they lift their forehead off the blanket for a '
            'second or two before setting it down — often turned to one side. '
            'It is a wobble, not a hold.',
    'm_2_gm_2':
        'Watch a nappy change: arms and legs kick and wave freely, and both '
            'sides join in about equally. You are looking for symmetry, not '
            'strength.',
    'm_2_fm_1':
        'Their fists are not clamped shut all the time. Stroke a palm and the '
            'fingers curl around your finger, then open again on their own.',
    'm_2_la_1':
        'Soft open vowels — "aah", "ooh", a wet gurgle — when they are calm '
            'and content, not when they are hungry or upset. Crying does not '
            'count.',
    'm_2_la_2':
        'Speak from the side, out of view: they still, their eyes widen, or '
            'the head swings slowly toward you. A startle to a loud bang is a '
            'reflex, not this.',
    'm_2_cg_1':
        'Held about 30 cm away, they lock onto your face and stay there for '
            'several seconds, studying it, rather than sliding past.',
    'm_2_cg_2':
        'Move your face or a high-contrast card slowly side to side; their '
            'eyes follow it part of the way across, sometimes in little jumps '
            'rather than one smooth sweep.',
    'm_2_se_1':
        'A whole-face smile that answers yours — eyes crinkle too — and comes '
            'back when you smile again. Not the fleeting sleepy smile of the '
            'first weeks.',
    'm_2_se_2':
        'Mid-grizzle, your voice or your arms take the edge off: the crying '
            'eases and the body softens, even if it takes a minute.',

    // ─── 4 months ───────────────────────────────────────────────────────────
    'm_4_gm_1':
        'Held upright against your chest, the head stays put while you walk, '
            'instead of bobbing. Some sway when they turn to look is normal.',
    'm_4_gm_2':
        'Held standing with feet on your lap or the floor, they straighten '
            'their legs and press down, often bouncing.',
    'm_4_fm_1':
        'Hands find the mouth on purpose and stay there — sucking fists and '
            'fingers is the point of the exercise.',
    'm_4_fm_2':
        'Dangle a toy within reach: they swipe at it. Early swings miss by a '
            'long way; the aim is the attempt, not the contact.',
    'm_4_la_1':
        'Long strings of sound with tune in them — rising, falling, getting '
            'louder — as though they are telling you something.',
    'm_4_la_2':
        'You say "aah", pause, and they say something back. The turn-taking '
            'matters more than how closely the sound matches.',
    'm_4_cg_1':
        'You come through the door across the room and they brighten before '
            'you speak — recognition by sight, at a distance.',
    'm_4_cg_2':
        'Something catches their eye and their whole body orients to it: eyes '
            'fix, arms reach, mouth opens.',
    'm_4_se_1':
        'They smile first, without being smiled at — at you, at a sibling, at '
            'a familiar voice arriving.',
    'm_4_se_2':
        'Peekaboo or bouncing gets grins and wriggling, and stopping gets a '
            'complaint. The protest is the milestone.',

    // ─── 6 months ───────────────────────────────────────────────────────────
    'm_6_gm_1':
        'They get themselves from back to front and front to back. Most '
            'babies learn one direction well before the other.',
    'm_6_fm_1':
        'A toy in one hand crosses the midline into the other, on purpose, '
            'rather than being dropped and picked up again.',
    'm_6_gm_2':
        'Sat on the floor, they hold themselves up for a few seconds with '
            'hands down as props, then topple. Propped and brief still counts.',
    'm_6_fm_2':
        'A small toy just out of reach gets dragged in with a sweep of the '
            'whole hand. Fingers work as one — the pincer grip comes later.',
    'm_6_la_1':
        'Their name, said conversationally from across the room, gets a look '
            'up. Test it against a neutral word to be sure it is the name.',
    'm_6_la_2':
        'Two different sounds you can tell apart: a squeal or chuckle when '
            'happy, and a grumbling protest when the toy goes away.',
    'm_6_cg_1':
        'Everything new gets turned over, squeezed and then put in the mouth. '
            'The mouth is a sense organ at this age.',
    'm_6_cg_2':
        'Left alone for a moment they scan the room — the ceiling fan, the '
            'dog, the light — rather than staring at nothing.',
    'm_6_se_1':
        'Warm and easy with the people they live with, and noticeably more '
            'watchful with a visitor. Wariness of strangers is a milestone, '
            'not a problem.',
    'm_6_se_2':
        'They start games as well as joining them: pausing, catching your '
            'eye, and waiting for you to do the thing again.',

    // ─── 9 months ───────────────────────────────────────────────────────────
    'm_9_gm_1':
        'Hands on the sofa or a low table, they hold themselves upright and '
            'take their own weight, even if you helped them up.',
    'm_9_gm_2':
        'From lying down they pull on your hands, a cot rail or the furniture '
            'and haul themselves up to sitting.',
    'm_9_fm_1':
        'A single pea or crumb picked up between the tips of thumb and index '
            'finger, not scooped into the palm.',
    'm_9_fm_2':
        'Two objects, one in each hand, brought together deliberately — and '
            'the noise is clearly the reason they do it again.',
    'm_9_la_1':
        'A firm "no" makes them stop, look at you or hesitate. Understanding '
            'it and obeying it are different milestones.',
    'm_9_la_2':
        'Repeated syllable strings — "bababa", "dadada", "mamama" — with '
            'consonants in them, not just vowels.',
    'm_9_cg_1':
        'Cover half a toy with a cloth and they pull the cloth away. The '
            'visible corner is what makes it findable at this age.',
    'm_9_cg_2':
        'Drop a spoon from the highchair and their eyes go to the floor, '
            'tracking where it went rather than staying on your hand.',
    'm_9_se_1':
        'They want the familiar person, object to being handed over, and '
            'settle again once back. This is attachment working, not a step '
            'backwards.',
    'm_9_se_2':
        'One particular toy or blanket gets sought out, and the wrong one '
            'gets rejected.',

    // ─── 12 months ──────────────────────────────────────────────────────────
    'm_12_gm_1':
        'They pull up on furniture and cruise along it. First steps often '
            'come later than the first birthday and that is well within '
            'normal.',
    'm_12_gm_2':
        'From standing or lying, they get themselves to sitting with no hands '
            'from you.',
    'm_12_fm_1':
        'Blocks into a box and out again, over and over. Taking out usually '
            'comes weeks before putting in.',
    'm_12_fm_2':
        'A neat pinch — thumb against the side or tip of the index finger — '
            'used on something tiny like a piece of cereal.',
    'm_12_la_1':
        '"Mama" or "dada" aimed at the right person, not sprayed at everyone. '
            'Any consistent word for a person counts.',
    'm_12_la_2':
        'Waving at a departure, shaking the head for no, arms up to be '
            'lifted — communication without words.',
    'm_12_cg_1':
        'Hide a toy completely under a cloth while they watch, and they lift '
            'the cloth to get it.',
    'm_12_cg_2':
        'The same object gets shaken, banged, dropped and posted through '
            'gaps — experiments, not repetition.',
    'm_12_se_1':
        'A new face makes them go quiet, cling, or check your expression '
            'before deciding. That check is the milestone.',
    'm_12_se_2':
        'They do something that got a laugh — a noise, a dropped spoon — '
            'again, and look straight at you for the reaction.',

    // ─── 15 months ──────────────────────────────────────────────────────────
    'm_15_gm_1':
        'Several steps across a room with nothing held and no one holding on. '
            'Wide-legged, arms up, frequent landings on the bottom.',
    'm_15_gm_2':
        'They drop into a squat to pick something up and come back up without '
            'putting a hand down or holding on.',
    'm_15_fm_1':
        'One block placed on top of another and released so it stays. Two is '
            'the whole milestone.',
    'm_15_fm_2':
        'Crayon held in a fist, marks made on the paper on purpose — back and '
            'forth lines and loops, not drawing.',
    'm_15_la_1':
        'Three or more words they use themselves and you would recognise out '
            'of context. Their own versions count if they are consistent.',
    'm_15_la_2':
        'A point at a dog or a plane, then a look back at your face to check '
            'you saw it too. The look back is what makes it sharing.',
    'm_15_cg_1':
        'They toddle off to play a few metres away, glance back to find you, '
            'and carry on. Base camp behaviour.',
    'm_15_cg_2':
        'A book is brought to you and pushed into your hands or your lap — a '
            'request made with an object.',
    'm_15_se_1':
        'Pointing used to get things: at the cupboard for a snack, at the '
            'door to go out.',
    'm_15_se_2':
        'Spontaneous hugs, leaning in, a kiss on request for the people they '
            'know — and not for everyone.',

    // ─── 18 months ──────────────────────────────────────────────────────────
    'm_18_gm_1':
        'Up a step or two with one hand held or a rail gripped, usually '
            'leading with the same foot each time.',
    'm_18_gm_2':
        'A ball on the floor is kicked forward on purpose. Walking into it '
            'hard enough to move it also counts at first.',
    'm_18_fm_1':
        'A tower of four blocks that stands up long enough for them to look '
            'pleased about it.',
    'm_18_fm_2':
        'They turn pages themselves, forward and back. Several at once and '
            'the odd tear are both normal.',
    'm_18_la_1':
        'Six to ten words used unprompted across a day. Animal noises and '
            'their own consistent versions count.',
    'm_18_la_2':
        'Ask "where is your nose?" and they touch or look at it, without you '
            'pointing first.',
    'm_18_cg_1':
        'They hold a phone to an ear, a brush to hair, a spoon to a mouth — '
            'objects used for their real purpose, in play.',
    'm_18_cg_2':
        'They point at something and then check your face, using the point to '
            'make you look, not to reach.',
    'm_18_se_1':
        'They hand you a toy, then want it back, then hand it over again. The '
            'exchange itself is the game.',
    'm_18_se_2':
        'Big, sudden, physical upset when thwarted, and it passes. Tantrums '
            'at this age are a stage of development, not misbehaviour.',

    // ─── 24 months ──────────────────────────────────────────────────────────
    'm_24_gm_1':
        'Up and down a flight with a hand on the rail, both feet landing on '
            'each step before the next one.',
    'm_24_gm_2':
        'A real run — both feet leaving the ground, some speed — even if '
            'stopping and cornering are still unreliable.',
    'm_24_fm_1':
        'Four or more blocks stacked without them being nudged into place for '
            'them.',
    'm_24_fm_2':
        'You draw a line, they draw one roughly like it. Wobbly, wrong length '
            'and not quite parallel is a pass.',
    'm_24_la_1':
        'Two words joined to mean one thing — "more milk", "daddy go", "no '
            'bed". This matters more than the size of the vocabulary.',
    'm_24_la_2':
        'Ask "where is the duck?" in a familiar book and they put a finger on '
            'it.',
    'm_24_cg_1':
        '"Get your shoes and bring them here" done as one job, without you '
            'repeating the second half.',
    'm_24_cg_2':
        'Given a mixed pile, they put like with like — the red ones together, '
            'or the round ones — for at least part of the pile.',
    'm_24_se_1':
        '"Me do it" behaviour: refusing help with the spoon, the shoe, the '
            'stairs. Wanting to do it themselves is the milestone.',
    'm_24_se_2':
        'Other children register as interesting: they watch, follow, and get '
            'visibly excited, even without joining in.',

    // ─── 30 months ──────────────────────────────────────────────────────────
    'm_30_gm_1':
        'Both feet leave the floor together and land together, on the spot. '
            'Stepping down off a low ledge is a different skill.',
    'm_30_gm_2':
        'A ball thrown from above the shoulder, forwards. Direction and '
            'distance are not part of it yet.',
    'm_30_fm_1':
        'Single pages turned one at a time through a story, using finger and '
            'thumb at the edge.',
    'm_30_fm_2':
        'The crayon starts to sit between thumb and fingers rather than in a '
            'fist. Expect it to slip back to a fist when they concentrate.',
    'm_30_la_1':
        'Two- and three-word sentences used routinely, not just once — "want '
            'more juice", "mummy sit here".',
    'm_30_la_2':
        'They name what they see in a picture book unprompted, rather than '
            'only pointing when asked.',
    'm_30_cg_1':
        'A doll gets fed, a teddy gets told off, a block becomes a phone. '
            'Real function stands in for real objects.',
    'm_30_cg_2':
        'Asked for two, they hand over two. Beyond that "lots" — knowing two '
            'is not the same as counting.',
    'm_30_se_1':
        'Another child cries and they look concerned, go over, fetch someone, '
            'or offer a toy.',
    'm_30_se_2':
        'They play happily next to another child on the same activity without '
            'much joint play. Side by side is exactly right at this age.',

    // ─── 36 months ──────────────────────────────────────────────────────────
    'm_36_gm_1':
        'Confident on climbing frames and stairs, running and changing '
            'direction without going over.',
    'm_36_gm_2':
        'Feet on the pedals, pushing round in circles and going forward. '
            'Scooting it along with their feet is the earlier version.',
    'm_36_fm_1':
        'Shown a circle, they draw a closed-ish round shape. Lumpy and not '
            'quite joined up still counts.',
    'm_36_fm_2':
        'Six or more blocks stacked, with the patience to line them up as '
            'they go.',
    'm_36_la_1':
        'Sentences of three or more words that a stranger could mostly '
            'follow. Some sounds will still be unclear, and that is fine.',
    'm_36_la_2':
        '"Take off your shoes, put them by the door and come to the table" '
            'done as one instruction.',
    'm_36_cg_1': 'Given two objects they can say whether they are the same or '
        'different, and roughly why.',
    'm_36_cg_2':
        'Extended pretend with a story in it — the animals talk to each '
            'other, the doll goes to the shops.',
    'm_36_se_1':
        'They name feelings, theirs and other people\'s: happy, sad, cross, '
            'scared.',
    'm_36_se_2':
        'Being left at nursery or with a grandparent is easier than it was a '
            'year ago, even if it is still not nothing.',
  };
}
