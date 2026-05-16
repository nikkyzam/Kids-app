import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/data/milestones_data.dart';
import 'package:playsteps/models/milestone.dart';

void main() {
  group('MilestonesData.all', () {
    test('contains milestones', () {
      expect(MilestonesData.all, isNotEmpty);
    });

    test('all milestones have non-empty descriptions', () {
      for (final m in MilestonesData.all) {
        expect(m.description, isNotEmpty, reason: 'Milestone ${m.id} has empty description');
      }
    });

    test('all milestone IDs are unique', () {
      final ids = MilestonesData.all.map((m) => m.id).toList();
      expect(ids.length, ids.toSet().length);
    });

    test('all milestone age groups are positive', () {
      for (final m in MilestonesData.all) {
        expect(m.ageGroupMonths, greaterThan(0));
      }
    });

    test('covers all expected age groups', () {
      final expected = {2, 4, 6, 9, 12, 15, 18, 24, 30, 36};
      final actual = MilestonesData.all.map((m) => m.ageGroupMonths).toSet();
      for (final ag in expected) {
        expect(actual, contains(ag), reason: 'Missing age group $ag months');
      }
    });

    test('all domains are represented across all milestones', () {
      final domains = MilestonesData.all.map((m) => m.domain).toSet();
      for (final domain in MilestoneDomain.values) {
        expect(domains, contains(domain));
      }
    });

    test('each age group has milestones in multiple domains', () {
      for (final ageGroup in MilestonesData.ageGroups) {
        final milestones = MilestonesData.forAgeGroup(ageGroup);
        final domains = milestones.map((m) => m.domain).toSet();
        expect(domains.length, greaterThanOrEqualTo(2),
            reason: 'Age group $ageGroup months has too few domains');
      }
    });
  });

  group('MilestonesData.forAgeGroup', () {
    test('returns milestones for 2 months', () {
      final results = MilestonesData.forAgeGroup(2);
      expect(results, isNotEmpty);
      expect(results.every((m) => m.ageGroupMonths == 2), isTrue);
    });

    test('returns milestones for 12 months', () {
      final results = MilestonesData.forAgeGroup(12);
      expect(results, isNotEmpty);
      expect(results.every((m) => m.ageGroupMonths == 12), isTrue);
    });

    test('returns empty for unknown age group', () {
      final results = MilestonesData.forAgeGroup(99);
      expect(results, isEmpty);
    });
  });

  group('MilestonesData.filterByDomain', () {
    test('null domain returns all milestones', () {
      final all = MilestonesData.all;
      final filtered = MilestonesData.filterByDomain(all, null);
      expect(filtered.length, all.length);
    });

    test('filters to gross motor only', () {
      final filtered = MilestonesData.filterByDomain(MilestonesData.all, MilestoneDomain.grossMotor);
      expect(filtered, isNotEmpty);
      expect(filtered.every((m) => m.domain == MilestoneDomain.grossMotor), isTrue);
    });

    test('filters to language only', () {
      final filtered = MilestonesData.filterByDomain(MilestonesData.all, MilestoneDomain.language);
      expect(filtered, isNotEmpty);
      expect(filtered.every((m) => m.domain == MilestoneDomain.language), isTrue);
    });

    test('filtered results are a subset of the original list', () {
      final all = MilestonesData.all;
      for (final domain in MilestoneDomain.values) {
        final filtered = MilestonesData.filterByDomain(all, domain);
        expect(filtered.length, lessThanOrEqualTo(all.length));
      }
    });
  });

  group('MilestonesData.ageGroups', () {
    test('returns the expected list of age groups', () {
      expect(MilestonesData.ageGroups, equals([2, 4, 6, 9, 12, 15, 18, 24, 30, 36]));
    });

    test('is sorted in ascending order', () {
      final groups = MilestonesData.ageGroups;
      for (int i = 1; i < groups.length; i++) {
        expect(groups[i], greaterThan(groups[i - 1]));
      }
    });
  });
}
