import '../utils/clock.dart';

/// Biological sex, recorded only because the WHO growth standards are
/// sex-specific. It is optional: leaving it unset simply hides the percentile
/// overlay rather than blocking growth tracking.
enum ChildSex {
  female,
  male;

  String get label => this == ChildSex.female ? 'Girl' : 'Boy';
}

class ChildProfile {
  final int? id;
  final String? uuid;
  final String name;
  final DateTime dateOfBirth;

  /// The date the child was originally due, recorded only for babies born
  /// early. Null for a term birth — the overwhelmingly common case — so the
  /// whole adjusted-age path stays invisible unless a parent opts into it.
  final DateTime? dueDate;

  final ChildSex? sex;
  final DateTime createdAt;

  const ChildProfile({
    this.id,
    this.uuid,
    required this.name,
    required this.dateOfBirth,
    this.dueDate,
    this.sex,
    required this.createdAt,
  });

  int get ageInDays => Clock.now().difference(dateOfBirth).inDays;

  int get ageInWeeks => ageInDays ~/ 7;

  int get ageInMonths {
    final now = Clock.now();
    int months =
        (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (now.day < dateOfBirth.day) months--;
    return months.clamp(0, 999);
  }

  // ─── Adjusted (corrected) age ─────────────────────────────────────────────

  /// How many days early the baby arrived. Zero when no due date was given, or
  /// when the due date is on or before the birth date (a baby born late is not
  /// corrected — correction only ever removes prematurity, never adds it).
  ///
  /// Capped at 119 days (17 weeks): a birth more than four months before the
  /// due date is not survivable, so a larger gap is a typo or a corrupt synced
  /// row, and letting it through would push a toddler back into newborn
  /// content.
  int get prematureDays {
    final due = dueDate;
    if (due == null) return 0;
    final days = due.difference(dateOfBirth).inDays;
    if (days <= 0) return 0;
    return days > 119 ? 119 : days;
  }

  bool get wasBornEarly => prematureDays > 0;

  /// Correction is conventionally dropped once a child reaches two years, by
  /// which point the difference has washed out.
  static const int adjustmentEndsAtMonths = 24;

  bool get usesAdjustedAge =>
      wasBornEarly && ageInMonths < adjustmentEndsAtMonths;

  int get adjustedAgeInDays {
    final days = ageInDays - (usesAdjustedAge ? prematureDays : 0);
    return days < 0 ? 0 : days;
  }

  int get adjustedAgeInWeeks => adjustedAgeInDays ~/ 7;

  int get adjustedAgeInMonths {
    if (!usesAdjustedAge) return ageInMonths;
    final now = Clock.now();
    // Walk the calendar from the due date rather than subtracting days, so a
    // "month" stays a calendar month.
    final from = dueDate!;
    int months = (now.year - from.year) * 12 + now.month - from.month;
    if (now.day < from.day) months--;
    return months.clamp(0, 999);
  }

  static String _format(int weeks, int months) {
    final w = weeks < 0 ? 0 : weeks;
    if (w < 4) return '$w week${w == 1 ? '' : 's'}';
    if (w < 26) return '$w weeks';
    final m = months;
    if (m < 24) return '$m month${m == 1 ? '' : 's'}';
    final years = m ~/ 12;
    final rem = m % 12;
    if (rem == 0) return '$years yr';
    return '$years yr $rem mo';
  }

  // Returns age in weeks (0–26 weeks) then months (6–36+ months)
  String get displayAge {
    // Floored at zero: a date of birth in the future (from a restored backup
    // or a synced record written by a device with a wrong clock) would
    // otherwise render as "-10 weeks".
    return _format(ageInWeeks, ageInMonths);
  }

  /// The corrected age, shown alongside — never instead of — [displayAge] so a
  /// parent can always see both numbers.
  String get adjustedDisplayAge =>
      _format(adjustedAgeInWeeks, adjustedAgeInMonths);

  /// Chronological age, with the corrected age appended for a baby born
  /// early. Both numbers are always shown together: the chronological age is
  /// the one on the birth certificate, and hiding it would be its own kind of
  /// wrong.
  String get ageSummary => usesAdjustedAge
      ? '$displayAge · $adjustedDisplayAge adjusted'
      : displayAge;

  // Age in whole weeks capped at 156 weeks (3 years)
  int get ageBandWeeks => ageInWeeks.clamp(0, 156);

  /// The age the daily activity and the milestone ledger are matched against.
  /// For a baby born early this is the corrected age, so a 10-week-old born
  /// six weeks early gets four-week content rather than content they have no
  /// chance of engaging with.
  int get contentAgeBandWeeks => adjustedAgeInWeeks.clamp(0, 156);

  /// The age in whole weeks used for content matching, uncapped.
  int get contentAgeInWeeks => adjustedAgeInWeeks;

  /// The age in whole weeks used for content matching, as it was on [day].
  /// Looking back at a past day has to use the age the child was then, or a
  /// three-month-old's history would be re-rendered as newborn content.
  int contentAgeInWeeksOn(DateTime day) {
    final from = usesAdjustedAgeOn(day) ? dueDate! : dateOfBirth;
    final days = DateTime(day.year, day.month, day.day)
        .difference(DateTime(from.year, from.month, from.day))
        .inDays;
    return days < 0 ? 0 : days ~/ 7;
  }

  bool usesAdjustedAgeOn(DateTime day) {
    if (!wasBornEarly) return false;
    int months =
        (day.year - dateOfBirth.year) * 12 + day.month - dateOfBirth.month;
    if (day.day < dateOfBirth.day) months--;
    return months < adjustmentEndsAtMonths;
  }

  /// The age in whole months used for content matching — the milestone ledger
  /// and the red-flag prompts. The CDC's own guidance is to use corrected age
  /// for a baby born early, so a preemie is never told they are behind on a
  /// milestone they have not had the weeks to reach.
  int get contentAgeInMonths => adjustedAgeInMonths;

  ChildProfile copyWith({
    int? id,
    String? uuid,
    String? name,
    DateTime? dateOfBirth,
    DateTime? dueDate,
    bool clearDueDate = false,
    ChildSex? sex,
    bool clearSex = false,
  }) =>
      ChildProfile(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        sex: clearSex ? null : (sex ?? this.sex),
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'sex': sex?.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChildProfile.fromMap(Map<String, dynamic> map) => ChildProfile(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        name: map['name'] as String,
        dateOfBirth: DateTime.parse(map['date_of_birth'] as String),
        dueDate: _parseDate(map['due_date']),
        sex: _parseSex(map['sex']),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    // A malformed date from a restored backup or a synced row must not take
    // the whole profile down with it — the child simply reads as term-born.
    return DateTime.tryParse(raw);
  }

  static ChildSex? _parseSex(Object? raw) {
    if (raw is! String) return null;
    for (final value in ChildSex.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}
