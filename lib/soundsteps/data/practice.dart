import 'dart:math';

import '../services/progress_store.dart';
import 'letters.dart';

/// How likely a letter is to come up next, relative to others.
///
/// Letters a child keeps missing come up most (up to 11x a mastered one), new
/// letters a little more than ones in progress, and mastered letters least but
/// never never: toddlers forget, and a mastered letter still makes a good easy
/// win. This is simple spaced practice, not a full scheduler.
int practiceWeight(LetterStats s) {
  if (s.mastered) return 1;
  if (s.misses > s.correct) return 3 + 2 * min(s.misses - s.correct, 4);
  if (s.isNew) return 3;
  return 2;
}

/// Picks the next target from [pool], weighted by [practiceWeight].
/// Never repeats [previous] back-to-back unless the pool has only one letter.
LetterEntry pickTarget(
  List<LetterEntry> pool,
  ProgressStore progress,
  Random random, {
  LetterEntry? previous,
}) {
  final candidates = pool.length > 1 && previous != null
      ? pool.where((l) => l.letter != previous.letter).toList()
      : pool;
  final weights = [
    for (final c in candidates) practiceWeight(progress.statsFor(c.letter)),
  ];
  var roll = random.nextInt(weights.fold(0, (a, b) => a + b));
  for (var i = 0; i < candidates.length; i++) {
    roll -= weights[i];
    if (roll < 0) return candidates[i];
  }
  return candidates.last; // unreachable; keeps the analyzer and compiler happy
}
