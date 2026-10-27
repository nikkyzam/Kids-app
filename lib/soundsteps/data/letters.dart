import 'dart:math';

/// One letter of the alphabet as a toddler meets it: the letter, the sound it
/// makes, and a picture word that starts with that sound.
class LetterEntry {
  const LetterEntry({
    required this.letter,
    required this.sound,
    required this.word,
    required this.emoji,
  });

  /// Upper-case letter shown on screen.
  final String letter;

  /// Spelled out for the speech engine so it says the sound, not the name:
  /// "buh" rather than "bee". Text-to-speech has no phoneme mode, so these are
  /// phonetic approximations.
  final String sound;

  /// A familiar word starting with the sound.
  final String word;

  /// Must be an emoji that is colourful by default. Text-default symbols
  /// (☀ ☂ 🖼, written with an invisible U+FE0F to request colour) render as
  /// black glyphs on some renderers; a test enforces this.
  final String emoji;
}

const List<LetterEntry> letters = [
  LetterEntry(letter: 'A', sound: 'ah', word: 'apple', emoji: '🍎'),
  LetterEntry(letter: 'B', sound: 'buh', word: 'ball', emoji: '⚽'),
  LetterEntry(letter: 'C', sound: 'kuh', word: 'cat', emoji: '🐱'),
  LetterEntry(letter: 'D', sound: 'duh', word: 'dog', emoji: '🐶'),
  LetterEntry(letter: 'E', sound: 'eh', word: 'egg', emoji: '🥚'),
  LetterEntry(letter: 'F', sound: 'fff', word: 'fish', emoji: '🐟'),
  LetterEntry(letter: 'G', sound: 'guh', word: 'goat', emoji: '🐐'),
  LetterEntry(letter: 'H', sound: 'huh', word: 'hat', emoji: '🎩'),
  LetterEntry(letter: 'I', sound: 'ih', word: 'igloo', emoji: '🛖'),
  LetterEntry(letter: 'J', sound: 'juh', word: 'jam', emoji: '🍓'),
  LetterEntry(letter: 'K', sound: 'kuh', word: 'kite', emoji: '🪁'),
  LetterEntry(letter: 'L', sound: 'lll', word: 'lion', emoji: '🦁'),
  LetterEntry(letter: 'M', sound: 'mmm', word: 'moon', emoji: '🌙'),
  LetterEntry(letter: 'N', sound: 'nnn', word: 'nest', emoji: '🪺'),
  LetterEntry(letter: 'O', sound: 'aw', word: 'octopus', emoji: '🐙'),
  LetterEntry(letter: 'P', sound: 'puh', word: 'pig', emoji: '🐷'),
  LetterEntry(letter: 'Q', sound: 'kwuh', word: 'queen', emoji: '👑'),
  LetterEntry(letter: 'R', sound: 'rrr', word: 'rabbit', emoji: '🐰'),
  LetterEntry(letter: 'S', sound: 'sss', word: 'sun', emoji: '🌞'),
  LetterEntry(letter: 'T', sound: 'tuh', word: 'tiger', emoji: '🐯'),
  LetterEntry(letter: 'U', sound: 'uh', word: 'umbrella', emoji: '☔'),
  LetterEntry(letter: 'V', sound: 'vvv', word: 'van', emoji: '🚐'),
  LetterEntry(letter: 'W', sound: 'wuh', word: 'whale', emoji: '🐳'),
  LetterEntry(letter: 'X', sound: 'ks', word: 'box', emoji: '📦'),
  LetterEntry(letter: 'Y', sound: 'yuh', word: 'yo-yo', emoji: '🪀'),
  LetterEntry(letter: 'Z', sound: 'zzz', word: 'zebra', emoji: '🦓'),
];

/// Letters usable in the picture-to-word game: those whose picture word
/// *starts* with the letter's sound. X is out: "box" ends with it.
final List<LetterEntry> pictureLetters =
    letters.where((l) => l.letter != 'X').toList(growable: false);

/// The target plus two distractors, shuffled.
///
/// All three choices make different sounds. A distractor sharing the target's
/// sound would make the right answer ambiguous (C and K both say "kuh"), and
/// two distractors sharing a sound with each other would just be noise.
List<LetterEntry> choicesFor(LetterEntry target, Random random) {
  final seen = {target.sound};
  final distractors = <LetterEntry>[];
  for (final l in [...letters]..shuffle(random)) {
    if (seen.add(l.sound)) distractors.add(l);
    if (distractors.length == 2) break;
  }
  return [target, ...distractors]..shuffle(random);
}
