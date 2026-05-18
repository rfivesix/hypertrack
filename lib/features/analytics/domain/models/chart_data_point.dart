// lib/models/chart_data_point.dart

/// Represents a single data point in a chart or graph.
///
/// Links a [date] to a numeric [value] (e.g., body weight over time).
class ChartDataPoint {
  /// The date when the data was recorded.
  final DateTime date;

  /// The numeric value at that specific date.
  final double value;

  /// Creates a new [ChartDataPoint] instance.
  ChartDataPoint({required this.date, required this.value});
}
