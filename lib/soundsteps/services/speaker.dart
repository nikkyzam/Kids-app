import 'package:flutter_tts/flutter_tts.dart';

/// Speaks text aloud. An interface so screens never touch the plugin and
/// tests can record what would have been said.
abstract class Speaker {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Device text-to-speech. Slow and high-pitched for small children.
///
/// Speech must never crash the app: if the device has no engine, a call
/// swallows the error and the screens still work, silently.
class TtsSpeaker implements Speaker {
  TtsSpeaker({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(0.4);
        await _tts.setPitch(1.15);
      }();

  @override
  Future<void> speak(String text) async {
    try {
      await _init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // No engine available; stay silent rather than interrupt a child.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
