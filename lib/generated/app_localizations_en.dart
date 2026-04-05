// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hypertrack';

  @override
  String get bannerText => 'Recommendation / Current Workout';

  @override
  String get calories => 'Calories';

  @override
  String get water => 'Water';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get steps => 'Steps';

  @override
  String get daily => 'Daily';

  @override
  String get today => 'Today';

  @override
  String get workoutSection => 'Workout section - not yet implemented';

  @override
  String get addMenuTitle => 'What do you want to add?';

  @override
  String get addFoodOption => 'add Food';

  @override
  String get addLiquidOption => 'add Liquid';

  @override
  String get searchHintText => 'Search...';

  @override
  String get mealtypeBreakfast => 'Breakfast';

  @override
  String get mealtypeLunch => 'Lunch';

  @override
  String get mealtypeDinner => 'Dinner';

  @override
  String get mealtypeSnack => 'Snack';

  @override
  String get waterHeader => 'Water & Drinks';

  @override
  String get openFoodFactsSource => 'Data from Open Food Facts';

  @override
  String get tabRecent => 'Recent';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get fabCreateOwnFood => 'Custom Food';

  @override
  String get recentEmptyState =>
      'Your recently used food items\nwill appear here.';

  @override
  String get favoritesEmptyState =>
      'You don\'t have any favorites yet.\nMark a food with the heart icon to see it here.';

  @override
  String get searchInitialHint => 'Please enter a search term.';

  @override
  String get searchNoResults => 'No results found.';

  @override
  String get createFoodScreenTitle => 'Create Custom Food';

  @override
  String get formFieldName => 'Name of the food';

  @override
  String get formFieldBrand => 'Brand (optional)';

  @override
  String get formSectionMainNutrients => 'Main Nutrients (per 100g)';

  @override
  String get formFieldCalories => 'Calories (kcal)';

  @override
  String get formFieldProtein => 'Protein (g)';

  @override
  String get formFieldCarbs => 'Carbohydrates (g)';

  @override
  String get formFieldFat => 'Fat (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Additional Nutrients (optional, per 100g)';

  @override
  String get formFieldSugar => 'Of which sugars (g)';

  @override
  String get formFieldFiber => 'Fiber (g)';

  @override
  String get formFieldKj => 'Kilojoules (kJ)';

  @override
  String get formFieldSalt => 'Salt (g)';

  @override
  String get formFieldSodium => 'Sodium (mg)';

  @override
  String get formFieldCalcium => 'Calcium (mg)';

  @override
  String get buttonSave => 'Save';

  @override
  String get validatorPleaseEnterName => 'Please enter a name.';

  @override
  String get validatorPleaseEnterNumber => 'Please enter a valid number.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName was saved successfully.';
  }

  @override
  String get foodDetailSegmentPortion => 'Portion';

  @override
  String get foodDetailSegment100g => '100g';

  @override
  String get sugar => 'Sugar';

  @override
  String get fiber => 'Fiber';

  @override
  String get salt => 'Salt';

  @override
  String get explorerScreenTitle => 'Food Explorer';

  @override
  String get nutritionScreenTitle => 'Nutrition Analysis';

  @override
  String get entriesForDateRangeLabel => 'Entries for';

  @override
  String get noEntriesForPeriod => 'No entries for this period yet.';

  @override
  String get waterEntryTitle => 'Water';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileDailyGoals => 'Daily Goals';

  @override
  String get profileDailyGoalsCL => 'DAILY GOALS';

  @override
  String get snackbarGoalsSaved => 'Goals saved successfully!';

  @override
  String get measurementsScreenTitle => 'Measurements';

  @override
  String get measurementsEmptyState =>
      'No measurements recorded yet.\nStart with the \'+\' button.';

  @override
  String get addMeasurementDialogTitle => 'Add New Measurement';

  @override
  String get formFieldMeasurementType => 'Type of Measurement';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Value ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Please enter a value';

  @override
  String get measurementWeight => 'Body Weight';

  @override
  String get measurementFatPercent => 'Body Fat';

  @override
  String get measurementNeck => 'Neck';

  @override
  String get measurementShoulder => 'Shoulder';

  @override
  String get measurementChest => 'Chest';

  @override
  String get measurementLeftBicep => 'Left Bicep';

  @override
  String get measurementRightBicep => 'Right Bicep';

  @override
  String get measurementLeftForearm => 'Left Forearm';

  @override
  String get measurementRightForearm => 'Right Forearm';

  @override
  String get measurementAbdomen => 'Abdomen';

  @override
  String get measurementWaist => 'Waist';

  @override
  String get measurementHips => 'Hips';

  @override
  String get measurementLeftThigh => 'Left Thigh';

  @override
  String get measurementRightThigh => 'Right Thigh';

  @override
  String get measurementLeftCalf => 'Left Calf';

  @override
  String get measurementRightCalf => 'Right Calf';

  @override
  String get drawerMenuTitle => 'Hypertrack Menu';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerFoodExplorer => 'Food Explorer';

  @override
  String get drawerDataManagement => 'Data Backup';

  @override
  String get drawerMeasurements => 'Measurements';

  @override
  String get dataManagementTitle => 'Data Backup';

  @override
  String get exportCardTitle => 'Export Data';

  @override
  String get exportCardDescription =>
      'Saves all your journal entries, favorites, and custom foods into a single backup file.';

  @override
  String get exportCardButton => 'Create Backup';

  @override
  String get importCardTitle => 'Import Data';

  @override
  String get importCardDescription =>
      'Restores your data from a previously created backup file. WARNING: All data currently stored in the app will be overwritten!';

  @override
  String get importCardButton => 'Restore Backup';

  @override
  String get recommendationDefault => 'Track your first meal!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Last $count days: +$difference kcal over target';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Last $count days: $difference kcal under target';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Last $count days: Target achieved ✅';
  }

  @override
  String get recommendationFirstEntry => 'Great, your first entry is logged!';

  @override
  String get dialogConfirmTitle => 'Confirmation Required';

  @override
  String get dialogConfirmImportContent =>
      'Do you really want to restore data from this backup?\n\nWARNING: All your current entries, favorites, and custom foods will be permanently deleted and replaced.';

  @override
  String get dialogButtonCancel => 'Cancel';

  @override
  String get dialogButtonOverwrite => 'Yes, overwrite all';

  @override
  String get snackbarNoFileSelected => 'No file selected.';

  @override
  String get snackbarImportSuccessTitle => 'Import successful!';

  @override
  String get snackbarImportSuccessContent =>
      'Your data has been restored. It is recommended to restart the app for a correct display.';

  @override
  String get snackbarButtonOK => 'OK';

  @override
  String get snackbarImportError => 'Error while importing data.';

  @override
  String get snackbarExportSuccess =>
      'Backup file has been passed to the system. Please choose a location to save.';

  @override
  String get snackbarExportFailed => 'Export canceled or failed.';

  @override
  String get profileUserHeight => 'Height (cm)';

  @override
  String get workoutRoutinesTitle => 'Routines';

  @override
  String get workoutHistoryTitle => 'Workout History';

  @override
  String get workoutHistoryButton => 'History';

  @override
  String get emptyRoutinesTitle => 'No Routines Found';

  @override
  String get emptyRoutinesSubtitle =>
      'Create your first routine or start a blank workout.';

  @override
  String get createFirstRoutineButton => 'Create First Routine';

  @override
  String get startEmptyWorkoutButton => 'Free Workout';

  @override
  String get editRoutineSubtitle => 'Tap to edit, or start the workout.';

  @override
  String get startButton => 'Start';

  @override
  String get addRoutineButton => 'New Routine';

  @override
  String get freeWorkoutTitle => 'Free Workout';

  @override
  String get finishWorkoutButton => 'Finish';

  @override
  String get addSetButton => 'Add Set';

  @override
  String get addExerciseToWorkoutButton => 'Add Exercise to Workout';

  @override
  String get lastTimeLabel => 'Last Time';

  @override
  String get setLabel => 'Set';

  @override
  String get kgLabel => 'Weight (kg)';

  @override
  String get repsLabel => 'Reps';

  @override
  String get cardioDistanceLabel => 'Distance (km)';

  @override
  String get cardioTimeLabel => 'Time (min)';

  @override
  String get cardioIntensityLabel => 'Intens.';

  @override
  String get cardioIntensityShortLabel => 'Int.';

  @override
  String get restTimerLabel => 'Rest';

  @override
  String get skipButton => 'Skip';

  @override
  String get emptyHistory => 'No completed workouts yet.';

  @override
  String get workoutDetailsTitle => 'Workout Details';

  @override
  String get workoutNotFound => 'Workout not found.';

  @override
  String get totalVolumeLabel => 'Total Volume';

  @override
  String get notesLabel => 'Notes';

  @override
  String get hevyImportTitle => 'Hevy Import';

  @override
  String get hevyImportDescription =>
      'Import your entire training history from a Hevy CSV export file.';

  @override
  String get hevyImportButton => 'Import Hevy Data';

  @override
  String hevyImportSuccess(Object count) {
    return 'Successfully imported $count workouts!';
  }

  @override
  String get hevyImportFailed => 'Import failed. Please check the file.';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get addMeasurement => 'Add Measurement';

  @override
  String get filterToday => 'Today';

  @override
  String get filter7Days => '7 Days';

  @override
  String get filter30Days => '30 Days';

  @override
  String get filterAll => 'All';

  @override
  String get showLess => 'Show less';

  @override
  String get showMoreDetails => 'Show more details';

  @override
  String get deleteConfirmTitle => 'Confirm Deletion';

  @override
  String get deleteConfirmContent => 'Do you really want to delete this entry?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get tabBaseFoods => 'Base Foods';

  @override
  String get baseFoodsEmptyState =>
      'This section will soon be filled with a curated list of base foods like fruits, vegetables, and more.';

  @override
  String get noBrand => 'No Brand';

  @override
  String get unknown => 'Unknown';

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
  String get exerciseCatalogTitle => 'Exercise Catalog';

  @override
  String get filterByMuscle => 'Filter by muscle group';

  @override
  String get noExercisesFound => 'No exercises found.';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get edit => 'Edit';

  @override
  String get repsLabelShort => 'reps';

  @override
  String get titleNewRoutine => 'New Routine';

  @override
  String get titleEditRoutine => 'Edit Routine';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Please enter a name for the routine.';

  @override
  String get snackbarRoutineCreated =>
      'Routine created. Now add some exercises.';

  @override
  String get snackbarRoutineSaved => 'Routine saved.';

  @override
  String get formFieldRoutineName => 'Name of the routine';

  @override
  String get emptyStateAddFirstExercise => 'Add your first exercise.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Add Exercise';

  @override
  String get kgLabelShort => 'kg';

  @override
  String get drawerExerciseCatalog => 'Exercise Catalog';

  @override
  String get lastWorkoutTitle => 'Last Workout';

  @override
  String get repeatButton => 'Repeat';

  @override
  String get weightHistoryTitle => 'Weight History';

  @override
  String get hideSummary => 'Hide Summary';

  @override
  String get showSummary => 'Show Summary';

  @override
  String get exerciseDataAttribution => 'Exercise data from wger';

  @override
  String get duplicate => 'Duplicate';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Are you sure you want to permanently delete the routine \'$routineName\'?';
  }

  @override
  String get editPauseTimeTitle => 'Edit Pause Duration';

  @override
  String get pauseInSeconds => 'Pause in seconds';

  @override
  String get editPauseTime => 'Edit Pause';

  @override
  String pauseDuration(int seconds) {
    return '$seconds second pause';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Pauses up to ${seconds}s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Are you sure you want to permanently delete this workout log?';

  @override
  String get removeExercise => 'Remove Exercise';

  @override
  String get deleteExerciseConfirmTitle => 'Remove Exercise?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Are you sure you want to remove \'$exerciseName\' from this routine?';
  }

  @override
  String get doneButtonLabel => 'Done';

  @override
  String get setRestTimeButton => 'Set rest time';

  @override
  String get deleteExerciseButton => 'Delete exercise';

  @override
  String get restOverLabel => 'Pause is over';

  @override
  String get workoutRunningLabel => 'Workout is active …';

  @override
  String get continueButton => 'Continue';

  @override
  String get discardButton => 'Discard';

  @override
  String get workoutStatsTitle => 'Training (7 days)';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get durationLabel => 'Duration';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Sets';

  @override
  String get muscleSplitLabel => 'Muscle Split';

  @override
  String get snackbar_could_not_open_open_link => 'Konnte Link nicht öffnen';

  @override
  String get chart_no_data_for_period => 'No chart data for this period';

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
  String get data_export_button => 'Export';

  @override
  String get data_import_button => 'Import';

  @override
  String get snackbar_button_ok => 'OK';

  @override
  String get measurement_session_detail_view =>
      'Detailview of measurement session';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Delete profile picture';

  @override
  String get attribution_title => 'Attribution';

  @override
  String get add_liquid_title => 'Add fluid';

  @override
  String get add_button => 'Add';

  @override
  String get discard_button => 'Discard';

  @override
  String get continue_workout_button => 'Continue';

  @override
  String get soon_available_snackbar => 'This screen will be available soon';

  @override
  String get start_button => 'Start';

  @override
  String get today_overview_text => 'TODAY IN FOCUS';

  @override
  String get quick_add_text => 'QUICK ADD';

  @override
  String get scann_barcode_capslock => 'Scan barcode';

  @override
  String get protocol_today_capslock => 'TODAY\'S PROTOCOL';

  @override
  String get my_plans_capslock => 'MY PLANS';

  @override
  String get overview_capslock => 'OVERVIEW';

  @override
  String get manage_all_plans => 'Manage all plans';

  @override
  String get free_training => 'free training';

  @override
  String get my_consistency => 'MY CONSISTENCY';

  @override
  String get calendar_currently_not_available =>
      'The calendar view will be available soon.';

  @override
  String get in_depth_analysis => 'IN-DEPTH ANALYSIS';

  @override
  String get body_measurements => 'Body measurements';

  @override
  String get measurements_description =>
      'Analyze weight, body fat percentage and circumference.';

  @override
  String get nutrition_description => 'Evaluate macros, calories and trends.';

  @override
  String get training_analysis => 'Training analysis';

  @override
  String get training_analysis_description =>
      'Track volume, strength and progression.';

  @override
  String get load_dots => 'loading...';

  @override
  String get profile_capslock => 'PROFILE';

  @override
  String get settings_capslock => 'SETTINGS';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get my_goals => 'My goals';

  @override
  String get my_goals_description => 'Adjust calories, macros and water.';

  @override
  String get backup_and_import => 'Data backup & import';

  @override
  String get backup_and_import_description =>
      'Create backups, restore, and import data.';

  @override
  String get about_and_legal_capslock => 'ABOUT & LEGAL';

  @override
  String get attribution_and_license => 'Attribution & Licenses';

  @override
  String get data_from_off_and_wger => 'Data from Open Food Facts and wger.';

  @override
  String get app_version => 'App version';

  @override
  String get all_measurements => 'ALL MEASUREMENTS';

  @override
  String get date_and_time_of_measurement => 'Date & time of measurement';

  @override
  String get onbWelcomeTitle => 'Welcome to Hypertrack';

  @override
  String get onbWelcomeBody =>
      'Let’s start by setting personal goals to guide training and nutrition.';

  @override
  String get onbTrackTitle => 'Track everything';

  @override
  String get onbTrackBody =>
      'Log nutrition, workouts, and measurements — all in one place.';

  @override
  String get onbPrivacyTitle => 'Offline-first & privacy';

  @override
  String get onbPrivacyBody =>
      'Your data stays on the device. No cloud accounts, no background sync.';

  @override
  String get onbFinishTitle => 'All set';

  @override
  String get onbFinishBody =>
      'You’re ready to explore the app. You can adjust settings anytime.';

  @override
  String get onbFinishCta => 'Let’s go!';

  @override
  String get onbShowTutorialAgain => 'Show tutorial again';

  @override
  String get onbSetGoalsCta => 'Set goals';

  @override
  String get onbHeaderTitle => 'Tutorial';

  @override
  String get onbHeaderSkip => 'Skip';

  @override
  String get onbBack => 'Back';

  @override
  String get onbNext => 'Next';

  @override
  String get onbGuideTitle => 'How this tutorial works';

  @override
  String get onbGuideBody =>
      'Swipe between slides or use Next. Tap the buttons on each slide to try features. You can finish anytime with Skip.';

  @override
  String get onbCtaOpenNutrition => 'Open nutrition';

  @override
  String get onbCtaLearnMore => 'Learn more';

  @override
  String get onbBadgeDone => 'Done';

  @override
  String get onbTipSetGoals => 'Tip: adjust targets first';

  @override
  String get onbTipAddEntry => 'Tip: add one entry today';

  @override
  String get onbTipLocalControl => 'You control all data locally';

  @override
  String get onbTrackHowBody =>
      'How to log nutrition:\n• Open the Food tab.\n• Tap the + button.\n• Search products or scan a barcode.\n• Adjust portion and time.\n• Save to your diary.';

  @override
  String get onbMeasureTitle => 'Track measurements';

  @override
  String get onbMeasureBody =>
      'How to add measurements:\n• Open the Stats tab.\n• Tap the + button.\n• Choose a metric (e.g., weight, waist, body fat).\n• Enter value and time.\n• Save to your history.';

  @override
  String get onbTipMeasureToday =>
      'Tip: add today’s weight to start your graph';

  @override
  String get onbTrainTitle => 'Train with routines';

  @override
  String get onbTrainBody =>
      'Create a routine and start a workout:\n• Open the Train tab.\n• Tap Create routine to add exercises and sets.\n• Save the routine.\n• Tap Start to begin, or use “Start empty workout”.';

  @override
  String get onbTipStartWorkout =>
      'Tip: start an empty workout to log a quick session';

  @override
  String get unitsSection => 'units';

  @override
  String get weightUnit => 'Weight units';

  @override
  String get lengthUnit => 'unit of length';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get noFavorites => 'No Favorites';

  @override
  String get nothingTrackedYet => 'Nothing tracked yet';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'No product found for barcode \"$barcode\".';
  }

  @override
  String get categoryHint => 'e.g. Chest, Back, Legs...';

  @override
  String get validatorPleaseEnterCategory => 'Please enter a category.';

  @override
  String get dialogEnterPasswordImport => 'Enter password to import backup';

  @override
  String get dataManagementBackupTitle => 'Hypertrack Data Backup';

  @override
  String get dataManagementBackupDescription =>
      'Back up or restore all your app data. Ideal for changing devices.';

  @override
  String get exportEncrypted => 'Export Encrypted';

  @override
  String get dialogPasswordForExport => 'Password for encrypted export';

  @override
  String get snackbarEncryptedBackupShared => 'Encrypted backup shared.';

  @override
  String get exportFailed => 'Export failed.';

  @override
  String get csvExportTitle => 'Data Export (CSV)';

  @override
  String get csvExportDescription =>
      'Export parts of your data as a CSV file for analysis in other programs.';

  @override
  String get snackbarSharingNutrition => 'Sharing nutrition diary...';

  @override
  String get snackbarExportFailedNoEntries =>
      'Export failed. There may be no entries yet.';

  @override
  String get snackbarSharingMeasurements => 'Sharing measurements...';

  @override
  String get snackbarSharingWorkouts => 'Sharing workout history...';

  @override
  String get mapExercisesTitle => 'Map Exercises';

  @override
  String get mapExercisesDescription =>
      'Map unknown names from logs to wger exercises.';

  @override
  String get mapExercisesButton => 'Start Mapping';

  @override
  String get autoBackupTitle => 'Automatic Backups';

  @override
  String get autoBackupDescription =>
      'Periodically saves a backup in the folder. Current folder:';

  @override
  String get autoBackupDefaultFolder => 'App-Documents/Backups (Default)';

  @override
  String get autoBackupChooseFolder => 'Choose Folder';

  @override
  String get autoBackupCopyPath => 'Copy Path';

  @override
  String get autoBackupRunNow => 'Check & Run Auto-Backup Now';

  @override
  String get snackbarAutoBackupSuccess => 'Auto-Backup completed.';

  @override
  String get snackbarAutoBackupFailed => 'Auto-Backup failed or was canceled.';

  @override
  String get noUnknownExercisesFound => 'No unknown exercises found';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Auto-backup folder set:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Path copied';

  @override
  String get passwordLabel => 'Password';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get involvedMuscles => 'Involved Muscles';

  @override
  String get primaryLabel => 'Primary:';

  @override
  String get secondaryLabel => 'Secondary:';

  @override
  String get noMusclesSpecified => 'No muscles specified.';

  @override
  String get noSelection => 'No selection';

  @override
  String get selectButton => 'Select';

  @override
  String get applyingChanges => 'Applying changes...';

  @override
  String get applyMapping => 'Apply Mapping';

  @override
  String get personalData => 'Personal Data';

  @override
  String get personalDataCL => 'PERSONAL DATA';

  @override
  String get macroDistribution => 'Macronutrient Distribution';

  @override
  String get dialogFinishWorkoutBody =>
      'Are you sure you want to finish this workout?';

  @override
  String get attributionText =>
      'This app uses data from external sources:\n\n● Exercise data and images from wger (wger.de), licensed under CC-BY-SA 4.0.\n\n● Food database from Open Food Facts (openfoodfacts.org), available under the Open Database License (ODbL).';

  @override
  String get errorRoutineNotFound => 'Routine not found';

  @override
  String get workoutHistoryEmptyTitle => 'Your history is empty';

  @override
  String get workoutSummaryTitle => 'Workout Complete';

  @override
  String get workoutSummaryExerciseOverview => 'Exercise Overview';

  @override
  String get nutritionDiary => 'Diary';

  @override
  String get detailedNutrientGoals => 'Detailed Nutrients';

  @override
  String get detailedNutrientGoalsCL => 'DETAILED NUTRIENTS';

  @override
  String get supplementTrackerTitle => 'Supplement Tracker';

  @override
  String get supplementTrackerDescription => 'Track goals, limits, and intake.';

  @override
  String get createSupplementTitle => 'Create Supplement';

  @override
  String get supplementNameLabel => 'Supplement Name';

  @override
  String get defaultDoseLabel => 'Default Dose';

  @override
  String get unitLabel => 'Unit';

  @override
  String get dailyGoalLabel => 'Daily Goal (optional)';

  @override
  String get dailyLimitLabel => 'Daily Limit (optional)';

  @override
  String get dailyProgressTitle => 'Daily Progress';

  @override
  String get todaysLogTitle => 'Today\'s Log';

  @override
  String get logIntakeTitle => 'Log Intake';

  @override
  String get emptySupplementGoals =>
      'Set goals or limits for supplements to see your progress here.';

  @override
  String get emptySupplementLogs => 'No intake logged for today yet.';

  @override
  String get doseLabel => 'Dose';

  @override
  String get settingsDescription => 'Theme, units, data and more';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get caffeinePrompt => 'Caffeine (optional)';

  @override
  String get caffeineUnit => 'mg per 100ml';

  @override
  String get profile => 'Profile';

  @override
  String get measurementWeightCapslock => 'BODY WEIGHT';

  @override
  String get diary => 'Diary';

  @override
  String get analysis => 'Analysis';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get dayBeforeYesterday => 'Two days ago';

  @override
  String get statistics => 'Statistics';

  @override
  String get workout => 'Workout';

  @override
  String get addFoodTitle => 'add food';

  @override
  String get nutritionExplorerTitle => 'Nutrition Explorer';

  @override
  String get myMeals => 'My Meals';

  @override
  String get myMealsCL => 'MY MEALS';

  @override
  String get supplement_caffeine => 'Caffeine';

  @override
  String get supplement_creatine_monohydrate => 'Creatine Monohydrate';

  @override
  String get manageSupplementsTitle => 'Manage supplements';

  @override
  String get deleted => 'deleted';

  @override
  String get operationNotAllowed => 'This operation isn\'t allowed';

  @override
  String get emptySupplements => 'No supplements available';

  @override
  String get undo => 'Rückgängig';

  @override
  String get deleteSupplementConfirm =>
      'Are you sure you want to delete this supplement? All historical data will be lost.\n\nTip: You can simply untrack it by editing the supplement instead.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get unitNotSupported => 'Unit not supported.';

  @override
  String get caffeineUnitLocked => 'For caffeine the unit is fixed: mg.';

  @override
  String get caffeineMustBeMg => 'Caffeine must be recorded in mg.';

  @override
  String get tabCatalogSearch => 'Catalog';

  @override
  String get tabMeals => 'Meals';

  @override
  String get emptyCategory => 'No entries';

  @override
  String get searchSectionBase => 'Base foods';

  @override
  String get searchSectionOther => 'Other results';

  @override
  String get mealsComingSoonTitle => 'Meals (coming soon)';

  @override
  String get mealsComingSoonBody =>
      'Soon you will be able to create your own meals from multiple foods.';

  @override
  String get mealsEmptyTitle => 'No meals yet';

  @override
  String get mealsEmptyBody =>
      'Create meals to quickly log multiple foods at once.';

  @override
  String get mealsCreate => 'Create meal';

  @override
  String get mealsEdit => 'Edit meal';

  @override
  String get mealsDelete => 'Delete meal';

  @override
  String get mealsAddToDiary => 'Add food';

  @override
  String get mealNameLabel => 'Meal name';

  @override
  String get mealNotesLabel => 'Notes';

  @override
  String get mealIngredientsTitle => 'Ingredients';

  @override
  String get mealAddIngredient => 'Add ingredient';

  @override
  String get mealIngredientAmountLabel => 'Amount';

  @override
  String get mealDeleteConfirmTitle => 'Delete meal';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Are you sure you want to delete the meal \'$name\'? All its ingredients will also be removed.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Meal \'$name\' has been added to your diary.';
  }

  @override
  String get mealSaved => 'Meal saved.';

  @override
  String get mealDeleted => 'Meal deleted.';

  @override
  String get confirm => 'Confirm';

  @override
  String get addMealToDiaryTitle => 'Add to diary';

  @override
  String get mealTypeLabel => 'Meal';

  @override
  String get amountLabel => 'Amount';

  @override
  String get mealAddedToDiarySuccess => 'Meal added to diary';

  @override
  String get error => 'Error';

  @override
  String get mealsViewTitle => 'mealsViewTitle';

  @override
  String get noNotes => 'No notes';

  @override
  String get ingredientsCapsLock => 'INGREDIENTS';

  @override
  String get nutritionSectionLabel => 'NUTRITION FACTS';

  @override
  String get nutritionCalculatedForCurrentAmounts => 'for current quantities';

  @override
  String get startCapsLock => 'START';

  @override
  String get nutritionHubSubtitle =>
      'Discover insights, track meals, and plan your nutrition here soon.';

  @override
  String get nutritionHubTitle => 'Nutrition';

  @override
  String get nutrition => 'nutrition';

  @override
  String get changeSetTypTitle => 'Change set type';

  @override
  String get settingsVisualStyleTitle => 'Visual Style';

  @override
  String get settingsVisualStyleStandard => 'Standard (Glass)';

  @override
  String get settingsVisualStyleLiquid => 'Fluid (Liquid Glass)';

  @override
  String get settingsVisualStyleLiquidDesc => 'Rounded, floating UI elements';

  @override
  String get settingsMaterialColorsTitle => 'Material colors';

  @override
  String get settingsMaterialColorsSubtitle =>
      'Use Android dynamic colors (Material You) instead of the Hypertrack brand accent';

  @override
  String get searchBaseFoodHint => 'Search base foods';

  @override
  String get searchNoHits => 'No hits.';

  @override
  String get onbSubtitleWelcome =>
      'Your central tool for fitness, nutrition & progress.';

  @override
  String get onbBodyWelcome =>
      'We help you set and track your goals. Efficiently log workouts, nutrition, supplements, and body measurements.';

  @override
  String get onbBodyNutritionVisual =>
      'Log meals with just a few clicks. Keep an eye on calories, macros, and water to effortlessly track your goal.';

  @override
  String get onbBodyMeasurementsVisual =>
      'Visualize your progress. The weight and circumference chart makes your success visible and keeps you motivated.';

  @override
  String get onbBodyWorkoutVisual =>
      'Create routines and start your training in seconds. Log sets, weights, and rests for maximum progression.';

  @override
  String get onbTitleAppLayout => 'Navigation & Quick-Add';

  @override
  String get onbBodyAppLayout =>
      'The bottom bar allows quick switching between areas. Use the large [+] button to log everything instantly.';

  @override
  String get dataHubTitle => 'Data Hub';

  @override
  String get resumeButton => 'Resume';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Hypertrack';

  @override
  String get onboardingWelcomeSubtitle =>
      'Let\'s set up your profile to get the best results.';

  @override
  String get onboardingNameTitle => 'What\'s your name?';

  @override
  String get onboardingNameLabel => 'Your Name';

  @override
  String get onboardingNameError => 'Please enter your name';

  @override
  String get onboardingDobTitle => 'When were you born?';

  @override
  String get onboardingDobLabel => 'Date of Birth';

  @override
  String get onboardingDobError => 'Please select your date of birth';

  @override
  String get onboardingWeightTitle => 'Current Weight';

  @override
  String get onboardingWeightLabel => 'Weight (kg)';

  @override
  String get onboardingWeightError => 'Please enter a valid weight';

  @override
  String get onboardingGoalsTitle => 'Your Nutrition Goals';

  @override
  String get onboardingGoalsSubtitle =>
      'You can change these later in settings.';

  @override
  String get onboardingGoalCalories => 'Daily Calories (kcal)';

  @override
  String get onboardingGoalProtein => 'Protein (g)';

  @override
  String get onboardingGoalCarbs => 'Carbs (g)';

  @override
  String get onboardingGoalFat => 'Fat (g)';

  @override
  String get onboardingGoalWater => 'Water (ml)';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingFinish => 'Start Tracking';

  @override
  String get onboardingHeightLabel => 'Height (cm)';

  @override
  String get onboardingGenderLabel => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderDiverse => 'Diverse';

  @override
  String get aiSettingsTitle => 'AI Meal Capture';

  @override
  String get aiSettingsDescription => 'Configure AI-powered meal recognition.';

  @override
  String get aiProviderSection => 'AI Provider';

  @override
  String get aiProviderLabel => 'Provider';

  @override
  String get aiApiKeySection => 'API Key';

  @override
  String get aiApiKeyLabel => 'API Key';

  @override
  String get aiApiKeyHint => 'Paste your API key here';

  @override
  String get aiSaveKey => 'Save Key';

  @override
  String get aiTestConnection => 'Test';

  @override
  String get aiTestSuccess => 'Connection successful!';

  @override
  String get aiKeySaved => 'API key saved securely.';

  @override
  String get aiPrivacySection => 'Privacy';

  @override
  String get aiPrivacyDisclosure =>
      'Your images and text are sent to the selected AI provider only when you tap Analyze. Data is never stored on external servers beyond processing your request. Your API key is stored encrypted on this device only.';

  @override
  String get aiMealCapture => 'AI Meal';

  @override
  String get aiCaptureTitle => 'AI Meal Capture';

  @override
  String get aiCaptureTabPhoto => 'Photo';

  @override
  String get aiCaptureTabVoice => 'Voice';

  @override
  String get aiCaptureTabText => 'Text';

  @override
  String get aiCapturePhotoHint =>
      'Take or select up to 4 photos of your meal.';

  @override
  String get aiCaptureVoiceHint => 'Tap the microphone and describe your meal.';

  @override
  String get aiCaptureTextHint =>
      'Describe your meal (e.g. \"Grilled chicken with rice and salad\")...';

  @override
  String get aiAnalyzeButton => 'Analyze';

  @override
  String get aiAnalyzing => 'Analyzing your meal...';

  @override
  String get aiReviewTitle => 'Review Suggestions';

  @override
  String aiReviewFoundItems(int count) {
    return 'AI found $count items';
  }

  @override
  String get aiReviewNoMatch => 'No match — tap to search';

  @override
  String get aiReviewConfidence => 'Confidence';

  @override
  String get aiReviewAddItem => 'Add item manually';

  @override
  String get aiReviewSaveToDiary => 'Save to Diary';

  @override
  String get aiReviewFeedbackHint => 'Describe what the AI got wrong...';

  @override
  String get aiReviewRetryButton => 'Retry with Feedback';

  @override
  String get aiReviewFeedbackSection => 'Correction';

  @override
  String get aiErrorNoKey =>
      'No API key configured. Please set one in Settings → AI Meal Capture.';

  @override
  String get aiErrorNetwork =>
      'Network error. Please check your connection and try again.';

  @override
  String get aiErrorAuth => 'Authentication failed. Please check your API key.';

  @override
  String get aiErrorParse =>
      'Could not understand the AI response. Please try again.';

  @override
  String get aiErrorRateLimit => 'Too many requests. Please wait a moment.';

  @override
  String get aiEnableTitle => 'Enable AI Features';

  @override
  String get aiEnableSubtitle =>
      'Allows the use of AI for meal recognition. Disabling this hides all AI buttons in the app.';

  @override
  String get aiRecommendationTitle => 'AI Meal Coach';

  @override
  String get aiRecommendDietary => 'Dietary';

  @override
  String get aiRecommendSituation => 'Situation';

  @override
  String get aiRecommendVegan => 'Vegan';

  @override
  String get aiRecommendVegetarian => 'Vegetarian';

  @override
  String get aiRecommendPescetarian => 'Pescetarian';

  @override
  String get aiRecommendOnTheGo => 'On the go (No utensils)';

  @override
  String get aiRecommendNoKitchen => 'No cooking (Cold meal)';

  @override
  String get aiRecommendWithCooking => 'Cooking allowed';

  @override
  String get aiRecommendGenerate => 'Generate';

  @override
  String get aiRecommendGenerating => 'Thinking…';

  @override
  String get aiRecommendSaveToDiary => 'Save to Diary';

  @override
  String get aiRecommendNoMatch => 'No database match';

  @override
  String get aiRecommendRemainingMacros => 'Remaining today';

  @override
  String get aiRecommendCustomRequest => 'Custom request';

  @override
  String get aiRecommendCustomRequestHint =>
      'e.g. Include leftover rice, high protein, etc.';

  @override
  String get currentlyTracking => 'Currently tracking';

  @override
  String get currentlyTrackingDesc => 'Show in daily tracker hub';

  @override
  String get filter3Months => '3 Months';

  @override
  String get filter6Months => '6 Months';

  @override
  String get sectionConsistency => 'Consistency & Frequency';

  @override
  String get metricsWorkoutsWeek => 'Workouts (Week)';

  @override
  String get metricsCurrentStreak => 'Current Streak';

  @override
  String get metricsActiveWeeks => 'weeks active';

  @override
  String get placeholderCalendarHeatmap => 'Calendar Heatmap Visual';

  @override
  String get consistencyTrackerTitle => 'Consistency Tracker';

  @override
  String get consistencyTrackerComingSoon =>
      'Consistency & Habit Tracker (Coming Soon)';

  @override
  String get sectionMuscleVolume => 'Muscle Groups & Volume';

  @override
  String get metricsTopTrained => 'Top Trained';

  @override
  String get metricsMostNeglected => 'Most Neglected';

  @override
  String get placeholderMuscleHeatmap => 'Muscle Heatmap Visual';

  @override
  String get muscleAnalyticsTitle => 'Muscle Group Analytics';

  @override
  String get muscleAnalyticsComingSoon =>
      'Muscle Volume & Heatmaps (Coming Soon)';

  @override
  String get sectionPerformance => 'Performance & PRs';

  @override
  String get metricsRecentPrs => 'Recent PRs';

  @override
  String get metricsVolumeLifted => 'Volume Lifted';

  @override
  String get metricsMostImproved => 'Most Improved';

  @override
  String get exerciseAnalyticsTitle => 'Exercise Analytics';

  @override
  String get exerciseAnalyticsSubtitle =>
      'Search and analyze specific exercises';

  @override
  String get prDashboardTitle => 'PR Dashboard';

  @override
  String get prDashboardComingSoon => 'Records & Progress (Coming Soon)';

  @override
  String get exerciseAnalyticsComingSoon =>
      'Exercise search & specific trends (Coming Soon)';

  @override
  String get sectionRecovery => 'Recovery';

  @override
  String get metricsMuscleReadiness => 'Muscle Readiness';

  @override
  String get recoveryTrackerTitle => 'Recovery Tracker';

  @override
  String get recoveryTrackerComingSoon =>
      'Muscle readiness & fatigue (Coming Soon)';

  @override
  String get recoveryOverallMostlyRecovered => 'Mostly recovered';

  @override
  String get recoveryOverallMixed => 'Mixed recovery state';

  @override
  String get recoveryOverallSeveralRecovering =>
      'Several muscle groups still recovering';

  @override
  String get recoveryOverallInsufficientData =>
      'Not enough data for recovery insight yet';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return 'Recovering: $recovering  Ready: $ready  Fresh: $fresh';
  }

  @override
  String get recoveryHubNoDataSummary =>
      'Keep logging workouts to unlock recovery insights.';

  @override
  String get recoveryByMuscleTitle => 'Recovery by Muscle';

  @override
  String get recoveryStateRecovering => 'Recovering';

  @override
  String get recoveryStateReady => 'Ready';

  @override
  String get recoveryStateFresh => 'Fresh';

  @override
  String get recoveryStateUnknown => 'Unknown';

  @override
  String recoveryLastLoadedHours(int hours) {
    return 'Last significant loading: ${hours}h ago';
  }

  @override
  String get recoveryFatigueContextHigh =>
      'Recent fatigue context: high session fatigue';

  @override
  String get recoveryFatigueContextBaseline =>
      'Recent fatigue context: baseline session fatigue';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle: last significantly loaded ${hours}h ago, with high session fatigue.';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle: last significantly loaded ${hours}h ago.';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'This is a conservative heuristic based on recent significant loading and session effort. It is not a medical recovery measurement.';

  @override
  String recoveryRecentLoad(String sets) {
    return 'Recent load amount: $sets equivalent sets';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return 'Heuristic window: often around $from to $to hours, depending on context.';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      'Radar overview of recent recovery pressure by muscle. It is directional and heuristic.';

  @override
  String get recoveryNoDataBody =>
      'Not enough significant training load has been logged yet to estimate muscle recovery.';

  @override
  String get sectionBodyNutrition => 'Body & Nutrition';

  @override
  String get metricsCurrentWeight => 'Current Weight';

  @override
  String get metricsAvgCalories => 'Avg. Calories';

  @override
  String get placeholderWeightTrend => 'Weight Trend Line Chart';

  @override
  String get exerciseAnalyticsPrsLabel => 'PERSONAL RECORDS';

  @override
  String get exerciseAnalyticsTrendsLabel => 'TRENDS';

  @override
  String get exerciseAnalyticsNoData => 'No tracking data for this exercise.';

  @override
  String get exerciseAnalyticsNotEnoughData => 'Not enough data';

  @override
  String get exerciseAnalyticsChartWeight => 'Weight Over Time (kg)';

  @override
  String get exerciseAnalyticsChartVolume => 'Volume Over Time (kg)';

  @override
  String get exerciseAnalyticsChartSets => 'Sets Over Time';

  @override
  String get allTimeRecordsLabel => 'All-Time Records';

  @override
  String get recentActivityLabel => 'Recent Activity';

  @override
  String get prsByRepRangeLabel => 'Best Set by Rep Range';

  @override
  String get volumeAnalyticsTitle => 'Volume Analytics';

  @override
  String get weeklyTonnageLabel => 'Weekly Tonnage';

  @override
  String get volumeByMuscleLabel => 'By Muscle Group';

  @override
  String get topExercisesLabel => 'Top Exercises';

  @override
  String get thisWeekLabel => 'This Week';

  @override
  String get avgPerWeekLabel => 'Avg / Week';

  @override
  String get streakLabel => 'Streak';

  @override
  String get trainingCalendarLabel => 'Training Calendar';

  @override
  String get workoutsPerWeekLabel => 'Workouts per Week';

  @override
  String get totalWorkoutsLabel => 'Total';

  @override
  String get weeksLabel => 'Weeks';

  @override
  String get tonnageKgLabel => 'Tonnage (kg)';

  @override
  String get noWorkoutDataLabel =>
      'No workout data yet. Start logging to see stats.';

  @override
  String get analyticsSectionVolumeMuscles => 'Volume & Muscle Groups';

  @override
  String get analyticsSectionPerformanceRecords => 'Performance & Records';

  @override
  String get analyticsTopVolume => 'Top Trained';

  @override
  String get analyticsLowestVolume => 'Lowest Volume';

  @override
  String get analyticsRecentRecords => 'Recent Records';

  @override
  String analyticsPerfWithReps(String weight, int reps) {
    return '$weight kg x $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg (this week)';

  @override
  String get analyticsRecoverySummary => '3 recovering, 8 ready';

  @override
  String get analyticsViewDetails => 'View details';

  @override
  String get analyticsRepRangeSuffix => ' reps';

  @override
  String get analyticsNoRecordYet => 'No record yet';

  @override
  String get analyticsNotableImprovements => 'Notable Improvements';

  @override
  String get analyticsNoPrTrendInWindow =>
      'There is no clear PR trend in this window yet.';

  @override
  String analyticsE1rmProgress(String previous, String recent) {
    return 'e1RM $previous -> $recent kg';
  }

  @override
  String get analyticsUnitKg => 'kg';

  @override
  String get analyticsUnitSets => 'sets';

  @override
  String get analyticsViewLabel => 'View';

  @override
  String get analyticsViewWeek => 'Week';

  @override
  String get analyticsViewMonth => 'Month';

  @override
  String get analyticsViewByExercise => 'By Exercise';

  @override
  String get analyticsViewByMuscle => 'By Muscle Group';

  @override
  String get analyticsMetricLabel => 'Metric';

  @override
  String get analyticsMovedWeightKg => 'Moved Weight (kg)';

  @override
  String get analyticsWorkSets => 'Work Sets';

  @override
  String get analyticsVolumeContextWithSets =>
      'Moved weight = weight x reps. Switch to work sets for count-based load.';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'This view uses moved weight (weight x reps).';

  @override
  String get analyticsKpisHeader => 'KPIs';

  @override
  String get analyticsTrainingDaysPerWeek => 'Training Days / Week';

  @override
  String get analyticsLast4Weeks => 'last 4 weeks';

  @override
  String get analyticsRhythm => 'Rhythm';

  @override
  String get analyticsVsPrior4Weeks => 'vs the previous 4 weeks';

  @override
  String get analyticsRollingConsistency => 'Rolling Consistency';

  @override
  String get analyticsWeeksAtLeast2Workouts => 'weeks with at least 2 sessions';

  @override
  String get analyticsCalendarExplainer =>
      'Color intensity reflects sessions per day, making this a true consistency map.';

  @override
  String get analyticsSelectDayPrompt =>
      'Select a day to inspect session count.';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date: $count sessions';
  }

  @override
  String get analyticsTotalSessions => 'Total Sessions';

  @override
  String get analyticsPlaceholderWeightValue => '82.5';

  @override
  String get analyticsPlaceholderWeightTrend => 'kg (-0.5)';

  @override
  String get analyticsPlaceholderCaloriesValue => '2,450';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/day';

  @override
  String get analyticsMuscleWeeklySets => 'Weekly Sets';

  @override
  String get analyticsMuscleTopFrequency => 'Top Frequency';

  @override
  String get analyticsPerWeekAbbrev => 'wk';

  @override
  String get analyticsKeepTrackingUnlockInsights =>
      'Keep tracking to unlock insights.';

  @override
  String get analyticsGuidanceNoClearWeakPoint =>
      'Guidance: No clear weak point in this period.';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'Guidance: Lower recent emphasis on $muscles.';
  }

  @override
  String get analyticsPeriodLabel => 'Period';

  @override
  String get analyticsEquivalentSetsExplainer =>
      'Equivalent hard sets use primary x1.0 and secondary x0.5 weighting. Frequency counts only days reaching >= 1.0 equivalent sets.';

  @override
  String get analyticsWeeklySetsByMuscle => 'Weekly Sets by Muscle';

  @override
  String get analyticsFrequencyByMuscle => 'Frequency by Muscle';

  @override
  String get analyticsRecentDistributionHeatmap =>
      'Recent Distribution Heatmap';

  @override
  String get analyticsRadarOverviewTitle => 'Radar Overview';

  @override
  String get analyticsRadarVolumeCaption =>
      'Shows relative volume distribution across muscles for a quick at-a-glance summary.';

  @override
  String get analyticsGuidanceTitle => 'Guidance';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'This is directional guidance based on your recent set distribution, not an absolute diagnosis.';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      'Insights are intentionally softened until enough data is available.';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Week total: $value equivalent sets';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      'Frequency counts only days where the muscle reached >= 1.0 equivalent sets.';

  @override
  String liveWorkoutE1rmCurrentSet(String value) {
    return 'e1RM $value kg';
  }

  @override
  String liveWorkoutE1rmBestSession(String value) {
    return 'Best e1RM this session: $value kg';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta) {
    return 'vs last session: $delta kg';
  }

  @override
  String get bodyNutritionCorrelationTitle => 'Body & Nutrition Trends';

  @override
  String get metricsWeightChange => 'Weight Change';

  @override
  String get analyticsKcalPerDay => 'kcal/day';

  @override
  String get analyticsDaysWithWeightData => 'days with weight';

  @override
  String get analyticsDayUnitLabel => 'days';

  @override
  String get analyticsPerDayLabel => 'per day';

  @override
  String get analyticsEffectiveRangeLabel => 'Effective range';

  @override
  String get analyticsAxisXLabel => 'X';

  @override
  String get analyticsAxisYLabel => 'Y';

  @override
  String get analyticsHighConfidenceLabel => 'Higher-confidence pattern';

  @override
  String get analyticsLowConfidenceLabel => 'Lower-confidence pattern';

  @override
  String get analyticsObservedPatternLabel => 'Observed pattern';

  @override
  String get analyticsBodyNutritionTrendContext =>
      'Body weight and calorie trends';

  @override
  String get analyticsBodyNutritionTrendContextHint =>
      'These lines show nearby trend movement over the same period for context.';

  @override
  String get analyticsWeightTrendLabel => 'Body weight (smoothed)';

  @override
  String get analyticsCaloriesTrendLabel => 'Calories (daily avg trend)';

  @override
  String get analyticsInterpretationTitle => 'Interpretation';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'Data coverage in this range is strong enough for a more reliable pattern read.';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'Data coverage in this range is still limited, so treat this as early context.';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      'Keep logging weight and calories regularly to improve confidence.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      'Interpretation confidence: higher. Use this as trend context, not a direct cause statement.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      'Interpretation confidence: lower. Use this as an early pattern signal and keep tracking.';

  @override
  String get analyticsCorrelationDisclaimer =>
      'This view shows trend correlation over time. It does not prove that calorie changes directly caused weight changes.';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      'Weight trend is stable while average calories increased.';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      'Weight is trending upward alongside higher average calorie intake.';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      'Recent calorie reduction has not yet clearly changed the weight trend.';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      'Weight is trending downward alongside lower average calorie intake.';

  @override
  String get analyticsInsightMixedPattern =>
      'Weight and calorie trends move in mixed directions without a clear correlation pattern yet.';

  @override
  String get analyticsInsightNotEnoughData =>
      'Not enough data yet for meaningful correlation insight.';

  @override
  String get restTimerNotificationTitle => 'Rest finished';

  @override
  String get restTimerNotificationBody =>
      'Your pause timer is over. Ready for the next set.';

  @override
  String get onboardingContinueSetup => 'Set Up Profile';

  @override
  String get onboardingRestoreFromBackup => 'Restore from Backup';

  @override
  String get onboardingRestoreImporting => 'Importing backup...';

  @override
  String get onboardingRestoreSuccess => 'Backup restored successfully!';

  @override
  String get onboardingRestoreFailed =>
      'Import failed. Please check the file and try again.';

  @override
  String get finishWorkoutTitleLabel => 'Workout Title';

  @override
  String get finishWorkoutNotesLabel => 'Notes (optional)';

  @override
  String get finishWorkoutNotesHint => 'How did the workout go?';

  @override
  String get sleepSectionTitle => 'Sleep';

  @override
  String get sleepSectionSubtitleDayEntry =>
      'Day overview and detail drill-downs';

  @override
  String get sleepSectionSubtitleAllEntry =>
      'Sleep day, week, and month views are available from this entry';

  @override
  String get sleepScopeDay => 'Day';

  @override
  String get sleepScopeWeek => 'Week';

  @override
  String get sleepScopeMonth => 'Month';

  @override
  String get sleepWeekSummaryTitle => 'Week summary';

  @override
  String get sleepMonthSummaryTitle => 'Month summary';

  @override
  String get sleepSleepWindowTitle => 'Sleep window';

  @override
  String get sleepDailyScoreTitle => 'Daily score';

  @override
  String get sleepMonthDailyScoreStatesTitle => 'Daily score states';

  @override
  String sleepMeanScoreLabel(String value) {
    return 'Mean score: $value';
  }

  @override
  String get sleepHubScoreLabel => 'Sleep score';

  @override
  String get sleepHubAverageLabel => 'Average';

  @override
  String get sleepHubBedtimeLabel => 'Bedtime';

  @override
  String get sleepHubInterruptionsLabel => 'Interruptions';

  @override
  String sleepHubInterruptionsSummary(int count, String duration) {
    return '$count wake-ups, $duration total';
  }

  @override
  String sleepWeekdayAvgDurationLabel(String value) {
    return 'Weekday avg duration: $value';
  }

  @override
  String sleepWeekendAvgDurationLabel(String value) {
    return 'Weekend avg duration: $value';
  }

  @override
  String get sleepWeekNoScoredNights =>
      'No scored sleep nights available in this week yet.';

  @override
  String get sleepMonthNoScoredNights =>
      'No scored sleep nights available this month yet.';

  @override
  String get sleepSettingsSectionTitle => 'Sleep';

  @override
  String get sleepEnableTrackingTitle => 'Enable sleep tracking';

  @override
  String get sleepEnableTrackingSubtitle =>
      'Read sleep and overnight heart rate from Health Connect / HealthKit';

  @override
  String get sleepHealthConnectionStatusTitle => 'Health connection status';

  @override
  String get sleepRequestAccessTitle => 'Request access';

  @override
  String get sleepRequestAccessSubtitle =>
      'Request or re-request sleep/heart-rate permissions';

  @override
  String get sleepImportNowTitle => 'Import sleep data now';

  @override
  String get sleepImportNowSubtitle =>
      'Import all available sleep data (all time)';

  @override
  String get sleepRawImportsTitle => 'View raw sleep imports';

  @override
  String get sleepRawImportsSubtitle => 'Show recent Health Connect payloads';

  @override
  String get sleepDataStatusTitle => 'Data status';

  @override
  String get sleepDataStatusSubtitle =>
      'Permissions granted. If no sleep appears yet, run a manual import below.';

  @override
  String get sleepNoPermissionTitle => 'No permission';

  @override
  String get sleepNoPermissionSubtitle =>
      'Sleep and heart-rate permissions are required to import sleep data.';

  @override
  String get sleepFeatureUnavailableTitle => 'Feature unavailable';

  @override
  String get sleepFeatureUnavailableSubtitle =>
      'Sleep import is unavailable on this device or Health Connect is not installed.';

  @override
  String get sleepNoRawImportsFound => 'No raw sleep imports found yet.';

  @override
  String get sleepRawImportsSheetTitle => 'Raw sleep imports (latest)';

  @override
  String sleepImportFinishedSessions(int count) {
    return 'Sleep import finished ($count sessions).';
  }

  @override
  String get sleepImportUnavailableCheckPermissions =>
      'Sleep import unavailable. Check permissions.';

  @override
  String get sleepStatusChecking => 'Checking permission status…';

  @override
  String get sleepStatusReady => 'Ready';

  @override
  String get sleepStatusDenied => 'Denied';

  @override
  String get sleepStatusPartial => 'Partial access';

  @override
  String get sleepStatusUnavailable => 'Unavailable on this device';

  @override
  String get sleepStatusNotInstalled => 'Health Connect not installed';

  @override
  String get sleepStatusTechnicalError => 'Technical error';

  @override
  String get sleepConnectHealthDataTitle => 'Connect health data';

  @override
  String get sleepConnectHealthDataMessage =>
      'Connect HealthKit or Health Connect to import sleep records.';

  @override
  String get sleepPermissionDeniedTitle => 'Permission denied';

  @override
  String get sleepPermissionDeniedMessage =>
      'Sleep permissions are denied. Open settings to grant access.';

  @override
  String get sleepSourceUnavailableTitle => 'Source unavailable';

  @override
  String get sleepSourceUnavailableMessage =>
      'Sleep data source is unavailable or not installed on this device.';

  @override
  String get sleepEmptyDayNoData => 'No sleep data available for this day.';

  @override
  String get sleepEmptyDayConnectMessage =>
      'Connect Health Connect/HealthKit in Settings and import recent sleep data.';

  @override
  String get sleepOpenSettingsButton => 'Open settings';

  @override
  String get sleepImportNowButton => 'Import now';

  @override
  String get sleepImportFinishedRefreshing =>
      'Sleep import finished. Refreshing...';

  @override
  String get sleepImportUnavailableSettingsHint =>
      'Sleep import not available. Check permissions in Settings.';

  @override
  String get sleepTimelineTitle => 'Timeline';

  @override
  String get sleepTimelineUnavailable =>
      'No stage timeline available for this night.';

  @override
  String get sleepStageDeepLabel => 'Deep';

  @override
  String get sleepStageLightLabel => 'Light';

  @override
  String get sleepStageRemLabel => 'REM';

  @override
  String get sleepStageAwakeLabel => 'Awake';

  @override
  String get sleepScoreCardTitle => 'Sleep quality';

  @override
  String get sleepScoreUnavailableForNight =>
      'Score unavailable for this night.';

  @override
  String sleepScoreCompletenessLabel(String value) {
    return 'Score completeness: $value';
  }

  @override
  String get sleepQualityGood => 'Good';

  @override
  String get sleepQualityAverage => 'Average';

  @override
  String get sleepQualityPoor => 'Poor';

  @override
  String get sleepQualityUnavailable => 'Unavailable';

  @override
  String get sleepQualitySubtitleGood => 'Recovery looked strong overnight.';

  @override
  String get sleepQualitySubtitleAverage =>
      'Sleep was okay with room for improvement.';

  @override
  String get sleepQualitySubtitlePoor => 'Recovery signals were weak tonight.';

  @override
  String get sleepQualitySubtitleUnavailable =>
      'Not enough data to score this night.';

  @override
  String get sleepQualityRegularityNotContributing =>
      'Regularity did not contribute (<5 valid days).';

  @override
  String get sleepQualityRegularityPreliminary =>
      'Regularity is preliminary (5-6 valid days).';

  @override
  String sleepQualityRegularityStable(int days) {
    return 'Regularity is stable ($days days).';
  }

  @override
  String sleepRegularityNightView(int count) {
    return '$count-night view';
  }

  @override
  String get sleepMetricUnavailable => 'Unavailable';

  @override
  String get sleepMetricDurationTitle => 'Duration';

  @override
  String get sleepMetricHeartRateTitle => 'Heart rate';

  @override
  String get sleepMetricRegularityTitle => 'Regularity';

  @override
  String get sleepMetricDepthTitle => 'Depth';

  @override
  String get sleepMetricInterruptionsTitle => 'Interruptions';

  @override
  String get sleepMetricDepthLowConfidence => 'Low confidence';

  @override
  String get sleepMetricDepthStagesAvailable => 'Stages available';

  @override
  String get sleepDurationUnavailable => 'Duration data is unavailable.';

  @override
  String get sleepDurationStatusWithinTarget => 'Within target';

  @override
  String get sleepDurationStatusBelowTarget => 'Below target';

  @override
  String get sleepDurationSubtitle =>
      'Your total sleep duration for this night.';

  @override
  String get sleepDurationBenchmarkHint =>
      'Adults often do best with roughly 7–9 hours. This benchmark helps you see where your night sits in that range.';

  @override
  String get sleepDepthUnavailable => 'Depth data is unavailable.';

  @override
  String get sleepDepthConfidenceTooLow =>
      'Stage confidence is too low for a reliable depth breakdown.';

  @override
  String get sleepDepthBreakdownUnavailable =>
      'Stage duration breakdown is unavailable for this night.';

  @override
  String get sleepDepthRatingRestorative => 'Restorative';

  @override
  String get sleepDepthRatingLightLeaning => 'Light-leaning';

  @override
  String sleepDepthStageConfidenceLabel(String value) {
    return 'Stage confidence: $value';
  }

  @override
  String get sleepDepthSubtitle =>
      'Stage distribution based on derived timeline segments.';

  @override
  String get sleepInterruptionsUnavailable =>
      'Interruptions data is unavailable.';

  @override
  String get sleepInterruptionsStatusNoneDetected => 'None detected';

  @override
  String get sleepInterruptionsStatusDetected => 'Detected';

  @override
  String get sleepInterruptionsSubtitle =>
      'Qualifying wake interruptions overnight.';

  @override
  String get sleepInterruptionsTotalWakeDuration => 'Total wake duration';

  @override
  String get sleepInterruptionsFootnote =>
      'This view includes only qualifying interruptions from derived analysis outputs.';

  @override
  String get sleepRegularityUnavailable => 'Regularity data is unavailable.';

  @override
  String sleepRegularityNightRange(int count) {
    return '$count-night range';
  }

  @override
  String get sleepRegularityStatusSufficientTrend => 'Sufficient trend data';

  @override
  String get sleepRegularityStatusLimitedTrend => 'Limited trend data';

  @override
  String get sleepRegularitySubtitle =>
      'Bedtime and wake windows for recent nights.';

  @override
  String get sleepRegularityAverageBedtime => 'Average bedtime';

  @override
  String get sleepRegularityAverageWake => 'Average wake';

  @override
  String get sleepHeartRateUnavailable =>
      'Sleep heart-rate data is unavailable.';

  @override
  String get sleepHeartRateStatusNoSampleSeries =>
      'No sample series for this night';

  @override
  String get sleepHeartRateStatusBaselineNotEstablished =>
      'Baseline not established';

  @override
  String get sleepHeartRateStatusComparisonUnavailable =>
      'Baseline comparison unavailable';

  @override
  String get sleepHeartRateStatusBelowBaseline => 'Below baseline';

  @override
  String get sleepHeartRateStatusAboveBaseline => 'Above baseline';

  @override
  String get sleepHeartRateNoSamplesText =>
      'No persisted sleep heart-rate samples are available for this night.';

  @override
  String get sleepHeartRateBaselineNotEstablishedText =>
      'Baseline not established yet. This is neutral and expected early on.';

  @override
  String get sleepHeartRateComparisonUnavailableText =>
      'Baseline comparison is currently unavailable for this night.';

  @override
  String sleepHeartRateDeltaText(String direction, String delta, String unit) {
    return 'Your sleep HR is $direction baseline by $delta $unit.';
  }

  @override
  String get sleepHeartRateDirectionBelow => 'below';

  @override
  String get sleepHeartRateDirectionAbove => 'above';

  @override
  String get sleepHeartRateComparedBaselineSubtitle =>
      'Compared with your established sleep baseline.';

  @override
  String get sleepHeartRateNoBaselineSubtitle =>
      'Baseline is not established yet. This is neutral.';

  @override
  String get sleepHeartRateSamplesUnavailable =>
      'No heart-rate samples were stored for this night. Trend chart is unavailable.';

  @override
  String sleepHeartRateDashedLineHint(String value, String unit) {
    return 'Dashed line shows baseline ($value $unit).';
  }

  @override
  String get sleepBpmUnit => 'bpm';

  @override
  String get sleepRawImportImportedAt => 'Imported at';

  @override
  String get sleepRawImportStatus => 'Status';

  @override
  String get sleepRawImportSource => 'Source';

  @override
  String get sleepRawImportApp => 'App';

  @override
  String get sleepRawImportConfidence => 'Confidence';

  @override
  String get sleepRawImportPayload => 'Payload';

  @override
  String get adaptiveBodyweightTargetSectionTitle =>
      'Adaptive bodyweight target';

  @override
  String get adaptiveRecommendationSettingsSectionTitle =>
      'Recommendation settings';

  @override
  String get adaptiveGoalDirectionLabel => 'Goal direction';

  @override
  String get adaptiveGoalLose => 'Lose weight';

  @override
  String get adaptiveGoalMaintain => 'Maintain weight';

  @override
  String get adaptiveGoalGain => 'Gain weight';

  @override
  String adaptiveRatePerWeek(String value) {
    return '$value kg/week';
  }

  @override
  String get adaptivePriorActivityLabel => 'Baseline daily activity';

  @override
  String get adaptivePriorActivityLow => 'Low activity';

  @override
  String get adaptivePriorActivityModerate => 'Moderate activity';

  @override
  String get adaptivePriorActivityHigh => 'High activity';

  @override
  String get adaptivePriorActivityHelp =>
      'This reflects your normal day-to-day movement (sitting, walking, standing), not extra cardio sessions.';

  @override
  String get adaptiveExtraCardioLabel =>
      'Extra cardio/endurance outside the app';

  @override
  String get adaptiveExtraCardioOption0 => '0 h/week';

  @override
  String get adaptiveExtraCardioOption1 => '1 h/week';

  @override
  String get adaptiveExtraCardioOption2 => '2 h/week';

  @override
  String get adaptiveExtraCardioOption3 => '3 h/week';

  @override
  String get adaptiveExtraCardioOption5 => '5 h/week';

  @override
  String get adaptiveExtraCardioOption7Plus => '7+ h/week';

  @override
  String get adaptiveExtraCardioHelp =>
      'Include jogging, running, cycling, swimming, or other endurance sessions not logged as Hypertrack workouts.';

  @override
  String get onboardingAdaptiveGoalTitle => 'Adaptive nutrition recommendation';

  @override
  String get onboardingAdaptiveGoalSubtitle =>
      'Set your direction and weekly rate. We create a conservative starting recommendation and adapt it with your logs.';

  @override
  String get adaptiveRecommendationGenerating => 'Generating...';

  @override
  String get adaptiveRecommendationRefresh => 'Refresh recommendation';

  @override
  String get onboardingAdaptiveSummaryEmpty =>
      'Set your goal inputs and tap refresh to preview your starting recommendation.';

  @override
  String get onboardingAdaptiveSummaryTitle => 'Recommendation preview';

  @override
  String onboardingAdaptiveSummaryCalories(int value) {
    return 'Calories: $value kcal';
  }

  @override
  String onboardingAdaptiveSummaryProtein(int value) {
    return 'Protein: $value g';
  }

  @override
  String onboardingAdaptiveSummaryCarbs(int value) {
    return 'Carbs: $value g';
  }

  @override
  String onboardingAdaptiveSummaryFat(int value) {
    return 'Fat: $value g';
  }

  @override
  String onboardingAdaptiveSummaryConfidence(String value) {
    return 'Confidence: $value';
  }

  @override
  String get onboardingAdaptiveSummaryApply => 'Apply to daily goals';

  @override
  String get onboardingAdaptiveSummaryApplied => 'Applied to daily goals';

  @override
  String get onboardingBodyFatOptionalLabel => 'Body fat % (optional)';

  @override
  String get onboardingBodyFatOptionalHelper =>
      'Optional: only enter this if you roughly know your value. Leaving it empty is okay. It helps personalize the initial recommendation.';

  @override
  String get onboardingBodyFatHelpAction => 'How do I estimate this?';

  @override
  String get onboardingBodyFatHelpDialogTitle => 'Body fat % help';

  @override
  String get onboardingBodyFatHelpDialogBody =>
      'You can leave this empty if unsure. A rough estimate is enough and only helps the initial recommendation; weekly updates adapt from your real logs.';

  @override
  String get onboardingBodyFatHelpDialogAction => 'Got it';

  @override
  String get adaptiveRecommendationCardTitle => 'Adaptive recommendation';

  @override
  String get adaptiveRecommendationEmptyBody =>
      'Track weight and nutrition for about a week to unlock your first weekly recommendation.';

  @override
  String adaptiveRecommendationGoalLine(String goal, String rate) {
    return 'Goal: $goal ($rate)';
  }

  @override
  String adaptiveRecommendationMaintenanceLine(int value) {
    return 'Maintenance estimate: $value kcal';
  }

  @override
  String adaptiveRecommendationCaloriesValue(int value) {
    return '$value kcal';
  }

  @override
  String adaptiveRecommendationProteinValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationCarbsValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationFatValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationConfidenceLine(String value) {
    return 'Confidence: $value';
  }

  @override
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays) {
    return 'Data basis: $windowDays days, $weightLogs weight logs, $intakeDays intake days';
  }

  @override
  String adaptiveRecommendationActiveCaloriesLine(int value) {
    return 'Current active calories: $value kcal';
  }

  @override
  String get adaptiveRecommendationApplying => 'Applying...';

  @override
  String get adaptiveRecommendationApplyAction =>
      'Apply recommendation to active goals';

  @override
  String get adaptiveRecommendationWarningCalorieFloor =>
      'Recommendation constrained by a minimum calorie safety floor. Review profile data and recent logs before applying.';

  @override
  String get adaptiveRecommendationWarningUnresolvedFood =>
      'Some nutrition entries could not be fully resolved for calorie estimation. Recommendation is conservative.';

  @override
  String get adaptiveRecommendationWarningLargeAdjustment =>
      'Large adjustment detected. Please review your recent logging completeness before applying.';

  @override
  String get adaptiveRecommendationWarningConservative =>
      'Review suggested: recommendation was adjusted conservatively due to data variability.';

  @override
  String get adaptiveConfidenceNotEnoughData => 'Not enough data';

  @override
  String get adaptiveConfidenceLow => 'Low';

  @override
  String get adaptiveConfidenceMedium => 'Medium';

  @override
  String get adaptiveConfidenceHigh => 'High';

  @override
  String get adaptiveRecommendationAppliedToGoalsSnack =>
      'Recommendation applied to active goals.';

  @override
  String get adaptiveRecommendationNotAvailableSnack =>
      'No recommendation available to apply.';
}
