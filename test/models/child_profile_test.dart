import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/utils/clock.dart';

/// Ages are asserted against a frozen clock and explicit dates.
///
/// These previously built a date of birth with `DateTime(year, month - 6, day)`
/// relative to today, which Dart silently normalises when the target month is
/// shorter than the current day: run on the 31st of August,
/// `DateTime(2026, 2, 31)` becomes 3 March, so "six months ago" was really five
/// months and 28 days and the test failed. It only broke on certain calendar
/// days, which is the worst kind of flake.
void main() {
  // A mid-month date, so no arithmetic below can roll over a month boundary.
  final today = DateTime(2026, 8, 15, 12);
  setUp(() => Clock.freeze(today));
  tearDown(Clock.reset);

  ChildProfile bornOn(DateTime dob) =>
      ChildProfile(name: 'A', dateOfBirth: dob, createdAt: dob);

  group('ChildProfile.ageInWeeks', () {
    test('returns 0 for newborn born today', () {
      expect(bornOn(today).ageInWeeks, 0);
    });

    test('returns 2 for 14-day-old baby', () {
      expect(bornOn(DateTime(2026, 8, 1)).ageInWeeks, 2);
    });

    test('returns 26 for 182-day-old baby', () {
      expect(bornOn(DateTime(2026, 2, 14)).ageInWeeks, 26);
    });
  });

  group('ChildProfile.ageInMonths', () {
    test('returns 0 for newborn', () {
      expect(bornOn(today).ageInMonths, 0);
    });

    test('returns 6 for a 6-month-old', () {
      expect(bornOn(DateTime(2026, 2, 15)).ageInMonths, 6);
    });

    test('returns 12 for a 1-year-old', () {
      expect(bornOn(DateTime(2025, 8, 15)).ageInMonths, 12);
    });

    test('a birth date on the 31st does not roll into the next month', () {
      // 31 March to 15 August is four full months, not five: the day of the
      // month has not come round yet.
      Clock.freeze(DateTime(2026, 8, 15, 12));
      expect(bornOn(DateTime(2026, 3, 31)).ageInMonths, 4);
    });
  });

  group('ChildProfile.displayAge', () {
    test('shows weeks for baby under 4 weeks', () {
      expect(bornOn(DateTime(2026, 8, 5)).displayAge, contains('week'));
    });

    test('shows weeks for baby between 4 and 26 weeks', () {
      expect(bornOn(DateTime(2026, 6, 6)).displayAge, contains('week'));
    });

    test('shows months for baby between 6 and 24 months', () {
      expect(bornOn(DateTime(2025, 11, 15)).displayAge, contains('month'));
    });

    test('shows yr for baby 2+ years', () {
      expect(bornOn(DateTime(2024, 8, 15)).displayAge, contains('yr'));
    });
  });

  group('ChildProfile.ageBandWeeks', () {
    test('clamps to 0 for newborn', () {
      final profile = ChildProfile(
          name: 'A', dateOfBirth: DateTime.now(), createdAt: DateTime.now());
      expect(profile.ageBandWeeks, 0);
    });

    test('clamps to 156 for 4+ year old', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 4));
      final profile =
          ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.ageBandWeeks, 156);
    });

    test('returns actual value within range', () {
      expect(bornOn(DateTime(2026, 6, 6)).ageBandWeeks, 10);
    });
  });

  group('ChildProfile serialization', () {
    test('toMap/fromMap roundtrip preserves all fields', () {
      final dob = DateTime(2024, 3, 15, 0, 0, 0);
      final created = DateTime(2024, 3, 15, 10, 30, 0);
      final original = ChildProfile(
          id: 42, name: 'Emma', dateOfBirth: dob, createdAt: created);
      final restored = ChildProfile.fromMap(original.toMap());

      expect(restored.id, 42);
      expect(restored.name, 'Emma');
      expect(restored.dateOfBirth.toIso8601String(), dob.toIso8601String());
      expect(restored.createdAt.toIso8601String(), created.toIso8601String());
    });

    test('toMap excludes id when null', () {
      final profile = ChildProfile(
          name: 'Bug',
          dateOfBirth: DateTime(2024, 1, 1),
          createdAt: DateTime.now());
      final map = profile.toMap();
      expect(map['id'], isNull);
      expect(map['name'], 'Bug');
    });
  });

  group('ChildProfile.copyWith', () {
    test('updates only name, preserves other fields', () {
      final original = ChildProfile(
          id: 1,
          name: 'Old',
          dateOfBirth: DateTime(2024, 1, 1),
          createdAt: DateTime.now());
      final updated = original.copyWith(name: 'New');
      expect(updated.name, 'New');
      expect(updated.id, 1);
      expect(updated.dateOfBirth, original.dateOfBirth);
    });

    test('updates dateOfBirth', () {
      final original = ChildProfile(
          id: 1,
          name: 'A',
          dateOfBirth: DateTime(2024, 1, 1),
          createdAt: DateTime.now());
      final newDob = DateTime(2024, 6, 1);
      final updated = original.copyWith(dateOfBirth: newDob);
      expect(updated.dateOfBirth, newDob);
    });
  });
}
