import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/number_words.dart';

/// The arithmetic operations the gate can ask about.
///
/// Deliberately three rather than one: a gate that always multiplies is a gate
/// a child learns the shape of.
enum GateOperator {
  plus,
  minus,
  times;

  String get word {
    switch (this) {
      case GateOperator.plus:
        return 'plus';
      case GateOperator.minus:
        return 'minus';
      case GateOperator.times:
        return 'times';
    }
  }

  int apply(int a, int b) {
    switch (this) {
      case GateOperator.plus:
        return a + b;
      case GateOperator.minus:
        return a - b;
      case GateOperator.times:
        return a * b;
    }
  }
}

/// One generated challenge. Split out from the widget so the generator can be
/// tested directly, over many seeds, rather than by tapping through a dialog.
class ParentalGateChallenge {
  final int a;
  final int b;
  final GateOperator operator;
  final List<int> options;

  const ParentalGateChallenge({
    required this.a,
    required this.b,
    required this.operator,
    required this.options,
  });

  int get answer => operator.apply(a, b);

  /// The question, entirely in words: "What is seven times eight?"
  String get question =>
      'What is ${NumberWords.of(a)} ${operator.word} ${NumberWords.of(b)}?';

  static const int optionCount = 6;

  static ParentalGateChallenge generate([Random? random]) {
    final rng = random ?? Random();
    final operator =
        GateOperator.values[rng.nextInt(GateOperator.values.length)];

    late int a;
    late int b;
    switch (operator) {
      case GateOperator.plus:
        a = rng.nextInt(8) + 2; // 2–9
        b = rng.nextInt(8) + 2; // 2–9
      case GateOperator.minus:
        // Ordered so the answer is always positive: a parent should never have
        // to reason about negative numbers to get into Settings.
        a = rng.nextInt(8) + 5; // 5–12
        b = rng.nextInt(a - 2) + 2; // 2–(a-1)
      case GateOperator.times:
        a = rng.nextInt(8) + 2; // 2–9
        b = rng.nextInt(8) + 2; // 2–9
    }

    final answer = operator.apply(a, b);
    // Distractors sit close to the answer, so the right one cannot be picked
    // out by being the largest or the odd one out.
    final options = <int>{answer};
    while (options.length < optionCount) {
      final offset = rng.nextInt(13) - 6;
      final candidate = answer + offset;
      if (candidate > 0 && candidate <= 100) options.add(candidate);
    }

    return ParentalGateChallenge(
      a: a,
      b: b,
      operator: operator,
      options: options.toList()..shuffle(rng),
    );
  }
}

class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({super.key});

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late ParentalGateChallenge _challenge;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _challenge = ParentalGateChallenge.generate();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
          SizedBox(width: 8),
          Text('Parent Check'),
        ],
      ),
      // A bounded width is required because the content holds a GridView (a
      // scrollable), which cannot answer AlertDialog's intrinsic-width query.
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _challenge.question,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_failed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Incorrect — try again',
                    style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: _challenge.options
                  .map((option) => OutlinedButton(
                        onPressed: () => _checkAnswer(option),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        // Words, not digits, for the same reason the question
                        // is in words: matching digits is something a child can
                        // do without reading.
                        child: FittedBox(
                          child: Text(NumberWords.of(option),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _checkAnswer(int answer) {
    if (answer == _challenge.answer) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      // A wrong answer both says so and asks something else, so repeated
      // guessing cannot converge on one question's answer set.
      _challenge = ParentalGateChallenge.generate();
      _failed = true;
    });
  }
}
