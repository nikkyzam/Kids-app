import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/utils/clock.dart';

/// Corrected age for a baby born early.
///
/// As with the other age tests, everything is asserted against a frozen clock
/// and explicit dates so a run on the 31st of a month cannot produce a
/// different answer than a run on the 1st.
void main() {
  final today = DateTime(2026, 8, 15, 12);
  setUp(() => Clock.freeze(today));
  tearDown(Clock.reset);

  ChildProfile born(DateTime dob, {DateTime? due}) =>
      ChildProfile(name: 'A', dateOfBirth: dob, dueDate: due, createdAt: dob);

  group('a term birth', () {
    final termBaby = born(DateTime(2026, 5, 15));

    test('has no correction at all', () {
      expect(termBaby.wasBornEarly, isFalse);
      expect(termBaby.usesAdjustedAge, isFalse);
      expect(termBaby.prematureDays, 0);
    });

    test('matches content against the chronological age', () {
      expect(termBaby.contentAgeBandWeeks, termBaby.ageBandWeeks);
      expect(termBaby.contentAgeInMonths, termBaby.ageInMonths);
    });

    test('shows a single age, with nothing about adjustment', () {
      expect(termBaby.ageSummary, termBaby.displayAge);
      expect(termBaby.ageSummary, isNot(contains('adjusted')));
    });
  });

  group('a baby born eight weeks early', () {
    // Born 15 May, originally due 10 July: 56 days early.
    final preemie = born(DateTime(2026, 5, 15), due: DateTime(2026, 7, 10));

    test('reports the gestational correction in days', () {
      expect(preemie.prematureDays, 56);
      expect(preemie.wasBornEarly, isTrue);
      expect(preemie.usesAdjustedAge, isTrue);
    });

    test('is corrected by exactly that many days', () {
      expect(preemie.ageInDays, 92);
      expect(preemie.adjustedAgeInDays, 92 - 56);
      expect(preemie.ageInWeeks, 13);
      expect(preemie.adjustedAgeInWeeks, 5);
    });

    test('matches activities against the corrected age', () {
      expect(preemie.contentAgeBandWeeks, 5);
      expect(preemie.ageBandWeeks, 13);
    });

    test('counts corrected months from the due date', () {
      // Due 10 July, so on 15 August the corrected age is one month.
      expect(preemie.adjustedAgeInMonths, 1);
      expect(preemie.ageInMonths, 3);
    });

    test('shows both ages, never the corrected one alone', () {
      expect(preemie.ageSummary, contains(preemie.displayAge));
      expect(preemie.ageSummary, contains('adjusted'));
    });
  });

  test('correction stops at two years', () {
    // Born 1 June 2024, due 1 August 2024: still under two on the day before
    // the second birthday, and no longer corrected on the birthday itself.
    final dob = DateTime(2024, 6, 1);
    final due = DateTime(2024, 8, 1);

    Clock.freeze(DateTime(2026, 5, 31, 12));
    final justUnderTwo = born(dob, due: due);
    expect(justUnderTwo.usesAdjustedAge, isTrue);
    expect(justUnderTwo.adjustedAgeInWeeks, lessThan(justUnderTwo.ageInWeeks));

    Clock.freeze(DateTime(2026, 6, 1, 12));
    final exactlyTwo = born(dob, due: due);
    expect(exactlyTwo.ageInMonths, 24);
    expect(exactlyTwo.usesAdjustedAge, isFalse);
    expect(exactlyTwo.contentAgeBandWeeks, exactlyTwo.ageBandWeeks);
    expect(exactlyTwo.ageSummary, exactlyTwo.displayAge);
  });

  group('nonsense due dates never make a child younger than they are', () {
    test('a due date on the birth date is no correction', () {
      final p = born(DateTime(2026, 5, 15), due: DateTime(2026, 5, 15));
      expect(p.prematureDays, 0);
      expect(p.usesAdjustedAge, isFalse);
    });

    test('a baby born late is not aged up', () {
      final p = born(DateTime(2026, 5, 15), due: DateTime(2026, 5, 1));
      expect(p.prematureDays, 0);
      expect(p.adjustedAgeInDays, p.ageInDays);
    });

    test('an impossible gap is clamped to 17 weeks', () {
      // A corrupt row claiming the baby was a year early would otherwise push
      // a toddler back into newborn content.
      final p = born(DateTime(2026, 5, 15), due: DateTime(2027, 5, 15));
      expect(p.prematureDays, 119);
      expect(p.adjustedAgeInDays, 0);
    });
  });

  group('serialisation', () {
    test('round-trips the due date and sex', () {
      final p = ChildProfile(
        name: 'A',
        dateOfBirth: DateTime(2026, 5, 15),
        dueDate: DateTime(2026, 7, 10),
        sex: ChildSex.female,
        createdAt: DateTime(2026, 5, 15),
      );
      final back = ChildProfile.fromMap(p.toMap());
      expect(back.dueDate, p.dueDate);
      expect(back.sex, ChildSex.female);
    });

    test('a profile written before the column existed still loads', () {
      final back = ChildProfile.fromMap({
        'id': 1,
        'uuid': 'u',
        'name': 'A',
        'date_of_birth': DateTime(2026, 5, 15).toIso8601String(),
        'created_at': DateTime(2026, 5, 15).toIso8601String(),
      });
      expect(back.dueDate, isNull);
      expect(back.sex, isNull);
      expect(back.usesAdjustedAge, isFalse);
    });

    test('a corrupt due date reads as a term birth rather than crashing', () {
      final back = ChildProfile.fromMap({
        'name': 'A',
        'date_of_birth': DateTime(2026, 5, 15).toIso8601String(),
        'due_date': 'not-a-date',
        'sex': 'martian',
        'created_at': DateTime(2026, 5, 15).toIso8601String(),
      });
      expect(back.dueDate, isNull);
      expect(back.sex, isNull);
    });

    test('copyWith can clear the due date and the sex', () {
      final p = ChildProfile(
        name: 'A',
        dateOfBirth: DateTime(2026, 5, 15),
        dueDate: DateTime(2026, 7, 10),
        sex: ChildSex.male,
        createdAt: DateTime(2026, 5, 15),
      );
      final cleared = p.copyWith(clearDueDate: true, clearSex: true);
      expect(cleared.dueDate, isNull);
      expect(cleared.sex, isNull);
    });
  });
}
