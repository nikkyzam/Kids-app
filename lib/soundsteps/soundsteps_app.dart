import 'package:flutter/material.dart';

import '../config/app_flavor.dart';
import 'screens/home_screen.dart';
import 'services/progress_store.dart';
import 'services/speaker.dart';

class SoundStepsApp extends StatelessWidget {
  const SoundStepsApp({super.key, required this.progress, this.speaker});

  /// Saved progress; opened before the app starts (see `main`).
  final ProgressStore progress;

  /// Injectable for tests; defaults to device text-to-speech.
  final Speaker? speaker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppFlavor.soundsteps.displayName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF8A5B),
        fontFamily: 'Nunito',
      ),
      home: SoundStepsHome(
        speaker: speaker ?? TtsSpeaker(),
        progress: progress,
      ),
    );
  }
}
