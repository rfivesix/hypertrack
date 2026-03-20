// lib/features/statistics/statistics_state_container.dart
//
// Shared state container for the statistics feature.
//
// Provides a single snapshot-oriented load path intended for hub
// composition and drill-down reuse. In Phase 1 this is a wiring skeleton
// that defines the public surface and dependency shape; concrete data
// population and ChangeNotifier integration are wired up in Phase 2.
//
// Phase: 1 — Foundations (parity-only, internal only).

import 'domain/analytics_state.dart';

/// Shared state container for statistics hub and drill-down screens.
///
/// Each property exposes an [AnalyticsState] snapshot for one analytics
/// domain. The hub composes these snapshots for its summary cards;
/// drill-down screens can re-use the same snapshots to avoid redundant
/// fetches.
///
/// In Phase 1 all snapshots are initialised to [AnalyticsState.loading].
/// Phase 2 wires up concrete data adapters and a refresh path.
class StatisticsStateContainer {
  /// Snapshot for personal-record momentum analytics.
  ///
  /// Populated by the PR dashboard data path in Phase 2.
  AnalyticsState<Map<String, dynamic>> prSnapshot =
      const AnalyticsState.loading();

  /// Snapshot for workout consistency and streak analytics.
  ///
  /// Populated by the consistency tracker data path in Phase 2.
  AnalyticsState<Map<String, dynamic>> consistencySnapshot =
      const AnalyticsState.loading();

  /// Snapshot for muscle-group volume and distribution analytics.
  ///
  /// Populated by the muscle analytics data path in Phase 2.
  AnalyticsState<Map<String, dynamic>> muscleSnapshot =
      const AnalyticsState.loading();

  /// Snapshot for recovery readiness analytics.
  ///
  /// Populated by the recovery tracker data path in Phase 2.
  AnalyticsState<Map<String, dynamic>> recoverySnapshot =
      const AnalyticsState.loading();

  /// Snapshot for body-weight / nutrition correlation analytics.
  ///
  /// Populated by the body–nutrition data path in Phase 2.
  AnalyticsState<Map<String, dynamic>> bodyNutritionSnapshot =
      const AnalyticsState.loading();

  /// Resets all snapshots to [AnalyticsState.loading].
  ///
  /// Called at the start of a full hub refresh so each consumer can
  /// show a loading indicator while data is being fetched.
  void resetAll() {
    prSnapshot = const AnalyticsState.loading();
    consistencySnapshot = const AnalyticsState.loading();
    muscleSnapshot = const AnalyticsState.loading();
    recoverySnapshot = const AnalyticsState.loading();
    bodyNutritionSnapshot = const AnalyticsState.loading();
  }
}
