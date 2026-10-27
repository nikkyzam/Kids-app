import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/config/app_flavor.dart';
import 'package:playsteps/soundsteps/data/letters.dart';
import 'package:playsteps/soundsteps/screens/letters_screen.dart';
import 'package:playsteps/soundsteps/screens/sound_match_screen.dart';
import 'package:playsteps/soundsteps/services/progress_store.dart';
import 'package:playsteps/soundsteps/services/speaker.dart';
import 'package:playsteps/soundsteps/soundsteps_app.dart';

class FakeSpeaker implements Speaker {
  final List<String> said = [];

  @override
  Future<void> speak(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  group('flavor', () {
    test('soundsteps is registered with its own product IDs', () {
      final f = AppFlavor.byId('soundsteps');
      expect(f.displayName, 'SoundSteps');
      expect(f.premiumProductId, isNot(AppFlavor.playsteps.premiumProductId));
    });

    test('unknown flavor throws instead of falling back', () {
      expect(() => AppFlavor.byId('nope'), throwsStateError);
    });
  });

  group('letters data', () {
    test('covers A-Z once each, all fields filled', () {
      expect(letters.map((l) => l.letter).join(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      for (final l in letters) {
        expect(l.sound, isNotEmpty);
        expect(l.emoji, isNotEmpty);
        // X is the one exception: almost no English word starts with the /ks/
        // sound, so it is taught with "box" (the sound at the end).
        if (l.letter == 'X') continue;
        expect(l.word.toUpperCase().startsWith(l.letter), isTrue,
            reason: '${l.word} should start with ${l.letter}');
      }
    });
  });

  testWidgets('home opens letters and speaks the tapped letter',
      (tester) async {
    final speaker = FakeSpeaker();
    await tester.pumpWidget(
        SoundStepsApp(speaker: speaker, progress: ProgressStore.memory()));
    await tester.tap(find.byKey(const Key('open-letters')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('letter-B')));
    await tester.pump();

    expect(speaker.said.last, 'buh. B is for ball');
    expect(find.byKey(const Key('selected-letter')), findsOneWidget);
  });

  testWidgets('letters screen shows every letter', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LettersScreen(
          speaker: FakeSpeaker(), progress: ProgressStore.memory()),
    ));
    // The grid is lazy; scroll to the last letter to prove it is reachable.
    await tester.scrollUntilVisible(find.byKey(const Key('letter-Z')), 200);
    expect(find.byKey(const Key('letter-Z')), findsOneWidget);
  });

  group('sound match', () {
    Future<(FakeSpeaker, LetterEntry)> pump(WidgetTester tester) async {
      final speaker = FakeSpeaker();
      await tester.pumpWidget(MaterialApp(
        home: SoundMatchScreen(
          speaker: speaker,
          progress: ProgressStore.memory(),
          random: Random(7),
        ),
      ));
      await tester.pump();
      // First prompt is "<sound>. Which letter?"; recover the target from it.
      final sound = speaker.said.first.split('.').first;
      return (speaker, letters.firstWhere((l) => l.sound == sound));
    }

    testWidgets('offers three choices, one of which is the answer',
        (tester) async {
      final (_, target) = await pump(tester);
      expect(find.byKey(Key('choice-${target.letter}')), findsOneWidget);
      final choices = letters
          .where((l) =>
              find.byKey(Key('choice-${l.letter}')).evaluate().isNotEmpty)
          .toList();
      expect(choices.length, 3);
      // No two choices share a sound, so exactly one sound is right.
      expect(choices.map((c) => c.sound).toSet().length, 3);
    });

    testWidgets('right answer earns a star; wrong one just retries',
        (tester) async {
      final (speaker, target) = await pump(tester);
      final wrong = letters.firstWhere((l) =>
          l.sound != target.sound &&
          find.byKey(Key('choice-${l.letter}')).evaluate().isNotEmpty);

      await tester.tap(find.byKey(Key('choice-${wrong.letter}')));
      await tester.pump();
      expect(find.text('⭐ 0'), findsOneWidget);
      expect(speaker.said.any((t) => t.startsWith('Try again.')), isTrue);

      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump();
      expect(find.text('⭐ 1'), findsOneWidget);

      // Let the next-round timer fire so no timer is left pending.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
