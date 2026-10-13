import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../services/speaker.dart';

/// Alphabet grid. Tap a letter to hear its sound and a picture word, and see
/// the picture. Exploration only: nothing to get wrong.
class LettersScreen extends StatefulWidget {
  const LettersScreen({super.key, required this.speaker});

  final Speaker speaker;

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  LetterEntry? _selected;

  void _select(LetterEntry entry) {
    setState(() => _selected = entry);
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
                child: selected == null
                    ? const Text('Tap a letter!',
                        style: TextStyle(fontSize: 24))
                    : Row(
                        key: const Key('selected-letter'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(selected.emoji,
                              style: const TextStyle(fontSize: 64)),
                          const SizedBox(width: 12),
                          Text(
                            '${selected.letter} ${selected.word}',
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.all(12),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (final entry in letters)
                    Semantics(
                      button: true,
                      label: 'Letter ${entry.letter}',
                      child: Material(
                        color: entry == selected
                            ? const Color(0xFFFF8A5B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          key: Key('letter-${entry.letter}'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _select(entry),
                          child: Center(
                            child: Text(
                              entry.letter,
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
