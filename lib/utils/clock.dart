import 'package:flutter/foundation.dart' show visibleForTesting;

/// The app's source of "now".
///
/// Domain logic reads the current time through this rather than calling
/// `DateTime.now()` directly, so behaviour that depends on the clock — streaks
/// rolling over at midnight, a child's age on their birthday, the day-of-year
/// rotation that picks each day's activity — can be tested at a chosen instant
/// instead of only at whatever time the suite happens to run.
///
/// Presentation code (timestamps in exported PDFs, filenames, `updated_at`
/// columns) may still use `DateTime.now()`; only decisions worth asserting on
/// need to be controllable.
class Clock {
  Clock._();

  static DateTime Function() _source = DateTime.now;

  /// The current local time.
  static DateTime now() => _source();

  /// Today with the time component stripped, in local time.
  ///
  /// Use this instead of arithmetic on a Duration when comparing calendar
  /// days: a Duration is always 24 hours, but a calendar day is 23 or 25 hours
  /// across a daylight-saving transition.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Pins [now] to a fixed instant for the duration of a test.
  ///
  /// Always pair with [reset], e.g. `addTearDown(Clock.reset)`.
  @visibleForTesting
  static void freeze(DateTime instant) => _source = () => instant;

  /// Restores the real system clock.
  @visibleForTesting
  static void reset() => _source = DateTime.now;
}
