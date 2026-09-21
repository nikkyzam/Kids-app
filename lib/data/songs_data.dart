import '../models/activity.dart' show SkillCategory;
import '../models/song.dart';

/// The songs the app suggests, with their words and their section structure.
///
/// Every rhyme here is traditional and long out of copyright, so the *words*
/// ship with the app and work offline. The tune is optional: a parent who
/// wants to hear it searches YouTube from the song's page, and the sections
/// below are laid over whichever recording they pick.
///
/// No timestamps are stored. The same rhyme exists in hundreds of recordings
/// at different tempos and with different intros, so a hard-coded "chorus at
/// 0:42" would be wrong for nearly all of them. [SongSegmenter] distributes
/// these sections across the real runtime the player reports instead.
class SongsData {
  SongsData._();

  static const List<Song> all = [
    // ─── Birth to six months ────────────────────────────────────────────────
    Song(
      id: 'song_twinkle',
      title: 'Twinkle, Twinkle, Little Star',
      searchQuery: 'Twinkle Twinkle Little Star nursery rhyme for babies',
      why: 'A slow, steady melody with a narrow range — easy for a newborn to '
          'track, and the repeated first and last verse gives them something '
          'to recognise.',
      skillCategory: SkillCategory.language,
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 52,
      parts: [
        SongPart(label: 'Verse 1', lines: [
          'Twinkle, twinkle, little star,',
          'How I wonder what you are!',
          'Up above the world so high,',
          'Like a diamond in the sky.',
        ]),
        SongPart(label: 'Verse 2', lines: [
          'When the blazing sun is gone,',
          'When he nothing shines upon,',
          'Then you show your little light,',
          'Twinkle, twinkle, all the night.',
        ]),
        SongPart(label: 'Ending', lines: [
          'Twinkle, twinkle, little star,',
          'How I wonder what you are!',
        ]),
      ],
    ),
    Song(
      id: 'song_rock_a_bye',
      title: 'Rock-a-bye Baby',
      searchQuery: 'Rock a bye baby lullaby',
      why: 'A lullaby in rocking time. Sung while you actually rock, the beat '
          'and the movement line up, which is how babies first feel rhythm.',
      skillCategory: SkillCategory.sensory,
      ageBandMinWeeks: 0,
      ageBandMaxWeeks: 52,
      parts: [
        SongPart(label: 'Verse', lines: [
          'Rock-a-bye baby, on the treetop,',
          'When the wind blows, the cradle will rock,',
          'When the bough breaks, the cradle will fall,',
          'And down will come baby, cradle and all.',
        ]),
      ],
    ),
    Song(
      id: 'song_pat_a_cake',
      title: 'Pat-a-cake',
      searchQuery: 'Pat a cake nursery rhyme with actions',
      why: 'A hand-clapping rhyme. Take their hands and clap for them — the '
          'turn-taking matters more than the tune at this age.',
      skillCategory: SkillCategory.fineMotor,
      ageBandMinWeeks: 12,
      ageBandMaxWeeks: 78,
      parts: [
        SongPart(label: 'Verse', lines: [
          "Pat-a-cake, pat-a-cake, baker's man,",
          'Bake me a cake as fast as you can;',
          'Pat it and prick it and mark it with B,',
          'And put it in the oven for baby and me.',
        ]),
      ],
    ),

    // ─── Six to eighteen months ─────────────────────────────────────────────
    Song(
      id: 'song_itsy_bitsy',
      title: 'The Itsy Bitsy Spider',
      searchQuery: 'Itsy Bitsy Spider nursery rhyme with hand actions',
      why: 'The finger walk is a fine-motor challenge disguised as a song, and '
          'the story arc — up, washed out, up again — holds attention.',
      skillCategory: SkillCategory.fineMotor,
      ageBandMinWeeks: 26,
      ageBandMaxWeeks: 104,
      parts: [
        SongPart(label: 'Verse', lines: [
          'The itsy bitsy spider climbed up the waterspout.',
          'Down came the rain and washed the spider out.',
          'Out came the sun and dried up all the rain,',
          'And the itsy bitsy spider climbed up the spout again.',
        ]),
      ],
    ),
    Song(
      id: 'song_row_your_boat',
      title: 'Row, Row, Row Your Boat',
      searchQuery: 'Row Row Row Your Boat nursery rhyme',
      why: 'Sit facing each other, hold hands and rock back and forth on the '
          'beat. Core strength and shared rhythm in one game.',
      skillCategory: SkillCategory.grossMotor,
      ageBandMinWeeks: 26,
      ageBandMaxWeeks: 130,
      parts: [
        SongPart(label: 'Verse', lines: [
          'Row, row, row your boat,',
          'Gently down the stream.',
          'Merrily, merrily, merrily, merrily,',
          'Life is but a dream.',
        ]),
      ],
    ),
    Song(
      id: 'song_head_shoulders',
      title: 'Head, Shoulders, Knees and Toes',
      searchQuery: 'Head Shoulders Knees and Toes song for toddlers',
      why: 'Naming body parts while touching them is how the words stick. '
          'Start slow; speeding up is the whole joke once they know it.',
      skillCategory: SkillCategory.grossMotor,
      ageBandMinWeeks: 52,
      ageBandMaxWeeks: 156,
      parts: [
        SongPart(label: 'Verse', lines: [
          'Head, shoulders, knees and toes,',
          'Knees and toes.',
          'Head, shoulders, knees and toes,',
          'Knees and toes.',
        ]),
        SongPart(label: 'Bridge', lines: [
          'And eyes and ears and mouth and nose,',
        ]),
        SongPart(label: 'Ending', lines: [
          'Head, shoulders, knees and toes,',
          'Knees and toes.',
        ]),
      ],
    ),
    Song(
      id: 'song_if_youre_happy',
      title: "If You're Happy and You Know It",
      searchQuery: "If You're Happy and You Know It song for toddlers",
      why: 'Every verse asks for a different action, so it builds listening '
          'and following a one-step instruction — and names a feeling.',
      skillCategory: SkillCategory.socialEmotional,
      ageBandMinWeeks: 52,
      ageBandMaxWeeks: 156,
      parts: [
        SongPart(label: 'Clap your hands', lines: [
          "If you're happy and you know it, clap your hands.",
          "If you're happy and you know it, clap your hands.",
          "If you're happy and you know it, and you really want to show it,",
          "If you're happy and you know it, clap your hands.",
        ]),
        SongPart(label: 'Stamp your feet', lines: [
          "If you're happy and you know it, stamp your feet.",
          "If you're happy and you know it, stamp your feet.",
          "If you're happy and you know it, and you really want to show it,",
          "If you're happy and you know it, stamp your feet.",
        ]),
        SongPart(label: 'Shout hooray', lines: [
          "If you're happy and you know it, shout hooray!",
          "If you're happy and you know it, shout hooray!",
          "If you're happy and you know it, and you really want to show it,",
          "If you're happy and you know it, shout hooray!",
        ]),
      ],
    ),

    // ─── Eighteen months to three years ─────────────────────────────────────
    Song(
      id: 'song_wheels_on_the_bus',
      title: 'The Wheels on the Bus',
      searchQuery: 'The Wheels on the Bus song for toddlers',
      why: 'Each verse swaps one word and one action, which is exactly the '
          'pattern toddlers use to work out how language slots together.',
      skillCategory: SkillCategory.language,
      ageBandMinWeeks: 52,
      ageBandMaxWeeks: 156,
      parts: [
        SongPart(label: 'Wheels', lines: [
          'The wheels on the bus go round and round,',
          'Round and round, round and round.',
          'The wheels on the bus go round and round,',
          'All through the town.',
        ]),
        SongPart(label: 'Wipers', lines: [
          'The wipers on the bus go swish, swish, swish,',
          'Swish, swish, swish, swish, swish, swish.',
          'The wipers on the bus go swish, swish, swish,',
          'All through the town.',
        ]),
        SongPart(label: 'Horn', lines: [
          'The horn on the bus goes beep, beep, beep,',
          'Beep, beep, beep, beep, beep, beep.',
          'The horn on the bus goes beep, beep, beep,',
          'All through the town.',
        ]),
        SongPart(label: 'Babies', lines: [
          'The babies on the bus go wah, wah, wah,',
          'Wah, wah, wah, wah, wah, wah.',
          'The babies on the bus go wah, wah, wah,',
          'All through the town.',
        ]),
      ],
    ),
    Song(
      id: 'song_old_macdonald',
      title: 'Old MacDonald Had a Farm',
      searchQuery: 'Old MacDonald Had a Farm song for children',
      why: 'Animal sounds are often among the first words a toddler produces, '
          'and this song asks for one every few bars.',
      skillCategory: SkillCategory.language,
      ageBandMinWeeks: 52,
      ageBandMaxWeeks: 156,
      parts: [
        SongPart(label: 'Cow', lines: [
          'Old MacDonald had a farm, E-I-E-I-O.',
          'And on that farm he had a cow, E-I-E-I-O.',
          'With a moo-moo here and a moo-moo there,',
          'Here a moo, there a moo, everywhere a moo-moo.',
          'Old MacDonald had a farm, E-I-E-I-O.',
        ]),
        SongPart(label: 'Duck', lines: [
          'Old MacDonald had a farm, E-I-E-I-O.',
          'And on that farm he had a duck, E-I-E-I-O.',
          'With a quack-quack here and a quack-quack there,',
          'Here a quack, there a quack, everywhere a quack-quack.',
          'Old MacDonald had a farm, E-I-E-I-O.',
        ]),
        SongPart(label: 'Sheep', lines: [
          'Old MacDonald had a farm, E-I-E-I-O.',
          'And on that farm he had a sheep, E-I-E-I-O.',
          'With a baa-baa here and a baa-baa there,',
          'Here a baa, there a baa, everywhere a baa-baa.',
          'Old MacDonald had a farm, E-I-E-I-O.',
        ]),
      ],
    ),
    Song(
      id: 'song_baa_baa',
      title: 'Baa, Baa, Black Sheep',
      searchQuery: 'Baa Baa Black Sheep nursery rhyme',
      why: 'Short, and shares its tune with Twinkle and the Alphabet Song — '
          'one melody a child already knows, carrying three sets of words.',
      skillCategory: SkillCategory.language,
      ageBandMinWeeks: 26,
      ageBandMaxWeeks: 156,
      parts: [
        SongPart(label: 'Verse', lines: [
          'Baa, baa, black sheep, have you any wool?',
          'Yes sir, yes sir, three bags full.',
          'One for the master, one for the dame,',
          'And one for the little boy who lives down the lane.',
        ]),
      ],
    ),
    Song(
      id: 'song_five_little_ducks',
      title: 'Five Little Ducks',
      searchQuery: 'Five Little Ducks counting song',
      why: 'Counting down from five, one verse at a time. The number words '
          'arrive in order and in a story, which beats reciting them.',
      skillCategory: SkillCategory.cognitive,
      ageBandMinWeeks: 78,
      ageBandMaxWeeks: 156,
      parts: [
        SongPart(label: 'Five', lines: [
          'Five little ducks went out one day,',
          'Over the hills and far away.',
          'Mother duck said, "Quack, quack, quack, quack,"',
          'But only four little ducks came back.',
        ]),
        SongPart(label: 'Four', lines: [
          'Four little ducks went out one day,',
          'Over the hills and far away.',
          'Mother duck said, "Quack, quack, quack, quack,"',
          'But only three little ducks came back.',
        ]),
        SongPart(label: 'Three', lines: [
          'Three little ducks went out one day,',
          'Over the hills and far away.',
          'Mother duck said, "Quack, quack, quack, quack,"',
          'But only two little ducks came back.',
        ]),
        SongPart(label: 'All back', lines: [
          'Sad mother duck went out one day,',
          'Over the hills and far away.',
          'Mother duck said, "Quack, quack, quack, quack,"',
          'And all of the five little ducks came back.',
        ]),
      ],
    ),
    Song(
      id: 'song_hickory_dickory',
      title: 'Hickory Dickory Dock',
      searchQuery: 'Hickory Dickory Dock nursery rhyme',
      why: 'Nonsense syllables on a strong beat. Toddlers copy the rhythm long '
          'before the words, which is the first step to speech.',
      skillCategory: SkillCategory.language,
      ageBandMinWeeks: 52,
      ageBandMaxWeeks: 156,
      parts: [
        SongPart(label: 'Verse', lines: [
          'Hickory dickory dock,',
          'The mouse ran up the clock.',
          'The clock struck one,',
          'The mouse ran down,',
          'Hickory dickory dock.',
        ]),
      ],
    ),
  ];

  /// The songs worth offering a child of [ageInWeeks].
  static List<Song> forAge(int ageInWeeks) =>
      all.where((s) => s.matchesAge(ageInWeeks)).toList();

  static Song? byId(String id) {
    for (final song in all) {
      if (song.id == id) return song;
    }
    return null;
  }

  /// A plain substring search over titles, for the catalogue's filter box.
  static List<Song> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.skillCategory.label.toLowerCase().contains(q))
        .toList();
  }
}
