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
      dash_range: "Likely range 2480-2800",
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
      priv_c3_copy: "Optional AI and health features are separate choices, with your API key and platform permissions in your control.",
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
      imp_title: "Imprint",
      imp_resp: "Responsible for this Train Libre website:",
      priv_hero_title: "Your data stays with you.",
      priv_hero_copy: "Train Libre is offline-first. This policy explains how we handle your data locally and when optional features interact with third-party services.",
      p_last_updated: "Last updated:",
      p_ov_t: "Overview",
      p_ov_c_1: "Train Libre is an offline-first fitness and nutrition tracking app. Your data is stored locally on your device by default and does not require a cloud account.",
      p_ov_c_2: "Sensitive data stays on your device unless you explicitly use a feature that accesses another app, a system health service, a third-party AI provider, a share/export target, or a remote public catalog source.",
      p_ov_c_3: "Train Libre is not a medical service. Health, recovery, sleep, pulse, nutrition, and training features are for personal tracking and training context only. They are not intended to diagnose, treat, cure, or prevent any disease or medical condition.",
      p_data_t: "Data We Process",
      p_data_c_1: "Depending on the features you use, Train Libre stores or processes the following data on your device:",
      p_data_l1: "Profile and settings: Username, height, gender, goals, and unit preferences.",
      p_data_l2: "Workouts: Routines, exercises, sets, reps, weights, RIR/RPE, rest times, and duration.",
      p_data_l3: "Nutrition: Foods, meals, barcodes, calories, macros, hydration, and supplements.",
      p_data_l4: "Body data: Bodyweight and body measurements.",
      p_data_l5: "Health integration: Steps, sleep sessions, and heart-rate samples (when permissions are granted).",
      p_data_l6: "Local analytics: Training statistics, recovery estimates, and body/nutrition trend calculations.",
      p_data_c_2: "The app uses local storage (SQLite/Drift), SharedPreferences, and secure native storage for AI API keys.",
      p_perm_t: "Permissions and Device Access",
      p_perm_c_1: "Train Libre requests the following permissions for specific features:",
      p_perm_l1: "Camera: Used for barcode scanning and AI meal photo capture.",
      p_perm_l2: "Photos/Gallery: Used for selecting a profile image or meal photos for AI analysis.",
      p_perm_l3: "Notifications: Used for reminders or recommendations where enabled.",
      p_perm_l4: "File Access: Used for data import/export and backups.",
      p_perm_l5: "Health Access: Used for Apple Health or Google Health Connect features.",
      p_perm_c_2: "You can manage these permissions in your device settings.",
      p_health_t: "Health and Fitness Data",
      p_health_c_1: "Integration with platform health services (Apple Health on iOS, Google Health Connect on Android) is entirely optional. Access only occurs after you explicitly grant permission.",
      p_health_c_2: "Depending on enabled features, Train Libre may read: steps, sleep sessions and stages, heart-rate data, and workout-related health data where available.",
      p_health_c_3: "Train Libre may write/export supported app-recorded data such as: workouts, body measurements, nutrition aggregates, and hydration data.",
      p_health_c_4: "Export is one-way from Train Libre to the platform health service. Train Libre remains the primary local source of truth.",
      p_health_c_5: "Health data is used for personal tracking, statistics, and training context. It is not used for advertising, tracking, profiling, or sale.",
      p_health_c_6: "The app is not a medical device and does not provide medical diagnosis or treatment. Permissions can be revoked in system settings.",
      p_ai_t: "AI Features",
      p_ai_c_1: "AI meal recognition and AI meal recommendations are optional and disabled by default. The app uses a \"Bring Your Own Key\" (BYOK) model where you choose and configure a supported provider.",
      p_ai_c_2: "Only when you actively use an AI feature are selected inputs sent to the configured provider (e.g., meal description text, selected images, nutrient context, and optional recent meal history if enabled).",
      p_ai_c_3: "API keys are stored locally and securely. Train Libre does not operate its own AI backend for these requests. Provider processing is governed by their own terms and privacy policies.",
      p_ai_c_4: "AI outputs are estimates. Results are shown for review before saving. You can edit, remove, or reject items before they become part of the local diary.",
      p_ai_c_5: "AI data is not used by Train Libre for advertising or tracking.",
      p_back_t: "Backups and Data Portability",
      p_back_c_1: "You can create JSON backups, encrypted backups, or CSV exports. If you choose a non-encrypted format, the file contents are readable by anyone with access to the file.",
      p_back_c_2: "You are responsible for where you save or share these exported files. Imports allow you to restore data from previous backups or other supported formats.",
      p_cat_t: "Remote Catalogs",
      p_cat_c_1: "The app can fetch public exercise and food catalog updates from official Train Libre sources. These requests only download data and do not upload your personal tracking logs.",
      p_ads_t: "Ads, Analytics, and Tracking",
      p_ads_c_1: "Train Libre does not include advertising, third-party analytics SDKs, or trackers. All statistics and insights are computed locally on your device. Your data is never sold or shared for advertising purposes.",
      p_sec_t: "Data Storage and Security",
      p_sec_c_1: "Primary data is stored locally. Security depends on your device's operating system and lock screen protections. Be cautious when sharing exported files or using unencrypted backups.",
      p_ctrl_t: "Your Controls",
      p_ctrl_l1: "You decide which optional features and permissions to enable.",
      p_ctrl_l2: "You can delete entries or your entire profile within the app.",
      p_ctrl_l3: "You can remove saved AI API keys at any time.",
      p_ctrl_l4: "Uninstalling the app removes its local data from your device.",
      p_cont_t: "Contact",
      learn_more: "Learn more",
      evidence_read_more: "Evidence & further reading",
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
      ai_meal_how_c1: "Train Libre uses a \"Bring Your Own Key\" (BYOK) model. You choose a provider and model; the app handles the orchestration. Your data stays local, and the AI is only called when you trigger a capture.",
      ai_meal_how_c2: "Recognition is treated as a noisy proposal. Once the AI returns food names and grams, the app runs a deterministic validation pass. It attempts to repair common errors and flags low-confidence matches before you see the result.",
      ai_meal_limits_t: "Scientific & Technical Limitations",
      ai_meal_limits_c1: "Research into computer-vision-based nutrition estimation highlights several fundamental hurdles that make 100% accuracy impossible for consumer apps:",
      ai_meal_limits_l1: "The Volume Problem: A 2D photo lacks depth information. Studies show that without a reference object or multiple angles, volume error rates typically range from 10% to 30%.",
      ai_meal_limits_l2: "Hidden Ingredients: AI cannot 'see' the oils, butter, or sugar used in preparation. A grilled breast and a sautéed one may look identical but differ significantly in caloric density.",
      ai_meal_limits_l3: "Mixed Dishes: Ingredients in dishes like stir-fries or burritos are often occluded. If the rice is under the curry, the AI will likely underestimate the portion.",
      ai_meal_guidance_t: "Practical Guidance",
      ai_meal_guidance_c: "Treat AI capture as a friction-reduction tool, not a ground truth. Always use the review screen to adjust gram estimates and ensure the matched foods align with what you actually ate.",

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
      adapt_nut_how_c3: "To handle the 'noise' of water retention and glycogen shifts, the system uses a 7-day confirmation rule for goal changes and a phase-dependent scaling factor for energy density (kcal/kg).",
      adapt_nut_limits_t: "Uncertainty & Interpretation",
      adapt_nut_limits_c1: "Daily scale weight is high-noise data. Factors like sodium intake, hydration, and muscle glycogen can cause shifts of several kilograms that do not represent changes in body tissue.",
      adapt_nut_limits_l1: "Trend vs. Noise: The algorithm prioritizes the long-term trend. This means it may feel slow to respond to rapid, short-term changes.",
      adapt_nut_limits_l2: "Logging Consistency: The precision of the estimate depends entirely on the consistency of your logs. Sparse data will result in wider uncertainty ranges.",
      adapt_nut_limits_l3: "Stabilization: During the first 2-4 weeks, the system relies on profile 'priors'. It becomes significantly more accurate once it has sufficient user-specific history.",

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
      recovery_how_c1: "The tracker uses an 'Equivalent Set' model. Research (e.g., Vieira et al., 2021) shows that training to failure (0 RIR) significantly elongates recovery time, sometimes by 24–48 hours, compared to submaximal training.",
      recovery_how_c2: "Train Libre applies this by weighting your working sets. A set at 0 RIR is flagged as high-fatigue, extending the estimated recovery window. The system also recognizes that compound movements like bench pressing create recovery pressure not just for the chest, but also for the triceps and front delts.",
      recovery_how_c3: "Different muscle groups recover at different rates. Larger, high-load groups (like the quads or lower back) are assigned longer base windows than smaller groups (like the biceps or calves).",
      recovery_limits_t: "Why it is a guide, not a measurement",
      recovery_limits_c1: "Logged data is a proxy for training stress. The heuristic cannot 'see' external factors like sleep debt, nutritional deficiencies, or systemic life stress unless they are manually logged or integrated via health services.",
      recovery_limits_l1: "Subjectivity: Use the status as a data-informed suggestion. If the app says a muscle is 'Ready' but you feel significant soreness or lethargy, prioritize your body's feedback.",
      recovery_limits_l2: "Novelty: New exercises or sudden volume spikes may cause disproportionate fatigue that the base heuristic may not fully capture.",
      footer_recovery: "Recovery Tracker"
    },
    de: {
      nav_features: "Funktionen",
      nav_guidance: "KI-Unterstützung",
      nav_privacy: "Datenschutz",
      nav_showcase: "Vorschau",
      nav_imprint: "Impressum",
      hero_eyebrow: "Lokale Datenkontrolle & Privatsphäre",
      hero_statement: "Behalte die volle Kontrolle über dein Training.",
      hero_copy: "Die private, offline-zuerst Lösung für strukturiertes Workout-Logging, intelligente Mahlzeitenerkennung und adaptive Kalorien-Ziele – ohne Cloud-Zwang.",
      hero_cta_ios: "iOS TestFlight Beta",
      hero_cta_android: "Android (via Obtainium)",
      hero_point_1: "KI-Mahlzeitenerkennung",
      hero_point_2: "Adaptive Kalorien-Empfehlungen",
      hero_point_3: "Kein Cloud-Konto nötig",
      hero_point_4: "Lokale Datenspeicherung",
      feat_kicker: "Highlights",
      feat_heading: "Professionelles Tracking ohne Ablenkung.",
      feat_copy: "Train Libre fokussiert sich auf das Wesentliche: präzise Protokollierung, ehrliche Analyse und sichtbarer Fortschritt.",
      f1_title: "Trainingstagebuch mit System",
      f1_copy: "Dokumentiere jeden Satz im Detail – inklusive Aufwärmsätzen, Dropsets und RIR-Tracking für volle Transparenz.",
      f1_small: "Trainingspläne, Historie, Auswertung",
      f2_title: "Ernährung & Supplemente",
      f2_copy: "Erfasse Mahlzeiten, Kalorien, Makros und Supplemente wie Kreatin oder Koffein in einem gemeinsamen Journal.",
      f2_small: "Nährwerte, Wasser, Supplementierung",
      f3_title: "Fortschritt im Kontext",
      f3_copy: "Verfolge dein Körpergewicht und deine Maße direkt neben Ernährungstrends und Trainingskonstanz.",
      f3_small: "Messwerte, Trends, Zielsetzung",
      f4_title: "Regeneration & Vitalwerte",
      f4_copy: "Integriere Schlaf-, Schritt- und Herzfrequenzdaten für ein ganzheitliches Bild deiner Erholung.",
      f4_small: "Information, keine Diagnose",
      f5_title: "Echte Datenhoheit",
      f5_copy: "Erstelle lokale Backups und nutze den Health-Export, ohne jemals die Kontrolle über deine Daten abzugeben.",
      f5_small: "Offline-first Architektur",
      f6_title: "KI, die mitdenkt",
      f6_copy: "Erfasse Mahlzeiten per Foto oder Text. Prüfe Portionen und Nährwerte lokal, bevor sie in deinem Log landen.",
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
      dash_range: "Bereich: 2480-2800",
      dash_confidence: "Mittleres Vertrauen",
      macro_kcal: "Ziel-Kalorien",
      macro_protein: "Protein",
      macro_carbs: "Kohlenhydrate",
      step1: "Geglättete Trends reduzieren tägliche Schwankungen vor der Kalorienanpassung.",
      step2: "Lückenhafte Logs führen zu breiteren Unsicherheitsbereichen statt Fehlsteuerungen.",
      step3: "Empfehlungen sind Vorschläge und ersetzen niemals deine Ziele ohne Bestätigung.",
      priv_kicker: "Datenschutz",
      priv_heading: "Deine Daten gehören dir.",
      priv_copy: "Train Libre ist offline-first. Deine Daten werden lokal verarbeitet. Es gibt keinen Kontozwang und kein Tracking.",
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
      imp_resp: "Verantwortlich für diese Website:",
      priv_hero_title: "Deine Daten bleiben bei dir.",
      priv_hero_copy: "Train Libre ist eine Offline-First-App. Hier erfährst du, wie wir deine Privatsphäre schützen und wann Daten dein Gerät verlassen.",
      p_last_updated: "Stand:",
      p_ov_t: "Überblick",
      p_ov_c_1: "Train Libre ist eine Offline-First-App für Fitness und Ernährung. Deine Daten werden standardmäßig lokal auf deinem Gerät gespeichert; es wird kein Cloud-Konto benötigt.",
      p_ov_c_2: "Sensible Daten verlassen dein Gerät nur, wenn du explizit Funktionen nutzt, die auf Drittanbieter (z. B. KI-Provider) oder Systemdienste zugreifen.",
      p_ov_c_3: "Train Libre ist kein medizinischer Dienst. Alle Funktionen dienen der persönlichen Dokumentation und Trainingssteuerung.",
      p_data_t: "Datenverarbeitung",
      p_data_c_1: "Je nach genutzten Funktionen speichert die App folgende Daten lokal auf deinem Gerät:",
      p_data_l1: "Profil & Einstellungen: Benutzername, Körpermaße, Ziele und Einheiten.",
      p_data_l2: "Training: Pläne, Übungen, Sätze, Wiederholungen, Gewichte und RIR/RPE.",
      p_data_l3: "Ernährung: Lebensmittel, Mahlzeiten, Barcodes, Kalorien, Makros und Hydration.",
      p_data_l4: "Körperwerte: Gewicht und Maße.",
      p_data_l5: "Health-Integration: Schritte, Schlaf und Herzfrequenz (bei erteilter Freigabe).",
      p_data_l6: "Analysen: Statistiken, Regenerationstrends und Nährwertberechnungen.",
      p_data_c_2: "Die App nutzt lokale SQLite-Datenbanken und sicheren Speicher für KI-Schlüssel.",
      p_perm_t: "Berechtigungen",
      p_perm_c_1: "Train Libre benötigt Zugriff auf folgende Funktionen nur bei aktiver Nutzung:",
      p_perm_l1: "Kamera: Für Barcode-Scans und Mahlzeiten-Fotos.",
      p_perm_l2: "Galerie: Für die Auswahl von Profilbildern oder Mahlzeiten-Fotos.",
      p_perm_l3: "Mitteilungen: Für Erinnerungen oder Empfehlungen.",
      p_perm_l4: "Dateizugriff: Für Backups sowie den Import und Export von Daten.",
      p_perm_l5: "Health-Dienste: Für die Anbindung an Apple Health oder Google Health Connect.",
      p_perm_c_2: "Diese Berechtigungen können jederzeit in den Systemeinstellungen widerrufen werden.",
      p_health_t: "Gesundheitsdaten",
      p_health_c_1: "Die Integration mit Apple Health oder Google Health Connect ist vollkommen optional. Der Zugriff erfolgt erst, nachdem du die Berechtigung in der App und den Systemeinstellungen explizit erteilt hast.",
      p_health_c_2: "Bei erteilter Freigabe kann Train Libre folgende Daten lesen: Schritte, Schlafphasen und -dauer, Herzfrequenzdaten sowie trainingsbezogene Gesundheitsdaten, sofern verfügbar.",
      p_health_c_3: "Bei erteilter Freigabe kann die App folgende in der App erfasste Daten exportieren: Workouts, Körpermaße, Nährwertsummen und Hydrationsdaten.",
      p_health_c_4: "Dies erfolgt als Einweg-Export von Train Libre zum jeweiligen Systemdienst. Train Libre bleibt die primäre Quelle für deine Daten.",
      p_health_c_5: "Gesundheitsdaten werden für das persönliche Tracking, Statistiken und den Trainingskontext verwendet. Sie werden nicht für Werbung, Tracking, Profiling oder zum Verkauf genutzt.",
      p_health_c_6: "Die App ist kein medizinisches Gerät und bietet keine medizinischen Diagnosen oder Behandlungen an. Berechtigungen können jederzeit in den Systemeinstellungen widerrufen werden.",
      p_ai_t: "KI-Funktionen",
      p_ai_c_1: "Die Mahlzeitenerkennung via KI und KI-Empfehlungen sind optional und standardmäßig deaktiviert. Die App nutzt ein \"Bring Your Own Key\" (BYOK)-Modell, bei dem du einen unterstützten Provider selbst wählst und konfigurierst.",
      p_ai_c_2: "Nur wenn du eine KI-Funktion aktiv nutzt, werden ausgewählte Eingaben an den konfigurierten Provider gesendet. Dies kann Mahlzeitentexte, ausgewählte Bilder, Makronährstoff-Kontext oder optional den kürzlichen Mahlzeitenverlauf (falls aktiviert) umfassen.",
      p_ai_c_3: "API-Schlüssel werden lokal und sicher auf deinem Gerät gespeichert. Train Libre betreibt kein eigenes KI-Backend für diese Anfragen. Die Verarbeitung durch den Provider unterliegt dessen eigenen Bedingungen und Datenschutzrichtlinien.",
      p_ai_c_4: "KI-Ergebnisse sind Schätzwerte. Ergebnisse werden zur Prüfung angezeigt, wobei du Einträge bearbeiten, entfernen oder ablehnen kannst, bevor sie in dein lokales Tagebuch übernommen werden.",
      p_ai_c_5: "KI-Daten werden von Train Libre nicht für Werbung oder Tracking verwendet.",
      p_back_t: "Backups & Portabilität",
      p_back_c_1: "Du kannst lokale JSON-Backups, verschlüsselte Backups oder CSV-Exporte erstellen.",
      p_back_c_2: "Du bist selbst dafür verantwortlich, wo du diese Dateien speicherst oder teilst.",
      p_cat_t: "Remote-Kataloge",
      p_cat_c_1: "Die App lädt öffentliche Übungs- und Lebensmittelkataloge herunter. Dabei werden keine persönlichen Daten hochgeladen.",
      p_ads_t: "Werbung & Tracking",
      p_ads_c_1: "Train Libre enthält keine Werbung, Analyse-SDKs oder Tracker. Alle Statistiken werden lokal berechnet. Deine Daten werden niemals zu Werbezwecken geteilt.",
      p_sec_t: "Datensicherheit",
      p_sec_c_1: "Primäre Daten liegen lokal. Die Sicherheit hängt von den Schutzmechanismen deines Betriebssystems ab.",
      p_ctrl_t: "Deine Kontrolle",
      p_ctrl_l1: "Du entscheidest, welche Funktionen und Berechtigungen du aktivierst.",
      p_ctrl_l2: "Du kannst Einträge oder dein gesamtes Profil jederzeit in der App löschen.",
      p_ctrl_l3: "KI-Schlüssel können jederzeit entfernt werden.",
      p_ctrl_l4: "Das Deinstallieren der App löscht alle lokalen Daten vom Gerät.",
      p_cont_t: "Kontakt",
      learn_more: "Mehr erfahren",
      evidence_read_more: "Evidenz & Quellen",
      ai_meal_hero_t: "KI-Mahlzeitenerkennung",
      ai_meal_hero_c: "Ein review-basierter Ansatz zur Erfassung von Ernährungsdaten, der LLMs als Vorschlagsebene für eine lokale, deterministische Validierung nutzt.",
      ai_meal_what_t: "Was diese Funktion tut",
      ai_meal_what_l1: "Schlägt Lebensmittelnamen und Gewichtsschätzungen basierend auf Fotos oder Textbeschreibungen vor.",
      ai_meal_what_l2: "Gleicht KI-Vorschläge mit der lokalen Lebensmitteldatenbank der App ab.",
      ai_meal_what_l3: "Berechnet Nährwertsummen lokal unter Verwendung gematchter Produktdaten.",
      ai_meal_what_l4: "Bietet eine Review-Oberfläche, um jeden Eintrag manuell zu bearbeiten oder abzulehnen.",
      ai_meal_not_t: "Was sie NICHT tut",
      ai_meal_not_l1: "Sie bietet keine medizinische Nährwertanalyse.",
      ai_meal_not_l2: "Sie 'weiß' nicht automatisch um die Kaloriendichte eines spezifischen Restaurantgerichts.",
      ai_meal_not_l3: "Sie speichert keine Daten ohne deine ausdrückliche Prüfung und Bestätigung.",
      ai_meal_how_t: "Die Architektur: Lokal & BYOK",
      ai_meal_how_c1: "Train Libre nutzt ein \"Bring Your Own Key\" (BYOK)-Modell. Du wählst Provider und Modell; die App übernimmt die Orchestrierung. Deine Daten bleiben lokal.",
      ai_meal_how_c2: "Die Erkennung wird als ungenauer Vorschlag behandelt. Sobald die KI Namen und Mengen liefert, führt die App eine deterministische Validierung durch, um Fehler zu korrigieren.",
      ai_meal_limits_t: "Wissenschaftliche & technische Grenzen",
      ai_meal_limits_c1: "Die Forschung zur bildbasierten Nährwertschätzung zeigt fundamentale Hürden auf, die eine 100%ige Genauigkeit unmöglich machen:",
      ai_meal_limits_l1: "Das Volumen-Problem: Einem 2D-Foto fehlt die Tiefeninformation. Ohne Referenzobjekte liegen die Fehlerraten bei der Volumenschätzung oft zwischen 10% und 30%.",
      ai_meal_limits_l2: "Versteckte Zutaten: Die KI kann Öle, Butter oder Zucker nicht 'sehen'. Ein gedünstetes und ein in Butter gebratenes Gericht können identisch aussehen, sich aber kalorisch stark unterscheiden.",
      ai_meal_limits_l3: "Verdeckte Lebensmittel: In gemischten Gerichten wie Burritos sind Zutaten oft verdeckt. Wenn der Reis unter dem Curry liegt, wird die Portion wahrscheinlich unterschätzt.",
      ai_meal_guidance_t: "Praktische Hinweise",
      ai_meal_guidance_c: "Betrachte die KI-Erfassung als Werkzeug zur Zeitersparnis, nicht als absolute Wahrheit. Nutze immer den Review-Bildschirm, um Schätzungen anzupassen.",

      adapt_nut_hero_t: "Adaptive Kalorienschätzung",
      adapt_nut_hero_c: "Ein rekursives Schätzsystem, das darauf ausgelegt ist, die Erhaltungskalorien (TDEE) aus schwankenden Körpergewichts- und Log-Daten abzuleiten.",
      adapt_nut_what_t: "Was dieses System tut",
      adapt_nut_what_l1: "Schätzt deine Erhaltungskalorien (TDEE) basierend auf deinem tatsächlichen Fortschritt.",
      adapt_nut_what_l2: "Analysiert Gewichtstrends mittels Glättung, um tägliche Schwankungen zu filtern.",
      adapt_nut_what_l3: "Aktualisiert wöchentliche Ziele konservativ, um Überreaktionen zu vermeiden.",
      adapt_nut_what_l4: "Liefert einen Unsicherheitsbereich basierend auf der Konstanz deiner Daten.",
      adapt_nut_not_t: "Was es NICHT tut",
      adapt_nut_not_l1: "Es ist kein Ersatz für medizinische Stoffwechseltests oder ärztlichen Rat.",
      adapt_nut_not_l2: "Es kann Gewichtsänderungen aufgrund individueller Variabilität nicht mit 100%iger Präzision vorhersagen.",
      adapt_nut_not_l3: "Es berücksichtigt keine Krankheiten oder extremen Stress, sofern diese nicht in den Logs sichtbar sind.",
      adapt_nut_how_t: "Funktionsweise: Rekursive Schätzung",
      adapt_nut_how_c1: "Statt auf statische Formeln wie Mifflin-St. Jeor zu vertrauen – die laut Forschung bei Einzelpersonen stark abweichen können – betrachtet Train Libre deinen Stoffwechsel als dynamischen Zustand.",
      adapt_nut_how_c2: "Die App nutzt einen bayesianisch inspirierten rekursiven Schätzer. Jede Woche wird die Vorhersage mit dem tatsächlichen Trend verglichen und die Schätzung entsprechend angepasst.",
      adapt_nut_how_c3: "Um Wassereinlagerungen und Glykogen-Schwankungen abzufangen, nutzt das System eine 7-Tage-Bestätigungsregel für Zieländerungen und eine phasenabhängige Skalierung der Energiedichte.",
      adapt_nut_limits_t: "Unsicherheit & Interpretation",
      adapt_nut_limits_c1: "Das tägliche Körpergewicht ist ein extrem 'verrauschtes' Datum. Faktoren wie Natriumzufuhr und Hydration können Schwankungen verursachen, die kein Körperfett darstellen.",
      adapt_nut_limits_l1: "Trend vs. Rauschen: Der Algorithmus priorisiert den langfristigen Trend. Er reagiert daher bewusst langsam auf kurzfristige Sprünge.",
      adapt_nut_limits_l2: "Konstanz der Logs: Die Präzision der Schätzung hängt direkt von der Regelmäßigkeit deiner Einträge ab. Lückenhafte Daten führen zu größeren Unsicherheitsbereichen.",
      adapt_nut_limits_l3: "Stabilisierung: In den ersten 2-4 Wochen stützt sich das System auf profilbasierte Annahmen. Es wird präziser, je mehr spezifische Daten vorliegen.",

      recovery_hero_t: "Regenerations-Heuristik",
      recovery_hero_c: "Eine Planungshilfe, die die muskelspezifische Bereitschaft basierend auf der Akkumulation und dem Abklingen der Trainingsbelastung schätzt.",
      recovery_what_t: "Was dieses System tut",
      recovery_what_l1: "Schätzt den Regenerationsstatus einzelner Muskelgruppen.",
      recovery_what_l2: "Berücksichtigt primäre und sekundäre Muskelbeteiligung (Überschneidungen).",
      recovery_what_l3: "Passt Regenerationsfenster basierend auf der Nähe zum Versagen (RIR/RPE) an.",
      recovery_what_l4: "Nutzt muskelspezifische Basis-Regenerationskurven (z. B. unterer Rücken vs. Delta).",
      recovery_not_t: "Was es NICHT tut",
      recovery_not_l1: "Es misst keine tatsächlichen physiologischen Biomarker oder ZNS-Ermüdung.",
      recovery_not_l2: "Es kann keine Verletzungen vorhersagen oder nicht dokumentierte Schmerzen erfassen.",
      recovery_not_l3: "Es ist kein Ersatz für das subjektive Körpergefühl oder trainerisches Urteilsvermögen.",
      recovery_how_t: "Die Wissenschaft hinter der Schätzung",
      recovery_how_c1: "Der Tracker nutzt ein 'Equivalent Set'-Modell. Forschungsergebnisse (z. B. Morán-Navarro et al., 2017) legen nahe, dass Training bis zum Versagen (0 RIR) die Regenerationszeit signifikant verlängert.",
      recovery_how_c2: "Train Libre gewichtet Arbeitssätze entsprechend: Ein Satz mit 0 RIR wird in der Heuristik als belastender eingestuft, was das geschätzte Zeitfenster verlängert. Das System erkennt zudem, dass Verbundübungen mehrere Muskelgruppen gleichzeitig beanspruchen.",
      recovery_how_c3: "Verschiedene Muskelgruppen regenerieren unterschiedlich schnell. Große Muskelgruppen (wie Quads oder unterer Rücken) haben längere Basis-Fenster im Abkling-Modell als kleinere Gruppen (wie Bizeps oder Waden).",
      recovery_limits_t: "Warum es ein Leitfaden ist, keine Messung",
      recovery_limits_c1: "Daten aus dem Logbuch sind ein Proxy für Trainingsstress. Die Heuristik kann externe Faktoren wie Schlafmangel oder Stress nicht direkt 'sehen'.",
      recovery_limits_l1: "Subjektivität: Nutze den Status als datengestützte Empfehlung. Wenn die App 'Bereit' anzeigt, du aber Schmerzen fühlst, priorisiere dein Körpergefühl.",
      recovery_limits_l2: "Anpassung: Neue Übungen oder plötzliche Volumen-Steigerungen können zu einer Ermüdung führen, die die Basis-Heuristik nicht vollständig erfasst.",
      footer_recovery: "Regenerations-Tracker"
    }
  };

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// Theme logic
const updateTheme = (theme) => {
  document.documentElement.setAttribute("data-theme", theme);
  localStorage.setItem("theme", theme);
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
    if (TRANSLATIONS[lang][key]) {
      el.textContent = TRANSLATIONS[lang][key];
    }
  });
  document.documentElement.setAttribute("lang", lang);
};

const initLang = () => {
  const langToggle = document.getElementById("lang-toggle");
  let currentLang = localStorage.getItem("lang") || (navigator.language.startsWith("de") ? "de" : "en");
  updateTranslations(currentLang);

  if (langToggle) {
    const newToggle = langToggle.cloneNode(true);
    langToggle.parentNode.replaceChild(newToggle, langToggle);

    newToggle.addEventListener("click", () => {
      currentLang = currentLang === "en" ? "de" : "en";
      updateTranslations(currentLang);
      localStorage.setItem("lang", currentLang);
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
