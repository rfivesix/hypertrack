// lib/features/statistics/presentation/statistics_formatter.dart
//
// Defines the presentation-formatter boundary for the statistics feature.
// Formatters map typed analytics results to display-ready labels, units,
// and status text consumed by widgets and screens.
//
// Phase: 1 — Foundations (structural stub; concrete implementations added
// in Phase 4 during chart and presentation standardization).

/// Marker interface for statistics presentation formatters.
///
/// Each formatter takes a typed analytics result and produces
/// display-ready strings, colors, or other presentation values.
///
/// Concrete implementations (e.g. [RecoveryFormatter],
/// [ConsistencyFormatter]) are introduced in Phase 4.
abstract class StatisticsFormatter {}
