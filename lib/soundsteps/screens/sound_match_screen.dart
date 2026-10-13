import 'dart:math';

import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../services/speaker.dart';

/// Hear a sound, tap the letter that makes it. Three big choices; a wrong tap
/// is met with an encouraging retry, never a penalty or a buzzer.
class SoundMatchScreen extends StatefulWidget {
  const SoundMatchScreen({super.key, required this.speaker, this.random});

  final Speaker speaker;

  /// Injectable so tests get a deterministic round.
  final Random? random;

  @override
  State<SoundMatchScreen> createState() => _SoundMatchScreenState();
}

class _SoundMatchScreenState extends State<SoundMatchScreen> {
  late final Random _random = widget.random ?? Random();
  late LetterEntry _target;
  late List<LetterEntry> _choices;
  int _stars = 0;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  @override
  void dispose() {
    widget.speaker.stop();
    super.dispose();
  }

  void _newRound() {
    _target = letters[_random.nextInt(letters.length)];
    _choices = choicesFor(_target, _random);
    _message = '';
  }

  void _prompt() => widget.speaker.speak('${_target.sound}. Which letter?');

  void _pick(LetterEntry choice) {
    // Judged by sound, not identity: C and K both say "kuh" and both are right.
    if (choice.sound == _target.sound) {
      widget.speaker.speak('Great job! ${choice.letter} says ${choice.sound}');
      setState(() {
        _stars++;
        _message = '🎉 Yes!';
      });
      Future<void>.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(_newRound);
        _prompt();
      });
    } else {
      widget.speaker.speak('Try again');
      setState(() => _message = 'Try again!');
      _prompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF8EF),
      appBar: AppBar(
        title: const Text('Match the sound'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('⭐ $_stars',
                  key: const Key('stars'),
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            IconButton(
              key: const Key('replay'),
              iconSize: 96,
              tooltip: 'Hear it again',
              onPressed: _prompt,
              icon: const Icon(Icons.volume_up_rounded),
            ),
            SizedBox(
              height: 48,
              child: Text(_message,
                  key: const Key('message'),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Row(
                children: [
                  for (final choice in _choices)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Semantics(
                          button: true,
                          label: 'Letter ${choice.letter}',
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              key: Key('choice-${choice.letter}'),
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _pick(choice),
                              child: Center(
                                child: Text(choice.letter,
                                    style: const TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.w800)),
                              ),
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
