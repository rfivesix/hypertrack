# System Architecture

This document describes the technical structure, design patterns, and directory layout of the Hypertrack application.

---

## 📖 Table of Contents

- [Layered Architecture](#layered-architecture)
- [Directory Structure](#directory-structure)
- [Navigation Flow](#navigation-flow)
- [State Management](#state-management)
- [Localization](#localization)
- [Technical Stack](#technical-stack)

---

## Layered Architecture

Hypertrack follows a layered architecture to enforce separation of concerns:

```
┌────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                        │
│          lib/screens/  ·  lib/widgets/  ·  lib/dialogs/       │
├────────────────────────────────────────────────────────────────┤
│                 FEATURE DOMAIN/PRESENTATION                    │
│                    lib/features/<feature>/                     │
├────────────────────────────────────────────────────────────────┤
│                     LOGIC & SERVICES LAYER                     │
│                    lib/services/  ·  lib/util/                │
├────────────────────────────────────────────────────────────────┤
│                           DATA LAYER                           │
│                     lib/models/  ·  lib/data/                 │
└────────────────────────────────────────────────────────────────┘
```

### 1. Presentation Layer

Responsible for all user-facing elements.

| Directory | Contents | Examples |
| :--- | :--- | :--- |
| `lib/screens/` | Full-page route widgets (42 files) | `home.dart`, `live_workout_screen.dart` |
| `lib/widgets/` | Reusable atomic components (26 files) | `SummaryCard`, `GlassFab`, `GlobalAppBar` |
| `lib/dialogs/` | Modal/bottom-sheet content (5 files) | `FluidDialogContent`, `QuantityDialogContent` |

*See [UI & Widgets](ui_and_widgets.md) for a complete widget catalog.*

### 2. Logic & Services Layer

Encapsulates business logic, state management, and utility functions.

| File | Responsibility |
| :--- | :--- |
| `services/workout_session_manager.dart` | Manages the state of an active workout session (current exercise, timer, set progression). |
| `services/profile_service.dart` | Manages user profile data and avatar images. |
| `services/theme_service.dart` | Handles theme mode persistence and switching. |
| `services/ui_state_service.dart` | Lightweight in-memory state for UI preferences (e.g., section collapse states). |
| `services/db_service.dart` | Provides a centralized database access point. |
| `util/design_constants.dart` | Global spacing, border radius, and padding tokens. |
| `util/date_util.dart` | Date comparison helpers (e.g., `isSameDate`). |
| `util/time_util.dart` | Duration formatting for workout timers. |
| `util/encryption_util.dart` | AES encryption/decryption for backup files. |
| `util/mapping_prefs.dart` | Persistent exercise name mapping storage. |
| `util/supplement_l10n.dart` | Localized supplement name resolution. |
| `util/l10n_ext.dart` | Localization helper extensions. |
| `util/util_convert.dart` | Unit conversion utilities. |

### 3. Data Layer

Handles persistence, serialization, and external data operations.

| File | Responsibility |
| :--- | :--- |
| `data/database_helper.dart` | Primary SQLite manager for nutrition, supplements, measurements, settings, and fluids. |
| `data/workout_database_helper.dart` | SQLite manager for exercises, routines, workout logs, and set logs. |
| `data/product_database_helper.dart` | High-volume product/food catalog storage. |
| `data/backup_manager.dart` | Full JSON backup/restore, encrypted export, CSV export, and auto-backup scheduling. |
| `data/import_manager.dart` | Hevy CSV parsing and workout data import. |
| `data/basis_data_manager.dart` | Seed data initialization (default exercises, supplements, etc.). |
| `data/base_db_exporter.dart` | Abstract base for database export implementations. |
| `data/drift_database.dart` | Drift ORM setup (future migration target). |

*See [Data Models & Storage](data_models_and_storage.md) for entity details.*

### 4. Feature Modules

Feature modules are used where a domain has enough complexity to benefit from local domain/data/presentation contracts.

| Module | Path | Responsibility |
| :--- | :--- | :--- |
| `statistics` | `lib/features/statistics/` | Statistics-specific range policy, data-quality policy, typed payload models, data adapters, and shared formatting contracts |

The Statistics module currently includes:

- `domain/` — `statistics_range_policy.dart`, `statistics_data_quality_policy.dart`, payload models, domain services
- `data/` — `statistics_hub_data_adapter.dart`, `body_nutrition_analytics_data_adapter.dart`
- `presentation/` — `statistics_formatter.dart`

---

## Directory Structure

```
lib/
├── config/                  # Feature flags and dev configuration
│   └── dev_flags.dart
├── data/                    # Database helpers, backup, and import managers
│   ├── database_helper.dart
│   ├── workout_database_helper.dart
│   ├── product_database_helper.dart
│   ├── backup_manager.dart
│   ├── import_manager.dart
│   ├── basis_data_manager.dart
│   ├── base_db_exporter.dart
│   └── drift_database.dart  # Future: Drift ORM
├── dialogs/                 # Modal/bottom-sheet content widgets
│   ├── fluid_dialog_content.dart
│   ├── log_supplement_dialog_content.dart
│   ├── log_supplement_menu.dart
│   ├── quantity_dialog_content.dart
│   └── water_dialog_content.dart
├── generated/               # Auto-generated files (localization)
├── l10n/                    # Localization source files
│   ├── app_de.arb           # German translations
│   └── app_en.arb           # English translations
├── models/                  # Data entity definitions (20 files)
├── screens/                 # Full-page route widgets (42 files)
├── services/                # Application services (6 files)
│   └── ai_service.dart      # Multi-provider AI service (OpenAI + Gemini)
├── theme/                   # Custom theme extensions
│   ├── app_colors.dart      # AppSurfaces ThemeExtension
│   └── color_constants.dart # Light/dark mode color tokens
├── util/                    # Utility functions and constants (8 files)
├── widgets/                 # Reusable UI components (26 files)
└── main.dart                # Application entry point
```

---

## Navigation Flow

The application uses Flutter's imperative `Navigator` API with `MaterialPageRoute`:

```
main.dart (MaterialApp / ChangeNotifierProvider)
└── AppInitializerScreen
    ├── [First launch] → OnboardingScreen → MainScreen
    └── [Returning]    → MainScreen
                          ├── PageView (5 tabs)
                          │   ├── DiaryScreen
                          │   ├── WorkoutHubScreen
                          │   ├── Home
                          │   ├── StatisticsHubScreen
                          │   └── NutritionHubScreen
                          ├── GlassFab (Quick Actions)
                          │   ├── → AddFoodScreen
                          │   ├── → AiMealCaptureScreen (NEW)
                          │   ├── → ScannerScreen
                          │   └── → LogSupplementMenu
                          └── RunningWorkoutBar (overlay)
                              └── → LiveWorkoutScreen
```

Key navigation patterns:
- **Push & Return:** Most screens push new routes and await results (e.g., selecting a food item returns quantity data).
- **Data Refresh:** Parent screens use `.then((_) => _refresh())` after returning from child screens.
- **Result Passing:** Screens like `ExerciseCatalogScreen` support a `selectionMode` parameter to return selected exercises to the caller.

---

## State Management

Hypertrack uses a pragmatic mix of state management approaches:

| Approach | Where Used |
| :--- | :--- |
| `ChangeNotifierProvider` | `ThemeService` (global theme mode), `WorkoutSessionManager` (active workout state) |
| `StatefulWidget` | All screens for local page state (loading, form inputs, data) |
| `StatefulBuilder` | Inline state for dialogs and bottom sheets |
| `SharedPreferences` | Simple key-value flags (auto-backup path, extra nutrient targets) |

---

## Localization

The app supports **German** and **English** using Flutter's `flutter_localizations` package:

- Source files: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`
- Generated code: `lib/generated/app_localizations.dart`
- Access pattern: `AppLocalizations.of(context)!.keyName`
- Parameterized strings use ICU format: `'hevyImportSuccess': '{count} workouts imported.'`

---

## Technical Stack

| Component | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) |
| **Language** | Dart |
| **Local Database** | [SQLite](https://sqlite.org) via [Drift](https://drift.simonbinder.eu/) ORM |
| **State Management** | `Provider` + `StatefulWidget` |
| **Localization** | `flutter_localizations` (ARB files) |
| **AI Integration** | `speech_to_text`, REST APIs (OpenAI, Gemini) |
| **Secure Storage** | `flutter_secure_storage` (API keys) |
| **Charts** | `fl_chart` |
| **Calendar** | `table_calendar` |
| **Barcode Scanning** | `mobile_scanner` |
| **File Handling** | `file_picker`, `path_provider`, `share_plus` |
| **Local Settings** | `shared_preferences` |
| **Encryption** | `encrypt` (AES) |

---

## Security & Trust Boundaries

Hypertrack is designed with a strong offline-first security posture. 

1. **API Keys (BYOK):** Keys required for the AI Meal Capture feature (OpenAI / Gemini) are encrypted and isolated in native hardware-backed storage utilizing `FlutterSecureStorage` securely proxying to the iOS Keychain and Android Keystore.
2. **Local Database Security:** Hypertrack relies entirely on device OS-level encryption (Android File-Based Encryption / iOS Data Protection) to safeguard the `app_hybrid.sqlite` database and health data metrics. We advise users to maintain strong mobile screen locks. SQLCipher and SSL Pinning are explicitly omitted in the current Beta phase to prioritize stability against complex migration and CA rotation risks.

---

[← Return to Overview](overview.md)
