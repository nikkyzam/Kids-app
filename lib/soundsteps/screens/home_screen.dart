import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../services/speaker.dart';
import '../widgets/parent_gate.dart';
import 'letters_screen.dart';
import 'picture_word_screen.dart';
import 'sound_match_screen.dart';

/// Two big buttons and nothing else: a 2-year-old navigates by picture.
class SoundStepsHome extends StatelessWidget {
  const SoundStepsHome({
    super.key,
    required this.speaker,
    required this.progress,
  });

  final Speaker speaker;
  final ProgressStore progress;

  /// Parents only: a long-press on the star count, then the parental gate,
  /// then a confirmation. Toddlers can neither find nor pass it by accident.
  Future<void> _resetProgress(BuildContext context) async {
    final passed = await showParentGate(context);
    if (!passed || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
            'This clears your child\'s stars and learned letters on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-reset'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) await progress.reset();
  }

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
              GestureDetector(
                key: const Key('home-stars'),
                onLongPress: () => _resetProgress(context),
                child: ListenableBuilder(
                  listenable: progress,
                  builder: (_, __) => Text(
                    '⭐ ${progress.stars}   🔤 ${progress.masteredCount}/26',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _BigButton(
                  key: const Key('open-letters'),
                  color: const Color(0xFFFFB74D),
                  emoji: '🔤',
                  label: 'Letters',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        LettersScreen(speaker: speaker, progress: progress),
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
                    builder: (_) =>
                        SoundMatchScreen(speaker: speaker, progress: progress),
                  )),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _BigButton(
                  key: const Key('open-picture-word'),
                  color: const Color(0xFF64B5F6),
                  emoji: '🖼️',
                  label: 'Picture words',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        PictureWordScreen(speaker: speaker, progress: progress),
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
          // scaleDown: on a short phone the three stacked buttons get little
          // height; shrink the content to fit rather than overflow.
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 56)),
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
        ),
      ),
    );
  }
}
