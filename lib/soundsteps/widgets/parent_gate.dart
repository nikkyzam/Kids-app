import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/number_words.dart';

/// A question only a grown-up will answer: "What is seven plus eight?", with
/// the question and every option written in words. A 2-4 year old can neither
/// read it nor paste it into a calculator.
///
/// SoundSteps has its own gate rather than reusing PlaySteps' dialog because
/// that file also pulls in PlaySteps' theme; this one depends only on the
/// number-spelling helper.
class ParentGateChallenge {
  const ParentGateChallenge({
    required this.a,
    required this.b,
    required this.options,
  });

  final int a;
  final int b;
  final List<int> options;

  int get answer => a + b;

  String get question =>
      'What is ${NumberWords.of(a)} plus ${NumberWords.of(b)}?';

  static const int optionCount = 4;

  static ParentGateChallenge generate([Random? random]) {
    final r = random ?? Random();
    final a = 6 + r.nextInt(5); // 6..10
    final b = 5 + r.nextInt(5); // 5..9
    final answer = a + b;
    // Plausible wrong answers: near the real one, never equal to it.
    final wrong = <int>{};
    while (wrong.length < optionCount - 1) {
      final candidate = answer + r.nextInt(7) - 3;
      if (candidate != answer && candidate > 0) wrong.add(candidate);
    }
    return ParentGateChallenge(
      a: a,
      b: b,
      options: [answer, ...wrong]..shuffle(r),
    );
  }
}

/// Shows the gate; completes with true only if answered correctly.
Future<bool> showParentGate(BuildContext context, {Random? random}) async {
  final passed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ParentGateDialog(random: random),
  );
  return passed == true;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({this.random});

  final Random? random;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  late final ParentGateChallenge _challenge =
      ParentGateChallenge.generate(widget.random);
  bool _failed = false;

  void _answer(int value) {
    if (value == _challenge.answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grown-ups only'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_challenge.question, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in _challenge.options)
                OutlinedButton(
                  onPressed: () => _answer(o),
                  child: Text(NumberWords.of(o)),
                ),
            ],
          ),
          if (_failed)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Not quite. Try again.'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
