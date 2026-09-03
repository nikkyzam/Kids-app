import '../models/activity.dart';
import 'activities_draft_data.dart';
import '../utils/clock.dart';

class ActivitiesData {
  ActivitiesData._();

  /// Activities that have been through content review.
  static const List<PlayActivity> reviewed = [
    // ─── 0–4 weeks (FREE TIER) ───────────────────────────────────────────────
    PlayActivity(
      id: 'act_0_1',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Skin-to-Skin Snuggle',
      durationMins: 5,
      materials: ['Warm blanket', 'Comfortable chair or couch'],
      instructions: [
        'Hold baby chest-to-chest on your bare skin, covering both with a blanket.',
        'Speak or hum softly near baby\'s ear — your heartbeat and voice are familiar anchors.',
        'Let baby rest for 5 minutes; notice any eye movements or gentle grips.',
      ],
      skillTargeted: 'Bonding & Regulation',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_0_2',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Gentle Face Gazing',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Hold baby 20–30 cm from your face — newborns see best at this distance.',
        'Make slow, exaggerated facial expressions: open mouth wide, stick tongue out, raise eyebrows.',
        'Pause after each expression and watch for baby to mimic or react.',
      ],
      skillTargeted: 'Visual Tracking & Social Smile',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_0_3',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Tummy Time on Chest',
      durationMins: 5,
      materials: ['Comfortable flat surface'],
      instructions: [
        'Recline slightly and lay baby tummy-down on your chest, face clear of your body.',
        'Support baby\'s bottom and let them push up with their head naturally.',
        'Encourage with soft words and watch baby work hard to lift their head.',
      ],
      skillTargeted: 'Head & Neck Strength',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_0_4',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Sound Localization',
      durationMins: 5,
      materials: ['Small rattle or set of keys'],
      instructions: [
        'While baby is calm and awake, gently shake a rattle about 30 cm to the left of baby\'s head.',
        'Pause 5 seconds, then repeat on the right side.',
        'Watch for baby\'s eyes or head to slowly track toward the sound source.',
      ],
      skillTargeted: 'Auditory Differentiation',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_0_5',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'High-Contrast Visual Tour',
      durationMins: 5,
      materials: [
        'Black-and-white picture (printed or from a book)',
        'Tape or book holder'
      ],
      instructions: [
        'Prop a bold black-and-white image (stripes, faces, checkers) 20 cm from baby\'s eyes.',
        'Slowly move the image left and right at a 45-degree arc, taking 3 seconds per sweep.',
        'Pause when baby\'s eyes lock on and wait — let their visual system do the work.',
      ],
      skillTargeted: 'Visual Focus & Tracking',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_0_6',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Calm Voice Imitation',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'When baby makes a sound (coo, grunt, or cry wind-down), pause and repeat it back softly.',
        'Wait 5–10 seconds to give baby a turn; they may move lips or make a tiny sound.',
        'Keep taking turns for 5 minutes — this is proto-conversation.',
      ],
      skillTargeted: 'Early Language & Turn-Taking',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_0_7',
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 4,
      title: 'Gentle Hand Exploration',
      durationMins: 5,
      materials: ['Soft cloth or textured fabric swatch'],
      instructions: [
        'With baby calm, lightly brush a soft cloth across each palm and fingertip.',
        'Observe whether baby grasps the cloth — use the grasp reflex by placing cloth in palm.',
        'Alternate with a slightly rougher texture and narrate: "This is soft … this is bumpy."',
      ],
      skillTargeted: 'Tactile Sensory & Palmar Grasp',
      skillCategory: SkillCategory.sensory,
    ),

    // ─── 4–8 weeks ───────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_4_1',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Tummy Time with Mirror',
      durationMins: 5,
      materials: [
        'Non-breakable baby mirror',
        '2 rolled towels or a nursing pillow'
      ],
      instructions: [
        'Place a rolled towel under baby\'s chest during tummy time to reduce strain.',
        'Position the mirror at eye level 20 cm away so baby can see their reflection.',
        'Encourage with "Who\'s that? That\'s you!" as baby lifts their head to look.',
      ],
      skillTargeted: 'Neck Strength & Self-Awareness',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_4_2',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Bicycle Legs Rhyme',
      durationMins: 5,
      materials: ['Soft mat or changing table'],
      instructions: [
        'Lay baby on their back and gently hold both ankles.',
        'Slowly cycle legs in a forward pedaling motion while singing a simple rhyme.',
        'Pause after 30 seconds; watch baby kick legs independently in response.',
      ],
      skillTargeted: 'Leg Strength & Body Awareness',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_4_3',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Colour Contrast Parade',
      durationMins: 5,
      materials: [
        '3 household objects of different solid colours (cup, cloth, toy)'
      ],
      instructions: [
        'Hold a brightly coloured object 25 cm from baby\'s face until eyes focus.',
        'Slowly move it in a wide arc from left to right over 4 seconds.',
        'Swap to the next colour and repeat; name each colour as you go.',
      ],
      skillTargeted: 'Visual Tracking & Colour Perception',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_4_4',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Singing Turn-Taking',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Sing a short repeated phrase (e.g., "la-la-la") directly to baby\'s face.',
        'Pause completely for 5 seconds, leaving space for baby to respond.',
        'When baby coos or moves lips, respond immediately with the same phrase — this builds conversational timing.',
      ],
      skillTargeted: 'Vocalization & Auditory Processing',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_4_5',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Gentle Baby Massage',
      durationMins: 5,
      materials: ['Baby-safe oil (optional)', 'Warm room'],
      instructions: [
        'With warm hands, use long gentle strokes down baby\'s legs from thigh to foot.',
        'Gently squeeze and release each arm from shoulder to wrist.',
        'Finish with small circular strokes on baby\'s back — watch for relaxed body language.',
      ],
      skillTargeted: 'Tactile Sensory & Body Mapping',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_4_6',
      ageBandMinWeeks: 4,
      ageBandMaxWeeks: 8,
      title: 'Soft Sound Orchestra',
      durationMins: 5,
      materials: ['Crinkle toy or paper', 'Bell', 'Wooden spoon'],
      instructions: [
        'With baby on back and alert, crinkle paper gently to the left — wait for eye movement.',
        'Ring a small bell gently to the right; pause 5 seconds for tracking.',
        'Tap a wooden spoon on a pot once; narrate "tap-tap" and watch baby respond.',
      ],
      skillTargeted: 'Auditory Differentiation & Attention',
      skillCategory: SkillCategory.sensory,
    ),

    // ─── 8–12 weeks ──────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_8_1',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Bat the Dangling Toy',
      durationMins: 5,
      materials: ['Activity gym or soft toy tied with ribbon overhead'],
      instructions: [
        'Dangle a soft toy just above baby\'s chest within arm reach while on their back.',
        'Gently guide one hand to make contact with the toy — baby will feel cause-and-effect.',
        'Remove your hand and let baby try on their own; celebrate every swipe.',
      ],
      skillTargeted: 'Reaching & Hand-Eye Coordination',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_8_2',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Supported Sitting View',
      durationMins: 5,
      materials: ['Boppy pillow or caregiver\'s lap'],
      instructions: [
        'Sit baby upright on your lap or in a nursing pillow, with your hands supporting their sides.',
        'Point to objects around the room, naming each: "window … plant … cup."',
        'Watch baby\'s head and eyes scan the environment with growing curiosity.',
      ],
      skillTargeted: 'Head Control & Visual Exploration',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_8_3',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Laugh Trigger Play',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Gently blow raspberries on baby\'s tummy while maintaining eye contact.',
        'Pause and wait — baby may smile or start to giggle.',
        'Repeat the exact same action; predictability builds anticipation and laughs.',
      ],
      skillTargeted: 'Social Laughter & Anticipation',
      skillCategory: SkillCategory.socialEmotional,
    ),
    PlayActivity(
      id: 'act_8_4',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Texture Scarf Peek',
      durationMins: 5,
      materials: ['3 scarves of different textures (silk, cotton, wool)'],
      instructions: [
        'Drape a silk scarf over baby\'s face lightly, then pull it away saying "peek-a-boo!"',
        'Let baby touch each scarf in turn; describe the texture: "smooth … fuzzy … rough."',
        'Encourage baby to grab and pull the scarf off their own face — beginning of agency.',
      ],
      skillTargeted: 'Tactile Discrimination & Object Permanence',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_8_5',
      ageBandMinWeeks: 8,
      ageBandMaxWeeks: 12,
      title: 'Prop-Up Story Time',
      durationMins: 5,
      materials: ['Board book with large simple images'],
      instructions: [
        'Prop book so baby can see bold images from their tummy-time position.',
        'Slowly turn each page saying just one word per page: "Dog. Ball. Tree."',
        'Pause on any page where baby stares — their attention is learning.',
      ],
      skillTargeted: 'Language Exposure & Visual Attention',
      skillCategory: SkillCategory.language,
    ),

    // ─── 12–16 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_12_1',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Rolling Practice',
      durationMins: 5,
      materials: ['Soft play mat'],
      instructions: [
        'Place baby on their back and gently bend one knee across their body to initiate a roll.',
        'Let baby feel the weight shift but do not force the roll — guide only.',
        'Cheer when baby completes even a partial roll, reinforcing the effort.',
      ],
      skillTargeted: 'Rolling Preparation & Core Strength',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_12_2',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Rattle Grasp & Shake',
      durationMins: 5,
      materials: ['Lightweight rattle'],
      instructions: [
        'Place a lightweight rattle in baby\'s palm — they should reflexively grip.',
        'Gently shake their hand to demonstrate the sound the rattle makes.',
        'Release and let baby explore on their own; notice if they shake intentionally.',
      ],
      skillTargeted: 'Grasping & Cause-and-Effect',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_12_3',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Water Sounds Sensory',
      durationMins: 5,
      materials: ['Clear sealed bottle half-filled with water and a bead'],
      instructions: [
        'Show baby the bottle and tilt it slowly so water and bead move visibly.',
        'Let baby grip the bottle and feel the shifting weight as it tilts.',
        'Narrate: "The water goes swoosh … and back again."',
      ],
      skillTargeted: 'Visual-Tactile Coordination & Object Tracking',
      skillCategory: SkillCategory.sensory,
    ),
    PlayActivity(
      id: 'act_12_4',
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 16,
      title: 'Mirror Dance',
      durationMins: 5,
      materials: ['Non-breakable mirror', 'Calm music (optional)'],
      instructions: [
        'Hold baby facing a safe mirror while soft music plays.',
        'Gently sway and bounce to the rhythm, pointing to baby\'s reflection.',
        'Say "That\'s you dancing!" — baby begins to connect reflection to self.',
      ],
      skillTargeted: 'Self-Recognition & Rhythm',
      skillCategory: SkillCategory.socialEmotional,
    ),

    // ─── 16–24 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_16_1',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Floor Tummy Exploration',
      durationMins: 5,
      materials: ['Play mat', '3 small interesting objects'],
      instructions: [
        'Place baby on tummy with 3 objects (cup, cloth ball, spoon) within arm\'s reach.',
        'Let baby reach and grab freely; resist the urge to assist unless frustrated.',
        'Name each object as baby interacts: "Cup! Ball! Spoon!"',
      ],
      skillTargeted: 'Reaching & Independent Exploration',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_16_2',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Pass the Toy',
      durationMins: 5,
      materials: ['Soft toy or block'],
      instructions: [
        'Offer a toy to baby\'s right hand until they grasp it firmly.',
        'Gently encourage them to pass it to their left hand by touching the toy with the free hand.',
        'Celebrate when baby transfers the object — this midline crossing is a big milestone.',
      ],
      skillTargeted: 'Bilateral Coordination & Midline Crossing',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_16_3',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Peek-a-Boo Buildup',
      durationMins: 5,
      materials: ['Cloth or small blanket'],
      instructions: [
        'Cover your own face with a cloth and count slowly: "One … two … three … BOO!"',
        'Let baby\'s anticipation build before you reveal — watch their expression.',
        'Now cover baby\'s face lightly and let them pull it off themselves.',
      ],
      skillTargeted: 'Object Permanence & Anticipation',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_16_4',
      ageBandMinWeeks: 16,
      ageBandMaxWeeks: 24,
      title: 'Babble Concert',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Face baby and produce long babble strings: "ba-ba-ba … da-da-da … ma-ma-ma."',
        'Pause completely after each string for baby to copy or respond.',
        'Amplify whatever sounds baby makes — "Yes! Ba-ba-ba!" — reinforcing vocal play.',
      ],
      skillTargeted: 'Proto-Language & Vocal Imitation',
      skillCategory: SkillCategory.language,
    ),

    // ─── 24–36 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_24_1',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Sit and Stack',
      durationMins: 5,
      materials: ['3–4 soft stackable cups or blocks'],
      instructions: [
        'Sit baby upright with support and place a cup in front of them.',
        'Stack a second cup on top, letting baby watch, then give them a cup to try.',
        'Let baby knock the tower down — that\'s the best part and builds cause-and-effect.',
      ],
      skillTargeted: 'Sitting Balance & Problem Solving',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_24_2',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Pincer Pick-Up',
      durationMins: 5,
      materials: ['Dry cereal puffs or small soft objects on a tray'],
      instructions: [
        'Place several puffs on a clean tray in front of seated baby.',
        'Demonstrate picking one up with your thumb and index finger only.',
        'Encourage baby to try the pincer grip — don\'t worry if they use a raking motion; keep offering.',
      ],
      skillTargeted: 'Pincer Grasp Development',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_24_3',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Name Response Game',
      durationMins: 5,
      materials: ['Favourite toy as a reward'],
      instructions: [
        'With baby engaged in play, say their name once in a normal voice and wait.',
        'If they look up, immediately reward with the toy and enthusiastic praise.',
        'Repeat from different positions in the room to generalise name recognition.',
      ],
      skillTargeted: 'Name Recognition & Attention',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_24_4',
      ageBandMinWeeks: 24,
      ageBandMaxWeeks: 36,
      title: 'Box In, Box Out',
      durationMins: 5,
      materials: ['Small box or bowl', '5 large blocks or soft balls'],
      instructions: [
        'Show baby how to drop objects one by one into the box with exaggerated enthusiasm.',
        'Let baby fill the box independently — resist helping unless truly stuck.',
        'Flip the box to dump everything out and start again; repetition is how babies learn.',
      ],
      skillTargeted: 'Object Permanence & Fine Motor Control',
      skillCategory: SkillCategory.cognitive,
    ),

    // ─── 36–48 weeks ─────────────────────────────────────────────────────────
    PlayActivity(
      id: 'act_36_1',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Cruise Along the Couch',
      durationMins: 5,
      materials: ['Sturdy couch or low coffee table'],
      instructions: [
        'Stand baby at one end of the couch, hands holding the edge.',
        'Place a tempting toy at the other end and encourage lateral stepping.',
        'Stay close to spot, offering verbal encouragement but not physical help.',
      ],
      skillTargeted: 'Cruising & Pre-Walking Leg Strength',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_36_2',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Point and Name',
      durationMins: 5,
      materials: ['Picture book with familiar objects'],
      instructions: [
        'Open book and point to a picture: "Where\'s the dog?" Wait 3 seconds.',
        'If baby points or looks, celebrate; if not, you point and name it.',
        'Work through 5–6 pictures; watch comprehension grow over sessions.',
      ],
      skillTargeted: 'Receptive Language & Joint Attention',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_36_3',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Shape Sorter Introduction',
      durationMins: 5,
      materials: ['Shape sorter toy or DIY: cut-out holes in a box lid'],
      instructions: [
        'Offer just the circle piece first — the easiest shape.',
        'Guide baby\'s hand to feel the hole, then let them try to push the shape through.',
        'Celebrate every attempt; success can take many sessions and that\'s normal.',
      ],
      skillTargeted: 'Problem Solving & Spatial Reasoning',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_36_4',
      ageBandMinWeeks: 36,
      ageBandMaxWeeks: 48,
      title: 'Wave Goodbye Practice',
      durationMins: 5,
      materials: ['No materials needed'],
      instructions: [
        'Stand 2 metres from baby and wave enthusiastically, saying "bye-bye!"',
        'Take baby\'s hand and gently wave it while saying the phrase.',
        'Walk out of sight briefly and return, repeating — social gestures stick with context.',
      ],
      skillTargeted: 'Gestural Communication & Social Engagement',
      skillCategory: SkillCategory.socialEmotional,
    ),

    // ─── 48–65 weeks (12–15 months) ──────────────────────────────────────────
    PlayActivity(
      id: 'act_48_1',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Push-Toy Walk',
      durationMins: 5,
      materials: ['Push toy, stroller, or sturdy laundry basket'],
      instructions: [
        'Let baby grip the push toy and take steps behind it on a smooth floor.',
        'Stay close to catch falls, but let baby set the direction and pace.',
        'Narrate movement: "Forward! Turn! Stop!" to build vocabulary and body awareness.',
      ],
      skillTargeted: 'Independent Walking & Balance',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_48_2',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Scribble Time',
      durationMins: 5,
      materials: ['Large paper taped to floor', 'Fat crayons (2 colours)'],
      instructions: [
        'Tape paper to the floor so it can\'t slide, give baby one fat crayon.',
        'Demonstrate a back-and-forth scribble motion on paper.',
        'Let baby scribble freely; name the colour they\'re using as they go.',
      ],
      skillTargeted: 'Fine Motor Control & Cause-and-Effect',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_48_3',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Simple Instruction Game',
      durationMins: 5,
      materials: ['Ball', 'Cup'],
      instructions: [
        'Place a ball and cup in front of baby and say "Give me the ball" — wait 5 seconds.',
        'If baby hands it correctly, praise and return it. Then say "Put ball in cup."',
        'Keep instructions to one step; don\'t repeat — give them processing time.',
      ],
      skillTargeted: 'Receptive Language & Following Directions',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_48_4',
      ageBandMinWeeks: 48,
      ageBandMaxWeeks: 65,
      title: 'Pretend Phone Call',
      durationMins: 5,
      materials: ['Old phone or wooden block as pretend phone'],
      instructions: [
        'Hold the phone to your ear, say "Hello? Yes, this is me! It\'s for you!" and hand it to baby.',
        'Encourage baby to hold it to their ear — imitation of familiar routines is developing.',
        'Have a mock conversation, then say goodbye and hang up; repeat 3 times.',
      ],
      skillTargeted: 'Symbolic Play & Imitation',
      skillCategory: SkillCategory.cognitive,
    ),

    // ─── 65–88 weeks (15–20 months) ──────────────────────────────────────────
    PlayActivity(
      id: 'act_65_1',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Ball Kick Practice',
      durationMins: 5,
      materials: ['Soft ball (10 cm diameter)'],
      instructions: [
        'Place the ball in front of baby while they stand holding your hand.',
        'Model kicking: step forward and kick gently. Then guide their leg.',
        'Roll the ball back and let baby walk to it and kick again independently.',
      ],
      skillTargeted: 'Dynamic Balance & Bilateral Coordination',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_65_2',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Block Tower Challenge',
      durationMins: 5,
      materials: ['6–8 wooden or foam blocks'],
      instructions: [
        'Build a 3-block tower slowly so baby watches each step.',
        'Give baby 4 blocks and encourage them to build their own — hand over hand if needed.',
        'Count blocks aloud as they stack: "One … two … THREE!" then celebrate the crash.',
      ],
      skillTargeted: 'Fine Motor Planning & Counting Exposure',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_65_3',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Two-Word Request Game',
      durationMins: 5,
      materials: ['2–3 favourite snack items or toys'],
      instructions: [
        'Hold up two items (e.g., apple and banana) and ask "Which one?" then wait.',
        'When baby points or makes a sound, model the two-word phrase: "More apple?" "Big ball?"',
        'Expand every single word to two: if baby says "ball", say "Roll ball!" and do it.',
      ],
      skillTargeted: 'Two-Word Utterance Development',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_65_4',
      ageBandMinWeeks: 65,
      ageBandMaxWeeks: 88,
      title: 'Emotion Mirror Game',
      durationMins: 5,
      materials: ['Mirror or no materials needed'],
      instructions: [
        'Make a big smile at baby and say "Happy!" — encourage them to mirror it.',
        'Switch to a surprised face (wide eyes, open mouth) and say "Surprised!"',
        'Try sad, then silly — naming each feeling links facial expression to emotion words.',
      ],
      skillTargeted: 'Emotional Recognition & Vocabulary',
      skillCategory: SkillCategory.socialEmotional,
    ),

    // ─── 88–117 weeks (20–27 months) ─────────────────────────────────────────
    PlayActivity(
      id: 'act_88_1',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Jump Splash',
      durationMins: 5,
      materials: ['Shallow tray with 1 cm of water (or trampoline)'],
      instructions: [
        'Place a shallow tray of water on non-slip mat outdoors.',
        'Demonstrate jumping in with two feet; let baby splash with full enthusiasm.',
        'Count each jump together: "One jump … two jump … THREE!"',
      ],
      skillTargeted: 'Two-Foot Jump & Gross Motor Power',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_88_2',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Shape and Colour Sort',
      durationMins: 5,
      materials: ['Coloured blocks or socks', '2 baskets or bowls'],
      instructions: [
        'Label two bowls with a colour swatch each. Place mixed objects nearby.',
        'Model sorting: "This is red — red goes here!" and place it in the red bowl.',
        'Hand objects one at a time to baby; guide gently without correcting harshly.',
      ],
      skillTargeted: 'Classification & Colour Recognition',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_88_3',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Story Retell',
      durationMins: 5,
      materials: ['Familiar board book (read 3+ times previously)'],
      instructions: [
        'Open book and pause on each page, waiting for baby to fill in the word or sound.',
        'Point to a character and ask "What\'s the [dog] doing?" Accept any attempt.',
        'Ask "What happens next?" before turning the page — prediction builds comprehension.',
      ],
      skillTargeted: 'Narrative Language & Memory',
      skillCategory: SkillCategory.language,
    ),
    PlayActivity(
      id: 'act_88_4',
      ageBandMinWeeks: 88,
      ageBandMaxWeeks: 117,
      title: 'Sharing Practice',
      durationMins: 5,
      materials: [
        '5 identical objects (blocks, crackers, or stickers)',
        '1 other person'
      ],
      instructions: [
        'Sit with baby and a partner; distribute items one at a time, alternating who receives.',
        'Say "One for me, one for you" with each handoff — model enthusiastic acceptance.',
        'Let baby distribute the last round independently; praise every attempt to share.',
      ],
      skillTargeted: 'Sharing, Turn-Taking & Empathy',
      skillCategory: SkillCategory.socialEmotional,
    ),

    // ─── 117–156 weeks (27–36 months) ────────────────────────────────────────
    PlayActivity(
      id: 'act_117_1',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Obstacle Course',
      durationMins: 5,
      materials: [
        'Pillows (crawl over)',
        'Hula hoop (step through)',
        'Line of tape (balance)'
      ],
      instructions: [
        'Set up 3 stations in sequence: crawl over pillows, step through hoop, walk tape line.',
        'Walk through the course yourself first as a demo, then say "Your turn!"',
        'Time baby with a casual count and celebrate beating their last "score."',
      ],
      skillTargeted: 'Complex Gross Motor Sequencing',
      skillCategory: SkillCategory.grossMotor,
    ),
    PlayActivity(
      id: 'act_117_2',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Scissors & Play-Dough',
      durationMins: 5,
      materials: ['Play-dough rolled into a snake', 'Safety scissors'],
      instructions: [
        'Show baby how to hold scissors with thumb up and two fingers in the lower hole.',
        'Let baby snip the play-dough snake into pieces — dough provides just enough resistance.',
        'Count the pieces together and try rolling a new snake to repeat.',
      ],
      skillTargeted: 'Scissor Skills & Hand Strength',
      skillCategory: SkillCategory.fineMotor,
    ),
    PlayActivity(
      id: 'act_117_3',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Three-Step Direction',
      durationMins: 5,
      materials: ['Book', 'Cup', 'Cushion'],
      instructions: [
        'Give a 3-step instruction: "Put the book on the cushion, then bring me the cup."',
        'Wait quietly while baby processes — don\'t repeat unless they ask.',
        'Vary difficulty: 2 steps if too hard, 4 steps if too easy for your child.',
      ],
      skillTargeted: 'Working Memory & Executive Function',
      skillCategory: SkillCategory.cognitive,
    ),
    PlayActivity(
      id: 'act_117_4',
      ageBandMinWeeks: 117,
      ageBandMaxWeeks: 156,
      title: 'Feeling Story',
      durationMins: 5,
      materials: ['Stuffed animal'],
      instructions: [
        'Pick up a stuffed animal and give it a name and a feeling: "[Bear] feels sad today."',
        'Ask baby "Why is [Bear] sad? What should we do?" — accept and expand all answers.',
        'Let baby play out helping Bear feel better; this is social problem-solving in action.',
      ],
      skillTargeted: 'Empathy, Emotional Reasoning & Narrative Play',
      skillCategory: SkillCategory.socialEmotional,
    ),
  ];

  /// Every activity the app can offer.
  ///
  /// [ActivitiesDraftData.pendingReview] is drafted content that has not been
  /// professionally reviewed — see the warning at the top of that file. Drop it
  /// from this list to ship only reviewed activities.
  static const List<PlayActivity> all = [
    ...reviewed,
    ...ActivitiesDraftData.pendingReview,
  ];

  static List<PlayActivity> forAgeBandWeeks(int ageInWeeks) {
    return all
        .where((a) =>
            ageInWeeks >= a.ageBandMinWeeks && ageInWeeks < a.ageBandMaxWeeks)
        .toList();
  }

  /// The activity for a given calendar day.
  ///
  /// Selection is a pure function of the date and the age band, so the same
  /// day always yields the same activity — which is what makes it possible to
  /// look back at a day the parent never opened the app and still see what was
  /// waiting for them.
  ///
  /// [dismissed] are activities the parent has set aside for this child. They
  /// drop out of the rotation entirely rather than being replaced only on the
  /// day they were dismissed: an activity that does not suit a child should not
  /// come back around next week. If every activity in the band has been
  /// dismissed the band is used unfiltered — showing nothing at all would be a
  /// worse answer than showing something already declined.
  static PlayActivity? activityForDate(
    DateTime date,
    int ageInWeeks, {
    Set<String> dismissed = const {},
  }) {
    final band = forAgeBandWeeks(ageInWeeks);
    if (band.isEmpty) return null;
    final pool = band.where((a) => !dismissed.contains(a.id)).toList();
    final from = pool.isEmpty ? band : pool;
    return from[dayOfYear(date) % from.length];
  }

  /// The 0-based ordinal day of the year.
  ///
  /// Counted from the calendar rather than as a Duration from 1 January: a
  /// Duration is exactly 24 hours, so in a timezone that has moved on or off
  /// daylight saving since New Year the elapsed hours are one short of a whole
  /// number of days and `inDays` truncates to the wrong day — which would slide
  /// the whole rotation by one for half the world, twice a year.
  static int dayOfYear(DateTime date) {
    const cumulative = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    final isLeap =
        date.year % 4 == 0 && (date.year % 100 != 0 || date.year % 400 == 0);
    final leapDay = (isLeap && date.month > 2) ? 1 : 0;
    return cumulative[date.month - 1] + leapDay + date.day - 1;
  }

  static PlayActivity? todayActivity(
    int ageInWeeks, {
    Set<String> dismissed = const {},
  }) =>
      activityForDate(Clock.now(), ageInWeeks, dismissed: dismissed);
}
