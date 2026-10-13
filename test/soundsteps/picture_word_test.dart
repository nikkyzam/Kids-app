import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/soundsteps/data/letters.dart';
import 'package:playsteps/soundsteps/screens/home_screen.dart';
import 'package:playsteps/soundsteps/screens/picture_word_screen.dart';
import 'package:playsteps/soundsteps/services/speaker.dart';

class FakeSpeaker implements Speaker {
  final List<String> said = [];

  @override
  Future<void> speak(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  group('picture word data', () {
    test('every picture word starts with its letter; X is excluded', () {
      expect(pictureLetters.any((l) => l.letter == 'X'), isFalse);
      expect(pictureLetters.length, 25);
      for (final l in pictureLetters) {
        expect(l.word.toUpperCase().startsWith(l.letter), isTrue,
            reason: '${l.word} should start with ${l.letter}');
      }
    });

    test('choicesFor: target present, three choices, all different sounds', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final target in letters) {
          final choices = choicesFor(target, Random(seed));
          expect(choices.length, 3);
          expect(choices, contains(target));
          expect(choices.map((c) => c.sound).toSet().length, 3,
              reason: 'ambiguous choices for ${target.letter} (seed $seed)');
        }
      }
    });
  });

  group('picture word screen', () {
    Future<(FakeSpeaker, LetterEntry)> pump(WidgetTester tester) async {
      final speaker = FakeSpeaker();
      await tester.pumpWidget(MaterialApp(
        home: PictureWordScreen(speaker: speaker, random: Random(3)),
      ));
      await tester.pump();
      // First prompt: "<word>. What does <word> start with?"
      final word = speaker.said.first.split('.').first;
      return (speaker, letters.firstWhere((l) => l.word == word));
    }

    testWidgets('shows the picture, speaks the word, offers 3 letters',
        (tester) async {
      final (speaker, target) = await pump(tester);
      expect(find.text(target.emoji), findsOneWidget);
      expect(speaker.said.first,
          '${target.word}. What does ${target.word} start with?');
      expect(find.byKey(Key('choice-${target.letter}')), findsOneWidget);
      final shown = letters
          .where((l) =>
              find.byKey(Key('choice-${l.letter}')).evaluate().isNotEmpty)
          .length;
      expect(shown, 3);
      expect(find.byKey(const Key('word-hidden')), findsOneWidget);
    });

    testWidgets('wrong answer retries without a star or revealing the word',
        (tester) async {
      final (speaker, target) = await pump(tester);
      final wrong = letters.firstWhere((l) =>
          l.sound != target.sound &&
          find.byKey(Key('choice-${l.letter}')).evaluate().isNotEmpty);

      await tester.tap(find.byKey(Key('choice-${wrong.letter}')));
      await tester.pump();

      expect(find.text('⭐ 0'), findsOneWidget);
      expect(speaker.said, contains('Try again'));
      expect(find.byKey(const Key('word-revealed')), findsNothing);
    });

    testWidgets('right answer reveals the word, one star, then a new round',
        (tester) async {
      final (speaker, target) = await pump(tester);

      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump();

      expect(find.text('⭐ 1'), findsOneWidget);
      expect(find.byKey(const Key('word-revealed')), findsOneWidget);
      expect(speaker.said,
          contains('Yes! ${target.word} starts with ${target.sound}'));

      // A second tap on the answer while the next round loads must not score.
      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump();
      expect(find.text('⭐ 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const Key('word-revealed')), findsNothing);
      expect(find.byKey(const Key('word-hidden')), findsOneWidget);
    });

    testWidgets('tapping the picture repeats the word', (tester) async {
      final (speaker, _) = await pump(tester);
      await tester.tap(find.byKey(const Key('picture')));
      await tester.pump();
      expect(speaker.said.length, 2);
      expect(speaker.said.last, speaker.said.first);
    });
  });

  group('navigation and small screens', () {
    testWidgets('home opens picture words', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SoundStepsHome(speaker: FakeSpeaker()),
      ));
      await tester.tap(find.byKey(const Key('open-picture-word')));
      await tester.pumpAndSettle();
      expect(find.byType(PictureWordScreen), findsOneWidget);
    });

    // A 320x568 phone is the smallest the app supports; three stacked buttons
    // and the game screen must lay out without an overflow.
    testWidgets('home and picture words fit a 320x568 screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: SoundStepsHome(speaker: FakeSpeaker()),
      ));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('open-picture-word')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(PictureWordScreen), findsOneWidget);
    });
  });
}
