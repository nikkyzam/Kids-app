import 'package:flutter/material.dart';

import '../services/speaker.dart';
import 'letters_screen.dart';
import 'sound_match_screen.dart';

/// Two big buttons and nothing else: a 2-year-old navigates by picture.
class SoundStepsHome extends StatelessWidget {
  const SoundStepsHome({super.key, required this.speaker});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'SoundSteps',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _BigButton(
                  key: const Key('open-letters'),
                  color: const Color(0xFFFFB74D),
                  emoji: '🔤',
                  label: 'Letters',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LettersScreen(speaker: speaker),
                  )),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _BigButton(
                  key: const Key('open-match'),
                  color: const Color(0xFF81C784),
                  emoji: '👂',
                  label: 'Match the sound',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SoundMatchScreen(speaker: speaker),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    super.key,
    required this.color,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 72)),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
