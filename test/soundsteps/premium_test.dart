import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/soundsteps/data/letters.dart';
import 'package:playsteps/soundsteps/data/strokes.dart';
import 'package:playsteps/soundsteps/screens/home_screen.dart';
import 'package:playsteps/soundsteps/screens/parent_corner_screen.dart';
import 'package:playsteps/soundsteps/screens/trace_screen.dart';
import 'package:playsteps/soundsteps/screens/welcome_screen.dart';
import 'package:playsteps/soundsteps/services/progress_store.dart';
import 'package:playsteps/soundsteps/services/settings_store.dart';
import 'package:playsteps/soundsteps/services/speaker.dart';
import 'package:playsteps/soundsteps/soundsteps_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_speaker.dart';
import 'gate_helper.dart';

void main() {
  group('SettingsStore', () {
    test('sensible defaults: slow speech, haptics on, no break, not onboarded',
        () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsStore.open();
      expect(s.speed, SpeechSpeed.slow);
      expect(s.haptics, isTrue);
      expect(s.breakMinutes, 0);
      expect(s.reduceMotion, isFalse);
      expect(s.childName, '');
      expect(s.onboarded, isFalse);
    });

    test('choices survive a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final s = await SettingsStore.open(prefs);
      s
        ..childName = '  Mia '
        ..speed = SpeechSpeed.normal
        ..breakMinutes = 15
        ..haptics = false
        ..reduceMotion = true
        ..onboarded = true;
      await Future<void>.delayed(Duration.zero);
      final again = await SettingsStore.open(prefs);
      expect(again.childName, 'Mia'); // trimmed
      expect(again.speed, SpeechSpeed.normal);
      expect(again.breakMinutes, 15);
      expect(again.haptics, isFalse);
      expect(again.reduceMotion, isTrue);
      expect(again.onboarded, isTrue);
    });

    test('corrupt saved settings fall back to defaults', () async {
      SharedPreferences.setMockInitialValues(
          {SettingsStore.storageKey: 'nope{'});
      final s = await SettingsStore.open();
      expect(s.speed, SpeechSpeed.slow);
      expect(s.onboarded, isFalse);
    });
  });

  group('ProgressStore additions', () {
    test('addStar counts toward stickers, not toward any letter', () async {
      final p = ProgressStore.memory();
      await p.addStar();
      expect(p.stars, 1);
      expect(p.masteredCount, 0);
      expect(p.statsFor('A').isNew, isTrue);
    });

    test('play time adds up per day and old days are dropped', () async {
      final p = ProgressStore.memory();
      final day = DateTime(2026, 11, 2, 10);
      await p.recordPlay(const Duration(seconds: 90), now: day);
      await p.recordPlay(const Duration(seconds: 90), now: day);
      expect(p.minutesOn(day), 3);
      expect(p.minutesOn(day.subtract(const Duration(days: 1))), 0);

      await p.recordPlay(const Duration(minutes: 1),
          now: day.add(const Duration(days: 20)));
      expect(p.minutesOn(day), 0, reason: 'more than two weeks old');
    });

    test('play time is saved and cleared by reset', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final p = await ProgressStore.open(prefs);
      final day = DateTime(2026, 11, 2);
      await p.recordPlay(const Duration(minutes: 4), now: day);
      expect((await ProgressStore.open(prefs)).minutesOn(day), 4);
      await p.reset();
      expect((await ProgressStore.open(prefs)).minutesOn(day), 0);
    });
  });

  group('tracing data', () {
    test('every letter A-Z has guide strokes', () {
      expect(letterStrokes.keys.toSet(), letters.map((l) => l.letter).toSet());
      for (final e in letterStrokes.entries) {
        expect(e.value, isNotEmpty, reason: e.key);
        for (final s in e.value) {
          expect(s.length, greaterThan(2), reason: e.key);
          for (final p in s) {
            expect(p.dx, inInclusiveRange(0, 1), reason: e.key);
            expect(p.dy, inInclusiveRange(0, 1), reason: e.key);
          }
        }
      }
    });

    test('following the guide completes every letter', () {
      for (final e in letterStrokes.entries) {
        final t = TraceProgress(e.value);
        for (final s in e.value) {
          s.forEach(t.touch);
        }
        expect(t.complete, isTrue, reason: e.key);
      }
    });

    test('a scribble in the corner does not count', () {
      final t = TraceProgress(letterStrokes['O']!);
      for (var i = 0; i < 50; i++) {
        t.touch(Offset(0.02 + i * 0.001, 0.98));
      }
      expect(t.complete, isFalse);
    });

    test('skipping a short stroke is not enough (A without its crossbar)', () {
      final strokes = letterStrokes['A']!;
      final t = TraceProgress(strokes);
      strokes[0].forEach(t.touch);
      strokes[1].forEach(t.touch);
      expect(t.complete, isFalse);
      strokes[2].forEach(t.touch);
      expect(t.complete, isTrue);
    });

    test('no letter can be finished with any one stroke left out', () {
      for (final e in letterStrokes.entries) {
        if (e.value.length < 2) continue;
        for (var skip = 0; skip < e.value.length; skip++) {
          final t = TraceProgress(e.value);
          for (var s = 0; s < e.value.length; s++) {
            if (s != skip) e.value[s].forEach(t.touch);
          }
          expect(t.complete, isFalse,
              reason: '${e.key} finished without stroke ${skip + 1}');
        }
      }
    });

    test('half a letter is not enough', () {
      final strokes = letterStrokes['E']!;
      final t = TraceProgress(strokes);
      strokes.first.forEach(t.touch); // just the upright
      expect(t.complete, isFalse);
    });
  });

  group('trace screen', () {
    Future<(RecordingSpeaker, ProgressStore)> pumpTrace(WidgetTester tester,
        {String letter = 'L'}) async {
      final speaker = RecordingSpeaker();
      final progress = ProgressStore.memory();
      await tester.pumpWidget(MaterialApp(
        home: TraceScreen(
          speaker: speaker,
          progress: progress,
          startIndex: letters.indexWhere((l) => l.letter == letter),
        ),
      ));
      await tester.pump();
      return (speaker, progress);
    }

    Future<void> traceWithFinger(WidgetTester tester, String letter) async {
      final rect = tester.getRect(find.byKey(const Key('trace-pad')));
      Offset at(Offset p) =>
          rect.topLeft + Offset(p.dx * rect.width, p.dy * rect.height);
      for (final stroke in letterStrokes[letter]!) {
        final g = await tester.startGesture(at(stroke.first));
        for (final p in stroke.skip(1)) {
          await g.moveTo(at(p));
        }
        await g.up();
        await tester.pump();
      }
    }

    testWidgets('introduces the letter and its sound', (tester) async {
      final (speaker, _) = await pumpTrace(tester);
      expect(speaker.said.single, 'Trace the letter L. L says lll.');
      expect(find.text('Ll'), findsOneWidget);
    });

    testWidgets('tracing L by finger earns a star and moves on to M',
        (tester) async {
      final (speaker, progress) = await pumpTrace(tester);
      await traceWithFinger(tester, 'L');
      expect(progress.stars, 1);
      expect(progress.masteredCount, 0);
      expect(speaker.said.last, startsWith('You traced L!'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Mm'), findsOneWidget);
      expect(speaker.said.last, 'Trace the letter M. M says mmm.');
    });

    testWidgets('next and previous wrap around the alphabet', (tester) async {
      await pumpTrace(tester, letter: 'A');
      await tester.tap(find.byKey(const Key('trace-prev')));
      await tester.pump();
      expect(find.text('Zz'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trace-next')));
      await tester.pump();
      expect(find.text('Aa'), findsOneWidget);
    });

    testWidgets('fits a 320x568 phone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpTrace(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('app shell', () {
    testWidgets('first launch: welcome, name, then Pip greets by name',
        (tester) async {
      final speaker = RecordingSpeaker();
      final settings = SettingsStore.memory(onboarded: false);
      await tester.pumpWidget(SoundStepsApp(
          progress: ProgressStore.memory(),
          settings: settings,
          speaker: speaker));
      expect(find.byType(WelcomeScreen), findsOneWidget);

      await tester.enterText(find.byKey(const Key('welcome-name')), 'Mia');
      await tester.tap(find.byKey(const Key('welcome-start')));
      await tester.pumpAndSettle();
      expect(settings.onboarded, isTrue);
      expect(find.byType(SoundStepsHome), findsOneWidget);
      expect(speaker.said.first, "Hi Mia! I'm Pip. Let's play!");
    });

    testWidgets('no name, plain hello', (tester) async {
      final speaker = RecordingSpeaker();
      await tester.pumpWidget(
          SoundStepsApp(progress: ProgressStore.memory(), speaker: speaker));
      await tester.pump();
      expect(speaker.said.first, "Hi! I'm Pip. Let's play!");
    });

    testWidgets(
        'break reminder: Pip naps when time is up; a grown-up can '
        'carry on', (tester) async {
      final speaker = RecordingSpeaker();
      final progress = ProgressStore.memory();
      final settings = SettingsStore.memory()..breakMinutes = 1;
      await tester.pumpWidget(SoundStepsApp(
        progress: progress,
        settings: settings,
        speaker: speaker,
        tick: const Duration(seconds: 10),
      ));
      await tester.pump(const Duration(seconds: 50));
      expect(find.byKey(const Key('break-overlay')), findsNothing);

      await tester.pump(const Duration(seconds: 10));
      expect(find.byKey(const Key('break-overlay')), findsOneWidget);
      expect(speaker.said.last, contains('Time for a break'));
      expect(progress.minutesOn(DateTime.now()), 1);

      await tester.tap(find.byKey(const Key('keep-playing')));
      await tester.pumpAndSettle();
      await solveGate(tester);
      expect(find.byKey(const Key('break-overlay')), findsNothing);
    });

    testWidgets('coming back after a while starts a fresh session',
        (tester) async {
      var now = DateTime(2026, 11, 2, 9);
      final settings = SettingsStore.memory()..breakMinutes = 1;
      await tester.pumpWidget(SoundStepsApp(
        progress: ProgressStore.memory(),
        settings: settings,
        speaker: RecordingSpeaker(),
        tick: const Duration(seconds: 10),
        clock: () => now,
      ));
      await tester.pump(const Duration(seconds: 60));
      expect(find.byKey(const Key('break-overlay')), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 6));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byKey(const Key('break-overlay')), findsNothing);
    });

    testWidgets('time in the background does not count as play',
        (tester) async {
      final progress = ProgressStore.memory();
      await tester.pumpWidget(SoundStepsApp(
        progress: progress,
        speaker: RecordingSpeaker(),
        tick: const Duration(seconds: 30),
      ));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 3));
      expect(progress.minutesOn(DateTime.now()), 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    testWidgets('break reminder off: no nap however long they play',
        (tester) async {
      await tester.pumpWidget(SoundStepsApp(
        progress: ProgressStore.memory(),
        speaker: RecordingSpeaker(),
        tick: const Duration(seconds: 30),
      ));
      await tester.pump(const Duration(minutes: 45));
      expect(find.byKey(const Key('break-overlay')), findsNothing);
    });

    testWidgets('the calmer-screen switch turns animations off app-wide',
        (tester) async {
      final settings = SettingsStore.memory()..reduceMotion = true;
      await tester.pumpWidget(SoundStepsApp(
          progress: ProgressStore.memory(),
          settings: settings,
          speaker: RecordingSpeaker()));
      final ctx = tester.element(find.byType(SoundStepsHome));
      expect(MediaQuery.disableAnimationsOf(ctx), isTrue);
    });
  });

  group("grown-ups' corner", () {
    testWidgets('reached from home only through the gate', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SoundStepsHome(
            speaker: RecordingSpeaker(), progress: ProgressStore.memory()),
      ));
      await tester.tap(find.byKey(const Key('open-parent-corner')));
      await tester.pumpAndSettle();
      expect(find.byType(ParentCornerScreen), findsNothing);
      await solveGate(tester);
      expect(find.byType(ParentCornerScreen), findsOneWidget);
    });

    testWidgets('report shows stars, play time and letter states',
        (tester) async {
      final progress = ProgressStore.memory();
      final today = DateTime(2026, 11, 2, 12);
      for (var i = 0; i < 3; i++) {
        await progress.recordSuccess('A', firstTry: true);
      }
      await progress.recordMiss('B');
      await progress.recordMiss('B');
      await progress.recordSuccess('C', firstTry: true);
      await progress.recordPlay(const Duration(minutes: 7), now: today);
      await tester.pumpWidget(MaterialApp(
        home: ParentCornerScreen(
            progress: progress, settings: SettingsStore.memory(), today: today),
      ));
      expect(find.byKey(const Key('mastery-A-learned')), findsOneWidget);
      expect(find.byKey(const Key('mastery-B-tricky')), findsOneWidget);
      expect(find.byKey(const Key('mastery-C-practising')), findsOneWidget);
      expect(find.byKey(const Key('mastery-D-fresh')), findsOneWidget);
      expect(find.textContaining('Practising most: B'), findsOneWidget);
      expect(find.text('7'), findsOneWidget); // today's bar label
      expect(find.text('Minutes played · last 7 days (7 min)'), findsOneWidget);
    });

    testWidgets('settings change and stick', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final settings = SettingsStore.memory();
      await tester.pumpWidget(MaterialApp(
        home: ParentCornerScreen(
            progress: ProgressStore.memory(), settings: settings),
      ));
      await tester.enterText(find.byKey(const Key('child-name')), 'Leo');
      await tester.tap(find.text('Normal'));
      await tester.tap(find.byKey(const Key('break-15')));
      await tester.tap(find.byKey(const Key('haptics')));
      await tester.tap(find.byKey(const Key('reduce-motion')));
      await tester.pumpAndSettle();
      expect(settings.childName, 'Leo');
      expect(settings.speed, SpeechSpeed.normal);
      expect(settings.breakMinutes, 15);
      expect(settings.haptics, isFalse);
      expect(settings.reduceMotion, isTrue);
    });

    testWidgets('reset clears progress after confirmation', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final progress = ProgressStore.memory();
      await progress.addStar();
      await tester.pumpWidget(MaterialApp(
        home: ParentCornerScreen(
            progress: progress, settings: SettingsStore.memory()),
      ));
      await tester.tap(find.byKey(const Key('parent-reset')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('parent-confirm-reset')));
      await tester.pumpAndSettle();
      expect(progress.stars, 0);
    });

    testWidgets('fits a 320x568 phone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: ParentCornerScreen(
            progress: ProgressStore.memory(), settings: SettingsStore.memory()),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('speech speed reaches the speech engine', () {
    const channel = MethodChannel('flutter_tts');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return 1;
      });
    });
    tearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    test('slow by default, normal when the parent picks it', () async {
      final settings = SettingsStore.memory();
      final speaker = TtsSpeaker(settings: settings);
      await speaker.speak('hi');
      double lastRate() =>
          (calls.lastWhere((c) => c.method == 'setSpeechRate').arguments as num)
              .toDouble();
      expect(lastRate(), SpeechSpeed.slow.rate);

      settings.speed = SpeechSpeed.normal;
      await speaker.speak('hi again');
      expect(lastRate(), SpeechSpeed.normal.rate);
      expect(calls.where((c) => c.method == 'speak').length, 2);
    });
  });
}
