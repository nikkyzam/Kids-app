import 'clock.dart';

/// Timestamp handling for last-write-wins sync.
///
/// Rows carry an `updated_at` string and the newer one wins. That comparison is
/// only meaningful if both sides describe the same instant in the same frame of
/// reference, so timestamps are written in UTC and compared as parsed instants
/// rather than as text.
class SyncTimestamp {
  SyncTimestamp._();

  /// The value to store in an `updated_at` column.
  ///
  /// Always UTC (with a trailing `Z`). Writing local wall-clock time makes a
  /// device's timezone offset look like recency: a phone in UTC+10 would appear
  /// ten hours "newer" than one in UTC, and would win every conflict against a
  /// genuinely later edit made further west.
  static String now() => Clock.now().toUtc().toIso8601String();

  static String from(DateTime time) => time.toUtc().toIso8601String();

  /// How far ahead of this device's clock a remote timestamp may be.
  ///
  /// Devices in a family are not perfectly synchronised, so a little skew is
  /// expected and must not cause edits to be dropped.
  static const Duration maxClockSkew = Duration(days: 1);

  /// Parses an `updated_at` value to an absolute instant.
  ///
  /// Handles legacy rows written before timestamps were normalised: a string
  /// with no zone designator is interpreted as local time, which is what those
  /// rows actually meant, so old and new records remain comparable.
  ///
  /// Returns null for anything implausible. `DateTime.tryParse` silently rolls
  /// out-of-range components over — `2026-13-45T99:99:99Z` becomes 2027-02-18 —
  /// so a corrupt row would otherwise land far in the future, win every
  /// conflict, and overwrite good local data until real time caught up.
  static DateTime? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;

    final utc = parsed.toUtc();
    if (utc.isAfter(Clock.now().toUtc().add(maxClockSkew))) return null;
    return utc;
  }

  /// Whether [remote] represents a strictly later edit than [local].
  ///
  /// Unparseable or missing values are treated as "not newer" so a malformed
  /// remote row can never overwrite good local data.
  static bool isRemoteNewer(String? remote, String? local) {
    final r = parse(remote);
    if (r == null) return false;
    final l = parse(local);
    if (l == null) return true;
    return r.isAfter(l);
  }
}
