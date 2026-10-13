import 'dart:math';

import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../services/speaker.dart';

/// See a picture, hear its word, tap the letter it starts with. The same
/// forgiving loop as sound matching: a wrong tap gets a retry, never a penalty.
/// On a right answer the word is shown with its first letter picked out, so
/// the child sees the sound they just found sitting at the front of the word.
class PictureWordScreen extends StatefulWidget {
  const PictureWordScreen({super.key, required this.speaker, this.random});

  final Speaker speaker;

  /// Injectable so tests get a deterministic round.
  final Random? random;

  @override
  State<PictureWordScreen> createState() => _PictureWordScreenState();
}

class _PictureWordScreenState extends State<PictureWordScreen> {
  late final Random _random = widget.random ?? Random();
  late LetterEntry _target;
  late List<LetterEntry> _choices;
  int _stars = 0;
  bool _solved = false;
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
    _target = pictureLetters[_random.nextInt(pictureLetters.length)];
    _choices = choicesFor(_target, _random);
    _solved = false;
    _message = '';
  }

  void _prompt() => widget.speaker
      .speak('${_target.word}. What does ${_target.word} start with?');

  void _pick(LetterEntry choice) {
    if (_solved) return; // ignore taps while the next round is loading
    // Judged by sound, as in sound matching: for "cat", C and K are the same
    // sound, and distractors never share the target's sound.
    if (choice.sound == _target.sound) {
      widget.speaker.speak('Yes! ${_target.word} starts with ${_target.sound}');
      setState(() {
        _stars++;
        _solved = true;
        _message = '🎉 Yes!';
      });
      Future<void>.delayed(const Duration(milliseconds: 2200), () {
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

  Widget _wordLabel() {
    final word = _target.word;
    if (!_solved) return const SizedBox(height: 56, key: Key('word-hidden'));
    // First letter picked out in colour; the rest in plain text.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FD),
      appBar: AppBar(
        title: const Text('Picture words'),
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
            Expanded(
              flex: 5,
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Hear the word again',
                  child: GestureDetector(
                    key: const Key('picture'),
                    onTap: _prompt,
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_target.emoji,
                            style: const TextStyle(fontSize: 140)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _wordLabel(),
            SizedBox(
              height: 40,
              child: Text(_message,
                  key: const Key('message'),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              flex: 3,
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
                                        fontSize: 64,
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
