# Train Libre

Train Libre is an offline-first fitness app for **workouts, nutrition, analytics, sleep, steps, measurements, and supplements**.

Designed for experienced lifters and athletes, it provides structured tracking and long-term progress analysis without gamification. Train Libre prioritizes **privacy**, **local data ownership**, and **transparent analytics**.

## Download & Install

<table align="center">
  <tr>
    <td align="center" valign="middle" width="300">
      <a href="https://testflight.apple.com/join/VpG7r9z4">
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

- **Workout Tracking:** Structured sets (warm-up, failure, dropsets), history, and session reviews.
- **Nutrition:** Calorie and macro tracking with adaptive weekly guidance.
- **AI Meal Features (Optional):** AI-assisted meal capture via BYOK (Bring Your Own Key) setup. Disabled by default.
- **Analytics:** Deep insights into performance, volume, recovery, and trends.
- **Sleep & Steps:** Integration of recovery and activity context from system health services.
- **Supplements:** Track caffeine, creatine, and custom supplements.
- **Local Data:** One-way export to Apple Health and Google Health Connect.

## Privacy & Philosophy

- **Offline-First:** Your data stays on your device by default.
- **No Accounts:** No mandatory cloud account or registration required.
- **Transparency:** Open-source and avoids opaque tracking or gamification.
- **BYOK AI:** Optional AI features require your own API key; no data is sent to AI providers unless you opt-in.

## Documentation

- [Project Overview](documentation/overview.md)
- [System Architecture](documentation/architecture.md)
- [Data Models & Storage](documentation/data_models_and_storage.md)
- [Statistics & Analytics](documentation/statistics_module.md)
- [Adaptive Nutrition Recommendation](documentation/adaptive_nutrition_recommendation_current_state.md)
- [AI Meal Features Architecture](documentation/ai_meal_features_architecture.md)

## Credits

- **[Open Food Facts](https://openfoodfacts.org/)** for food database coverage.
- **[wger](https://github.com/wger-project/wger)** for the workout database foundation.

## License

[GPL-3.0](LICENSE)
