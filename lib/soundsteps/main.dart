import 'package:flutter/material.dart';

import 'services/progress_store.dart';
import 'soundsteps_app.dart';

/// SoundSteps on its own, without importing any PlaySteps code. Used for
/// quick previews, e.g. in a browser:
///
///   flutter run -d chrome -t lib/soundsteps/main.dart
///
/// Store builds still go through lib/main.dart with the soundsteps flavor
/// (tool/build_app.sh), which boots this same app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SoundStepsApp(progress: await ProgressStore.open()));
}
