import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/soundsteps/screens/home_screen.dart';
import 'package:playsteps/soundsteps/screens/letters_screen.dart';
import 'package:playsteps/soundsteps/screens/picture_word_screen.dart';
import 'package:playsteps/soundsteps/services/progress_store.dart';
import 'package:playsteps/soundsteps/widgets/motion.dart';
import 'package:playsteps/soundsteps/widgets/parent_gate.dart';
import 'package:playsteps/utils/number_words.dart';

import 'fake_speaker.dart';

Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: c!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

/// The current paint scale of the Bounce wrapping [find]. A scale transform
/// does not change layout size, so it has to be read from the transition.
double bounceScale(WidgetTester tester, Finder bounce) => tester
    .widget<ScaleTransition>(
        find.descendant(of: bounce, matching: find.byType(ScaleTransition)))
    .scale
    .value;

/// Solves the grown-ups-only question the way a parent would.
Future<void> solveGate(WidgetTester tester) async {
  final question = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('What is '));
  final words = {for (var n = 0; n <= 40; n++) NumberWords.of(n): n};
  final parts = question
      .substring(8, question.length - 1)
      .split(' plus ')
      .map((w) => words[w]!);
  await tester.tap(find.text(NumberWords.of(parts.reduce((a, b) => a + b))));
  await tester.pumpAndSettle();
}

void main() {
  group('motion widgets', () {
    const box = Key('box');

    testWidgets('Shake wobbles when triggered, then comes to rest',
        (tester) async {
      Widget build(int t) => host(Shake(
          trigger: t, child: const SizedBox(key: box, width: 40, height: 40)));
      await tester.pumpWidget(build(0));
      final rest = tester.getTopLeft(find.byKey(box));

      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getTopLeft(find.byKey(box)).dx, isNot(rest.dx));

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getTopLeft(find.byKey(box)).dx, closeTo(rest.dx, 0.01));
    });

    testWidgets('Bounce grows then settles back to normal size',
        (tester) async {
      Widget build(int t) => host(Bounce(
          trigger: t, child: const SizedBox(key: box, width: 40, height: 40)));
      final bounce = find.byType(Bounce);
      await tester.pumpWidget(build(0));
      expect(bounceScale(tester, bounce), 1.0);

      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 130));
      expect(bounceScale(tester, bounce), greaterThan(1.0));

      await tester.pump(const Duration(milliseconds: 600));
      expect(bounceScale(tester, bounce), closeTo(1.0, 0.001));
    });

    testWidgets('nothing animates at first build, only on a change',
        (tester) async {
      await tester.pumpWidget(host(const Bounce(
          trigger: 0, child: SizedBox(key: box, width: 40, height: 40))));
      await tester.pump(const Duration(milliseconds: 130));
      expect(bounceScale(tester, find.byType(Bounce)), 1.0);
    });

    testWidgets('StarBurst shows stars while playing and none at rest',
        (tester) async {
      Widget build(int t) =>
          host(SizedBox(width: 300, height: 300, child: StarBurst(trigger: t)));
      await tester.pumpWidget(build(0));
      expect(find.text('⭐'), findsNothing);

      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('⭐'), findsWidgets);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('⭐'), findsNothing);
    });

    testWidgets('reduce-motion setting turns every animation off',
        (tester) async {
      Widget build(int t) => host(
            Column(children: [
              Shake(
                  trigger: t,
                  child: const SizedBox(key: box, width: 40, height: 40)),
              Bounce(
                  trigger: t,
                  child: const SizedBox(key: Key('b'), width: 40, height: 40)),
              SizedBox(width: 300, height: 300, child: StarBurst(trigger: t)),
            ]),
            reduceMotion: true,
          );
      await tester.pumpWidget(build(0));
      final rest = tester.getTopLeft(find.byKey(box));
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(find.byKey(box)), rest);
      expect(bounceScale(tester, find.byType(Bounce)), 1.0);
      expect(find.text('⭐'), findsNothing);
    });
  });

  group('game feedback', () {
    testWidgets('a right answer bursts stars; a wrong one does not',
        (tester) async {
      final speaker = RecordingSpeaker();
      await tester.pumpWidget(MaterialApp(
        home: PictureWordScreen(
            speaker: speaker,
            progress: ProgressStore.memory(),
            random: Random(5)),
      ));
      await tester.pump();
      final word = speaker.said.first.split('.').first;
      final targetLetter = word[0].toUpperCase();

      // The title bar's "⭐ 0" is a different string; the burst is bare "⭐".
      expect(find.text('⭐'), findsNothing);
      await tester.tap(find.byKey(Key('choice-$targetLetter')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('⭐'), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('letters screen', () {
    testWidgets('a mastered letter wears a star', (tester) async {
      final progress = ProgressStore.memory();
      for (var i = 0; i < 3; i++) {
        await progress.recordSuccess('B', firstTry: true);
      }
      await tester.pumpWidget(MaterialApp(
        home: LettersScreen(speaker: RecordingSpeaker(), progress: progress),
      ));
      expect(find.byKey(const Key('mastered-B')), findsOneWidget);
      expect(find.byKey(const Key('mastered-A')), findsNothing);
    });
  });

  group('home and the grown-ups-only reset', () {
    Future<ProgressStore> pumpHome(WidgetTester tester) async {
      final progress = ProgressStore.memory();
      await progress.recordSuccess('B', firstTry: true);
      await tester.pumpWidget(MaterialApp(
        home: SoundStepsHome(speaker: RecordingSpeaker(), progress: progress),
      ));
      return progress;
    }

    testWidgets('shows stars and learned letters, live', (tester) async {
      final progress = await pumpHome(tester);
      expect(find.text('⭐ 1   🔤 0/26'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await progress.recordSuccess('B', firstTry: true);
      }
      await tester.pump();
      expect(find.text('⭐ 3   🔤 1/26'), findsOneWidget);
    });

    testWidgets('a plain tap on the stars does nothing', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.byKey(const Key('home-stars')));
      await tester.pumpAndSettle();
      expect(find.text('Grown-ups only'), findsNothing);
    });

    testWidgets('long-press, pass the gate, confirm: progress is cleared',
        (tester) async {
      final progress = await pumpHome(tester);
      await tester.longPress(find.byKey(const Key('home-stars')));
      await tester.pumpAndSettle();
      expect(find.text('Grown-ups only'), findsOneWidget);

      await solveGate(tester);
      expect(find.text('Reset progress?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-reset')));
      await tester.pumpAndSettle();
      expect(progress.stars, 0);
    });

    testWidgets('a wrong gate answer keeps the progress', (tester) async {
      final progress = await pumpHome(tester);
      await tester.longPress(find.byKey(const Key('home-stars')));
      await tester.pumpAndSettle();

      // Tap an option that is not the answer.
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
      final wrong = tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .map((b) => (b.child as Text).data!)
          .firstWhere((w) => words[w] != sum);
      await tester.tap(find.text(wrong));
      await tester.pump();
      expect(find.text('Not quite. Try again.'), findsOneWidget);
      expect(progress.stars, 1);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(progress.stars, 1);
    });

    testWidgets('cancelling the confirmation keeps the progress',
        (tester) async {
      final progress = await pumpHome(tester);
      await tester.longPress(find.byKey(const Key('home-stars')));
      await tester.pumpAndSettle();
      await solveGate(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(progress.stars, 1);
    });
  });

  group('ParentGateChallenge', () {
    test('answer is among four distinct positive options, over many seeds', () {
      for (var seed = 0; seed < 500; seed++) {
        final c = ParentGateChallenge.generate(Random(seed));
        expect(c.options.length, 4);
        expect(c.options.toSet().length, 4);
        expect(c.options, contains(c.answer));
        expect(c.options.every((o) => o > 0), isTrue);
      }
    });

    test('the question is written in words, with no digits', () {
      final q = ParentGateChallenge.generate(Random(1)).question;
      expect(RegExp(r'\d').hasMatch(q), isFalse, reason: q);
    });
  });
}
