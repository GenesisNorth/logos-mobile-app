/// Injectable time source so pace-lock and streak rules are testable.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// Test/debug clock that can be moved forward manually.
class FixedClock implements Clock {
  DateTime current;
  FixedClock(this.current);
  @override
  DateTime now() => current;
  void advance(Duration d) => current = current.add(d);
}

/// Date helpers in the user's local timezone.
extension LocalDate on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  /// Local midnight that begins the next calendar day.
  DateTime get nextMidnight => DateTime(year, month, day + 1);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Whole calendar days from [other] to this (DST-safe).
  int calendarDaysSince(DateTime other) {
    final a = DateTime.utc(year, month, day);
    final b = DateTime.utc(other.year, other.month, other.day);
    return a.difference(b).inDays;
  }
}
