# Hypertrack

**The modern, privacy-first fitness & nutrition tracker.**

Hypertrack (formerly *Hypertrack*) is an open-source, offline-first application built with Flutter. It aims to replace fragmented fitness tools by combining advanced workout logging, nutrition tracking, and body metrics into a single, cohesive ecosystem—without compromising your data privacy.

---

### 📖 **Documentation**
Learn more about the project: **[Hypertrack Project Overview](documentation/overview.md)**
- [System Architecture](documentation/architecture.md)
- [Data Models & Storage](documentation/data_models_and_storage.md)
- [UI & Widgets](documentation/ui_and_widgets.md)
- [Statistics Module (Source of Truth)](documentation/statistics_module.md)
- [Sleep Module — Day Batch 2](documentation/sleep/sleep_day_batch_2.md)

---

> **Note:** Hypertrack is currently shipping iterative **v0.7.1 alpha** builds focused on Health Steps UX and integration polish.

---

## ⚠️ **Important Disclaimer: v0.7 Foundation + Active Alpha Iterations**

**Please read before using:**

Hypertrack is on the **v0.7.x foundation** with active **v0.7.1 alpha** iterations. The architecture transition (Drift + UUIDs + modular analytics) is complete, while Health Steps and related UX continue to be refined in alpha releases.

* **Stable Foundation:** The database structure is solidified and no further breaking schema changes are expected.
* **Active Development:** New features and refinements continue to ship in minor and alpha updates.
* **Recommendation:** Continue using the built-in **Backup (JSON)** feature regularly as a best-practice safeguard.

---

## 🌟 Current Features (v0.7+)

Hypertrack is already a fully functional daily driver for fitness enthusiasts.

### 🏋️‍♂️ Workout Tracking
* **Routines:** Create custom workout plans with specific exercises, sets, and targets.
* **Live Logging:** Track your sessions in real-time with an integrated rest timer, RPE tracking, and previous performance references.
* **Flexible Sets:** Support for Normal, Warmup, Dropset, and Failure sets.
* **History:** Detailed log of all past workouts, volume, and personal records.

### 🍎 Nutrition & Hydration
* **Food Database:** Integrated with **Open Food Facts** for barcode scanning and product search.
* **Meals:** Group foods into meals (Breakfast, Lunch, etc.) or create custom reusable recipes.
* **🤖 AI Meal Capture & Recommendations (v0.6+):** Log meals instantly via photo, voice, or text description. Get personalized meal suggestions based on your remaining daily macros. AI detects individual foods with estimated quantities — review and edit before saving. Supports OpenAI GPT-4o and Google Gemini (BYOK — bring your own key).
* **Fluid Tracking:** dedicated logging for water, coffee, and sugary drinks.
* **Smart Analysis:** Automatically tracks caffeine intake based on logged beverages.
* **Macro Goals:** Set daily targets for Calories, Protein, Carbs, Fats, Fiber, Sugar, and Salt.

### 📈 Body Metrics & Health
* **Measurements:** Track weight, body fat percentage, and tape measurements (biceps, waist, etc.).
* **Charts:** Visualize your progress over time.
* **Statistics & Analytics Hub (v0.7):** ✅ Fully functional analytics workspace for consistency, performance, muscle distribution, recovery, and body/nutrition correlations, including dedicated drill-down screens.
* **Health Steps Module (v0.7.1 beta):** Dedicated steps detail screen with Day/Week/Month navigation, period switching, and improved trend visualizations with target/average guidance.
* **Supplements:** Manage your inventory and track daily intake of supplements (like Creatine or Vitamins) with full historical tracking of goals and limits.

### 🛡️ Privacy & Tech
* **Offline-First:** All data stays on your device by default. No account required.
* **Data at Rest Security:** Hypertrack natively inherits your device's OS-level encryption (iOS Data Protection / Android FBE). We strongly advise enabling a secure screen lock on your device.
* **No Ads, No Bloat:** Just the tools you need.
* **Export:** Full JSON export and encrypted backup options.
* **Universal Sharing (v0.7):** Export screenshots/photos and text context from anywhere in your workflow, then share instantly through native iOS/Android share sheets.

---

## 🗺️ Roadmap: The Path to v1.0 & Beyond

We are building a platform that gives you the convenience of cloud-based apps with the freedom of open source.

### ✅ Completed: v0.5 (The Architecture Update)
* **Database Rewrite:** Full migration to **Drift** (SQLite ORM) and **UUIDs (v4)** — completed.
* **Cloud-Ready Foundation:** The data layer is now stable and prepared for conflict-free synchronization.

### ✅ Completed: v0.6 (The AI Nutrition Update)
* **AI Meal Capture & Recommendations:** Capture meals via photo, voice, or text, and receive personalized meal suggestions based on remaining macros. Full support for OpenAI & Gemini.
* **Smart Matching:** AI intelligently matches against the local, language-aware product database.
* **Privacy Controls:** Global AI Kill-Switch added. API keys natively encrypted at rest.

### 🚧 Current: v0.7 (Health & Connectivity)
* **Apple HealthKit Integration:** Syncing workouts and weight with Apple Health — **Work in Progress (actively in development)**.
* **Statistics & Analytics Hub:** ✅ Completed and production-ready in v0.7.
* **Statistics Refactor:** Completed architecture and UX polish for the Statistics module (range-policy alignment, typed payload adoption in core analytics paths, and improved drill-down consistency).
* **Core Tracking Stability:** Continued refinements and bug fixes across workout and nutrition logging.

### ☁️ Planned: v1.0 (MVP & Store Release)
* **Silent Cloud Backup:** Hybrid self-host / managed encrypted backup running seamlessly in the background.
* **Cross-Device Sync:** Seamlessly switch between devices without manual exports.
* **Self-Hosting:** Official Docker support for users who want to host their own backend (BYOB - Bring Your Own Backend).
* **Core-Tracking Stability:** Polished, production-ready workout and nutrition experience.

### 🤝 Vision: v2.0 (Social & Connectivity)
* **Social Feed:** Share workouts, PRs, and streaks with friends.
* **Profiles:** Public profiles to showcase your stats (opt-in).
* **Competition:** Leaderboards and group challenges.

---

## 🛠️ Tech Stack

* **Framework:** Flutter
* **Local Database:** Drift (SQLite ORM)
* **State Management:** Provider
* **Backend (Future):** Supabase (PostgreSQL)

## ❤️ Contributing

Contributions, issues, and feature requests are welcome!
The v0.5 architecture refactoring is complete. Feel free to open an issue to discuss ideas or submit a PR—we'd love your help!

## 📄 License

[MIT](LICENSE)
