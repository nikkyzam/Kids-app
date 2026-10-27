import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../services/progress_store.dart';
import '../services/speaker.dart';
import '../widgets/motion.dart';

/// Alphabet grid. Tap a letter to hear its sound and a picture word, and see
/// the picture. Exploration only: nothing to get wrong. Letters the child has
/// mastered in the games carry a small star, so progress is visible here too.
class LettersScreen extends StatefulWidget {
  const LettersScreen({
    super.key,
    required this.speaker,
    required this.progress,
  });

  final Speaker speaker;
  final ProgressStore progress;

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  LetterEntry? _selected;
  final Map<String, int> _bounces = {};

  void _select(LetterEntry entry) {
    setState(() {
      _selected = entry;
      _bounces[entry.letter] = (_bounces[entry.letter] ?? 0) + 1;
    });
    widget.speaker
        .speak('${entry.sound}. ${entry.letter} is for ${entry.word}');
  }

  @override
  void dispose() {
    widget.speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(
        title: const Text('Letters'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Center(
                // The picture pops in; with reduced motion it just swaps.
                child: AnimatedSwitcher(
                  duration: motionEnabled(context)
                      ? const Duration(milliseconds: 300)
                      : Duration.zero,
                  // Only the new picture: the default layout stacks the old
                  // one on top while it shrinks, and the two texts overlap.
                  layoutBuilder: (current, previous) =>
                      current ?? const SizedBox.shrink(),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: animation, curve: Curves.elasticOut),
                    child: child,
                  ),
                  child: selected == null
                      ? const Text('Tap a letter!',
                          key: Key('letters-hint'),
                          style: TextStyle(fontSize: 24))
                      : Row(
                          key: ValueKey(selected.letter),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(selected.emoji,
                                style: const TextStyle(fontSize: 64)),
                            const SizedBox(width: 12),
                            Text(
                              '${selected.letter} ${selected.word}',
                              key: const Key('selected-letter'),
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.progress,
                builder: (context, _) => GridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.all(12),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (final entry in letters)
                      Bounce(
                        trigger: _bounces[entry.letter] ?? 0,
                        child: _LetterTile(
                          entry: entry,
                          selected: entry == selected,
                          mastered:
                              widget.progress.statsFor(entry.letter).mastered,
                          onTap: () => _select(entry),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _pastels = [
  Color(0xFFFFE0B2),
  Color(0xFFC8E6C9),
  Color(0xFFBBDEFB),
  Color(0xFFE1BEE7),
  Color(0xFFFFF9C4),
  Color(0xFFFFCDD2),
];

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.entry,
    required this.selected,
    required this.mastered,
    required this.onTap,
  });

  final LetterEntry entry;
  final bool selected;
  final bool mastered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: mastered
          ? 'Letter ${entry.letter}, learned'
          : 'Letter ${entry.letter}',
      child: Material(
        // Each letter its own soft colour, so the grid reads as a rainbow
        // rather than a wall of white.
        color: selected
            ? const Color(0xFFFF8A5B)
            : _pastels[entry.letter.codeUnitAt(0) % _pastels.length],
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: Key('letter-${entry.letter}'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                entry.letter,
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
              ),
              if (mastered)
                Positioned(
                  top: 4,
                  right: 6,
                  child: Text('⭐',
                      key: Key('mastered-${entry.letter}'),
                      style: const TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
