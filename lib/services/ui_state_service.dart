// lib/services/ui_state_service.dart

/// Service for maintaining transient UI state that doesn't belong in other services.
///
/// Uses a singleton pattern to provide a single source of truth for UI preferences.
class UiStateService {
  /// Singleton instance of [UiStateService].
  static final UiStateService instance = UiStateService._internal();

  // Privater Konstruktor
  UiStateService._internal();

  /// Whether the nutrition summary on the home screen is expanded.
  bool isNutritionSummaryExpanded = true; // Enabled by default, as requested
}
