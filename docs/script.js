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
      p_ov_c: "Train Libre is an offline-first fitness and nutrition tracking app. Your data is stored locally on your device by default and does not require a cloud account. Sensitive data stays on your device unless you explicitly use features that access third-party providers or system services.",
      p_data_t: "Data We Process",
      p_data_c: "Depending on the features you use, the app stores profile data, workouts, nutrition logs, body measurements, and health integration data (like steps or sleep) locally on your device.",
      p_perm_t: "Permissions",
      p_perm_c: "The app requests access to the Camera (barcodes/AI photos), Gallery (profile/meal images), Notifications (reminders), and Health services (Apple Health/Google Health Connect) only when needed.",
      p_health_t: "Health and Fitness Data",
      p_health_c: "Optional health integrations allow the app to read steps, sleep, and heart-rate data, or export your logs to system health services. This is a one-way export by default.",
      p_ai_t: "AI Features",
      p_ai_c: "AI meal features are optional and use a \"Bring Your Own Key\" (BYOK) model. Data is only sent to your chosen provider when you use these features.",
      p_back_t: "Backups and Portability",
      p_back_c: "You can create local backups or exports. You are responsible for the security of these files once they leave the app's local storage.",
      p_cat_t: "Remote Catalogs",
      p_cat_c: "The app fetches public exercise and food catalog updates. These requests only download data and do not upload your personal logs.",
      p_ads_t: "Ads, Analytics, and Tracking",
      p_ads_c: "Train Libre does not include advertising, third-party analytics SDKs, or trackers. All statistics are computed locally.",
      p_sec_t: "Data Storage and Security",
      p_sec_c: "Primary data is stored locally. Security depends on your device's operating system and lock screen protections.",
      p_ctrl_t: "Your Controls",
      p_ctrl_c: "You decide which features to enable. You can delete entries or your entire profile within the app at any time.",
      p_child_t: "Children",
      p_child_c: "Train Libre is intended for users who can responsibly manage their own health and fitness data.",
      p_cont_t: "Contact"
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
      p_health_c_1: "Optionale Health-Integrationen ermöglichen das Lesen und Schreiben von Gesundheitsdaten.",
      p_health_c_2: "Bei Freigabe liest die App Schritte, Schlafdauer/-phasen und Herzfrequenzdaten aus.",
      p_health_c_3: "Ebenso können Körpermaße, Nährwerte und Workouts an Systemdienste exportiert werden.",
      p_health_c_4: "Dies erfolgt als Einweg-Export; Train Libre bleibt die primäre Quelle deiner Daten.",
      p_ai_t: "KI-Funktionen",
      p_ai_c_1: "Die Mahlzeitenerkennung via KI ist optional und standardmäßig deaktiviert.",
      p_ai_c_2: "Sie nutzt ein \"Bring Your Own Key\" (BYOK)-Modell. Daten werden nur an den von dir gewählten Provider gesendet.",
      p_ai_c_3: "Vom Provider gelieferte Schätzwerte werden lokal abgeglichen und können vor dem Speichern angepasst werden.",
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
      p_cont_t: "Kontakt"
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
})();
