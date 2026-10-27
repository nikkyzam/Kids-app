import 'dart:math';

import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../services/progress_store.dart';
import '../services/speaker.dart';
import 'choice_game.dart';

/// Hear a sound, tap the letter that makes it. Three big choices; a wrong tap
/// is met with an encouraging retry, never a penalty or a buzzer.
class SoundMatchScreen extends StatelessWidget {
  const SoundMatchScreen({
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
      title: 'Match the sound',
      background: const Color(0xFFEFF8EF),
      speaker: speaker,
      progress: progress,
      random: random,
      pool: letters,
      prompt: (t) => '${t.sound}. Which letter?',
      success: (t) => '${t.letter} says ${t.sound}',
      hero: (context, round) => IconButton(
        key: const Key('replay'),
        iconSize: 96,
        tooltip: 'Hear it again',
        onPressed: round.replay,
        icon: const Icon(Icons.volume_up_rounded),
      ),
    );
  }
}
