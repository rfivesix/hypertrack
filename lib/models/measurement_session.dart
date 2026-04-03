// lib/models/measurement_session.dart
import 'measurement.dart';

/// Represents a group of body measurements taken at the same time.
///
/// A session acts as a container for multiple [Measurement] instances (e.g., weight and body fat).
class MeasurementSession {
  /// Unique identifier for the measurement session.
  final int? id;

  /// The exact time when the measurements were taken.
  final DateTime timestamp;

  /// The list of individual [Measurement] entries associated with this session.
  final List<Measurement> measurements; // Hält die Detailwerte

  /// Last modification timestamp of the newest member measurement when available.
  final DateTime? updatedAt;

  /// Creates a new [MeasurementSession] instance.
  MeasurementSession({
    this.id,
    required this.timestamp,
    this.measurements = const [],
    this.updatedAt,
  });
}
