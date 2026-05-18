# Train Libre Engineering Documentation

This directory contains the technical documentation for the Train Libre architecture, modules, and processes.

## Architecture & System
- **[System Architecture](../documentation/architecture.md)**
  Details the high-level layering, clean architecture boundaries, and execution flows within the app. Consult this when extending or adding a new feature module.
- **[Project Overview](../documentation/overview.md)**
  Provides a bird's-eye view of app capabilities, shell navigation, and module responsibilities. Read this for a general introduction to the repository.
- **[Data Models & Storage](../documentation/data_models_and_storage.md)**
  Explains the local persistence strategy, database schema rules, and Drift ORM implementations. Reference this when migrating tables or modifying core storage mechanisms.
- **[UI & Widgets](../documentation/ui_and_widgets.md)**
  Covers the app's design system, custom surface extensions, widget catalog, and interaction patterns. Consult this when building new interfaces to ensure visual consistency.

## Modules & Features
- **[Statistics Module](../documentation/statistics_module.md)**
  Outlines the data sources, range policies, and recovery heuristics driving the analytics views. Consult this when modifying chart logic or metric calculations.
- **[Sleep Module Current State](../documentation/sleep/sleep_current_state.md)**
  Describes the pipeline, platform ingestion, and aggregation mechanics of the sleep tracking module.
- **[Sleep Health Score V2](../documentation/sleep/sleep_health_score_v2.md)**
  Details the mathematical modeling behind the sleep scoring algorithm and pipeline phases.
- **[Adaptive Nutrition Recommendation](../documentation/adaptive_nutrition_recommendation_current_state.md)**
  Explains the Bayesian logic, adaptive estimation constraints, and recommendation flow for nutrition goals.
- **[AI Meal Features Architecture](../documentation/ai_meal_features_architecture.md)**
  Maps out the opt-in meal processing AI systems and their integration layers.
- **[Health Steps Integration](../documentation/health_steps.md)**
  Documents how health steps are aggregated, synchronized, and stored within the application.

## Synchronization & Integrations
- **[Wger Catalog Refresh & Distribution](../documentation/wger_catalog_refresh_system.md)**
  Describes the synchronization patterns for the exercise catalog derived from Wger base data.
- **[OFF Catalog Refresh System](../documentation/off_catalog_refresh_system.md)**
  Explains the background fetch and local merge processes for Open Food Facts catalogs.
- **[Health Export One-Way](../documentation/health_export_one_way.md)**
  Outlines the one-way background synchronization rules for external health metric platforms.
