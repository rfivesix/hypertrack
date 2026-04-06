import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hypertrack'**
  String get appTitle;

  /// No description provided for @bannerText.
  ///
  /// In en, this message translates to:
  /// **'Recommendation / Current Workout'**
  String get bannerText;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @workoutSection.
  ///
  /// In en, this message translates to:
  /// **'Workout section - not yet implemented'**
  String get workoutSection;

  /// No description provided for @addMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to add?'**
  String get addMenuTitle;

  /// No description provided for @addFoodOption.
  ///
  /// In en, this message translates to:
  /// **'add Food'**
  String get addFoodOption;

  /// No description provided for @addLiquidOption.
  ///
  /// In en, this message translates to:
  /// **'add Liquid'**
  String get addLiquidOption;

  /// No description provided for @searchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHintText;

  /// No description provided for @mealtypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealtypeBreakfast;

  /// No description provided for @mealtypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealtypeLunch;

  /// No description provided for @mealtypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealtypeDinner;

  /// No description provided for @mealtypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealtypeSnack;

  /// No description provided for @waterHeader.
  ///
  /// In en, this message translates to:
  /// **'Water & Drinks'**
  String get waterHeader;

  /// No description provided for @openFoodFactsSource.
  ///
  /// In en, this message translates to:
  /// **'Data from Open Food Facts'**
  String get openFoodFactsSource;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @fabCreateOwnFood.
  ///
  /// In en, this message translates to:
  /// **'Custom Food'**
  String get fabCreateOwnFood;

  /// No description provided for @recentEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Your recently used food items\nwill appear here.'**
  String get recentEmptyState;

  /// No description provided for @favoritesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any favorites yet.\nMark a food with the heart icon to see it here.'**
  String get favoritesEmptyState;

  /// No description provided for @searchInitialHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter a search term.'**
  String get searchInitialHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get searchNoResults;

  /// No description provided for @createFoodScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Food'**
  String get createFoodScreenTitle;

  /// No description provided for @formFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name of the food'**
  String get formFieldName;

  /// No description provided for @formFieldBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get formFieldBrand;

  /// No description provided for @formSectionMainNutrients.
  ///
  /// In en, this message translates to:
  /// **'Main Nutrients (per 100g)'**
  String get formSectionMainNutrients;

  /// No description provided for @formFieldCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get formFieldCalories;

  /// No description provided for @formFieldProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get formFieldProtein;

  /// No description provided for @formFieldCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates (g)'**
  String get formFieldCarbs;

  /// No description provided for @formFieldFat.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get formFieldFat;

  /// No description provided for @formSectionOptionalNutrients.
  ///
  /// In en, this message translates to:
  /// **'Additional Nutrients (optional, per 100g)'**
  String get formSectionOptionalNutrients;

  /// No description provided for @formFieldSugar.
  ///
  /// In en, this message translates to:
  /// **'Of which sugars (g)'**
  String get formFieldSugar;

  /// No description provided for @formFieldFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber (g)'**
  String get formFieldFiber;

  /// No description provided for @formFieldKj.
  ///
  /// In en, this message translates to:
  /// **'Kilojoules (kJ)'**
  String get formFieldKj;

  /// No description provided for @formFieldSalt.
  ///
  /// In en, this message translates to:
  /// **'Salt (g)'**
  String get formFieldSalt;

  /// No description provided for @formFieldSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium (mg)'**
  String get formFieldSodium;

  /// No description provided for @formFieldCalcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium (mg)'**
  String get formFieldCalcium;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @validatorPleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get validatorPleaseEnterName;

  /// No description provided for @validatorPleaseEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number.'**
  String get validatorPleaseEnterNumber;

  /// No description provided for @snackbarSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'{foodName} was saved successfully.'**
  String snackbarSaveSuccess(String foodName);

  /// No description provided for @foodDetailSegmentPortion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get foodDetailSegmentPortion;

  /// No description provided for @foodDetailSegment100g.
  ///
  /// In en, this message translates to:
  /// **'100g'**
  String get foodDetailSegment100g;

  /// No description provided for @sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugar;

  /// No description provided for @fiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiber;

  /// No description provided for @salt.
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get salt;

  /// No description provided for @explorerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Food Explorer'**
  String get explorerScreenTitle;

  /// No description provided for @nutritionScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Analysis'**
  String get nutritionScreenTitle;

  /// No description provided for @entriesForDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries for'**
  String get entriesForDateRangeLabel;

  /// No description provided for @noEntriesForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No entries for this period yet.'**
  String get noEntriesForPeriod;

  /// No description provided for @waterEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterEntryTitle;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileScreenTitle;

  /// No description provided for @profileDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get profileDailyGoals;

  /// No description provided for @profileDailyGoalsCL.
  ///
  /// In en, this message translates to:
  /// **'DAILY GOALS'**
  String get profileDailyGoalsCL;

  /// No description provided for @snackbarGoalsSaved.
  ///
  /// In en, this message translates to:
  /// **'Goals saved successfully!'**
  String get snackbarGoalsSaved;

  /// No description provided for @measurementsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurementsScreenTitle;

  /// No description provided for @measurementsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No measurements recorded yet.\nStart with the \'+\' button.'**
  String get measurementsEmptyState;

  /// No description provided for @addMeasurementDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Measurement'**
  String get addMeasurementDialogTitle;

  /// No description provided for @formFieldMeasurementType.
  ///
  /// In en, this message translates to:
  /// **'Type of Measurement'**
  String get formFieldMeasurementType;

  /// No description provided for @formFieldMeasurementValue.
  ///
  /// In en, this message translates to:
  /// **'Value ({unit})'**
  String formFieldMeasurementValue(Object unit);

  /// No description provided for @validatorPleaseEnterValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get validatorPleaseEnterValue;

  /// No description provided for @measurementWeight.
  ///
  /// In en, this message translates to:
  /// **'Body Weight'**
  String get measurementWeight;

  /// No description provided for @measurementFatPercent.
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get measurementFatPercent;

  /// No description provided for @measurementNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get measurementNeck;

  /// No description provided for @measurementShoulder.
  ///
  /// In en, this message translates to:
  /// **'Shoulder'**
  String get measurementShoulder;

  /// No description provided for @measurementChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get measurementChest;

  /// No description provided for @measurementLeftBicep.
  ///
  /// In en, this message translates to:
  /// **'Left Bicep'**
  String get measurementLeftBicep;

  /// No description provided for @measurementRightBicep.
  ///
  /// In en, this message translates to:
  /// **'Right Bicep'**
  String get measurementRightBicep;

  /// No description provided for @measurementLeftForearm.
  ///
  /// In en, this message translates to:
  /// **'Left Forearm'**
  String get measurementLeftForearm;

  /// No description provided for @measurementRightForearm.
  ///
  /// In en, this message translates to:
  /// **'Right Forearm'**
  String get measurementRightForearm;

  /// No description provided for @measurementAbdomen.
  ///
  /// In en, this message translates to:
  /// **'Abdomen'**
  String get measurementAbdomen;

  /// No description provided for @measurementWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get measurementWaist;

  /// No description provided for @measurementHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get measurementHips;

  /// No description provided for @measurementLeftThigh.
  ///
  /// In en, this message translates to:
  /// **'Left Thigh'**
  String get measurementLeftThigh;

  /// No description provided for @measurementRightThigh.
  ///
  /// In en, this message translates to:
  /// **'Right Thigh'**
  String get measurementRightThigh;

  /// No description provided for @measurementLeftCalf.
  ///
  /// In en, this message translates to:
  /// **'Left Calf'**
  String get measurementLeftCalf;

  /// No description provided for @measurementRightCalf.
  ///
  /// In en, this message translates to:
  /// **'Right Calf'**
  String get measurementRightCalf;

  /// No description provided for @drawerMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Hypertrack Menu'**
  String get drawerMenuTitle;

  /// No description provided for @drawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// No description provided for @drawerFoodExplorer.
  ///
  /// In en, this message translates to:
  /// **'Food Explorer'**
  String get drawerFoodExplorer;

  /// No description provided for @drawerDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get drawerDataManagement;

  /// No description provided for @drawerMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get drawerMeasurements;

  /// No description provided for @dataManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataManagementTitle;

  /// No description provided for @exportCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportCardTitle;

  /// No description provided for @exportCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Saves all your journal entries, favorites, and custom foods into a single backup file.'**
  String get exportCardDescription;

  /// No description provided for @exportCardButton.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get exportCardButton;

  /// No description provided for @importCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importCardTitle;

  /// No description provided for @importCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Restores your data from a previously created backup file. WARNING: All data currently stored in the app will be overwritten!'**
  String get importCardDescription;

  /// No description provided for @importCardButton.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get importCardButton;

  /// No description provided for @recommendationDefault.
  ///
  /// In en, this message translates to:
  /// **'Track your first meal!'**
  String get recommendationDefault;

  /// No description provided for @recommendationOverTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: +{difference} kcal over target'**
  String recommendationOverTarget(Object count, Object difference);

  /// No description provided for @recommendationUnderTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: {difference} kcal under target'**
  String recommendationUnderTarget(Object count, Object difference);

  /// No description provided for @recommendationOnTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: Target achieved ✅'**
  String recommendationOnTarget(Object count);

  /// No description provided for @recommendationFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Great, your first entry is logged!'**
  String get recommendationFirstEntry;

  /// No description provided for @dialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Required'**
  String get dialogConfirmTitle;

  /// No description provided for @dialogConfirmImportContent.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to restore data from this backup?\n\nWARNING: All your current entries, favorites, and custom foods will be permanently deleted and replaced.'**
  String get dialogConfirmImportContent;

  /// No description provided for @dialogButtonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogButtonCancel;

  /// No description provided for @dialogButtonOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Yes, overwrite all'**
  String get dialogButtonOverwrite;

  /// No description provided for @snackbarNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected.'**
  String get snackbarNoFileSelected;

  /// No description provided for @snackbarImportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Import successful!'**
  String get snackbarImportSuccessTitle;

  /// No description provided for @snackbarImportSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored. It is recommended to restart the app for a correct display.'**
  String get snackbarImportSuccessContent;

  /// No description provided for @snackbarButtonOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get snackbarButtonOK;

  /// No description provided for @snackbarImportError.
  ///
  /// In en, this message translates to:
  /// **'Error while importing data.'**
  String get snackbarImportError;

  /// No description provided for @snackbarExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup file has been passed to the system. Please choose a location to save.'**
  String get snackbarExportSuccess;

  /// No description provided for @snackbarExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export canceled or failed.'**
  String get snackbarExportFailed;

  /// No description provided for @profileUserHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileUserHeight;

  /// No description provided for @workoutRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get workoutRoutinesTitle;

  /// No description provided for @workoutHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get workoutHistoryTitle;

  /// No description provided for @workoutHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get workoutHistoryButton;

  /// No description provided for @emptyRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Routines Found'**
  String get emptyRoutinesTitle;

  /// No description provided for @emptyRoutinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first routine or start a blank workout.'**
  String get emptyRoutinesSubtitle;

  /// No description provided for @createFirstRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'Create First Routine'**
  String get createFirstRoutineButton;

  /// No description provided for @startEmptyWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Free Workout'**
  String get startEmptyWorkoutButton;

  /// No description provided for @editRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit, or start the workout.'**
  String get editRoutineSubtitle;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @addRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get addRoutineButton;

  /// No description provided for @freeWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Workout'**
  String get freeWorkoutTitle;

  /// No description provided for @finishWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishWorkoutButton;

  /// No description provided for @addSetButton.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSetButton;

  /// No description provided for @addExerciseToWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise to Workout'**
  String get addExerciseToWorkoutButton;

  /// No description provided for @lastTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Time'**
  String get lastTimeLabel;

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// No description provided for @kgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get kgLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @cardioDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get cardioDistanceLabel;

  /// No description provided for @cardioTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time (min)'**
  String get cardioTimeLabel;

  /// No description provided for @cardioIntensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Intens.'**
  String get cardioIntensityLabel;

  /// No description provided for @cardioIntensityShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Int.'**
  String get cardioIntensityShortLabel;

  /// No description provided for @restTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restTimerLabel;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No completed workouts yet.'**
  String get emptyHistory;

  /// No description provided for @workoutDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Details'**
  String get workoutDetailsTitle;

  /// No description provided for @workoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found.'**
  String get workoutNotFound;

  /// No description provided for @totalVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolumeLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @hevyImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Hevy Import'**
  String get hevyImportTitle;

  /// No description provided for @hevyImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Import your entire training history from a Hevy CSV export file.'**
  String get hevyImportDescription;

  /// No description provided for @hevyImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import Hevy Data'**
  String get hevyImportButton;

  /// No description provided for @hevyImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} workouts!'**
  String hevyImportSuccess(Object count);

  /// No description provided for @hevyImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check the file.'**
  String get hevyImportFailed;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @addMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get addMeasurement;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filter7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get filter7Days;

  /// No description provided for @filter30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get filter30Days;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Show more details'**
  String get showMoreDetails;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this entry?'**
  String get deleteConfirmContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @tabBaseFoods.
  ///
  /// In en, this message translates to:
  /// **'Base Foods'**
  String get tabBaseFoods;

  /// No description provided for @baseFoodsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'This section will soon be filled with a curated list of base foods like fruits, vegetables, and more.'**
  String get baseFoodsEmptyState;

  /// No description provided for @noBrand.
  ///
  /// In en, this message translates to:
  /// **'No Brand'**
  String get noBrand;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @backupFileSubject.
  ///
  /// In en, this message translates to:
  /// **'Hypertrack App Backup - {timestamp}'**
  String backupFileSubject(String timestamp);

  /// No description provided for @foodItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{brand} - {calories} kcal / 100g'**
  String foodItemSubtitle(String brand, int calories);

  /// No description provided for @foodListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{grams}g - {time}'**
  String foodListSubtitle(int grams, String time);

  /// No description provided for @foodListTrailingKcal.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String foodListTrailingKcal(int calories);

  /// No description provided for @waterListTrailingMl.
  ///
  /// In en, this message translates to:
  /// **'{milliliters} ml'**
  String waterListTrailingMl(int milliliters);

  /// No description provided for @exerciseCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Catalog'**
  String get exerciseCatalogTitle;

  /// No description provided for @filterByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Filter by muscle group'**
  String get filterByMuscle;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found.'**
  String get noExercisesFound;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @repsLabelShort.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsLabelShort;

  /// No description provided for @titleNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get titleNewRoutine;

  /// No description provided for @titleEditRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get titleEditRoutine;

  /// No description provided for @validatorPleaseEnterRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the routine.'**
  String get validatorPleaseEnterRoutineName;

  /// No description provided for @snackbarRoutineCreated.
  ///
  /// In en, this message translates to:
  /// **'Routine created. Now add some exercises.'**
  String get snackbarRoutineCreated;

  /// No description provided for @snackbarRoutineSaved.
  ///
  /// In en, this message translates to:
  /// **'Routine saved.'**
  String get snackbarRoutineSaved;

  /// No description provided for @formFieldRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Name of the routine'**
  String get formFieldRoutineName;

  /// No description provided for @emptyStateAddFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'Add your first exercise.'**
  String get emptyStateAddFirstExercise;

  /// No description provided for @setCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 set}other{{count} sets}}'**
  String setCount(int count);

  /// No description provided for @fabAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get fabAddExercise;

  /// No description provided for @kgLabelShort.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgLabelShort;

  /// No description provided for @drawerExerciseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Exercise Catalog'**
  String get drawerExerciseCatalog;

  /// No description provided for @lastWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Last Workout'**
  String get lastWorkoutTitle;

  /// No description provided for @repeatButton.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatButton;

  /// No description provided for @weightHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight History'**
  String get weightHistoryTitle;

  /// No description provided for @hideSummary.
  ///
  /// In en, this message translates to:
  /// **'Hide Summary'**
  String get hideSummary;

  /// No description provided for @showSummary.
  ///
  /// In en, this message translates to:
  /// **'Show Summary'**
  String get showSummary;

  /// No description provided for @exerciseDataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Exercise data from wger'**
  String get exerciseDataAttribution;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @deleteRoutineConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete the routine \'{routineName}\'?'**
  String deleteRoutineConfirmContent(String routineName);

  /// No description provided for @editPauseTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Pause Duration'**
  String get editPauseTimeTitle;

  /// No description provided for @pauseInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Pause in seconds'**
  String get pauseInSeconds;

  /// No description provided for @editPauseTime.
  ///
  /// In en, this message translates to:
  /// **'Edit Pause'**
  String get editPauseTime;

  /// No description provided for @pauseDuration.
  ///
  /// In en, this message translates to:
  /// **'{seconds} second pause'**
  String pauseDuration(int seconds);

  /// No description provided for @maxPauseDuration.
  ///
  /// In en, this message translates to:
  /// **'Pauses up to {seconds}s'**
  String maxPauseDuration(int seconds);

  /// No description provided for @deleteWorkoutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this workout log?'**
  String get deleteWorkoutConfirmContent;

  /// No description provided for @removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise'**
  String get removeExercise;

  /// No description provided for @deleteExerciseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise?'**
  String get deleteExerciseConfirmTitle;

  /// No description provided for @deleteExerciseConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \'{exerciseName}\' from this routine?'**
  String deleteExerciseConfirmContent(String exerciseName);

  /// No description provided for @doneButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButtonLabel;

  /// No description provided for @setRestTimeButton.
  ///
  /// In en, this message translates to:
  /// **'Set rest time'**
  String get setRestTimeButton;

  /// No description provided for @deleteExerciseButton.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get deleteExerciseButton;

  /// No description provided for @restOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause is over'**
  String get restOverLabel;

  /// No description provided for @workoutRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout is active …'**
  String get workoutRunningLabel;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @discardButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// No description provided for @workoutStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Training (7 days)'**
  String get workoutStatsTitle;

  /// No description provided for @workoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsLabel;

  /// Label for workout duration summary
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// Label for number of sets summary
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// Label for muscle split bar chart
  ///
  /// In en, this message translates to:
  /// **'Muscle Split'**
  String get muscleSplitLabel;

  /// No description provided for @snackbar_could_not_open_open_link.
  ///
  /// In en, this message translates to:
  /// **'Konnte Link nicht öffnen'**
  String get snackbar_could_not_open_open_link;

  /// No description provided for @chart_no_data_for_period.
  ///
  /// In en, this message translates to:
  /// **'No chart data for this period'**
  String get chart_no_data_for_period;

  /// No description provided for @amount_in_milliliters.
  ///
  /// In en, this message translates to:
  /// **'Menge in Millilitern'**
  String get amount_in_milliliters;

  /// No description provided for @amount_in_grams.
  ///
  /// In en, this message translates to:
  /// **'Menge in Gramm'**
  String get amount_in_grams;

  /// No description provided for @meal_label.
  ///
  /// In en, this message translates to:
  /// **'Mahlzeit'**
  String get meal_label;

  /// No description provided for @add_to_water_intake.
  ///
  /// In en, this message translates to:
  /// **'Zur Trinkmenge hinzufügen'**
  String get add_to_water_intake;

  /// No description provided for @create_exercise_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Eigene Übung erstellen'**
  String get create_exercise_screen_title;

  /// No description provided for @exercise_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name der Übung'**
  String get exercise_name_label;

  /// No description provided for @category_label.
  ///
  /// In en, this message translates to:
  /// **'Kategorie'**
  String get category_label;

  /// No description provided for @description_optional_label.
  ///
  /// In en, this message translates to:
  /// **'Beschreibung (optional)'**
  String get description_optional_label;

  /// No description provided for @primary_muscles_label.
  ///
  /// In en, this message translates to:
  /// **'Primäre Muskeln'**
  String get primary_muscles_label;

  /// No description provided for @primary_muscles_hint.
  ///
  /// In en, this message translates to:
  /// **'z.B. Brust, Trizeps'**
  String get primary_muscles_hint;

  /// No description provided for @secondary_muscles_label.
  ///
  /// In en, this message translates to:
  /// **'Sekundäre Muskeln (optional)'**
  String get secondary_muscles_label;

  /// No description provided for @secondary_muscles_hint.
  ///
  /// In en, this message translates to:
  /// **'z.B. Schultern'**
  String get secondary_muscles_hint;

  /// No description provided for @set_type_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get set_type_normal;

  /// No description provided for @set_type_warmup.
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get set_type_warmup;

  /// No description provided for @set_type_failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get set_type_failure;

  /// No description provided for @set_type_dropset.
  ///
  /// In en, this message translates to:
  /// **'Dropset'**
  String get set_type_dropset;

  /// No description provided for @set_reps_hint.
  ///
  /// In en, this message translates to:
  /// **'8-12'**
  String get set_reps_hint;

  /// No description provided for @data_export_button.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get data_export_button;

  /// No description provided for @data_import_button.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get data_import_button;

  /// No description provided for @snackbar_button_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get snackbar_button_ok;

  /// No description provided for @measurement_session_detail_view.
  ///
  /// In en, this message translates to:
  /// **'Detailview of measurement session'**
  String get measurement_session_detail_view;

  /// No description provided for @unit_grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unit_grams;

  /// No description provided for @unit_kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unit_kcal;

  /// No description provided for @delete_profile_picture_button.
  ///
  /// In en, this message translates to:
  /// **'Delete profile picture'**
  String get delete_profile_picture_button;

  /// No description provided for @attribution_title.
  ///
  /// In en, this message translates to:
  /// **'Attribution'**
  String get attribution_title;

  /// No description provided for @add_liquid_title.
  ///
  /// In en, this message translates to:
  /// **'Add fluid'**
  String get add_liquid_title;

  /// No description provided for @add_button.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add_button;

  /// No description provided for @discard_button.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard_button;

  /// No description provided for @continue_workout_button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_workout_button;

  /// No description provided for @soon_available_snackbar.
  ///
  /// In en, this message translates to:
  /// **'This screen will be available soon'**
  String get soon_available_snackbar;

  /// No description provided for @start_button.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_button;

  /// No description provided for @today_overview_text.
  ///
  /// In en, this message translates to:
  /// **'TODAY IN FOCUS'**
  String get today_overview_text;

  /// No description provided for @quick_add_text.
  ///
  /// In en, this message translates to:
  /// **'QUICK ADD'**
  String get quick_add_text;

  /// No description provided for @scann_barcode_capslock.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scann_barcode_capslock;

  /// No description provided for @protocol_today_capslock.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PROTOCOL'**
  String get protocol_today_capslock;

  /// No description provided for @my_plans_capslock.
  ///
  /// In en, this message translates to:
  /// **'MY PLANS'**
  String get my_plans_capslock;

  /// No description provided for @overview_capslock.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overview_capslock;

  /// No description provided for @manage_all_plans.
  ///
  /// In en, this message translates to:
  /// **'Manage all plans'**
  String get manage_all_plans;

  /// No description provided for @free_training.
  ///
  /// In en, this message translates to:
  /// **'free training'**
  String get free_training;

  /// No description provided for @my_consistency.
  ///
  /// In en, this message translates to:
  /// **'MY CONSISTENCY'**
  String get my_consistency;

  /// No description provided for @calendar_currently_not_available.
  ///
  /// In en, this message translates to:
  /// **'The calendar view will be available soon.'**
  String get calendar_currently_not_available;

  /// No description provided for @in_depth_analysis.
  ///
  /// In en, this message translates to:
  /// **'IN-DEPTH ANALYSIS'**
  String get in_depth_analysis;

  /// No description provided for @body_measurements.
  ///
  /// In en, this message translates to:
  /// **'Body measurements'**
  String get body_measurements;

  /// No description provided for @measurements_description.
  ///
  /// In en, this message translates to:
  /// **'Analyze weight, body fat percentage and circumference.'**
  String get measurements_description;

  /// No description provided for @nutrition_description.
  ///
  /// In en, this message translates to:
  /// **'Evaluate macros, calories and trends.'**
  String get nutrition_description;

  /// No description provided for @training_analysis.
  ///
  /// In en, this message translates to:
  /// **'Training analysis'**
  String get training_analysis;

  /// No description provided for @training_analysis_description.
  ///
  /// In en, this message translates to:
  /// **'Track volume, strength and progression.'**
  String get training_analysis_description;

  /// No description provided for @load_dots.
  ///
  /// In en, this message translates to:
  /// **'loading...'**
  String get load_dots;

  /// No description provided for @profile_capslock.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile_capslock;

  /// No description provided for @settings_capslock.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings_capslock;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @my_goals.
  ///
  /// In en, this message translates to:
  /// **'My goals'**
  String get my_goals;

  /// No description provided for @my_goals_description.
  ///
  /// In en, this message translates to:
  /// **'Adjust calories, macros and water.'**
  String get my_goals_description;

  /// No description provided for @backup_and_import.
  ///
  /// In en, this message translates to:
  /// **'Data backup & import'**
  String get backup_and_import;

  /// No description provided for @backup_and_import_description.
  ///
  /// In en, this message translates to:
  /// **'Create backups, restore, and import data.'**
  String get backup_and_import_description;

  /// No description provided for @about_and_legal_capslock.
  ///
  /// In en, this message translates to:
  /// **'ABOUT & LEGAL'**
  String get about_and_legal_capslock;

  /// No description provided for @attribution_and_license.
  ///
  /// In en, this message translates to:
  /// **'Attribution & Licenses'**
  String get attribution_and_license;

  /// No description provided for @data_from_off_and_wger.
  ///
  /// In en, this message translates to:
  /// **'Data from Open Food Facts and wger.'**
  String get data_from_off_and_wger;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get app_version;

  /// No description provided for @all_measurements.
  ///
  /// In en, this message translates to:
  /// **'ALL MEASUREMENTS'**
  String get all_measurements;

  /// No description provided for @date_and_time_of_measurement.
  ///
  /// In en, this message translates to:
  /// **'Date & time of measurement'**
  String get date_and_time_of_measurement;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hypertrack'**
  String get onbWelcomeTitle;

  /// Onboarding slide 1 description
  ///
  /// In en, this message translates to:
  /// **'Let’s start by setting personal goals to guide training and nutrition.'**
  String get onbWelcomeBody;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Track everything'**
  String get onbTrackTitle;

  /// Onboarding slide 2 description
  ///
  /// In en, this message translates to:
  /// **'Log nutrition, workouts, and measurements — all in one place.'**
  String get onbTrackBody;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Offline-first & privacy'**
  String get onbPrivacyTitle;

  /// Onboarding slide 3 description
  ///
  /// In en, this message translates to:
  /// **'Your data stays on the device. No cloud accounts, no background sync.'**
  String get onbPrivacyBody;

  /// Onboarding final slide title
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get onbFinishTitle;

  /// Onboarding final slide description
  ///
  /// In en, this message translates to:
  /// **'You’re ready to explore the app. You can adjust settings anytime.'**
  String get onbFinishBody;

  /// Final button label to finish onboarding
  ///
  /// In en, this message translates to:
  /// **'Let’s go!'**
  String get onbFinishCta;

  /// Settings item to reopen onboarding
  ///
  /// In en, this message translates to:
  /// **'Show tutorial again'**
  String get onbShowTutorialAgain;

  /// Optional CTA linking to Goals screen from onboarding
  ///
  /// In en, this message translates to:
  /// **'Set goals'**
  String get onbSetGoalsCta;

  /// Onboarding header title
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get onbHeaderTitle;

  /// Skip button label in onboarding header
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbHeaderSkip;

  /// Back button in onboarding footer
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// Next button in onboarding footer
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// Guide banner title in onboarding
  ///
  /// In en, this message translates to:
  /// **'How this tutorial works'**
  String get onbGuideTitle;

  /// Guide banner description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Swipe between slides or use Next. Tap the buttons on each slide to try features. You can finish anytime with Skip.'**
  String get onbGuideBody;

  /// CTA to open nutrition tracking from onboarding
  ///
  /// In en, this message translates to:
  /// **'Open nutrition'**
  String get onbCtaOpenNutrition;

  /// CTA to learn more about privacy/offline
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get onbCtaLearnMore;

  /// Badge label shown after completing CTA
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onbBadgeDone;

  /// Hint text on goals slide
  ///
  /// In en, this message translates to:
  /// **'Tip: adjust targets first'**
  String get onbTipSetGoals;

  /// Hint text on nutrition slide
  ///
  /// In en, this message translates to:
  /// **'Tip: add one entry today'**
  String get onbTipAddEntry;

  /// Hint on privacy slide about local data control
  ///
  /// In en, this message translates to:
  /// **'You control all data locally'**
  String get onbTipLocalControl;

  /// Onboarding slide 2 replacement body: step-by-step nutrition logging instructions
  ///
  /// In en, this message translates to:
  /// **'How to log nutrition:\n• Open the Food tab.\n• Tap the + button.\n• Search products or scan a barcode.\n• Adjust portion and time.\n• Save to your diary.'**
  String get onbTrackHowBody;

  /// Onboarding slide title for measurements
  ///
  /// In en, this message translates to:
  /// **'Track measurements'**
  String get onbMeasureTitle;

  /// Step-by-step instructions for adding measurements
  ///
  /// In en, this message translates to:
  /// **'How to add measurements:\n• Open the Stats tab.\n• Tap the + button.\n• Choose a metric (e.g., weight, waist, body fat).\n• Enter value and time.\n• Save to your history.'**
  String get onbMeasureBody;

  /// Hint for measurements slide
  ///
  /// In en, this message translates to:
  /// **'Tip: add today’s weight to start your graph'**
  String get onbTipMeasureToday;

  /// Onboarding slide title for training routines
  ///
  /// In en, this message translates to:
  /// **'Train with routines'**
  String get onbTrainTitle;

  /// Instructions for creating a routine and starting a workout
  ///
  /// In en, this message translates to:
  /// **'Create a routine and start a workout:\n• Open the Train tab.\n• Tap Create routine to add exercises and sets.\n• Save the routine.\n• Tap Start to begin, or use “Start empty workout”.'**
  String get onbTrainBody;

  /// Hint for training slide
  ///
  /// In en, this message translates to:
  /// **'Tip: start an empty workout to log a quick session'**
  String get onbTipStartWorkout;

  /// No description provided for @unitsSection.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsSection;

  /// No description provided for @weightUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight units'**
  String get weightUnit;

  /// No description provided for @lengthUnit.
  ///
  /// In en, this message translates to:
  /// **'unit of length'**
  String get lengthUnit;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No Favorites'**
  String get noFavorites;

  /// No description provided for @nothingTrackedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing tracked yet'**
  String get nothingTrackedYet;

  /// No description provided for @snackbarBarcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product found for barcode \"{barcode}\".'**
  String snackbarBarcodeNotFound(String barcode);

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chest, Back, Legs...'**
  String get categoryHint;

  /// No description provided for @validatorPleaseEnterCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category.'**
  String get validatorPleaseEnterCategory;

  /// No description provided for @dialogEnterPasswordImport.
  ///
  /// In en, this message translates to:
  /// **'Enter password to import backup'**
  String get dialogEnterPasswordImport;

  /// No description provided for @dataManagementBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Hypertrack Data Backup'**
  String get dataManagementBackupTitle;

  /// No description provided for @dataManagementBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Back up or restore all your app data. Ideal for changing devices.'**
  String get dataManagementBackupDescription;

  /// No description provided for @exportEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Export Encrypted'**
  String get exportEncrypted;

  /// No description provided for @dialogPasswordForExport.
  ///
  /// In en, this message translates to:
  /// **'Password for encrypted export'**
  String get dialogPasswordForExport;

  /// No description provided for @snackbarEncryptedBackupShared.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup shared.'**
  String get snackbarEncryptedBackupShared;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get exportFailed;

  /// No description provided for @csvExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Export (CSV)'**
  String get csvExportTitle;

  /// No description provided for @csvExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Export parts of your data as a CSV file for analysis in other programs.'**
  String get csvExportDescription;

  /// No description provided for @snackbarSharingNutrition.
  ///
  /// In en, this message translates to:
  /// **'Sharing nutrition diary...'**
  String get snackbarSharingNutrition;

  /// No description provided for @snackbarExportFailedNoEntries.
  ///
  /// In en, this message translates to:
  /// **'Export failed. There may be no entries yet.'**
  String get snackbarExportFailedNoEntries;

  /// No description provided for @snackbarSharingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Sharing measurements...'**
  String get snackbarSharingMeasurements;

  /// No description provided for @snackbarSharingWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Sharing workout history...'**
  String get snackbarSharingWorkouts;

  /// No description provided for @mapExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Map Exercises'**
  String get mapExercisesTitle;

  /// No description provided for @mapExercisesDescription.
  ///
  /// In en, this message translates to:
  /// **'Map unknown names from logs to wger exercises.'**
  String get mapExercisesDescription;

  /// No description provided for @mapExercisesButton.
  ///
  /// In en, this message translates to:
  /// **'Start Mapping'**
  String get mapExercisesButton;

  /// No description provided for @autoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Backups'**
  String get autoBackupTitle;

  /// No description provided for @autoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Periodically saves a backup in the folder. Current folder:'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'App-Documents/Backups (Default)'**
  String get autoBackupDefaultFolder;

  /// No description provided for @autoBackupChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get autoBackupChooseFolder;

  /// No description provided for @autoBackupCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get autoBackupCopyPath;

  /// No description provided for @autoBackupRunNow.
  ///
  /// In en, this message translates to:
  /// **'Check & Run Auto-Backup Now'**
  String get autoBackupRunNow;

  /// No description provided for @snackbarAutoBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Auto-Backup completed.'**
  String get snackbarAutoBackupSuccess;

  /// No description provided for @snackbarAutoBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-Backup failed or was canceled.'**
  String get snackbarAutoBackupFailed;

  /// No description provided for @noUnknownExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No unknown exercises found'**
  String get noUnknownExercisesFound;

  /// No description provided for @snackbarAutoBackupFolderSet.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup folder set:\n{path}'**
  String snackbarAutoBackupFolderSet(String path);

  /// No description provided for @snackbarPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get snackbarPathCopied;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @involvedMuscles.
  ///
  /// In en, this message translates to:
  /// **'Involved Muscles'**
  String get involvedMuscles;

  /// No description provided for @primaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary:'**
  String get primaryLabel;

  /// No description provided for @secondaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary:'**
  String get secondaryLabel;

  /// No description provided for @noMusclesSpecified.
  ///
  /// In en, this message translates to:
  /// **'No muscles specified.'**
  String get noMusclesSpecified;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'No selection'**
  String get noSelection;

  /// No description provided for @selectButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectButton;

  /// No description provided for @applyingChanges.
  ///
  /// In en, this message translates to:
  /// **'Applying changes...'**
  String get applyingChanges;

  /// No description provided for @applyMapping.
  ///
  /// In en, this message translates to:
  /// **'Apply Mapping'**
  String get applyMapping;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get personalData;

  /// No description provided for @personalDataCL.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DATA'**
  String get personalDataCL;

  /// No description provided for @macroDistribution.
  ///
  /// In en, this message translates to:
  /// **'Macronutrient Distribution'**
  String get macroDistribution;

  /// No description provided for @dialogFinishWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish this workout?'**
  String get dialogFinishWorkoutBody;

  /// No description provided for @attributionText.
  ///
  /// In en, this message translates to:
  /// **'This app uses data from external sources:\n\n● Exercise data and images from wger (wger.de), licensed under CC-BY-SA 4.0.\n\n● Food database from Open Food Facts (openfoodfacts.org), available under the Open Database License (ODbL).'**
  String get attributionText;

  /// No description provided for @errorRoutineNotFound.
  ///
  /// In en, this message translates to:
  /// **'Routine not found'**
  String get errorRoutineNotFound;

  /// No description provided for @workoutHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your history is empty'**
  String get workoutHistoryEmptyTitle;

  /// No description provided for @workoutSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete'**
  String get workoutSummaryTitle;

  /// No description provided for @workoutSummaryExerciseOverview.
  ///
  /// In en, this message translates to:
  /// **'Exercise Overview'**
  String get workoutSummaryExerciseOverview;

  /// No description provided for @nutritionDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get nutritionDiary;

  /// No description provided for @detailedNutrientGoals.
  ///
  /// In en, this message translates to:
  /// **'Detailed Nutrients'**
  String get detailedNutrientGoals;

  /// No description provided for @detailedNutrientGoalsCL.
  ///
  /// In en, this message translates to:
  /// **'DETAILED NUTRIENTS'**
  String get detailedNutrientGoalsCL;

  /// No description provided for @supplementTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplement Tracker'**
  String get supplementTrackerTitle;

  /// No description provided for @supplementTrackerDescription.
  ///
  /// In en, this message translates to:
  /// **'Track goals, limits, and intake.'**
  String get supplementTrackerDescription;

  /// No description provided for @createSupplementTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Supplement'**
  String get createSupplementTitle;

  /// No description provided for @supplementNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplement Name'**
  String get supplementNameLabel;

  /// No description provided for @defaultDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Dose'**
  String get defaultDoseLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal (optional)'**
  String get dailyGoalLabel;

  /// No description provided for @dailyLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit (optional)'**
  String get dailyLimitLabel;

  /// No description provided for @dailyProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgressTitle;

  /// No description provided for @todaysLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Log'**
  String get todaysLogTitle;

  /// No description provided for @logIntakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Intake'**
  String get logIntakeTitle;

  /// No description provided for @emptySupplementGoals.
  ///
  /// In en, this message translates to:
  /// **'Set goals or limits for supplements to see your progress here.'**
  String get emptySupplementGoals;

  /// No description provided for @emptySupplementLogs.
  ///
  /// In en, this message translates to:
  /// **'No intake logged for today yet.'**
  String get emptySupplementLogs;

  /// No description provided for @doseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseLabel;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Theme, units, data and more'**
  String get settingsDescription;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @caffeinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Caffeine (optional)'**
  String get caffeinePrompt;

  /// No description provided for @caffeineUnit.
  ///
  /// In en, this message translates to:
  /// **'mg per 100ml'**
  String get caffeineUnit;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @measurementWeightCapslock.
  ///
  /// In en, this message translates to:
  /// **'BODY WEIGHT'**
  String get measurementWeightCapslock;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @dayBeforeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Two days ago'**
  String get dayBeforeYesterday;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @addFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'add food'**
  String get addFoodTitle;

  /// No description provided for @nutritionExplorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Explorer'**
  String get nutritionExplorerTitle;

  /// No description provided for @myMeals.
  ///
  /// In en, this message translates to:
  /// **'My Meals'**
  String get myMeals;

  /// No description provided for @myMealsCL.
  ///
  /// In en, this message translates to:
  /// **'MY MEALS'**
  String get myMealsCL;

  /// No description provided for @supplement_caffeine.
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get supplement_caffeine;

  /// No description provided for @supplement_creatine_monohydrate.
  ///
  /// In en, this message translates to:
  /// **'Creatine Monohydrate'**
  String get supplement_creatine_monohydrate;

  /// No description provided for @manageSupplementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage supplements'**
  String get manageSupplementsTitle;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get deleted;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This operation isn\'t allowed'**
  String get operationNotAllowed;

  /// No description provided for @emptySupplements.
  ///
  /// In en, this message translates to:
  /// **'No supplements available'**
  String get emptySupplements;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Rückgängig'**
  String get undo;

  /// No description provided for @deleteSupplementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this supplement? All historical data will be lost.\n\nTip: You can simply untrack it by editing the supplement instead.'**
  String get deleteSupplementConfirm;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @unitNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Unit not supported.'**
  String get unitNotSupported;

  /// No description provided for @caffeineUnitLocked.
  ///
  /// In en, this message translates to:
  /// **'For caffeine the unit is fixed: mg.'**
  String get caffeineUnitLocked;

  /// No description provided for @caffeineMustBeMg.
  ///
  /// In en, this message translates to:
  /// **'Caffeine must be recorded in mg.'**
  String get caffeineMustBeMg;

  /// No description provided for @tabCatalogSearch.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get tabCatalogSearch;

  /// No description provided for @tabMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get tabMeals;

  /// No description provided for @emptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get emptyCategory;

  /// No description provided for @searchSectionBase.
  ///
  /// In en, this message translates to:
  /// **'Base foods'**
  String get searchSectionBase;

  /// No description provided for @searchSectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other results'**
  String get searchSectionOther;

  /// No description provided for @mealsComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Meals (coming soon)'**
  String get mealsComingSoonTitle;

  /// No description provided for @mealsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Soon you will be able to create your own meals from multiple foods.'**
  String get mealsComingSoonBody;

  /// No description provided for @mealsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No meals yet'**
  String get mealsEmptyTitle;

  /// No description provided for @mealsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create meals to quickly log multiple foods at once.'**
  String get mealsEmptyBody;

  /// No description provided for @mealsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create meal'**
  String get mealsCreate;

  /// No description provided for @mealsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get mealsEdit;

  /// No description provided for @mealsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get mealsDelete;

  /// No description provided for @mealsAddToDiary.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get mealsAddToDiary;

  /// No description provided for @mealNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get mealNameLabel;

  /// No description provided for @mealNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get mealNotesLabel;

  /// No description provided for @mealIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get mealIngredientsTitle;

  /// No description provided for @mealAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get mealAddIngredient;

  /// No description provided for @mealIngredientAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get mealIngredientAmountLabel;

  /// No description provided for @mealDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get mealDeleteConfirmTitle;

  /// No description provided for @mealDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the meal \'{name}\'? All its ingredients will also be removed.'**
  String mealDeleteConfirmBody(Object name);

  /// No description provided for @mealAddedToDiary.
  ///
  /// In en, this message translates to:
  /// **'Meal \'{name}\' has been added to your diary.'**
  String mealAddedToDiary(Object name);

  /// No description provided for @mealSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal saved.'**
  String get mealSaved;

  /// No description provided for @mealDeleted.
  ///
  /// In en, this message translates to:
  /// **'Meal deleted.'**
  String get mealDeleted;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @addMealToDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to diary'**
  String get addMealToDiaryTitle;

  /// No description provided for @mealTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealTypeLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @mealAddedToDiarySuccess.
  ///
  /// In en, this message translates to:
  /// **'Meal added to diary'**
  String get mealAddedToDiarySuccess;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @mealsViewTitle.
  ///
  /// In en, this message translates to:
  /// **'mealsViewTitle'**
  String get mealsViewTitle;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @ingredientsCapsLock.
  ///
  /// In en, this message translates to:
  /// **'INGREDIENTS'**
  String get ingredientsCapsLock;

  /// No description provided for @nutritionSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION FACTS'**
  String get nutritionSectionLabel;

  /// No description provided for @nutritionCalculatedForCurrentAmounts.
  ///
  /// In en, this message translates to:
  /// **'for current quantities'**
  String get nutritionCalculatedForCurrentAmounts;

  /// No description provided for @startCapsLock.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startCapsLock;

  /// No description provided for @nutritionHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover insights, track meals, and plan your nutrition here soon.'**
  String get nutritionHubSubtitle;

  /// No description provided for @nutritionHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionHubTitle;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'nutrition'**
  String get nutrition;

  /// No description provided for @changeSetTypTitle.
  ///
  /// In en, this message translates to:
  /// **'Change set type'**
  String get changeSetTypTitle;

  /// No description provided for @settingsVisualStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Style'**
  String get settingsVisualStyleTitle;

  /// No description provided for @settingsVisualStyleStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard (Glass)'**
  String get settingsVisualStyleStandard;

  /// No description provided for @settingsVisualStyleLiquid.
  ///
  /// In en, this message translates to:
  /// **'Fluid (Liquid Glass)'**
  String get settingsVisualStyleLiquid;

  /// No description provided for @settingsVisualStyleLiquidDesc.
  ///
  /// In en, this message translates to:
  /// **'Rounded, floating UI elements'**
  String get settingsVisualStyleLiquidDesc;

  /// No description provided for @settingsMaterialColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Material colors'**
  String get settingsMaterialColorsTitle;

  /// No description provided for @settingsMaterialColorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Android dynamic colors (Material You) instead of the Hypertrack brand accent'**
  String get settingsMaterialColorsSubtitle;

  /// No description provided for @searchBaseFoodHint.
  ///
  /// In en, this message translates to:
  /// **'Search base foods'**
  String get searchBaseFoodHint;

  /// No description provided for @searchNoHits.
  ///
  /// In en, this message translates to:
  /// **'No hits.'**
  String get searchNoHits;

  /// No description provided for @onbSubtitleWelcome.
  ///
  /// In en, this message translates to:
  /// **'Your central tool for fitness, nutrition & progress.'**
  String get onbSubtitleWelcome;

  /// No description provided for @onbBodyWelcome.
  ///
  /// In en, this message translates to:
  /// **'We help you set and track your goals. Efficiently log workouts, nutrition, supplements, and body measurements.'**
  String get onbBodyWelcome;

  /// No description provided for @onbBodyNutritionVisual.
  ///
  /// In en, this message translates to:
  /// **'Log meals with just a few clicks. Keep an eye on calories, macros, and water to effortlessly track your goal.'**
  String get onbBodyNutritionVisual;

  /// No description provided for @onbBodyMeasurementsVisual.
  ///
  /// In en, this message translates to:
  /// **'Visualize your progress. The weight and circumference chart makes your success visible and keeps you motivated.'**
  String get onbBodyMeasurementsVisual;

  /// No description provided for @onbBodyWorkoutVisual.
  ///
  /// In en, this message translates to:
  /// **'Create routines and start your training in seconds. Log sets, weights, and rests for maximum progression.'**
  String get onbBodyWorkoutVisual;

  /// No description provided for @onbTitleAppLayout.
  ///
  /// In en, this message translates to:
  /// **'Navigation & Quick-Add'**
  String get onbTitleAppLayout;

  /// No description provided for @onbBodyAppLayout.
  ///
  /// In en, this message translates to:
  /// **'The bottom bar allows quick switching between areas. Use the large [+] button to log everything instantly.'**
  String get onbBodyAppLayout;

  /// No description provided for @dataHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Hub'**
  String get dataHubTitle;

  /// No description provided for @resumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButton;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hypertrack'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your profile to get the best results.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get onboardingNameError;

  /// No description provided for @onboardingDobTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get onboardingDobTitle;

  /// No description provided for @onboardingDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get onboardingDobLabel;

  /// No description provided for @onboardingDobError.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get onboardingDobError;

  /// No description provided for @onboardingWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get onboardingWeightTitle;

  /// No description provided for @onboardingWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get onboardingWeightLabel;

  /// No description provided for @onboardingWeightError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get onboardingWeightError;

  /// No description provided for @onboardingGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Nutrition Goals'**
  String get onboardingGoalsTitle;

  /// No description provided for @onboardingGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change these later in settings.'**
  String get onboardingGoalsSubtitle;

  /// No description provided for @onboardingGoalCalories.
  ///
  /// In en, this message translates to:
  /// **'Daily Calories (kcal)'**
  String get onboardingGoalCalories;

  /// No description provided for @onboardingGoalProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get onboardingGoalProtein;

  /// No description provided for @onboardingGoalCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get onboardingGoalCarbs;

  /// No description provided for @onboardingGoalFat.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get onboardingGoalFat;

  /// No description provided for @onboardingGoalWater.
  ///
  /// In en, this message translates to:
  /// **'Water (ml)'**
  String get onboardingGoalWater;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Start Tracking'**
  String get onboardingFinish;

  /// No description provided for @onboardingHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get onboardingHeightLabel;

  /// No description provided for @onboardingGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get onboardingGenderLabel;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderDiverse.
  ///
  /// In en, this message translates to:
  /// **'Diverse'**
  String get genderDiverse;

  /// No description provided for @aiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Capture'**
  String get aiSettingsTitle;

  /// No description provided for @aiSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure AI-powered meal recognition.'**
  String get aiSettingsDescription;

  /// No description provided for @aiProviderSection.
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get aiProviderSection;

  /// No description provided for @aiProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiProviderLabel;

  /// No description provided for @aiApiKeySection.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiApiKeySection;

  /// No description provided for @aiApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiApiKeyLabel;

  /// No description provided for @aiApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key here'**
  String get aiApiKeyHint;

  /// No description provided for @aiSaveKey.
  ///
  /// In en, this message translates to:
  /// **'Save Key'**
  String get aiSaveKey;

  /// No description provided for @aiTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get aiTestConnection;

  /// No description provided for @aiTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get aiTestSuccess;

  /// No description provided for @aiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved securely.'**
  String get aiKeySaved;

  /// No description provided for @aiPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aiPrivacySection;

  /// No description provided for @aiPrivacyDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Your images and text are sent to the selected AI provider only when you tap Analyze. Data is never stored on external servers beyond processing your request. Your API key is stored encrypted on this device only.'**
  String get aiPrivacyDisclosure;

  /// No description provided for @aiMealCapture.
  ///
  /// In en, this message translates to:
  /// **'AI Meal'**
  String get aiMealCapture;

  /// No description provided for @aiCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Capture'**
  String get aiCaptureTitle;

  /// No description provided for @aiCaptureTabPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get aiCaptureTabPhoto;

  /// No description provided for @aiCaptureTabVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get aiCaptureTabVoice;

  /// No description provided for @aiCaptureTabText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get aiCaptureTabText;

  /// No description provided for @aiCapturePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Take or select up to 4 photos of your meal.'**
  String get aiCapturePhotoHint;

  /// No description provided for @aiCaptureVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone and describe your meal.'**
  String get aiCaptureVoiceHint;

  /// No description provided for @aiCaptureTextHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your meal (e.g. \"Grilled chicken with rice and salad\")...'**
  String get aiCaptureTextHint;

  /// No description provided for @aiAnalyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get aiAnalyzeButton;

  /// No description provided for @aiAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your meal...'**
  String get aiAnalyzing;

  /// No description provided for @aiReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Suggestions'**
  String get aiReviewTitle;

  /// No description provided for @aiReviewFoundItems.
  ///
  /// In en, this message translates to:
  /// **'AI found {count} items'**
  String aiReviewFoundItems(int count);

  /// No description provided for @aiReviewNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match — tap to search'**
  String get aiReviewNoMatch;

  /// No description provided for @aiReviewConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get aiReviewConfidence;

  /// No description provided for @aiReviewAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item manually'**
  String get aiReviewAddItem;

  /// No description provided for @aiReviewSaveToDiary.
  ///
  /// In en, this message translates to:
  /// **'Save to Diary'**
  String get aiReviewSaveToDiary;

  /// No description provided for @aiReviewFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what the AI got wrong...'**
  String get aiReviewFeedbackHint;

  /// No description provided for @aiReviewRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry with Feedback'**
  String get aiReviewRetryButton;

  /// No description provided for @aiReviewFeedbackSection.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get aiReviewFeedbackSection;

  /// No description provided for @aiErrorNoKey.
  ///
  /// In en, this message translates to:
  /// **'No API key configured. Please set one in Settings → AI Meal Capture.'**
  String get aiErrorNoKey;

  /// No description provided for @aiErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get aiErrorNetwork;

  /// No description provided for @aiErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your API key.'**
  String get aiErrorAuth;

  /// No description provided for @aiErrorParse.
  ///
  /// In en, this message translates to:
  /// **'Could not understand the AI response. Please try again.'**
  String get aiErrorParse;

  /// No description provided for @aiErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get aiErrorRateLimit;

  /// No description provided for @aiEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable AI Features'**
  String get aiEnableTitle;

  /// No description provided for @aiEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allows the use of AI for meal recognition. Disabling this hides all AI buttons in the app.'**
  String get aiEnableSubtitle;

  /// No description provided for @aiRecommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Coach'**
  String get aiRecommendationTitle;

  /// No description provided for @aiRecommendDietary.
  ///
  /// In en, this message translates to:
  /// **'Dietary'**
  String get aiRecommendDietary;

  /// No description provided for @aiRecommendSituation.
  ///
  /// In en, this message translates to:
  /// **'Situation'**
  String get aiRecommendSituation;

  /// No description provided for @aiRecommendVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get aiRecommendVegan;

  /// No description provided for @aiRecommendVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get aiRecommendVegetarian;

  /// No description provided for @aiRecommendPescetarian.
  ///
  /// In en, this message translates to:
  /// **'Pescetarian'**
  String get aiRecommendPescetarian;

  /// No description provided for @aiRecommendOnTheGo.
  ///
  /// In en, this message translates to:
  /// **'On the go (No utensils)'**
  String get aiRecommendOnTheGo;

  /// No description provided for @aiRecommendNoKitchen.
  ///
  /// In en, this message translates to:
  /// **'No cooking (Cold meal)'**
  String get aiRecommendNoKitchen;

  /// No description provided for @aiRecommendWithCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking allowed'**
  String get aiRecommendWithCooking;

  /// No description provided for @aiRecommendGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get aiRecommendGenerate;

  /// No description provided for @aiRecommendGenerating.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiRecommendGenerating;

  /// No description provided for @aiRecommendSaveToDiary.
  ///
  /// In en, this message translates to:
  /// **'Save to Diary'**
  String get aiRecommendSaveToDiary;

  /// No description provided for @aiRecommendNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No database match'**
  String get aiRecommendNoMatch;

  /// No description provided for @aiRecommendRemainingMacros.
  ///
  /// In en, this message translates to:
  /// **'Remaining today'**
  String get aiRecommendRemainingMacros;

  /// No description provided for @aiRecommendCustomRequest.
  ///
  /// In en, this message translates to:
  /// **'Custom request'**
  String get aiRecommendCustomRequest;

  /// No description provided for @aiRecommendCustomRequestHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Include leftover rice, high protein, etc.'**
  String get aiRecommendCustomRequestHint;

  /// No description provided for @currentlyTracking.
  ///
  /// In en, this message translates to:
  /// **'Currently tracking'**
  String get currentlyTracking;

  /// No description provided for @currentlyTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Show in daily tracker hub'**
  String get currentlyTrackingDesc;

  /// No description provided for @filter3Months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get filter3Months;

  /// No description provided for @filter6Months.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get filter6Months;

  /// No description provided for @sectionConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency & Frequency'**
  String get sectionConsistency;

  /// No description provided for @metricsWorkoutsWeek.
  ///
  /// In en, this message translates to:
  /// **'Workouts (Week)'**
  String get metricsWorkoutsWeek;

  /// No description provided for @metricsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get metricsCurrentStreak;

  /// No description provided for @metricsActiveWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks active'**
  String get metricsActiveWeeks;

  /// No description provided for @placeholderCalendarHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Calendar Heatmap Visual'**
  String get placeholderCalendarHeatmap;

  /// No description provided for @consistencyTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency Tracker'**
  String get consistencyTrackerTitle;

  /// No description provided for @consistencyTrackerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Consistency & Habit Tracker (Coming Soon)'**
  String get consistencyTrackerComingSoon;

  /// No description provided for @sectionMuscleVolume.
  ///
  /// In en, this message translates to:
  /// **'Muscle Groups & Volume'**
  String get sectionMuscleVolume;

  /// No description provided for @metricsTopTrained.
  ///
  /// In en, this message translates to:
  /// **'Top Trained'**
  String get metricsTopTrained;

  /// No description provided for @metricsMostNeglected.
  ///
  /// In en, this message translates to:
  /// **'Most Neglected'**
  String get metricsMostNeglected;

  /// No description provided for @placeholderMuscleHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Muscle Heatmap Visual'**
  String get placeholderMuscleHeatmap;

  /// No description provided for @muscleAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Muscle Group Analytics'**
  String get muscleAnalyticsTitle;

  /// No description provided for @muscleAnalyticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Muscle Volume & Heatmaps (Coming Soon)'**
  String get muscleAnalyticsComingSoon;

  /// No description provided for @sectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance & PRs'**
  String get sectionPerformance;

  /// No description provided for @metricsRecentPrs.
  ///
  /// In en, this message translates to:
  /// **'Recent PRs'**
  String get metricsRecentPrs;

  /// No description provided for @metricsVolumeLifted.
  ///
  /// In en, this message translates to:
  /// **'Volume Lifted'**
  String get metricsVolumeLifted;

  /// No description provided for @metricsMostImproved.
  ///
  /// In en, this message translates to:
  /// **'Most Improved'**
  String get metricsMostImproved;

  /// No description provided for @exerciseAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Analytics'**
  String get exerciseAnalyticsTitle;

  /// No description provided for @exerciseAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search and analyze specific exercises'**
  String get exerciseAnalyticsSubtitle;

  /// No description provided for @prDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'PR Dashboard'**
  String get prDashboardTitle;

  /// No description provided for @prDashboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Records & Progress (Coming Soon)'**
  String get prDashboardComingSoon;

  /// No description provided for @exerciseAnalyticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Exercise search & specific trends (Coming Soon)'**
  String get exerciseAnalyticsComingSoon;

  /// No description provided for @sectionRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get sectionRecovery;

  /// No description provided for @metricsMuscleReadiness.
  ///
  /// In en, this message translates to:
  /// **'Muscle Readiness'**
  String get metricsMuscleReadiness;

  /// No description provided for @recoveryTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Tracker'**
  String get recoveryTrackerTitle;

  /// No description provided for @recoveryTrackerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Muscle readiness & fatigue (Coming Soon)'**
  String get recoveryTrackerComingSoon;

  /// No description provided for @recoveryOverallMostlyRecovered.
  ///
  /// In en, this message translates to:
  /// **'Mostly recovered'**
  String get recoveryOverallMostlyRecovered;

  /// No description provided for @recoveryOverallMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed recovery state'**
  String get recoveryOverallMixed;

  /// No description provided for @recoveryOverallSeveralRecovering.
  ///
  /// In en, this message translates to:
  /// **'Several muscle groups still recovering'**
  String get recoveryOverallSeveralRecovering;

  /// No description provided for @recoveryOverallInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for recovery insight yet'**
  String get recoveryOverallInsufficientData;

  /// No description provided for @recoveryHubCountsSummary.
  ///
  /// In en, this message translates to:
  /// **'Recovering: {recovering}  Ready: {ready}  Fresh: {fresh}'**
  String recoveryHubCountsSummary(int recovering, int ready, int fresh);

  /// No description provided for @recoveryHubNoDataSummary.
  ///
  /// In en, this message translates to:
  /// **'Keep logging workouts to unlock recovery insights.'**
  String get recoveryHubNoDataSummary;

  /// No description provided for @recoveryByMuscleTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery by Muscle'**
  String get recoveryByMuscleTitle;

  /// No description provided for @recoveryStateRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get recoveryStateRecovering;

  /// No description provided for @recoveryStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get recoveryStateReady;

  /// No description provided for @recoveryStateFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get recoveryStateFresh;

  /// No description provided for @recoveryStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get recoveryStateUnknown;

  /// No description provided for @recoveryLastLoadedHours.
  ///
  /// In en, this message translates to:
  /// **'Last significant loading: {hours}h ago'**
  String recoveryLastLoadedHours(int hours);

  /// No description provided for @recoveryFatigueContextHigh.
  ///
  /// In en, this message translates to:
  /// **'Recent fatigue context: high session fatigue'**
  String get recoveryFatigueContextHigh;

  /// No description provided for @recoveryFatigueContextBaseline.
  ///
  /// In en, this message translates to:
  /// **'Recent fatigue context: baseline session fatigue'**
  String get recoveryFatigueContextBaseline;

  /// No description provided for @recoveryExplanationWithHighFatigue.
  ///
  /// In en, this message translates to:
  /// **'{muscle}: last significantly loaded {hours}h ago, with high session fatigue.'**
  String recoveryExplanationWithHighFatigue(String muscle, int hours);

  /// No description provided for @recoveryExplanationBasic.
  ///
  /// In en, this message translates to:
  /// **'{muscle}: last significantly loaded {hours}h ago.'**
  String recoveryExplanationBasic(String muscle, int hours);

  /// No description provided for @recoveryHeuristicDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a conservative heuristic based on recent significant loading and session effort. It is not a medical recovery measurement.'**
  String get recoveryHeuristicDisclaimer;

  /// No description provided for @recoveryRecentLoad.
  ///
  /// In en, this message translates to:
  /// **'Recent load amount: {sets} equivalent sets'**
  String recoveryRecentLoad(String sets);

  /// No description provided for @recoveryWindowHeuristic.
  ///
  /// In en, this message translates to:
  /// **'Heuristic window: often around {from} to {to} hours, depending on context.'**
  String recoveryWindowHeuristic(int from, int to);

  /// No description provided for @recoveryRadarHeuristicCaption.
  ///
  /// In en, this message translates to:
  /// **'Radar overview of recent recovery pressure by muscle. It is directional and heuristic.'**
  String get recoveryRadarHeuristicCaption;

  /// No description provided for @recoveryNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Not enough significant training load has been logged yet to estimate muscle recovery.'**
  String get recoveryNoDataBody;

  /// No description provided for @sectionBodyNutrition.
  ///
  /// In en, this message translates to:
  /// **'Body & Nutrition'**
  String get sectionBodyNutrition;

  /// No description provided for @metricsCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get metricsCurrentWeight;

  /// No description provided for @metricsAvgCalories.
  ///
  /// In en, this message translates to:
  /// **'Avg. Calories'**
  String get metricsAvgCalories;

  /// No description provided for @placeholderWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend Line Chart'**
  String get placeholderWeightTrend;

  /// No description provided for @exerciseAnalyticsPrsLabel.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL RECORDS'**
  String get exerciseAnalyticsPrsLabel;

  /// No description provided for @exerciseAnalyticsTrendsLabel.
  ///
  /// In en, this message translates to:
  /// **'TRENDS'**
  String get exerciseAnalyticsTrendsLabel;

  /// No description provided for @exerciseAnalyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'No tracking data for this exercise.'**
  String get exerciseAnalyticsNoData;

  /// No description provided for @exerciseAnalyticsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get exerciseAnalyticsNotEnoughData;

  /// No description provided for @exerciseAnalyticsChartWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight Over Time (kg)'**
  String get exerciseAnalyticsChartWeight;

  /// No description provided for @exerciseAnalyticsChartVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume Over Time (kg)'**
  String get exerciseAnalyticsChartVolume;

  /// No description provided for @exerciseAnalyticsChartSets.
  ///
  /// In en, this message translates to:
  /// **'Sets Over Time'**
  String get exerciseAnalyticsChartSets;

  /// No description provided for @allTimeRecordsLabel.
  ///
  /// In en, this message translates to:
  /// **'All-Time Records'**
  String get allTimeRecordsLabel;

  /// No description provided for @recentActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivityLabel;

  /// No description provided for @prsByRepRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Set by Rep Range'**
  String get prsByRepRangeLabel;

  /// No description provided for @volumeAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Volume Analytics'**
  String get volumeAnalyticsTitle;

  /// No description provided for @weeklyTonnageLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Tonnage'**
  String get weeklyTonnageLabel;

  /// No description provided for @volumeByMuscleLabel.
  ///
  /// In en, this message translates to:
  /// **'By Muscle Group'**
  String get volumeByMuscleLabel;

  /// No description provided for @topExercisesLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Exercises'**
  String get topExercisesLabel;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekLabel;

  /// No description provided for @avgPerWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg / Week'**
  String get avgPerWeekLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// No description provided for @trainingCalendarLabel.
  ///
  /// In en, this message translates to:
  /// **'Training Calendar'**
  String get trainingCalendarLabel;

  /// No description provided for @workoutsPerWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts per Week'**
  String get workoutsPerWeekLabel;

  /// No description provided for @totalWorkoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalWorkoutsLabel;

  /// No description provided for @weeksLabel.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeksLabel;

  /// No description provided for @tonnageKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Tonnage (kg)'**
  String get tonnageKgLabel;

  /// No description provided for @noWorkoutDataLabel.
  ///
  /// In en, this message translates to:
  /// **'No workout data yet. Start logging to see stats.'**
  String get noWorkoutDataLabel;

  /// No description provided for @analyticsSectionVolumeMuscles.
  ///
  /// In en, this message translates to:
  /// **'Volume & Muscle Groups'**
  String get analyticsSectionVolumeMuscles;

  /// No description provided for @analyticsSectionPerformanceRecords.
  ///
  /// In en, this message translates to:
  /// **'Performance & Records'**
  String get analyticsSectionPerformanceRecords;

  /// No description provided for @analyticsTopVolume.
  ///
  /// In en, this message translates to:
  /// **'Top Trained'**
  String get analyticsTopVolume;

  /// No description provided for @analyticsLowestVolume.
  ///
  /// In en, this message translates to:
  /// **'Lowest Volume'**
  String get analyticsLowestVolume;

  /// No description provided for @analyticsRecentRecords.
  ///
  /// In en, this message translates to:
  /// **'Recent Records'**
  String get analyticsRecentRecords;

  /// No description provided for @analyticsPerfWithReps.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg x {reps}'**
  String analyticsPerfWithReps(String weight, int reps);

  /// No description provided for @analyticsKgThisWeek.
  ///
  /// In en, this message translates to:
  /// **'kg (this week)'**
  String get analyticsKgThisWeek;

  /// No description provided for @analyticsRecoverySummary.
  ///
  /// In en, this message translates to:
  /// **'3 recovering, 8 ready'**
  String get analyticsRecoverySummary;

  /// No description provided for @analyticsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get analyticsViewDetails;

  /// No description provided for @analyticsRepRangeSuffix.
  ///
  /// In en, this message translates to:
  /// **' reps'**
  String get analyticsRepRangeSuffix;

  /// No description provided for @analyticsNoRecordYet.
  ///
  /// In en, this message translates to:
  /// **'No record yet'**
  String get analyticsNoRecordYet;

  /// No description provided for @analyticsNotableImprovements.
  ///
  /// In en, this message translates to:
  /// **'Notable Improvements'**
  String get analyticsNotableImprovements;

  /// No description provided for @analyticsNoPrTrendInWindow.
  ///
  /// In en, this message translates to:
  /// **'There is no clear PR trend in this window yet.'**
  String get analyticsNoPrTrendInWindow;

  /// No description provided for @analyticsE1rmProgress.
  ///
  /// In en, this message translates to:
  /// **'e1RM {previous} -> {recent} kg'**
  String analyticsE1rmProgress(String previous, String recent);

  /// No description provided for @analyticsUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get analyticsUnitKg;

  /// No description provided for @analyticsUnitSets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get analyticsUnitSets;

  /// No description provided for @analyticsViewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get analyticsViewLabel;

  /// No description provided for @analyticsViewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get analyticsViewWeek;

  /// No description provided for @analyticsViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get analyticsViewMonth;

  /// No description provided for @analyticsViewByExercise.
  ///
  /// In en, this message translates to:
  /// **'By Exercise'**
  String get analyticsViewByExercise;

  /// No description provided for @analyticsViewByMuscle.
  ///
  /// In en, this message translates to:
  /// **'By Muscle Group'**
  String get analyticsViewByMuscle;

  /// No description provided for @analyticsMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get analyticsMetricLabel;

  /// No description provided for @analyticsMovedWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Moved Weight (kg)'**
  String get analyticsMovedWeightKg;

  /// No description provided for @analyticsWorkSets.
  ///
  /// In en, this message translates to:
  /// **'Work Sets'**
  String get analyticsWorkSets;

  /// No description provided for @analyticsVolumeContextWithSets.
  ///
  /// In en, this message translates to:
  /// **'Moved weight = weight x reps. Switch to work sets for count-based load.'**
  String get analyticsVolumeContextWithSets;

  /// No description provided for @analyticsVolumeContextTonnageOnly.
  ///
  /// In en, this message translates to:
  /// **'This view uses moved weight (weight x reps).'**
  String get analyticsVolumeContextTonnageOnly;

  /// No description provided for @analyticsKpisHeader.
  ///
  /// In en, this message translates to:
  /// **'KPIs'**
  String get analyticsKpisHeader;

  /// No description provided for @analyticsTrainingDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Training Days / Week'**
  String get analyticsTrainingDaysPerWeek;

  /// No description provided for @analyticsLast4Weeks.
  ///
  /// In en, this message translates to:
  /// **'last 4 weeks'**
  String get analyticsLast4Weeks;

  /// No description provided for @analyticsRhythm.
  ///
  /// In en, this message translates to:
  /// **'Rhythm'**
  String get analyticsRhythm;

  /// No description provided for @analyticsVsPrior4Weeks.
  ///
  /// In en, this message translates to:
  /// **'vs the previous 4 weeks'**
  String get analyticsVsPrior4Weeks;

  /// No description provided for @analyticsRollingConsistency.
  ///
  /// In en, this message translates to:
  /// **'Rolling Consistency'**
  String get analyticsRollingConsistency;

  /// No description provided for @analyticsWeeksAtLeast2Workouts.
  ///
  /// In en, this message translates to:
  /// **'weeks with at least 2 sessions'**
  String get analyticsWeeksAtLeast2Workouts;

  /// No description provided for @analyticsCalendarExplainer.
  ///
  /// In en, this message translates to:
  /// **'Color intensity reflects sessions per day, making this a true consistency map.'**
  String get analyticsCalendarExplainer;

  /// No description provided for @analyticsSelectDayPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a day to inspect session count.'**
  String get analyticsSelectDayPrompt;

  /// No description provided for @analyticsSelectedDayWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count} sessions'**
  String analyticsSelectedDayWorkouts(String date, int count);

  /// No description provided for @analyticsTotalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get analyticsTotalSessions;

  /// No description provided for @analyticsPlaceholderWeightValue.
  ///
  /// In en, this message translates to:
  /// **'82.5'**
  String get analyticsPlaceholderWeightValue;

  /// No description provided for @analyticsPlaceholderWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'kg (-0.5)'**
  String get analyticsPlaceholderWeightTrend;

  /// No description provided for @analyticsPlaceholderCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'2,450'**
  String get analyticsPlaceholderCaloriesValue;

  /// No description provided for @analyticsPlaceholderCaloriesUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal/day'**
  String get analyticsPlaceholderCaloriesUnit;

  /// No description provided for @analyticsMuscleWeeklySets.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sets'**
  String get analyticsMuscleWeeklySets;

  /// No description provided for @analyticsMuscleTopFrequency.
  ///
  /// In en, this message translates to:
  /// **'Top Frequency'**
  String get analyticsMuscleTopFrequency;

  /// No description provided for @analyticsPerWeekAbbrev.
  ///
  /// In en, this message translates to:
  /// **'wk'**
  String get analyticsPerWeekAbbrev;

  /// No description provided for @analyticsKeepTrackingUnlockInsights.
  ///
  /// In en, this message translates to:
  /// **'Keep tracking to unlock insights.'**
  String get analyticsKeepTrackingUnlockInsights;

  /// No description provided for @analyticsGuidanceNoClearWeakPoint.
  ///
  /// In en, this message translates to:
  /// **'Guidance: No clear weak point in this period.'**
  String get analyticsGuidanceNoClearWeakPoint;

  /// No description provided for @analyticsGuidanceLowerEmphasis.
  ///
  /// In en, this message translates to:
  /// **'Guidance: Lower recent emphasis on {muscles}.'**
  String analyticsGuidanceLowerEmphasis(String muscles);

  /// No description provided for @analyticsPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get analyticsPeriodLabel;

  /// No description provided for @analyticsEquivalentSetsExplainer.
  ///
  /// In en, this message translates to:
  /// **'Equivalent hard sets use primary x1.0 and secondary x0.5 weighting. Frequency counts only days reaching >= 1.0 equivalent sets.'**
  String get analyticsEquivalentSetsExplainer;

  /// No description provided for @analyticsWeeklySetsByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sets by Muscle'**
  String get analyticsWeeklySetsByMuscle;

  /// No description provided for @analyticsFrequencyByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Frequency by Muscle'**
  String get analyticsFrequencyByMuscle;

  /// No description provided for @analyticsRecentDistributionHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Recent Distribution Heatmap'**
  String get analyticsRecentDistributionHeatmap;

  /// No description provided for @analyticsRadarOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Radar Overview'**
  String get analyticsRadarOverviewTitle;

  /// No description provided for @analyticsRadarVolumeCaption.
  ///
  /// In en, this message translates to:
  /// **'Shows relative volume distribution across muscles for a quick at-a-glance summary.'**
  String get analyticsRadarVolumeCaption;

  /// No description provided for @analyticsGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get analyticsGuidanceTitle;

  /// No description provided for @analyticsGuidanceDirectionalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is directional guidance based on your recent set distribution, not an absolute diagnosis.'**
  String get analyticsGuidanceDirectionalDisclaimer;

  /// No description provided for @analyticsGuidanceSoftenedDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Insights are intentionally softened until enough data is available.'**
  String get analyticsGuidanceSoftenedDisclaimer;

  /// No description provided for @analyticsWeekTotalEquivalentSets.
  ///
  /// In en, this message translates to:
  /// **'Week total: {value} equivalent sets'**
  String analyticsWeekTotalEquivalentSets(String value);

  /// No description provided for @analyticsFrequencyRuleFooter.
  ///
  /// In en, this message translates to:
  /// **'Frequency counts only days where the muscle reached >= 1.0 equivalent sets.'**
  String get analyticsFrequencyRuleFooter;

  /// No description provided for @liveWorkoutE1rmCurrentSet.
  ///
  /// In en, this message translates to:
  /// **'e1RM {value} kg'**
  String liveWorkoutE1rmCurrentSet(String value);

  /// No description provided for @liveWorkoutE1rmBestSession.
  ///
  /// In en, this message translates to:
  /// **'Best e1RM this session: {value} kg'**
  String liveWorkoutE1rmBestSession(String value);

  /// No description provided for @liveWorkoutE1rmVsLastSession.
  ///
  /// In en, this message translates to:
  /// **'vs last session: {delta} kg'**
  String liveWorkoutE1rmVsLastSession(String delta);

  /// No description provided for @bodyNutritionCorrelationTitle.
  ///
  /// In en, this message translates to:
  /// **'Body & Nutrition Trends'**
  String get bodyNutritionCorrelationTitle;

  /// No description provided for @metricsWeightChange.
  ///
  /// In en, this message translates to:
  /// **'Weight Change'**
  String get metricsWeightChange;

  /// No description provided for @analyticsKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal/day'**
  String get analyticsKcalPerDay;

  /// No description provided for @analyticsDaysWithWeightData.
  ///
  /// In en, this message translates to:
  /// **'days with weight'**
  String get analyticsDaysWithWeightData;

  /// No description provided for @analyticsDayUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get analyticsDayUnitLabel;

  /// No description provided for @analyticsPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get analyticsPerDayLabel;

  /// No description provided for @analyticsEffectiveRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective range'**
  String get analyticsEffectiveRangeLabel;

  /// No description provided for @analyticsAxisXLabel.
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get analyticsAxisXLabel;

  /// No description provided for @analyticsAxisYLabel.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get analyticsAxisYLabel;

  /// No description provided for @analyticsHighConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Higher-confidence pattern'**
  String get analyticsHighConfidenceLabel;

  /// No description provided for @analyticsLowConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Lower-confidence pattern'**
  String get analyticsLowConfidenceLabel;

  /// No description provided for @analyticsObservedPatternLabel.
  ///
  /// In en, this message translates to:
  /// **'Observed pattern'**
  String get analyticsObservedPatternLabel;

  /// No description provided for @analyticsBodyNutritionTrendContext.
  ///
  /// In en, this message translates to:
  /// **'Body weight and calorie trends'**
  String get analyticsBodyNutritionTrendContext;

  /// No description provided for @analyticsBodyNutritionTrendContextHint.
  ///
  /// In en, this message translates to:
  /// **'These lines show nearby trend movement over the same period for context.'**
  String get analyticsBodyNutritionTrendContextHint;

  /// No description provided for @analyticsWeightTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Body weight (smoothed)'**
  String get analyticsWeightTrendLabel;

  /// No description provided for @analyticsCaloriesTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories (daily avg trend)'**
  String get analyticsCaloriesTrendLabel;

  /// No description provided for @analyticsInterpretationTitle.
  ///
  /// In en, this message translates to:
  /// **'Interpretation'**
  String get analyticsInterpretationTitle;

  /// No description provided for @analyticsBodyNutritionConfidenceHighHint.
  ///
  /// In en, this message translates to:
  /// **'Data coverage in this range is strong enough for a more reliable pattern read.'**
  String get analyticsBodyNutritionConfidenceHighHint;

  /// No description provided for @analyticsBodyNutritionConfidenceLowHint.
  ///
  /// In en, this message translates to:
  /// **'Data coverage in this range is still limited, so treat this as early context.'**
  String get analyticsBodyNutritionConfidenceLowHint;

  /// No description provided for @analyticsBodyNutritionLowConfidenceNudge.
  ///
  /// In en, this message translates to:
  /// **'Keep logging weight and calories regularly to improve confidence.'**
  String get analyticsBodyNutritionLowConfidenceNudge;

  /// No description provided for @analyticsBodyNutritionInterpretationConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'Interpretation confidence: higher. Use this as trend context, not a direct cause statement.'**
  String get analyticsBodyNutritionInterpretationConfidenceHigh;

  /// No description provided for @analyticsBodyNutritionInterpretationConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Interpretation confidence: lower. Use this as an early pattern signal and keep tracking.'**
  String get analyticsBodyNutritionInterpretationConfidenceLow;

  /// No description provided for @analyticsCorrelationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This view shows trend correlation over time. It does not prove that calorie changes directly caused weight changes.'**
  String get analyticsCorrelationDisclaimer;

  /// No description provided for @analyticsInsightStableWeightCaloriesUp.
  ///
  /// In en, this message translates to:
  /// **'Weight trend is stable while average calories increased.'**
  String get analyticsInsightStableWeightCaloriesUp;

  /// No description provided for @analyticsInsightWeightUpCaloriesUp.
  ///
  /// In en, this message translates to:
  /// **'Weight is trending upward alongside higher average calorie intake.'**
  String get analyticsInsightWeightUpCaloriesUp;

  /// No description provided for @analyticsInsightCaloriesDownWeightStable.
  ///
  /// In en, this message translates to:
  /// **'Recent calorie reduction has not yet clearly changed the weight trend.'**
  String get analyticsInsightCaloriesDownWeightStable;

  /// No description provided for @analyticsInsightWeightDownCaloriesDown.
  ///
  /// In en, this message translates to:
  /// **'Weight is trending downward alongside lower average calorie intake.'**
  String get analyticsInsightWeightDownCaloriesDown;

  /// No description provided for @analyticsInsightMixedPattern.
  ///
  /// In en, this message translates to:
  /// **'Weight and calorie trends move in mixed directions without a clear correlation pattern yet.'**
  String get analyticsInsightMixedPattern;

  /// No description provided for @analyticsInsightNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet for meaningful correlation insight.'**
  String get analyticsInsightNotEnoughData;

  /// No description provided for @restTimerNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest finished'**
  String get restTimerNotificationTitle;

  /// No description provided for @restTimerNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your pause timer is over. Ready for the next set.'**
  String get restTimerNotificationBody;

  /// No description provided for @onboardingContinueSetup.
  ///
  /// In en, this message translates to:
  /// **'Set Up Profile'**
  String get onboardingContinueSetup;

  /// No description provided for @onboardingRestoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get onboardingRestoreFromBackup;

  /// No description provided for @onboardingRestoreImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing backup...'**
  String get onboardingRestoreImporting;

  /// No description provided for @onboardingRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully!'**
  String get onboardingRestoreSuccess;

  /// No description provided for @onboardingRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check the file and try again.'**
  String get onboardingRestoreFailed;

  /// No description provided for @finishWorkoutTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout Title'**
  String get finishWorkoutTitleLabel;

  /// No description provided for @finishWorkoutNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get finishWorkoutNotesLabel;

  /// No description provided for @finishWorkoutNotesHint.
  ///
  /// In en, this message translates to:
  /// **'How did the workout go?'**
  String get finishWorkoutNotesHint;

  /// No description provided for @sleepSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepSectionTitle;

  /// No description provided for @sleepSectionSubtitleDayEntry.
  ///
  /// In en, this message translates to:
  /// **'Day overview and detail drill-downs'**
  String get sleepSectionSubtitleDayEntry;

  /// No description provided for @sleepSectionSubtitleAllEntry.
  ///
  /// In en, this message translates to:
  /// **'Sleep day, week, and month views are available from this entry'**
  String get sleepSectionSubtitleAllEntry;

  /// No description provided for @sleepScopeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get sleepScopeDay;

  /// No description provided for @sleepScopeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get sleepScopeWeek;

  /// No description provided for @sleepScopeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get sleepScopeMonth;

  /// No description provided for @sleepWeekSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Week summary'**
  String get sleepWeekSummaryTitle;

  /// No description provided for @sleepMonthSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Month summary'**
  String get sleepMonthSummaryTitle;

  /// No description provided for @sleepSleepWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep window'**
  String get sleepSleepWindowTitle;

  /// No description provided for @sleepDailyScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily score'**
  String get sleepDailyScoreTitle;

  /// No description provided for @sleepMonthDailyScoreStatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily score states'**
  String get sleepMonthDailyScoreStatesTitle;

  /// No description provided for @sleepMeanScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Mean score: {value}'**
  String sleepMeanScoreLabel(String value);

  /// No description provided for @sleepHubScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep score'**
  String get sleepHubScoreLabel;

  /// No description provided for @sleepHubAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get sleepHubAverageLabel;

  /// No description provided for @sleepHubBedtimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get sleepHubBedtimeLabel;

  /// No description provided for @sleepHubInterruptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Interruptions'**
  String get sleepHubInterruptionsLabel;

  /// No description provided for @sleepHubInterruptionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} wake-ups, {duration} total'**
  String sleepHubInterruptionsSummary(int count, String duration);

  /// No description provided for @sleepWeekdayAvgDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekday avg duration: {value}'**
  String sleepWeekdayAvgDurationLabel(String value);

  /// No description provided for @sleepWeekendAvgDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekend avg duration: {value}'**
  String sleepWeekendAvgDurationLabel(String value);

  /// No description provided for @sleepWeekNoScoredNights.
  ///
  /// In en, this message translates to:
  /// **'No scored sleep nights available in this week yet.'**
  String get sleepWeekNoScoredNights;

  /// No description provided for @sleepMonthNoScoredNights.
  ///
  /// In en, this message translates to:
  /// **'No scored sleep nights available this month yet.'**
  String get sleepMonthNoScoredNights;

  /// No description provided for @sleepSettingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepSettingsSectionTitle;

  /// No description provided for @sleepEnableTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable sleep tracking'**
  String get sleepEnableTrackingTitle;

  /// No description provided for @sleepEnableTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read sleep and overnight heart rate from Health Connect / HealthKit'**
  String get sleepEnableTrackingSubtitle;

  /// No description provided for @sleepHealthConnectionStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Health connection status'**
  String get sleepHealthConnectionStatusTitle;

  /// No description provided for @sleepRequestAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get sleepRequestAccessTitle;

  /// No description provided for @sleepRequestAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request or re-request sleep/heart-rate permissions'**
  String get sleepRequestAccessSubtitle;

  /// No description provided for @sleepImportNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Import sleep data now'**
  String get sleepImportNowTitle;

  /// No description provided for @sleepImportNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import all available sleep data (all time)'**
  String get sleepImportNowSubtitle;

  /// No description provided for @sleepRawImportsTitle.
  ///
  /// In en, this message translates to:
  /// **'View raw sleep imports'**
  String get sleepRawImportsTitle;

  /// No description provided for @sleepRawImportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show recent Health Connect payloads'**
  String get sleepRawImportsSubtitle;

  /// No description provided for @sleepDataStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Data status'**
  String get sleepDataStatusTitle;

  /// No description provided for @sleepDataStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions granted. If no sleep appears yet, run a manual import below.'**
  String get sleepDataStatusSubtitle;

  /// No description provided for @sleepNoPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'No permission'**
  String get sleepNoPermissionTitle;

  /// No description provided for @sleepNoPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep and heart-rate permissions are required to import sleep data.'**
  String get sleepNoPermissionSubtitle;

  /// No description provided for @sleepFeatureUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature unavailable'**
  String get sleepFeatureUnavailableTitle;

  /// No description provided for @sleepFeatureUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep import is unavailable on this device or Health Connect is not installed.'**
  String get sleepFeatureUnavailableSubtitle;

  /// No description provided for @sleepNoRawImportsFound.
  ///
  /// In en, this message translates to:
  /// **'No raw sleep imports found yet.'**
  String get sleepNoRawImportsFound;

  /// No description provided for @sleepRawImportsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Raw sleep imports (latest)'**
  String get sleepRawImportsSheetTitle;

  /// No description provided for @sleepImportFinishedSessions.
  ///
  /// In en, this message translates to:
  /// **'Sleep import finished ({count} sessions).'**
  String sleepImportFinishedSessions(int count);

  /// No description provided for @sleepImportUnavailableCheckPermissions.
  ///
  /// In en, this message translates to:
  /// **'Sleep import unavailable. Check permissions.'**
  String get sleepImportUnavailableCheckPermissions;

  /// No description provided for @sleepStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking permission status…'**
  String get sleepStatusChecking;

  /// No description provided for @sleepStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get sleepStatusReady;

  /// No description provided for @sleepStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get sleepStatusDenied;

  /// No description provided for @sleepStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial access'**
  String get sleepStatusPartial;

  /// No description provided for @sleepStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this device'**
  String get sleepStatusUnavailable;

  /// No description provided for @sleepStatusNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Health Connect not installed'**
  String get sleepStatusNotInstalled;

  /// No description provided for @sleepStatusTechnicalError.
  ///
  /// In en, this message translates to:
  /// **'Technical error'**
  String get sleepStatusTechnicalError;

  /// No description provided for @sleepConnectHealthDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect health data'**
  String get sleepConnectHealthDataTitle;

  /// No description provided for @sleepConnectHealthDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect HealthKit or Health Connect to import sleep records.'**
  String get sleepConnectHealthDataMessage;

  /// No description provided for @sleepPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get sleepPermissionDeniedTitle;

  /// No description provided for @sleepPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sleep permissions are denied. Open settings to grant access.'**
  String get sleepPermissionDeniedMessage;

  /// No description provided for @sleepSourceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Source unavailable'**
  String get sleepSourceUnavailableTitle;

  /// No description provided for @sleepSourceUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Sleep data source is unavailable or not installed on this device.'**
  String get sleepSourceUnavailableMessage;

  /// No description provided for @sleepEmptyDayNoData.
  ///
  /// In en, this message translates to:
  /// **'No sleep data available for this day.'**
  String get sleepEmptyDayNoData;

  /// No description provided for @sleepEmptyDayConnectMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect Health Connect/HealthKit in Settings and import recent sleep data.'**
  String get sleepEmptyDayConnectMessage;

  /// No description provided for @sleepOpenSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get sleepOpenSettingsButton;

  /// No description provided for @sleepImportNowButton.
  ///
  /// In en, this message translates to:
  /// **'Import now'**
  String get sleepImportNowButton;

  /// No description provided for @sleepImportFinishedRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Sleep import finished. Refreshing...'**
  String get sleepImportFinishedRefreshing;

  /// No description provided for @sleepImportUnavailableSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Sleep import not available. Check permissions in Settings.'**
  String get sleepImportUnavailableSettingsHint;

  /// No description provided for @sleepTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get sleepTimelineTitle;

  /// No description provided for @sleepTimelineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No stage timeline available for this night.'**
  String get sleepTimelineUnavailable;

  /// No description provided for @sleepStageDeepLabel.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get sleepStageDeepLabel;

  /// No description provided for @sleepStageLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get sleepStageLightLabel;

  /// No description provided for @sleepStageRemLabel.
  ///
  /// In en, this message translates to:
  /// **'REM'**
  String get sleepStageRemLabel;

  /// No description provided for @sleepStageAwakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Awake'**
  String get sleepStageAwakeLabel;

  /// No description provided for @sleepScoreCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep quality'**
  String get sleepScoreCardTitle;

  /// No description provided for @sleepScoreUnavailableForNight.
  ///
  /// In en, this message translates to:
  /// **'Score unavailable for this night.'**
  String get sleepScoreUnavailableForNight;

  /// No description provided for @sleepScoreCompletenessLabel.
  ///
  /// In en, this message translates to:
  /// **'Score completeness: {value}'**
  String sleepScoreCompletenessLabel(String value);

  /// No description provided for @sleepQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get sleepQualityGood;

  /// No description provided for @sleepQualityAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get sleepQualityAverage;

  /// No description provided for @sleepQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepQualityPoor;

  /// No description provided for @sleepQualityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get sleepQualityUnavailable;

  /// No description provided for @sleepQualitySubtitleGood.
  ///
  /// In en, this message translates to:
  /// **'Recovery looked strong overnight.'**
  String get sleepQualitySubtitleGood;

  /// No description provided for @sleepQualitySubtitleAverage.
  ///
  /// In en, this message translates to:
  /// **'Sleep was okay with room for improvement.'**
  String get sleepQualitySubtitleAverage;

  /// No description provided for @sleepQualitySubtitlePoor.
  ///
  /// In en, this message translates to:
  /// **'Recovery signals were weak tonight.'**
  String get sleepQualitySubtitlePoor;

  /// No description provided for @sleepQualitySubtitleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to score this night.'**
  String get sleepQualitySubtitleUnavailable;

  /// No description provided for @sleepQualityRegularityNotContributing.
  ///
  /// In en, this message translates to:
  /// **'Regularity did not contribute (<5 valid days).'**
  String get sleepQualityRegularityNotContributing;

  /// No description provided for @sleepQualityRegularityPreliminary.
  ///
  /// In en, this message translates to:
  /// **'Regularity is preliminary (5-6 valid days).'**
  String get sleepQualityRegularityPreliminary;

  /// No description provided for @sleepQualityRegularityStable.
  ///
  /// In en, this message translates to:
  /// **'Regularity is stable ({days} days).'**
  String sleepQualityRegularityStable(int days);

  /// No description provided for @sleepRegularityNightView.
  ///
  /// In en, this message translates to:
  /// **'{count}-night view'**
  String sleepRegularityNightView(int count);

  /// No description provided for @sleepMetricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get sleepMetricUnavailable;

  /// No description provided for @sleepMetricDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sleepMetricDurationTitle;

  /// No description provided for @sleepMetricHeartRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get sleepMetricHeartRateTitle;

  /// No description provided for @sleepMetricRegularityTitle.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get sleepMetricRegularityTitle;

  /// No description provided for @sleepMetricDepthTitle.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get sleepMetricDepthTitle;

  /// No description provided for @sleepMetricInterruptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interruptions'**
  String get sleepMetricInterruptionsTitle;

  /// No description provided for @sleepMetricDepthLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get sleepMetricDepthLowConfidence;

  /// No description provided for @sleepMetricDepthStagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Stages available'**
  String get sleepMetricDepthStagesAvailable;

  /// No description provided for @sleepDurationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Duration data is unavailable.'**
  String get sleepDurationUnavailable;

  /// No description provided for @sleepDurationStatusWithinTarget.
  ///
  /// In en, this message translates to:
  /// **'Within target'**
  String get sleepDurationStatusWithinTarget;

  /// No description provided for @sleepDurationStatusBelowTarget.
  ///
  /// In en, this message translates to:
  /// **'Below target'**
  String get sleepDurationStatusBelowTarget;

  /// No description provided for @sleepDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your total sleep duration for this night.'**
  String get sleepDurationSubtitle;

  /// No description provided for @sleepDurationBenchmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Adults often do best with roughly 7–9 hours. This benchmark helps you see where your night sits in that range.'**
  String get sleepDurationBenchmarkHint;

  /// No description provided for @sleepDepthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Depth data is unavailable.'**
  String get sleepDepthUnavailable;

  /// No description provided for @sleepDepthConfidenceTooLow.
  ///
  /// In en, this message translates to:
  /// **'Stage confidence is too low for a reliable depth breakdown.'**
  String get sleepDepthConfidenceTooLow;

  /// No description provided for @sleepDepthBreakdownUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stage duration breakdown is unavailable for this night.'**
  String get sleepDepthBreakdownUnavailable;

  /// No description provided for @sleepDepthRatingRestorative.
  ///
  /// In en, this message translates to:
  /// **'Restorative'**
  String get sleepDepthRatingRestorative;

  /// No description provided for @sleepDepthRatingLightLeaning.
  ///
  /// In en, this message translates to:
  /// **'Light-leaning'**
  String get sleepDepthRatingLightLeaning;

  /// No description provided for @sleepDepthStageConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage confidence: {value}'**
  String sleepDepthStageConfidenceLabel(String value);

  /// No description provided for @sleepDepthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stage distribution based on derived timeline segments.'**
  String get sleepDepthSubtitle;

  /// No description provided for @sleepInterruptionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Interruptions data is unavailable.'**
  String get sleepInterruptionsUnavailable;

  /// No description provided for @sleepInterruptionsStatusNoneDetected.
  ///
  /// In en, this message translates to:
  /// **'None detected'**
  String get sleepInterruptionsStatusNoneDetected;

  /// No description provided for @sleepInterruptionsStatusDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get sleepInterruptionsStatusDetected;

  /// No description provided for @sleepInterruptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Qualifying wake interruptions overnight.'**
  String get sleepInterruptionsSubtitle;

  /// No description provided for @sleepInterruptionsTotalWakeDuration.
  ///
  /// In en, this message translates to:
  /// **'Total wake duration'**
  String get sleepInterruptionsTotalWakeDuration;

  /// No description provided for @sleepInterruptionsFootnote.
  ///
  /// In en, this message translates to:
  /// **'This view includes only qualifying interruptions from derived analysis outputs.'**
  String get sleepInterruptionsFootnote;

  /// No description provided for @sleepRegularityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Regularity data is unavailable.'**
  String get sleepRegularityUnavailable;

  /// No description provided for @sleepRegularityNightRange.
  ///
  /// In en, this message translates to:
  /// **'{count}-night range'**
  String sleepRegularityNightRange(int count);

  /// No description provided for @sleepRegularityStatusSufficientTrend.
  ///
  /// In en, this message translates to:
  /// **'Sufficient trend data'**
  String get sleepRegularityStatusSufficientTrend;

  /// No description provided for @sleepRegularityStatusLimitedTrend.
  ///
  /// In en, this message translates to:
  /// **'Limited trend data'**
  String get sleepRegularityStatusLimitedTrend;

  /// No description provided for @sleepRegularitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bedtime and wake windows for recent nights.'**
  String get sleepRegularitySubtitle;

  /// No description provided for @sleepRegularityAverageBedtime.
  ///
  /// In en, this message translates to:
  /// **'Average bedtime'**
  String get sleepRegularityAverageBedtime;

  /// No description provided for @sleepRegularityAverageWake.
  ///
  /// In en, this message translates to:
  /// **'Average wake'**
  String get sleepRegularityAverageWake;

  /// No description provided for @sleepHeartRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sleep heart-rate data is unavailable.'**
  String get sleepHeartRateUnavailable;

  /// No description provided for @sleepHeartRateStatusNoSampleSeries.
  ///
  /// In en, this message translates to:
  /// **'No sample series for this night'**
  String get sleepHeartRateStatusNoSampleSeries;

  /// No description provided for @sleepHeartRateStatusBaselineNotEstablished.
  ///
  /// In en, this message translates to:
  /// **'Baseline not established'**
  String get sleepHeartRateStatusBaselineNotEstablished;

  /// No description provided for @sleepHeartRateStatusComparisonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Baseline comparison unavailable'**
  String get sleepHeartRateStatusComparisonUnavailable;

  /// No description provided for @sleepHeartRateStatusBelowBaseline.
  ///
  /// In en, this message translates to:
  /// **'Below baseline'**
  String get sleepHeartRateStatusBelowBaseline;

  /// No description provided for @sleepHeartRateStatusAboveBaseline.
  ///
  /// In en, this message translates to:
  /// **'Above baseline'**
  String get sleepHeartRateStatusAboveBaseline;

  /// No description provided for @sleepHeartRateNoSamplesText.
  ///
  /// In en, this message translates to:
  /// **'No persisted sleep heart-rate samples are available for this night.'**
  String get sleepHeartRateNoSamplesText;

  /// No description provided for @sleepHeartRateBaselineNotEstablishedText.
  ///
  /// In en, this message translates to:
  /// **'Baseline not established yet. This is neutral and expected early on.'**
  String get sleepHeartRateBaselineNotEstablishedText;

  /// No description provided for @sleepHeartRateComparisonUnavailableText.
  ///
  /// In en, this message translates to:
  /// **'Baseline comparison is currently unavailable for this night.'**
  String get sleepHeartRateComparisonUnavailableText;

  /// No description provided for @sleepHeartRateDeltaText.
  ///
  /// In en, this message translates to:
  /// **'Your sleep HR is {direction} baseline by {delta} {unit}.'**
  String sleepHeartRateDeltaText(String direction, String delta, String unit);

  /// No description provided for @sleepHeartRateDirectionBelow.
  ///
  /// In en, this message translates to:
  /// **'below'**
  String get sleepHeartRateDirectionBelow;

  /// No description provided for @sleepHeartRateDirectionAbove.
  ///
  /// In en, this message translates to:
  /// **'above'**
  String get sleepHeartRateDirectionAbove;

  /// No description provided for @sleepHeartRateComparedBaselineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compared with your established sleep baseline.'**
  String get sleepHeartRateComparedBaselineSubtitle;

  /// No description provided for @sleepHeartRateNoBaselineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Baseline is not established yet. This is neutral.'**
  String get sleepHeartRateNoBaselineSubtitle;

  /// No description provided for @sleepHeartRateSamplesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No heart-rate samples were stored for this night. Trend chart is unavailable.'**
  String get sleepHeartRateSamplesUnavailable;

  /// No description provided for @sleepHeartRateDashedLineHint.
  ///
  /// In en, this message translates to:
  /// **'Dashed line shows baseline ({value} {unit}).'**
  String sleepHeartRateDashedLineHint(String value, String unit);

  /// No description provided for @sleepBpmUnit.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get sleepBpmUnit;

  /// No description provided for @sleepRawImportImportedAt.
  ///
  /// In en, this message translates to:
  /// **'Imported at'**
  String get sleepRawImportImportedAt;

  /// No description provided for @sleepRawImportStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sleepRawImportStatus;

  /// No description provided for @sleepRawImportSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sleepRawImportSource;

  /// No description provided for @sleepRawImportApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sleepRawImportApp;

  /// No description provided for @sleepRawImportConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get sleepRawImportConfidence;

  /// No description provided for @sleepRawImportPayload.
  ///
  /// In en, this message translates to:
  /// **'Payload'**
  String get sleepRawImportPayload;

  /// No description provided for @adaptiveBodyweightTargetSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive bodyweight target'**
  String get adaptiveBodyweightTargetSectionTitle;

  /// No description provided for @adaptiveRecommendationSettingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendation settings'**
  String get adaptiveRecommendationSettingsSectionTitle;

  /// No description provided for @adaptiveGoalDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal direction'**
  String get adaptiveGoalDirectionLabel;

  /// No description provided for @adaptiveGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get adaptiveGoalLose;

  /// No description provided for @adaptiveGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get adaptiveGoalMaintain;

  /// No description provided for @adaptiveGoalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get adaptiveGoalGain;

  /// No description provided for @adaptiveRatePerWeek.
  ///
  /// In en, this message translates to:
  /// **'{value} kg/week'**
  String adaptiveRatePerWeek(String value);

  /// No description provided for @adaptivePriorActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Baseline daily activity'**
  String get adaptivePriorActivityLabel;

  /// No description provided for @adaptivePriorActivityLow.
  ///
  /// In en, this message translates to:
  /// **'Low activity'**
  String get adaptivePriorActivityLow;

  /// No description provided for @adaptivePriorActivityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate activity'**
  String get adaptivePriorActivityModerate;

  /// No description provided for @adaptivePriorActivityHigh.
  ///
  /// In en, this message translates to:
  /// **'High activity'**
  String get adaptivePriorActivityHigh;

  /// No description provided for @adaptivePriorActivityVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very high activity'**
  String get adaptivePriorActivityVeryHigh;

  /// No description provided for @adaptivePriorActivityHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'Baseline daily activity only (separate from extra cardio):'**
  String get adaptivePriorActivityHelpIntro;

  /// No description provided for @adaptivePriorActivityHelpLowLine.
  ///
  /// In en, this message translates to:
  /// **'Low: mostly sitting, student/pupil or office routine.'**
  String get adaptivePriorActivityHelpLowLine;

  /// No description provided for @adaptivePriorActivityHelpModerateLine.
  ///
  /// In en, this message translates to:
  /// **'Moderate: mixed sitting, walking, and standing.'**
  String get adaptivePriorActivityHelpModerateLine;

  /// No description provided for @adaptivePriorActivityHelpHighLine.
  ///
  /// In en, this message translates to:
  /// **'High: lots of standing/walking or a physically active job.'**
  String get adaptivePriorActivityHelpHighLine;

  /// No description provided for @adaptivePriorActivityHelpVeryHighLine.
  ///
  /// In en, this message translates to:
  /// **'Very high: very movement-heavy routine/job with consistently high daily activity.'**
  String get adaptivePriorActivityHelpVeryHighLine;

  /// No description provided for @adaptiveExtraCardioLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra cardio/endurance outside the app'**
  String get adaptiveExtraCardioLabel;

  /// No description provided for @adaptiveExtraCardioOption0.
  ///
  /// In en, this message translates to:
  /// **'0 h/week'**
  String get adaptiveExtraCardioOption0;

  /// No description provided for @adaptiveExtraCardioOption1.
  ///
  /// In en, this message translates to:
  /// **'1 h/week'**
  String get adaptiveExtraCardioOption1;

  /// No description provided for @adaptiveExtraCardioOption2.
  ///
  /// In en, this message translates to:
  /// **'2 h/week'**
  String get adaptiveExtraCardioOption2;

  /// No description provided for @adaptiveExtraCardioOption3.
  ///
  /// In en, this message translates to:
  /// **'3 h/week'**
  String get adaptiveExtraCardioOption3;

  /// No description provided for @adaptiveExtraCardioOption5.
  ///
  /// In en, this message translates to:
  /// **'5 h/week'**
  String get adaptiveExtraCardioOption5;

  /// No description provided for @adaptiveExtraCardioOption7Plus.
  ///
  /// In en, this message translates to:
  /// **'7+ h/week'**
  String get adaptiveExtraCardioOption7Plus;

  /// No description provided for @adaptiveExtraCardioHelp.
  ///
  /// In en, this message translates to:
  /// **'Include jogging, running, cycling, swimming, or other endurance sessions not logged as Hypertrack workouts.'**
  String get adaptiveExtraCardioHelp;

  /// No description provided for @onboardingAdaptiveGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive nutrition recommendation'**
  String get onboardingAdaptiveGoalTitle;

  /// No description provided for @onboardingAdaptiveGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your direction and weekly rate. We create a conservative starting recommendation and adapt it with your logs.'**
  String get onboardingAdaptiveGoalSubtitle;

  /// No description provided for @adaptiveRecommendationGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get adaptiveRecommendationGenerating;

  /// No description provided for @adaptiveRecommendationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh recommendation'**
  String get adaptiveRecommendationRefresh;

  /// No description provided for @onboardingAdaptiveSummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set your goal inputs and tap refresh to preview your starting recommendation.'**
  String get onboardingAdaptiveSummaryEmpty;

  /// No description provided for @onboardingAdaptiveSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendation preview'**
  String get onboardingAdaptiveSummaryTitle;

  /// No description provided for @onboardingAdaptiveSummaryCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories: {value} kcal'**
  String onboardingAdaptiveSummaryCalories(int value);

  /// No description provided for @onboardingAdaptiveSummaryProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein: {value} g'**
  String onboardingAdaptiveSummaryProtein(int value);

  /// No description provided for @onboardingAdaptiveSummaryCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs: {value} g'**
  String onboardingAdaptiveSummaryCarbs(int value);

  /// No description provided for @onboardingAdaptiveSummaryFat.
  ///
  /// In en, this message translates to:
  /// **'Fat: {value} g'**
  String onboardingAdaptiveSummaryFat(int value);

  /// No description provided for @onboardingAdaptiveSummaryConfidence.
  ///
  /// In en, this message translates to:
  /// **'Data basis: {value}'**
  String onboardingAdaptiveSummaryConfidence(String value);

  /// No description provided for @onboardingAdaptiveSummaryApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to daily goals'**
  String get onboardingAdaptiveSummaryApply;

  /// No description provided for @onboardingAdaptiveSummaryApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied to daily goals'**
  String get onboardingAdaptiveSummaryApplied;

  /// No description provided for @onboardingBodyFatPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Body fat %'**
  String get onboardingBodyFatPageTitle;

  /// No description provided for @onboardingBodyFatPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional step: enter a rough estimate if you know it.'**
  String get onboardingBodyFatPageSubtitle;

  /// No description provided for @onboardingBodyFatOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Body fat % (optional)'**
  String get onboardingBodyFatOptionalLabel;

  /// No description provided for @onboardingBodyFatOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional: only enter this if you roughly know your value. Leaving it empty is okay. It helps personalize the initial recommendation.'**
  String get onboardingBodyFatOptionalHelper;

  /// No description provided for @onboardingBodyFatHelpAction.
  ///
  /// In en, this message translates to:
  /// **'How do I estimate this?'**
  String get onboardingBodyFatHelpAction;

  /// No description provided for @bodyFatGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Body fat % guidance'**
  String get bodyFatGuidanceTitle;

  /// No description provided for @bodyFatGuidanceIntro.
  ///
  /// In en, this message translates to:
  /// **'Body-fat percentage can only be estimated roughly from appearance. This is orientation only, not a precise diagnosis.'**
  String get bodyFatGuidanceIntro;

  /// No description provided for @bodyFatGuidanceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Appearance can vary strongly at the same body-fat level due to muscle mass, fat distribution, genetics, water retention, posture, and lighting.'**
  String get bodyFatGuidanceDisclaimer;

  /// No description provided for @bodyFatGuidanceSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference sex'**
  String get bodyFatGuidanceSexLabel;

  /// No description provided for @bodyFatGuidancePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String bodyFatGuidancePercent(int percent);

  /// No description provided for @bodyFatGuidanceMale10.
  ///
  /// In en, this message translates to:
  /// **'Very lean, clear definition.'**
  String get bodyFatGuidanceMale10;

  /// No description provided for @bodyFatGuidanceMale15.
  ///
  /// In en, this message translates to:
  /// **'Athletic, visibly defined.'**
  String get bodyFatGuidanceMale15;

  /// No description provided for @bodyFatGuidanceMale20.
  ///
  /// In en, this message translates to:
  /// **'Sporty, slightly softer.'**
  String get bodyFatGuidanceMale20;

  /// No description provided for @bodyFatGuidanceMale25.
  ///
  /// In en, this message translates to:
  /// **'Less definition, more waist and belly softness.'**
  String get bodyFatGuidanceMale25;

  /// No description provided for @bodyFatGuidanceMale30.
  ///
  /// In en, this message translates to:
  /// **'Clearly softer, rounder.'**
  String get bodyFatGuidanceMale30;

  /// No description provided for @bodyFatGuidanceMale35.
  ///
  /// In en, this message translates to:
  /// **'Very soft, almost no visible definition.'**
  String get bodyFatGuidanceMale35;

  /// No description provided for @bodyFatGuidanceMale40.
  ///
  /// In en, this message translates to:
  /// **'Strongly rounder appearance, no visible definition.'**
  String get bodyFatGuidanceMale40;

  /// No description provided for @bodyFatGuidanceFemale15.
  ///
  /// In en, this message translates to:
  /// **'Very lean, very defined.'**
  String get bodyFatGuidanceFemale15;

  /// No description provided for @bodyFatGuidanceFemale20.
  ///
  /// In en, this message translates to:
  /// **'Lean and athletic.'**
  String get bodyFatGuidanceFemale20;

  /// No description provided for @bodyFatGuidanceFemale25.
  ///
  /// In en, this message translates to:
  /// **'Fit, lightly soft.'**
  String get bodyFatGuidanceFemale25;

  /// No description provided for @bodyFatGuidanceFemale30.
  ///
  /// In en, this message translates to:
  /// **'Soft, healthy-looking average athletic-to-normal range.'**
  String get bodyFatGuidanceFemale30;

  /// No description provided for @bodyFatGuidanceFemale35.
  ///
  /// In en, this message translates to:
  /// **'Noticeably softer.'**
  String get bodyFatGuidanceFemale35;

  /// No description provided for @bodyFatGuidanceFemale40.
  ///
  /// In en, this message translates to:
  /// **'Clearly softer, rounder overall appearance.'**
  String get bodyFatGuidanceFemale40;

  /// No description provided for @adaptiveRecommendationCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive recommendation'**
  String get adaptiveRecommendationCardTitle;

  /// No description provided for @adaptiveRecommendationEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Track weight and nutrition for about a week to unlock your first weekly recommendation.'**
  String get adaptiveRecommendationEmptyBody;

  /// No description provided for @adaptiveRecommendationGoalLine.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} ({rate})'**
  String adaptiveRecommendationGoalLine(String goal, String rate);

  /// No description provided for @adaptiveRecommendationMaintenanceLine.
  ///
  /// In en, this message translates to:
  /// **'Maintenance estimate: {value} kcal'**
  String adaptiveRecommendationMaintenanceLine(int value);

  /// No description provided for @adaptiveRecommendationCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String adaptiveRecommendationCaloriesValue(int value);

  /// No description provided for @adaptiveRecommendationProteinValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String adaptiveRecommendationProteinValue(int value);

  /// No description provided for @adaptiveRecommendationCarbsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String adaptiveRecommendationCarbsValue(int value);

  /// No description provided for @adaptiveRecommendationFatValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String adaptiveRecommendationFatValue(int value);

  /// No description provided for @adaptiveRecommendationConfidenceLine.
  ///
  /// In en, this message translates to:
  /// **'Data basis: {value}'**
  String adaptiveRecommendationConfidenceLine(String value);

  /// No description provided for @adaptiveRecommendationDataBasisLine.
  ///
  /// In en, this message translates to:
  /// **'Data basis: {windowDays} days, {weightLogs} weight logs, {intakeDays} intake days'**
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays);

  /// No description provided for @adaptiveRecommendationActiveCaloriesLine.
  ///
  /// In en, this message translates to:
  /// **'Current active calories: {value} kcal'**
  String adaptiveRecommendationActiveCaloriesLine(int value);

  /// No description provided for @adaptiveRecommendationApplying.
  ///
  /// In en, this message translates to:
  /// **'Applying...'**
  String get adaptiveRecommendationApplying;

  /// No description provided for @adaptiveRecommendationApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply recommendation to active goals'**
  String get adaptiveRecommendationApplyAction;

  /// No description provided for @adaptiveRecommendationWarningCalorieFloor.
  ///
  /// In en, this message translates to:
  /// **'Recommendation constrained by a minimum calorie safety floor. Review profile data and recent logs before applying.'**
  String get adaptiveRecommendationWarningCalorieFloor;

  /// No description provided for @adaptiveRecommendationWarningUnresolvedFood.
  ///
  /// In en, this message translates to:
  /// **'Some nutrition entries could not be fully resolved for calories. Check recent logs before applying.'**
  String get adaptiveRecommendationWarningUnresolvedFood;

  /// No description provided for @adaptiveRecommendationWarningLargeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Large adjustment detected. Please review your recent logging completeness before applying.'**
  String get adaptiveRecommendationWarningLargeAdjustment;

  /// No description provided for @adaptiveRecommendationWarningMacroConstrained.
  ///
  /// In en, this message translates to:
  /// **'Macro split was constrained by the calorie budget. Check if your target rate is too aggressive.'**
  String get adaptiveRecommendationWarningMacroConstrained;

  /// No description provided for @adaptiveRecommendationWarningConservative.
  ///
  /// In en, this message translates to:
  /// **'Review suggested: recommendation was adjusted conservatively due to data variability.'**
  String get adaptiveRecommendationWarningConservative;

  /// No description provided for @adaptiveRecommendationDataBasisHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Built from recent logs and their completeness.'**
  String get adaptiveRecommendationDataBasisHintDefault;

  /// No description provided for @adaptiveRecommendationDataBasisHintPriorOnly.
  ///
  /// In en, this message translates to:
  /// **'Based on profile/prior data only. Add recent weight and intake logs for adaptive adjustment.'**
  String get adaptiveRecommendationDataBasisHintPriorOnly;

  /// No description provided for @adaptiveRecommendationDataBasisHintSparseWeight.
  ///
  /// In en, this message translates to:
  /// **'Recent weight logs are sparse, so trend quality is limited.'**
  String get adaptiveRecommendationDataBasisHintSparseWeight;

  /// No description provided for @adaptiveRecommendationDataBasisHintSparseIntake.
  ///
  /// In en, this message translates to:
  /// **'Recent intake logs are sparse, so maintenance inference is limited.'**
  String get adaptiveRecommendationDataBasisHintSparseIntake;

  /// No description provided for @adaptiveRecommendationDataBasisHintSparseWeightAndIntake.
  ///
  /// In en, this message translates to:
  /// **'Recent weight and intake logs are sparse, so this recommendation is more conservative.'**
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake;

  /// No description provided for @adaptiveConfidenceNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Profile/prior only'**
  String get adaptiveConfidenceNotEnoughData;

  /// No description provided for @adaptiveConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Limited recent logs'**
  String get adaptiveConfidenceLow;

  /// No description provided for @adaptiveConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Usable recent logs'**
  String get adaptiveConfidenceMedium;

  /// No description provided for @adaptiveConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'Strong recent logs'**
  String get adaptiveConfidenceHigh;

  /// No description provided for @adaptiveRecommendationAppliedToGoalsSnack.
  ///
  /// In en, this message translates to:
  /// **'Recommendation applied to active goals.'**
  String get adaptiveRecommendationAppliedToGoalsSnack;

  /// No description provided for @adaptiveRecommendationNotAvailableSnack.
  ///
  /// In en, this message translates to:
  /// **'No recommendation available to apply.'**
  String get adaptiveRecommendationNotAvailableSnack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
