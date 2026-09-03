import 'dart:math' as math;

import '../data/who_growth_standards_data.dart';
import '../models/child_profile.dart';
import '../models/growth_measurement.dart';

/// Where a measurement sits against the WHO Child Growth Standards.
///
/// This exists to answer the question every parent asks and no chart of raw
/// numbers can — "is this normal?" — with the honest version of the answer:
/// here is the range most children fall in, and here is where yours is in it.
/// It is a comparison, not an assessment, and the screen that shows it says so
/// every time.
class WhoGrowthStandards {
  WhoGrowthStandards._();

  /// The average length of a month, used to turn an age in days into the
  /// fractional month the tables are indexed by.
  static const double _daysPerMonth = 30.4375;

  /// The percentile curves the chart draws. The 3rd and 97th are the outer
  /// pair WHO's own charts use; the 15th and 85th give the middle of the range
  /// some shape without crowding the plot.
  static const List<int> curvePercentiles = [3, 15, 50, 85, 97];

  static bool isSupported(GrowthMetric metric, ChildSex? sex) =>
      sex != null && WhoGrowthStandardsData.tableFor(metric, sex) != null;

  /// Interpolates the LMS parameters at a fractional age in months.
  ///
  /// The published tables are one row per completed month. Snapping to the
  /// nearest row would make a chart step; interpolating between the two
  /// neighbouring rows keeps the curve smooth, which is what a parent reads it
  /// as. Beyond the table's range there is nothing to interpolate towards, so
  /// it returns null rather than extrapolating a curve WHO never published.
  static WhoLms? lmsAt(GrowthMetric metric, ChildSex sex, double ageMonths) {
    final table = WhoGrowthStandardsData.tableFor(metric, sex);
    if (table == null) return null;
    if (ageMonths < 0 || ageMonths > WhoGrowthStandardsData.maxAgeMonths) {
      return null;
    }

    final lower = ageMonths.floor();
    final upper = ageMonths.ceil();
    final a = table[lower];
    final b = table[upper];
    if (a == null || b == null) return null;
    if (lower == upper) return a;

    final t = ageMonths - lower;
    return WhoLms(
      a.l + (b.l - a.l) * t,
      a.m + (b.m - a.m) * t,
      a.s + (b.s - a.s) * t,
    );
  }

  /// The measurement at a given z-score — the inverse of [zScore], and what
  /// the chart's curves are drawn from.
  static double? valueAtZ(
    GrowthMetric metric,
    ChildSex sex,
    double ageMonths,
    double z,
  ) {
    final lms = lmsAt(metric, sex, ageMonths);
    if (lms == null) return null;
    return _valueAtZ(lms, z);
  }

  static double _valueAtZ(WhoLms lms, double z) {
    // L is the Box-Cox power. At L = 0 the distribution is lognormal and the
    // general form divides by zero, so that case is handled separately.
    if (lms.l.abs() < 1e-7) return lms.m * math.exp(lms.s * z);
    return lms.m * math.pow(1 + lms.l * lms.s * z, 1 / lms.l).toDouble();
  }

  /// How many standard deviations [value] sits from the median for a child of
  /// this sex and age.
  static double? zScore(
    GrowthMetric metric,
    ChildSex sex,
    double ageMonths,
    double value,
  ) {
    final lms = lmsAt(metric, sex, ageMonths);
    if (lms == null || value <= 0) return null;

    final double z;
    if (lms.l.abs() < 1e-7) {
      z = math.log(value / lms.m) / lms.s;
    } else {
      z = (math.pow(value / lms.m, lms.l).toDouble() - 1) / (lms.l * lms.s);
    }

    if (z.abs() <= 3 || !_usesTailCorrection(metric)) return z;

    // WHO's own correction for the extreme tails of the weight-based
    // indicators: past ±3 SD the fitted curve stops describing real children,
    // so the distance is measured in units of the outermost SD interval
    // instead. Without it, a genuinely small baby's z-score runs away to
    // implausible numbers.
    if (z > 3) {
      final sd3 = _valueAtZ(lms, 3);
      final sd2 = _valueAtZ(lms, 2);
      final interval = sd3 - sd2;
      if (interval <= 0) return z;
      return 3 + (value - sd3) / interval;
    }
    final sd3neg = _valueAtZ(lms, -3);
    final sd2neg = _valueAtZ(lms, -2);
    final interval = sd2neg - sd3neg;
    if (interval <= 0) return z;
    return -3 + (value - sd3neg) / interval;
  }

  /// WHO applies the tail correction to weight-based indicators only; the
  /// length, height and head-circumference standards are used as fitted all
  /// the way out.
  static bool _usesTailCorrection(GrowthMetric metric) =>
      metric == GrowthMetric.weight;

  /// The percentile (0–100) a measurement falls at.
  static double? percentile(
    GrowthMetric metric,
    ChildSex sex,
    double ageMonths,
    double value,
  ) {
    final z = zScore(metric, sex, ageMonths, value);
    if (z == null) return null;
    return _normalCdf(z) * 100;
  }

  /// The age in fractional months a child was on [date], corrected for a baby
  /// born early.
  ///
  /// Corrected age is the convention for plotting a preemie against these
  /// standards: the WHO curves describe children born at term, so comparing a
  /// baby born ten weeks early by their birth date would place a normally
  /// growing child near the bottom of every chart.
  static double ageMonthsAt(ChildProfile profile, DateTime date) {
    final from = profile.usesAdjustedAgeOn(date)
        ? profile.dueDate!
        : profile.dateOfBirth;
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(from.year, from.month, from.day))
        .inDays;
    if (days <= 0) return 0;
    return days / _daysPerMonth;
  }

  /// A short, plain sentence for a measurement — or null when there is no
  /// honest one to give (no sex recorded, or an age outside the tables).
  static String? summaryFor({
    required ChildProfile profile,
    required GrowthMetric metric,
    required double value,
    required DateTime measuredOn,
  }) {
    final sex = profile.sex;
    if (sex == null) return null;
    final months = ageMonthsAt(profile, measuredOn);
    final p = percentile(metric, sex, months, value);
    if (p == null) return null;

    final rounded = p.round().clamp(1, 99);
    // Deliberately flat wording. "Above average" invites a reading of good and
    // bad where there is none: a child at the 10th percentile who is following
    // their own curve is doing exactly what they should.
    return '${_ordinal(rounded)} percentile for ${_metricNoun(metric)} '
        'among children the same age and sex.';
  }

  static String _metricNoun(GrowthMetric metric) {
    switch (metric) {
      case GrowthMetric.weight:
        return 'weight';
      case GrowthMetric.height:
        return 'length';
      case GrowthMetric.headCircumference:
        return 'head circumference';
    }
  }

  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  /// The z-score a percentile corresponds to, for drawing the curves.
  static double zForPercentile(int percentile) {
    switch (percentile) {
      case 3:
        return -1.88079;
      case 15:
        return -1.03643;
      case 50:
        return 0;
      case 85:
        return 1.03643;
      case 97:
        return 1.88079;
      default:
        return _inverseNormalCdf(percentile / 100);
    }
  }

  /// The standard normal cumulative distribution, via the error function.
  ///
  /// Abramowitz & Stegun 7.1.26 — accurate to about 1.5e-7, which is far
  /// finer than a percentile the app then rounds to a whole number.
  static double _normalCdf(double z) {
    final x = z / math.sqrt2;
    final sign = x < 0 ? -1.0 : 1.0;
    final ax = x.abs();

    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final t = 1 / (1 + p * ax);
    final y = 1 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
            t *
            math.exp(-ax * ax);
    return 0.5 * (1 + sign * y);
  }

  /// The inverse of [_normalCdf], for percentiles the table above does not
  /// name. Acklam's rational approximation, good to about 1.15e-9.
  static double _inverseNormalCdf(double p) {
    if (p <= 0) return double.negativeInfinity;
    if (p >= 1) return double.infinity;

    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00,
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01,
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00,
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00,
    ];
    const pLow = 0.02425;
    const pHigh = 1 - pLow;

    if (p < pLow) {
      final q = math.sqrt(-2 * math.log(p));
      return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    if (p > pHigh) {
      final q = math.sqrt(-2 * math.log(1 - p));
      return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    final q = p - 0.5;
    final r = q * q;
    return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r +
            a[5]) *
        q /
        (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  }
}
