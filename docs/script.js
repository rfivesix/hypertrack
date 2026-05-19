(() => {
  const TRANSLATIONS = {
    en: {
      nav_features: "Features",
      nav_guidance: "AI Guidance",
      nav_privacy: "Privacy",
      nav_showcase: "Showcase",
      nav_imprint: "Imprint",
      hero_eyebrow: "Offline-first fitness tracking",
      hero_statement: "Own every rep, meal, calorie, and recovery signal.",
      hero_copy: "A private, local-first app for structured workout logging, reviewable AI meal recognition, adaptive calorie guidance, nutrition, hydration, measurements, sleep, pulse, and long-term progress without a mandatory cloud account.",
      hero_cta_ios: "iOS TestFlight Beta",
      hero_cta_android: "Android (Obtainium)",
      hero_point_1: "AI meal recognition",
      hero_point_2: "Adaptive calorie guidance",
      hero_point_3: "Optional BYOK AI",
      hero_point_4: "Local data by default",
      feat_kicker: "Feature Highlights",
      feat_heading: "Built for serious tracking without the noise.",
      feat_copy: "Train Libre keeps the daily surface calm and the underlying data rich, so you can log precisely, review honestly, and understand progress over time.",
      f1_title: "Workout logging that respects training.",
      f1_copy: "Log set by set with routines, warm-ups, working sets, failure sets, dropsets, reps, weight, and RIR.",
      f1_small: "Routines, history, session review",
      f2_title: "Nutrition, hydration, and supplements together.",
      f2_copy: "Track meals, calories, macros, fluids, caffeine, creatine, and custom supplements in one local journal.",
      f2_small: "Food, water, macros, doses",
      f3_title: "Body data with context.",
      f3_copy: "Log bodyweight and measurements, then read them beside nutrition trends and training consistency.",
      f3_small: "Measurements, trends, goals",
      f4_title: "Recovery, sleep, steps, and pulse insights.",
      f4_copy: "Use sleep, steps, heart-rate context, and recovery views where your device data is available.",
      f4_small: "Training guidance, not diagnosis",
      f5_title: "Backups, export, and ownership.",
      f5_copy: "Create local backups, import and export your data, and use one-way health export without making the cloud your source of truth.",
      f5_small: "Local-first control",
      f6_title: "AI meal recognition that stays reviewable.",
      f6_copy: "Capture meals from photos or text, then review portions, food matches, warnings, and locally computed nutrition before saving.",
      f6_small: "Photo, text, grams, review",
      intel_kicker: "AI & Diet Guidance",
      intel_heading: "Helpful intelligence, kept accountable.",
      intel_intro: "Train Libre uses AI where it removes friction, then brings the result back into the app's local data model with review, validation, confidence, and explicit user control.",
      intel_c1_label: "AI meal recognition",
      intel_c1_title: "From plate to log, with a checkpoint.",
      intel_c1_copy: "Snap photos or describe a meal. Train Libre asks your chosen AI provider for food names and gram estimates, then matches them against the local food database and rebuilds calories and macros inside the app.",
      intel_c1_p1: "Photo and text capture",
      intel_c1_p2: "Gram estimates",
      intel_c1_p3: "Local nutrition totals",
      intel_c1_p4: "Editable review",
      intel_c2_label: "Calorie estimation",
      intel_c2_title: "Diet targets that adapt to your real trend.",
      intel_c2_copy: "Train Libre estimates maintenance calories from your profile, logged intake, and smoothed bodyweight trend, then turns that estimate into weekly calorie and macro targets you can apply when ready.",
      intel_c2_p1: "Weekly recommendation",
      intel_c2_p2: "Confidence range",
      intel_c2_p3: "Quality warnings",
      intel_c2_p4: "Manual apply",
      dash_maintenance: "Estimated maintenance",
      dash_maintenance_copy: "Profile prior + recent logs",
      dash_fresh: "Fresh this week",
      dash_kcal: "kcal/day",
      dash_range: "Likely range <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>2480</mn><mtext>–</mtext><mn>2800</mn></mrow><annotation encoding=\"application/x-tex\">2480\text{--}2800</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">2480</span><span class=\"mord text\"><span class=\"mord\">–</span></span><span class=\"mord\">2800</span></span></span></span>",
      dash_confidence: "Medium confidence",
      macro_kcal: "target kcal",
      macro_protein: "protein",
      macro_carbs: "carbs",
      step1: "Smoothed weight trends reduce day-to-day scale noise before calories are adjusted.",
      step2: "Sparse logs, unresolved foods, and early diet-phase swings widen uncertainty instead of oversteering.",
      step3: "Recommendations show warnings and never replace your active goals until you apply them.",
      priv_kicker: "Privacy & Ownership",
      priv_heading: "Your data starts local.",
      priv_copy: "Train Libre is offline-first. Your tracking data is handled locally by default, and there is no mandatory Train Libre cloud account. Sharing, export, health integrations, catalog refreshes, AI meal recognition, and provider calls happen only through features you choose to use.",
      priv_c1_title: "Local by default",
      priv_c1_copy: "Workouts, meals, measurements, and app state are designed around device-local storage.",
      priv_c2_title: "Portable when needed",
      priv_c2_copy: "Backups, imports, exports, and share sheets make data movable without turning it into a hosted account.",
      priv_c3_title: "Clear boundaries",
      priv_c3_copy: "Optional AI and health features separate choices, with your API key and platform permissions in your control.",
      show_kicker: "Product Showcase",
      show_heading: "The actual app, framed with care.",
      show_note: "Dark surfaces, bold typography, glass controls, and restrained color accents carry the same visual language from logging to AI capture to training review.",
      show_c1_title: "Daily diary",
      show_c1_copy: "Nutrition, hydration, supplements, steps, and meals in one calm view.",
      show_c2_title: "Live workout",
      show_c2_copy: "Set-level logging with RIR, rest timing, and session progress.",
      show_c3_title: "AI meal capture",
      show_c3_copy: "Photo or text input becomes reviewable food entries, not a black-box save.",
      open_kicker: "Open & Transparent",
      open_heading: "Public code. Public catalogs. Private logs.",
      open_copy: "Train Libre is available on GitHub and built around understandable data flows rather than opaque tracking loops.",
      open_l1_title: "Developed in public",
      open_l1_copy: "The project source is available on GitHub, with app behavior, catalog tooling, backup logic, and privacy boundaries visible in the repository.",
      open_l2_title: "Open catalog integrations",
      open_l2_copy: "Food and exercise coverage is grounded in public sources, including Open Food Facts and wger-based catalog data.",
      open_l3_title: "Transparent analytics",
      open_l3_copy: "Progress, recovery, consistency, and nutrition insights are meant to be readable, practical, and grounded in the data you logged.",
      footer_medical: "Fitness, nutrition, recovery, and pulse features are for personal tracking and training context, not medical diagnosis or treatment.",
      footer_privacy: "Privacy Policy",
      footer_imprint: "Imprint",
      imp_title: "Legal Notice",
      
      // LEGAL & PRIVACY (Verbatim from assets/legal/privacy_policy.md)
      legal_version: "Version 1.2",
      legal_date: "20. Mai 2026 / May 20, 2026",
      legal_intro: "This privacy policy informs you in accordance with Articles 13 and 14 of the General Data Protection Regulation (GDPR) about the processing of personal data and health-related data in the mobile application \"Train Libre\" and during a visit to this website.<br><br>Since Train Libre is designed as a local-first application, full control over your data remains directly with you at all times. We do not operate any central database or application servers to store your profiles, workouts, or nutrition logs.",
      
      // Legal Notice (English)
      imp_heading: "Legal Notice",
      imp_angaben: "Information according to § 5 DDG:",
      imp_service_provider: "Service Provider / Responsible for the App “Train Libre”:",
      imp_name: "Richard Georg Schotte",
      imp_address: "Bundesallee 114<br>12161 Berlin<br>Germany",
      imp_contact_label: "Contact:",
      imp_email: "E-Mail: feedback@schotte.me",
      imp_phone: "Phone: (+49) 1520 6915571",
      imp_rep_label: "Authorized Representative:",
      imp_rep_val: "Richard Georg Schotte (Sole Developer)",
      imp_vat_label: "VAT-ID:",
      imp_vat_val: "Not available",
      
      // Privacy Policy (English)
      priv_hero_title: "Your data stays with you.",
      priv_hero_copy: "Train Libre is offline-first. All sensitive health data remains exclusively on your device. This policy explains how we handle your data locally and when optional features interact with third-party services.",
      p_last_updated: "As of: May 20, 2026",
      p_1_t: "1. Controller",
      p_1_c1: "The controller for data processing within the meaning of Article 4(7) of the GDPR is the developer and service provider:<br><br><strong>Richard Georg Schotte</strong><br>Bundesallee 114<br>12161 Berlin<br>Germany<br><br>Email: feedback@schotte.me<br>Phone: (+49) 1520 6915571<br><br>Since the controller is an individual developer and the statutory requirements for the mandatory appointment of a data protection officer pursuant to Article 37 of the GDPR and Section 38 of the German Federal Data Protection Act (BDSG) are not met, no separate data protection officer has been appointed. All data protection-related inquiries can be directed directly to the email address provided above.",
      p_2_t: "2. Core Philosophy",
      p_2_c1: "Train Libre is based on the principles of \"privacy by design\" and \"privacy by default\" (Article 25 of the GDPR) as well as the principle of data minimization (Article 5(1)(c) of the GDPR).",
      p_2_l1: "<strong>No User Accounts:</strong> No registration or creation of a user account is required to use the app. No email addresses, passwords, or login credentials are stored on external servers.",
      p_2_l2: "<strong>Local-First Architecture:</strong> All profile settings, athletic activities, nutrition data, vital signs, and measurements entered by you are stored exclusively in a local SQLite database on your own end device.",
      p_2_l3: "<strong>No Central Backend Server:</strong> We do not operate any cloud databases or application servers to store or process your training and nutrition data. Your data remains in your physical possession.",
      p_2_l4: "<strong>No Tracking or Analytics SDKs:</strong> Train Libre completely dispenses with the integration of third-party advertising networks, behavior-based analysis services, or error diagnostics SDKs (such as Firebase Analytics, Google Analytics, Mixpanel, Sentry, or Crashlytics). No profiling or behavior-based evaluation for marketing purposes takes place.",
      p_2_l5: "<strong>Web Hosting & No Cookies (Website Visit):</strong> When you access this website, your web browser connects to the servers of our hosting provider (GitHub Pages / GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA) for technical reasons. In this context, standard, non-identifiable technical server log files (IP address, user-agent, timestamp) are automatically processed to deliver the page. This is based on our legitimate interest in providing a secure and error-free website (Art. 6(1)(f) GDPR). This website does not use cookies, tracking scripts, or analytical tools.",
      p_3_t: "3. Locally Processed Data",
      p_3_c1: "By using the app, your mobile device's operating system processes data in a local SQLite database (Drift/sqflite). This storage is necessary for the operation of the app and to fulfill its core functions.",
      p_3_a_t: "A. Categories of Processed Data",
      p_3_a_c1: "The local database includes the following data categories:",
      p_3_a_l1: "1. <strong>Profile Settings and Goals:</strong> Username, date of birth, body height, gender, profile picture file path, and individually defined daily goals (target calories, target protein, target carbohydrates, target fat, target water, target steps).",
      p_3_a_l2: "2. <strong>Training and Activity Logs (Workouts):</strong> Training plans (routines), exercise templates, historical workout logs (start and end times, notes, exercise sets with rep and weight values, RPE and RIR values, rest times, cardiovascular activities including distance, duration, and calories burned).",
      p_3_a_l3: "3. <strong>Nutrition and Fluid Logs (Nutrition & Fluids):</strong> Consumed food items (timestamp, amount in grams/milliliters, meal type), water and beverage logs (amount, nutrient content, caffeine content).",
      p_3_a_l4: "4. <strong>Food and Product Catalog (User-Products):</strong> Products individually created by the user, including barcode, product name, brand, and macro/micronutrient information per 100g/ml (calories, protein, carbohydrates, fat, sugar, dietary fiber, salt, caffeine, list of ingredients, and additives).",
      p_3_a_l5: "5. <strong>Supplements:</strong> Set up supplements (name, default dose, unit, daily goal, and daily limit) as well as historical supplement log entries with intake timestamp and amount.",
      p_3_a_l6: "6. <strong>Body Dimensions and Measurements (Measurements):</strong> Historical measurement values for body weight and various body circumferences (e.g., chest, waist) including date and unit.",
      p_3_a_l7: "7. <strong>Heart Rate Data Aggregates:</strong> Local hourly aggregations of heart rate (minimum, maximum, and average beats per minute, as well as sample count).",
      p_3_a_l8: "8. <strong>Sleep Data Analyses:</strong> Processed sleep data including sleep phases (deep sleep, REM, light sleep, waking phases), sleep efficiency, resting heart rate, sleep interruptions, sleep regularity, as well as historical raw data imports from system interfaces.",
      p_3_a_l9: "9. <strong>Local Step Segments:</strong> Step counts imported from system interfaces with precise start and end times as well as data source identifiers for local duplicate cleaning.",
      p_3_b_t: "B. Legal Basis for Processing",
      p_3_b_c1: "Since storage and evaluation take place exclusively locally on your end device, control over data protection and data processing remains in your own sphere. Insofar as the app is considered within the scope of the GDPR, the following legal bases apply:",
      p_3_b_l1: "<strong>General Data and Settings (Article 6(1)(b) of the GDPR):</strong> The processing of general profile settings, training plans, and app preferences is carried out to fulfill the user relationship (provision of app functionalities).",
      p_3_b_l2: "<strong>Health Data (Article 9(2)(a) of the GDPR in conjunction with Article 6(1)(a) of the GDPR):</strong> For the processing of physical measurements, heart rate data, sleep analyses, and nutrition logs (which fall under special categories of data as health-related data), you grant your explicit consent by actively entering them or enabling the import. You can withdraw this consent at any time by deleting the corresponding entries or by resetting all app data.",
      p_4_t: "4. Third-Party Integrations / BYOK",
      p_4_c1: "To provide advanced features, the app has interfaces to external services. These functions are optional and require your active participation.",
      p_4_a_t: "A. Bring-Your-Own-Key (BYOK) AI Meal Capture",
      p_4_a_c1: "Train Libre offers the option to analyze meals via photos or free-text descriptions using artificial intelligence. This function is based on the \"Bring-Your-Own-Key\" (BYOK) principle. You must store your own API key from a supported provider in the app to use this.",
      p_4_a_l1: "<strong>Supported Providers:</strong> OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok.",
      p_4_a_l2: "<strong>Secure Local Key Storage:</strong> The API key you enter is stored encrypted using the <code>flutter_secure_storage</code> package in the operating system's secured storage area (iOS Keychain or Android Keystore). The key remains exclusively local to your device and is never transmitted to us.",
      p_4_a_l3: "<strong>Restricted Data Transmission:</strong> When using the AI analysis, your device sends the captured meal photo or entered text description directly via an encrypted HTTPS connection to the API of the selected AI provider.",
      p_4_a_l4: "<strong>Privacy Protection via System Prompt:</strong> To maximize your privacy, the app's globally stored system prompt is configured to instruct the AI provider to identify only food components and estimate their weight in grams. The AI provider is explicitly instructed <strong>not</strong> to perform any nutrient calculations (such as calories, protein, fat, or carbohydrates). The determination of nutrients is then performed completely locally and offline on your device by matching the recognized food names with your local offline catalog. Thus, no personal nutrition or health history is transmitted to the AI services.",
      p_4_a_l5: "<strong>Responsibility:</strong> Since you are using your personal API key, you enter into a direct user relationship with the respective AI provider. Data processing by the AI provider is subject to their respective privacy policies. Please check your provider's privacy policy (especially regarding the use of data for training purposes and server locations) before using the function. For transmissions to providers outside the European Union (especially the USA), this occurs on the basis of standard contractual clauses or adequacy decisions that you have agreed with the provider.",
      p_4_b_t: "B. Offline Catalog Updates (Open Food Facts & Exercise Catalog)",
      p_4_b_c1: "To scan food barcodes offline and look up exercises, Train Libre uses local product and exercise catalogs. These catalogs are downloaded directly to your device as precompiled SQLite database files.",
      p_4_b_l1: "<strong>How it Works:</strong> The app checks at regular intervals whether updates are available for the food catalog (based on Open Food Facts) or the exercise catalog (based on wger/GitHub). The check and subsequent download of the compressed catalog databases are performed via an encrypted HTTPS connection directly to the servers of the hosting service provider (e.g., GitHub Pages / GitHub Inc. or Open Food Facts).",
      p_4_b_l2: "<strong>Data Minimization:</strong> When downloading catalog updates, technical connection data (in particular your IP address, date/time of access, and the app's User-Agent) are transmitted to the host as a system requirement. No user-generated data, scanned barcodes, or personal profile characteristics are sent to the catalog hosts at any time.",
      p_4_b_l3: "<strong>Local Barcode Mapping:</strong> The matching of a scanned barcode or the search for food and exercises takes place 100 percent offline on your device. Unlike conventional nutrition apps, scanning a product does not send a request with the barcode to a cloud server.",
      p_5_t: "5. Health Data Interfaces",
      p_5_c1: "Train Libre can interact with your operating system's system-wide health databases (Apple HealthKit on iOS or Google Health Connect on Android). This interaction takes place exclusively locally on your end device and requires your explicit approval, which can be revoked at any time, in the system settings of the respective operating system.",
      p_5_a_t: "A. Data Import (Reading)",
      p_5_a_c1: "If you grant permission to the app, Train Libre reads data from Apple HealthKit or Google Health Connect to display and process it locally within the app:",
      p_5_a_l1: "<strong>Step Counts:</strong> Import of recorded step count segments for offline evaluation.",
      p_5_a_l2: "<strong>Sleep Data:</strong> Import of sleep intervals and sleep phases.",
      p_5_a_l3: "<strong>Heart Rate:</strong> Import of heart rate samples to calculate local hourly aggregations.",
      p_5_a_c2: "The import is used exclusively for display and local analysis within Train Libre. No transfer of this imported data to external servers takes place.",
      p_5_b_t: "B. Data Export (Writing & Idempotency)",
      p_5_b_c1: "At your request, Train Libre can export data manually recorded in the app to the system health databases (Apple HealthKit / Google Health Connect):",
      p_5_b_l1: "<strong>Body Dimensions:</strong> Export of weight measurements.",
      p_5_b_l2: "<strong>Nutrition and Hydration:</strong> Export of consumed nutritional values, calories, and water amounts.",
      p_5_b_l3: "<strong>Workouts:</strong> Export of completed training sessions.",
      p_5_b_c2: "<strong>Local Idempotency Protection:</strong> To prevent duplicate data from being written to your system health database during repeated synchronizations, Train Libre features a local logging system. In the <code>health_export_records</code> table of the local SQLite database, a unique ID, the target platform (Apple Health or Health Connect), the data domain, and a unique idempotency key are stored together with the export timestamp for every successful write operation. This comparison takes place purely locally on your device and serves to ensure data consistency.",
      p_6_t: "6. Data Security & Backups",
      p_6_c1: "Since all data resides locally on your end device, the security of the device is critical to protecting your data.",
      p_6_a_t: "A. Local Data Isolation",
      p_6_a_c1: "The operating system (iOS/Android) isolates Train Libre's app data using sandbox mechanisms. Other installed applications do not have access to the local SQLite database or the API keys stored in the secured app settings without your consent.",
      p_6_b_t: "B. Manual and Automatic Backups",
      p_6_b_c1: "The app offers functions to back up your data in order to prevent data loss in the event of device replacement or damage.",
      p_6_b_l1: "1. <strong>File Generation and Export:</strong> You can generate a complete backup of all data stored in the SQLite database and in the settings. This backup is generated as a structured JSON file in the operating system's temporary storage area and exported via the system's own share menu (Share Sheet). After the export, the temporary file is deleted immediately.",
      p_6_b_l2: "2. <strong>Encryption:</strong> To protect your sensitive data, backups can be encrypted with a password of your choice before export. The encryption is performed locally on the device using strong cryptographic algorithms. Unencrypted backups should always be stored in secure locations.",
      p_6_b_l3: "3. <strong>Automatic Backups:</strong> You can enable automatic backups at configurable intervals. On Android, this feature uses the Storage Access Framework (SAF) to save directly to a target folder selected by you. Alternatively, the file is saved in the local app document directory. These backup files remain on your device unless you actively copy them to an external cloud storage location (e.g., iCloud Drive or Google Drive).",
      p_6_b_l4: "4. <strong>System Backups:</strong> Please note that if system-wide device backups are enabled (e.g., via Apple iCloud or Google Drive Backup), Train Libre's application data will by default be uploaded to the respective cloud by the operating system. This is beyond our control and can be disabled for Train Libre in your device's system settings.",
      p_7_t: "7. Data Subject Rights",
      p_7_c1: "As a data subject, you have extensive rights under the GDPR. Since Train Libre is a local-first app, you can exercise most of these rights directly and independently within the app without depending on our cooperation.",
      p_7_l1: "<strong>Right of Access (Article 15 of the GDPR) & Data Portability (Article 20 of the GDPR):</strong> You have the right to know what data is stored in the app. You can view your entire database yourself at any time and export it in a machine-readable format (JSON file) using the integrated backup export function. You can also export reports in standard formats (such as CSV).",
      p_7_l2: "<strong>Right to Rectification (Article 16 of the GDPR):</strong> You can correct or change all profile data, workouts, nutrition logs, body weights, and settings entered manually by you at any time directly in the app's user interfaces.",
      p_7_l3: "<strong>Right to Erasure / \"Right to be Forgotten\" (Article 17 of the GDPR):</strong> You can manually delete individual records (e.g., a specific workout or food log) in the app.",
      p_7_l4: "<strong>Irrevocable Data Erasure (AppData Reset):</strong> The app has an integrated deletion function for all local application data. You can execute the complete data deletion function in the settings. This process irrevocably deletes:<br>• All SharedPreferences settings and app states.<br>• All recorded training logs, custom exercises, and routines.<br>• All nutrition logs, meal templates, and custom food items.<br>• All entered body measurements, supplement logbooks, and historical daily goals.<br>• All locally cached heart rate and sleep analysis stages.<br>• All API keys for AI providers stored in the operating system's secure storage.<br><br>After executing this function, the app is in its factory default state. Please note that data already exported to Apple Health or Google Health Connect cannot be deleted by this internal app function, as it is under the control of the operating system. However, you can delete this exported data at any time directly in the system's own health apps from Apple or Google.",
      p_7_l5: "<strong>Right to Lodge a Complaint with a Supervisory Authority (Article 77 of the GDPR):</strong> Without prejudice to internal app control options, you have the right to lodge a complaint with a competent data protection supervisory authority. This can be, for example, the supervisory authority of your habitual residence, your place of work, or the place of the alleged infringement (e.g., the Berlin Commissioner for Data Protection and Freedom of Information).",
      p_cont_t: "Contact",
      
      learn_more: "Learn more",
      evidence_read_more: "Evidence & further reading",
      footer_recovery: "Recovery Tracker",
      recovery_hero_t: "Recovery & Readiness Heuristic",
      recovery_hero_c: "A planning aid that estimates muscle-specific readiness based on training-load accumulation and decay over time.",
      recovery_what_t: "What this system does",
      recovery_what_l1: "Estimates the recovery status of individual muscle groups.",
      recovery_what_l2: "Accounts for primary and secondary muscle involvement (overlapping sets).",
      recovery_what_l3: "Adjusts recovery windows based on proximity to failure (RIR/RPE).",
      recovery_what_l4: "Uses muscle-specific base recovery curves (e.g., lower back vs. delts).",
      recovery_not_t: "What it does NOT do",
      recovery_not_l1: "It does not measure actual physiological biomarkers or CNS fatigue.",
      recovery_not_l2: "It cannot predict injury or account for unlogged pain.",
      recovery_not_l3: "It is not a substitute for subjective feeling or coaching judgment.",
      recovery_how_t: "The Science of Inferred Readiness",
      recovery_how_c1: "The tracker uses an 'Equivalent Set' model. Research (e.g., Vieira et al., 2021) shows that training to failure (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>0</mn><mtext> RIR</mtext></mrow><annotation encoding=\"application/x-tex\">0\text{ RIR}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">0</span><span class=\"mord text\"><span class=\"mord\"> RIR</span></span></span></span></span>) significantly elongates recovery time, sometimes by <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>24</mn><mtext>–</mtext><mn>48</mn><mtext> hours</mtext></mrow><annotation encoding=\"application/x-tex\">24\text{--}48\text{ hours}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">24</span><span class=\"mord text\"><span class=\"mord\">–</span></span><span class=\"mord\">48</span><span class=\"mord text\"><span class=\"mord\"> hours</span></span></span></span></span>, compared to submaximal training.",
      recovery_how_c2: "Train Libre applies this by weighting your working sets. A set at <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>0</mn><mtext> RIR</mtext></mrow><annotation encoding=\"application/x-tex\">0\text{ RIR}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">0</span><span class=\"mord text\"><span class=\"mord\"> RIR</span></span></span></span></span> is flagged as high-fatigue, extending the estimated recovery window. The system also recognizes that compound movements like bench pressing create recovery pressure not just for the chest, but also for the triceps and front delts.",
      recovery_how_c3: "Different muscle groups recover at different rates. Larger, high-load groups (like the quads or lower back) are assigned longer base windows than smaller groups (like the biceps or calves).",
      recovery_limits_t: "Why it is a guide, not a measurement",
      recovery_limits_l1: "Subjectivity: Use the status as a data-informed suggestion. If the app says a muscle is 'Ready' but you feel significant soreness or lethargy, prioritize your body's feedback.",
      recovery_limits_l2: "Novelty: New exercises or sudden volume spikes may cause disproportionate fatigue that the base heuristic may not fully capture.",
      adapt_nut_hero_t: "Adaptive Nutrition Estimation",
      adapt_nut_hero_c: "A recursive estimation system designed to infer maintenance calories (TDEE) from noisy bodyweight and intake data.",
      adapt_nut_what_t: "What this system does",
      adapt_nut_what_l1: "Estimates your maintenance calories (TDEE) based on your real-world progress.",
      adapt_nut_what_l2: "Analyzes bodyweight trends using smoothing to filter out daily noise.",
      adapt_nut_what_l3: "Updates weekly targets conservatively to avoid overreacting to fluctuations.",
      adapt_nut_what_l4: "Provides an uncertainty range based on the consistency of your logged data.",
      adapt_nut_not_t: "What it does NOT do",
      adapt_nut_not_l1: "It is not a replacement for metabolic testing or medical advice.",
      adapt_nut_not_l2: "It cannot predict weight change with 100% precision due to individual variability.",
      adapt_nut_not_l3: "It does not account for illness, travel, or extreme stress unless reflected in your logs.",
      adapt_nut_how_t: "How it works: Bayesian Recursive Estimation",
      adapt_nut_how_c1: "Instead of relying on static formulas like Mifflin-St Jeor—which research shows can be significantly off for individuals—Train Libre treats your metabolism as a dynamic 'hidden state'.",
      adapt_nut_how_c2: "The app uses a Bayesian-inspired recursive estimator (similar to a Kalman filter). Every week, it compares its prediction (based on your intake) with the actual weight trend. It then calculates the 'gain'—deciding how much to trust the new data versus the previous estimate.",
      adapt_nut_how_c3: "To handle the 'noise' of water retention and glycogen shifts, the system uses a <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>7</mn><mtext>-day</mtext></mrow><annotation encoding=\"application/x-tex\">7\text{-day}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8889em;vertical-align:-0.1944em;\"></span><span class=\"mord\">7</span><span class=\"mord text\"><span class=\"mord\">-day</span></span></span></span></span> confirmation rule for goal changes and a phase-dependent scaling factor for energy density (kcal/kg).",
      adapt_nut_limits_t: "Uncertainty & Interpretation",
      adapt_nut_limits_l1: "Trend vs. Noise: The algorithm prioritizes the long-term trend. This means it may feel slow to respond to rapid, short-term changes.",
      adapt_nut_limits_l2: "Logging Consistency: The precision of the estimate depends entirely on the consistency of your logs. Sparse data will result in wider uncertainty ranges.",
      adapt_nut_limits_l3: "Stabilization: During the first <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>2</mn><mtext>–</mtext><mn>4</mn><mtext> weeks</mtext></mrow><annotation encoding=\"application/x-tex\">2\text{--}4\text{ weeks}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">2</span><span class=\"mord text\"><span class=\"mord\">–</span></span><span class=\"mord\">4</span><span class=\"mord text\"><span class=\"mord\"> weeks</span></span></span></span></span>, the system relies on profile 'priors'. It becomes significantly more accurate once it has sufficient user-specific history.",
      ai_meal_hero_t: "AI Meal Recognition",
      ai_meal_hero_c: "A review-first approach to capturing nutrition data using large language models as a proposing layer for local deterministic validation.",
      ai_meal_what_t: "What this feature does",
      ai_meal_what_l1: "Proposes food names and weight estimates from photos or text descriptions.",
      ai_meal_what_l2: "Matches AI suggestions against the app's local database of foods.",
      ai_meal_what_l3: "Calculates nutrition totals locally using matched product data.",
      ai_meal_what_l4: "Provides a manual review interface to edit or reject every entry.",
      ai_meal_not_t: "What it does NOT do",
      ai_meal_not_l1: "It does not provide medical-grade nutrition analysis.",
      ai_meal_not_l2: "It does not automatically 'know' the caloric density of a specific restaurant dish.",
      ai_meal_not_l3: "It does not silently save data without your explicit review and confirmation.",
      ai_meal_how_t: "The Architecture: Local-First & BYOK",
      ai_meal_how_c1: "Train Libre uses a 'Bring Your Own Key' (BYOK) model. You choose a provider and model; the app handles the orchestration. Your data stays local, and the AI is only called when you trigger a capture.",
      ai_meal_how_c2: "Recognition is treated as a noisy proposal. Once the AI returns food names and grams, the app runs a deterministic validation pass. It attempts to repair common errors and flags low-confidence matches before you see the result.",
      ai_meal_limits_t: "Scientific & Technical Limitations",
      ai_meal_limits_l1: "The Volume Problem: A <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>2</mn><mtext>D</mtext></mrow><annotation encoding=\"application/x-tex\">2\text{D}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">2</span><span class=\"mord text\"><span class=\"mord\">D</span></span></span></span></span> photo lacks depth information. Studies show that without a reference object or multiple angles, volume error rates typically range from <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>10</mn><mi mathvariant=\"normal\">%</mi></mrow><annotation encoding=\"application/x-tex\">10\%</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8056em;vertical-align:-0.0556em;\"></span><span class=\"mord\">10%</span></span></span></span> to <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>30</mn><mi mathvariant=\"normal\">%</mi></mrow><annotation encoding=\"application/x-tex\">30\%</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8056em;vertical-align:-0.0556em;\"></span><span class=\"mord\">30%</span></span></span></span>.",
      ai_meal_limits_l2: "Hidden Ingredients: AI cannot 'see' the oils, butter, or sugar used in preparation. A grilled breast and a sautéed one may look identical but differ significantly in caloric density.",
      ai_meal_limits_l3: "Mixed Dishes: Ingredients in dishes like stir-fries or burritos are often occluded. If the rice is under the curry, the AI will likely underestimate the portion.",
      ai_meal_guidance_t: "Practical Guidance",
      ai_meal_guidance_c: "Treat AI capture as a friction-reduction tool, not a ground truth. Always use the review screen to adjust gram estimates and ensure the matched foods align with what you actually ate.",
      nav_overview: "Overview",
      nav_architecture: "Architecture",
      nav_limitations: "Limitations",
      nav_evidence: "Evidence",
      nav_mathematics: "Mathematics",
      nav_science: "Science",
      nav_privacy_philosophy: "Philosophy",
      nav_privacy_local: "Local Data",
      nav_privacy_thirdparty: "BYOK & Services",
      nav_privacy_rights: "Your Rights",
      nav_imp_provider: "Provider",
      nav_imp_contact: "Contact",
      nav_imp_representative: "Representative",
      tdee_deep_c: "Recursive Estimation & Metabolic Smoothing Mechanics",
      tdee_kalman_t: "Recursive Kalman Filtering",
      tdee_kalman_c: "Your metabolic maintenance rate is modeled as a hidden dynamic state <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>x</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">x_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\">x</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:0em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span> and estimated recursively. The system transition is governed by <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>x</mi><mi>t</mi></msub><mo>=</mo><msub><mi>x</mi><mrow><mi>t</mi><mo>−</mo><mn>1</mn></mrow></msub><mo>+</mo><msub><mi>w</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">x_t = x_{t-1} + w_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\">x</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:0em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.7917em;vertical-align:-0.2083em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\">x</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.3011em;\"><span style=\"top:-2.55em;margin-left:0em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mtight\"><span class=\"mord mathnormal mtight\">t</span><span class=\"mbin mtight\">−</span><span class=\"mord mtight\">1</span></span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2083em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span><span class=\"mbin\">+</span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0269em;\">w</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.0269em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span>, where the process noise <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>w</mi><mi>t</mi></msub><mo>∼</mo><mi mathvariant=\"script\">N</mi><mo stretchy=\"false\">(</mo><mn>0</mn><mo separator=\"true\">,</mo><mi>Q</mi><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">w_t \sim \mathcal{N}(0, Q)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0269em;\">w</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.0269em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">∼</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord mathcal\" style=\"margin-right:0.1474em;\">N</span><span class=\"mopen\">(</span><span class=\"mord\">0</span><span class=\"mpunct\">,</span><span class=\"mspace\" style=\"margin-right:0.1667em;\"></span><span class=\"mord mathnormal\">Q</span><span class=\"mclose\">)</span></span></span></span> models metabolic fluctuations.",
      tdee_math_t: "Observed Maintenance Equation",
      tdee_math_c: "The daily observed calorie maintenance (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>M</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">M_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8333em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.109em;\">M</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.109em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span>) is computed using your energy intake and the derivative of your smoothed bodyweight: <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>M</mi><mi>t</mi></msub><mo>=</mo><msub><mtext>avgCalories</mtext><mi>t</mi></msub><mo>−</mo><mo stretchy=\"false\">(</mo><mi mathvariant=\"normal\">Δ</mi><msub><mtext>Weight</mtext><mi>t</mi></msub><mo>×</mo><msub><mtext>kcalPerKg</mtext><mi>t</mi></msub><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">M_t = \text{avgCalories}_t - (\Delta\text{Weight}_t \times \text{kcalPerKg}_t)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8333em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.109em;\">M</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.109em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.9386em;vertical-align:-0.2441em;\"></span><span class=\"mord\"><span class=\"mord text\"><span class=\"mord\">avgCalories</span></span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1864em;\"><span style=\"top:-2.4559em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2441em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span><span class=\"mbin\">−</span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">Δ</span><span class=\"mord\"><span class=\"mord text\"><span class=\"mord\">Weight</span></span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1864em;\"><span style=\"top:-2.4559em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2441em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span><span class=\"mbin\">×</span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord\"><span class=\"mord text\"><span class=\"mord\">kcalPerKg</span></span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1864em;\"><span style=\"top:-2.4559em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2441em;\"><span></span></span></span></span></span></span><span class=\"mclose\">)</span></span></span></span>. We smooth weight scale logs to eliminate daily water retention and glycogen noise.",
      tdee_ramp_t: "9-Week Linear Energetic Ramp",
      tdee_ramp_c: "When starting a diet phase, rapid body mass changes are heavily skewed by non-adipose factors (glycogen depletion, sodium drops). To prevent the estimator from oversteering, the energetic cost of body mass changes (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mi>k</mi><mi>c</mi><mi>a</mi><mi>l</mi><mi>P</mi><mi>e</mi><mi>r</mi><mi>K</mi><msub><mi>g</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">kcalPerKg_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8889em;vertical-align:-0.1944em;\"></span><span class=\"mord mathnormal\" style=\"margin-right:0.0315em;\">k</span><span class=\"mord mathnormal\">c</span><span class=\"mord mathnormal\">a</span><span class=\"mord mathnormal\" style=\"margin-right:0.0197em;\">l</span><span class=\"mord mathnormal\" style=\"margin-right:0.1389em;\">P</span><span class=\"mord mathnormal\" style=\"margin-right:0.0278em;\">er</span><span class=\"mord mathnormal\" style=\"margin-right:0.0715em;\">K</span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0359em;\">g</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.0359em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span>) ramps linearly over <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>9</mn><mtext> weeks</mtext></mrow><annotation encoding=\"application/x-tex\">9\text{ weeks}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">9</span><span class=\"mord text\"><span class=\"mord\"> weeks</span></span></span></span></span> from a prior-driven <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3000</mn><mtext> kcal/kg</mtext></mrow><annotation encoding=\"application/x-tex\">3000\text{ kcal/kg}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord\">3000</span><span class=\"mord text\"><span class=\"mord\"> kcal/kg</span></span></span></span></span> to the fat-tissue-equilibrium value of <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>7700</mn><mtext> kcal/kg</mtext></mrow><annotation encoding=\"application/x-tex\">7700\text{ kcal/kg}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord\">7700</span><span class=\"mord text\"><span class=\"mord\"> kcal/kg</span></span></span></span></span>.",
      tdee_noise_t: "Handling Missing Data (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mi>Q</mi><mo>=</mo><mn>40</mn></mrow><annotation encoding=\"application/x-tex\">Q = 40</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord mathnormal\">Q</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">40</span></span></span></span>)",
      tdee_noise_c: "On days with missing food logs or weight measurements, the measurement update is bypassed. The state covariance <span class=\"math-inline\"><span class=\"math-var\">P<sub>t</sub></span></span> propagates by adding the process noise variance (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mi>Q</mi><mo>=</mo><mn>40</mn></mrow><annotation encoding=\"application/x-tex\">Q = 40</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord mathnormal\">Q</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">40</span></span></span></span>). This increases the uncertainty bounds (Likely Range) in the UI and automatically dampens subsequent updates, preventing sudden weight spikes from distorting your long-term metabolic baseline.",
      adapt_nut_limits_c1: "Daily scale weight is high-noise data. Factors like sodium intake, hydration, and muscle glycogen can cause shifts of several kilograms that do not represent changes in body tissue.",
      ai_meal_deep_c: "Algorithmic Invariants & Local Matching Pipeline",
      ai_meal_privacy_t: "BYOK Privacy Invariant",
      ai_meal_privacy_c: "Your API key is stored securely using the operating system's Keychain (iOS) or Keystore (Android) via <code>flutter_secure_storage</code>. Raw image bytes or text descriptions are sent directly to your chosen AI provider (OpenAI, Anthropic, Gemini, Mistral, xAI) via TLS 1.3. No intermediate Train Libre server exists. Personal user profiles, weight history, and targets never leave your device.",
      ai_meal_matching_t: "Local Deterministic Matching",
      ai_meal_matching_c: "The AI operates only as a proposing layer. Once the model outputs food names and raw gram estimates, Train Libre matches these proposals against the local SQLite database (compiled from Open Food Facts and wger) using a tokenized Jaro-Winkler fuzzy matching scoring engine (validation threshold <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>D</mi><mi>v</mi></msub><mo>≥</mo><mn>0.82</mn></mrow><annotation encoding=\"application/x-tex\">D_v \ge 0.82</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8333em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0278em;\">D</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1514em;\"><span style=\"top:-2.55em;margin-left:-0.0278em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\" style=\"margin-right:0.0359em;\">v</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">≥</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">0.82</span></span></span></span>). If the match confidence is low, a local warning is flagged.",
      ai_meal_retry_t: "<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3</mn><mtext>-Pass</mtext></mrow><annotation encoding=\"application/x-tex\">3\text{-Pass}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">3</span><span class=\"mord text\"><span class=\"mord\">-Pass</span></span></span></span></span> Self-Repair Retry Loop",
      ai_meal_retry_c: "To counter structural LLM hallucinations, the app runs a local <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3</mn><mtext>-Pass</mtext></mrow><annotation encoding=\"application/x-tex\">3\text{-Pass}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">3</span><span class=\"mord text\"><span class=\"mord\">-Pass</span></span></span></span></span> self-repair routine: <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mo stretchy=\"false\">(</mo><mn>1</mn><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">(1)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">1</span><span class=\"mclose\">)</span></span></span></span> <strong>Structured Extraction</strong>: forces JSON output using strict schemas; <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mo stretchy=\"false\">(</mo><mn>2</mn><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">(2)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">2</span><span class=\"mclose\">)</span></span></span></span> <strong>Quantity Normalization</strong>: standardizes qualitative descriptors (e.g., 'a splash of milk', 'one medium slice') into metric grams; <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mo stretchy=\"false\">(</mo><mn>3</mn><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">(3)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">3</span><span class=\"mclose\">)</span></span></span></span> <strong>Syntactic Repair</strong>: attempts regex-based extraction of malformed JSON arrays before initiating up to <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3</mn></mrow><annotation encoding=\"application/x-tex\">3</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">3</span></span></span></span> automated localized retries.",
      ai_meal_ban_t: "Strict Nutrient Computation Ban",
      ai_meal_ban_c: "The AI is programmatically banned from calculating calories, macros, or nutritional totals (enforced via system instructions). All macro arithmetic is calculated 100% locally and offline on your device using verified food catalog densities. This prevents your health status from leaking to LLMs and ensures perfect mathematical consistency (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>1</mn><mtext>g Protein</mtext><mo>=</mo><mn>4</mn><mtext> kcal</mtext></mrow><annotation encoding=\"application/x-tex\">1\text{g Protein} = 4\text{ kcal}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord\">1</span><span class=\"mord text\"><span class=\"mord\">g Protein</span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">4</span><span class=\"mord text\"><span class=\"mord\"> kcal</span></span></span></span></span>, <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>1</mn><mtext>g Carb</mtext><mo>=</mo><mn>4</mn><mtext> kcal</mtext></mrow><annotation encoding=\"application/x-tex\">1\text{g Carb} = 4\text{ kcal}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8889em;vertical-align:-0.1944em;\"></span><span class=\"mord\">1</span><span class=\"mord text\"><span class=\"mord\">g Carb</span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">4</span><span class=\"mord text\"><span class=\"mord\"> kcal</span></span></span></span></span>, <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>1</mn><mtext>g Fat</mtext><mo>=</mo><mn>9</mn><mtext> kcal</mtext></mrow><annotation encoding=\"application/x-tex\">1\text{g Fat} = 9\text{ kcal}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord\">1</span><span class=\"mord text\"><span class=\"mord\">g Fat</span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">9</span><span class=\"mord text\"><span class=\"mord\"> kcal</span></span></span></span></span>).",
      ai_meal_limits_c1: "Research into computer-vision-based nutrition estimation highlights several fundamental hurdles that make 100% accuracy impossible for consumer apps:",
      rec_deep_c: "Three-Layer Architecture & Composite Indices",
      rec_schema_t: "Three-Layer Sleep Schema",
      rec_schema_c: "Sleep data processing is segmented into three distinct layers: (1) <strong>Raw Time-Series Ingestion</strong> from Apple HealthKit or Google Health Connect; (2) <strong>Local Validation & Duplicate Resolution</strong> of overlapping sleep intervals using wearable priority hierarchies; (3) <strong>Composite Index Computation</strong> performed offline.",
      rec_score_t: "Sleep Health Score V2",
      rec_score_c: "Calculates a composite score based on sleep efficiency (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mfrac><mtext>time asleep</mtext><mtext>time in bed</mtext></mfrac></mrow><annotation encoding=\"application/x-tex\">\frac{\text{time asleep}}{\text{time in bed}}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1.2772em;vertical-align:-0.345em;\"></span><span class=\"mord\"><span class=\"mopen nulldelimiter\"></span><span class=\"mfrac\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.9322em;\"><span style=\"top:-2.655em;\"><span class=\"pstrut\" style=\"height:3em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mtight\"><span class=\"mord text mtight\"><span class=\"mord mtight\">time in bed</span></span></span></span></span><span style=\"top:-3.23em;\"><span class=\"pstrut\" style=\"height:3em;\"></span><span class=\"frac-line\" style=\"border-bottom-width:0.04em;\"></span></span><span style=\"top:-3.4461em;\"><span class=\"pstrut\" style=\"height:3em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mtight\"><span class=\"mord text mtight\"><span class=\"mord mtight\">time asleep</span></span></span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.345em;\"><span></span></span></span></span></span><span class=\"mclose nulldelimiter\"></span></span></span></span></span>), WASO (Wake After Sleep Onset - tracking structural disruptions), and the Sleep Regularity Index (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mtext>SRI</mtext></mrow><annotation encoding=\"application/x-tex\">\text{SRI}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord text\"><span class=\"mord\">SRI</span></span></span></span></span>), which measures the probability of being in the same state (asleep/awake) at any two time points <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>24</mn><mtext> hours</mtext></mrow><annotation encoding=\"application/x-tex\">24\text{ hours}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">24</span><span class=\"mord text\"><span class=\"mord\"> hours</span></span></span></span></span> apart.",
      rec_pulse_t: "Hourly Pulse Aggregation",
      rec_pulse_c: "Queries raw high-frequency heart rate samples, removes outliers via local z-scoring, and aggregates them into <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>1</mn><mtext>-hour</mtext></mrow><annotation encoding=\"application/x-tex\">1\text{-hour}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">1</span><span class=\"mord text\"><span class=\"mord\">-hour</span></span></span></span></span> blocks (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mo stretchy=\"false\">[</mo><mtext>timestamp</mtext><mo separator=\"true\">,</mo><mtext>min_bpm</mtext><mo separator=\"true\">,</mo><mtext>max_bpm</mtext><mo separator=\"true\">,</mo><mtext>avg_bpm</mtext><mo separator=\"true\">,</mo><mtext>sample_count</mtext><mo stretchy=\"false\">]</mo></mrow><annotation encoding=\"application/x-tex\">[\text{timestamp}, \text{min\_bpm}, \text{max\_bpm}, \text{avg\_bpm}, \text{sample\_count}]</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1.06em;vertical-align:-0.31em;\"></span><span class=\"mopen\">[</span><span class=\"mord text\"><span class=\"mord\">timestamp</span></span><span class=\"mpunct\">,</span><span class=\"mspace\" style=\"margin-right:0.1667em;\"></span><span class=\"mord text\"><span class=\"mord\">min_bpm</span></span><span class=\"mpunct\">,</span><span class=\"mspace\" style=\"margin-right:0.1667em;\"></span><span class=\"mord text\"><span class=\"mord\">max_bpm</span></span><span class=\"mpunct\">,</span><span class=\"mspace\" style=\"margin-right:0.1667em;\"></span><span class=\"mord text\"><span class=\"mord\">avg_bpm</span></span><span class=\"mpunct\">,</span><span class=\"mspace\" style=\"margin-right:0.1667em;\"></span><span class=\"mord text\"><span class=\"mord\">sample_count</span></span><span class=\"mclose\">]</span></span></span></span>). This reduces storage space by <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>98</mn><mi mathvariant=\"normal\">%</mi></mrow><annotation encoding=\"application/x-tex\">98\%</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8056em;vertical-align:-0.0556em;\"></span><span class=\"mord\">98%</span></span></span></span> while retaining diagnostic pulse-rate curves for sleep analysis and resting heart rate (RHR) trends.",
      recovery_limits_c1: "Logged data is a proxy for training stress. The heuristic cannot 'see' external factors like sleep debt, nutritional deficiencies, or systemic life stress unless they are manually logged or integrated via health services."
    },
    de: {
      nav_features: "Funktionen",
      nav_guidance: "KI-Unterstützung",
      nav_privacy: "Datenschutz",
      nav_showcase: "Vorschau",
      nav_imprint: "Impressum",
      hero_eyebrow: "Privates Workout- & Ernährungs-Tracking",
      hero_statement: "Keine Werbung. Kein Konto. Seriöse Analysen.",
      hero_copy: "Eine private, offline-zuerst Fitness-App für Workouts, Kalorien, Makros, Körpergewicht und Regeneration – ohne Werbung, Kontozwang oder Analyse-SDKs.",
      hero_cta_ios: "iOS TestFlight Beta",
      hero_cta_android: "Android (via Obtainium)",
      hero_point_1: "Workout- & Makro-Tracker",
      hero_point_2: "Privatsphäre / Offline-first",
      hero_point_3: "Keine Werbung oder Konten",
      hero_point_4: "Optionale KI-Mahlzeit-Tools",
      feat_kicker: "Highlights",
      feat_heading: "Echtes Tracking ohne Ablenkung.",
      feat_copy: "Train Libre fokussiert sich auf das Wesentliche: präzise Protokollierung, ehrliche Analyse und sichtbarer Fortschritt.",
      f1_title: "Workout-Tracker.",
      f1_copy: "Dokumentiere jeden Satz im Detail – inklusive Aufwärmsätzen, Dropsets und RIR-Tracking für volle Transparenz.",
      f1_small: "Trainingspläne, Historie, Auswertung",
      f2_title: "Kalorien- & Makro-Tracker.",
      f2_copy: "Erfasse Mahlzeiten, Kalorien, Makros und Supplemente wie Kreatin oder Koffein in einem gemeinsamen Journal.",
      f2_small: "Nährwerte, Wasser, Supplementierung",
      f3_title: "Körpergewicht- & Regenerations-Analysen.",
      f3_copy: "Verfolge dein Körpergewicht und deine Maße direkt neben Ernährungstrends und Trainingskonstanz.",
      f3_small: "Messwerte, Trends, Zielsetzung",
      f4_title: "Regeneration & Vitalwerte.",
      f4_copy: "Integriere Schlaf-, Schritt- und Herzfrequenzdaten für ein ganzheitliches Bild deiner Erholung.",
      f4_small: "Information, keine Diagnose",
      f5_title: "Echte Datenhoheit.",
      f5_copy: "Erstelle lokale Backups und nutze den Health-Export, ohne jemals die Kontrolle über deine Daten abzugeben.",
      f5_small: "Offline-first Architektur",
      f6_title: "Optionale KI-Mahlzeit-Tools.",
      f6_copy: "Erfasse Mahlzeiten per Foto oder Text und prüfe jeden Eintrag lokal, bevor er gespeichert wird. Nutzergesteuert via BYOK.",
      f6_small: "Foto, Text, Review, Präzision",
      intel_kicker: "Intelligente Planung",
      intel_heading: "KI-Unterstützung unter deiner Kontrolle.",
      intel_intro: "Train Libre nutzt KI dort, wo sie echten Mehrwert bietet. Alle Ergebnisse landen erst nach deiner Prüfung im lokalen Logbuch.",
      intel_c1_label: "Mahlzeitenerkennung",
      intel_c1_title: "Vom Teller direkt ins Logbuch",
      intel_c1_copy: "Nutze Fotos oder Beschreibungen deiner Mahlzeiten. Die KI schätzt Portionen, die du flexibel anpassen kannst.",
      intel_c1_p1: "Foto- & Texterfassung",
      intel_c1_p2: "Portionsschätzungen",
      intel_c1_p3: "Lokale Nährwertsummen",
      intel_c1_p4: "Anpassbarer Review",
      intel_c2_label: "Kalorien-Anpassung",
      intel_c2_title: "Ziele, die sich dir anpassen",
      intel_c2_copy: "Basierend auf deinen Logs und Gewichtstrends berechnet die App deine Erhaltungskalorien und gibt Empfehlungen.",
      intel_c2_p1: "Wöchentliche Ziele",
      intel_c2_p2: "Konfidenz-Bereich",
      intel_c2_p3: "Qualitätswarnungen",
      intel_c2_p4: "Manuelle Übernahme",
      dash_maintenance: "Erhaltungskalorien",
      dash_maintenance_copy: "Profil-Prior + aktuelle Logs",
      dash_fresh: "Aktuell für diese Woche",
      dash_kcal: "kcal/Tag",
      dash_range: "Bereich: <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>2480</mn><mtext>–</mtext><mn>2800</mn></mrow><annotation encoding=\"application/x-tex\">2480\text{--}2800</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">2480</span><span class=\"mord text\"><span class=\"mord\">–</span></span><span class=\"mord\">2800</span></span></span></span>",
      dash_confidence: "Mittleres Vertrauen",
      macro_kcal: "Ziel-Kalorien",
      macro_protein: "Protein",
      macro_carbs: "Kohlenhydrate",
      step1: "Geglättete Trends reduzieren tägliche Schwankungen vor der Kalorienanpassung.",
      step2: "Lückenhafte Logs führen zu breiteren Unsicherheitsbereichen statt Fehlsteuerungen.",
      step3: "Empfehlungen sind Vorschläge und ersetzen niemals deine Ziele ohne Bestätigung.",
      priv_kicker: "Datenschutz",
      priv_heading: "Privat durch Design.",
      priv_copy: "Train Libre ist offline-first. Deine Daten bleiben standardmäßig auf deinem Gerät. Keine Werbung, keine Analyse-SDKs und kein Kontozwang.",
      priv_c1_title: "Lokal auf deinem Gerät",
      priv_c1_copy: "Workouts, Mahlzeiten und Messungen verbleiben standardmäßig lokal auf deinem Smartphone.",
      priv_c2_title: "Portabel & Flexibel",
      priv_c2_copy: "Nutze Backups und Exporte, um deine Daten jederzeit zu sichern oder zu übertragen.",
      priv_c3_title: "Klare Trennung",
      priv_c3_copy: "KI- und Health-Funktionen sind optional und liegen voll in deiner Hand.",
      show_kicker: "Vorschau",
      show_heading: "Modernes Design für ambitioniertes Tracking.",
      show_note: "Dunkle Oberflächen und klare Typografie sorgen für ein fokussiertes Nutzererlebnis.",
      show_c1_title: "Das Tagebuch",
      show_c1_copy: "Ernährung, Training und Vitalwerte in einer aufgeräumten Übersicht.",
      show_c2_title: "Live-Aufzeichnung",
      show_c2_copy: "Präzises Logging während des Trainings – inklusive Pausentimer.",
      show_c3_title: "KI-Eingabe",
      show_c3_copy: "Schnelle Mahlzeitenerfassung mit anschließender Kontrolle.",
      open_kicker: "Open Source",
      open_heading: "Offener Code. Private Daten.",
      open_copy: "Train Libre ist Open Source. Wir setzen auf Transparenz statt auf undurchsichtige Algorithmen.",
      open_l1_title: "Quellcode einsehbar",
      open_l1_copy: "Die App wird öffentlich auf GitHub entwickelt. Das Verhalten ist für jeden prüfbar.",
      open_l2_title: "Offene Datenbanken",
      open_l2_copy: "Wir nutzen öffentliche Quellen wie Open Food Facts und wger für unsere Kataloge.",
      open_l3_title: "Logische Analyse",
      open_l3_copy: "Fortschritts-Analysen basieren auf logischen Modellen, die du nachvollziehen kannst.",
      footer_medical: "Fitness-, Ernährungs- und Vitalwerte dienen der Information und ersetzen keine medizinische Diagnose.",
      footer_privacy: "Datenschutz",
      footer_imprint: "Impressum",
      imp_title: "Impressum",

      // LEGAL & PRIVACY (Verbatim from assets/legal/privacy_policy.md)
      legal_version: "Version 1.2",
      legal_date: "20. Mai 2026 / May 20, 2026",
      legal_intro: "Diese Datenschutzerklärung informiert Sie gemäß Art. 13 und 14 der Datenschutz-Grundverordnung (DSGVO) über die Verarbeitung personenbezogener Daten und gesundheitsbezogener Daten in der mobilen Applikation „Train Libre“ sowie beim Besuch dieser Website.<br><br>Da Train Libre als Local-First-Applikation konzipiert ist, verbleibt die vollständige Kontrolle über Ihre Daten zu jedem Zeitpunkt direkt bei Ihnen. Wir betreiben keine zentralen Datenbank- oder Anwendungsserver zur Speicherung Ihrer Profile, Workouts oder Ernährungsprotokolle.",
      
      // Impressum (Deutsch)
      imp_heading: "Impressum (Anbieterkennzeichnung)",
      imp_angaben: "Angaben gemäß § 5 DDG:",
      imp_service_provider: "Diensteanbieter / Verantwortlich für die App „Train Libre“:",
      imp_name: "Richard Georg Schotte",
      imp_address: "Bundesallee 114<br>12161 Berlin<br>Deutschland",
      imp_contact_label: "Kontakt:",
      imp_email: "E-Mail: feedback@schotte.me",
      imp_phone: "Telefon: (+49) 1520 6915571",
      imp_rep_label: "Vertretungsberechtigte Person:",
      imp_rep_val: "Richard Georg Schotte (Einzelentwickler)",
      imp_vat_label: "Umsatzsteuer-ID:",
      imp_vat_val: "Nicht vorhanden",

      // Datenschutzerklärung (Deutsch)
      priv_hero_title: "Deine Daten bleiben bei dir.",
      priv_hero_copy: "Train Libre ist eine Offline-First-App. Alle sensiblen Gesundheitsdaten verbleiben ausschließlich lokal auf deinem Gerät. Diese Erklärung informiert dich über die Verarbeitung deiner Daten.",
      p_last_updated: "Stand: 20. Mai 2026",
      p_1_t: "1. Verantwortlicher",
      p_1_c1: "Verantwortlich für die Datenverarbeitung im Sinne des Art. 4 Nr. 7 DSGVO ist der Entwickler und Diensteanbieter:<br><br><strong>Richard Georg Schotte</strong><br>Bundesallee 114<br>12161 Berlin<br>Deutschland<br><br>E-Mail: feedback@schotte.me<br>Telefon: (+49) 1520 6915571<br><br>Da es sich bei dem Verantwortlichen um einen Einzelentwickler handelt und die gesetzlichen Voraussetzungen zur verpflichtenden Bestellung eines Datenschutzbeauftragten gemäß Art. 37 DSGVO bzw. § 38 BDSG nicht vorliegen, ist kein gesonderter Datenschutzbeauftragter bestellt. Sämtliche datenschutzbezogene Anfragen können direkt an die oben genannte E-Mail-Adresse gerichtet werden.",
      p_2_t: "2. Grundphilosophie",
      p_2_c1: "Train Libre beruht auf dem Prinzip des „Privacy by Design“ und des „Privacy by Default“ (Art. 25 DSGVO) sowie auf dem Grundsatz der Datensparsamkeit (Art. 5 Abs. 1 lit. c DSGVO).",
      p_2_l1: "<strong>Keine Benutzerkonten:</strong> Für die Nutzung der App ist keine Registrierung und kein Erstellen eines Benutzerkontos erforderlich. Es werden keine E-Mail-Adressen, Passwörter oder Anmeldedaten auf externen Servern gespeichert.",
      p_2_l2: "<strong>Local-First-Architektur:</strong> Sämtliche von Ihnen eingegebenen Profileinstellungen, sportlichen Aktivitäten, Ernährungsdaten, Vitalwerte und Messungen werden ausschließlich in einer lokalen SQLite-Datenbank auf Ihrem eigenen Endgerät gespeichert.",
      p_2_l3: "<strong>Kein zentraler Backend-Server:</strong> Wir betreiben keine Cloud-Datenbanken und keine Anwendungsserver zur Speicherung oder Verarbeitung Ihrer Trainings- und Ernährungsdaten. Ihre Daten verbleiben in Ihrem physischen Besitz.",
      p_2_l4: "<strong>Keine Tracking- oder Analyse-SDKs:</strong> Train Libre verzichtet vollständig auf die Integration von Werbenetzwerken, verhaltensbasierten Analyse-Diensten oder Fehlerdiagnose-SDKs von Drittanbietern (wie beispielsweise Firebase Analytics, Google Analytics, Mixpanel, Sentry oder Crashlytics). Es findet keinerlei Profilbildung oder verhaltensbezogene Auswertung zu Marketingzwecken statt.",
      p_2_l5: "<strong>Web-Hosting & keine Cookies (Website-Besuch):</strong> Beim Aufruf dieser Website stellt Ihr Webbrowser technisch bedingt eine Verbindung zu den Servern des Hosting-Dienstleisters (GitHub Pages / GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA) her. Hierbei werden standardmäßige, nicht identifizierbare technische Server-Logfiles (IP-Adresse, User-Agent, Zeitstempel) automatisch verarbeitet, um die Website auszuliefern. Dies erfolgt auf Grundlage unseres berechtigten Interesses an einer sicheren und fehlerfreien Bereitstellung der Webseite (Art. 6 Abs. 1 lit. f DSGVO). Diese Website verwendet keine Cookies, keine Tracking-Skripte und keine Analyse-Werkzeuge.",
      p_3_t: "3. Lokal verarbeitete Daten",
      p_3_c1: "Durch die Nutzung der App verarbeitet das Betriebssystem Ihres Mobilgeräts Daten in einer lokalen SQLite-Datenbank (Drift/sqflite). Die Speicherung dient dem Betrieb der App und der Erfüllung der Kernfunktionen.",
      p_3_a_t: "A. Kategorien verarbeiteter Daten",
      p_3_a_c1: "Die lokale Datenbank umfasst folgende Datenkategorien:",
      p_3_a_l1: "1. <strong>Profileinstellungen und Ziele:</strong> Benutzername, Geburtsdatum, Körpergröße, Geschlecht, Profilbild-Dateipfad sowie individuell festgelegte Tagesziele (Ziel-Kalorien, Ziel-Proteine, Ziel-Kohlenhydrate, Ziel-Fett, Ziel-Wasser, Ziel-Schritte).",
      p_3_a_l2: "2. <strong>Trainings- und Aktivitätsprotokolle (Workouts):</strong> Trainingspläne (Routinen), Übungsvorlagen, historische Workout-Protokolle (Start- und Endzeit, Notizen, Übungssätze mit rep- und Gewicht-Werten, RPE- und RIR-Werten, Pausenzeiten, kardiovaskuläre Aktivitäten inklusive Distanz, Dauer und verbrannten Kalorien).",
      p_3_a_l3: "3. <strong>Ernährungs- und Flüssigkeitsprotokolle (Nutrition & Fluids):</strong> Konsumierte Lebensmittel (Zeitpunkt, Menge in Gramm/Millilitern, Mahlzeitentyp), Wasser- und Getränkeprotokolle (Menge, Nährstoffgehalt, Koffeingehalt).",
      p_3_a_l4: "4. <strong>Lebensmittel- und Produktkatalog (User-Products):</strong> Individuell vom Benutzer angelegte Produkte mit Barcode, Produktname, Marke und Makro-/Mikronährwertangaben pro 100g/ml (Kalorien, Eiweiß, Kohlenhydrate, Fett, Zucker, Ballaststoffe, Salz, Koffein, Zutatenliste und Zusatzstoffe).",
      p_3_a_l5: "5. <strong>Supplemente (Nahrungsergänzungsmittel):</strong> Eingerichtete Supplemente (Name, Standarddosis, Einheit, Tagesziel und Tageslimit) sowie historische Supplement-Logeinträge mit Einnahme-Zeitpunkt und Menge.",
      p_3_a_l6: "6. <strong>Körpermaße und Messungen (Measurements):</strong> Historische Messwerte für das Körpergewicht und verschiedene Körperumfänge (z. B. Brust, Taille) inklusive Datum und Einheit.",
      p_3_a_l7: "7. <strong>Pulsdaten-Aggregate:</strong> Lokale stündliche Aggregationen der Herzfrequenz (minimale, maximale und durchschnittliche Schläge pro Minute sowie Stichprobenanzahl).",
      p_3_a_l8: "8. <strong>Schlafdaten-Analysen:</strong> Aufbereitete Schlafdaten inklusive Schlafphasen (Tiefschlaf, REM, Leichtschlaf, Wachphasen), Schlaf-Effizienz, Ruheherzfrequenz, Schlafunterbrechungen, Schlaf-Regularität sowie historische Rohdaten-Importe aus den System-Schnittstellen.",
      p_3_a_l9: "9. <strong>Lokale Schrittsegmente:</strong> Aus den System-Schnittstellen importierte Schrittzahlen mit genauen Start- und Endzeitpunkten sowie Kennungen der Datenquelle zur lokalen Bereinigung von Dubletten.",
      p_3_b_t: "B. Rechtsgrundlagen der Verarbeitung",
      p_3_b_c1: "Da die Speicherung und Auswertung ausschließlich lokal auf Ihrem Endgerät stattfindet, liegt die datenschutzrechtliche Verfügungsgewalt und Datenverarbeitung in Ihrer eigenen Sphäre. Soweit die App im Rahmen der DSGVO betrachtet wird, gelten folgende Rechtsgrundlagen:",
      p_3_b_l1: "<strong>Allgemeine Daten und Einstellungen (Art. 6 Abs. 1 lit. b DSGVO):</strong> Die Verarbeitung allgemeiner Profileinstellungen, Trainingspläne und App-Präferenzen erfolgt zur Erfüllung des Nutzungsverhältnisses (Bereitstellung der App-Funktionalitäten).",
      p_3_b_l2: "<strong>Gesundheitsdaten (Art. 9 Abs. 2 lit. a DSGVO in Verbindung mit Art. 6 Abs. 1 lit. a DSGVO):</strong> Für die Verarbeitung von körperlichen Messwerten, Pulsdaten, Schlafanalysen und Ernährungsprotokollen (welche als gesundheitsbezogene Daten unter die besonderen Kategorien fallen) erteilen Sie mit der aktiven Eingabe bzw. der Aktivierung des Imports Ihre ausdrückliche Einwilligung. Sie können diese Einwilligung jederzeit durch Löschen der entsprechenden Einträge oder durch Zurücksetzen aller App-Daten widerrufen.",
      p_4_t: "4. Drittanbieter-Integrationen / BYOK",
      p_4_c1: "Um erweiterte Funktionen bereitzustellen, verfügt die App über Schnittstellen zu externen Diensten. Diese Funktionen sind optional und erfordern Ihre aktive Mitwirkung.",
      p_4_a_t: "A. Bring-Your-Own-Key (BYOK) AI Meal Capture",
      p_4_a_c1: "Train Libre bietet die Möglichkeit, Mahlzeiten über Fotos oder Freitextbeschreibungen mittels Künstlicher Intelligenz analysieren zu lassen. Diese Funktion basiert auf dem „Bring-Your-Own-Key“-Prinzip (BYOK). Sie müssen hierfür Ihren eigenen API-Schlüssel eines unterstützten Anbieters in der App hinterlegen.",
      p_4_a_l1: "<strong>Unterstützte Anbieter:</strong> OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok.",
      p_4_a_l2: "<strong>Sichere lokale Schlüsselverwahrung:</strong> Der von Ihnen eingegebene API-Schlüssel wird unter Verwendung des Pakets <code>flutter_secure_storage</code> verschlüsselt im gesicherten Speicherbereich des Betriebssystems abgelegt (iOS Keychain bzw. Android Keystore). Der Schlüssel verbleibt ausschließlich lokal auf Ihrem Gerät und wird niemals an uns übertragen.",
      p_4_a_l3: "<strong>Eingeschränkte Datenübertragung:</strong> Bei der Nutzung der KI-Analyse sendet Ihr Gerät das aufgenommene Mahlzeiten-Foto bzw. die eingegebene Textbeschreibung direkt über eine verschlüsselte HTTPS-Verbindung an die API des ausgewählten KI-Anbieters.",
      p_4_a_l4: "<strong>Privatsphärenschutz per System-Prompt:</strong> Um Ihre Privatsphäre maximal zu schützen, ist der systemweit hinterlegte Prompt der App so konfiguriert, dass der KI-Anbieter angewiesen wird, ausschließlich Lebensmittelkomponenten zu identifizieren und deren Gewicht in Gramm zu schätzen. Der KI-Anbieter wird ausdrücklich angewiesen, <strong>keine</strong> Nährwertberechnungen (wie Kalorien, Proteine, Fett oder Kohlenhydrate) durchzuführen. Die Ermittlung der Nährwerte erfolgt im Anschluss vollständig lokal offline auf Ihrem Gerät durch Abgleich der erkannten Lebensmittelnamen mit Ihrem lokalen Offline-Katalog. Es wird somit keine persönliche Ernährungs- oder Gesundheitshistorie an die KI-Dienste übermittelt.",
      p_4_a_l5: "<strong>Verantwortlichkeit:</strong> Da Sie Ihren persönlichen API-Schlüssel verwenden, schließen Sie direkt ein Nutzungsverhältnis mit dem jeweiligen KI-Anbieter ab. Die Datenverarbeitung durch den KI-Anbieter unterliegt dessen jeweiligen Datenschutzbestimmungen. Bitte prüfen Sie die Datenschutzrichtlinien Ihres Anbieters (insbesondere bezüglich der Datenverwendung für Trainingszwecke und der Serverstandorte), bevor Sie die Funktion nutzen. Bei Übertragungen an Anbieter außerhalb der Europäischen Union (insbesondere in die USA) erfolgt dies auf Grundlage von Standardvertragsklauseln oder Angemessenheitsbeschlüssen, die Sie mit dem Anbieter vereinbart haben.",
      p_4_b_t: "B. Offline-Katalog-Updates (Open Food Facts & Exercise Catalog)",
      p_4_b_c1: "Um Lebensmittel-Barcodes offline scannen und Übungen nachschlagen zu können, nutzt Train Libre lokale Produkt- und Übungskataloge. Diese Kataloge werden als vorkompilierte SQLite-Datenbankdateien direkt auf Ihr Gerät heruntergeladen.",
      p_4_b_l1: "<strong>Funktionsweise:</strong> Die App prüft in regelmäßigen Abständen, ob Aktualisierungen für den Lebensmittelkatalog (basierend auf Open Food Facts) oder den Übungskatalog (basierend auf wger/GitHub) vorliegen. Die Prüfung und der anschließende Download der komprimierten Katalogdatenbanken erfolgen über eine verschlüsselte HTTPS-Verbindung direkt zu den Servern des Hosting-Dienstleisters (z. B. GitHub Pages / GitHub Inc. bzw. Open Food Facts).",
      p_4_b_l2: "<strong>Datenminimierung:</strong> Beim Herunterladen der Katalog-Updates werden systembedingt technische Verbindungsdaten (insbesondere Ihre IP-Adresse, Datum/Uhrzeit des Zugriffs und der User-Agent der App) an den Hoster übertragen. Es werden zu keinem Zeitpunkt nutzergenerierte Daten, gescannte Barcodes oder persönliche Profileigenschaften an die Katalog-Hoster gesendet.",
      p_4_b_l3: "<strong>Lokale Barcode-Zuordnung:</strong> Der Abgleich eines gescannten Barcodes oder die Suche nach Lebensmitteln und Übungen findet zu 100 Prozent offline auf Ihrem Gerät statt. Im Gegensatz zu herkömmlichen Ernährungs-Apps wird beim Scannen eines Produkts keine Anfrage mit dem Barcode an einen Cloud-Server gesendet.",
      p_5_t: "5. Gesundheitsdaten-Schnittstellen",
      p_5_c1: "Train Libre kann mit den systemweiten Gesundheitsdatenbanken Ihres Betriebssystems (Apple HealthKit unter iOS bzw. Google Health Connect unter Android) interagieren. Diese Interaktion erfolgt ausschließlich lokal auf Ihrem Endgerät und erfordert Ihre ausdrückliche, jederzeit widerrufbare Freigabe in den Systemeinstellungen des jeweiligen Betriebssystems.",
      p_5_a_t: "A. Daten-Import (Lesen)",
      p_5_a_c1: "Sofern Sie der App die Berechtigung erteilen, liest Train Libre Daten aus Apple HealthKit bzw. Google Health Connect aus, um diese lokal in der App anzuzeigen und zu verarbeiten:",
      p_5_a_l1: "<strong>Schrittzahlen:</strong> Import der aufgezeichneten Schrittzahlsegmente zur Offline-Auswertung.",
      p_5_a_l2: "<strong>Schlafdaten:</strong> Import von Schlafzeiträumen und Schlafphasen.",
      p_5_a_l3: "<strong>Herzfrequenz:</strong> Import von Puls-Stichproben zur Berechnung lokaler stündlicher Aggregationen.",
      p_5_a_c2: "Der Import dient ausschließlich der Darstellung und lokalen Analyse innerhalb von Train Libre. Es findet kein Transfer dieser importierten Daten an externe Server statt.",
      p_5_b_t: "B. Daten-Export (Schreiben & Idempotenz)",
      p_5_b_c1: "Auf Ihren Wunsch hin kann Train Libre manuell in der App erfasste Daten in die System-Gesundheitsdatenbanken (Apple HealthKit / Google Health Connect) exportieren:",
      p_5_b_l1: "<strong>Körpermaße:</strong> Export von Gewichtsmessungen.",
      p_5_b_l2: "<strong>Ernährung und Hydration:</strong> Export von konsumierten Nährwerten, Kalorien und Wassermengen.",
      p_5_b_l3: "<strong>Workouts:</strong> Export von abgeschlossenen Trainingseinheiten.",
      p_5_b_c2: "<strong>Lokaler Idempotenz-Schutz:</strong> Um zu verhindern, dass bei wiederholten Synchronisationen Daten mehrfach in Ihre System-Gesundheitsdatenbank geschrieben werden, verfügt Train Libre über ein lokales Protokollierungssystem. In der Tabelle <code>health_export_records</code> der lokalen SQLite-Datenbank wird für jeden erfolgreichen Schreibvorgang eine eindeutige ID, die Ziel-Plattform (Apple Health oder Health Connect), der Datenbereich (Domain) sowie ein eindeutiger Idempotenzschlüssel zusammen mit dem Export-Zeitstempel gespeichert. Dieser Abgleich findet rein lokal auf Ihrem Gerät statt und dient der Sicherstellung der Datenkonsistenz.",
      p_6_t: "6. Datensicherheit & Backups",
      p_6_c1: "Da sämtliche Daten lokal auf Ihrem Endgerät liegen, ist die Sicherheit des Geräts maßgeblich für den Schutz Ihrer Daten.",
      p_6_a_t: "A. Lokale Datenisolation",
      p_6_a_c1: "Das Betriebssystem (iOS/Android) isoliert die App-Daten von Train Libre durch Sandbox-Mechanismen. Andere installierte Applikationen haben ohne Ihre Zustimmung keinen Zugriff auf die lokale SQLite-Datenbank oder die in den gesicherten App-Einstellungen hinterlegten API-Schlüssel.",
      p_6_b_t: "B. Manuelle und automatische Backups",
      p_6_b_c1: "Die App bietet Ihnen Funktionen zur Sicherung Ihrer Daten, um Datenverlust bei Gerätewechsel oder -beschädigung vorzubeugen.",
      p_6_b_l1: "1. <strong>Dateigenerierung und Export:</strong> Sie können ein vollständiges Backup aller in der SQLite-Datenbank sowie in den Einstellungen gespeicherten Daten erzeugen. Dieses Backup wird als strukturierte JSON-Datei im temporären Speicherbereich des Betriebssystems generiert und über das systemeigene Teilen-Menü (Share Sheet) exportiert. Nach dem Export wird die temporäre Datei unverzüglich gelöscht.",
      p_6_b_l2: "2. <strong>Verschlüsselung:</strong> Zum Schutz Ihrer sensiblen Daten können Backups vor dem Export mit einem von Ihnen gewählten Passwort verschlüsselt werden. Die Verschlüsselung erfolgt lokal auf dem Gerät mittels starker kryptografischer Algorithmen. Unverschlüsselte Backups sollten stets an sicheren Speicherorten aufbewahrt werden.",
      p_6_b_l3: "3. <strong>Automatische Backups:</strong> Sie können automatische Backups in konfigurierbaren Intervallen aktivieren. Unter Android nutzt diese Funktion das Storage Access Framework (SAF) zur direkten Ablage in einem von Ihnen ausgewählten Zielordner. Alternativ erfolgt die Ablage im lokalen App-Dokumentenverzeichnis. Diese Backup-Dateien verbleiben auf Ihrem Gerät, es sei denn, Sie kopieren sie aktiv an einen externen Cloud-Speicherort (z. B. iCloud Drive oder Google Drive).",
      p_6_b_l4: "4. <strong>System-Backups:</strong> Bitte beachten Sie, dass bei aktivierten systemweiten Geräte-Backups (z. B. über Apple iCloud oder Google Drive Backup) die Anwendungsdaten von Train Libre standardmäßig vom Betriebssystem in die jeweilige Cloud hochgeladen werden. Dies liegt außerhalb unseres Einflussbereichs und kann in den Systemeinstellungen Ihres Geräts für Train Libre deaktiviert werden.",
      p_7_t: "7. Betroffenenrechte",
      p_7_c1: "Als betroffene Person stehen Ihnen im Rahmen der DSGVO weitreichende Rechte zu. Da Train Libre eine Local-First-App ist, können Sie den Großteil dieser Rechte direkt und selbstbestimmt innerhalb der App ausüben, ohne auf unsere Mitwirkung angewiesen zu sein.",
      p_7_l1: "<strong>Recht auf Auskunft (Art. 15 DSGVO) & Datenübertragbarkeit (Art. 20 DSGVO):</strong> Sie haben das Recht zu erfahren, welche Daten in der App gespeichert sind. Sie können Ihre vollständige Datenbank zeitnah selbst einsehen und über die integrierte Backup-Exportfunktion in einem maschinenlesbaren Format (JSON-Datei) exportieren. Zudem können Sie Berichte in Standardformaten (wie CSV) exportieren.",
      p_7_l2: "<strong>Recht auf Berichtigung (Art. 16 DSGVO):</strong> Sie können sämtliche von Ihnen manuell erfassten Profildaten, Workouts, Ernährungsprotokolle, Körpergewichte und Einstellungen jederzeit direkt in den Benutzeroberflächen der App korrigieren oder ändern.",
      p_7_l3: "<strong>Recht auf Löschung / „Recht auf Vergessenwerden“ (Art. 17 DSGVO):</strong> Sie können einzelne Datensätze (z. B. ein bestimmtes Workout oder ein Lebensmittel-Log) manuell in der App löschen.",
      p_7_l4: "<strong>Unwiderrufliche Datenlöschung (AppData Reset):</strong> Die App verfügt über eine integrierte Löschfunktion für alle lokalen Anwendungsdaten. In den Einstellungen können Sie die Funktion zur vollständigen Datenlöschung ausführen. Dieser Prozess löscht unwiderruflich:<br>• Alle SharedPreferences-Einstellungen und App-Zustände.<br>• Alle aufgezeichneten Trainingsprotokolle, benutzerdefinierten Übungen und Routinen.<br>• Alle Ernährungsprotokolle, Mahlzeitenvorlagen und benutzerdefinierten Lebensmittel.<br>• Alle eingetragenen Körpermaße, Supplement-Logbücher und historischen Tagesziele.<br>• Sämtliche lokal zwischengespeicherten Puls- und Schlafanalysestufen.<br>• Alle in der sicheren Betriebssystem-Ablage hinterlegten API-Schlüssel für KI-Anbieter.<br><br>Nach Ausführung dieser Funktion befindet sich die App im Auslieferungszustand. Bitte beachten Sie, dass bereits an Apple Health oder Google Health Connect exportierte Daten durch diese appinterne Funktion nicht gelöscht werden können, da diese in der Hoheit des Betriebssystems liegen. Sie können diese exportierten Daten jedoch jederzeit direkt in den systemeigenen Health-Apps von Apple oder Google löschen.",
      p_7_l5: "<strong>Recht auf Beschwerde bei einer Aufsichtsbehörde (Art. 77 DSGVO):</strong> Unbeschadet der appinternen Kontrollmöglichkeiten haben Sie das Recht, Beschwerde bei einer zuständigen Datenschutz-Aufsichtsbehörde einzulegen. Dies kann beispielsweise die Aufsichtsbehörde Ihres üblichen Aufenthaltsortes, Ihres Arbeitsplatzes oder des Sitzes des Verantwortlichen sein (z. B. die Berliner Beauftragte für Datenschutz und Informationsfreiheit).",
      p_cont_t: "Kontakt",
      
      learn_more: "Mehr erfahren",
      evidence_read_more: "Evidenz & Quellen",
      footer_recovery: "Regenerations-Tracker",
      recovery_hero_t: "Regenerations-Heuristik",
      recovery_hero_c: "Eine Planungshilfe, die die muskelspezifische Bereitschaft basierend auf Trainingsbelastung und Erholung über die Zeit schätzt.",
      recovery_what_t: "Was dieses System leistet",
      recovery_what_l1: "Schätzt den Regenerationsstatus einzelner Muskelgruppen.",
      recovery_what_l2: "Berücksichtigt primäre und sekundäre Muskelbeteiligung (überlappende Sätze).",
      recovery_what_l3: "Passt Regenerationsfenster basierend auf der Nähe zum Versagen (RIR/RPE) an.",
      recovery_what_l4: "Nutzt muskelspezifische Basis-Regenerationskurven (z. B. unterer Rücken vs. Schultern).",
      recovery_not_t: "Was es NICHT leistet",
      recovery_not_l1: "Es misst keine tatsächlichen physiologischen Biomarker oder ZNS-Ermüdung.",
      recovery_not_l2: "Es kann keine Verletzungen vorhersagen oder nicht protokollierte Schmerzen berücksichtigen.",
      recovery_not_l3: "Es ist kein Ersatz für das subjektive Empfinden oder Trainer-Urteil.",
      recovery_how_t: "Die Wissenschaft hinter der geschätzten Bereitschaft",
      recovery_how_c1: "Der Tracker nutzt ein 'Equivalent Set'-Modell. Studien (z. B. Vieira et al., 2021) zeigen, dass Training bis zum Versagen (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>0</mn><mtext> RIR</mtext></mrow><annotation encoding=\"application/x-tex\">0\text{ RIR}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">0</span><span class=\"mord text\"><span class=\"mord\"> RIR</span></span></span></span></span>) die Regenerationszeit signifikant verlängert, teils um <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>24</mn><mtext>–</mtext><mn>48</mn><mtext> Stunden</mtext></mrow><annotation encoding=\"application/x-tex\">24\text{--}48\text{ Stunden}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">24</span><span class=\"mord text\"><span class=\"mord\">–</span></span><span class=\"mord\">48</span><span class=\"mord text\"><span class=\"mord\"> Stunden</span></span></span></span></span> im Vergleich zu submaximalem Training.",
      recovery_how_c2: "Train Libre gewichtet Arbeitssätze entsprechend. Ein Satz mit <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>0</mn><mtext> RIR</mtext></mrow><annotation encoding=\"application/x-tex\">0\text{ RIR}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">0</span><span class=\"mord text\"><span class=\"mord\"> RIR</span></span></span></span></span> wird als hochgradig ermüdend markiert, was das geschätzte Regenerationsfenster erweitert. Das System erkennt zudem, dass Verbundübungen wie Bankdrücken nicht nur die Brust, sondern auch Trizeps und vordere Schultern belasten.",
      recovery_how_c3: "Verschiedene Muskelgruppen regenerieren unterschiedlich schnell. Große, hoch belastbare Gruppen (wie Quads oder unterer Rücken) haben längere Basis-Fenster als kleinere Gruppen (wie Bizeps oder Waden).",
      recovery_limits_t: "Warum es ein Leitfaden ist, keine Messung",
      recovery_limits_l1: "Subjektivität: Nutze den Status als datengestützten Vorschlag. Wenn die App 'Bereit' anzeigt, du dich aber erschöpft fühlst, priorisiere dein Körpergefühl.",
      recovery_limits_l2: "Neuheit: Neue Übungen oder plötzliche Volumensteigerungen können überproportionale Ermüdung verursachen, die die Basis-Heuristik eventuell nicht voll erfasst.",
      adapt_nut_hero_t: "Adaptive Ernährungs-Schätzung",
      adapt_nut_hero_c: "Ein rekursives Schätzsystem, das Erhaltungskalorien (TDEE) aus Körpergewichts- und Aufnahmedaten ableitet.",
      adapt_nut_what_t: "Was dieses System leistet",
      adapt_nut_what_l1: "Schätzt deine Erhaltungskalorien (TDEE) basierend auf deinem tatsächlichen Fortschritt.",
      adapt_nut_what_l2: "Analysiert Gewichtstrends mittels Glättung, um tägliche Schwankungen zu filtern.",
      adapt_nut_what_l3: "Aktualisiert wöchentliche Ziele konservativ, um Überreaktionen auf Schwankungen zu vermeiden.",
      adapt_nut_what_l4: "Gibt einen Unsicherheitsbereich basierend auf der Konsistenz deiner Daten an.",
      adapt_nut_not_t: "Was es NICHT leistet",
      adapt_nut_not_l1: "Es ist kein Ersatz für Stoffwechseluntersuchungen oder medizinischen Rat.",
      adapt_nut_not_l2: "Es kann Gewichtsänderungen aufgrund individueller Variabilität nicht mit 100% Präzision vorhersagen.",
      adapt_nut_not_l3: "Krankheit, Reisen oder extremer Stress werden nur berücksichtigt, wenn sie sich in deinen Logs widerspiegeln.",
      adapt_nut_how_t: "Funktionsweise: Bayesian Recursive Estimation",
      adapt_nut_how_c1: "Statt auf statische Formeln wie Mifflin-St Jeor zu setzen – die laut Forschung bei Individuen stark abweichen können – betrachtet Train Libre deinen Stoffwechsel als dynamischen 'Hidden State'.",
      adapt_nut_how_c2: "Die App nutzt einen Bayesian-inspirierten rekursiven Schätzer (ähnlich einem Kalman-Filter). Jede Woche wird die Vorhersage mit dem tatsächlichen Trend verglichen. Das System berechnet den 'Gain' – also wie sehr den neuen Daten gegenüber der bisherigen Schätzung vertraut wird.",
      adapt_nut_how_c3: "Um das 'Rauschen' durch Wassereinlagerungen und Glykogenspringer zu handhaben, nutzt das System eine <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>7</mn><mrow><mtext>-Tage-Best</mtext><mover accent=\"true\"><mtext>a</mtext><mo>¨</mo></mover><mtext>tigungsregel</mtext></mrow></mrow><annotation encoding=\"application/x-tex\">7\text{-Tage-Bestätigungsregel}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8889em;vertical-align:-0.1944em;\"></span><span class=\"mord\">7</span><span class=\"mord text\"><span class=\"mord\">-Tage-Best</span><span class=\"mord accent\"><span class=\"vlist-t\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.6679em;\"><span style=\"top:-3em;\"><span class=\"pstrut\" style=\"height:3em;\"></span><span class=\"mord\">a</span></span><span style=\"top:-3em;\"><span class=\"pstrut\" style=\"height:3em;\"></span><span class=\"accent-body\" style=\"left:-0.25em;\"><span class=\"mord\">¨</span></span></span></span></span></span></span><span class=\"mord\">tigungsregel</span></span></span></span></span> für Zieländerungen und phasenspezifische Skalierungsfaktoren für die Energiedichte (kcal/kg).",
      adapt_nut_limits_t: "Unsicherheit & Interpretation",
      adapt_nut_limits_l1: "Trend vs. Rauschen: Der Algorithmus priorisiert den langfristigen Trend. Er reagiert daher eventuell verzögert auf schnelle, kurzfristige Änderungen.",
      adapt_nut_limits_l2: "Logging-Konsistenz: Die Präzision der Schätzung hängt vollständig von der Konsistenz deiner Aufzeichnungen ab. Lückenhafte Daten führen zu breiteren Unsicherheitsbereichen.",
      adapt_nut_limits_l3: "Stabilisierung: In den ersten <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>2</mn><mtext>–</mtext><mn>4</mn><mtext> Wochen</mtext></mrow><annotation encoding=\"application/x-tex\">2\text{--}4\text{ Wochen}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">2</span><span class=\"mord text\"><span class=\"mord\">–</span></span><span class=\"mord\">4</span><span class=\"mord text\"><span class=\"mord\"> Wochen</span></span></span></span></span> stützt sich das System auf Profil-Startwerte (Priors). Es wird signifikant genauer, sobald ausreichend nutzerspezifische Historie vorliegt.",
      ai_meal_hero_t: "KI-Mahlzeitenerkennung",
      ai_meal_hero_c: "Ein prüfbasierter Ansatz zur Erfassung von Ernährungsdaten, der Large Language Models als Vorschlagsebene für lokale Validierung nutzt.",
      ai_meal_what_t: "Was diese Funktion leistet",
      ai_meal_what_l1: "Schlägt Lebensmittelnamen und Gewichte anhand von Fotos oder Textbeschreibungen vor.",
      ai_meal_what_l2: "Gleicht KI-Vorschläge mit der lokalen Lebensmitteldatenbank der App ab.",
      ai_meal_what_l3: "Berechnet Nährwertsummen lokal unter Verwendung der gematchten Produktdaten.",
      ai_meal_what_l4: "Bietet eine manuelle Review-Oberfläche, um jeden Eintrag zu bearbeiten oder abzulehnen.",
      ai_meal_not_t: "Was sie NICHT leistet",
      ai_meal_not_l1: "Sie bietet keine medizinisch fundierte Ernährungsanalyse.",
      ai_meal_not_l2: "Sie 'weiß' nicht automatisch die Kaloriendichte eines spezifischen Restaurantgerichts.",
      ai_meal_not_l3: "Sie speichert keine Daten ohne deine explizite Prüfung und Bestätigung.",
      ai_meal_how_t: "Die Architektur: Local-First & BYOK",
      ai_meal_how_c1: "Train Libre nutzt ein 'Bring Your Own Key' (BYOK) Modell. Du wählst Anbieter und Modell; die App übernimmt die Orchestrierung. Deine Daten bleiben lokal, und die KI wird nur bei einer Erfassung aufgerufen.",
      ai_meal_how_c2: "Erkennung wird als unscharfer Vorschlag behandelt. Sobald die KI Ergebnisse liefert, führt die App eine deterministische Validierung durch. Sie versucht Fehler zu korrigieren und markiert unsichere Treffer.",
      ai_meal_limits_t: "Wissenschaftliche & technische Grenzen",
      ai_meal_limits_l1: "Das Volumen-Problem: Ein <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>2</mn><mtext>D-Foto</mtext></mrow><annotation encoding=\"application/x-tex\">2\text{D-Foto}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">2</span><span class=\"mord text\"><span class=\"mord\">D-Foto</span></span></span></span></span> hat keine Tiefeninformationen. Studien zeigen, dass ohne Referenzobjekt die Fehlerraten beim Volumen meist zwischen <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>10</mn><mi mathvariant=\"normal\">%</mi></mrow><annotation encoding=\"application/x-tex\">10\%</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8056em;vertical-align:-0.0556em;\"></span><span class=\"mord\">10%</span></span></span></span> und <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>30</mn><mi mathvariant=\"normal\">%</mi></mrow><annotation encoding=\"application/x-tex\">30\%</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8056em;vertical-align:-0.0556em;\"></span><span class=\"mord\">30%</span></span></span></span> liegen.",
      ai_meal_limits_l2: "Versteckte Zutaten: Die KI kann Öle, Butter oder Zucker nicht 'sehen'. Ein gegrilltes Hähnchen und ein in Fett gebratenes können identisch aussehen, unterscheiden sich aber massiv in der Kaloriendichte.",
      ai_meal_limits_l3: "Mischgerichte: Zutaten in Pfannengerichten oder Burritos sind oft verdeckt. Wenn der Reis unter dem Curry liegt, wird die KI die Portion wahrscheinlich unterschätzen.",
      ai_meal_guidance_t: "Praktische Hinweise",
      ai_meal_guidance_c: "Betrachte die KI-Erfassung als Werkzeug zur Reibungsreduzierung, nicht als absolute Wahrheit. Nutze immer den Review-Screen, um Schätzungen anzupassen.",
      nav_overview: "Übersicht",
      nav_architecture: "Architektur",
      nav_limitations: "Grenzen",
      nav_evidence: "Quellen",
      nav_mathematics: "Mathematik",
      nav_science: "Wissenschaft",
      nav_privacy_philosophy: "Philosophie",
      nav_privacy_local: "Lokale Daten",
      nav_privacy_thirdparty: "BYOK & Dienste",
      nav_privacy_rights: "Ihre Rechte",
      nav_imp_provider: "Anbieter",
      nav_imp_contact: "Kontakt",
      nav_imp_representative: "Vertretung",
      tdee_deep_c: "Rekursive Schätzung & Stoffwechsel-Glättungsmechanismen",
      tdee_kalman_t: "Rekursive Kalman-Filterung",
      tdee_kalman_c: "Deine tatsächliche Erhaltungsrate wird als verborgener dynamischer Zustand <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>x</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">x_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\">x</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:0em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span> modelliert und rekursiv geschätzt. Die Zustandsänderung folgt der Gleichung <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>x</mi><mi>t</mi></msub><mo>=</mo><msub><mi>x</mi><mrow><mi>t</mi><mo>−</mo><mn>1</mn></mrow></msub><mo>+</mo><msub><mi>w</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">x_t = x_{t-1} + w_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\">x</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:0em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.7917em;vertical-align:-0.2083em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\">x</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.3011em;\"><span style=\"top:-2.55em;margin-left:0em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mtight\"><span class=\"mord mathnormal mtight\">t</span><span class=\"mbin mtight\">−</span><span class=\"mord mtight\">1</span></span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2083em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span><span class=\"mbin\">+</span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0269em;\">w</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.0269em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span>, wobei das Prozessrauschen <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>w</mi><mi>t</mi></msub><mo>∼</mo><mi mathvariant=\"script\">N</mi><mo stretchy=\"false\">(</mo><mn>0</mn><mo separator=\"true\">,</mo><mi>Q</mi><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">w_t \sim \mathcal{N}(0, Q)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.5806em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0269em;\">w</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.0269em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">∼</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord mathcal\" style=\"margin-right:0.1474em;\">N</span><span class=\"mopen\">(</span><span class=\"mord\">0</span><span class=\"mpunct\">,</span><span class=\"mspace\" style=\"margin-right:0.1667em;\"></span><span class=\"mord mathnormal\">Q</span><span class=\"mclose\">)</span></span></span></span> physiologische Schwankungen darstellt.",
      tdee_math_t: "Beobachtete Erhaltungs-Gleichung",
      tdee_math_c: "Die täglich gemessene Erhaltungsenergie (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>M</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">M_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8333em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.109em;\">M</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.109em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span>) wird aus der Energiezufuhr und der Ableitung deines geglätteten Gewichts berechnet: <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>M</mi><mi>t</mi></msub><mo>=</mo><msub><mtext>avgCalories</mtext><mi>t</mi></msub><mo>−</mo><mo stretchy=\"false\">(</mo><mi mathvariant=\"normal\">Δ</mi><msub><mtext>Weight</mtext><mi>t</mi></msub><mo>×</mo><msub><mtext>kcalPerKg</mtext><mi>t</mi></msub><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">M_t = \text{avgCalories}_t - (\Delta\text{Weight}_t \times \text{kcalPerKg}_t)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8333em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.109em;\">M</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.109em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.9386em;vertical-align:-0.2441em;\"></span><span class=\"mord\"><span class=\"mord text\"><span class=\"mord\">avgCalories</span></span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1864em;\"><span style=\"top:-2.4559em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2441em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span><span class=\"mbin\">−</span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">Δ</span><span class=\"mord\"><span class=\"mord text\"><span class=\"mord\">Weight</span></span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1864em;\"><span style=\"top:-2.4559em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2441em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span><span class=\"mbin\">×</span><span class=\"mspace\" style=\"margin-right:0.2222em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord\"><span class=\"mord text\"><span class=\"mord\">kcalPerKg</span></span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1864em;\"><span style=\"top:-2.4559em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2441em;\"><span></span></span></span></span></span></span><span class=\"mclose\">)</span></span></span></span>. Gewichtseinträge werden geglättet, um tägliche Wasser- und Glykogen-Schwankungen herauszufiltern.",
      tdee_ramp_t: "9-wöchige lineare energetische Rampe",
      tdee_ramp_c: "Zu Beginn einer Diätphase werden schnelle Gewichtsänderungen stark durch Nicht-Fettgewebe-Faktoren (Glykogenentleerung, Natriumverlust) beeinflusst. Um ein Übersteuern der Schätzung zu verhindern, steigt der energetische Äquivalenzwert (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mi>k</mi><mi>c</mi><mi>a</mi><mi>l</mi><mi>P</mi><mi>e</mi><mi>r</mi><mi>K</mi><msub><mi>g</mi><mi>t</mi></msub></mrow><annotation encoding=\"application/x-tex\">kcalPerKg_t</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8889em;vertical-align:-0.1944em;\"></span><span class=\"mord mathnormal\" style=\"margin-right:0.0315em;\">k</span><span class=\"mord mathnormal\">c</span><span class=\"mord mathnormal\">a</span><span class=\"mord mathnormal\" style=\"margin-right:0.0197em;\">l</span><span class=\"mord mathnormal\" style=\"margin-right:0.1389em;\">P</span><span class=\"mord mathnormal\" style=\"margin-right:0.0278em;\">er</span><span class=\"mord mathnormal\" style=\"margin-right:0.0715em;\">K</span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0359em;\">g</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.2806em;\"><span style=\"top:-2.55em;margin-left:-0.0359em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\">t</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span></span></span></span>) über <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>9</mn><mtext> Wochen</mtext></mrow><annotation encoding=\"application/x-tex\">9\text{ Wochen}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">9</span><span class=\"mord text\"><span class=\"mord\"> Wochen</span></span></span></span></span> linear von anfangs <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3000</mn><mtext> kcal/kg</mtext></mrow><annotation encoding=\"application/x-tex\">3000\text{ kcal/kg}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord\">3000</span><span class=\"mord text\"><span class=\"mord\"> kcal/kg</span></span></span></span></span> auf den stabilen Fettgewebe-Standardwert von <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>7700</mn><mtext> kcal/kg</mtext></mrow><annotation encoding=\"application/x-tex\">7700\text{ kcal/kg}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mord\">7700</span><span class=\"mord text\"><span class=\"mord\"> kcal/kg</span></span></span></span></span> an.",
      tdee_noise_t: "Umgang mit fehlenden Daten (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mi>Q</mi><mo>=</mo><mn>40</mn></mrow><annotation encoding=\"application/x-tex\">Q = 40</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord mathnormal\">Q</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">40</span></span></span></span>)",
      tdee_noise_c: "An Tagen ohne Ernährungs- oder Gewichtseinträge wird das Messungs-Update übersprungen. Die Zustandskovarianz <span class=\"math-inline\"><span class=\"math-var\">P<sub>t</sub></span></span> erhöht sich durch Addition des Prozessrauschens (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mi>Q</mi><mo>=</mo><mn>40</mn></mrow><annotation encoding=\"application/x-tex\">Q = 40</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord mathnormal\">Q</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">40</span></span></span></span>). Dies vergrößert die Unsicherheitsbereiche in der UI und dämpft nachfolgende Updates automatisch, sodass kurzzeitige Gewichtssprünge die langfristige Stoffwechsel-Baseline nicht verzerren.",
      adapt_nut_limits_c1: "Das tägliche Körpergewicht ist ein sehr verrauschter Messwert. Faktoren wie Natriumzufuhr, Hydration und Muskelglykogen können Schwankungen von mehreren Kilogramm verursachen, die keine echten Gewebsveränderungen darstellen.",
      ai_meal_deep_c: "Algorithmische Invarianten & Lokale Matching-Pipeline",
      ai_meal_privacy_t: "BYOK-Datenschutz-Invariante",
      ai_meal_privacy_c: "Dein API-Schlüssel wird unter Verwendung von <code>flutter_secure_storage</code> sicher in der Keychain (iOS) oder dem Keystore (Android) deines Betriebssystems gespeichert. Rohe Bilddaten oder Textbeschreibungen werden über eine verschlüsselte Verbindung (TLS 1.3) direkt an den gewählten Anbieter (OpenAI, Anthropic, Gemini, Mistral, xAI) gesendet. Es existiert kein zwischengeschalteter Train Libre Server. Persönliche Profile, Gewichtsverlauf und Zielvorgaben verlassen niemals dein Gerät.",
      ai_meal_matching_t: "Lokales deterministisches Matching",
      ai_meal_matching_c: "Die KI arbeitet lediglich als Vorschlagsebene. Sobald das Modell Lebensmittelnamen und rohe Gewichtsschätzungen liefert, gleicht Train Libre diese mit der lokalen SQLite-Datenbank (kompiliert aus Open Food Facts und wger) über eine tokenbasierte Jaro-Winkler-Fuzzy-Matching-Engine (Schwellenwert <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><msub><mi>D</mi><mi>v</mi></msub><mo>≥</mo><mn>0.82</mn></mrow><annotation encoding=\"application/x-tex\">D_v \ge 0.82</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8333em;vertical-align:-0.15em;\"></span><span class=\"mord\"><span class=\"mord mathnormal\" style=\"margin-right:0.0278em;\">D</span><span class=\"msupsub\"><span class=\"vlist-t vlist-t2\"><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.1514em;\"><span style=\"top:-2.55em;margin-left:-0.0278em;margin-right:0.05em;\"><span class=\"pstrut\" style=\"height:2.7em;\"></span><span class=\"sizing reset-size6 size3 mtight\"><span class=\"mord mathnormal mtight\" style=\"margin-right:0.0359em;\">v</span></span></span></span><span class=\"vlist-s\">​</span></span><span class=\"vlist-r\"><span class=\"vlist\" style=\"height:0.15em;\"><span></span></span></span></span></span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">≥</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">0.82</span></span></span></span>) ab. Bei geringer Konfidenz wird eine lokale Warnung ausgegeben.",
      ai_meal_retry_t: "<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3</mn><mtext>-Pass</mtext></mrow><annotation encoding=\"application/x-tex\">3\text{-Pass}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6833em;\"></span><span class=\"mord\">3</span><span class=\"mord text\"><span class=\"mord\">-Pass</span></span></span></span></span>-Self-Repair-Retry-Schleife",
      ai_meal_retry_c: "Um strukturellen LLM-Halluzinationen entgegenzuwirken, führt die App eine lokale <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3</mn><mtext>-Pass-Self-Repair-Routine</mtext></mrow><annotation encoding=\"application/x-tex\">3\text{-Pass-Self-Repair-Routine}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8889em;vertical-align:-0.1944em;\"></span><span class=\"mord\">3</span><span class=\"mord text\"><span class=\"mord\">-Pass-Self-Repair-Routine</span></span></span></span></span> aus: <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mo stretchy=\"false\">(</mo><mn>1</mn><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">(1)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">1</span><span class=\"mclose\">)</span></span></span></span> <strong>Strukturierte Extraktion</strong>: erzwingt JSON-Ausgaben durch strikte Schemata; <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mo stretchy=\"false\">(</mo><mn>2</mn><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">(2)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">2</span><span class=\"mclose\">)</span></span></span></span> <strong>Mengen-Normalisierung</strong>: standardisiert qualitative Beschreibungen (z. B. 'ein Schuss Milch', 'eine mittlere Scheibe') in metrische Gramm; <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mo stretchy=\"false\">(</mo><mn>3</mn><mo stretchy=\"false\">)</mo></mrow><annotation encoding=\"application/x-tex\">(3)</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:1em;vertical-align:-0.25em;\"></span><span class=\"mopen\">(</span><span class=\"mord\">3</span><span class=\"mclose\">)</span></span></span></span> <strong>Syntaktische Reparatur</strong>: versucht eine Regex-basierte Extraktion fehlerhafter JSON-Arrays, bevor bis zu <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>3</mn></mrow><annotation encoding=\"application/x-tex\">3</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.6444em;\"></span><span class=\"mord\">3</span></span></span></span> automatisierte, lokale Wiederholungsversuche gestartet werden.",
      ai_meal_ban_t: "Strenges Verbot der Nährwertberechnung",
      ai_meal_ban_c: "Der KI ist die Berechnung von Kalorien, Makronährstoffen oder Nährwertsummen programmatisch untersagt (durchgesetzt per System-Prompt). Sämtliche Makro-Arithmetik wird zu 100% lokal und offline auf deinem Gerät unter Verwendung verifizierter Lebensmittelkatalog-Dichten berechnet. Dies verhindert das Abfließen deines Gesundheitsstatus an LLMs und garantiert mathematische Konsistenz (<span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>1</mn><mtext>g Protein</mtext><mo>=</mo><mn>4</mn><mtext> kcal</mtext></mrow><annotation encoding=\"application/x-tex\">1\text{g Protein} = 4\text{ kcal}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord\">1</span><span class=\"mord text\"><span class=\"mord\">g Protein</span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">4</span><span class=\"mord text\"><span class=\"mord\"> kcal</span></span></span></span></span>, <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>1</mn><mtext>g Kohlenhydrate</mtext><mo>=</mo><mn>4</mn><mtext> kcal</mtext></mrow><annotation encoding=\"application/x-tex\">1\text{g Kohlenhydrate} = 4\text{ kcal}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8889em;vertical-align:-0.1944em;\"></span><span class=\"mord\">1</span><span class=\"mord text\"><span class=\"mord\">g Kohlenhydrate</span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">4</span><span class=\"mord text\"><span class=\"mord\"> kcal</span></span></span></span></span>, <span class=\"katex\"><span class=\"katex-mathml\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\"><semantics><mrow><mn>1</mn><mtext>g Fett</mtext><mo>=</mo><mn>9</mn><mtext> kcal</mtext></mrow><annotation encoding=\"application/x-tex\">1\text{g Fett} = 9\text{ kcal}</annotation></semantics></math></span><span class=\"katex-html\" aria-hidden=\"true\"><span class=\"base\"><span class=\"strut\" style=\"height:0.8778em;vertical-align:-0.1944em;\"></span><span class=\"mord\">1</span><span class=\"mord text\"><span class=\"mord\">g Fett</span></span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span><span class=\"mrel\">=</span><span class=\"mspace\" style=\"margin-right:0.2778em;\"></span></span><span class=\"base\"><span class=\"strut\" style=\"height:0.6944em;\"></span><span class=\"mord\">9</span><span class=\"mord text\"><span class=\"mord\"> kcal</span></span></span></span></span>).",
      ai_meal_limits_c1: "Die Forschung zur computergestützten Ernährungsanalyse hebt mehrere fundamentale Hürden hervor, die eine 100%ige Genauigkeit bei Consumer-Apps unmöglich machen:",
      rec_deep_c: "Drei-Schichten-Architektur & Zusammengesetzte Indizes",
      rec_schema_t: "Drei-Schichten-Schlafschema",
      rec_schema_c: "Die Verarbeitung von Schlafdaten ist in drei separate Schichten gegliedert: (1) <strong>Erfassung roher Zeitreihen</strong> aus Apple HealthKit oder Google Health Connect; (2) <strong>Lokale Validierung & Dublettenbereinigung</strong> überlappender Schlafintervalle unter Verwendung von Wearable-Prioritätshierarchien; (3) offline berechnete <strong>Verbund-Index-Bestimmung</strong>.",
      rec_score_t: "Schlafgesundheits-Score V2",
      rec_score_c: "Berechnet einen zusammengesetzten Score basierend auf der Schlafeffizienz (tatsächliche Schlafzeit / Zeit im Bett), WASO (Wake After Sleep Onset - Erfassung nächtlicher Wachphasen) and dem Schlaf-Regularitäts-Index (SRI), welcher die Wahrscheinlichkeit angibt, zu zwei Zeitpunkten im Abstand von 24 Stunden im selben Zustand (wach/schlafend) zu sein.",
      rec_pulse_t: "Stündliche Puls-Aggregation",
      rec_pulse_c: "Fragt hochfrequente rohe Herzfrequenz-Messwerte ab, entfernt Ausreißer über lokales Z-Scoring und fasst diese in 1-stündige Segmente (<span class=\"math-inline\">[timestamp, min_bpm, max_bpm, avg_bpm, sample_count]</span>) zusammen. Dies reduziert den Speicherbedarf auf dem Gerät um 98% und erhält gleichzeitig aussagekräftige Pulsdiagramme für Schlafanalysen und Ruhepuls-Trends.",
      recovery_limits_c1: "Protokollierte Daten sind nur ein Indikator für den Trainingsstress. Die Heuristik kann externe Faktoren wie Schlafmangel, Nährstoffdefizite oder allgemeinen Lebensstress nicht erkennen, es sei denn, sie werden manuell erfasst oder über Gesundheitsdienste integriert."
    }
  };

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// Theme logic
const updateScreenshots = (theme) => {
  const oldTheme = theme === "dark" ? "light" : "dark";
  document.querySelectorAll("img").forEach((img) => {
    if (img.src.includes(`assets/screenshots/iOS/${oldTheme}/`)) {
      img.src = img.src.replace(`/${oldTheme}/`, `/${theme}/`).replace(`_${oldTheme}_`, `_${theme}_`);
    }
    if (img.dataset.fallbackSrc && img.dataset.fallbackSrc.includes(`assets/screenshots/iOS/${oldTheme}/`)) {
      img.dataset.fallbackSrc = img.dataset.fallbackSrc.replace(`/${oldTheme}/`, `/${theme}/`).replace(`_${oldTheme}_`, `_${theme}_`);
    }
  });
};

const updateTheme = (theme) => {
  document.documentElement.setAttribute("data-theme", theme);
  localStorage.setItem("theme", theme);
  updateScreenshots(theme);
};

const initTheme = () => {
  const themeToggle = document.getElementById("theme-toggle");
  const currentTheme = localStorage.getItem("theme") || (window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark");
  updateTheme(currentTheme);

  if (themeToggle) {
    // Remove old listeners to avoid multiple attachments
    const newToggle = themeToggle.cloneNode(true);
    themeToggle.parentNode.replaceChild(newToggle, themeToggle);

    newToggle.addEventListener("click", () => {
      const theme = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
      updateTheme(theme);
    });
  }
};

// Language logic
const updateTranslations = (lang) => {
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.getAttribute("data-i18n");
    const val = TRANSLATIONS[lang] ? TRANSLATIONS[lang][key] : null;
    if (val) {
      // Use innerHTML if the content contains HTML tags
      if (val.includes('<')) {
         el.innerHTML = val;
      } else {
         el.textContent = val;
      }
    }
  });
  document.documentElement.setAttribute("lang", lang);
};

const initLang = () => {
  const dropdown = document.getElementById("lang-dropdown");
  const toggleBtn = dropdown?.querySelector(".control-btn");
  const menu = dropdown?.querySelector(".dropdown-menu");
  const items = dropdown?.querySelectorAll(".dropdown-item");
  
  let currentLang = localStorage.getItem("lang") || (navigator.language.startsWith("de") ? "de" : "en");
  updateTranslations(currentLang);

  // Update active state in menu
  const updateActiveState = (lang) => {
    items?.forEach(item => {
      if (item.dataset.lang === lang) {
        item.classList.add("is-active");
      } else {
        item.classList.remove("is-active");
      }
    });
  };

  updateActiveState(currentLang);

  if (toggleBtn && menu) {
    toggleBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      const isOpen = menu.classList.contains("is-open");
      if (isOpen) {
        menu.classList.remove("is-open");
        toggleBtn.setAttribute("aria-expanded", "false");
      } else {
        menu.classList.add("is-open");
        toggleBtn.setAttribute("aria-expanded", "true");
      }
    });

    items?.forEach(item => {
      item.addEventListener("click", () => {
        const lang = item.dataset.lang;
        if (lang !== currentLang) {
          currentLang = lang;
          updateTranslations(currentLang);
          localStorage.setItem("lang", currentLang);
          updateActiveState(currentLang);
        }
        menu.classList.remove("is-open");
        toggleBtn.setAttribute("aria-expanded", "false");
      });
    });

    document.addEventListener("click", () => {
      menu.classList.remove("is-open");
      toggleBtn.setAttribute("aria-expanded", "false");
    });
  }
};

// Reveal logic
const initReveal = () => {
  const revealTargets = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && !reduceMotion) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.16, rootMargin: "0px 0px -8% 0px" });

    revealTargets.forEach((target) => observer.observe(target));
  } else {
    revealTargets.forEach((target) => target.classList.add("is-visible"));
  }
};

// Parallax/Scroll logic
const initParallax = () => {
  if (reduceMotion) return;

  const heroStage = document.querySelector(".hero-stage");
  const heroContent = document.querySelector(".hero-content");
  const phoneRow = document.querySelector(".phone-row");

  if (heroStage) {
    window.addEventListener("pointermove", (event) => {
      const mx = (event.clientX / window.innerWidth - 0.5).toFixed(3);
      const my = (event.clientY / window.innerHeight - 0.5).toFixed(3);
      heroStage.style.setProperty("--mx", mx);
      heroStage.style.setProperty("--my", my);
    }, { passive: true });
  }

  const syncScroll = () => {
    const y = Math.min(window.scrollY, 520);
    if (heroStage) heroStage.style.setProperty("--scroll", y.toFixed(0));
    if (heroContent) heroContent.style.setProperty("--hero-copy-scroll", y.toFixed(0));
    if (phoneRow) {
      const rowY = Math.max(0, window.scrollY - phoneRow.offsetTop + 650);
      phoneRow.style.setProperty("--row-scroll", rowY.toFixed(0));
    }
  };

  syncScroll();
  window.addEventListener("scroll", syncScroll, { passive: true });
};

// Fallback images
const initImages = () => {
  document.querySelectorAll("img[data-fallback-src]").forEach((image) => {
    image.addEventListener("error", () => {
      if (image.dataset.fallbackLoaded === "true") return;
      image.dataset.fallbackLoaded = "true";
      image.src = image.dataset.fallbackSrc;
    });
  });
};

// Execution
document.addEventListener("DOMContentLoaded", () => {
  initTheme();
  initLang();
  initReveal();
  initParallax();
  initImages();
});

// Early theme initialization to prevent flash
const savedTheme = localStorage.getItem("theme") || (window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark");
document.documentElement.setAttribute("data-theme", savedTheme);
}) ();
