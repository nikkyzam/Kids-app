/// An animal sticker for the sticker book.
class Sticker {
  const Sticker(this.emoji, this.name);

  final String emoji;
  final String name;
}

/// How many stars earn one sticker. Small enough that a toddler sees a new
/// one within a few minutes of play; the set is finite on purpose (no endless
/// treadmill), 30 stickers = 150 stars.
const int starsPerSticker = 5;

/// Unlock order is fixed (not random) so it is predictable and fair: no
/// loot-box mechanics in a toddler app. Familiar animals first.
const List<Sticker> stickers = [
  Sticker('🐶', 'puppy'),
  Sticker('🐱', 'kitten'),
  Sticker('🐰', 'bunny'),
  Sticker('🐻', 'bear'),
  Sticker('🦁', 'lion'),
  Sticker('🐸', 'frog'),
  Sticker('🐵', 'monkey'),
  Sticker('🐷', 'pig'),
  Sticker('🐮', 'cow'),
  Sticker('🐔', 'chicken'),
  Sticker('🐯', 'tiger'),
  Sticker('🐼', 'panda'),
  Sticker('🐨', 'koala'),
  Sticker('🦊', 'fox'),
  Sticker('🐧', 'penguin'),
  Sticker('🦉', 'owl'),
  Sticker('🐢', 'turtle'),
  Sticker('🐙', 'octopus'),
  Sticker('🦋', 'butterfly'),
  Sticker('🐞', 'ladybug'),
  Sticker('🐝', 'bee'),
  Sticker('🐳', 'whale'),
  Sticker('🐬', 'dolphin'),
  Sticker('🦒', 'giraffe'),
  Sticker('🐘', 'elephant'),
  Sticker('🦓', 'zebra'),
  Sticker('🦔', 'hedgehog'),
  Sticker('🦄', 'unicorn'),
  Sticker('🦕', 'dinosaur'),
  Sticker('🦖', 'T. rex'),
];

/// Stickers earned for a star total.
int stickersFor(int stars) {
  final n = stars ~/ starsPerSticker;
  return n > stickers.length ? stickers.length : n;
}
