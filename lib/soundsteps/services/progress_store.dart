import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/stickers.dart';

/// How a child is doing on one letter.
@immutable
class LetterStats {
  const LetterStats({this.correct = 0, this.misses = 0});

  /// Rounds answered right on the first try.
  final int correct;

  /// Rounds where a wrong letter was tapped first (counted once per round).
  final int misses;

  bool get isNew => correct == 0 && misses == 0;

  /// Right on the first try at least three times, and more often than not.
  bool get mastered => correct >= 3 && correct > misses;

  LetterStats copyWith({int? correct, int? misses}) => LetterStats(
      correct: correct ?? this.correct, misses: misses ?? this.misses);
}

/// What the child has done, kept on the device and nowhere else.
///
/// A [ChangeNotifier] so the home screen's star count and the letters grid's
/// "mastered" badges update as the games record results. Persistence is
/// best-effort: if storage fails, the session carries on from memory and the
/// child never sees an error.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs, this._stars, this._letters);

  /// In-memory only; nothing is saved. For tests and as a safe fallback.
  factory ProgressStore.memory() => ProgressStore._(null, 0, {});

  static const String storageKey = 'soundsteps.progress.v1';

  /// Loads saved progress. Missing, corrupt or unreadable data starts fresh.
  static Future<ProgressStore> open([SharedPreferences? prefs]) async {
    try {
      prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      return ProgressStore.memory();
    }
    var stars = 0;
    final letters = <String, LetterStats>{};
    try {
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        stars = (json['stars'] as num).toInt();
        (json['letters'] as Map<String, dynamic>).forEach((letter, v) {
          final m = v as Map<String, dynamic>;
          letters[letter] = LetterStats(
            correct: (m['c'] as num).toInt(),
            misses: (m['m'] as num).toInt(),
          );
        });
      }
    } catch (_) {
      stars = 0;
      letters.clear();
    }
    return ProgressStore._(prefs, stars, letters);
  }

  final SharedPreferences? _prefs;
  int _stars;
  final Map<String, LetterStats> _letters;

  int get stars => _stars;

  LetterStats statsFor(String letter) =>
      _letters[letter] ?? const LetterStats();

  /// Stickers earned so far; derived from stars, so nothing extra is stored.
  int get stickersUnlocked => stickersFor(_stars);

  int get masteredCount => _letters.values.where((s) => s.mastered).length;

  /// A wrong first tap on [letter]'s round.
  Future<void> recordMiss(String letter) {
    final s = statsFor(letter);
    _letters[letter] = s.copyWith(misses: s.misses + 1);
    return _changed();
  }

  /// The round for [letter] was solved. A star is always earned; the letter
  /// only moves toward "mastered" if it was right on the first try.
  Future<void> recordSuccess(String letter, {required bool firstTry}) {
    _stars++;
    if (firstTry) {
      final s = statsFor(letter);
      _letters[letter] = s.copyWith(correct: s.correct + 1);
    }
    return _changed();
  }

  Future<void> reset() {
    _stars = 0;
    _letters.clear();
    return _changed();
  }

  Future<void> _changed() async {
    notifyListeners();
    try {
      await _prefs?.setString(
        storageKey,
        jsonEncode({
          'stars': _stars,
          'letters': {
            for (final e in _letters.entries)
              e.key: {'c': e.value.correct, 'm': e.value.misses},
          },
        }),
      );
    } catch (_) {
      // Keep playing from memory.
    }
  }
}
