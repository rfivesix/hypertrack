// lib/util/date_util.dart

/// Extension providing date-only comparison for [DateTime] objects.
extension DateOnlyCompare on DateTime {
  /// Returns this value stripped to the local calendar date.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns true if this [DateTime] falls on the same calendar day as [other].
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns a [DateTime] based on this instance (date component) but
  /// using the current hour/minute. If it's today, it returns [DateTime.now()].
  DateTime get withCurrentTime {
    final now = DateTime.now();
    if (isSameDate(now)) {
      return now;
    }
    return DateTime(year, month, day, now.hour, now.minute);
  }
}
