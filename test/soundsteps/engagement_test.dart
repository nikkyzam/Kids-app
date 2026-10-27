import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/soundsteps/data/letters.dart';
import 'package:playsteps/soundsteps/data/stickers.dart';
import 'package:playsteps/soundsteps/screens/choice_game.dart';
import 'package:playsteps/soundsteps/screens/home_screen.dart';
import 'package:playsteps/soundsteps/screens/picture_word_screen.dart';
import 'package:playsteps/soundsteps/screens/sticker_book_screen.dart';
import 'package:playsteps/soundsteps/services/progress_store.dart';
import 'package:playsteps/soundsteps/widgets/mascot.dart';

import 'fake_speaker.dart';

/// Starts a picture-word game and returns the speaker, store and target.
Future<(RecordingSpeaker, ProgressStore, LetterEntry)> startGame(
  WidgetTester tester, {
  ProgressStore? progress,
  int seed = 5,
}) async {
  final speaker = RecordingSpeaker();
  final store = progress ?? ProgressStore.memory();
  await tester.pumpWidget(MaterialApp(
    home: PictureWordScreen(
        speaker: speaker, progress: store, random: Random(seed)),
  ));
  await tester.pump();
  return (speaker, store, currentTarget(speaker));
}

/// The target of the round being asked about, read from the last prompt.
LetterEntry currentTarget(RecordingSpeaker speaker) {
  final prompt = speaker.said.lastWhere((t) => t.contains('What does'));
  final word = prompt.replaceFirst('Listen! ', '').split('.').first;
  return letters.firstWhere((l) => l.word == word);
}

void main() {
  group('stickers', () {
    test('one sticker per five stars, capped at the set', () {
      expect(stickersFor(0), 0);
      expect(stickersFor(4), 0);
      expect(stickersFor(5), 1);
      expect(stickersFor(12), 2);
      expect(stickersFor(10000), stickers.length);
    });

    test('the set has no duplicate animals', () {
      expect(stickers.map((s) => s.emoji).toSet().length, stickers.length);
    });

    testWidgets('the fifth star wins a sticker, announced and shown',
        (tester) async {
      final store = ProgressStore.memory();
      for (var i = 0; i < 4; i++) {
        await store.recordSuccess('A', firstTry: true);
      }
      final (speaker, _, target) = await startGame(tester, progress: store);
      expect(find.byKey(const Key('new-sticker')), findsNothing);

      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(store.stickersUnlocked, 1);
      expect(find.byKey(const Key('new-sticker')), findsOneWidget);
      // Inside the banner: the round's picture may be the same animal.
      expect(
          find.descendant(
              of: find.byKey(const Key('new-sticker')),
              matching: find.text(stickers.first.emoji)),
          findsOneWidget);
      expect(speaker.said.last,
          endsWith('You won a sticker! The ${stickers.first.name}!'));

      // The celebration runs longer than usual, then the banner goes.
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.byKey(const Key('new-sticker')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('new-sticker')), findsNothing);
    });

    testWidgets('an ordinary win does not show the sticker banner',
        (tester) async {
      final (_, _, target) = await startGame(tester);
      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('new-sticker')), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'sticker book: earned ones speak their name, locked ones '
        'encourage', (tester) async {
      final store = ProgressStore.memory();
      for (var i = 0; i < 7; i++) {
        await store.recordSuccess('A', firstTry: true);
      }
      final speaker = RecordingSpeaker();
      await tester.pumpWidget(MaterialApp(
        home: StickerBookScreen(speaker: speaker, progress: store),
      ));
      expect(find.text('1 of ${stickers.length}  ·  ⭐ 3 more for the next one'),
          findsOneWidget);
      expect(find.text(stickers.first.emoji), findsOneWidget);
      expect(find.text(stickers[1].emoji), findsNothing);

      await tester.tap(find.byKey(const Key('sticker-0')));
      await tester.pump();
      expect(speaker.said.last, 'The ${stickers.first.name}!');

      await tester.tap(find.byKey(const Key('sticker-1')));
      await tester.pump();
      expect(speaker.said.last, 'Keep playing to win this one!');
      await tester.pumpAndSettle();
    });
  });

  group('holding attention', () {
    testWidgets(
        'after a quiet spell the prompt repeats and the answer '
        'wiggles; twice at most', (tester) async {
      final (speaker, _, target) = await startGame(tester);
      final before = speaker.said.length;

      await tester.pump(const Duration(seconds: 9));
      expect(speaker.said.length, before + 1);
      expect(speaker.said.last, startsWith('Listen! ${target.word}.'));

      await tester.pump(const Duration(seconds: 9));
      expect(speaker.said.length, before + 2);

      // No third nudge: invite, don't nag.
      await tester.pump(const Duration(seconds: 30));
      expect(speaker.said.length, before + 2);
    });

    testWidgets('no nudge once the round is won', (tester) async {
      final (speaker, _, target) = await startGame(tester);
      await tester.tap(find.byKey(Key('choice-${target.letter}')));
      await tester.pump();
      final afterWin = speaker.said.length;
      // The next round's prompt comes at ~2.2s; nothing else before it.
      await tester.pump(const Duration(seconds: 2));
      expect(speaker.said.length, afterWin);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('praise varies from round to round', (tester) async {
      final (speaker, _, _) = await startGame(tester, seed: 11);
      final cheers = <String>{};
      for (var round = 0; round < 8; round++) {
        final target = currentTarget(speaker);
        await tester.tap(find.byKey(Key('choice-${target.letter}')));
        await tester.pump();
        final reply = speaker.said.last;
        cheers.add(ChoiceGame.praise.firstWhere(reply.startsWith));
        await tester.pump(const Duration(seconds: 5));
      }
      expect(cheers.length, greaterThan(2));
    });

    testWidgets('the three choices are three different bright colours',
        (tester) async {
      await startGame(tester);
      final colors = tester
          .widgetList<Material>(find.ancestor(
              of: find.byWidgetPredicate((w) =>
                  w.key is ValueKey<String> &&
                  (w.key as ValueKey<String>).value.startsWith('choice-')),
              matching: find.byType(Material)))
          .map((m) => m.color)
          .where((c) => ChoiceGame.choiceColors.contains(c))
          .toSet();
      expect(colors.length, 3);
    });
  });

  group('Pip', () {
    testWidgets('greets once when the app opens, and again when tapped',
        (tester) async {
      final speaker = RecordingSpeaker();
      await tester.pumpWidget(MaterialApp(
        home:
            SoundStepsHome(speaker: speaker, progress: ProgressStore.memory()),
      ));
      await tester.pump();
      expect(speaker.said, ["Hi! I'm Pip. Let's play!"]);

      await tester.tap(find.byKey(const Key('pip')));
      await tester.pump();
      expect(speaker.said.length, 2);
      await tester.pumpAndSettle();
    });

    testWidgets('home opens the sticker book', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SoundStepsHome(
            speaker: RecordingSpeaker(), progress: ProgressStore.memory()),
      ));
      await tester.tap(find.byKey(const Key('open-stickers')));
      await tester.pumpAndSettle();
      expect(find.byType(StickerBookScreen), findsOneWidget);
    });

    Offset pipOffset(WidgetTester tester) => tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(Mascot), matching: find.byType(Transform))
            .first)
        .transform
        .getTranslation()
        .let((v) => Offset(v.x, v.y));

    testWidgets('jumps when cheered', (tester) async {
      Widget build(int cheer) => MaterialApp(
            home: Center(child: Mascot(cheer: cheer)),
          );
      await tester.pumpWidget(build(0));
      expect(pipOffset(tester).dy, 0);
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(pipOffset(tester).dy, lessThan(0)); // up in the air
      await tester.pump(const Duration(milliseconds: 500));
      expect(pipOffset(tester).dy, closeTo(0, 0.01));
    });

    testWidgets('stands still with reduce-motion on', (tester) async {
      Widget build(int cheer) => MaterialApp(
            builder: (context, c) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: c!,
            ),
            home: Center(child: Mascot(cheer: cheer)),
          );
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(pipOffset(tester).dy, 0);
      // The idle bob is off too.
      await tester.pump(const Duration(seconds: 4));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('paints in every mood without errors', (tester) async {
      for (final mood in MascotMood.values) {
        await tester
            .pumpWidget(MaterialApp(home: Center(child: Mascot(mood: mood))));
        expect(tester.takeException(), isNull);
      }
    });
  });

  testWidgets('home with Pip and stickers still fits a 320x568 phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: SoundStepsHome(
          speaker: RecordingSpeaker(), progress: ProgressStore.memory()),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('open-stickers')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
