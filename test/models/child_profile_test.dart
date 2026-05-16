import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/models/child_profile.dart';

void main() {
  group('ChildProfile.ageInWeeks', () {
    test('returns 0 for newborn born today', () {
      final profile = ChildProfile(name: 'A', dateOfBirth: DateTime.now(), createdAt: DateTime.now());
      expect(profile.ageInWeeks, 0);
    });

    test('returns 2 for 14-day-old baby', () {
      final dob = DateTime.now().subtract(const Duration(days: 14));
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.ageInWeeks, 2);
    });

    test('returns 26 for 182-day-old baby', () {
      final dob = DateTime.now().subtract(const Duration(days: 182));
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.ageInWeeks, 26);
    });
  });

  group('ChildProfile.ageInMonths', () {
    test('returns 0 for newborn', () {
      final profile = ChildProfile(name: 'A', dateOfBirth: DateTime.now(), createdAt: DateTime.now());
      expect(profile.ageInMonths, 0);
    });

    test('returns 6 for a 6-month-old', () {
      final now = DateTime.now();
      final dob = DateTime(now.year, now.month - 6, now.day);
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.ageInMonths, 6);
    });

    test('returns 12 for a 1-year-old', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 1, now.month, now.day);
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.ageInMonths, 12);
    });
  });

  group('ChildProfile.displayAge', () {
    test('shows weeks for baby under 4 weeks', () {
      final dob = DateTime.now().subtract(const Duration(days: 10));
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.displayAge, contains('week'));
    });

    test('shows weeks for baby between 4 and 26 weeks', () {
      final dob = DateTime.now().subtract(const Duration(days: 70));
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.displayAge, contains('week'));
    });

    test('shows months for baby between 6 and 24 months', () {
      final now = DateTime.now();
      final dob = DateTime(now.year, now.month - 9, now.day);
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.displayAge, contains('month'));
    });

    test('shows yr for baby 2+ years', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 2, now.month, now.day);
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.displayAge, contains('yr'));
    });
  });

  group('ChildProfile.ageBandWeeks', () {
    test('clamps to 0 for newborn', () {
      final profile = ChildProfile(name: 'A', dateOfBirth: DateTime.now(), createdAt: DateTime.now());
      expect(profile.ageBandWeeks, 0);
    });

    test('clamps to 156 for 4+ year old', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 4));
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.ageBandWeeks, 156);
    });

    test('returns actual value within range', () {
      final dob = DateTime.now().subtract(const Duration(days: 70));
      final profile = ChildProfile(name: 'A', dateOfBirth: dob, createdAt: DateTime.now());
      expect(profile.ageBandWeeks, 10);
    });
  });

  group('ChildProfile serialization', () {
    test('toMap/fromMap roundtrip preserves all fields', () {
      final dob = DateTime(2024, 3, 15, 0, 0, 0);
      final created = DateTime(2024, 3, 15, 10, 30, 0);
      final original = ChildProfile(id: 42, name: 'Emma', dateOfBirth: dob, createdAt: created);
      final restored = ChildProfile.fromMap(original.toMap());

      expect(restored.id, 42);
      expect(restored.name, 'Emma');
      expect(restored.dateOfBirth.toIso8601String(), dob.toIso8601String());
      expect(restored.createdAt.toIso8601String(), created.toIso8601String());
    });

    test('toMap excludes id when null', () {
      final profile = ChildProfile(name: 'Bug', dateOfBirth: DateTime(2024, 1, 1), createdAt: DateTime.now());
      final map = profile.toMap();
      expect(map['id'], isNull);
      expect(map['name'], 'Bug');
    });
  });

  group('ChildProfile.copyWith', () {
    test('updates only name, preserves other fields', () {
      final original = ChildProfile(id: 1, name: 'Old', dateOfBirth: DateTime(2024, 1, 1), createdAt: DateTime.now());
      final updated = original.copyWith(name: 'New');
      expect(updated.name, 'New');
      expect(updated.id, 1);
      expect(updated.dateOfBirth, original.dateOfBirth);
    });

    test('updates dateOfBirth', () {
      final original = ChildProfile(id: 1, name: 'A', dateOfBirth: DateTime(2024, 1, 1), createdAt: DateTime.now());
      final newDob = DateTime(2024, 6, 1);
      final updated = original.copyWith(dateOfBirth: newDob);
      expect(updated.dateOfBirth, newDob);
    });
  });
}
