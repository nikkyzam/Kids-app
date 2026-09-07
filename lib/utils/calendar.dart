/// Whole calendar days from [from] to [to], ignoring the time of day.
///
/// Not `to.difference(from).inDays`: a Duration is elapsed time, and once a
/// timezone has moved on or off daylight saving between the two dates the
/// elapsed hours are one short of a whole number of days, so `inDays`
/// truncates to the day before. Building both endpoints in UTC — which has no
/// transitions — from their local calendar components makes the count exact.
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
