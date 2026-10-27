import 'dart:math';

import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../services/progress_store.dart';
import '../services/speaker.dart';
import '../widgets/motion.dart';
import 'choice_game.dart';

/// See a picture, hear its word, tap the letter it starts with. The same
/// forgiving loop as sound matching. On a right answer the word is shown with
/// its first letter picked out, so the child sees the sound they just found
/// sitting at the front of the word.
class PictureWordScreen extends StatelessWidget {
  const PictureWordScreen({
    super.key,
    required this.speaker,
    required this.progress,
    this.random,
  });

  final Speaker speaker;
  final ProgressStore progress;
  final Random? random;

  @override
  Widget build(BuildContext context) {
    return ChoiceGame(
      title: 'Picture words',
      background: const Color(0xFFEAF4FD),
      speaker: speaker,
      progress: progress,
      random: random,
      pool: pictureLetters,
      choiceFontSize: 64,
      prompt: (t) => '${t.word}. What does ${t.word} start with?',
      success: (t) => 'Yes! ${t.word} starts with ${t.sound}',
      hero: (context, round) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Semantics(
              button: true,
              label: 'Hear the word again',
              child: GestureDetector(
                key: const Key('picture'),
                onTap: round.replay,
                // The picture hops each time it is spoken or the round is won.
                child: Bounce(
                  trigger: round.pulse,
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        round.target.emoji,
                        style: const TextStyle(fontSize: 140),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _WordLabel(word: round.target.word, revealed: round.solved),
        ],
      ),
    );
  }
}

class _WordLabel extends StatelessWidget {
  const _WordLabel({required this.word, required this.revealed});

  final String word;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    if (!revealed) return const SizedBox(height: 56, key: Key('word-hidden'));
    return SizedBox(
      height: 56,
      child: Text.rich(
        key: const Key('word-revealed'),
        TextSpan(children: [
          TextSpan(
            text: word[0].toUpperCase(),
            style: const TextStyle(color: Color(0xFFE64A19)),
          ),
          TextSpan(text: word.substring(1)),
        ]),
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
      ),
    );
  }
}
