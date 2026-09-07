import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/utils/calendar.dart';

/// Every "how old is this child" and "how many days of history" number in the
/// app is a count of calendar days. Measuring one as elapsed time instead is
/// correct for most of the year and off by one for the half of the world that
/// observes daylight saving — twice a year, silently. These pin the
/// distinction down. CI runs the whole suite a second time under
/// `TZ=America/New_York`, which is where the interesting cases are.
void main() {
  group('calendarDaysBetween', () {
    test('is zero for the same day, whatever the time of day', () {
      expect(
          calendarDaysBetween(DateTime(2026, 5, 20), DateTime(2026, 5, 20)), 0);
      expect(
        calendarDaysBetween(
            DateTime(2026, 5, 20, 23, 59), DateTime(2026, 5, 20, 0, 1)),
        0,
        reason: 'the time of day is not part of a calendar day count',
      );
    });

    test('counts whole days regardless of the hours on either end', () {
      // 23 elapsed hours, but one calendar day.
      expect(
        calendarDaysBetween(
            DateTime(2026, 5, 20, 23, 0), DateTime(2026, 5, 21, 22, 0)),
        1,
      );
      // 49 elapsed hours, but two calendar days.
      expect(
        calendarDaysBetween(
            DateTime(2026, 5, 20, 1, 0), DateTime(2026, 5, 22, 2, 0)),
        2,
      );
    });

    test('is exact across a spring-forward transition', () {
      // 8 March 2026 is the US spring-forward date: that day is 23 hours long,
      // so `to.difference(from).inDays` truncates to 1.
      final from = DateTime(2026, 3, 7);
      final to = DateTime(2026, 3, 9);

      expect(calendarDaysBetween(from, to), 2);
      if (from.timeZoneOffset != to.timeZoneOffset) {
        expect(to.difference(from).inDays, 1,
            reason: 'this is the truncation the function exists to avoid');
      }
    });

    test('is exact across a fall-back transition', () {
      // 1 November 2026 is 25 hours long in the US.
      final from = DateTime(2026, 10, 31);
      final to = DateTime(2026, 11, 2);

      expect(calendarDaysBetween(from, to), 2);
    });

    test('is exact across a whole year containing both transitions', () {
      expect(
          calendarDaysBetween(DateTime(2026, 1, 1), DateTime(2027, 1, 1)), 365);
      // 2024 was a leap year.
      expect(
          calendarDaysBetween(DateTime(2024, 1, 1), DateTime(2025, 1, 1)), 366);
    });

    test('is negative when the dates are the other way round', () {
      expect(calendarDaysBetween(DateTime(2026, 5, 21), DateTime(2026, 5, 20)),
          -1);
    });

    test('compares a UTC date against a local one by its calendar day', () {
      // Synced rows arrive as UTC; profile dates are local. Both are reduced
      // to their own calendar components, so neither is shifted by a zone.
      expect(
        calendarDaysBetween(
            DateTime.utc(2026, 5, 20, 12), DateTime(2026, 5, 22, 3)),
        2,
      );
    });
  });
}
