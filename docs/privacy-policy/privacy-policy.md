# Train Libre Privacy Policy

Last updated: May 6, 2026

## Overview

Train Libre is an offline-first fitness and nutrition tracking app. The repository shows that the app is designed to store user tracking data locally on the device by default and does not require a Train Libre cloud account.

Sensitive data stays on your device unless you explicitly use a feature that accesses another app, a system health service, a third-party AI provider, a share/export target, or a remote public catalog source.

Train Libre is not a medical service. Health, recovery, sleep, pulse, nutrition, and training features are for personal tracking and training context only. They are not intended to diagnose, treat, cure, or prevent any disease or medical condition.

## Data We Process

Depending on the features you use, Train Libre can store or process the following data on your device:

- Profile and settings data, such as username, birthday, height, gender, unit preferences, goals, theme settings, feature toggles, selected catalog region, and optional profile image path.
- Workout data, such as routines, exercises, sets, reps, weights, RIR/RPE, rest times, workout notes, workout dates, workout duration, distance, and cardio-related entries where used.
- Nutrition data, such as foods, meals, meal templates, product barcodes, quantities, calories, macros, sugar, fiber, salt/sodium, hydration, caffeine, creatine, supplements, supplement doses, and supplement history.
- Body data, such as bodyweight, body fat percentage, BMI where present, body measurements, and measurement sessions.
- Health integration data, such as step segments, sleep sessions, sleep stages, sleep-derived metrics, and heart-rate samples when health integrations are enabled and permissions are granted.
- Local analytics and derived data, such as training statistics, recovery estimates, body/nutrition trend calculations, sleep scores, pulse aggregates, and recommendation state.
- Imported data, such as workout CSV files selected by you for import.
- Backup/export data, when you choose to create, share, import, or automatically write backups.

The audited repository uses local SQLite/Drift storage, SharedPreferences, app document storage, temporary files for sharing/export, and secure native storage for AI API keys.

## Permissions and Device Access

The Android manifest and iOS permission strings show the following privacy-relevant permissions or device access:

- Camera: used for barcode scanning and AI meal photo capture.
- Photos or gallery: used for selecting a profile image and selecting meal photos for AI meal capture.
- Notifications: used for app notifications, including reminder or recommendation-related flows where enabled.
- File and folder access: used when you choose files for import, export files, share files, or select an Android folder for automatic backups.
- Health access: used for Apple Health or Google Health Connect features, as described below.

You can deny or revoke permissions in your device settings. Some features may not work without the related permission.

## Health and Fitness Data

Train Libre includes optional health integrations with Apple Health and Google Health Connect.

When enabled and permitted, the app can read:

- Steps, for step summaries and statistics.
- Sleep sessions and sleep stages, for sleep views and sleep-derived metrics.
- Heart-rate data, for sleep heart-rate context, pulse analysis, and workout heart-rate summaries where available.

When enabled and permitted, the app can write supported app-recorded data one way to Apple Health or Google Health Connect, including:

- Measurements such as weight and body fat percentage. Measurements such as weight, body fat percentage, and other supported body metrics.
- Aggregate nutrition and hydration entries.
- Workout sessions with session-level timing and summary notes where the platform supports them.

The repository documents this as a one-way export. It is not a bidirectional sync and does not make Apple Health or Google Health Connect the source of truth for Train Libre tracking data.

Train Libre also stores step segments locally after import. Sleep persistence tables store raw import records, normalized sleep sessions, sleep stage segments, sleep heart-rate samples, and derived nightly analyses. Pulse analysis reads platform heart-rate samples and stores hourly aggregate pulse data in the current repository.

## AI / Camera / Photos Features

AI meal features are optional and disabled by default in the repository documentation and settings flow. They use a bring-your-own-key design.

If you enable AI features and add an API key, Train Libre stores the API key in native secure storage through `flutter_secure_storage`. The audited code supports OpenAI, Google Gemini, Anthropic Claude, Mistral, and xAI Grok providers.

When you use AI meal capture or AI meal recommendations, Train Libre may send the following to the selected AI provider:

- Typed meal descriptions or prompts.
- Meal photos you choose or take for analysis.
- Selected preferences, constraints, meal type, target macros, and custom request text.
- A recent meal-history summary only if the separate recommendation context-sharing setting is enabled.
- Your provider API key as needed to authorize the request with that provider.

The AI provider returns suggested food names, gram estimates, recommendations, or repair suggestions. Train Libre then validates and matches those suggestions against the local food database before saving. The app does not silently save unmatched AI items as logged food.

Barcode scanning uses the camera to detect a barcode and look it up in the local product catalog. Profile image selection copies the selected image into app document storage.

## Backups, Export, Import, and Sharing

Train Libre includes full JSON backups, optional encrypted backups, automatic backups, CSV exports, import flows, and workout/routine sharing.

Full backups can include sensitive fitness, nutrition, body, profile, settings, preferences, custom foods, custom exercises, routines, workout logs, food logs, hydration, supplement data, goals, and imported step segments. The audited backup code exports all SharedPreferences keys as a `userPreferences` map. Based on the current backup serialization path reviewed, dedicated sleep and pulse persistence tables were not separately included in full backup payload generation.

Encrypted backups use a passphrase supplied by you. If you create an unencrypted backup or CSV export, the file contents are readable by anyone who can access the file.

Backups and exports are written to temporary files for sharing or to an app/user-selected storage location for automatic backups. On Android, automatic backups can use a folder selected through the Storage Access Framework. You are responsible for where you save, share, upload, or delete exported files and backups.

Imports can read selected files, such as full Train Libre backups or Hevy CSV workout exports, and write parsed data into the local database.

Sharing features can create text or image summaries of workouts and routines and pass them to the operating system share sheet. The selected receiving app or service handles that shared content under its own terms and privacy policy.

## Remote Catalogs and Third-Party Data Sources

Train Libre includes public exercise and food catalog data based on wger and Open Food Facts.

The repository shows remote catalog refresh services that can fetch public catalog manifests and SQLite catalog files from Train Libre GitHub release URLs. Supported Open Food Facts regions in the current configuration are Germany, United States, and United Kingdom. These catalog downloads are for public exercise and food data, not for uploading your personal tracking data.

Remote catalog requests may still expose standard network metadata, such as your IP address, user agent, request time, and requested URL, to the hosting provider and network operators. Train Libre validates downloaded catalog files before adopting them and falls back safely when a catalog refresh fails.

The app also contains links or attribution for Open Food Facts, wger, and the Train Libre GitHub repository. Opening external links leaves the app and is handled by your browser or the target service.

## Ads, Analytics, and Tracking

The audited repository does not include advertising SDKs, third-party analytics SDKs, crash-reporting SDKs, Firebase, AdMob, or tracker integrations.

Train Libre contains in-app statistics and analytics features, but those are local fitness and nutrition analysis features built from your local data. They are not evidence of third-party tracking.

Train Libre does not sell your personal data and does not use your data for advertising based on the audited repository behavior.

## Data Storage and Security

Train Libre stores primary app data locally in app-controlled SQLite/Drift databases and related app storage. Settings and feature state are stored in SharedPreferences. AI API keys are stored in native secure storage.

Local storage security depends on your device, operating system, lock screen, backups, and any apps or services you choose for sharing/export. Train Libre provides optional encrypted backups for full backup export, but unencrypted backups, CSV exports, shared images, shared text, and files you place in external folders may be accessible outside Train Libre.

No system can guarantee perfect security. Use device-level protections and be careful when sharing or storing exported files that contain health, fitness, nutrition, or profile data.

## Your Choices and Controls

You control Train Libre data and permissions in several ways:

- Do not enable optional AI features, health integrations, catalog refreshes, sharing, backups, imports, notifications, camera, or photos if you do not want to use them.
- Revoke camera, photo, notification, health, or file permissions in your device settings.
- Delete entries inside the app where deletion is available.
- Delete profile images and other local files where the app provides that control.
- Remove a saved AI API key from the AI settings screen.
- Disable AI recommendation context sharing while still using other AI features.
- Disable steps, sleep, pulse, or health export features in app settings where available.
- Delete backups, CSV exports, shared files, and automatic backup folders from wherever you stored them.
- Uninstall the app to remove app-local data from the device, subject to your operating system and backup settings.

If you have shared data with another app, an AI provider, Apple Health, Google Health Connect, cloud storage provider, messaging app, or other third party, you may need to manage or delete that copy through that third party.

## Children

Train Libre is a fitness and nutrition tracking app for users who can responsibly record training, nutrition, and health-related data. The repository does not indicate that the app is directed to children. Children should not use Train Libre without appropriate parent or guardian involvement.

## Changes to This Policy

This policy may be updated as Train Libre changes. Updates should revise the "Last updated" date and should continue to reflect the actual app behavior in the repository and release build.

## Contact

support@schotte.me
