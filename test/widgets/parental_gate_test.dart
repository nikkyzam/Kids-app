import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/utils/number_words.dart';
import 'package:playsteps/widgets/parental_gate_dialog.dart';

void main() {
  /// A thousand seeds rather than one: a gate that is only correct for the
  /// question the test happened to draw is not a gate.
  Iterable<ParentalGateChallenge> manyChallenges() =>
      Iterable.generate(1000, (i) => ParentalGateChallenge.generate(Random(i)));

  group('the generated challenge', () {
    test('always includes the right answer exactly once', () {
      for (final c in manyChallenges()) {
        expect(c.options.where((o) => o == c.answer), hasLength(1),
            reason: c.question);
      }
    });

    test('offers the full set of distinct options', () {
      for (final c in manyChallenges()) {
        expect(c.options, hasLength(ParentalGateChallenge.optionCount));
        expect(c.options.toSet(), hasLength(ParentalGateChallenge.optionCount));
      }
    });

    test('never asks a parent to reason about negative numbers', () {
      for (final c in manyChallenges()) {
        expect(c.answer, greaterThan(0), reason: c.question);
        expect(c.options.every((o) => o > 0), isTrue, reason: c.question);
      }
    });

    test('keeps every number inside the range that spells out', () {
      for (final c in manyChallenges()) {
        for (final n in [c.a, c.b, c.answer, ...c.options]) {
          expect(n, inInclusiveRange(0, 100));
          expect(NumberWords.of(n), isNot(contains(RegExp(r'[0-9]'))));
        }
      }
    });

    test('uses all three operators, so its shape cannot be learned', () {
      final used = manyChallenges().map((c) => c.operator).toSet();
      expect(used, containsAll(GateOperator.values));
    });

    test('writes the question entirely in words', () {
      for (final c in manyChallenges()) {
        // No digits anywhere: pasting the question into a calculator gets
        // nowhere, which is the point.
        expect(c.question, isNot(contains(RegExp(r'[0-9]'))),
            reason: c.question);
        expect(c.question, startsWith('What is '));
        expect(c.question, endsWith('?'));
        expect(c.question, contains(c.operator.word));
      }
    });

    test('the answer really is the arithmetic it asks for', () {
      for (final c in manyChallenges()) {
        switch (c.operator) {
          case GateOperator.plus:
            expect(c.answer, c.a + c.b);
          case GateOperator.minus:
            expect(c.answer, c.a - c.b);
          case GateOperator.times:
            expect(c.answer, c.a * c.b);
        }
      }
    });

    test('does not give the answer away by being the largest option', () {
      // If the answer were reliably the biggest or smallest, a child tapping
      // the extreme would pass more often than by chance.
      final largest = manyChallenges()
          .where((c) => c.answer == c.options.reduce(max))
          .length;
      expect(largest, lessThan(400));
    });
  });

  group('NumberWords', () {
    test('spells the range the gate uses', () {
      expect(NumberWords.of(0), 'zero');
      expect(NumberWords.of(7), 'seven');
      expect(NumberWords.of(13), 'thirteen');
      expect(NumberWords.of(20), 'twenty');
      expect(NumberWords.of(42), 'forty-two');
      expect(NumberWords.of(81), 'eighty-one');
      expect(NumberWords.of(100), 'one hundred');
    });

    test('falls back to digits outside its range rather than lying', () {
      expect(NumberWords.of(-1), '-1');
      expect(NumberWords.of(101), '101');
    });
  });
}
