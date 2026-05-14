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
      legal_version: "Version: 1.1",
      legal_date: "Date: May 12, 2026",
      legal_intro: "This document contains the Technical Data Inventory, followed by the legally binding German (Impressum & Datenschutzerklärung) and English (Legal Notice & Privacy Policy) sections.",
      
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
      p_last_updated: "Last updated: May 12, 2026",
      p_1_t: "1. General Information",
      p_1_c1: "This Privacy Policy informs you according to Art. 13 GDPR about the processing of personal data in “Train Libre”.",
      p_1_c2: "Controller: Richard Georg Schotte, Berlin (see Legal Notice for address). E-Mail: feedback@schotte.me",
      p_2_t: "2. Local-First & Privacy by Design",
      p_2_c1: "Train Libre is a \"local-first\" application. All sensitive health data remains exclusively on your device. We do not operate a cloud backend and have no access to your data.",
      p_3_t: "3. Legal Bases for Processing",
      p_3_a_t: "A. Health Data (Art. 9 GDPR)",
      p_3_a_c1: "The app processes special categories of personal data (weight, heart rate, sleep data, nutrition).",
      p_3_a_l1: "Legal Basis: Your explicit consent according to Art. 9(2)(a) GDPR in conjunction with Art. 6(1)(a) GDPR.",
      p_3_a_l2: "Voluntary Nature: Providing health data is not legally or contractually required. However, without it, tracking and analysis features are not available.",
      p_3_b_t: "B. App Functionality",
      p_3_b_c1: "Processing of settings and profiles is based on Art. 6(1)(b) GDPR (performance of a contract/usage agreement).",
      p_3_c_t: "C. Support & Feedback",
      p_3_c_c1: "Handled based on Art. 6(1)(b) GDPR and our legitimate interest in support quality and abuse prevention (Art. 6(1)(f) GDPR).",
      p_4_t: "4. Categories of Recipients",
      p_4_c1: "Apart from technical connection data processed by the hosting provider and third-party services described below, we do not receive the contents of your in‑app data. Recipients of technical or user-generated data may be:",
      p_4_l1: "AI Providers (OpenAI, Google, etc.): Act as separate controllers when you use BYOK AI features.",
      p_4_l2: "Catalog Services (Open Food Facts, wger, GitHub): Receive technical connection data (IP, User-Agent) during updates.",
      p_4_l3: "Cloud Providers (Apple/Google): Receive data via your system-wide backups if enabled.",
      p_5_t: "5. International Data Transfers (BYOK AI)",
      p_5_c1: "When using AI services, data may be transferred to third countries (especially the USA) subject to Art. 44 et seq. GDPR.",
      p_5_l1: "Safeguards: Providers typically use Standard Contractual Clauses (SCCs) or other legal mechanisms.",
      p_5_l2: "Note: As you use your own API key, processing is subject to the provider's privacy policy. Please review their policies before transmitting health data.",
      p_6_t: "6. HealthKit & Health Connect Integration",
      p_6_c1: "Train Libre can read and write health data via Apple HealthKit and Google Health Connect. This synchronization happens entirely on your device.",
      p_6_c2: "The app only accesses these services if you explicitly grant permission in your system settings.",
      p_6_c3: "Please also review Apple’s and Google’s separate privacy policies for these health platforms.",
      p_7_t: "7. No Tracking / No Analytics",
      p_7_c1: "The app does not use tracking or analytics SDKs (e.g., Firebase Analytics, Google Analytics, Sentry). No profiling for marketing purposes is performed.",
      p_8_t: "8. Retention Periods",
      p_8_l1: "App Data: Stored on your device until deleted or uninstalled.",
      p_8_l2: "E-Mails: Retained only as long as needed for handling the request and documentation, subject to statutory retention duties.",
      p_9_t: "9. Web Hosting (GitHub Pages)",
      p_9_c1: "This website is hosted on GitHub Pages. The service provider is GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA (and GitHub B.V., Vijzelstraat 68-72, 1017 HL Amsterdam, The Netherlands, according to GitHub’s privacy statement).",
      p_9_c2: "When you access our website, your browser connects to GitHub’s servers. In this context, technical data such as your IP address, requested URL, date and time, browser and operating system information may be stored in server log files.",
      p_9_c3: "The legal basis is our legitimate interest in providing a secure and efficient website according to Art. 6(1)(f) GDPR.",
      p_9_c4: "For details, please see GitHub’s privacy statement at https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement.",
      p_10_t: "10. Your Data Subject Rights",
      p_10_c1: "You have the following rights:",
      p_10_l1: "Access (Art. 15)",
      p_10_l2: "Rectification (Art. 16)",
      p_10_l3: "Erasure (Art. 17)",
      p_10_l4: "Restriction of processing (Art. 18)",
      p_10_l5: "Data portability (Art. 20)",
      p_10_l6: "Objection (Art. 21)",
      p_10_l7: "Withdrawal of consent (Art. 7(3)) with future effect.",
      p_10_c2: "You also have the right to lodge a complaint with a supervisory authority (Art. 77), such as the Berlin Commissioner for Data Protection and Freedom of Information.",
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
      recovery_how_c1: "The tracker uses an 'Equivalent Set' model. Research (e.g., Vieira et al., 2021) shows that training to failure (0 RIR) significantly elongates recovery time, sometimes by 24–48 hours, compared to submaximal training.",
      recovery_how_c2: "Train Libre applies this by weighting your working sets. A set at 0 RIR is flagged as high-fatigue, extending the estimated recovery window. The system also recognizes that compound movements like bench pressing create recovery pressure not just for the chest, but also for the triceps and front delts.",
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
      adapt_nut_how_c3: "To handle the 'noise' of water retention and glycogen shifts, the system uses a 7-day confirmation rule for goal changes and a phase-dependent scaling factor for energy density (kcal/kg).",
      adapt_nut_limits_t: "Uncertainty & Interpretation",
      adapt_nut_limits_l1: "Trend vs. Noise: The algorithm prioritizes the long-term trend. This means it may feel slow to respond to rapid, short-term changes.",
      adapt_nut_limits_l2: "Logging Consistency: The precision of the estimate depends entirely on the consistency of your logs. Sparse data will result in wider uncertainty ranges.",
      adapt_nut_limits_l3: "Stabilization: During the first 2-4 weeks, the system relies on profile 'priors'. It becomes significantly more accurate once it has sufficient user-specific history.",
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
      ai_meal_limits_l1: "The Volume Problem: A 2D photo lacks depth information. Studies show that without a reference object or multiple angles, volume error rates typically range from 10% to 30%.",
      ai_meal_limits_l2: "Hidden Ingredients: AI cannot 'see' the oils, butter, or sugar used in preparation. A grilled breast and a sautéed one may look identical but differ significantly in caloric density.",
      ai_meal_limits_l3: "Mixed Dishes: Ingredients in dishes like stir-fries or burritos are often occluded. If the rice is under the curry, the AI will likely underestimate the portion.",
      ai_meal_guidance_t: "Practical Guidance",
      ai_meal_guidance_c: "Treat AI capture as a friction-reduction tool, not a ground truth. Always use the review screen to adjust gram estimates and ensure the matched foods align with what you actually ate."
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
      dash_range: "Bereich: 2480-2800",
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
      legal_version: "Version: 1.1",
      legal_date: "Datum: 12. Mai 2026",
      legal_intro: "Dieses Dokument enthält das technische Dateninventar, gefolgt von den rechtlich bindenden deutschen (Impressum & Datenschutzerklärung) und englischen (Legal Notice & Privacy Policy) Abschnitten.",
      
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
      p_last_updated: "Stand: 12. Mai 2026",
      p_1_t: "1. Einleitung und Verantwortlicher",
      p_1_c1: "Diese Datenschutzerklärung informiert Sie gemäß Art. 13 DSGVO über die Verarbeitung personenbezogener Daten in der App „Train Libre“.",
      p_1_c2: "Verantwortlicher: Richard Georg Schotte, Berlin (Anschrift siehe Impressum). E-Mail: feedback@schotte.me",
      p_2_t: "2. Local-First Prinzip & Datensparsamkeit",
      p_2_c1: "Train Libre ist eine „Local-First“-App. Wir verfolgen den Ansatz der Datensparsamkeit und des Datenschutzes durch Technikgestaltung (Privacy by Design). Alle Ihre sensiblen Gesundheitsdaten verbleiben ausschließlich in einer lokalen Datenbank auf Ihrem Endgerät. Wir betreiben keinen Cloud-Server und haben keinen technischen Zugriff auf Ihre lokalen Daten.",
      p_3_t: "3. Kategorien von Daten und Rechtsgrundlagen",
      p_3_a_t: "A. Gesundheitsdaten (Art. 9 DSGVO)",
      p_3_a_c1: "Die App verarbeitet besondere Kategorien personenbezogener Daten (Gewicht, Herzfrequenz, Schlafdaten, Ernährung).",
      p_3_a_l1: "Rechtsgrundlage: Ihre ausdrückliche Einwilligung gemäß Art. 9 Abs. 2 lit. a DSGVO in Verbindung mit Art. 6 Abs. 1 lit. a DSGVO.",
      p_3_a_l2: "Freiwilligkeit: Die Bereitstellung dieser Daten ist weder gesetzlich noch vertraglich vorgeschrieben. Ohne diese Daten können die Tracking- und Analysefunktionen jedoch nicht genutzt werden.",
      p_3_b_t: "B. Kernfunktionalitäten der App",
      p_3_b_c1: "Die Speicherung Ihrer Einstellungen und Profile erfolgt zur Erfüllung des Nutzungsverhältnisses auf Grundlage von Art. 6 Abs. 1 lit. b DSGVO.",
      p_3_c_t: "C. Support & Feedback",
      p_3_c_c1: "Bei Kontaktaufnahme per E-Mail verarbeiten wir Ihre Daten zur Bearbeitung Ihres Anliegens (Art. 6 Abs. 1 lit. b DSGVO) sowie aufgrund unseres berechtigten Interesses an Supportqualität und Missbrauchsprävention (Art. 6 Abs. 1 lit. f DSGVO).",
      p_4_t: "4. Empfänger der Daten",
      p_4_c1: "Innerhalb der App findet kein automatischer Datentransfer an uns statt. Empfänger technischer oder nutzergenerierter Daten können jedoch sein:",
      p_4_l1: "KI-Anbieter (OpenAI, Google, Anthropic, Mistral, xAI etc.): Diese agieren als separate Verantwortliche und erhalten Daten (z. B. Fotos, Prompts), wenn Sie die BYOK-KI-Funktionen aktiv nutzen.",
      p_4_l2: "Katalog-Dienste (Open Food Facts, wger, GitHub): Diese erhalten technische Verbindungsdaten (IP-Adresse, User-Agent) beim Abruf von Datenbanken oder Updates.",
      p_4_l3: "Cloud-Anbieter (Apple iCloud / Google Drive): Diese erhalten Daten im Rahmen Ihrer systemweiten Backups, sofern Sie diese Funktion im Betriebssystem aktiviert haben.",
      p_5_t: "5. Drittlandübermittlung (BYOK AI)",
      p_5_c1: "Bei Nutzung von KI-Diensten können Daten an Anbieter in Drittländern (insbesondere die USA) übertragen werden.",
      p_5_l1: "Mechanismen: Die Anbieter stützen sich in der Regel auf Standardvertragsklauseln (SCCs) oder Angemessenheitsbeschlüsse.",
      p_5_l2: "Hinweis: Da Sie Ihren eigenen API-Schlüssel nutzen, unterliegt die Datenverarbeitung den Datenschutzbestimmungen des jeweiligen Anbieters. Bitte prüfen Sie deren Richtlinien (z. B. zu Datenstandorten), bevor Sie gesundheitsbezogene Daten übermitteln. Die Übermittlung erfolgt gemäß Art. 44 ff. DSGVO.",
      p_6_t: "6. Integration von HealthKit & Health Connect",
      p_6_c1: "Der Austausch mit Apple HealthKit oder Google Health Connect erfolgt rein lokal auf Ihrem Gerät.",
      p_6_c2: "Daten werden nur nach Ihrer expliziten Freigabe gelesen oder geschrieben.",
      p_6_c3: "Bitte beachten Sie zusätzlich die Datenschutzhinweise von Apple bzw. Google für HealthKit bzw. Health Connect.",
      p_7_t: "7. Kein Tracking / Keine Analyse",
      p_7_c1: "Die App verwendet keine Tracking- oder Analyse-SDKs (wie Firebase Analytics, Google Analytics oder Sentry). Es findet keine Profilbildung zu Marketingzwecken statt.",
      p_8_t: "8. Speicherdauer",
      p_8_l1: "App-Daten: Verbleiben auf Ihrem Gerät, bis Sie diese löschen oder die App deinstallieren.",
      p_8_l2: "E-Mails: Werden nur so lange gespeichert, wie für die Bearbeitung der Anfrage und Dokumentation erforderlich, sofern keine gesetzlichen Aufbewahrungspflichten bestehen.",
      p_9_t: "9. Webhosting (GitHub Pages)",
      p_9_c1: "Wir hosten diese Website bei GitHub Pages. Dienstanbieter ist GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA (bzw. GitHub B.V., Vijzelstraat 68-72, 1017 HL Amsterdam, Niederlande, laut GitHub‑Privacy‑Policy).",
      p_9_c2: "Beim Aufruf unserer Website stellt Ihr Browser eine Verbindung zu den Servern von GitHub her. Dabei werden technisch bedingt personenbezogene Daten wie Ihre IP‑Adresse, die aufgerufene URL, Datum und Uhrzeit sowie Informationen zu Browser und Betriebssystem in Server‑Logfiles verarbeitet.",
      p_9_c3: "Rechtsgrundlage ist unser berechtigtes Interesse an einer sicheren und effizienten Bereitstellung unseres Webangebots gemäß Art. 6 Abs. 1 lit. f DSGVO.",
      p_9_c4: "Weitere Informationen finden Sie in der Datenschutzerklärung von GitHub unter https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement.",
      p_10_t: "10. Ihre Betroffenenrechte",
      p_10_c1: "Sie haben gegenüber dem Verantwortlichen folgende Rechte:",
      p_10_l1: "Auskunft (Art. 15 DSGVO)",
      p_10_l2: "Berichtigung (Art. 16 DSGVO)",
      p_10_l3: "Löschung (Art. 17 DSGVO)",
      p_10_l4: "Einschränkung der Verarbeitung (Art. 18 DSGVO)",
      p_10_l5: "Datenübertragbarkeit (Art. 20 DSGVO)",
      p_10_l6: "Widerspruch (Art. 21 DSGVO)",
      p_10_l7: "Widerruf erteilter Einwilligungen (Art. 7 Abs. 3 DSGVO) mit Wirkung für die Zukunft.",
      p_10_c2: "Zudem haben Sie das Recht auf Beschwerde bei einer Aufsichtsbehörde (Art. 77 DSGVO), z. B. der Berliner Beauftragten für Datenschutz und Informationsfreiheit.",
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
      recovery_how_c1: "Der Tracker nutzt ein 'Equivalent Set'-Modell. Studien (z. B. Vieira et al., 2021) zeigen, dass Training bis zum Versagen (0 RIR) die Regenerationszeit signifikant verlängert, teils um 24–48 Stunden im Vergleich zu submaximalem Training.",
      recovery_how_c2: "Train Libre gewichtet Arbeitssätze entsprechend. Ein Satz mit 0 RIR wird als hochgradig ermüdend markiert, was das geschätzte Regenerationsfenster erweitert. Das System erkennt zudem, dass Verbundübungen wie Bankdrücken nicht nur die Brust, sondern auch Trizeps und vordere Schultern belasten.",
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
      adapt_nut_how_c3: "Um das 'Rauschen' durch Wassereinlagerungen und Glykogenspringer zu handhaben, nutzt das System eine 7-Tage-Bestätigungsregel für Zieländerungen und phasenspezifische Skalierungsfaktoren für die Energiedichte (kcal/kg).",
      adapt_nut_limits_t: "Unsicherheit & Interpretation",
      adapt_nut_limits_l1: "Trend vs. Rauschen: Der Algorithmus priorisiert den langfristigen Trend. Er reagiert daher eventuell verzögert auf schnelle, kurzfristige Änderungen.",
      adapt_nut_limits_l2: "Logging-Konsistenz: Die Präzision der Schätzung hängt vollständig von der Konsistenz deiner Aufzeichnungen ab. Lückenhafte Daten führen zu breiteren Unsicherheitsbereichen.",
      adapt_nut_limits_l3: "Stabilisierung: In den ersten 2-4 Wochen stützt sich das System auf Profil-Startwerte (Priors). Es wird signifikant genauer, sobald ausreichend nutzerspezifische Historie vorliegt.",
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
      ai_meal_limits_l1: "Das Volumen-Problem: Ein 2D-Foto hat keine Tiefeninformationen. Studien zeigen, dass ohne Referenzobjekt die Fehlerraten beim Volumen meist zwischen 10% und 30% liegen.",
      ai_meal_limits_l2: "Versteckte Zutaten: Die KI kann Öle, Butter oder Zucker nicht 'sehen'. Ein gegrilltes Hähnchen und ein in Fett gebratenes können identisch aussehen, unterscheiden sich aber massiv in der Kaloriendichte.",
      ai_meal_limits_l3: "Mischgerichte: Zutaten in Pfannengerichten oder Burritos sind oft verdeckt. Wenn der Reis unter dem Curry liegt, wird die KI die Portion wahrscheinlich unterschätzen.",
      ai_meal_guidance_t: "Praktische Hinweise",
      ai_meal_guidance_c: "Betrachte die KI-Erfassung als Werkzeug zur Reibungsreduzierung, nicht als absolute Wahrheit. Nutze immer den Review-Screen, um Schätzungen anzupassen."
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
    if (TRANSLATIONS[lang] && TRANSLATIONS[lang][key]) {
      // Use innerHTML if the content might contain <br> tags
      if (key.includes('address') || key.includes('_c')) {
         el.innerHTML = TRANSLATIONS[lang][key];
      } else {
         el.textContent = TRANSLATIONS[lang][key];
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
