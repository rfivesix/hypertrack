// lib/features/statistics/domain/analytics_state.dart
//
// Defines the shared analytics state contract used across the statistics
// feature. All analytics datasets—whether loaded by the hub or individual
// drill-down screens—are classified using [AnalyticsStatus] so that loading,
// empty, insufficient-data, error, and ready states are handled uniformly.
//
// Phase: 1 — Foundations (parity-only, internal only).

/// Classifies the lifecycle status of an analytics dataset.
enum AnalyticsStatus {
  /// Data is being fetched or computed.
  loading,

  /// No data exists for the requested range or period.
  empty,

  /// Data exists but does not meet the minimum quality threshold
  /// required for reliable insight computation (e.g. too few data points
  /// or too short a span).
  insufficient,

  /// An unrecoverable error occurred while fetching or computing the data.
  error,

  /// Data is available and ready for display.
  ready,
}

/// A typed snapshot of an analytics result paired with a status
/// classification.
///
/// Generic parameter [T] is the payload type for the [ready] state.
/// In early phases [T] is typically `Map<String, dynamic>`; it is
/// progressively tightened to typed models in later phases.
///
/// Usage:
/// ```dart
/// AnalyticsState<MyData> state = AnalyticsState.loading();
/// // …after fetch:
/// state = AnalyticsState.ready(myData);
/// ```
class AnalyticsState<T> {
  /// A state indicating data is currently being loaded.
  const AnalyticsState.loading()
      : status = AnalyticsStatus.loading,
        data = null,
        errorMessage = null;

  /// A state indicating no data is available for the requested range.
  const AnalyticsState.empty()
      : status = AnalyticsStatus.empty,
        data = null,
        errorMessage = null;

  /// A state indicating data exists but quality is insufficient for
  /// meaningful insight computation.
  const AnalyticsState.insufficient()
      : status = AnalyticsStatus.insufficient,
        data = null,
        errorMessage = null;

  /// A state indicating an error occurred. An optional [message] may
  /// carry diagnostic context for logging or display.
  AnalyticsState.error([String? message])
      : status = AnalyticsStatus.error,
        data = null,
        errorMessage = message;

  /// A state indicating data is ready for display.
  AnalyticsState.ready(T value)
      : status = AnalyticsStatus.ready,
        data = value,
        errorMessage = null;

  /// The lifecycle status of this analytics result.
  final AnalyticsStatus status;

  /// The analytics payload. Non-null only when [status] is [AnalyticsStatus.ready].
  final T? data;

  /// An optional diagnostic message. Non-null only when [status] is
  /// [AnalyticsStatus.error].
  final String? errorMessage;

  /// Whether data is currently being loaded.
  bool get isLoading => status == AnalyticsStatus.loading;

  /// Whether no data is available for the requested range.
  bool get isEmpty => status == AnalyticsStatus.empty;

  /// Whether data exists but is insufficient for reliable insights.
  bool get isInsufficient => status == AnalyticsStatus.insufficient;

  /// Whether an error occurred.
  bool get isError => status == AnalyticsStatus.error;

  /// Whether data is available and ready for display.
  bool get isReady => status == AnalyticsStatus.ready;

  @override
  String toString() => 'AnalyticsState<$T>(status: $status)';
}
