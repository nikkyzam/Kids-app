import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/data/who_growth_standards_data.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/models/growth_measurement.dart';
import 'package:playsteps/services/who_growth_standards.dart';

/// The bundled table is transcribed rather than fetched at runtime, so these
/// tests are what stands between a corrupted or half-regenerated file and a
/// parent reading a wrong number about their child. The anchors below are
/// WHO's own published medians and percentile values.
void main() {
  group('the bundled table', () {
    test('covers every metric and sex from birth to 36 months', () {
      for (final metric in GrowthMetric.values) {
        for (final sex in ChildSex.values) {
          final table = WhoGrowthStandardsData.tableFor(metric, sex);
          expect(table, isNotNull, reason: '$metric / $sex missing');
          for (int month = 0; month <= 36; month++) {
            expect(table![month], isNotNull,
                reason: '$metric / $sex has no row for month $month');
          }
        }
      }
    });

    test('holds its medians at the anchor ages', () {
      // A tripwire against a corrupted or half-regenerated file rather than an
      // independent check of the numbers — the SD test below is the one that
      // validates them against WHO's own published output.
      const anchors = <List<Object>>[
        [GrowthMetric.weight, ChildSex.male, 0, 3.3464],
        [GrowthMetric.weight, ChildSex.female, 0, 3.2322],
        [GrowthMetric.weight, ChildSex.male, 12, 9.6479],
        [GrowthMetric.weight, ChildSex.female, 12, 8.9481],
        [GrowthMetric.weight, ChildSex.male, 24, 12.1515],
        [GrowthMetric.weight, ChildSex.female, 24, 11.4775],
        [GrowthMetric.height, ChildSex.male, 0, 49.8842],
        [GrowthMetric.height, ChildSex.female, 0, 49.1477],
        [GrowthMetric.height, ChildSex.male, 12, 75.7488],
        [GrowthMetric.height, ChildSex.female, 12, 74.0150],
        [GrowthMetric.headCircumference, ChildSex.male, 0, 34.4618],
        [GrowthMetric.headCircumference, ChildSex.female, 0, 33.8787],
        [GrowthMetric.headCircumference, ChildSex.male, 12, 46.0661],
        [GrowthMetric.headCircumference, ChildSex.female, 12, 44.8965],
      ];

      for (final anchor in anchors) {
        final metric = anchor[0] as GrowthMetric;
        final sex = anchor[1] as ChildSex;
        final month = anchor[2] as int;
        final median = anchor[3] as double;

        final lms = WhoGrowthStandardsData.tableFor(metric, sex)![month]!;
        expect(lms.m, closeTo(median, 0.0001),
            reason: '$metric / $sex at $month months');
      }
    });

    test('changes over from length to height at two years', () {
      // WHO measures children lying down to 24 months and standing after, and
      // the two standards differ by about 0.7cm at the changeover. Using the
      // wrong one either side would put a step in every chart.
      final boys =
          WhoGrowthStandardsData.tableFor(GrowthMetric.height, ChildSex.male)!;
      expect(boys[23]!.m, closeTo(86.941, 0.001));
      expect(boys[24]!.m, closeTo(87.1161, 0.001));
    });

    test('rises monotonically — no transcription slips', () {
      for (final metric in GrowthMetric.values) {
        for (final sex in ChildSex.values) {
          final table = WhoGrowthStandardsData.tableFor(metric, sex)!;
          for (int month = 1; month <= 36; month++) {
            // Except at 24 months for height, where the standard itself steps
            // down by design.
            if (metric == GrowthMetric.height && month == 24) continue;
            expect(table[month]!.m, greaterThan(table[month - 1]!.m),
                reason: '$metric / $sex went backwards at month $month');
          }
        }
      }
    });
  });

  group('percentile curves', () {
    test('reproduce WHO\'s own published standard-deviation values', () {
      // The strongest check available: WHO publishes the measurement at each
      // whole standard deviation alongside the LMS parameters, so recomputing
      // those from L, M and S proves the arithmetic here, independently of the
      // table transcription — a slip in either shows up as a mismatch.
      double at(GrowthMetric metric, ChildSex sex, int month, double z) =>
          WhoGrowthStandards.valueAtZ(metric, sex, month.toDouble(), z)!;

      // Boys, weight-for-age at 12 months (kg).
      expect(
          at(GrowthMetric.weight, ChildSex.male, 12, -3), closeTo(6.9, 0.05));
      expect(
          at(GrowthMetric.weight, ChildSex.male, 12, -2), closeTo(7.7, 0.05));
      expect(at(GrowthMetric.weight, ChildSex.male, 12, 0), closeTo(9.6, 0.05));
      expect(
          at(GrowthMetric.weight, ChildSex.male, 12, 2), closeTo(12.0, 0.05));
      expect(
          at(GrowthMetric.weight, ChildSex.male, 12, 3), closeTo(13.3, 0.05));

      // Girls, height-for-age at 24 months (cm).
      expect(at(GrowthMetric.height, ChildSex.female, 24, -2),
          closeTo(79.3, 0.05));
      expect(
          at(GrowthMetric.height, ChildSex.female, 24, 0), closeTo(85.7, 0.05));
      expect(
          at(GrowthMetric.height, ChildSex.female, 24, 2), closeTo(92.2, 0.05));

      // Girls, head-circumference-for-age at 6 months (cm).
      expect(at(GrowthMetric.headCircumference, ChildSex.female, 6, -2),
          closeTo(39.6, 0.05));
      expect(at(GrowthMetric.headCircumference, ChildSex.female, 6, 0),
          closeTo(42.2, 0.05));
      expect(at(GrowthMetric.headCircumference, ChildSex.female, 6, 2),
          closeTo(44.8, 0.05));
    });

    test('put the published SD values at the percentiles they belong to', () {
      // -2 SD is the 2.3rd percentile, not the 3rd: a chart that labelled the
      // -2 SD line "3rd percentile" would be off by a whole line.
      final sd2neg = WhoGrowthStandards.percentile(
          GrowthMetric.weight, ChildSex.male, 12, 7.7)!;
      final median = WhoGrowthStandards.percentile(
          GrowthMetric.weight, ChildSex.male, 12, 9.6479)!;

      expect(sd2neg, closeTo(2.3, 0.3));
      expect(median, closeTo(50, 0.5));
    });

    test('are ordered, at every age and for every metric', () {
      for (final metric in GrowthMetric.values) {
        for (final sex in ChildSex.values) {
          for (int month = 0; month <= 36; month++) {
            double? previous;
            for (final p in WhoGrowthStandards.curvePercentiles) {
              final value = WhoGrowthStandards.valueAtZ(metric, sex,
                  month.toDouble(), WhoGrowthStandards.zForPercentile(p))!;
              if (previous != null) {
                expect(value, greaterThan(previous),
                    reason: '$metric / $sex at $month months, P$p');
              }
              previous = value;
            }
          }
        }
      }
    });
  });

  group('a child\'s own percentile', () {
    test('puts the median at the 50th', () {
      final median = WhoGrowthStandards.valueAtZ(
          GrowthMetric.weight, ChildSex.female, 6, 0)!;

      final p = WhoGrowthStandards.percentile(
          GrowthMetric.weight, ChildSex.female, 6, median)!;

      expect(p, closeTo(50, 0.5));
    });

    test('round-trips against the curve values', () {
      for (final target in WhoGrowthStandards.curvePercentiles) {
        final value = WhoGrowthStandards.valueAtZ(GrowthMetric.weight,
            ChildSex.male, 18, WhoGrowthStandards.zForPercentile(target))!;

        expect(
            WhoGrowthStandards.percentile(
                GrowthMetric.weight, ChildSex.male, 18, value)!,
            closeTo(target.toDouble(), 0.5));
      }
    });

    test('keeps a very small baby on a plausible scale', () {
      // Below -3 SD the fitted curve stops describing real children, so WHO
      // measures the remaining distance in units of the outer SD interval.
      // Without that correction this runs away to an absurd z.
      final z = WhoGrowthStandards.zScore(
          GrowthMetric.weight, ChildSex.male, 12, 5.0)!;

      expect(z, lessThan(-3));
      expect(z, greaterThan(-8));
    });

    test('interpolates between the published months', () {
      final at12 = WhoGrowthStandards.valueAtZ(
          GrowthMetric.weight, ChildSex.male, 12, 0)!;
      final at13 = WhoGrowthStandards.valueAtZ(
          GrowthMetric.weight, ChildSex.male, 13, 0)!;
      final halfway = WhoGrowthStandards.valueAtZ(
          GrowthMetric.weight, ChildSex.male, 12.5, 0)!;

      // A chart that snapped to whole months would step; this must not.
      expect(halfway, greaterThan(at12));
      expect(halfway, lessThan(at13));
    });
  });

  group('when there is no honest answer, it gives none', () {
    final profile = ChildProfile(
      name: 'Emma',
      dateOfBirth: DateTime(2025, 1, 1),
      sex: ChildSex.female,
      createdAt: DateTime(2025, 1, 1),
    );

    test('past the end of the tables', () {
      expect(WhoGrowthStandards.lmsAt(GrowthMetric.weight, ChildSex.male, 40),
          isNull);
      expect(
          WhoGrowthStandards.valueAtZ(
              GrowthMetric.weight, ChildSex.male, 40, 0),
          isNull);
    });

    test('before birth', () {
      expect(WhoGrowthStandards.lmsAt(GrowthMetric.weight, ChildSex.male, -1),
          isNull);
    });

    test('with no sex recorded', () {
      final unknown = profile.copyWith(clearSex: true);

      expect(WhoGrowthStandards.isSupported(GrowthMetric.weight, unknown.sex),
          isFalse);
      expect(
        WhoGrowthStandards.summaryFor(
          profile: unknown,
          metric: GrowthMetric.weight,
          value: 8.0,
          measuredOn: DateTime(2025, 7, 1),
        ),
        isNull,
      );
    });

    test('with a nonsensical measurement', () {
      expect(
          WhoGrowthStandards.zScore(GrowthMetric.weight, ChildSex.male, 12, 0),
          isNull);
      expect(
          WhoGrowthStandards.zScore(GrowthMetric.weight, ChildSex.male, 12, -3),
          isNull);
    });
  });

  group('age at a measurement', () {
    test('is counted from the birth date for a term baby', () {
      final profile = ChildProfile(
        name: 'Emma',
        dateOfBirth: DateTime(2025, 1, 1),
        sex: ChildSex.female,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(WhoGrowthStandards.ageMonthsAt(profile, DateTime(2025, 7, 1)),
          closeTo(5.95, 0.05));
    });

    test('is corrected for a baby born early', () {
      // The WHO curves describe babies born at term. Plotting a baby born ten
      // weeks early by their birth date would put a normally growing child at
      // the bottom of every chart.
      final preemie = ChildProfile(
        name: 'Noah',
        dateOfBirth: DateTime(2025, 1, 1),
        dueDate: DateTime(2025, 3, 12),
        sex: ChildSex.male,
        createdAt: DateTime(2025, 1, 1),
      );

      final corrected =
          WhoGrowthStandards.ageMonthsAt(preemie, DateTime(2025, 7, 1));
      expect(corrected, closeTo(3.6, 0.1));
    });

    test('never goes negative', () {
      final profile = ChildProfile(
        name: 'Emma',
        dateOfBirth: DateTime(2025, 1, 1),
        sex: ChildSex.female,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(WhoGrowthStandards.ageMonthsAt(profile, DateTime(2024, 12, 1)), 0);
    });
  });

  group('the sentence a parent reads', () {
    final profile = ChildProfile(
      name: 'Emma',
      dateOfBirth: DateTime(2025, 1, 1),
      sex: ChildSex.female,
      createdAt: DateTime(2025, 1, 1),
    );

    test('names the percentile and what it is compared against', () {
      final median = WhoGrowthStandards.valueAtZ(
          GrowthMetric.weight, ChildSex.female, 6, 0)!;

      final summary = WhoGrowthStandards.summaryFor(
        profile: profile,
        metric: GrowthMetric.weight,
        value: median,
        measuredOn: DateTime(2025, 7, 1),
      )!;

      expect(summary, contains('percentile'));
      expect(summary, contains('same age and sex'));
    });

    test('never grades the child', () {
      // A child at the 10th percentile who is following their own curve is
      // doing exactly what they should; wording that implies otherwise is the
      // one thing this feature must not do.
      const forbidden = [
        'above average',
        'below average',
        'underweight',
        'overweight',
        'healthy',
        'concern',
        'too small',
        'too big',
        'behind',
        'good',
        'poor',
      ];

      for (final z in [-2.5, -1.0, 0.0, 1.0, 2.5]) {
        final value = WhoGrowthStandards.valueAtZ(
            GrowthMetric.weight, ChildSex.female, 6, z)!;
        final summary = WhoGrowthStandards.summaryFor(
          profile: profile,
          metric: GrowthMetric.weight,
          value: value,
          measuredOn: DateTime(2025, 7, 1),
        )!;

        for (final word in forbidden) {
          expect(summary.toLowerCase(), isNot(contains(word)),
              reason: 'z=$z produced "$summary"');
        }
      }
    });

    test('never reports a 0th or 100th percentile', () {
      // Both are impossible readings of a continuous distribution, and both
      // would land far harder than they deserve.
      for (final z in [-6.0, 6.0]) {
        final value = WhoGrowthStandards.valueAtZ(
            GrowthMetric.height, ChildSex.female, 6, z)!;
        final summary = WhoGrowthStandards.summaryFor(
          profile: profile,
          metric: GrowthMetric.height,
          value: value,
          measuredOn: DateTime(2025, 7, 1),
        )!;

        expect(summary, isNot(contains('0th percentile')));
        expect(summary, isNot(contains('100th percentile')));
      }
    });

    test('uses the right ordinal suffix', () {
      final measuredOn = DateTime(2025, 7, 1);
      // The value has to be taken at the age the summary will use, not at a
      // round month: 1 July is 5.95 months after 1 January, and a curve read a
      // fortnight out shifts the percentile enough to change the word.
      final ageMonths = WhoGrowthStandards.ageMonthsAt(profile, measuredOn);

      String summaryAtPercentile(int p) => WhoGrowthStandards.summaryFor(
            profile: profile,
            metric: GrowthMetric.weight,
            value: WhoGrowthStandards.valueAtZ(
                GrowthMetric.weight,
                ChildSex.female,
                ageMonths,
                WhoGrowthStandards.zForPercentile(p))!,
            measuredOn: measuredOn,
          )!;

      expect(summaryAtPercentile(3), contains('3rd'));
      expect(summaryAtPercentile(15), contains('15th'));
      expect(summaryAtPercentile(50), contains('50th'));
    });
  });
}
