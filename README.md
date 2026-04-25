
# Hypertrack
Hypertrack is an offline-first fitness app for **workouts, nutrition, analytics, sleep, steps, measurements, and supplements**.

It is designed primarily for **experienced lifters and gym-focused athletes** who want structured tracking, clear long-term progress analysis, and practical recommendations **without gamification**. Hypertrack focuses on **privacy-friendly local data handling**, **transparent analytics**, and features that are intended to be understandable, evidence-informed, and mathematically grounded where appropriate. It can be used as a simple logging app but its main goal is to go beyond logging without becoming noisy, gimmicky, or opaque.

## Install

<table align="center">
  <tr>
    <td align="center" valign="middle" width="420">
      <a href="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTo7lpaRmW36htMaT8R6q4qOQlJ3A5-wvvdJg&s">
        <img
          src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
          alt="Download on the App Store"
          width="100%"
        />
      </a>
    </td>
    <td width="28"></td>
    <td align="center" valign="middle" width="420">
      <a href="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTo7lpaRmW36htMaT8R6q4qOQlJ3A5-wvvdJg&s">
        <img
          src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
          alt="Get it on Google Play"
          width="100%"
        />
      </a>
    </td>
  </tr>
  <tr>
    <td colspan="3" align="center">
      <sub><b>Official app stores</b></sub>
    </td>
  </tr>
  <tr>
    <td colspan="3" height="18"></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="420">
      <a href="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTo7lpaRmW36htMaT8R6q4qOQlJ3A5-wvvdJg&s">
        <img
          src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
          alt="Get it on F-Droid"
          width="100%"
        />
      </a>
    </td>
    <td width="28"></td>
    <td align="center" valign="middle" width="420">
      <a href="http://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/rfivesix/hypertrack/releases">
        <img
          src="https://raw.githubusercontent.com/ImranR98/Obtainium/main/assets/graphics/badge_obtainium.png"
          alt="Get it on Obtainium"
          width="100%"
        />
      </a>
    </td>
  </tr>
  <tr>
    <td colspan="3" align="center">
      <sub><b>Alternative Android distribution</b></sub>
    </td>
  </tr>
</table>

## Highlights

- **Workout tracking** with structured sets, history, and session review
- **Nutrition tracking** with calories, macros, and adaptive weekly intake guidance
- **Statistics and analytics** for performance, consistency, muscle volume, recovery, and body/nutrition trends
- **Sleep and steps integration** for broader recovery and activity context
- **Supplement tracking**, including caffeine, creatine, and custom supplements
- **Offline-first local data handling**
- **One-way export** to Apple Health and Google Health Connect
- **Optional AI meal features** with BYOK setup  
  - AI is **disabled by default**
  - no mandatory cloud account
  - no provider-managed in-app billing flow

## Core features

### Workouts
- Log full workout sessions
- Track exercises set by set
- Support warm-up, standard, failure, and dropset-style set logging
- Track reps, weight, and RIR
- Review workout history and post-workout summaries
- View workout heart-rate summaries and workout-detail heart-rate charts where data is available

### Nutrition
- Log foods, meals, and nutrition entries
- Track calories and core macros
- Track additional nutrition values such as fiber, sugar, and salt/sodium where available
- Use adaptive weekly nutrition recommendations based on the current Bayesian estimator
- Use optional AI-assisted meal capture with your own API key
- Export aggregate nutrition data to Apple Health and Google Health Connect

### Statistics
- Performance and PR-oriented views
- Consistency tracking
- Muscle-volume-related analysis
- Recovery-focused insights
- Bodyweight and calorie trend analysis
- Sleep and steps context inside the statistics area

### Sleep and steps
- Import and aggregate step data
- Import, process, and visualize sleep data
- Sleep day, week, and month views
- Sleep detail screens and scoring
- Sleep and steps integration into the broader analytics experience

### Measurements
- Log bodyweight and body measurements
- Track changes over time in charts
- Export supported measurements to Apple Health and Google Health Connect

### Supplements
- Track caffeine and creatine
- Track custom supplements
- Review supplement intake over time

## Health integrations

Hypertrack supports **one-way export** to:

- **Apple Health**
- **Google Health Connect**

This includes supported app-recorded data such as:
- measurements
- aggregate nutrition
- hydration
- workout sessions

Hypertrack remains the source of truth for its own tracking and analytics.

## Privacy and local-first philosophy

- Hypertrack is **offline-first**
- app data is handled locally by default
- AI meal features are **optional** and **disabled by default**
- AI usage is **BYOK only** (bring your own API key)
- optional AI recommendation history/context sharing is a separate opt-in
- no mandatory cloud account is required to use the app

## Documentation

- [Project Overview](documentation/overview.md)
- [AI Meal Features Architecture](documentation/ai_meal_features_architecture.md)
- [Adaptive Nutrition Recommendation](documentation/adaptive_nutrition_recommendation_current_state.md)
- [Statistics Module](documentation/statistics_module.md)
- [System Architecture](documentation/architecture.md)

## Credits

- **[Open Food Facts](https://openfoodfacts.org/)** for food database coverage
- **[wger](https://github.com/wger-project/wger)** for the workout database foundation

## License

[MIT](LICENSE)
