# Train Libre: Modular Documentation Suite

Welcome to the technical documentation suite for **Train Libre**, a highly performant, offline-first, and privacy-centric wellness, sleep, and nutrition tracking application. This suite provides detailed architecture specifications, state management paradigms, and mathematical descriptions of the core algorithmic features of the application.

## Project Vision

Train Libre is designed around the core principles of user autonomy, offline capability, and algorithmic transparency. By avoiding any centralized backend, storing all user records in a local SQLite database (via Drift), and utilizing a Bring Your Own Key (BYOK) model for optional AI enhancements, the application guarantees absolute user privacy and data ownership.

---

## Documentation Directory Map

This documentation suite is split into highly modular, focused files categorised by audience and purpose. Use the links below to navigate the suite.

### 1. Developer Documentation (`documentation/developer/`)
For software engineers, system architects, and technical contributors.

*   [**System Overview & Testing Philosophy**](developer/overview.md): High-level system purpose, tech stack, and details on our highly stable 107-file, 590+ test suite.
*   [**System Architecture & SQLite Lifecycle**](developer/architecture.md): Our strict Clean Architecture boundaries (Presentation $\rightarrow$ Domain $\leftarrow$ Data) and thread-safe lazy-initializing private constructor for SQLite.
*   [**Data Flow & State Lifecycle**](developer/data_flow_and_state.md): Detail on our "Reactive Reads / Imperative Writes" paradigm, reactive Drift stream handlers, subscription lifecycles, and edit-mode user interface input blocking.

### 2. Feature Transparency & Algorithmic Logic (`documentation/features/`)
For advanced users, mathematical evaluators, and privacy auditors who seek complete transparency into our smart processing engines.

*   [**Capabilities & Privacy Overview**](features/overview.md): Summary of the app's advanced smart capabilities, local processing model, and native secure storage.
*   [**Bayesian TDEE Estimator (Kalman Filter)**](features/bayesian_tdee_estimator.md): Full mathematical and algorithmic analysis of the Adaptive Diet Recommendation Engine, including Kalman filter equations, variance boundaries, completeness coefficients, and linear ramps.
*   [**BYOK AI Meal Capture & Validation**](features/byok_ai_validation.md): Core detail on the local BYOK API integration, system prompts restricting LLM calculations, fuzzy string matching, target-fit verification, and the 3-pass self-repair verification loop.
*   [**One-Way Native Health Export**](features/health_sync_export.md): Technical overview of the Apple HealthKit and Google Health Connect data syncing pipelines, details on step segment merging, and the SQLite-backed Single Source of Truth (SSOT) idempotency architecture.
*   [**Sleep Health Score Engine (SHS v3.5)**](features/sleep_scoring_engine.md): Complete technical specification of our sleep scoring algorithms, including Gaussian, logistic, and quadratic curves for 5 domains and the continuous soft-cap multiplier penalty logic.
