class RecommendationScheduler {
  const RecommendationScheduler._();

  static DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime dueWeekStart(DateTime now) {
    final day = normalizeDay(now);
    final offsetFromMonday = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: offsetFromMonday));
  }

  /// Stable input anchor for recommendation generation inside a due week.
  ///
  /// Weekly cadence is Monday-based, so each due week uses the previous
  /// Sunday's completed day as the rolling-window end.
  static DateTime stableWindowEndDayForDueWeek(DateTime now) {
    final dueStart = dueWeekStart(now);
    return normalizeDay(dueStart.subtract(const Duration(days: 1)));
  }

  static String dueWeekKeyFor(DateTime now) {
    final dueStart = dueWeekStart(now);
    final year = dueStart.year.toString().padLeft(4, '0');
    final month = dueStart.month.toString().padLeft(2, '0');
    final day = dueStart.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static bool shouldGenerateForWeek({
    required String dueWeekKey,
    required String? lastGeneratedDueWeekKey,
  }) {
    return dueWeekKey != lastGeneratedDueWeekKey;
  }
}
