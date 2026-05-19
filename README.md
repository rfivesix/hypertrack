# Train Libre

**Private workout and nutrition tracking for Android and iOS.**

Train Libre is an open-source, offline-first fitness app for logging workouts, calories, macros, bodyweight, and recovery — without ads, mandatory accounts, or analytics SDKs.

Designed for people who want serious tracking without social feeds, gamification, or subscription pressure, Train Libre prioritizes **privacy**, **local data ownership**, and **transparent analytics**.

## Download & Install

<table align="center">
  <tr>
    <td align="center" valign="middle" width="300">
      <a href="https://testflight.apple.com/join/x1UaM6TQ">
        <img
          src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
          alt="Download on the App Store"
          width="100%"
        />
      </a>
      <br><sub><b>iOS Public TestFlight Beta</b></sub>
    </td>
    <td width="50"></td>
    <td align="center" valign="middle" width="300">
      <a href="http://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/rfivesix/train-libre/releases">
        <img
          src="https://raw.githubusercontent.com/ImranR98/Obtainium/main/assets/graphics/badge_obtainium.png"
          alt="Get it on Obtainium"
          width="100%"
        />
      </a>
      <br><sub><b>Android (via Obtainium)</b></sub>
    </td>
  </tr>
</table>

*Google Play release is currently not available.*

## Platform Support

Train Libre is built with Flutter and supports:
- **iOS** (Active)
- **Android** (Active)

## Key Features

- **Workout Tracker:** Log sets (warm-up, failure, dropsets), routines, and session history.
- **Calorie & Macro Tracker:** Track nutrition, hydration, and supplements with adaptive weekly guidance.
- **Bodyweight & Recovery Analytics:** Deep insights into muscle readiness, volume trends, and body measurements.
- **Optional AI Meal Tools:** Capture meals from photos or text via BYOK (Bring Your Own Key) setup. Always reviewable before saving.
- **Privacy & Local-First:** Data stays on device. Optional one-way health export to Apple Health and Google Health Connect.

## Privacy & Philosophy

- **No Ads. No Mandatory Account. No Analytics SDKs.**
- **Offline-First:** Your data stays local unless you explicitly choose otherwise.
- **Open-Source Transparency:** Trust through public code and understandable data flows.
- **User-Controlled AI:** Optional AI features require your own API key; no data is sent to providers without opt-in.

## Documentation

This project features a comprehensive, modular documentation suite split by target audience and component. Use the links below to access the technical resources:

### Developer Resources
*   [Developer Overview](documentation/developer/overview.md): Technical vision, key architectural pillars, technology stack, and testing philosophy.
*   [Architecture & SQLite Lifecycle](documentation/developer/architecture.md): Clean Architecture layering and database connection lifecycle pattern.
*   [Data Flow & State Lifecycle](documentation/developer/data_flow_and_state.md): Reactive reads, imperative writes, subscription cancellation, and UI concurrency guards.

### Advanced Features & Algorithmic Transparency
*   [Smart Features Overview](documentation/features/overview.md): Overview of algorithmic features and architectural privacy invariants.
*   [Bayesian TDEE Estimator](documentation/features/bayesian_tdee_estimator.md): Comprehensive mathematical and statistical formulation of the Kalman filter-based adaptive energy expenditure engine.
*   [BYOK AI Meal Validation](documentation/features/byok_ai_validation.md): AI meal capture pipeline details, fuzzy validation scoring, and the 3-pass self-repair verification loop.
*   [One-Way Health Sync & Export](documentation/features/health_sync_export.md): Data export pipelines, SQLite-backed idempotency tracking, step segment merging policies, and fault-tolerance patterns.

For the full interlinked documentation map, see the main [Documentation Entry Point](documentation/README.md).

## Roadmap

The long-term vision, future modules, and planned features are maintained in the [ROADMAP.md](ROADMAP.md) file.

## Credits

- **[Open Food Facts](https://openfoodfacts.org/)** for food database coverage.
- **[wger](https://github.com/wger-project/wger)** for the workout database foundation.

## License

[GPL-3.0](LICENSE)

