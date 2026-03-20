// lib/features/statistics/data/statistics_data_adapter.dart
//
// Defines the data-adapter boundary for the statistics feature.
// Concrete adapters wrap database-helper calls and isolate persistence
// access from domain logic and screens.
//
// Phase: 1 — Foundations (structural stub; concrete implementations added
// in Phase 2 during domain and data-contract cleanup).

/// Marker interface for statistics data adapters.
///
/// Each adapter is responsible for fetching a single analytics dataset
/// from the underlying persistence layer and returning it in the shape
/// expected by its corresponding domain service or state container.
///
/// Concrete implementations (e.g. [RecoveryDataAdapter],
/// [ConsistencyDataAdapter]) are introduced in Phase 2.
abstract class StatisticsDataAdapter {}
