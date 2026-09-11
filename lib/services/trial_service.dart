import 'package:shared_preferences/shared_preferences.dart';

import '../utils/clock.dart';

/// The free trial, which starts when onboarding creates the first profile.
///
/// The age-based free tier alone gave a parent four weeks of content before a
/// paywall — and a newborn's parent has neither the time nor the sleep to
/// evaluate an app in that window. The trial opens everything for a fortnight
/// from first launch; when it lapses the app falls back to the age-based free
/// tier rather than locking the door, so nothing a parent already recorded
/// becomes unreachable.
class TrialService {
  TrialService._();

  static const String firstLaunchKey = 'first_launch_at';

  static const Duration length = Duration(days: 14);

  /// Stamps the trial start, once. Safe to call after every profile save.
  ///
  /// Stored rather than derived from the install date, which no platform
  /// exposes consistently. A parent who reinstalls does get a fresh trial;
  /// tying it to an account would mean requiring an account, which this app
  /// deliberately does not.
  static Future<DateTime> recordFirstLaunch(SharedPreferences prefs) async {
    final existing = startedAt(prefs);
    if (existing != null) return existing;
    final now = Clock.now();
    await prefs.setString(firstLaunchKey, now.toIso8601String());
    return now;
  }

  static DateTime? startedAt(SharedPreferences prefs) {
    final raw = prefs.getString(firstLaunchKey);
    if (raw == null) return null;
    // A corrupt value must not take the launch down with it; the trial simply
    // reads as not yet started and is stamped again.
    return DateTime.tryParse(raw);
  }

  static DateTime? endsAt(SharedPreferences prefs) {
    final start = startedAt(prefs);
    return start?.add(length);
  }

  static bool isActive(SharedPreferences prefs) {
    final end = endsAt(prefs);
    if (end == null) return false;
    return Clock.now().isBefore(end);
  }

  /// Whole days left, rounded up, so the last partial day still reads as "1
  /// day left" rather than "0 days left" while the trial is in fact running.
  static int daysRemaining(SharedPreferences prefs) {
    final end = endsAt(prefs);
    if (end == null) return 0;
    final remaining = end.difference(Clock.now());
    if (remaining.isNegative) return 0;
    // Minutes, not hours: `inHours` truncates first, so the last hour of the
    // trial read as "0 days left" while everything was still unlocked.
    final days = remaining.inMinutes / Duration.minutesPerDay;
    return days.ceil().clamp(0, length.inDays);
  }

  /// True once the trial has been used up — as distinct from never started.
  /// The paywall says something different in each case.
  static bool hasLapsed(SharedPreferences prefs) =>
      startedAt(prefs) != null && !isActive(prefs);
}
