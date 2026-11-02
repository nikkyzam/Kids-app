import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_flavor.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/progress_store.dart';
import 'services/settings_store.dart';
import 'services/speaker.dart';
import 'widgets/break_overlay.dart';

class SoundStepsApp extends StatefulWidget {
  const SoundStepsApp({
    super.key,
    required this.progress,
    this.settings,
    this.speaker,
    this.tick = const Duration(seconds: 30),
    this.clock = DateTime.now,
  });

  /// Saved progress; opened before the app starts (see `main`).
  final ProgressStore progress;

  /// The grown-up's settings; in-memory (and already onboarded) if absent.
  final SettingsStore? settings;

  /// Injectable for tests; defaults to device text-to-speech.
  final Speaker? speaker;

  /// How often play time is counted and the break reminder checked.
  final Duration tick;
  final DateTime Function() clock;

  /// Coming back after at least this long away starts a fresh session.
  static const freshSessionAfter = Duration(minutes: 5);

  @override
  State<SoundStepsApp> createState() => _SoundStepsAppState();
}

class _SoundStepsAppState extends State<SoundStepsApp>
    with WidgetsBindingObserver {
  late final SettingsStore _settings =
      widget.settings ?? SettingsStore.memory();
  late final Speaker _speaker =
      widget.speaker ?? TtsSpeaker(settings: _settings);
  Timer? _ticker;
  bool _active = true;
  DateTime? _awaySince;
  Duration _session = Duration.zero;
  bool _onBreak = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(widget.tick, (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTick() {
    if (!_active || _onBreak) return;
    widget.progress.recordPlay(widget.tick, now: widget.clock());
    _session += widget.tick;
    final limit = _settings.breakMinutes;
    if (limit > 0 && _session >= Duration(minutes: limit)) {
      setState(() => _onBreak = true);
      _speaker.speak('Great playing! Pip is sleepy. Time for a break!');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final away = _awaySince;
      _active = true;
      _awaySince = null;
      if (away != null &&
          widget.clock().difference(away) >= SoundStepsApp.freshSessionAfter) {
        setState(() {
          _session = Duration.zero;
          _onBreak = false;
        });
      }
    } else if (_active) {
      _active = false;
      _awaySince = widget.clock();
    }
  }

  void _keepPlaying() => setState(() {
        _session = Duration.zero;
        _onBreak = false;
      });

  @override
  Widget build(BuildContext context) {
    return SoundStepsScope(
      settings: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => MaterialApp(
          title: AppFlavor.soundsteps.displayName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFFFF8A5B),
            fontFamily: 'Nunito',
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
            }),
          ),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              // The parent's "calmer screen" switch adds to the device's own
              // reduce-motion setting; it never turns that off.
              data: mq.copyWith(
                disableAnimations:
                    mq.disableAnimations || _settings.reduceMotion,
              ),
              child: Stack(
                children: [
                  child!,
                  if (_onBreak)
                    // Its own Navigator: the overlay sits above the app's
                    // navigator, and the grown-ups' gate opens a dialog,
                    // which needs one to open into.
                    Positioned.fill(
                      child: HeroControllerScope.none(
                        child: Navigator(
                          onGenerateRoute: (_) => PageRouteBuilder<void>(
                            pageBuilder: (_, __, ___) =>
                                BreakOverlay(onKeepPlaying: _keepPlaying),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          home: _settings.onboarded
              ? SoundStepsHome(speaker: _speaker, progress: widget.progress)
              : WelcomeScreen(settings: _settings),
        ),
      ),
    );
  }
}
