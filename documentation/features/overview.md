# Feature Transparency & Privacy Architecture

Train Libre leverages advanced computational intelligence to provide users with adaptive nutrition recommendations, intelligent meal capture, and robust health metrics synchronization. Crucially, all calculations and integrations are designed around strict **local-first** and **privacy-first** principles.

---

## Architectural Privacy Invariants

To achieve true user privacy, the application enforces the following technical boundaries:

1.  **Zero Cloud Intermediaries**: The application does not route user metrics through a custom server. There is no central database, no login wall, and no shared telemetry pipeline.
2.  **On-Device Encryption & Security**: Extremely sensitive data, such as the developer keys required to invoke third-party Large Language Models, are stored using hardware-backed cryptographic keychains (`flutter_secure_storage`).
3.  **Local Algorithmic Execution**: High-level statistical logic, such as the Kalman Filter that computes TDEE recommendations, is evaluated completely on-device. Your body mass indices, intake habits, and physical metrics are never transmitted for analysis.

---

## Smart Capabilities Overview

The core computational modules of Train Libre are split into isolated, mathematically transparent features:

### 1. Bayesian TDEE Estimator
A mathematical engine utilizing a recursive Kalman Filter. It combines daily bodyweight slope calculations with logged calorie intakes to predict the user's Total Daily Energy Expenditure (TDEE). By applying Bayesian priors and calculating real-time observation variance, the system adjusts calorie recommendations while automatically penalizing poor-quality or sparse data.
*   *Learn more in the [**Bayesian TDEE Estimator Documentation**](bayesian_tdee_estimator.md).*

### 2. BYOK AI Meal Capture & Validation
An image and text analysis capture engine that translates photo logs or food descriptions into atomic, loggable ingredient components. It operates under a **Bring Your Own Key (BYOK)** security structure, communicating directly with provider end-points (OpenAI, Gemini, Anthropic, Mistral, xAI). It enforces a deterministic validation engine and a 3-pass self-repair validation loop to ensure all suggested weights and names map precisely to local database items before saving.
*   *Learn more in the [**BYOK AI Captured Meal Validation Documentation**](byok_ai_validation.md).*

### 3. One-Way Health Export
A local synchronization pipe that bridges local wellness data with native system platforms (Apple HealthKit and Google Health Connect). The export pipelines emphasize absolute idempotency. Using a local SQLite single source of truth (`health_export_records`), the application logs a custom hash of the data payload and date, ensuring that repeated synchronizations never write duplicate segments.
*   *Learn more in the [**One-Way Native Health Export Documentation**](health_sync_export.md).*

### 4. Sleep Health Score Engine (SHS v3.5)
A clinical-grade sleep analysis engine that evaluates overnight recovery across 5 domains (Sleep Duration, Sleep Continuity, Sleep Stage Depth / Architecture, Circadian Timing, and Sleep Regularity). Shifting from rigid binary limits to a continuous soft-cap multiplier model, the engine dynamically applies penalty factors based on the single worst-performing biological bottleneck (such as severe REM or N3 deep sleep deprivation, insufficient TST, or late circadian mid-sleep delays) to guide users with precise, contextual biological feedback.
*   *Learn more in the [**Sleep Health Score Engine Documentation**](sleep_scoring_engine.md).*

