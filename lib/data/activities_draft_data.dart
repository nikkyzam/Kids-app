import '../models/activity.dart';

/// ⚠️ DRAFT CONTENT — NOT PROFESSIONALLY REVIEWED ⚠️
///
/// These activities were drafted to close the gap in the daily play loop: the
/// reviewed library holds only four activities per age band past 16 weeks, so
/// the same four repeated every four days.
///
/// **They have not been reviewed by a paediatric occupational therapist,
/// health visitor, or any other qualified professional.** They were written by
/// an AI assistant from general, widely published play guidance. Before this
/// ships to parents, every entry needs sign-off from someone qualified,
/// checking at minimum:
///
///  * that the activity is developmentally appropriate for its age band
///  * that no activity implies a milestone *should* have been reached, which
///    can alarm a parent whose child is developing normally at a different pace
///  * the safety notes, particularly supervision, choking risk, and anything
///    involving water, climbing, or objects a child might mouth
///  * that nothing reads as clinical advice
///
/// Keeping them in a separate file makes that review boundary explicit and the
/// batch easy to remove: delete this file and drop [ActivitiesData.draft] from
/// [ActivitiesData.all].
///
/// Distribution — this batch adds 70 activities, taking every band from as few
/// as four up to ten or more, so the daily rotation repeats roughly every ten
/// to twelve days rather than every four. Longer age bands still deserve more
/// than this batch provides; see the count test in
/// `test/data/activities_data_test.dart`.
class ActivitiesDraftData {
  ActivitiesDraftData._();

  static const List<PlayActivity> pendingReview = [
    // ─── 0–4 weeks ───────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_0_8',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Slow Rocking Rhythm',
      durationMins: 5,
      materials: ['A chair you can rock or sway in'],
      instructions: [
        'Hold baby securely against your chest, supporting head and neck.',
        'Sway slowly side to side — roughly one gentle movement per '
            'second.',
        'Hum or breathe audibly so baby feels the rhythm as well as hears '
            'it. Stop if baby turns away, arches, or splays their fingers — '
            'those are signs of having had enough.',
      ],
      skillTargeted: 'Balance & Self-Soothing',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_0_9',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Finger Grasp Hello',
      durationMins: 3,
      materials: ['Clean hands'],
      instructions: [
        'Stroke the inside of baby\'s palm with one fingertip.',
        'Let baby curl their fingers around yours — this is a reflex, not '
            'a choice, and it is meant to be automatic at this age.',
        'Talk quietly about what you are doing while they hold on. Swap '
            'hands so both get a turn.',
      ],
      skillTargeted: 'Grasp Reflex & Touch',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_0_10',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Voices From Both Sides',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'With baby lying on their back, speak softly near their right '
            'ear.',
        'Pause, then speak near the left ear and watch for stilling, a '
            'blink, or eyes shifting.',
        'Newborns often respond by going quiet rather than turning — that '
            'counts. Keep your voice gentle; sudden loud sounds are '
            'startling, not fun.',
      ],
      skillTargeted: 'Sound Localisation',
      skillCategory: SkillCategory.language,
    ),

    // ─── 4–8 weeks ───────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_4_7',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'High-Contrast Card Show',
      durationMins: 5,
      materials: ['A black-and-white patterned card or simple drawing'],
      instructions: [
        'Hold the card about 25 cm from baby\'s face while they lie on '
            'their back or sit supported in your lap.',
        'Hold it still until they settle on it, then move it slowly '
            'sideways.',
        'Swap for a different pattern when interest fades. Two or three '
            'minutes is plenty — looking hard is real work.',
      ],
      skillTargeted: 'Visual Focus & Tracking',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_4_8',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Bicycle Legs',
      durationMins: 5,
      materials: ['A soft flat surface'],
      instructions: [
        'Lay baby on their back and hold their lower legs gently.',
        'Cycle the legs slowly, one then the other, never forcing a '
            'joint.',
        'Sing while you do it so the movement has a rhythm. Stop whenever '
            'baby resists or stiffens.',
      ],
      skillTargeted: 'Hip Mobility & Body Awareness',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_4_9',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Narrated Nappy Change',
      durationMins: 5,
      materials: ['Your usual changing setup'],
      instructions: [
        'Describe each step out loud as you go: "Now the left leg, now we '
            'lift".',
        'Pause after a sentence and leave a gap, as if baby were '
            'replying.',
        'Meet their eyes when you speak — a turn-taking rhythm starts '
            'here. Keep one hand on baby at all times on a raised surface.',
      ],
      skillTargeted: 'Conversational Turn-Taking',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_4_10',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Two Textures',
      durationMins: 5,
      materials: ['A soft cloth', 'A slightly textured cloth (e.g. towelling)'],
      instructions: [
        'Stroke one cloth slowly along baby\'s arm, naming it: "This one '
            'is soft".',
        'Wait a few seconds, then use the second cloth and name that too.',
        'Watch which one holds their attention longer. Avoid the face, '
            'and stop if baby pulls away.',
      ],
      skillTargeted: 'Tactile Discrimination',
      skillCategory: SkillCategory.sensory,
    ),

    // ─── 8–12 weeks ──────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_8_6',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Reach for the Dangle',
      durationMins: 5,
      materials: ['A light toy or ribbon you can hold above baby'],
      instructions: [
        'Hold the toy within arm\'s reach above baby\'s chest, not their '
            'face.',
        'Let them bat, swipe, or simply stare — all are progress.',
        'Move it slightly closer if their arms wave without connecting. '
            'Never leave anything dangling over a baby you are not holding.',
      ],
      skillTargeted: 'Reaching & Eye-Hand Coordination',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_8_7',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Side-Lying Play',
      durationMins: 5,
      materials: ['A rolled towel'],
      instructions: [
        'Lay baby on their side with a rolled towel supporting their '
            'back.',
        'Put a toy in front of them at chest height.',
        'Side-lying brings both hands together in front, which is harder '
            'on their back. Stay beside them the whole time and return them '
            'to their back afterwards. Babies sleep on their backs — this is '
            'awake play only.',
      ],
      skillTargeted: 'Midline Play & Trunk Control',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_8_8',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Copycat Cooing',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'When baby makes a vowel sound, repeat it back exactly.',
        'Wait. Give them a long pause — replies are slow at this age.',
        'If they answer, copy again, then try a small variation. Follow '
            'their lead and stop when they look away.',
      ],
      skillTargeted: 'Vocal Imitation',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_8_9',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Mirror Discovery',
      durationMins: 5,
      materials: ['A shatterproof mirror'],
      instructions: [
        'Hold the mirror about 30 cm from baby, or prop it safely during '
            'tummy time.',
        'Let them look. Point and say "That\'s you" and "That\'s me".',
        'Babies this age do not recognise themselves — the draw is the '
            'face, and that is exactly the point. Never leave a mirror '
            'propped near a baby unattended.',
      ],
      skillTargeted: 'Face Recognition & Attention',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_8_10',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Crinkle Hunt',
      durationMins: 5,
      materials: ['A crinkly fabric book or crinkle toy'],
      instructions: [
        'Crinkle the toy out of sight and watch baby still or search.',
        'Bring it into view and crinkle again so sound and object '
            'connect.',
        'Let them touch it and feel the noise happen under their own '
            'hand. Use only baby-safe fabric — never plastic bags or '
            'wrapping.',
      ],
      skillTargeted: 'Cause & Effect, Auditory Attention',
      skillCategory: SkillCategory.cognitive,
    ),

    // ─── 12–16 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_12_5',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Roll Invitation',
      durationMins: 5,
      materials: ['A favourite toy'],
      instructions: [
        'With baby on their back, hold a toy out to one side, just past '
            'their shoulder.',
        'Let them twist towards it. Some babies roll, most just rotate — '
            'both build the same muscles.',
        'Try the other side so both get practice. Never prop or push a '
            'baby over; let the movement be theirs.',
      ],
      skillTargeted: 'Rolling & Trunk Rotation',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_12_6',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Two Hands Together',
      durationMins: 5,
      materials: ['A light rattle or ring toy'],
      instructions: [
        'Place the toy into both of baby\'s hands at their chest.',
        'Hold their hands together around it for a moment, then let go.',
        'Bringing both hands to the middle is a big step towards later '
            'self-feeding and reaching. Use a toy with no small parts.',
      ],
      skillTargeted: 'Midline Coordination',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_12_7',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Sing Their Name',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Pick a simple tune and sing baby\'s name into it, over and over.',
        'Change the volume and pitch; watch which version gets a smile.',
        'Pause and wait after each line. Repetition is the point — the '
            'same song daily is better than a new one.',
      ],
      skillTargeted: 'Name Recognition & Rhythm',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_12_8',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'First Peekaboo',
      durationMins: 5,
      materials: ['A light muslin or cloth'],
      instructions: [
        'Cover your own face — not baby\'s — and say "Where did I go?".',
        'Reappear quickly with a bright "Peekaboo!".',
        'Keep the hidden moment very short; long disappearances are '
            'unsettling. Stop if baby looks worried rather than delighted.',
      ],
      skillTargeted: 'Object Permanence & Anticipation',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_12_9',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Texture Page Turn',
      durationMins: 5,
      materials: ['A touch-and-feel board book'],
      instructions: [
        'Sit baby supported in your lap facing the book.',
        'Guide their hand onto each texture and name it.',
        'Let them set the pace — lingering on one page is fine. Board '
            'books only; paper pages tear and end up in mouths.',
      ],
      skillTargeted: 'Tactile Exploration & Book Habits',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_12_10',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Your Turn, My Turn',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Make a sound, then hold a long, expectant pause.',
        'Respond to whatever comes back — a coo, a kick, a smile — as if '
            'it were a sentence.',
        'Keep the exchange going as long as baby stays engaged. Looking '
            'away is their way of asking for a break.',
      ],
      skillTargeted: 'Reciprocal Interaction',
      skillCategory: SkillCategory.socialEmotional,
    ),

    // ─── 16–24 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_16_5',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Supported Sitting',
      durationMins: 5,
      materials: ['Cushions or your own body as support'],
      instructions: [
        'Sit baby between your legs, leaning back against you.',
        'Offer a toy at chest height so they use hands while trunk works.',
        'Return to lying down as soon as they slump — slumping means '
            'tired, not lazy. Never leave a propped baby unattended, even for '
            'a moment.',
      ],
      skillTargeted: 'Trunk Strength & Sitting Balance',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_16_6',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Hand to Hand',
      durationMins: 5,
      materials: ['A light toy easy to grip'],
      instructions: [
        'Give the toy to one hand and wait.',
        'Hold out your palm on the other side to invite a transfer.',
        'Passing an object between hands is a genuine milestone; '
            'celebrate it when it comes, and do not worry when it does not '
            'yet. Nothing small enough to fit inside a toilet-roll tube.',
      ],
      skillTargeted: 'Object Transfer',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_16_7',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Ba-Ba-Ba',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Repeat a simple consonant string: "ba-ba-ba", "da-da-da".',
        'Exaggerate your lips so baby can see how the sound is made.',
        'Pause and let them try. Any sound back is a reply. Repeat the '
            'same few sounds across days rather than inventing new ones.',
      ],
      skillTargeted: 'Consonant Babble',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_16_8',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Drop and Fetch',
      durationMins: 5,
      materials: ['Two or three safe toys'],
      instructions: [
        'Sit baby supported with toys in reach.',
        'When one is dropped, name it — "Down it goes!" — and hand it '
            'back.',
        'Expect to do this many times; the repetition is the learning. '
            'Play on the floor, not a raised surface.',
      ],
      skillTargeted: 'Cause & Effect, Persistence',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_16_9',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Finding Feet',
      durationMins: 5,
      materials: ['A pair of brightly coloured socks (optional)'],
      instructions: [
        'With baby on their back, bring their feet gently into their '
            'view.',
        'Tap the soles together and name them: "These are your feet".',
        'Let them grab and, very likely, taste — that is how they map '
            'their own body. Socks with anything glued or sewn on are a '
            'choking risk; plain only.',
      ],
      skillTargeted: 'Body Awareness',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_16_10',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Mirror Smiles',
      durationMins: 5,
      materials: ['A shatterproof mirror'],
      instructions: [
        'Sit together facing the mirror, baby supported on your lap.',
        'Smile, wave, and pull faces; narrate both of you.',
        'Watch for them looking between your real face and the '
            'reflection. Keep sessions short and cheerful.',
      ],
      skillTargeted: 'Social Referencing',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_16_11',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Roll Both Ways',
      durationMins: 5,
      materials: ['A soft floor space'],
      instructions: [
        'Encourage rolling towards a toy on one side, then set up the '
            'other side.',
        'Most babies favour one direction first; the second usually '
            'follows.',
        'Clear the space of anything hard before you start. Once rolling '
            'begins, never leave them on a bed or sofa.',
      ],
      skillTargeted: 'Rolling Both Directions',
      skillCategory: SkillCategory.grossMotor,
    ),

    // ─── 24–36 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_24_5',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Sitting and Playing',
      durationMins: 8,
      materials: ['Two or three toys', 'Cushions around the sides'],
      instructions: [
        'Sit baby on the floor with toys in an arc in front of them.',
        'Place cushions beside and behind, but stay within arm\'s reach.',
        'Reaching sideways for a toy is balance practice, wobbles '
            'included. Floor only — never a raised surface.',
      ],
      skillTargeted: 'Independent Sitting',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_24_6',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Bang Two Together',
      durationMins: 5,
      materials: ['Two safe objects that make a sound (wooden spoons, cups)'],
      instructions: [
        'Give one object to each hand.',
        'Show them banging the two together, then wait.',
        'Bringing two objects to the middle and connecting them is a real '
            'cognitive step. Choose objects with no small or breakable parts.',
      ],
      skillTargeted: 'Bilateral Coordination',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_24_7',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Where Did It Go?',
      durationMins: 5,
      materials: ['A cup and a small safe toy'],
      instructions: [
        'Show baby the toy, then cover it with the cup while they watch.',
        'Wait. If they do not search, lift the cup and show them again.',
        'Searching for a hidden object usually appears somewhere in this '
            'band — later is common and fine. Use a toy too large to swallow.',
      ],
      skillTargeted: 'Object Permanence',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_24_8',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Babble Conversation',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Treat every babble as a full sentence and answer it seriously.',
        'Add one real word: they say "ba-ba", you say "Ball! Yes, a '
            'ball".',
        'Leave long gaps for their turn. Face them so they can watch your '
            'mouth.',
      ],
      skillTargeted: 'Turn-Taking & Vocabulary',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_24_9',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Texture Basket',
      durationMins: 8,
      materials: ['A basket of safe household objects of different textures'],
      instructions: [
        'Fill a basket with items like a wooden spoon, a silicone mat, a '
            'flannel, a metal cup.',
        'Let baby choose and explore, mouth included.',
        'Name each texture as they find it. Everything must be too big to '
            'swallow, unbreakable, and free of strings or loose parts. Stay '
            'with them throughout.',
      ],
      skillTargeted: 'Tactile Exploration & Choice',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_24_10',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Who Is That?',
      durationMins: 5,
      materials: ['Photos of familiar people'],
      instructions: [
        'Look at photos together and name each person warmly.',
        'Return to the same few faces daily rather than showing many.',
        'Watch for a smile of recognition. Keep photos behind glass-free '
            'covers or use printed board pages.',
      ],
      skillTargeted: 'Familiar Face Recognition',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_24_11',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Reach and Shuffle',
      durationMins: 8,
      materials: ['A favourite toy'],
      instructions: [
        'Place the toy just beyond reach while baby is on their tummy.',
        'Let them work for it — pivoting, pushing back, or commando '
            'crawling all count.',
        'Bring it closer before frustration sets in. Many babies never '
            'crawl on hands and knees, and that is within normal.',
      ],
      skillTargeted: 'Pre-Crawling Movement',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_24_12',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Songs With Actions',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Pick one action song and do it the same way every day.',
        'Do the actions on or near baby — clapping their hands with '
            'yours.',
        'Pause before the exciting part and watch them anticipate it. '
            'Familiarity beats variety here.',
      ],
      skillTargeted: 'Anticipation & Rhythm',
      skillCategory: SkillCategory.language,
    ),

    // ─── 36–48 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_36_5',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Cruising the Furniture',
      durationMins: 8,
      materials: ['Stable, sturdy furniture at chest height'],
      instructions: [
        'Place a toy along a sofa so baby sidesteps towards it while '
            'holding on.',
        'Check first that everything they might grab is stable and cannot '
            'tip.',
        'Bare feet grip better than socks on hard floors. Stay alongside '
            '— falls at this stage are frequent and normal.',
      ],
      skillTargeted: 'Cruising & Standing Balance',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_36_6',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Fill and Dump',
      durationMins: 8,
      materials: ['A container and several large safe objects'],
      instructions: [
        'Show baby how to drop objects in, then tip them all out.',
        'Hand them back and let the cycle repeat as long as they like.',
        'This looks repetitive and is genuinely how the concept is '
            'learned. Objects must be too large to swallow; container should '
            'have no lid.',
      ],
      skillTargeted: 'Release & Container Concepts',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_36_7',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Point and Name',
      durationMins: 5,
      materials: ['Any room, or a window'],
      instructions: [
        'Follow baby\'s gaze, point at what they are looking at, and name '
            'it.',
        'Use single clear words rather than sentences.',
        'When they point, always name what they have chosen — following '
            'their interest teaches more than directing it. Repeat the same '
            'words across days.',
      ],
      skillTargeted: 'Joint Attention & First Words',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_36_8',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Two Blocks High',
      durationMins: 5,
      materials: ['Two or three large soft or wooden blocks'],
      instructions: [
        'Stack two blocks and let baby knock them down — knocking comes '
            'first.',
        'Hand them a block and see whether they place or drop it.',
        'Stacking usually arrives near the end of the first year. Large '
            'blocks only.',
      ],
      skillTargeted: 'Controlled Release',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_36_9',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Wave Bye-Bye',
      durationMins: 3,
      materials: ['No materials needed'],
      instructions: [
        'Wave and say "bye-bye" every single time someone leaves the '
            'room.',
        'Gently help their hand wave at first.',
        'Do the same with "hello" on the way back in. Consistency across '
            'days is what makes the gesture stick.',
      ],
      skillTargeted: 'Social Gestures',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_36_10',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Rolling the Ball',
      durationMins: 8,
      materials: ['A soft ball'],
      instructions: [
        'Sit facing each other with legs apart and roll the ball across.',
        'Say "your turn" and "my turn" each time.',
        'They may not roll it back for weeks — pushing or patting counts. '
            'Use a ball too large to fit in the mouth.',
      ],
      skillTargeted: 'Turn-Taking & Tracking',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_36_11',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Splash Time',
      durationMins: 8,
      materials: ['A shallow tray with 2–3 cm of water', 'Cups and a towel'],
      instructions: [
        'Sit baby beside a very shallow tray of water and let them splash '
            'and pour.',
        'Name what happens: "pour", "splash", "wet".',
        'Babies can drown in a few centimetres of water. Stay within '
            'arm\'s reach the entire time and empty the tray immediately '
            'afterwards. Never answer the door or phone mid-activity.',
      ],
      skillTargeted: 'Sensory Exploration & Vocabulary',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_36_12',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Hidden Under the Cloth',
      durationMins: 5,
      materials: ['A cloth and a favourite toy'],
      instructions: [
        'Hide the toy fully under a cloth while baby watches.',
        'Encourage them to pull the cloth away themselves.',
        'Make the reveal a celebration. Progress to hiding it under one '
            'of two cloths when that gets easy.',
      ],
      skillTargeted: 'Object Permanence & Problem Solving',
      skillCategory: SkillCategory.cognitive,
    ),

    // ─── 48–65 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_48_5',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Push-Along Walking',
      durationMins: 8,
      materials: ['A weighted push toy or a sturdy box'],
      instructions: [
        'Let your child push a stable, weighted toy across a clear floor.',
        'A cardboard box with a couple of books inside works as well as a '
            'bought toy.',
        'Clear the route first and stay alongside. Do not use a baby '
            'walker — they are unsafe and discouraged by health authorities '
            'in many countries.',
      ],
      skillTargeted: 'Walking Balance',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_48_6',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'First Scribbles',
      durationMins: 8,
      materials: ['Chunky non-toxic crayons', 'Large paper'],
      instructions: [
        'Tape paper to the floor or table so it does not slide.',
        'Show one mark, then hand over the crayon and let them lead.',
        'Fists, not fingers, hold crayons at this age. Chunky crayons '
            'only, and stay close — crayons get tasted.',
      ],
      skillTargeted: 'Mark Making & Grip',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_48_7',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'One-Step Instructions',
      durationMins: 5,
      materials: ['Familiar household objects'],
      instructions: [
        'Ask for one simple thing: "Give me the cup".',
        'Hold your hand out as a visual clue.',
        'Celebrate the attempt, not just the success. One instruction at '
            'a time — two-step requests come much later.',
      ],
      skillTargeted: 'Receptive Language',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_48_8',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Posting Practice',
      durationMins: 8,
      materials: ['A box with a hole cut in the lid', 'Large safe objects'],
      instructions: [
        'Cut a hole big enough for the objects you are using.',
        'Show one going in, then let them try.',
        'Lining an object up with a hole takes real coordination. Objects '
            'must be too large to swallow; supervise throughout.',
      ],
      skillTargeted: 'Spatial Problem Solving',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_48_9',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Animal Sounds',
      durationMins: 5,
      materials: ['An animal picture book or toy animals'],
      instructions: [
        'Name the animal, then make its sound: "Dog. Woof!".',
        'Animal sounds are often easier first words than animal names.',
        'Pause and let them try. Stick to the same handful of animals for '
            'a while.',
      ],
      skillTargeted: 'Expressive Language',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_48_10',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Helping Get Dressed',
      durationMins: 5,
      materials: ['Everyday clothes'],
      instructions: [
        'Say what comes next and pause: "Arm in the sleeve".',
        'Let them push an arm through or hold a foot up.',
        'Allow extra time — this only works when nobody is rushing. '
            'Praise the effort, not the speed.',
      ],
      skillTargeted: 'Self-Help & Cooperation',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_48_11',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Dance and Freeze',
      durationMins: 8,
      materials: ['Music'],
      instructions: [
        'Play music and move together — bouncing, swaying, or holding '
            'hands.',
        'Stop the music suddenly and freeze, then start again.',
        'The pause and restart is where the fun and the listening live. '
            'Clear the floor space first.',
      ],
      skillTargeted: 'Rhythm & Listening',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_48_12',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Stack and Topple',
      durationMins: 8,
      materials: ['Soft or wooden blocks'],
      instructions: [
        'Build a small tower together and let them knock it over.',
        'Count the blocks aloud as you stack.',
        'Rebuilding after every crash is the whole game. Keep towers low '
            'so falling blocks stay harmless.',
      ],
      skillTargeted: 'Stacking & Cause and Effect',
      skillCategory: SkillCategory.fineMotor,
    ),

    // ─── 65–88 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_65_5',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Safe Climbing',
      durationMins: 10,
      materials: ['Sofa cushions on the floor'],
      instructions: [
        'Build a low, soft pile of cushions to climb on and over.',
        'Stay beside them and let them find their own route.',
        'Climbing the safe thing you offer reduces climbing the '
            'bookshelf. Keep the height low and the landing soft.',
      ],
      skillTargeted: 'Climbing & Motor Planning',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_65_6',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Adding a Word',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'When they say one word, reply with two: "Dog" → "Big dog!".',
        'Keep your version only slightly longer than theirs.',
        'Do not ask them to repeat it — modelling works better than '
            'drilling. Do this throughout the day rather than as a set '
            'exercise.',
      ],
      skillTargeted: 'Two-Word Phrases',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_65_7',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Feeding Teddy',
      durationMins: 8,
      materials: ['A soft toy', 'A cup and spoon'],
      instructions: [
        'Pretend to feed the toy and describe what you are doing.',
        'Hand the spoon over and let them take a turn.',
        'Caring for a toy is early empathy as much as pretend play. Use '
            'real, unbreakable utensils.',
      ],
      skillTargeted: 'Pretend Play & Empathy',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_65_8',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Sorting by Colour',
      durationMins: 8,
      materials: ['Two containers', 'Objects in two clear colours'],
      instructions: [
        'Start with just two colours and plenty of examples.',
        'Sort a few yourself while naming the colours, then invite them '
            'in.',
        'Getting it "wrong" is normal well past two years old. Objects '
            'too large to swallow.',
      ],
      skillTargeted: 'Sorting & Colour Concepts',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_65_9',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Bubble Chase',
      durationMins: 8,
      materials: ['Non-toxic bubble mixture'],
      instructions: [
        'Blow bubbles and let them chase, reach, and pop.',
        'Blow them low and slow for the youngest chasers.',
        'Keep the bubble mixture out of reach — an adult blows, always. '
            'Floors get slippery; play outside or dry the floor after.',
      ],
      skillTargeted: 'Tracking & Coordination',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_65_10',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Sticker Peel',
      durationMins: 8,
      materials: ['Large stickers', 'Paper'],
      instructions: [
        'Peel the sticker halfway so a corner lifts, then hand it over.',
        'Let them place it anywhere on the paper.',
        'Peeling and pressing builds the same pincer grip as later pencil '
            'work. Large stickers only, and stay close — small ones get '
            'eaten.',
      ],
      skillTargeted: 'Pincer Grip',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_65_11',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'You Turn the Page',
      durationMins: 8,
      materials: ['A board book'],
      instructions: [
        'Read together and let them turn every page, even out of order.',
        'Follow their pace; skipping to a favourite page is fine.',
        'Ask "Where is the...?" and let them point. Finishing the book is '
            'not the goal.',
      ],
      skillTargeted: 'Book Handling & Vocabulary',
      skillCategory: SkillCategory.language,
    ),

    // ─── 88–117 weeks ────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_88_5',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Kick the Ball',
      durationMins: 10,
      materials: ['A lightweight ball'],
      instructions: [
        'Place the ball still in front of them and let them walk into it '
            'first.',
        'Deliberate kicking follows accidental kicking by some weeks.',
        'Play in an open space away from furniture. A light ball is '
            'easier and safer than a heavy one.',
      ],
      skillTargeted: 'Kicking & Balance',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_88_6',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Squeeze and Squash',
      durationMins: 10,
      materials: ['Non-toxic play dough'],
      instructions: [
        'Squeeze, roll, and flatten alongside them; no end product '
            'needed.',
        'Name what you are doing: "squash", "roll", "poke".',
        'Play dough is not food — stay with them and put it away '
            'afterwards. Home-made dough is very salty; keep it away from '
            'mouths.',
      ],
      skillTargeted: 'Hand Strength',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_88_7',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Where Is Your Nose?',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Ask for one body part at a time and touch your own to show.',
        'Start with three or four and add more slowly.',
        'Use a mirror to make it funnier. Keep it a game, never a test.',
      ],
      skillTargeted: 'Body Vocabulary',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_88_8',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Chunky Puzzle',
      durationMins: 10,
      materials: ['A wooden puzzle with knobs, 3–5 pieces'],
      instructions: [
        'Take all pieces out and let them try replacing one.',
        'Rotate the piece for them if they are close but stuck.',
        'Do it enough times and they will start turning pieces '
            'themselves. Knobbed puzzles suit small hands and have no loose '
            'small parts.',
      ],
      skillTargeted: 'Shape Matching',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_88_9',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Naming Feelings',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Put words to what you see: "You look cross. The tower fell '
            'down".',
        'Name the feeling before offering a fix.',
        'Name your own out loud too: "I feel tired today". Naming a '
            'feeling does not reward it — it teaches the word for it.',
      ],
      skillTargeted: 'Emotional Vocabulary',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_88_10',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Cushion Obstacle Course',
      durationMins: 10,
      materials: ['Cushions, a blanket, a low box'],
      instructions: [
        'Lay out a simple route: over a cushion, under a blanket, around '
            'a box.',
        'Go first and narrate: "over", "under", "around".',
        'Keep everything low and soft, and stay alongside. Let them '
            'repeat the same course many times.',
      ],
      skillTargeted: 'Motor Planning & Position Words',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_88_11',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Pouring Practice',
      durationMins: 10,
      materials: ['Two small jugs', 'A tray', 'A little water'],
      instructions: [
        'Half-fill one jug and let them pour between the two over a tray.',
        'Spills are part of it — hand them a cloth and let them help.',
        'Use only a small amount of water and stay with them throughout. '
            'Empty everything away immediately afterwards.',
      ],
      skillTargeted: 'Controlled Pouring',
      skillCategory: SkillCategory.fineMotor,
    ),

    // ─── 117–156 weeks ───────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_117_5',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Two-Footed Jumping',
      durationMins: 10,
      materials: ['A flat, clear floor'],
      instructions: [
        'Hold both hands and count "one, two, three, jump!".',
        'Getting both feet off the ground together is harder than it '
            'looks.',
        'Jump off nothing higher than a very low step, or off nothing at '
            'all. Soft floor, clear space, bare feet.',
      ],
      skillTargeted: 'Jumping & Power',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_117_6',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Threading Big Beads',
      durationMins: 10,
      materials: ['Large threading beads and a stiff lace'],
      instructions: [
        'Hold the lace steady at first and let them push a bead on.',
        'Two hands doing different jobs at once is the real skill here.',
        'Use beads far too large to swallow, and never leave them alone '
            'with the lace — cords are a strangulation risk. Put everything '
            'away when you finish.',
      ],
      skillTargeted: 'Two-Handed Coordination',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_117_7',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'What Happened Next?',
      durationMins: 8,
      materials: ['A familiar picture book'],
      instructions: [
        'Read a well-known book and stop before a favourite bit.',
        'Ask what comes next and wait.',
        'Accept any answer warmly, even a wrong one. Familiar books work '
            'far better than new ones for this.',
      ],
      skillTargeted: 'Recall & Story Sense',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_117_8',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Find the Pair',
      durationMins: 10,
      materials: ['Three or four pairs of matching socks'],
      instructions: [
        'Spread the socks out and find one pair together.',
        'Hold one up and ask them to find its twin.',
        'Start with pairs that look very different from each other. '
            'Folding laundry together counts as this activity.',
      ],
      skillTargeted: 'Matching & Visual Discrimination',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_117_9',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Taking Turns',
      durationMins: 10,
      materials: ['Any simple shared toy'],
      instructions: [
        'Play something with clear alternating turns and say whose turn '
            'it is.',
        'Keep waits very short at first — a few seconds is a long time '
            'now.',
        'Waiting is genuinely hard at this age; expect to remind them '
            'often. End while it is still going well.',
      ],
      skillTargeted: 'Turn-Taking & Patience',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_117_10',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Walk the Line',
      durationMins: 8,
      materials: ['A strip of tape on the floor'],
      instructions: [
        'Stick a straight line of tape down and walk along it together.',
        'Hold a hand at first, then try without.',
        'Try tiptoes or backwards once forwards is easy. Keep it on the '
            'floor — never a raised beam.',
      ],
      skillTargeted: 'Balance & Coordination',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_117_11',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Colour Hunt',
      durationMins: 10,
      materials: ['No materials needed'],
      instructions: [
        'Choose one colour and hunt for it together around the room.',
        'Name each find: "A red cup! A red book!".',
        'One colour per session is plenty. Works just as well on a walk '
            'as at home.',
      ],
      skillTargeted: 'Colour Recognition & Attention',
      skillCategory: SkillCategory.cognitive,
    ),
  ];
}
