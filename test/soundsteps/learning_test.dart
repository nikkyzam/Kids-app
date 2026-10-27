import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/soundsteps/data/letters.dart';
import 'package:playsteps/soundsteps/data/practice.dart';
import 'package:playsteps/soundsteps/screens/picture_word_screen.dart';
import 'package:playsteps/soundsteps/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_speaker.dart';

LetterEntry letter(String l) => letters.firstWhere((e) => e.letter == l);

void main() {
  group('ProgressStore', () {
    test('a first-try success earns a star and counts toward the letter',
        () async {
      final p = ProgressStore.memory();
      await p.recordSuccess('B', firstTry: true);
      expect(p.stars, 1);
      expect(p.statsFor('B').correct, 1);
    });

    test('a success after a miss earns the star but is not mastery evidence',
        () async {
      final p = ProgressStore.memory();
      await p.recordMiss('B');
      await p.recordSuccess('B', firstTry: false);
      expect(p.stars, 1);
      expect(p.statsFor('B').correct, 0);
      expect(p.statsFor('B').misses, 1);
    });

    test('mastered needs 3 first-try wins and more wins than misses', () async {
      final p = ProgressStore.memory();
      for (var i = 0; i < 2; i++) {
        await p.recordSuccess('B', firstTry: true);
      }
      expect(p.statsFor('B').mastered, isFalse);
      await p.recordSuccess('B', firstTry: true);
      expect(p.statsFor('B').mastered, isTrue);
      expect(p.masteredCount, 1);
      // Losing ground un-masters it.
      for (var i = 0; i < 3; i++) {
        await p.recordMiss('B');
      }
      expect(p.statsFor('B').mastered, isFalse);
    });

    test('notifies listeners so the UI can update', () async {
      final p = ProgressStore.memory();
      var calls = 0;
      p.addListener(() => calls++);
      await p.recordSuccess('A', firstTry: true);
      await p.recordMiss('A');
      expect(calls, 2);
    });

    test('progress survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = await ProgressStore.open(prefs);
      await first.recordMiss('C');
      await first.recordSuccess('C', firstTry: true);
      await first.recordSuccess('D', firstTry: true);

      final second = await ProgressStore.open(prefs);
      expect(second.stars, 2);
      expect(second.statsFor('C').misses, 1);
      expect(second.statsFor('C').correct, 1);
      expect(second.statsFor('D').correct, 1);
    });

    test('corrupt saved data starts fresh instead of crashing', () async {
      SharedPreferences.setMockInitialValues(
          {ProgressStore.storageKey: '{not json'});
      final p = await ProgressStore.open();
      expect(p.stars, 0);
      expect(p.masteredCount, 0);
    });

    test('reset clears everything, including what was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final p = await ProgressStore.open(prefs);
      await p.recordSuccess('B', firstTry: true);
      await p.reset();
      expect(p.stars, 0);
      final reopened = await ProgressStore.open(prefs);
      expect(reopened.stars, 0);
      expect(reopened.statsFor('B').isNew, isTrue);
    });
  });

  group('practice weighting', () {
    test('struggling > new > in progress > mastered', () {
      const struggling = LetterStats(misses: 3);
      const fresh = LetterStats();
      const inProgress = LetterStats(correct: 1);
      const mastered = LetterStats(correct: 3);
      expect(practiceWeight(struggling), greaterThan(practiceWeight(fresh)));
      expect(practiceWeight(fresh), greaterThan(practiceWeight(inProgress)));
      expect(practiceWeight(inProgress), greaterThan(practiceWeight(mastered)));
      expect(practiceWeight(mastered), 1); // never zero: still revisited
    });

    test('a missed letter comes up far more often than an unseen one',
        () async {
      final p = ProgressStore.memory();
      for (var i = 0; i < 5; i++) {
        await p.recordMiss('B');
      }
      final random = Random(1);
      final counts = <String, int>{};
      for (var i = 0; i < 3000; i++) {
        final t = pickTarget(pictureLetters, p, random);
        counts[t.letter] = (counts[t.letter] ?? 0) + 1;
      }
      expect(counts['B']!, greaterThan(2 * counts['D']!));
    });

    test('mastered letters still appear, just rarely', () async {
      final p = ProgressStore.memory();
      for (var i = 0; i < 3; i++) {
        await p.recordSuccess('B', firstTry: true);
      }
      final random = Random(2);
      var b = 0;
      for (var i = 0; i < 3000; i++) {
        if (pickTarget(pictureLetters, p, random).letter == 'B') b++;
      }
      expect(b, greaterThan(0));
    });

    test('never repeats the previous letter back-to-back', () {
      final p = ProgressStore.memory();
      final random = Random(3);
      var prev = letter('A');
      for (var i = 0; i < 500; i++) {
        final next = pickTarget(pictureLetters, p, random, previous: prev);
        expect(next.letter, isNot(prev.letter));
        prev = next;
      }
    });

    test('a one-letter pool may repeat rather than loop forever', () {
      final only = [letter('A')];
      final t = pickTarget(only, ProgressStore.memory(), Random(1),
          previous: only.first);
      expect(t.letter, 'A');
    });
  });

  group('game rules (picture words)', () {
    Future<(RecordingSpeaker, ProgressStore, LetterEntry)> start(
        WidgetTester tester) async {
      final speaker = RecordingSpeaker();
      final progress = ProgressStore.memory();
      await tester.pumpWidget(MaterialApp(
        home: PictureWordScreen(
            speaker: speaker, progress: progress, random: Random(5)),
      ));
      await tester.pump();
      final word = speaker.said.first.split('.').first;
      return (speaker, progress, letters.firstWhere((l) => l.word == word));
    }

    LetterEntry wrongChoice(LetterEntry target) => letters.firstWhere((l) =>
        l.sound != target.sound &&
        find.byKey(Key('choice-${l.letter}')).evaluate().isNotEmpty);

    testWidgets('many wrong taps in one round count as a single miss',
        (tester) async {
      final (_, progress, target) = await start(tester);
      final wrong = wrongChoice(target);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(Key('choice-${wrong.letter}')));
        await tester.pump();
      }
      expect(progress.statsFor(target.letter).misses, 1);
      expect(progress.stars, 0);
    });

    testWidgets('first-try win is recorded as mastery evidence',
        (tester) async {
      final (_, progress, target) = await start(tester);
      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump();
      expect(progress.stars, 1);
      expect(progress.statsFor(target.letter).correct, 1);
      expect(progress.statsFor(target.letter).misses, 0);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a win after a miss gives the star but not the credit',
        (tester) async {
      final (_, progress, target) = await start(tester);
      await tester.tap(find.byKey(Key('choice-${wrongChoice(target).letter}')));
      await tester.pump();
      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump();
      expect(progress.stars, 1);
      expect(progress.statsFor(target.letter).correct, 0);
      expect(progress.statsFor(target.letter).misses, 1);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('"try again" is one utterance with the prompt, not cut off',
        (tester) async {
      final (speaker, _, target) = await start(tester);
      await tester.tap(find.byKey(Key('choice-${wrongChoice(target).letter}')));
      await tester.pump();
      expect(speaker.said.last,
          'Try again. ${target.word}. What does ${target.word} start with?');
    });

    testWidgets('the next round is a different letter', (tester) async {
      final (speaker, _, target) = await start(tester);
      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      final nextWord = speaker.said.last.split('.').first;
      expect(nextWord, isNot(target.word));
    });
  });
}
