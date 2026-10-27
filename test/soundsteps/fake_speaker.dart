import 'package:playsteps/soundsteps/services/speaker.dart';

/// Records what would have been spoken.
class RecordingSpeaker implements Speaker {
  final List<String> said = [];

  @override
  Future<void> speak(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}
