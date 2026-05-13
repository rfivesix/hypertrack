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

- [Project Overview](documentation/overview.md)
- [System Architecture](documentation/architecture.md)
- [Data Models & Storage](documentation/data_models_and_storage.md)
- [Statistics & Analytics](documentation/statistics_module.md)
- [Adaptive Nutrition Recommendation](documentation/adaptive_nutrition_recommendation_current_state.md)
- [AI Meal Features Architecture](documentation/ai_meal_features_architecture.md)

## Roadmap

### Mid-term

- Program library (“store”) of curated training plans (e.g. PPL, upper/lower, hypertrophy blocks) that can be copied into personal routines.
- Weekly training calendar to assign plans/routines to specific days (e.g. Mon Push, Wed Pull, Fri Legs) and see planned vs. completed sessions.
- More advanced training and nutrition goal logic (training/rest‑day profiles, simple refeed/high‑day patterns) on top of the adaptive TDEE estimator.
- Official Google Play Store release
- F-Droid Release

### Long-term

- Wearable-/watch‑first logging experiences for minimal‑friction set tracking.
- Strava and other privacy‑respecting FOSS ecosystem integrations where they make sense.
- Deeper AI‑assisted workflows (meal capture, planning) while keeping BYOK and strict on‑device validation.

### Ideas / Potential

These are early ideas, not commitments. They will only happen if they make sense for users and for the project.

- **Optional low‑cost AI add‑on:** If there is enough demand, Train Libre might offer a privacy‑respecting subscription where the app manages the AI API key for you (no manual key setup, no per‑token billing hassle). The core app would stay open source, offline‑first, and fully usable without any subscription.

- **Optional private account & sync (self‑hostable first):** Long‑term, there could be an optional account layer for encrypted backup and multi‑device sync, designed to be self‑hostable (e.g. via a small Docker setup, possibly on top of something like Supabase or a similar backend).
  A public, centrally hosted instance might exist later, but would remain strictly optional — Train Libre should work fully without any account or external server.
  
## Credits

- **[Open Food Facts](https://openfoodfacts.org/)** for food database coverage.
- **[wger](https://github.com/wger-project/wger)** for the workout database foundation.

## License

[GPL-3.0](LICENSE)
