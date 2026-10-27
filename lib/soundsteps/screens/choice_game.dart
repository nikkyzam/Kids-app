import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../data/stickers.dart';
import '../data/practice.dart';
import '../services/progress_store.dart';
import '../services/speaker.dart';
import '../widgets/mascot.dart';
import '../widgets/motion.dart';

/// What the hero area is told about the current round.
class GameRound {
  const GameRound({
    required this.target,
    required this.solved,
    required this.pulse,
    required this.replay,
  });

  final LetterEntry target;

  /// The child has found the answer; the next round is about to load.
  final bool solved;

  /// Goes up each time the prompt is spoken or the round is won. Feed it to a
  /// [Bounce] so the picture reacts when it speaks.
  final int pulse;

  /// Speak the prompt again.
  final VoidCallback replay;
}

/// The loop shared by the toddler games: hear a prompt, tap one of three
/// letters, get encouragement, move on.
///
/// Rules the games rely on, kept here so they cannot drift apart:
///  * a wrong tap is a retry, never a penalty (a shake, "try again", no sound
///    effect, nothing lost);
///  * a right answer always earns a star, but only a first-try answer counts
///    toward mastering the letter;
///  * letters the child misses come up more often ([pickTarget]).
class ChoiceGame extends StatefulWidget {
  const ChoiceGame({
    super.key,
    required this.title,
    required this.background,
    required this.speaker,
    required this.progress,
    required this.pool,
    required this.prompt,
    required this.success,
    required this.hero,
    this.random,
    this.choiceFontSize = 64,
    this.celebrationDelay = const Duration(milliseconds: 2200),
    this.idleNudgeAfter = const Duration(seconds: 8),
  });

  final String title;
  final Color background;
  final Speaker speaker;
  final ProgressStore progress;

  /// Letters the game may ask about.
  final List<LetterEntry> pool;

  final String Function(LetterEntry target) prompt;

  /// The teaching half of the reply to a right answer ("B says buh"); a
  /// varied word of praise is put in front of it.
  final String Function(LetterEntry target) success;
  final Widget Function(BuildContext context, GameRound round) hero;

  /// Injectable so tests get a deterministic game.
  final Random? random;
  final double choiceFontSize;

  /// How long the win is shown before the next round.
  final Duration celebrationDelay;

  /// Quiet time before the game nudges a child who has drifted off: the
  /// answer wiggles and the prompt is repeated. At most twice per round, so
  /// it invites rather than nags.
  final Duration idleNudgeAfter;

  /// Rotated so the same sentence isn't heard every time; variety holds a
  /// toddler's attention longer than repetition.
  static const praise = [
    'Yes!',
    'Great job!',
    'Wow!',
    'You did it!',
    'Super!',
    'Yay!',
    'Well done!',
  ];

  /// Bright, distinct, and dark enough for white letters to stay legible.
  static const choiceColors = [
    Color(0xFFFF7043),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFD81B60),
  ];

  @override
  State<ChoiceGame> createState() => _ChoiceGameState();
}

class _ChoiceGameState extends State<ChoiceGame> {
  late final Random _random = widget.random ?? Random();
  late LetterEntry _target;
  late List<LetterEntry> _choices;
  LetterEntry? _lastTarget;
  bool _solved = false;
  bool _missed = false;
  String _message = '';
  int _pulse = 0;
  int _bursts = 0;
  final Map<String, int> _shakes = {};
  final Map<String, int> _bounces = {};
  Timer? _next;
  Timer? _idle;
  int _nudges = 0;
  Sticker? _newSticker;
  int _colorOffset = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  @override
  void dispose() {
    _next?.cancel();
    _idle?.cancel();
    widget.speaker.stop();
    super.dispose();
  }

  void _newRound() {
    _target = pickTarget(
      widget.pool,
      widget.progress,
      _random,
      previous: _lastTarget,
    );
    _lastTarget = _target;
    _choices = choicesFor(_target, _random);
    _solved = false;
    _missed = false;
    _message = '';
    _shakes.clear();
    _bounces.clear();
    _nudges = 0;
    _newSticker = null;
    _colorOffset = _random.nextInt(ChoiceGame.choiceColors.length);
  }

  void _armIdleNudge() {
    _idle?.cancel();
    _idle = Timer(widget.idleNudgeAfter, () {
      if (!mounted || _solved || _nudges >= 2) return;
      _nudges++;
      setState(
          () => _bounces[_target.letter] = (_bounces[_target.letter] ?? 0) + 1);
      _prompt('Listen! ');
    });
  }

  void _prompt([String prefix = '']) {
    setState(() => _pulse++);
    widget.speaker.speak('$prefix${widget.prompt(_target)}');
    _armIdleNudge();
  }

  void _pick(LetterEntry choice) {
    if (_solved) return; // ignore taps while the next round is loading
    // Judged by sound, not identity: C and K both say "kuh" and are both right.
    if (choice.sound == _target.sound) {
      _idle?.cancel();
      final stickersBefore = widget.progress.stickersUnlocked;
      widget.progress.recordSuccess(_target.letter, firstTry: !_missed);
      final earned = widget.progress.stickersUnlocked > stickersBefore
          ? stickers[widget.progress.stickersUnlocked - 1]
          : null;
      final cheer =
          ChoiceGame.praise[_random.nextInt(ChoiceGame.praise.length)];
      // One utterance, for the same reason as "Try again" below.
      widget.speaker.speak('$cheer ${widget.success(_target)}'
          '${earned == null ? '' : ' You won a sticker! The ${earned.name}!'}');
      setState(() {
        _newSticker = earned;
        _solved = true;
        _message = '🎉 Yes!';
        _pulse++;
        _bursts++;
        _bounces[choice.letter] = (_bounces[choice.letter] ?? 0) + 1;
      });
      _next = Timer(
          widget.celebrationDelay +
              (earned == null ? Duration.zero : const Duration(seconds: 2)),
          () {
        if (!mounted) return;
        setState(_newRound);
        _prompt();
      });
    } else {
      // One miss per round however many wrong taps: a toddler mashing the
      // wrong button shouldn't bury the letter in misses.
      if (!_missed) {
        _missed = true;
        widget.progress.recordMiss(_target.letter);
      }
      setState(() {
        _message = 'Try again!';
        _shakes[choice.letter] = (_shakes[choice.letter] ?? 0) + 1;
      });
      // One utterance: the speaker cancels what it is saying when asked to
      // speak again, so "Try again" followed by the prompt would be cut off.
      _prompt('Try again. ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ListenableBuilder(
                listenable: widget.progress,
                builder: (_, __) => Text(
                  '⭐ ${widget.progress.stars}',
                  key: const Key('stars'),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: widget.hero(
                      context,
                      GameRound(
                        target: _target,
                        solved: _solved,
                        pulse: _pulse,
                        replay: _prompt,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 0,
                    child: Mascot(
                      size: 76,
                      cheer: _bursts,
                      mood: _solved
                          ? MascotMood.happy
                          : _missed
                              ? MascotMood.encourage
                              : MascotMood.idle,
                    ),
                  ),
                  Positioned.fill(child: StarBurst(trigger: _bursts)),
                  if (_newSticker != null)
                    Positioned.fill(child: _NewStickerBanner(_newSticker!)),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: Text(
                _message,
                key: const Key('message'),
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  for (final (i, choice) in _choices.indexed)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Shake(
                          trigger: _shakes[choice.letter] ?? 0,
                          child: Bounce(
                            trigger: _bounces[choice.letter] ?? 0,
                            child: Semantics(
                              button: true,
                              label: 'Letter ${choice.letter}',
                              child: Material(
                                color: ChoiceGame.choiceColors[
                                    (i + _colorOffset) %
                                        ChoiceGame.choiceColors.length],
                                elevation: 3,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  key: Key('choice-${choice.letter}'),
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => _pick(choice),
                                  child: Center(
                                    child: Text(
                                      choice.letter,
                                      style: TextStyle(
                                        fontSize: widget.choiceFontSize,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
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

/// "New sticker!" — the sticker zooms in over the picture for the rest of the
/// celebration. Taps go through to nothing; the next round clears it.
class _NewStickerBanner extends StatelessWidget {
  const _NewStickerBanner(this.sticker);

  final Sticker sticker;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        key: const Key('new-sticker'),
        color: const Color(0xCCFFFFFF),
        alignment: Alignment.center,
        child: FittedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'New sticker!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: motionEnabled(context) ? 0.2 : 1, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child:
                    Text(sticker.emoji, style: const TextStyle(fontSize: 120)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
