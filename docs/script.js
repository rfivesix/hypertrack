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
      evidence_read_more: "Evidence & further reading"
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
      evidence_read_more: "Evidenz & Quellen"
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
