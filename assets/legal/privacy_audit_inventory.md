# Train Libre: Privacy & Data Inventory (Technical Audit)

**Date:** May 12, 2026  
**Status:** Exhaustive Technical Inventory  
**Purpose:** GDPR-compliant data mapping. This is NOT a privacy policy.

---

## 1. OS Permissions & Hardware Access

| Permission | Purpose (Code Logic) | Data Handling |
| :--- | :--- | :--- |
| **Camera** | Barcode scanning (`flutter_zxing`) and AI meal capture (`ai_meal_capture_screen.dart`). | Barcode images are processed in-memory for scanning. Meal photos are encoded to Base64 and transmitted to configured AI providers via `AiService`. Raw images may be temporarily cached by the OS image picker. |
| **Internet** | Connection to Third-Party APIs (AI, Open Food Facts, wger). | Enables outgoing HTTPS requests. Exposes user's IP address and OS user-agent to service endpoints. |
| **Health (Android Health Connect)** | Synchronizes health data with the Android system. | **Reads:** Steps, Sleep, Heart Rate. **Writes:** Weight, Body Fat, Nutrition, Hydration, Exercise, Distance. |
| **Health (iOS HealthKit)** | Synchronizes health data with Apple Health. | **Reads:** Steps, Sleep, Heart Rate. **Writes:** Measurements (Weight, etc.), Nutrition, Hydration, Workouts. |
| **Photo Library (iOS/Android)** | User selection of profile images or existing meal photos for AI analysis. | Accesses local storage to retrieve image files for processing or display. |
| **Notifications** | Scheduled reminders (e.g., `recommendation_due_notification.dart`). | Local scheduling of notifications. No external notification server is used. |
| **Storage (SAF)** | Backup and export functionality on Android via Storage Access Framework (`saf_storage_service.dart`). | Requests permission to read/write specific user-defined directories for `.db` and `.json` files. |

---

## 2. Local Data Storage & OS-Level Backups

### Primary Database (SQLite/Drift)
Stored in the App Sandbox (`app_hybrid.sqlite`).  
**Sensitive Data (GDPR Art. 9 - Health Data):**
- **Profiles:** Birthday, height, gender, profile image path.
- **Measurements:** Weight, body fat, and other physiological metrics.
- **NutritionLogs:** Complete history of food and fluid intake (dietary habits).
- **WorkoutLogs & SetLogs:** Detailed exercise history and performance metrics.
- **SupplementLogs:** History of supplement intake (e.g., caffeine, vitamins).
- **Sleep Data:** `sleep_raw_imports` (JSON payload from OS), `sleep_nightly_analyses` (score, duration, efficiency, heart rate).
- **Pulse Data:** `pulse_hourly_aggregates` (Heart rate metrics).
- **Steps:** `health_step_segments` (Step counts synced from OS).

### Secure Storage (`flutter_secure_storage`)
- **AI API Keys:** Stored in the device's secure hardware (iOS Keychain / Android Keystore).

### Preferences (`shared_preferences`)
- UI settings (Theme, Unit system).
- App tour status and feature flags.

### OS-Level Backups
- **iCloud / Google Drive Backup:** The app sandbox (including the SQLite DB) is NOT explicitly excluded from system-level backups (`excludeFromBackup` is absent in code). If the user has cloud backups enabled, their health data is synced to Apple/Google servers as part of the OS backup.

---

## 3. Third-Party APIs & Network Traffic

| Provider | Purpose | Data Transmitted |
| :--- | :--- | :--- |
| **AI Providers (BYOK)** | Meal analysis and recommendations. | **OpenAI, Google Gemini, Anthropic, Mistral, xAI:** Sends text prompts, meal photos (Base64), and requested JSON schema. User's API key is sent in the header. |
| **Open Food Facts** | Food catalog download and search. | Downloads DB files from OFF servers. attribution links expose IP to `openfoodfacts.org`. |
| **wger** | Exercise catalog download. | Downloads DB files from wger servers. attribution links expose IP to `wger.de`. |
| **GitHub** | Code repository and updates. | Attribution links and potential update checks expose IP to `github.com`. |

---

## 4. Feedback Report System

**File:** `lib/features/feedback_report/presentation/feedback_report_screen.dart`

**Collected Telemetry (Diagnostics):**
- **Metadata:** OS version, App version, Build number, Platform (Android/iOS/Web), Generation timestamp.
- **User Note:** Optional free-text message.
- **Adaptive Nutrition Diagnostics:** TDEE estimates, goal progress, and internal engine states.
- **Backup/Restore Diagnostics:** Status of local and cloud backup mechanisms.

**Transmission Method:**
- Uses `mailto:feedback@schotte.me`.
- **Privacy Impact:** Opens the user's default email client. This explicitly exposes the user's **email address** to the developer and creates a link between their identity and the diagnostic data.

---

## 5. Analytics, Crashlytics & Tracking

- **Confirmation:** The app does **NOT** contain Firebase Analytics, Google Analytics, Sentry, or any other third-party tracking or automated crash reporting SDKs.
- **Status:** Privacy-first. No automated background telemetry.

---

## 6. App Distribution & Hosting

- **Distribution Channels:** F-Droid, GitHub Releases, Apple App Store, Google Play Store.
- **Metrics:** Each store/platform collects its own download and usage metrics according to their respective privacy policies. Train Libre does not ingest these metrics back into its own infrastructure.

---

## 7. Security Architecture Notes

- **Encryption:** AI API keys are stored in encrypted hardware. The SQLite database is currently NOT encrypted at rest (stored in plain SQLite format in the sandbox).
- **No Cloud Backend:** Train Libre operates entirely without a proprietary cloud backend. All data syncing (Health, AI) happens directly between the device and the respective third-party API endpoints.
