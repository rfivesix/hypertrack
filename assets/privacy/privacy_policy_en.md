# Privacy Policy for the App "Train Libre"

**Version:** 1.4  
**As of:** May 26, 2026  

This privacy policy informs you in accordance with Articles 13 and 14 of the General Data Protection Regulation (GDPR) about the processing of personal data and health-related data in the mobile application "Train Libre". 

Since Train Libre is designed as a local-first application, full control over your data remains directly with you at all times. We do not operate any central database or application servers to store your profiles, workouts, or nutrition logs.

---

## 1. Controller

The controller for data processing within the meaning of Article 4(7) of the GDPR is the developer and service provider:

Richard Georg Schotte  
Bundesallee 114  
12161 Berlin  
Germany  

Email: feedback@schotte.me  
Phone: (+49) 1520 6915571  

Since the controller is an individual developer and the statutory requirements for the mandatory appointment of a data protection officer pursuant to Article 37 of the GDPR and Section 38 of the German Federal Data Protection Act (BDSG) are not met, no separate data protection officer has been appointed. All data protection-related inquiries can be directed directly to the email address provided above.

---

## 2. Core Philosophy

Train Libre is based on the principles of "privacy by design" and "privacy by default" (Article 25 of the GDPR) as well as the principle of data minimization (Article 5(1)(c) of the GDPR). 

* **No User Accounts:** No registration or creation of a user account is required to use the app. No email addresses, passwords, or login credentials are stored on external servers.
* **Local-First Architecture:** All profile settings, athletic activities, nutrition data, vital signs, and measurements entered by you are stored exclusively in a local SQLite database on your own end device.
* **No Central Backend Server:** We do not operate any cloud databases or application servers to store or process your training and nutrition data. Your data remains in your physical possession.
* **No Tracking or Analytics SDKs:** Train Libre completely dispenses with the integration of third-party advertising networks, behavior-based analysis services, or error diagnostics SDKs (such as Firebase Analytics, Google Analytics, Mixpanel, Sentry, or Crashlytics). No profiling or behavior-based evaluation for marketing purposes takes place.

---

## 3. Locally Processed Data

By using the app, your mobile device's operating system processes data in a local SQLite database (Drift/sqflite). This storage is necessary for the operation of the app and to fulfill its core functions.

### A. Categories of Processed Data

The local database includes the following data categories:

1. **Profile Settings and Goals:** Username, date of birth, body height, gender, profile picture file path, and individually defined daily goals (target calories, target protein, target carbohydrates, target fat, target water, target steps).
2. **Training and Activity Logs (Workouts):** Training plans (routines), exercise templates, historical workout logs (start and end times, notes, exercise sets with rep and weight values, RPE and RIR values, rest times, cardiovascular activities including distance, duration, and calories burned).
3. **Nutrition and Fluid Logs (Nutrition & Fluids):** Consumed food items (timestamp, amount in grams/milliliters, meal type), water and beverage logs (amount, nutrient content, caffeine content).
4. **Food and Product Catalog (User-Products):** Products individually created by the user, including barcode, product name, brand, and macro/micronutrient information per 100g/ml (calories, protein, carbohydrates, fat, sugar, dietary fiber, salt, caffeine, list of ingredients, and additives).
5. **Supplements:** Set up supplements (name, default dose, unit, daily goal, and daily limit) as well as historical supplement log entries with intake timestamp and amount.
6. **Body Dimensions and Measurements (Measurements):** Historical measurement values for body weight and various body circumferences (e.g., chest, waist) including date and unit.
7. **Heart Rate Data Aggregates:** Local hourly aggregations of heart rate (minimum, maximum, and average beats per minute, as well as sample count).
8. **Sleep Data Analyses:** Processed sleep data including sleep phases (deep sleep, REM, light sleep, waking phases), sleep efficiency, resting heart rate, sleep interruptions, sleep regularity, as well as historical raw data imports from system interfaces.
9. **Local Step Segments:** Step counts imported from system interfaces with precise start and end times as well as data source identifiers for local duplicate cleaning.

### B. Legal Basis for Processing

Since storage and evaluation take place exclusively locally on your end device, control over data protection and data processing remains in your own sphere. Insofar as the app is considered within the scope of the GDPR, the following legal bases apply:

* **General Data and Settings (Article 6(1)(b) of the GDPR):** The processing of general profile settings, training plans, and app preferences is carried out to fulfill the user relationship (provision of app functionalities).
* **Health Data (Article 9(2)(a) of the GDPR in conjunction with Article 6(1)(a) of the GDPR):** For the processing of physical measurements, heart rate data, sleep analyses, and nutrition logs (which fall under special categories of data as health-related data), you grant your explicit consent by actively entering them or enabling the import. You can withdraw this consent at any time by deleting the corresponding entries or by resetting all app data.

---

## 4. Third-Party Integrations / BYOK

To provide advanced features, the app has interfaces to external services. These functions are optional and require your active participation.

### A. Bring-Your-Own-Key (BYOK) AI Meal Capture

Train Libre offers the option to analyze meals via photos or free-text descriptions using artificial intelligence. This function is based on the "Bring-Your-Own-Key" (BYOK) principle. You must store your own API key from a supported provider in the app to use this.

* **Supported Providers:** OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok, Ollama, and custom OpenAI-compatible endpoints.
* **Secure Local Key Storage:** The API key you enter is stored encrypted using AES-256 encryption via the `flutter_secure_storage` package in the operating system's secured storage area (iOS Keychain or Android Keystore). The key remains exclusively local to your device and is never transmitted to us.
* **Restricted Data Transmission:** When using the AI analysis, your device sends the captured meal photo or entered text description directly via an encrypted HTTPS connection to the API of the selected AI provider. **No personalized account data, user metadata, or historical profile information from Train Libre is attached to these external endpoint payloads.**
* **Analytical AI Processing (No Generative Coaching):** The AI analysis is used for the **exclusive analytical purpose** of decomposing meal photos or text descriptions into **atomic ingredients**. Train Libre does **not** use AI to dynamically generate or propose personalized recipes, meal plans, or automated health coaching.
* **Privacy Protection via System Prompt:** To maximize your privacy, the app's globally stored system prompt is configured to instruct the AI provider to identify only food components and estimate their weight in grams. The AI provider is explicitly instructed **not** to perform any nutrient calculations (such as calories, protein, fat, or carbohydrates). The determination of nutrients is then performed via a **hybrid approach**: recognized food names are matched against your **local offline database** using a deterministic **Jaro-Winkler-based matching engine** (SQLite/Drift).
* **Local-First Alignment:** Core macro calculations, user profiling, and history tracking remain **strictly local-first** on your device and are never transmitted to external providers or used to train global AI models.
* **Responsibility:** Since you are using your personal API key, you enter into a direct user relationship with the respective AI provider. Data processing by the AI provider is subject to their respective privacy policies. Please check your provider's privacy policy (especially regarding the use of data for training purposes and server locations) before using the function.

| Provider | Privacy Policy |
| :--- | :--- |
| OpenAI | [https://openai.com/policies/privacy-policy](https://openai.com/policies/privacy-policy) |
| Google Gemini | [https://policies.google.com/privacy](https://policies.google.com/privacy) |
| Anthropic Claude | [https://www.anthropic.com/privacy](https://www.anthropic.com/privacy) |
| Mistral AI | [https://mistral.ai/privacy-policy](https://mistral.ai/privacy-policy) |
| xAI Grok | [https://x.ai/privacy-policy](https://x.ai/privacy-policy) |
| Ollama | [https://ollama.com/privacy](https://ollama.com/privacy) |

For transmissions to providers outside the European Union (especially the USA), this occurs on the basis of standard contractual clauses or adequacy decisions that you have agreed with the provider.

### B. Offline Catalog Updates (Open Food Facts & Exercise Catalog)

To scan food barcodes offline and look up exercises, Train Libre uses local product and exercise catalogs. These catalogs are downloaded directly to your device as precompiled SQLite database files.

* **How it Works:** The app checks at regular intervals whether updates are available for the food catalog (based on Open Food Facts) or the exercise catalog (based on wger/GitHub). The check and subsequent download of the compressed catalog databases are performed via an encrypted HTTPS connection directly to the servers of the hosting service provider (e.g., GitHub Pages / GitHub Inc. or Open Food Facts).
* **Data Minimization:** When downloading catalog updates, technical connection data (in particular your IP address, date/time of access, and the app's User-Agent) are transmitted to the host as a system requirement. No user-generated data, scanned barcodes, or personal profile characteristics are sent to the catalog hosts at any time.
* **Local Barcode Mapping:** The matching of a scanned barcode or the search for food and exercises takes place 100 percent offline on your device. Unlike conventional nutrition apps, scanning a product does not send a request with the barcode to a cloud server.

---

## 5. Health Data Interfaces

Train Libre can interact with your operating system's system-wide health databases (Apple HealthKit on iOS or Google Health Connect on Android). This interaction takes place exclusively locally on your end device and requires your explicit approval, which can be revoked at any time, in the system settings of the respective operating system.

### A. Data Import (Reading)

If you grant permission to the app, Train Libre reads data from Apple HealthKit or Google Health Connect to display and process it locally within the app:
* **Step Counts:** Import of recorded step count segments for offline evaluation.
* **Sleep Data:** Import of sleep intervals and sleep phases.
* **Heart Rate:** Import of heart rate samples to calculate local hourly aggregations.

The import is used exclusively for display and local analysis within Train Libre. No transfer of this imported data to external servers takes place.

### B. Data Export (Writing & Idempotency)

At your request, Train Libre can export data manually recorded in the app to the system health databases (Apple HealthKit / Google Health Connect):
* **Body Dimensions:** Export of weight measurements.
* **Nutrition and Hydration:** Export of consumed nutritional values, calories, and water amounts.
* **Workouts:** Export of completed training sessions.

* **Local Idempotency Protection:** To prevent duplicate data from being written to your system health database during repeated synchronizations, Train Libre features a local logging system. In the `health_export_records` table of the local SQLite database, a unique ID, the target platform (Apple Health or Health Connect), the data domain, and a unique idempotency key are stored together with the export timestamp for every successful write operation. This comparison takes place purely locally on your device and serves to ensure data consistency.

---

## 6. Data Security & Backups

Since all data resides locally on your end device, the security of the device is critical to protecting your data.

### A. Local Data Isolation

The operating system (iOS/Android) isolates Train Libre's app data using sandbox mechanisms. Other installed applications do not have access to the local SQLite database or the API keys stored in the secured app settings without your consent.

### B. Manual and Automatic Backups

The app offers functions to back up your data in order to prevent data loss in the event of device replacement or damage.

1. **File Generation and Export:** You can generate a complete backup of all data stored in the SQLite database and in the settings. This backup is generated as a structured JSON file in the operating system's temporary storage area and exported via the system's own share menu (Share Sheet). After the export, the temporary file is deleted immediately.
2. **Encryption:** To protect your sensitive data, backups can be encrypted with a password of your choice before export. The encryption is performed locally on the device using strong cryptographic algorithms. Unencrypted backups should always be stored in secure locations.
3. **Automatic Backups:** You can enable automatic backups at configurable intervals. On Android, this feature uses the Storage Access Framework (SAF) to save directly to a target folder selected by you. Alternatively, the file is saved in the local app document directory. These backup files remain on your device unless you actively copy them to an external cloud storage location (e.g., iCloud Drive or Google Drive).
4. **System Backups:** Please note that if system-wide device backups are enabled (e.g., via Apple iCloud or Google Drive Backup), Train Libre's application data will by default be uploaded to the respective cloud by the operating system. This is beyond our control and can be disabled for Train Libre in your device's system settings.

---

## 7. Data Subject Rights

As a data subject, you have extensive rights under the GDPR. Since Train Libre is a local-first app, you can exercise most of these rights directly and independently within the app without depending on our cooperation.

* **Right of Access (Article 15 of the GDPR) & Data Portability (Article 20 of the GDPR):** You have the right to know what data is stored in the app. You can view your entire database yourself at any time and export it in a machine-readable format (JSON file) using the integrated backup export function. You can also export reports in standard formats (such as CSV).
* **Right to Rectification (Article 16 of the GDPR):** You can correct or change all profile data, workouts, nutrition logs, body weights, and settings entered manually by you at any time directly in the app's user interfaces.
* **Right to Erasure / "Right to be Forgotten" (Article 17 of the GDPR):** You can manually delete individual records (e.g., a specific workout or food log) in the app.
* **Irrevocable Data Erasure (AppData Reset):** The app has an integrated deletion function for all local application data. You can execute the complete data deletion function in the settings. This process irrevocably deletes:
  * All SharedPreferences settings and app states.
  * All recorded training logs, custom exercises, and routines.
  * All nutrition logs, meal templates, and custom food items.
  * All entered body measurements, supplement logbooks, and historical daily goals.
  * All locally cached heart rate and sleep analysis stages.
  * All API keys for AI providers stored in the operating system's secure storage.
  
  After executing this function, the app is in its factory default state. Please note that data already exported to Apple Health or Google Health Connect cannot be deleted by this internal app function, as it is under the control of the operating system. However, you can delete this exported data at any time directly in the system's own health apps from Apple or Google.
* **Right to Lodge a Complaint with a Supervisory Authority (Article 77 of the GDPR):** Without prejudice to internal app control options, you have the right to lodge a complaint with a competent data protection supervisory authority. This can be, for example, the supervisory authority of your habitual residence, your place of work, or the place of the alleged infringement (e.g., the Berlin Commissioner for Data Protection and Freedom of Information).
