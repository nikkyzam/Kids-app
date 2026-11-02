import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/utils/number_words.dart';

/// Answers the grown-ups-only question the way a parent would.
Future<void> solveGate(WidgetTester tester) async {
  final question = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('What is '));
  final words = {for (var n = 0; n <= 40; n++) NumberWords.of(n): n};
  final sum = question
      .substring(8, question.length - 1)
      .split(' plus ')
      .map((w) => words[w]!)
      .reduce((a, b) => a + b);
  await tester.tap(find.text(NumberWords.of(sum)));
  await tester.pumpAndSettle();
}
