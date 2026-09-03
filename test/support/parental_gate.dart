import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/utils/number_words.dart';
import 'package:playsteps/widgets/parental_gate_dialog.dart';

/// Solves the parental gate the way a parent would: read the question, work
/// out the answer, tap it.
///
/// Kept in one place so a change to the gate — a new operator, a different
/// number of options — is one edit rather than a hunt through the suite. It
/// reads the challenge out of the rendered text rather than reaching into the
/// widget's state, so it also proves the question is legible.
Future<void> solveParentalGate(WidgetTester tester) async {
  await tester.tap(find.text(NumberWords.of(parentalGateAnswer(tester))).first);
  await tester.pump(const Duration(milliseconds: 400));
}

/// The answer to the challenge currently on screen.
int parentalGateAnswer(WidgetTester tester) {
  final question = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere(
        (s) => s.startsWith('What is '),
        orElse: () => throw StateError('no parental gate question on screen'),
      );

  final body = question.substring('What is '.length).replaceAll('?', '');

  for (final operator in GateOperator.values) {
    final separator = ' ${operator.word} ';
    if (!body.contains(separator)) continue;
    final parts = body.split(separator);
    return operator.apply(_value(parts[0]), _value(parts[1]));
  }

  throw StateError('parental gate question used no known operator: $question');
}

/// Taps "Unlock Settings" and then solves the gate behind it.
Future<void> unlockSettings(WidgetTester tester) async {
  await tester.tap(find.text('Unlock Settings'));
  await tester.pump(const Duration(milliseconds: 400));
  await solveParentalGate(tester);
}

/// Inverts [NumberWords] over the range the gate can produce.
int _value(String word) {
  for (int n = 0; n <= 100; n++) {
    if (NumberWords.of(n) == word) return n;
  }
  throw StateError('not a number word: "$word"');
}
