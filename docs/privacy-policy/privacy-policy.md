# Train Libre Privacy Policy

Last updated: May 09, 2026

## Overview

Train Libre is an offline-first fitness and nutrition tracking app. Your data is stored locally on your device by default and does not require a cloud account.

Sensitive data stays on your device unless you explicitly use a feature that accesses another app, a system health service, a third-party AI provider, a share/export target, or a remote public catalog source.

Train Libre is not a medical service. Health, recovery, sleep, pulse, nutrition, and training features are for personal tracking and training context only. They are not intended to diagnose, treat, cure, or prevent any disease or medical condition.

## Data We Process

Depending on the features you use, Train Libre stores or processes the following data on your device:

- **Profile and settings:** Username, height, gender, goals, and unit preferences.
- **Workouts:** Routines, exercises, sets, reps, weights, RIR/RPE, rest times, and duration.
- **Nutrition:** Foods, meals, barcodes, calories, macros, hydration, and supplements.
- **Body data:** Bodyweight and body measurements.
- **Health integration:** Steps, sleep sessions, and heart-rate samples (when permissions are granted).
- **Local analytics:** Training statistics, recovery estimates, and body/nutrition trend calculations.

The app uses local storage (SQLite/Drift), SharedPreferences, and secure native storage for AI API keys.

## Permissions and Device Access

Train Libre requests the following permissions for specific features:

- **Camera:** Used for barcode scanning and AI meal photo capture.
- **Photos/Gallery:** Used for selecting a profile image or meal photos for AI analysis.
- **Notifications:** Used for reminders or recommendations where enabled.
- **File Access:** Used for data import/export and backups.
- **Health Access:** Used for Apple Health or Google Health Connect features.

You can manage these permissions in your device settings.

## Health and Fitness Data

Integration with platform health services (Apple Health on iOS, Google Health Connect on Android) is entirely optional. Access only occurs after you explicitly grant permission.

Depending on enabled features, Train Libre may read:
- **Steps** for activity summaries.
- **Sleep sessions and stages** for recovery metrics.
- **Heart-rate data** for pulse analysis and workout summaries.
- **Workout-related health data** where available.

Train Libre may write/export supported app-recorded data such as:
- **Workouts**.
- **Body measurements** (weight, body fat).
- **Nutrition aggregates**.
- **Hydration data**.

This is a one-way export from Train Libre to the platform health service. Train Libre remains the primary local source of truth. Health data is used for personal tracking, statistics, and training context. It is not used for advertising, tracking, profiling, or sale. The app is not a medical device and does not provide medical diagnosis or treatment. Permissions can be revoked in system settings.

## AI Features

AI meal recognition and AI meal recommendations are optional and disabled by default. The app uses a "Bring Your Own Key" (BYOK) model where you choose and configure a supported provider.

Only when you actively use an AI feature are selected inputs sent to the configured provider. This may include:
- **Meal description text**.
- **Selected images**.
- **Relevant nutrient context**.
- **Optional recent meal context** (only if the user enables that setting).

API keys are stored locally and securely. Train Libre does not operate its own AI backend for these requests. Provider processing is governed by their own terms and privacy policies. AI outputs are estimates. Results are shown for review before saving. You can edit, remove, or reject items before they become part of the local diary. AI data is not used by Train Libre for advertising or tracking.

## Backups and Data Portability

You can create JSON backups, encrypted backups, or CSV exports. If you choose a non-encrypted format, the file contents are readable by anyone with access to the file.

You are responsible for where you save or share these exported files. Imports allow you to restore data from previous backups or other supported formats.

## Remote Catalogs

The app can fetch public exercise and food catalog updates from official Train Libre sources. These requests only download data and do not upload your personal tracking logs. Standard network metadata (like IP address) is visible to the hosting provider during these requests.

## Ads, Analytics, and Tracking

Train Libre does not include advertising, third-party analytics SDKs, or trackers. All statistics and insights are computed locally on your device. Your data is never sold or shared for advertising purposes.

## Data Storage and Security

Primary data is stored locally. Security depends on your device's operating system and lock screen protections. Be cautious when sharing exported files or using unencrypted backups.

## Your Controls

- You decide which optional features and permissions to enable.
- You can delete entries or your entire profile within the app.
- You can remove saved AI API keys at any time.
- Uninstalling the app removes its local data from your device.

## Contact

Richard Georg Schotte  
Email: richard@schotte.me
