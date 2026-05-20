# Datenschutzerklärung für die App „Train Libre“

**Version:** 1.2  
**Stand:** 20. Mai 2026  

Diese Datenschutzerklärung informiert Sie gemäß Art. 13 und 14 der Datenschutz-Grundverordnung (DSGVO) über die Verarbeitung personenbezogener Daten und gesundheitsbezogener Daten in der mobilen Applikation „Train Libre“. 

Da Train Libre als Local-First-Applikation konzipiert ist, verbleibt die vollständige Kontrolle über Ihre Daten zu jedem Zeitpunkt direkt bei Ihnen. Wir betreiben keine zentralen Datenbank- oder Anwendungsserver zur Speicherung Ihrer Profile, Workouts oder Ernährungsprotokolle.

---

## 1. Verantwortlicher

Verantwortlich für die Datenverarbeitung im Sinne des Art. 4 Nr. 7 DSGVO ist der Entwickler und Diensteanbieter:

Richard Georg Schotte  
Bundesallee 114  
12161 Berlin  
Deutschland  

E-Mail: feedback@schotte.me  
Telefon: (+49) 1520 6915571  

Da es sich bei dem Verantwortlichen um einen Einzelentwickler handelt und die gesetzlichen Voraussetzungen zur verpflichtenden Bestellung eines Datenschutzbeauftragten gemäß Art. 37 DSGVO bzw. § 38 BDSG nicht vorliegen, ist kein gesonderter Datenschutzbeauftragter bestellt. Sämtliche datenschutzbezogene Anfragen können direkt an die oben genannte E-Mail-Adresse gerichtet werden.

---

## 2. Grundphilosophie

Train Libre beruht auf dem Prinzip des „Privacy by Design“ und des „Privacy by Default“ (Art. 25 DSGVO) sowie auf dem Grundsatz der Datensparsamkeit (Art. 5 Abs. 1 lit. c DSGVO). 

* **Keine Benutzerkonten:** Für die Nutzung der App ist keine Registrierung und kein Erstellen eines Benutzerkontos erforderlich. Es werden keine E-Mail-Adressen, Passwörter oder Anmeldedaten auf externen Servern gespeichert.
* **Local-First-Architektur:** Sämtliche von Ihnen eingegebenen Profileinstellungen, sportlichen Aktivitäten, Ernährungsdaten, Vitalwerte und Messungen werden ausschließlich in einer lokalen SQLite-Datenbank auf Ihrem eigenen Endgerät gespeichert.
* **Kein zentraler Backend-Server:** Wir betreiben keine Cloud-Datenbanken und keine Anwendungsserver zur Speicherung oder Verarbeitung Ihrer Trainings- und Ernährungsdaten. Ihre Daten verbleiben in Ihrem physischen Besitz.
* **Keine Tracking- oder Analyse-SDKs:** Train Libre verzichtet vollständig auf die Integration von Werbenetzwerken, verhaltensbasierten Analyse-Diensten oder Fehlerdiagnose-SDKs von Drittanbietern (wie beispielsweise Firebase Analytics, Google Analytics, Mixpanel, Sentry oder Crashlytics). Es findet keinerlei Profilbildung oder verhaltensbezogene Auswertung zu Marketingzwecken statt.

---

## 3. Lokal verarbeitete Daten

Durch die Nutzung der App verarbeitet das Betriebssystem Ihres Mobilgeräts Daten in einer lokalen SQLite-Datenbank (Drift/sqflite). Die Speicherung dient dem Betrieb der App und der Erfüllung der Kernfunktionen.

### A. Kategorien verarbeiteter Daten

Die lokale Datenbank umfasst folgende Datenkategorien:

1. **Profileinstellungen und Ziele:** Benutzername, Geburtsdatum, Körpergröße, Geschlecht, Profilbild-Dateipfad sowie individuell festgelegte Tagesziele (Ziel-Kalorien, Ziel-Proteine, Ziel-Kohlenhydrate, Ziel-Fett, Ziel-Wasser, Ziel-Schritte).
2. **Trainings- und Aktivitätsprotokolle (Workouts):** Trainingspläne (Routinen), Übungsvorlagen, historische Workout-Protokolle (Start- und Endzeit, Notizen, Übungssätze mit rep- und Gewicht-Werten, RPE- und RIR-Werten, Pausenzeiten, kardiovaskuläre Aktivitäten inklusive Distanz, Dauer und verbrannten Kalorien).
3. **Ernährungs- und Flüssigkeitsprotokolle (Nutrition & Fluids):** Konsumierte Lebensmittel (Zeitpunkt, Menge in Gramm/Millilitern, Mahlzeitentyp), Wasser- und Getränkeprotokolle (Menge, Nährstoffgehalt, Koffeingehalt).
4. **Lebensmittel- und Produktkatalog (User-Products):** Individuell vom Benutzer angelegte Produkte mit Barcode, Produktname, Marke und Makro-/Mikronährwertangaben pro 100g/ml (Kalorien, Eiweiß, Kohlenhydrate, Fett, Zucker, Ballaststoffe, Salz, Koffein, Zutatenliste und Zusatzstoffe).
5. **Supplemente (Nahrungsergänzungsmittel):** Eingerichtete Supplemente (Name, Standarddosis, Einheit, Tagesziel und Tageslimit) sowie historische Supplement-Logeinträge mit Einnahme-Zeitpunkt und Menge.
6. **Körpermaße und Messungen (Measurements):** Historische Messwerte für das Körpergewicht und verschiedene Körperumfänge (z. B. Brust, Taille) inklusive Datum und Einheit.
7. **Pulsdaten-Aggregate:** Lokale stündliche Aggregationen der Herzfrequenz (minimale, maximale und durchschnittliche Schläge pro Minute sowie Stichprobenanzahl).
8. **Schlafdaten-Analysen:** Aufbereitete Schlafdaten inklusive Schlafphasen (Tiefschlaf, REM, Leichtschlaf, Wachphasen), Schlaf-Effizienz, Ruheherzfrequenz, Schlafunterbrechungen, Schlaf-Regularität sowie historische Rohdaten-Importe aus den System-Schnittstellen.
9. **Lokale Schrittsegmente:** Aus den System-Schnittstellen importierte Schrittzahlen mit genauen Start- und Endzeitpunkten sowie Kennungen der Datenquelle zur lokalen Bereinigung von Dubletten.

### B. Rechtsgrundlagen der Verarbeitung

Da die Speicherung und Auswertung ausschließlich lokal auf Ihrem Endgerät stattfindet, liegt die datenschutzrechtliche Verfügungsgewalt und Datenverarbeitung in Ihrer eigenen Sphäre. Soweit die App im Rahmen der DSGVO betrachtet wird, gelten folgende Rechtsgrundlagen:

* **Allgemeine Daten und Einstellungen (Art. 6 Abs. 1 lit. b DSGVO):** Die Verarbeitung allgemeiner Profileinstellungen, Trainingspläne und App-Präferenzen erfolgt zur Erfüllung des Nutzungsverhältnisses (Bereitstellung der App-Funktionalitäten).
* **Gesundheitsdaten (Art. 9 Abs. 2 lit. a DSGVO in Verbindung mit Art. 6 Abs. 1 lit. a DSGVO):** Für die Verarbeitung von körperlichen Messwerten, Pulsdaten, Schlafanalysen und Ernährungsprotokollen (welche als gesundheitsbezogene Daten unter die besonderen Kategorien fallen) erteilen Sie mit der aktiven Eingabe bzw. der Aktivierung des Imports Ihre ausdrückliche Einwilligung. Sie können diese Einwilligung jederzeit durch Löschen der entsprechenden Einträge oder durch Zurücksetzen aller App-Daten widerrufen.

---

## 4. Drittanbieter-Integrationen / BYOK

Um erweiterte Funktionen bereitzustellen, verfügt die App über Schnittstellen zu externen Diensten. Diese Funktionen sind optional und erfordern Ihre aktive Mitwirkung.

### A. Bring-Your-Own-Key (BYOK) AI Meal Capture

Train Libre bietet die Möglichkeit, Mahlzeiten über Fotos oder Freitextbeschreibungen mittels Künstlicher Intelligenz analysieren zu lassen. Diese Funktion basiert auf dem „Bring-Your-Own-Key“-Prinzip (BYOK). Sie müssen hierfür Ihren eigenen API-Schlüssel eines unterstützten Anbieters in der App hinterlegen.

* **Unterstützte Anbieter:** OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok.
* **Sichere lokale Schlüsselverwahrung:** Der von Ihnen eingegebene API-Schlüssel wird unter Verwendung des Pakets `flutter_secure_storage` verschlüsselt im gesicherten Speicherbereich des Betriebssystems abgelegt (iOS Keychain bzw. Android Keystore). Der Schlüssel verbleibt ausschließlich lokal auf Ihrem Gerät und wird niemals an uns übertragen.
* **Eingeschränkte Datenübertragung:** Bei der Nutzung der KI-Analyse sendet Ihr Gerät das aufgenommene Mahlzeiten-Foto bzw. die eingegebene Textbeschreibung direkt über eine verschlüsselte HTTPS-Verbindung an die API des ausgewählten KI-Anbieters. 
* **Privatsphärenschutz per System-Prompt:** Um Ihre Privatsphäre maximal zu schützen, ist der systemweit hinterlegte Prompt der App so konfiguriert, dass der KI-Anbieter angewiesen wird, ausschließlich Lebensmittelkomponenten zu identifizieren und deren Gewicht in Gramm zu schätzen. Der KI-Anbieter wird ausdrücklich angewiesen, **keine** Nährwertberechnungen (wie Kalorien, Proteine, Fett oder Kohlenhydrate) durchzuführen. Die Ermittlung der Nährwerte erfolgt im Anschluss vollständig lokal offline auf Ihrem Gerät durch Abgleich der erkannten Lebensmittelnamen mit Ihrem lokalen Offline-Katalog. Es wird somit keine persönliche Ernährungs- oder Gesundheitshistorie an die KI-Dienste übermittelt.
* **Verantwortlichkeit:** Da Sie Ihren persönlichen API-Schlüssel verwenden, schließen Sie direkt ein Nutzungsverhältnis mit dem jeweiligen KI-Anbieter ab. Die Datenverarbeitung durch den KI-Anbieter unterliegt dessen jeweiligen Datenschutzbestimmungen. Bitte prüfen Sie die Datenschutzrichtlinien Ihres Anbieters (insbesondere bezüglich der Datenverwendung für Trainingszwecke und der Serverstandorte), bevor Sie die Funktion nutzen. Bei Übertragungen an Anbieter außerhalb der Europäischen Union (insbesondere in die USA) erfolgt dies auf Grundlage von Standardvertragsklauseln oder Angemessenheitsbeschlüssen, die Sie mit dem Anbieter vereinbart haben.

### B. Offline-Katalog-Updates (Open Food Facts & Exercise Catalog)

Um Lebensmittel-Barcodes offline scannen und Übungen nachschlagen zu können, nutzt Train Libre lokale Produkt- und Übungskataloge. Diese Kataloge werden als vorkompilierte SQLite-Datenbankdateien direkt auf Ihr Gerät heruntergeladen.

* **Funktionsweise:** Die App prüft in regelmäßigen Abständen, ob Aktualisierungen für den Lebensmittelkatalog (basierend auf Open Food Facts) oder den Übungskatalog (basierend auf wger/GitHub) vorliegen. Die Prüfung und der anschließende Download der komprimierten Katalogdatenbanken erfolgen über eine verschlüsselte HTTPS-Verbindung direkt zu den Servern des Hosting-Dienstleisters (z. B. GitHub Pages / GitHub Inc. bzw. Open Food Facts).
* **Datenminimierung:** Beim Herunterladen der Katalog-Updates werden systembedingt technische Verbindungsdaten (insbesondere Ihre IP-Adresse, Datum/Uhrzeit des Zugriffs und der User-Agent der App) an den Hoster übertragen. Es werden zu keinem Zeitpunkt nutzergenerierte Daten, gescannte Barcodes oder persönliche Profileigenschaften an die Katalog-Hoster gesendet.
* **Lokale Barcode-Zuordnung:** Der Abgleich eines gescannten Barcodes oder die Suche nach Lebensmitteln und Übungen findet zu 100 Prozent offline auf Ihrem Gerät statt. Im Gegensatz zu herkömmlichen Ernährungs-Apps wird beim Scannen eines Produkts keine Anfrage mit dem Barcode an einen Cloud-Server gesendet.

---

## 5. Gesundheitsdaten-Schnittstellen

Train Libre kann mit den systemweiten Gesundheitsdatenbanken Ihres Betriebssystems (Apple HealthKit unter iOS bzw. Google Health Connect unter Android) interagieren. Diese Interaktion erfolgt ausschließlich lokal auf Ihrem Endgerät und erfordert Ihre ausdrückliche, jederzeit widerrufbare Freigabe in den Systemeinstellungen des jeweiligen Betriebssystems.

### A. Daten-Import (Lesen)

Sofern Sie der App die Berechtigung erteilen, liest Train Libre Daten aus Apple HealthKit bzw. Google Health Connect aus, um diese lokal in der App anzuzeigen und zu verarbeiten:
* **Schrittzahlen:** Import der aufgezeichneten Schrittzahlsegmente zur Offline-Auswertung.
* **Schlafdaten:** Import von Schlafzeiträumen und Schlafphasen.
* **Herzfrequenz:** Import von Puls-Stichproben zur Berechnung lokaler stündlicher Aggregationen.

Der Import dient ausschließlich der Darstellung und lokalen Analyse innerhalb von Train Libre. Es findet kein Transfer dieser importierten Daten an externe Server statt.

### B. Daten-Export (Schreiben & Idempotenz)

Auf Ihren Wunsch hin kann Train Libre manuell in der App erfasste Daten in die System-Gesundheitsdatenbanken (Apple HealthKit / Google Health Connect) exportieren:
* **Körpermaße:** Export von Gewichtsmessungen.
* **Ernährung und Hydration:** Export von konsumierten Nährwerten, Kalorien und Wassermengen.
* **Workouts:** Export von abgeschlossenen Trainingseinheiten.

* **Lokaler Idempotenz-Schutz:** Um zu verhindern, dass bei wiederholten Synchronisationen Daten mehrfach in Ihre System-Gesundheitsdatenbank geschrieben werden, verfügt Train Libre über ein lokales Protokollierungssystem. In der Tabelle `health_export_records` der lokalen SQLite-Datenbank wird für jeden erfolgreichen Schreibvorgang eine eindeutige ID, die Ziel-Plattform (Apple Health oder Health Connect), der Datenbereich (Domain) sowie ein eindeutiger Idempotenzschlüssel zusammen mit dem Export-Zeitstempel gespeichert. Dieser Abgleich findet rein lokal auf Ihrem Gerät statt und dient der Sicherstellung der Datenkonsistenz.

---

## 6. Datensicherheit & Backups

Da sämtliche Daten lokal auf Ihrem Endgerät liegen, ist die Sicherheit des Geräts maßgeblich für den Schutz Ihrer Daten. 

### A. Lokale Datenisolation

Das Betriebssystem (iOS/Android) isoliert die App-Daten von Train Libre durch Sandbox-Mechanismen. Andere installierte Applikationen haben ohne Ihre Zustimmung keinen Zugriff auf die lokale SQLite-Datenbank oder die in den gesicherten App-Einstellungen hinterlegten API-Schlüssel.

### B. Manuelle und automatische Backups

Die App bietet Ihnen Funktionen zur Sicherung Ihrer Daten, um Datenverlust bei Gerätewechsel oder -beschädigung vorzubeugen.

1. **Dateigenerierung und Export:** Sie können ein vollständiges Backup aller in der SQLite-Datenbank sowie in den Einstellungen gespeicherten Daten erzeugen. Dieses Backup wird als strukturierte JSON-Datei im temporären Speicherbereich des Betriebssystems generiert und über das systemeigene Teilen-Menü (Share Sheet) exportiert. Nach dem Export wird die temporäre Datei unverzüglich gelöscht.
2. **Verschlüsselung:** Zum Schutz Ihrer sensiblen Daten können Backups vor dem Export mit einem von Ihnen gewählten Passwort verschlüsselt werden. Die Verschlüsselung erfolgt lokal auf dem Gerät mittels starker kryptografischer Algorithmen. Unverschlüsselte Backups sollten stets an sicheren Speicherorten aufbewahrt werden.
3. **Automatische Backups:** Sie können automatische Backups in konfigurierbaren Intervallen aktivieren. Unter Android nutzt diese Funktion das Storage Access Framework (SAF) zur direkten Ablage in einem von Ihnen ausgewählten Zielordner. Alternativ erfolgt die Ablage im lokalen App-Dokumentenverzeichnis. Diese Backup-Dateien verbleiben auf Ihrem Gerät, es sei denn, Sie kopieren sie aktiv an einen externen Cloud-Speicherort (z. B. iCloud Drive oder Google Drive).
4. **System-Backups:** Bitte beachten Sie, dass bei aktivierten systemweiten Geräte-Backups (z. B. über Apple iCloud oder Google Drive Backup) die Anwendungsdaten von Train Libre standardmäßig vom Betriebssystem in die jeweilige Cloud hochgeladen werden. Dies liegt außerhalb unseres Einflussbereichs und kann in den Systemeinstellungen Ihres Geräts für Train Libre deaktiviert werden.

---

## 7. Betroffenenrechte

Als betroffene Person stehen Ihnen im Rahmen der DSGVO weitreichende Rechte zu. Da Train Libre eine Local-First-App ist, können Sie den Großteil dieser Rechte direkt und selbstbestimmt innerhalb der App ausüben, ohne auf unsere Mitwirkung angewiesen zu sein.

* **Recht auf Auskunft (Art. 15 DSGVO) & Datenübertragbarkeit (Art. 20 DSGVO):** Sie haben das Recht zu erfahren, welche Daten in der App gespeichert sind. Sie können Ihre vollständige Datenbank jederzeit selbst einsehen und über die integrierte Backup-Exportfunktion in einem maschinenlesbaren Format (JSON-Datei) exportieren. Zudem können Sie Berichte in Standardformaten (wie CSV) exportieren.
* **Recht auf Berichtigung (Art. 16 DSGVO):** Sie können sämtliche von Ihnen manuell erfassten Profildaten, Workouts, Ernährungsprotokolle, Körpergewichte und Einstellungen jederzeit direkt in den Benutzeroberflächen der App korrigieren oder ändern.
* **Recht auf Löschung / „Recht auf Vergessenwerden“ (Art. 17 DSGVO):** Sie können einzelne Datensätze (z. B. ein bestimmtes Workout oder ein Lebensmittel-Log) manuell in der App löschen.
* **Unwiderrufliche Datenlöschung (AppData Reset):** Die App verfügt über eine integrierte Löschfunktion für alle lokalen Anwendungsdaten. In den Einstellungen können Sie die Funktion zur vollständigen Datenlöschung ausführen. Dieser Prozess löscht unwiderruflich:
  * Alle SharedPreferences-Einstellungen und App-Zustände.
  * Alle aufgezeichneten Trainingsprotokolle, benutzerdefinierten Übungen und Routinen.
  * Alle Ernährungsprotokolle, Mahlzeitenvorlagen und benutzerdefinierten Lebensmittel.
  * Alle eingetragenen Körpermaße, Supplement-Logbücher und historischen Tagesziele.
  * Sämtliche lokal zwischengespeicherten Puls- und Schlafanalysestufen.
  * Alle in der sicheren Betriebssystem-Ablage hinterlegten API-Schlüssel für KI-Anbieter.
  
  Nach Ausführung dieser Funktion befindet sich die App im Auslieferungszustand. Bitte beachten Sie, dass bereits an Apple Health oder Google Health Connect exportierte Daten durch diese appinterne Funktion nicht gelöscht werden können, da diese in der Hoheit des Betriebssystems liegen. Sie können diese exportierten Daten jedoch jederzeit direkt in den systemeigenen Health-Apps von Apple oder Google löschen.
* **Recht auf Beschwerde bei einer Aufsichtsbehörde (Art. 77 DSGVO):** Unbeschadet der appinternen Kontrollmöglichkeiten haben Sie das Recht, Beschwerde bei einer zuständigen Datenschutz-Aufsichtsbehörde einzulegen. Dies kann beispielsweise die Aufsichtsbehörde Ihres üblichen Aufenthaltsortes, Ihres Arbeitsplatzes oder des Sitzes des Verantwortlichen sein (z. B. die Berliner Beauftragte für Datenschutz und Informationsfreiheit).

---

# Privacy Policy for the App "Train Libre"

**Version:** 1.2  
**As of:** May 20, 2026  

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

* **Supported Providers:** OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok.
* **Secure Local Key Storage:** The API key you enter is stored encrypted using the `flutter_secure_storage` package in the operating system's secured storage area (iOS Keychain or Android Keystore). The key remains exclusively local to your device and is never transmitted to us.
* **Restricted Data Transmission:** When using the AI analysis, your device sends the captured meal photo or entered text description directly via an encrypted HTTPS connection to the API of the selected AI provider.
* **Privacy Protection via System Prompt:** To maximize your privacy, the app's globally stored system prompt is configured to instruct the AI provider to identify only food components and estimate their weight in grams. The AI provider is explicitly instructed **not** to perform any nutrient calculations (such as calories, protein, fat, or carbohydrates). The determination of nutrients is then performed completely locally and offline on your device by matching the recognized food names with your local offline catalog. Thus, no personal nutrition or health history is transmitted to the AI services.
* **Responsibility:** Since you are using your personal API key, you enter into a direct user relationship with the respective AI provider. Data processing by the AI provider is subject to their respective privacy policies. Please check your provider's privacy policy (especially regarding the use of data for training purposes and server locations) before using the function. For transmissions to providers outside the European Union (especially the USA), this occurs on the basis of standard contractual clauses or adequacy decisions that you have agreed with the provider.

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
