# Developer Overview & Testing Philosophy

This document outlines the high-level system purpose, the modular offline-first tech stack, and the comprehensive testing philosophy that maintains stability across the Train Libre codebase.

---

## High-Level System Purpose

Train Libre is an offline-first, privacy-respecting health, nutrition, sleep, and activity tracker. Unlike traditional wellness applications that rely on persistent cloud servers, Train Libre runs entirely locally. It treats the user's mobile device as the primary computing unit and the absolute source of truth.

### Key Technical Pillars
1.  **Zero Backend Dependency**: No external cloud service is required for registration, database writes, sync logs, or analytic graphs.
2.  **User-Driven Connectivity**: Network operations are strictly confined to user-initiated actions, specifically Bring Your Own Key (BYOK) AI capture APIs and native system Health platforms (Apple HealthKit / Google Health Connect).
3.  **Performance and Battery Preservation**: Database access and background syncing utilize optimized local querying, caching, and lazy initialization to minimize battery usage and CPU overhead.

---

## Technology Stack

The application's framework and core modules are built using the following technologies:

*   **Core Framework**: Flutter (Dart) for high-performance cross-platform presentation and systems integration.
*   **Local Persistence**: Drift (formerly Moor) built on top of native SQLite databases. Drift acts as the reactive database layer, utilizing Dart code-generation for type-safe queries.
*   **Security & Encryption**: `flutter_secure_storage` to handle sensitive local data, such as private developer API keys for the optional AI services, utilizing iOS Keychain and Android Keystore services.
*   **Platform Integration**: Native Method Channels to bridge iOS Swift HealthKit and Android Kotlin Health Connect systems directly to Dart services.

---

## Testing Philosophy

A core tenet of the Train Libre development lifecycle is strict mathematical and logic regression checking. Due to the high sensitivity of personal health records and the mathematical nature of the TDEE (Total Daily Energy Expenditure) filter, any logic drift would result in erroneous calorie targets or synchronization corruption.

To prevent regressions, the codebase features a robust test suite comprising **107 individual test files** and **590+ automated tests**.

### Test Categories
1.  **Unit Tests**: Validate mathematical engines (e.g., `BayesianTdeeEstimator` and Kalman updates), text token fuzzy matching scores, data parsing models, and canonical health-data mapping algorithms.
2.  **Widget & Integration Tests**: Test page transitions, loading state blocks, secure key persistence, backup/restore file integrity, and asynchronous data ingestion flows.
3.  **Database Migration Tests**: Validate that schema transitions are completely lossless and that legacy fields map seamlessly to new structures (specifically testing reactive data migrations).

### Core Testing Invariant
No code is merged without passing the entire automated suite. Every mock database is rigorously injected via `DatabaseHelper.forTesting()`, ensuring that database tests execute in completely isolated memory environments without colliding with real user storage.
