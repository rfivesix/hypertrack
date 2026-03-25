// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Hypertrack';

  @override
  String get bannerText => 'Empfehlung / Aktuelles Workout';

  @override
  String get calories => 'Kalorien';

  @override
  String get water => 'Wasser';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Kohlenhydrate';

  @override
  String get fat => 'Fett';

  @override
  String get daily => 'Täglich';

  @override
  String get today => 'Heute';

  @override
  String get workoutSection => 'Workout-Bereich - noch nicht implementiert';

  @override
  String get addMenuTitle => 'Was möchtest du hinzufügen?';

  @override
  String get addFoodOption => 'Lebensmittel hinzufügen';

  @override
  String get addLiquidOption => 'Flüssigkeit hinzufügen';

  @override
  String get searchHintText => 'Suchen...';

  @override
  String get mealtypeBreakfast => 'Frühstück';

  @override
  String get mealtypeLunch => 'Mittagessen';

  @override
  String get mealtypeDinner => 'Abendessen';

  @override
  String get mealtypeSnack => 'Snack';

  @override
  String get waterHeader => 'Wasser & Getränke';

  @override
  String get openFoodFactsSource => 'Daten von Open Food Facts';

  @override
  String get tabRecent => 'Zuletzt';

  @override
  String get tabSearch => 'Suchen';

  @override
  String get tabFavorites => 'Favoriten';

  @override
  String get fabCreateOwnFood => 'Eigenes Lebensmittel';

  @override
  String get recentEmptyState =>
      'Deine zuletzt verwendeten Lebensmittel\nerscheinen hier.';

  @override
  String get favoritesEmptyState =>
      'Du hast noch keine Favoriten.\nMarkiere ein Lebensmittel mit dem Herz-Icon, um es hier zu sehen.';

  @override
  String get searchInitialHint => 'Bitte gib einen Suchbegriff ein.';

  @override
  String get searchNoResults => 'Keine Ergebnisse gefunden.';

  @override
  String get createFoodScreenTitle => 'Eigenes Lebensmittel erstellen';

  @override
  String get formFieldName => 'Name des Lebensmittels';

  @override
  String get formFieldBrand => 'Marke (optional)';

  @override
  String get formSectionMainNutrients => 'Haupt-Nährwerte (pro 100g)';

  @override
  String get formFieldCalories => 'Kalorien (kcal)';

  @override
  String get formFieldProtein => 'Protein (g)';

  @override
  String get formFieldCarbs => 'Kohlenhydrate (g)';

  @override
  String get formFieldFat => 'Fett (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Weitere Nährwerte (optional, pro 100g)';

  @override
  String get formFieldSugar => 'Davon Zucker (g)';

  @override
  String get formFieldFiber => 'Ballaststoffe (g)';

  @override
  String get formFieldKj => 'Kilojoule (kJ)';

  @override
  String get formFieldSalt => 'Salz (g)';

  @override
  String get formFieldSodium => 'Natrium (mg)';

  @override
  String get formFieldCalcium => 'Kalzium (mg)';

  @override
  String get buttonSave => 'Speichern';

  @override
  String get validatorPleaseEnterName => 'Bitte gib einen Namen ein.';

  @override
  String get validatorPleaseEnterNumber => 'Bitte gib eine gültige Zahl ein.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName wurde erfolgreich gespeichert.';
  }

  @override
  String get foodDetailSegmentPortion => 'Portion';

  @override
  String get foodDetailSegment100g => '100g';

  @override
  String get sugar => 'Zucker';

  @override
  String get fiber => 'Ballaststoffe';

  @override
  String get salt => 'Salz';

  @override
  String get explorerScreenTitle => 'Lebensmittel-Explorer';

  @override
  String get nutritionScreenTitle => 'Ernährungsanalyse';

  @override
  String get entriesForDateRangeLabel => 'Einträge für';

  @override
  String get noEntriesForPeriod => 'Noch keine Einträge für diesen Zeitraum.';

  @override
  String get waterEntryTitle => 'Wasser';

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileDailyGoals => 'Tägliche Ziele';

  @override
  String get profileDailyGoalsCL => 'TÄGLICHE ZIELE';

  @override
  String get snackbarGoalsSaved => 'Ziele erfolgreich gespeichert!';

  @override
  String get measurementsScreenTitle => 'Messwerte';

  @override
  String get measurementsEmptyState =>
      'Noch keine Messwerte erfasst.\nBeginne mit dem \'+\' Button.';

  @override
  String get addMeasurementDialogTitle => 'Neuer Messwert';

  @override
  String get formFieldMeasurementType => 'Art der Messung';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Wert ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Bitte Wert eingeben';

  @override
  String get measurementWeight => 'Körpergewicht';

  @override
  String get measurementFatPercent => 'Körperfett';

  @override
  String get measurementNeck => 'Nacken';

  @override
  String get measurementShoulder => 'Schulter';

  @override
  String get measurementChest => 'Brust';

  @override
  String get measurementLeftBicep => 'Linker Bizeps';

  @override
  String get measurementRightBicep => 'Rechter Bizeps';

  @override
  String get measurementLeftForearm => 'Linker Unterarm';

  @override
  String get measurementRightForearm => 'Rechter Unterarm';

  @override
  String get measurementAbdomen => 'Bauch';

  @override
  String get measurementWaist => 'Taille';

  @override
  String get measurementHips => 'Hüfte';

  @override
  String get measurementLeftThigh => 'Linker Oberschenkel';

  @override
  String get measurementRightThigh => 'Rechter Oberschenkel';

  @override
  String get measurementLeftCalf => 'Linke Wade';

  @override
  String get measurementRightCalf => 'Rechte Wade';

  @override
  String get drawerMenuTitle => 'Hypertrack Menü';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerFoodExplorer => 'Lebensmittel-Explorer';

  @override
  String get drawerDataManagement => 'Datensicherung';

  @override
  String get drawerMeasurements => 'Messwerte';

  @override
  String get dataManagementTitle => 'Datensicherung';

  @override
  String get exportCardTitle => 'Daten exportieren';

  @override
  String get exportCardDescription =>
      'Sichert alle deine Tagebucheinträge, Favoriten und eigenen Lebensmittel in einer einzigen Backup-Datei.';

  @override
  String get exportCardButton => 'Backup erstellen';

  @override
  String get importCardTitle => 'Daten importieren';

  @override
  String get importCardDescription =>
      'Stellt deine Daten aus einer zuvor erstellten Backup-Datei wieder her. ACHTUNG: Alle aktuell in der App gespeicherten Daten werden dabei überschrieben!';

  @override
  String get importCardButton => 'Backup wiederherstellen';

  @override
  String get recommendationDefault => 'Tracke deine erste Mahlzeit!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Letzte $count Tage: +$difference kcal über dem Ziel';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Letzte $count Tage: $difference kcal unter dem Ziel';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Letzte $count Tage: Ziel erreicht ✅';
  }

  @override
  String get recommendationFirstEntry =>
      'Super, dein erster Eintrag ist gemacht!';

  @override
  String get dialogConfirmTitle => 'Bestätigung erforderlich';

  @override
  String get dialogConfirmImportContent =>
      'Möchtest du wirklich die Daten aus diesem Backup wiederherstellen?\n\nACHTUNG: Alle deine aktuellen Einträge, Favoriten und eigenen Lebensmittel werden unwiderruflich gelöscht und ersetzt.';

  @override
  String get dialogButtonCancel => 'Abbrechen';

  @override
  String get dialogButtonOverwrite => 'Ja, alles überschreiben';

  @override
  String get snackbarNoFileSelected => 'Keine Datei ausgewählt.';

  @override
  String get snackbarImportSuccessTitle => 'Import erfolgreich!';

  @override
  String get snackbarImportSuccessContent =>
      'Deine Daten wurden wiederhergestellt. Für eine korrekte Anzeige wird empfohlen, die App jetzt neu zu starten.';

  @override
  String get snackbarButtonOK => 'OK';

  @override
  String get snackbarImportError => 'Fehler beim Importieren der Daten.';

  @override
  String get snackbarExportSuccess =>
      'Backup-Datei wurde an das System übergeben. Bitte wähle einen Speicherort.';

  @override
  String get snackbarExportFailed => 'Export abgebrochen oder fehlgeschlagen.';

  @override
  String get profileUserHeight => 'Körpergröße (cm)';

  @override
  String get workoutRoutinesTitle => 'Trainingspläne';

  @override
  String get workoutHistoryTitle => 'Workout-Verlauf';

  @override
  String get workoutHistoryButton => 'Verlauf';

  @override
  String get emptyRoutinesTitle => 'Keine Trainingspläne gefunden';

  @override
  String get emptyRoutinesSubtitle =>
      'Erstelle deinen ersten Trainingsplan oder starte ein freies Training.';

  @override
  String get createFirstRoutineButton => 'Ersten Plan erstellen';

  @override
  String get startEmptyWorkoutButton => 'Freies Training';

  @override
  String get editRoutineSubtitle =>
      'Tippen zum Bearbeiten, oder starte das Training.';

  @override
  String get startButton => 'Start';

  @override
  String get addRoutineButton => 'Neue Routine';

  @override
  String get freeWorkoutTitle => 'Freies Training';

  @override
  String get finishWorkoutButton => 'Beenden';

  @override
  String get addSetButton => 'Satz hinzufügen';

  @override
  String get addExerciseToWorkoutButton => 'Übung zum Workout hinzufügen';

  @override
  String get lastTimeLabel => 'Letztes Mal';

  @override
  String get setLabel => 'Satz';

  @override
  String get kgLabel => 'Gewicht (kg)';

  @override
  String get repsLabel => 'Wdh';

  @override
  String get restTimerLabel => 'Pause';

  @override
  String get skipButton => 'Überspringen';

  @override
  String get emptyHistory => 'Noch keine Workouts abgeschlossen.';

  @override
  String get workoutDetailsTitle => 'Workout-Details';

  @override
  String get workoutNotFound => 'Workout nicht gefunden.';

  @override
  String get totalVolumeLabel => 'Gesamtvolumen';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get hevyImportTitle => 'Hevy Import';

  @override
  String get hevyImportDescription =>
      'Importiere deine gesamte Trainings-Historie aus einer Hevy CSV-Exportdatei.';

  @override
  String get hevyImportButton => 'Hevy-Daten importieren';

  @override
  String hevyImportSuccess(Object count) {
    return '$count Workouts erfolgreich importiert!';
  }

  @override
  String get hevyImportFailed =>
      'Import fehlgeschlagen. Bitte überprüfe die Datei.';

  @override
  String get startWorkout => 'Workout starten';

  @override
  String get addMeasurement => 'Messwert hinzufügen';

  @override
  String get filterToday => 'Heute';

  @override
  String get filter7Days => '7 Tage';

  @override
  String get filter30Days => '30 Tage';

  @override
  String get filterAll => 'Alle';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get showMoreDetails => 'Mehr Details anzeigen';

  @override
  String get deleteConfirmTitle => 'Löschen bestätigen';

  @override
  String get deleteConfirmContent =>
      'Möchtest du diesen Eintrag wirklich löschen?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get tabBaseFoods => 'Grundnahrungsmittel';

  @override
  String get baseFoodsEmptyState =>
      'Dieser Bereich wird bald mit einer kuratierten Liste von Grundnahrungsmitteln wie Obst, Gemüse und mehr gefüllt sein.';

  @override
  String get noBrand => 'Keine Marke';

  @override
  String get unknown => 'Unbekannt';

  @override
  String backupFileSubject(String timestamp) {
    return 'Hypertrack App Backup - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100g';
  }

  @override
  String foodListSubtitle(int grams, String time) {
    return '${grams}g - $time';
  }

  @override
  String foodListTrailingKcal(int calories) {
    return '$calories kcal';
  }

  @override
  String waterListTrailingMl(int milliliters) {
    return '$milliliters ml';
  }

  @override
  String get exerciseCatalogTitle => 'Übungskatalog';

  @override
  String get filterByMuscle => 'Nach Muskelgruppe filtern';

  @override
  String get noExercisesFound => 'Keine Übungen gefunden.';

  @override
  String get noDescriptionAvailable => 'Keine Beschreibung verfügbar.';

  @override
  String get filterByCategory => 'Nach Kategorie filtern';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get repsLabelShort => 'Wdh';

  @override
  String get titleNewRoutine => 'Neue Routine';

  @override
  String get titleEditRoutine => 'Routine bearbeiten';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Bitte gib der Routine einen Namen.';

  @override
  String get snackbarRoutineCreated =>
      'Routine erstellt. Füge nun Übungen hinzu.';

  @override
  String get snackbarRoutineSaved => 'Routine gespeichert.';

  @override
  String get formFieldRoutineName => 'Name der Routine';

  @override
  String get emptyStateAddFirstExercise => 'Füge deine erste Übung hinzu.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Übung hinzufügen';

  @override
  String get kgLabelShort => 'kg';

  @override
  String get drawerExerciseCatalog => 'Übungskatalog';

  @override
  String get lastWorkoutTitle => 'Letztes Workout';

  @override
  String get repeatButton => 'Wiederholen';

  @override
  String get weightHistoryTitle => 'Gewichtsverlauf';

  @override
  String get hideSummary => 'Übersicht ausblenden';

  @override
  String get showSummary => 'Übersicht einblenden';

  @override
  String get exerciseDataAttribution => 'Übungsdaten von wger';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Möchtest du den Trainingsplan \'$routineName\' wirklich unwiderruflich löschen?';
  }

  @override
  String get editPauseTimeTitle => 'Pausendauer bearbeiten';

  @override
  String get pauseInSeconds => 'Pause in Sekunden';

  @override
  String get editPauseTime => 'Pause bearbeiten';

  @override
  String pauseDuration(int seconds) {
    return '$seconds Sekunden Pause';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Pausen bis zu ${seconds}s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Möchtest du dieses protokollierte Workout wirklich unwiderruflich löschen?';

  @override
  String get removeExercise => 'Übung entfernen';

  @override
  String get deleteExerciseConfirmTitle => 'Übung entfernen?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Möchtest du \'$exerciseName\' wirklich aus diesem Trainingsplan entfernen?';
  }

  @override
  String get doneButtonLabel => 'Fertig';

  @override
  String get setRestTimeButton => 'Pause einstellen';

  @override
  String get deleteExerciseButton => 'Übung löschen';

  @override
  String get restOverLabel => 'Pause vorbei';

  @override
  String get workoutRunningLabel => 'Workout läuft …';

  @override
  String get continueButton => 'Weiter';

  @override
  String get discardButton => 'Verwerfen';

  @override
  String get workoutStatsTitle => 'Training (7 Tage)';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get durationLabel => 'Dauer';

  @override
  String get volumeLabel => 'Volumen';

  @override
  String get setsLabel => 'Sätze';

  @override
  String get muscleSplitLabel => 'Muskel-Split';

  @override
  String get snackbar_could_not_open_open_link => 'Konnte Link nicht öffnen';

  @override
  String get chart_no_data_for_period => 'Keine Daten für diesen Zeitraum.';

  @override
  String get amount_in_milliliters => 'Menge in Millilitern';

  @override
  String get amount_in_grams => 'Menge in Gramm';

  @override
  String get meal_label => 'Mahlzeit';

  @override
  String get add_to_water_intake => 'Zur Trinkmenge hinzufügen';

  @override
  String get create_exercise_screen_title => 'Eigene Übung erstellen';

  @override
  String get exercise_name_label => 'Name der Übung';

  @override
  String get category_label => 'Kategorie';

  @override
  String get description_optional_label => 'Beschreibung (optional)';

  @override
  String get primary_muscles_label => 'Primäre Muskeln';

  @override
  String get primary_muscles_hint => 'z.B. Brust, Trizeps';

  @override
  String get secondary_muscles_label => 'Sekundäre Muskeln (optional)';

  @override
  String get secondary_muscles_hint => 'z.B. Schultern';

  @override
  String get set_type_normal => 'Normal';

  @override
  String get set_type_warmup => 'Warmup';

  @override
  String get set_type_failure => 'Failure';

  @override
  String get set_type_dropset => 'Dropset';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => 'Exportieren';

  @override
  String get data_import_button => 'Importieren';

  @override
  String get snackbar_button_ok => 'OK';

  @override
  String get measurement_session_detail_view =>
      'Detailansicht der Messsession.';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Profilbild löschen';

  @override
  String get attribution_title => 'Attribution';

  @override
  String get add_liquid_title => 'Flüssigkeit hinzufügen';

  @override
  String get add_button => 'Hinzufügen';

  @override
  String get discard_button => 'Verwerfen';

  @override
  String get continue_workout_button => 'Fortsetzen';

  @override
  String get soon_available_snackbar =>
      'Dieser Screen wird bald verfügbar sein!';

  @override
  String get start_button => 'Start';

  @override
  String get today_overview_text => 'HEUTE IM BLICK';

  @override
  String get quick_add_text => 'SCHNELLES HINZUFÜGEN';

  @override
  String get scann_barcode_capslock => 'Barcode scannen';

  @override
  String get protocol_today_capslock => 'HEUTIGES PROTOKOLL';

  @override
  String get my_plans_capslock => 'MEINE PLÄNE';

  @override
  String get overview_capslock => 'ÜBERBLICK';

  @override
  String get manage_all_plans => 'Alle Pläne verwalten';

  @override
  String get free_training => 'Freies Training';

  @override
  String get my_consistency => 'MEINE KONSISTENZ';

  @override
  String get calendar_currently_not_available =>
      'Die Kalender-Ansicht ist in Kürze verfügbar.';

  @override
  String get in_depth_analysis => 'TIEFEN-ANALYSE';

  @override
  String get body_measurements => 'Körpermaße';

  @override
  String get measurements_description =>
      'Gewicht, KFA und Umfänge analysieren.';

  @override
  String get nutrition_description => 'Makros, Kalorien und Trends auswerten.';

  @override
  String get training_analysis => 'Trainings-Analyse';

  @override
  String get training_analysis_description =>
      'Volumen, Kraft und Progression verfolgen.';

  @override
  String get load_dots => 'lade...';

  @override
  String get profile_capslock => 'PROFIL';

  @override
  String get settings_capslock => 'EINSTELLUNGEN';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get my_goals => 'Meine Ziele';

  @override
  String get my_goals_description => 'Kalorien, Makros und Wasser anpassen.';

  @override
  String get backup_and_import => 'Datensicherung & Import';

  @override
  String get backup_and_import_description =>
      'Backups erstellen, wiederherstellen und Daten importieren.';

  @override
  String get about_and_legal_capslock => 'ÜBER & RECHTLICHES';

  @override
  String get attribution_and_license => 'Attribution & Lizenzen';

  @override
  String get data_from_off_and_wger => 'Daten von Open Food Facts und wger.';

  @override
  String get app_version => 'App Version';

  @override
  String get all_measurements => 'ALLE MESSWERTE';

  @override
  String get date_and_time_of_measurement => 'Datum & Uhrzeit der Messung';

  @override
  String get onbWelcomeTitle => 'Willkommen bei Hypertrack';

  @override
  String get onbWelcomeBody =>
      'Starte mit deinen persönlichen Zielen für Training und Ernährung.';

  @override
  String get onbTrackTitle => 'Alles tracken';

  @override
  String get onbTrackBody =>
      'Erfasse Ernährung, Workouts und Messwerte — alles an einem Ort.';

  @override
  String get onbPrivacyTitle => 'Offline-first & Privatsphäre';

  @override
  String get onbPrivacyBody =>
      'Deine Daten bleiben auf dem Gerät. Keine Cloud-Konten, kein Hintergrund-Sync.';

  @override
  String get onbFinishTitle => 'Alles bereit';

  @override
  String get onbFinishBody =>
      'Du kannst loslegen. Einstellungen lassen sich jederzeit anpassen.';

  @override
  String get onbFinishCta => 'Los geht’s!';

  @override
  String get onbShowTutorialAgain => 'Tutorial erneut anzeigen';

  @override
  String get onbSetGoalsCta => 'Ziele festlegen';

  @override
  String get onbHeaderTitle => 'Tutorial';

  @override
  String get onbHeaderSkip => 'Überspringen';

  @override
  String get onbBack => 'Zurück';

  @override
  String get onbNext => 'Weiter';

  @override
  String get onbGuideTitle => 'So funktioniert das Tutorial';

  @override
  String get onbGuideBody =>
      'Wische zwischen den Folien oder nutze Weiter. Tippe die Buttons auf jeder Folie, um Funktionen auszuprobieren. Du kannst jederzeit über Überspringen beenden.';

  @override
  String get onbCtaOpenNutrition => 'Ernährung öffnen';

  @override
  String get onbCtaLearnMore => 'Mehr erfahren';

  @override
  String get onbBadgeDone => 'Erledigt';

  @override
  String get onbTipSetGoals => 'Tipp: Lege zuerst deine Ziele fest';

  @override
  String get onbTipAddEntry => 'Tipp: Füge heute einen Eintrag hinzu';

  @override
  String get onbTipLocalControl => 'Du kontrollierst alle Daten lokal';

  @override
  String get onbTrackHowBody =>
      'So erfasst du Ernährung:\n• Öffne den Tab „Food“.\n• Tippe auf das + Symbol.\n• Suche Produkte oder scanne einen Barcode.\n• Passe Portion und Uhrzeit an.\n• Speichere in deinem Tagebuch.';

  @override
  String get onbMeasureTitle => 'Messwerte erfassen';

  @override
  String get onbMeasureBody =>
      'So fügst du Messungen hinzu:\n• Öffne den Tab „Stats“.\n• Tippe auf das + Symbol.\n• Wähle eine Messgröße (z. B. Gewicht, Taille, KFA).\n• Gib Wert und Uhrzeit ein.\n• Speichere deinen Eintrag.';

  @override
  String get onbTipMeasureToday =>
      'Tipp: Trage dein heutiges Gewicht ein, um den Graphen zu starten';

  @override
  String get onbTrainTitle => 'Trainieren mit Routinen';

  @override
  String get onbTrainBody =>
      'Routine erstellen und Workout starten:\n• Öffne den Tab „Train“.\n• Tippe auf Routine erstellen und füge Übungen und Sätze hinzu.\n• Speichere die Routine.\n• Tippe auf Start, um zu beginnen – oder nutze „Freies Training starten“.';

  @override
  String get onbTipStartWorkout =>
      'Tipp: Starte ein freies Training für eine schnelle Einheit';

  @override
  String get unitsSection => 'Einheiten';

  @override
  String get weightUnit => 'Gewichtseinheit';

  @override
  String get lengthUnit => 'Längeneinheit';

  @override
  String get comingSoon => 'In Kürze verfügbar';

  @override
  String get noFavorites => 'Keine Favoriten';

  @override
  String get nothingTrackedYet => 'Noch nichts erfasst';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'Kein Produkt für Barcode \"$barcode\" gefunden.';
  }

  @override
  String get categoryHint => 'z.B. Brust, Rücken, Beine...';

  @override
  String get validatorPleaseEnterCategory => 'Bitte eine Kategorie angeben.';

  @override
  String get dialogEnterPasswordImport => 'Passwort für den Import eingeben';

  @override
  String get dataManagementBackupTitle => 'Hypertrack Datensicherung';

  @override
  String get dataManagementBackupDescription =>
      'Sichere oder wiederherstelle alle deine App-Daten. Ideal für einen Gerätewechsel.';

  @override
  String get exportEncrypted => 'Verschlüsselt exportieren';

  @override
  String get dialogPasswordForExport => 'Passwort für verschlüsselten Export';

  @override
  String get snackbarEncryptedBackupShared => 'Verschlüsseltes Backup geteilt.';

  @override
  String get exportFailed => 'Export fehlgeschlagen.';

  @override
  String get csvExportTitle => 'Daten-Export (CSV)';

  @override
  String get csvExportDescription =>
      'Exportiere Teile deiner Daten als CSV-Datei zur Analyse in anderen Programmen.';

  @override
  String get snackbarSharingNutrition => 'Ernährungstagebuch wird geteilt...';

  @override
  String get snackbarExportFailedNoEntries =>
      'Export fehlgeschlagen. Eventuell existieren noch keine Einträge.';

  @override
  String get snackbarSharingMeasurements => 'Messwerte werden geteilt...';

  @override
  String get snackbarSharingWorkouts => 'Trainingsverlauf wird geteilt...';

  @override
  String get mapExercisesTitle => 'Übungen zuordnen';

  @override
  String get mapExercisesDescription =>
      'Unbekannte Namen aus Logs auf wger-Übungen mappen.';

  @override
  String get mapExercisesButton => 'Mapping starten';

  @override
  String get autoBackupTitle => 'Automatische Backups';

  @override
  String get autoBackupDescription =>
      'Legt periodisch eine Sicherung im Ordner ab. Derzeitiger Ordner:';

  @override
  String get autoBackupDefaultFolder => 'App-Dokumente/Backups (Standard)';

  @override
  String get autoBackupChooseFolder => 'Ordner wählen';

  @override
  String get autoBackupCopyPath => 'Pfad kopieren';

  @override
  String get autoBackupRunNow => 'Jetzt Auto-Backup prüfen & ausführen';

  @override
  String get snackbarAutoBackupSuccess => 'Auto-Backup durchgeführt.';

  @override
  String get snackbarAutoBackupFailed =>
      'Auto-Backup fehlgeschlagen oder abgebrochen.';

  @override
  String get noUnknownExercisesFound => 'Keine unbekannten Übungen gefunden';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Auto-Backup-Ordner gesetzt:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Pfad kopiert';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get involvedMuscles => 'Involvierte Muskeln';

  @override
  String get primaryLabel => 'Primär:';

  @override
  String get secondaryLabel => 'Sekundär:';

  @override
  String get noMusclesSpecified => 'Keine Muskeln angegeben.';

  @override
  String get noSelection => 'Keine Auswahl';

  @override
  String get selectButton => 'Auswählen';

  @override
  String get applyingChanges => 'Wird angewendet...';

  @override
  String get applyMapping => 'Zuordnung anwenden';

  @override
  String get personalData => 'Persönliche Daten';

  @override
  String get personalDataCL => 'PERSÖNLICHE DATEN';

  @override
  String get macroDistribution => 'Makronährstoff-Verteilung';

  @override
  String get dialogFinishWorkoutBody =>
      'Möchtest du dieses Workout wirklich abschließen?';

  @override
  String get attributionText =>
      'Diese App verwendet Daten von externen Quellen:\n\n● Übungsdaten und Bilder von wger (wger.de), lizenziert unter der CC-BY-SA 4.0 Lizenz.\n\n● Lebensmittel-Datenbank von Open Food Facts (openfoodfacts.org), verfügbar unter der Open Database License (ODbL).';

  @override
  String get errorRoutineNotFound => 'Routine nicht gefunden';

  @override
  String get workoutHistoryEmptyTitle => 'Dein Verlauf ist leer';

  @override
  String get workoutSummaryTitle => 'Workout Abgeschlossen';

  @override
  String get workoutSummaryExerciseOverview => 'Übersicht der Übungen';

  @override
  String get nutritionDiary => 'Ernährungstagebuch';

  @override
  String get detailedNutrientGoals => 'Detail-Nährwerte';

  @override
  String get detailedNutrientGoalsCL => 'DETAIL-NÄHRWERTE';

  @override
  String get supplementTrackerTitle => 'Supplement-Tracker';

  @override
  String get supplementTrackerDescription =>
      'Ziele, Limits und Einnahmen verfolgen.';

  @override
  String get createSupplementTitle => 'Supplement erstellen';

  @override
  String get supplementNameLabel => 'Name des Supplements';

  @override
  String get defaultDoseLabel => 'Standard-Dosis';

  @override
  String get unitLabel => 'Einheit';

  @override
  String get dailyGoalLabel => 'Tagesziel (optional)';

  @override
  String get dailyLimitLabel => 'Tageslimit (optional)';

  @override
  String get dailyProgressTitle => 'Tagesfortschritt';

  @override
  String get todaysLogTitle => 'Heutiges Protokoll';

  @override
  String get logIntakeTitle => 'Einnahme protokollieren';

  @override
  String get emptySupplementGoals =>
      'Lege Ziele oder Limits für Supplements fest, um deinen Fortschritt hier zu sehen.';

  @override
  String get emptySupplementLogs =>
      'Noch keine Einnahmen für heute protokolliert.';

  @override
  String get doseLabel => 'Dosis';

  @override
  String get settingsDescription => 'Thema, Einheiten, Daten und mehr';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get caffeinePrompt => 'Koffein (optional)';

  @override
  String get caffeineUnit => 'mg pro 100ml';

  @override
  String get profile => 'Profil';

  @override
  String get measurementWeightCapslock => 'KÖRPERGEWICHT';

  @override
  String get diary => 'Tagebuch';

  @override
  String get analysis => 'Analyse';

  @override
  String get yesterday => 'Gestern';

  @override
  String get dayBeforeYesterday => 'Vorgestern';

  @override
  String get statistics => 'Statistiken';

  @override
  String get workout => 'Workout';

  @override
  String get addFoodTitle => 'Lebensmittel hinzufügen';

  @override
  String get nutritionExplorerTitle => 'Lebensmittel Explorer';

  @override
  String get myMeals => 'Meine Mahlzeiten';

  @override
  String get myMealsCL => 'MEINE MAHLZEITEN';

  @override
  String get supplement_caffeine => 'Koffein';

  @override
  String get supplement_creatine_monohydrate => 'Kreatin Monohydrat';

  @override
  String get manageSupplementsTitle => 'Supplements verwalten';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get operationNotAllowed => 'Diese Aktion nicht erlaubt.';

  @override
  String get emptySupplements => 'Noch keine Supplements vorhanden';

  @override
  String get undo => 'Rückgängig';

  @override
  String get deleteSupplementConfirm =>
      'Möchtest du dieses Supplement wirklich löschen? Alle historischen Daten gehen verloren.\n\nTipp: Du kannst stattdessen auch einfach das Tracking beenden, indem du das Supplement bearbeitest.';

  @override
  String get fieldRequired => 'Pflichtfeld';

  @override
  String get unitNotSupported => 'Einheit wird nicht unterstützt.';

  @override
  String get caffeineUnitLocked => 'Bei Koffein ist die Einheit fest: mg.';

  @override
  String get caffeineMustBeMg => 'Koffein muss in mg erfasst werden.';

  @override
  String get tabCatalogSearch => 'Katalog';

  @override
  String get tabMeals => 'Mahlzeiten';

  @override
  String get emptyCategory => 'Keine Einträge';

  @override
  String get searchSectionBase => 'Grundnahrungsmittel';

  @override
  String get searchSectionOther => 'Weitere Treffer';

  @override
  String get mealsComingSoonTitle => 'Mahlzeiten (in Vorbereitung)';

  @override
  String get mealsComingSoonBody =>
      'Bald kannst du eigene Mahlzeiten aus mehreren Lebensmitteln zusammenstellen.';

  @override
  String get mealsEmptyTitle => 'Noch keine Mahlzeiten';

  @override
  String get mealsEmptyBody =>
      'Lege Mahlzeiten an, um mehrere Lebensmittel mit einem Klick einzutragen.';

  @override
  String get mealsCreate => 'Mahlzeit erstellen';

  @override
  String get mealsEdit => 'Mahlzeit bearbeiten';

  @override
  String get mealsDelete => 'Mahlzeit löschen';

  @override
  String get mealsAddToDiary => 'Lebensmittel hinzufügen';

  @override
  String get mealNameLabel => 'Name der Mahlzeit';

  @override
  String get mealNotesLabel => 'Notizen';

  @override
  String get mealIngredientsTitle => 'Zutaten';

  @override
  String get mealAddIngredient => 'Zutat hinzufügen';

  @override
  String get mealIngredientAmountLabel => 'Menge';

  @override
  String get mealDeleteConfirmTitle => 'Mahlzeit löschen';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Möchtest du die Mahlzeit \'$name\' wirklich löschen? Alle Zutaten werden ebenfalls entfernt.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Mahlzeit \'$name\' wurde ins Tagebuch übernommen.';
  }

  @override
  String get mealSaved => 'Mahlzeit gespeichert.';

  @override
  String get mealDeleted => 'Mahlzeit gelöscht.';

  @override
  String get confirm => 'bestätigen';

  @override
  String get addMealToDiaryTitle => 'Zum Tagebuch hinzufügen';

  @override
  String get mealTypeLabel => 'Mahlzeit';

  @override
  String get amountLabel => 'Menge';

  @override
  String get mealAddedToDiarySuccess => 'Mahlzeit zum Tagebuch hinzugefügt';

  @override
  String get error => 'Fehler';

  @override
  String get mealsViewTitle => 'mealsViewTitle';

  @override
  String get noNotes => 'Keine Notizen';

  @override
  String get ingredientsCapsLock => 'ZUTATEN';

  @override
  String get nutritionSectionLabel => 'NÄHRWERTE';

  @override
  String get nutritionCalculatedForCurrentAmounts => 'für aktuelle Mengen';

  @override
  String get startCapsLock => 'START';

  @override
  String get nutritionHubSubtitle =>
      'Entdecke Einblicke, verfolge Mahlzeiten und erstelle hier bald deinen Ernährungsplan.';

  @override
  String get nutritionHubTitle => 'Ernährung';

  @override
  String get nutrition => 'Ernährung';

  @override
  String get changeSetTypTitle => 'Satztyp ändern';

  @override
  String get settingsVisualStyleTitle => 'Visueller Stil';

  @override
  String get settingsVisualStyleStandard => 'Standard (Glas)';

  @override
  String get settingsVisualStyleLiquid => 'Flüssig (Liquid Glass)';

  @override
  String get settingsVisualStyleLiquidDesc => 'Runde, schwebende UI-Elemente';

  @override
  String get settingsVisualStyleNative => 'Nativ';

  @override
  String get settingsVisualStyleNativeDesc =>
      'Verwendet auf unterstützten iOS-Versionen die native iOS-Tab-Bar.';

  @override
  String get searchBaseFoodHint => 'Suche Grundnahrungsmittel';

  @override
  String get searchNoHits => 'Keine Treffer.';

  @override
  String get onbSubtitleWelcome =>
      'Dein zentrales Werkzeug für Fitness, Ernährung & Fortschritt.';

  @override
  String get onbBodyWelcome =>
      'Wir helfen dir, deine Ziele zu setzen und zu verfolgen. Du kannst Workouts, Ernährung, Supps und Körpermaße effizient protokollieren.';

  @override
  String get onbBodyNutritionVisual =>
      'Erfasse Mahlzeiten mit wenigen Klicks. Behalte Kalorien, Makros und Wasser im Blick, um dein Ziel mühelos zu verfolgen.';

  @override
  String get onbBodyMeasurementsVisual =>
      'Visualisiere deinen Fortschritt. Der Gewichts- und Umfangsverlauf macht deinen Erfolg sichtbar und motiviert dich.';

  @override
  String get onbBodyWorkoutVisual =>
      'Erstelle Routinen und starte dein Training in Sekunden. Protokolliere Sätze, Gewichte und Pausen für maximale Progression.';

  @override
  String get onbTitleAppLayout => 'Navigation & Quick-Add';

  @override
  String get onbBodyAppLayout =>
      'Die Bottom Bar ermöglicht den schnellen Wechsel zwischen den Bereichen. Mit dem großen [+] Button kannst du sofort alles protokollieren.';

  @override
  String get dataHubTitle => 'Data Hub';

  @override
  String get resumeButton => 'Fortsetzen';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei Hypertrack';

  @override
  String get onboardingWelcomeSubtitle =>
      'Lass uns dein Profil einrichten, um loszulegen.';

  @override
  String get onboardingNameTitle => 'Wie heißt du?';

  @override
  String get onboardingNameLabel => 'Dein Name';

  @override
  String get onboardingNameError => 'Bitte gib deinen Namen ein';

  @override
  String get onboardingDobTitle => 'Wann bist du geboren?';

  @override
  String get onboardingDobLabel => 'Geburtsdatum';

  @override
  String get onboardingDobError => 'Bitte wähle dein Geburtsdatum';

  @override
  String get onboardingWeightTitle => 'Aktuelles Gewicht';

  @override
  String get onboardingWeightLabel => 'Gewicht (kg)';

  @override
  String get onboardingWeightError => 'Bitte gib ein gültiges Gewicht ein';

  @override
  String get onboardingGoalsTitle => 'Deine Ernährungsziele';

  @override
  String get onboardingGoalsSubtitle =>
      'Du kannst diese später in den Einstellungen ändern.';

  @override
  String get onboardingGoalCalories => 'Tagesziel Kalorien (kcal)';

  @override
  String get onboardingGoalProtein => 'Protein (g)';

  @override
  String get onboardingGoalCarbs => 'Kohlenhydrate (g)';

  @override
  String get onboardingGoalFat => 'Fett (g)';

  @override
  String get onboardingGoalWater => 'Wasser (ml)';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingBack => 'Zurück';

  @override
  String get onboardingFinish => 'Loslegen';

  @override
  String get onboardingHeightLabel => 'Größe (cm)';

  @override
  String get onboardingGenderLabel => 'Geschlecht';

  @override
  String get genderMale => 'Männlich';

  @override
  String get genderFemale => 'Weiblich';

  @override
  String get genderDiverse => 'Divers';

  @override
  String get aiSettingsTitle => 'KI-Mahlzeitenerkennung';

  @override
  String get aiSettingsDescription =>
      'KI-basierte Mahlzeitenerkennung konfigurieren.';

  @override
  String get aiProviderSection => 'KI-Anbieter';

  @override
  String get aiProviderLabel => 'Anbieter';

  @override
  String get aiApiKeySection => 'API-Schlüssel';

  @override
  String get aiApiKeyLabel => 'API-Schlüssel';

  @override
  String get aiApiKeyHint => 'API-Schlüssel hier einfügen';

  @override
  String get aiSaveKey => 'Speichern';

  @override
  String get aiTestConnection => 'Test';

  @override
  String get aiTestSuccess => 'Verbindung erfolgreich!';

  @override
  String get aiKeySaved => 'API-Schlüssel sicher gespeichert.';

  @override
  String get aiPrivacySection => 'Datenschutz';

  @override
  String get aiPrivacyDisclosure =>
      'Deine Bilder und Texte werden nur an den gewählten KI-Anbieter gesendet, wenn du auf Analysieren tippst. Daten werden über die Verarbeitung hinaus nicht auf externen Servern gespeichert. Dein API-Schlüssel wird verschlüsselt nur auf diesem Gerät gespeichert.';

  @override
  String get aiMealCapture => 'KI-Mahlzeit';

  @override
  String get aiCaptureTitle => 'KI-Mahlzeitenerkennung';

  @override
  String get aiCaptureTabPhoto => 'Foto';

  @override
  String get aiCaptureTabVoice => 'Sprache';

  @override
  String get aiCaptureTabText => 'Text';

  @override
  String get aiCapturePhotoHint =>
      'Mache oder wähle bis zu 4 Fotos deiner Mahlzeit.';

  @override
  String get aiCaptureVoiceHint =>
      'Tippe auf das Mikrofon und beschreibe deine Mahlzeit.';

  @override
  String get aiCaptureTextHint =>
      'Beschreibe deine Mahlzeit (z.B. \"Gegrilltes Hähnchen mit Reis und Salat\")...';

  @override
  String get aiAnalyzeButton => 'Analysieren';

  @override
  String get aiAnalyzing => 'Mahlzeit wird analysiert...';

  @override
  String get aiReviewTitle => 'Vorschläge prüfen';

  @override
  String aiReviewFoundItems(int count) {
    return 'KI hat $count Zutaten erkannt';
  }

  @override
  String get aiReviewNoMatch => 'Kein Treffer — tippe zum Suchen';

  @override
  String get aiReviewConfidence => 'Konfidenz';

  @override
  String get aiReviewAddItem => 'Zutat manuell hinzufügen';

  @override
  String get aiReviewSaveToDiary => 'Ins Tagebuch speichern';

  @override
  String get aiReviewFeedbackHint =>
      'Beschreibe, was die KI falsch erkannt hat...';

  @override
  String get aiReviewRetryButton => 'Mit Korrektur erneut versuchen';

  @override
  String get aiReviewFeedbackSection => 'Korrektur';

  @override
  String get aiErrorNoKey =>
      'Kein API-Schlüssel konfiguriert. Bitte unter Einstellungen → KI-Mahlzeitenerkennung eingeben.';

  @override
  String get aiErrorNetwork =>
      'Netzwerkfehler. Bitte Verbindung prüfen und erneut versuchen.';

  @override
  String get aiErrorAuth =>
      'Authentifizierung fehlgeschlagen. Bitte API-Schlüssel prüfen.';

  @override
  String get aiErrorParse =>
      'KI-Antwort konnte nicht verarbeitet werden. Bitte erneut versuchen.';

  @override
  String get aiErrorRateLimit => 'Zu viele Anfragen. Bitte kurz warten.';

  @override
  String get aiEnableTitle => 'KI-Funktionen aktivieren';

  @override
  String get aiEnableSubtitle =>
      'Ermöglicht die Nutzung von KI zur Mahlzeitenerkennung. Bei Deaktivierung werden alle KI-Buttons in der App ausgeblendet.';

  @override
  String get aiRecommendationTitle => 'KI-Mahlzeitcoach';

  @override
  String get aiRecommendDietary => 'Ernährungsweise';

  @override
  String get aiRecommendSituation => 'Situation';

  @override
  String get aiRecommendVegan => 'Vegan';

  @override
  String get aiRecommendVegetarian => 'Vegetarisch';

  @override
  String get aiRecommendPescetarian => 'Pescetarisch';

  @override
  String get aiRecommendOnTheGo => 'Unterwegs (Sofort essbar)';

  @override
  String get aiRecommendNoKitchen => 'Ohne Kochen (Kaltes Gericht)';

  @override
  String get aiRecommendWithCooking => 'Mit Kochen (Zubereitung)';

  @override
  String get aiRecommendGenerate => 'Generieren';

  @override
  String get aiRecommendGenerating => 'Denke nach…';

  @override
  String get aiRecommendSaveToDiary => 'Im Tagebuch speichern';

  @override
  String get aiRecommendNoMatch => 'Kein Datenbank-Treffer';

  @override
  String get aiRecommendRemainingMacros => 'Heute noch übrig';

  @override
  String get aiRecommendCustomRequest => 'Eigener Wunsch';

  @override
  String get aiRecommendCustomRequestHint =>
      'z. B. auf restlichen Reis achten, viel Protein, usw.';

  @override
  String get currentlyTracking => 'Aktuell tracken';

  @override
  String get currentlyTrackingDesc => 'In der täglichen Übersicht anzeigen';

  @override
  String get filter3Months => '3 Monate';

  @override
  String get filter6Months => '6 Monate';

  @override
  String get sectionConsistency => 'Konsistenz & Frequenz';

  @override
  String get metricsWorkoutsWeek => 'Workouts (Woche)';

  @override
  String get metricsCurrentStreak => 'Aktueller Streak';

  @override
  String get metricsActiveWeeks => 'Wochen aktiv';

  @override
  String get placeholderCalendarHeatmap => 'Kalender Heatmap';

  @override
  String get consistencyTrackerTitle => 'Konsistenz Tracker';

  @override
  String get consistencyTrackerComingSoon =>
      'Konsistenz & Habit Tracker (In Kürze)';

  @override
  String get sectionMuscleVolume => 'Muskelgruppen & Volumen';

  @override
  String get metricsTopTrained => 'Oft trainiert';

  @override
  String get metricsMostNeglected => 'Vernachlässigt';

  @override
  String get placeholderMuscleHeatmap => 'Muskelgruppen Heatmap';

  @override
  String get muscleAnalyticsTitle => 'Muskelgruppen Analyse';

  @override
  String get muscleAnalyticsComingSoon => 'Muskelvolumen & Heatmaps (In Kürze)';

  @override
  String get sectionPerformance => 'Leistung & PRs';

  @override
  String get metricsRecentPrs => 'Aktuelle PRs';

  @override
  String get metricsVolumeLifted => 'Bewegtes Gewicht';

  @override
  String get metricsMostImproved => 'Größte Steigerung';

  @override
  String get exerciseAnalyticsTitle => 'Übungs-Analyse';

  @override
  String get exerciseAnalyticsSubtitle =>
      'Spezifische Übungen suchen & analysieren';

  @override
  String get prDashboardTitle => 'PR Dashboard';

  @override
  String get prDashboardComingSoon => 'Rekorde & Fortschritte (In Kürze)';

  @override
  String get exerciseAnalyticsComingSoon => 'Übungssuche & Trends (In Kürze)';

  @override
  String get sectionRecovery => 'Erholung';

  @override
  String get metricsMuscleReadiness => 'Muskel-Bereitschaft';

  @override
  String get recoveryTrackerTitle => 'Erholungs-Tracker';

  @override
  String get recoveryTrackerComingSoon =>
      'Muskel-Bereitschaft & Ermüdung (In Kürze)';

  @override
  String get recoveryOverallMostlyRecovered => 'Überwiegend erholt';

  @override
  String get recoveryOverallMixed => 'Gemischter Erholungszustand';

  @override
  String get recoveryOverallSeveralRecovering =>
      'Mehrere Muskelgruppen sind noch in Erholung';

  @override
  String get recoveryOverallInsufficientData =>
      'Noch nicht genug Daten für eine Erholungs-Einschätzung';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return 'In Erholung: $recovering  Bereit: $ready  Frisch: $fresh';
  }

  @override
  String get recoveryHubNoDataSummary =>
      'Tracke weitere Workouts, um Erholungs-Einblicke freizuschalten.';

  @override
  String get recoveryByMuscleTitle => 'Erholung je Muskel';

  @override
  String get recoveryStateRecovering => 'In Erholung';

  @override
  String get recoveryStateReady => 'Bereit';

  @override
  String get recoveryStateFresh => 'Frisch';

  @override
  String get recoveryStateUnknown => 'Unbekannt';

  @override
  String recoveryLastLoadedHours(int hours) {
    return 'Letzte signifikante Belastung: vor ${hours}h';
  }

  @override
  String get recoveryFatigueContextHigh =>
      'Letzter Ermüdungs-Kontext: hohe Session-Ermüdung';

  @override
  String get recoveryFatigueContextBaseline =>
      'Letzter Ermüdungs-Kontext: normale Session-Ermüdung';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle: zuletzt vor ${hours}h signifikant belastet, mit hoher Session-Ermüdung.';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle: zuletzt vor ${hours}h signifikant belastet.';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'Dies ist eine konservative Heuristik auf Basis kürzlich signifikanter Belastung und Session-Anstrengung. Keine medizinische Erholungs-Messung.';

  @override
  String recoveryRecentLoad(String sets) {
    return 'Letzte Belastungsmenge: $sets äquivalente Sätze';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return 'Heuristisches Zeitfenster: häufig etwa $from bis $to Stunden, abhängig vom Kontext.';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      'Radar-Überblick zum jüngsten Erholungsdruck je Muskel. Richtungsweisend und heuristisch.';

  @override
  String get recoveryNoDataBody =>
      'Es wurden noch nicht genug signifikante Trainingsbelastungen erfasst, um die Muskel-Erholung einzuordnen.';

  @override
  String get sectionBodyNutrition => 'Körper & Ernährung';

  @override
  String get metricsCurrentWeight => 'Aktuelles Gewicht';

  @override
  String get metricsAvgCalories => 'Ø Kalorien';

  @override
  String get placeholderWeightTrend => 'Gewichts-Trend Diagramm';

  @override
  String get exerciseAnalyticsPrsLabel => 'PERSÖNLICHE REKORDE';

  @override
  String get exerciseAnalyticsTrendsLabel => 'TRENDS';

  @override
  String get exerciseAnalyticsNoData =>
      'Keine aufgezeichneten Daten für diese Übung.';

  @override
  String get exerciseAnalyticsNotEnoughData => 'Nicht genug Daten';

  @override
  String get exerciseAnalyticsChartWeight => 'Gewicht im Zeitverlauf (kg)';

  @override
  String get exerciseAnalyticsChartVolume => 'Volumen im Zeitverlauf (kg)';

  @override
  String get exerciseAnalyticsChartSets => 'Sätze im Zeitverlauf';

  @override
  String get allTimeRecordsLabel => 'Alle-Zeiten-Rekorde';

  @override
  String get recentActivityLabel => 'Letzte Aktivität';

  @override
  String get prsByRepRangeLabel => 'Bestes Set nach Wiederholungsbereich';

  @override
  String get volumeAnalyticsTitle => 'Volumen-Analyse';

  @override
  String get weeklyTonnageLabel => 'Wöchentliches Tonnage';

  @override
  String get volumeByMuscleLabel => 'Nach Muskelgruppe';

  @override
  String get topExercisesLabel => 'Top-Übungen';

  @override
  String get thisWeekLabel => 'Diese Woche';

  @override
  String get avgPerWeekLabel => 'Ø / Woche';

  @override
  String get streakLabel => 'Serie';

  @override
  String get trainingCalendarLabel => 'Trainingskalender';

  @override
  String get workoutsPerWeekLabel => 'Trainings pro Woche';

  @override
  String get totalWorkoutsLabel => 'Gesamt';

  @override
  String get weeksLabel => 'Wochen';

  @override
  String get tonnageKgLabel => 'Tonnage (kg)';

  @override
  String get noWorkoutDataLabel =>
      'Noch keine Daten. Starte ein Training, um Statistiken zu sehen.';

  @override
  String get analyticsSectionVolumeMuscles => 'Volumen & Muskelgruppen';

  @override
  String get analyticsSectionPerformanceRecords => 'Leistung & Rekorde';

  @override
  String get analyticsTopVolume => 'Top trainiert';

  @override
  String get analyticsLowestVolume => 'Niedrigstes Volumen';

  @override
  String get analyticsRecentRecords => 'Aktuelle Rekorde';

  @override
  String analyticsPerfWithReps(String weight, int reps) {
    return '$weight kg x $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg (diese Woche)';

  @override
  String get analyticsRecoverySummary => '3 in Erholung, 8 belastbar';

  @override
  String get analyticsViewDetails => 'Details ansehen';

  @override
  String get analyticsRepRangeSuffix => ' Wdh.';

  @override
  String get analyticsNoRecordYet => 'Noch kein Rekord';

  @override
  String get analyticsNotableImprovements => 'Bemerkenswerte Verbesserungen';

  @override
  String get analyticsNoPrTrendInWindow =>
      'In diesem Zeitraum gibt es noch keinen klaren Rekordtrend.';

  @override
  String analyticsE1rmProgress(String previous, String recent) {
    return 'e1RM $previous -> $recent kg';
  }

  @override
  String get analyticsUnitKg => 'kg';

  @override
  String get analyticsUnitSets => 'Sätze';

  @override
  String get analyticsViewLabel => 'Ansicht';

  @override
  String get analyticsViewWeek => 'Woche';

  @override
  String get analyticsViewMonth => 'Monat';

  @override
  String get analyticsViewByExercise => 'Nach Übung';

  @override
  String get analyticsViewByMuscle => 'Nach Muskelgruppe';

  @override
  String get analyticsMetricLabel => 'Messwert';

  @override
  String get analyticsMovedWeightKg => 'Bewegtes Gewicht (kg)';

  @override
  String get analyticsWorkSets => 'Arbeitssätze';

  @override
  String get analyticsVolumeContextWithSets =>
      'Bewegtes Gewicht = Gewicht x Wiederholungen. Für zählbasierte Belastung kannst du auf Arbeitssätze wechseln.';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'Diese Ansicht zeigt bewegtes Gewicht (Gewicht x Wiederholungen).';

  @override
  String get analyticsKpisHeader => 'Kennzahlen';

  @override
  String get analyticsTrainingDaysPerWeek => 'Trainingstage / Woche';

  @override
  String get analyticsLast4Weeks => 'letzte 4 Wochen';

  @override
  String get analyticsRhythm => 'Rhythmus';

  @override
  String get analyticsVsPrior4Weeks => 'gegenüber den 4 Wochen davor';

  @override
  String get analyticsRollingConsistency => 'Rollierende Konsistenz';

  @override
  String get analyticsWeeksAtLeast2Workouts =>
      'Wochen mit mindestens 2 Einheiten';

  @override
  String get analyticsCalendarExplainer =>
      'Die Farbdichte zeigt Einheiten pro Tag. Dadurch dient der Kalender als echte Konsistenz-Ansicht.';

  @override
  String get analyticsSelectDayPrompt =>
      'Wähle einen Tag aus, um die Anzahl der Einheiten zu sehen.';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date: $count Einheiten';
  }

  @override
  String get analyticsTotalSessions => 'Gesamte Einheiten';

  @override
  String get analyticsPlaceholderWeightValue => '82,5';

  @override
  String get analyticsPlaceholderWeightTrend => 'kg (-0,5)';

  @override
  String get analyticsPlaceholderCaloriesValue => '2.450';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/Tag';

  @override
  String get analyticsMuscleWeeklySets => 'Wöchentliche Sätze';

  @override
  String get analyticsMuscleTopFrequency => 'Top-Frequenz';

  @override
  String get analyticsPerWeekAbbrev => 'Woche';

  @override
  String get analyticsKeepTrackingUnlockInsights =>
      'Weiter tracken, um Einblicke freizuschalten.';

  @override
  String get analyticsGuidanceNoClearWeakPoint =>
      'Hinweis: Kein klarer Schwachpunkt in diesem Zeitraum.';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'Hinweis: Zuletzt geringere Betonung bei $muscles.';
  }

  @override
  String get analyticsPeriodLabel => 'Zeitraum';

  @override
  String get analyticsEquivalentSetsExplainer =>
      'Äquivalente Arbeitssätze nutzen Primär x1.0 und Sekundär x0.5. Frequenz zählt nur Tage mit >= 1.0 äquivalenten Sätzen.';

  @override
  String get analyticsWeeklySetsByMuscle => 'Wöchentliche Sätze je Muskel';

  @override
  String get analyticsFrequencyByMuscle => 'Frequenz je Muskel';

  @override
  String get analyticsRecentDistributionHeatmap =>
      'Aktuelle Verteilungs-Heatmap';

  @override
  String get analyticsRadarOverviewTitle => 'Radar-Überblick';

  @override
  String get analyticsRadarVolumeCaption =>
      'Zeigt die relative Volumenverteilung über Muskelgruppen für eine schnelle Übersicht.';

  @override
  String get analyticsGuidanceTitle => 'Hinweise';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'Dies ist ein richtungsweisender Hinweis auf Basis deiner letzten Satzverteilung, keine absolute Diagnose.';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      'Hinweise werden bewusst abgeschwächt, bis genug Daten vorliegen.';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Wochensumme: $value äquivalente Sätze';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      'Frequenz zählt nur Tage, an denen der Muskel >= 1.0 äquivalente Sätze erreicht.';

  @override
  String liveWorkoutE1rmCurrentSet(String value) {
    return 'e1RM $value kg';
  }

  @override
  String liveWorkoutE1rmBestSession(String value) {
    return 'Beste e1RM in dieser Session: $value kg';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta) {
    return 'vs letzte Session: $delta kg';
  }

  @override
  String get bodyNutritionCorrelationTitle => 'Körper & Ernährung Trends';

  @override
  String get metricsWeightChange => 'Gewichtsänderung';

  @override
  String get analyticsKcalPerDay => 'kcal/Tag';

  @override
  String get analyticsDaysWithWeightData => 'Tage mit Gewicht';

  @override
  String get analyticsDayUnitLabel => 'Tage';

  @override
  String get analyticsPerDayLabel => 'pro Tag';

  @override
  String get analyticsEffectiveRangeLabel => 'Effektiver Bereich';

  @override
  String get analyticsAxisXLabel => 'X';

  @override
  String get analyticsAxisYLabel => 'Y';

  @override
  String get analyticsHighConfidenceLabel =>
      'Muster mit höherer Verlässlichkeit';

  @override
  String get analyticsLowConfidenceLabel =>
      'Muster mit niedrigerer Verlässlichkeit';

  @override
  String get analyticsObservedPatternLabel => 'Beobachtetes Muster';

  @override
  String get analyticsBodyNutritionTrendContext =>
      'Gewichts- und Kalorientrends';

  @override
  String get analyticsBodyNutritionTrendContextHint =>
      'Diese Linien zeigen die Trendbewegung im gleichen Zeitraum als Kontext.';

  @override
  String get analyticsWeightTrendLabel => 'Körpergewicht (geglattet)';

  @override
  String get analyticsCaloriesTrendLabel => 'Kalorien (täglicher Trend)';

  @override
  String get analyticsInterpretationTitle => 'Interpretation';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'Die Datenabdeckung in diesem Bereich ist stark genug für eine verlässlichere Muster-Einordnung.';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'Die Datenabdeckung in diesem Bereich ist noch begrenzt, daher als frühen Kontext lesen.';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      'Regelmäßiges Logging von Gewicht und Kalorien verbessert die Verlässlichkeit.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      'Interpretations-Verlässlichkeit: höher. Als Trend-Kontext nutzen, nicht als direkten Ursache-Beleg.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      'Interpretations-Verlässlichkeit: niedriger. Als frühes Muster-Signal nutzen und weiter tracken.';

  @override
  String get analyticsCorrelationDisclaimer =>
      'Diese Ansicht zeigt zeitliche Trend-Korrelationen. Sie beweist nicht, dass Kalorienveränderungen direkt Gewichtsveränderungen verursacht haben.';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      'Der Gewichtstrend ist stabil, während die durchschnittlichen Kalorien gestiegen sind.';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      'Das Gewicht zeigt einen Aufwärtstrend zusammen mit höherer durchschnittlicher Kalorienaufnahme.';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      'Die jüngste Kalorienreduktion hat den Gewichtstrend noch nicht klar verändert.';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      'Das Gewicht zeigt einen Abwärtstrend zusammen mit niedrigerer durchschnittlicher Kalorienaufnahme.';

  @override
  String get analyticsInsightMixedPattern =>
      'Gewichts- und Kalorientrends bewegen sich gemischt, noch ohne klares Korrelationsmuster.';

  @override
  String get analyticsInsightNotEnoughData =>
      'Noch nicht genug Daten für eine aussagekräftige Korrelations-Einschätzung.';

  @override
  String get restTimerNotificationTitle => 'Pause beendet';

  @override
  String get restTimerNotificationBody =>
      'Dein Pausentimer ist abgelaufen. Bereit für den nächsten Satz.';

  @override
  String get onboardingContinueSetup => 'Profil einrichten';

  @override
  String get onboardingRestoreFromBackup => 'Aus Backup wiederherstellen';

  @override
  String get onboardingRestoreImporting => 'Backup wird importiert...';

  @override
  String get onboardingRestoreSuccess =>
      'Backup erfolgreich wiederhergestellt!';

  @override
  String get onboardingRestoreFailed =>
      'Import fehlgeschlagen. Bitte prüfe die Datei und versuche es erneut.';

  @override
  String get finishWorkoutTitleLabel => 'Workout-Titel';

  @override
  String get finishWorkoutNotesLabel => 'Notizen (optional)';

  @override
  String get finishWorkoutNotesHint => 'Wie lief das Workout?';
}
