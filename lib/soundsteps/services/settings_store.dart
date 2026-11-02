import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How fast Pip talks.
enum SpeechSpeed {
  /// For the youngest listeners; the default.
  slow(0.32),
  normal(0.45);

  const SpeechSpeed(this.rate);

  /// flutter_tts rate (0..1, platform-scaled).
  final double rate;
}

/// The grown-up's choices, kept on the device only.
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs, Map<String, dynamic> json)
      : _childName = (json['name'] as String?) ?? '',
        _speed = SpeechSpeed.values.firstWhere(
          (s) => s.name == json['speed'],
          orElse: () => SpeechSpeed.slow,
        ),
        _breakMinutes = (json['break'] as num?)?.toInt() ?? 0,
        _haptics = (json['haptics'] as bool?) ?? true,
        _reduceMotion = (json['reduceMotion'] as bool?) ?? false,
        _onboarded = (json['onboarded'] as bool?) ?? false;

  /// In memory only. [onboarded] defaults to true so tests and previews go
  /// straight to the home screen.
  factory SettingsStore.memory({bool onboarded = true}) =>
      SettingsStore._(null, {'onboarded': onboarded});

  static const String storageKey = 'soundsteps.settings.v1';

  /// Break-reminder choices offered to parents, in minutes. 0 = off.
  static const List<int> breakChoices = [0, 10, 15, 20, 30];

  static Future<SettingsStore> open([SharedPreferences? prefs]) async {
    try {
      prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      return SettingsStore.memory(onboarded: false);
    }
    try {
      final raw = prefs.getString(storageKey);
      final json = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      return SettingsStore._(prefs, json);
    } catch (_) {
      return SettingsStore._(prefs, {});
    }
  }

  final SharedPreferences? _prefs;
  String _childName;
  SpeechSpeed _speed;
  int _breakMinutes;
  bool _haptics;
  bool _reduceMotion;
  bool _onboarded;

  /// Optional first name or nickname; empty when not given.
  String get childName => _childName;
  SpeechSpeed get speed => _speed;
  int get breakMinutes => _breakMinutes;
  bool get haptics => _haptics;
  bool get reduceMotion => _reduceMotion;
  bool get onboarded => _onboarded;

  set childName(String v) => _set(() => _childName = v.trim());
  set speed(SpeechSpeed v) => _set(() => _speed = v);
  set breakMinutes(int v) => _set(() => _breakMinutes = v < 0 ? 0 : v);
  set haptics(bool v) => _set(() => _haptics = v);
  set reduceMotion(bool v) => _set(() => _reduceMotion = v);
  set onboarded(bool v) => _set(() => _onboarded = v);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      await _prefs?.setString(
        storageKey,
        jsonEncode({
          'name': _childName,
          'speed': _speed.name,
          'break': _breakMinutes,
          'haptics': _haptics,
          'reduceMotion': _reduceMotion,
          'onboarded': _onboarded,
        }),
      );
    } catch (_) {
      // Settings still apply for this session.
    }
  }
}

/// Makes the [SettingsStore] reachable from any SoundSteps widget, and
/// rebuilds dependents when a setting changes.
class SoundStepsScope extends InheritedNotifier<SettingsStore> {
  const SoundStepsScope({
    super.key,
    required SettingsStore settings,
    required super.child,
  }) : super(notifier: settings);

  /// Null outside a scope (e.g. a screen pumped alone in a test).
  static SettingsStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SoundStepsScope>()?.notifier;
}
