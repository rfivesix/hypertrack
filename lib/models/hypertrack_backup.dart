// lib/models/hypertrack_backup.dart

import 'exercise.dart';
import 'food_entry.dart';
import 'food_item.dart';
import 'measurement.dart';
import 'measurement_session.dart';
import 'routine.dart';
import 'routine_exercise.dart';
import 'set_log.dart';
import 'set_template.dart';
import 'fluid_entry.dart';
import 'workout_log.dart';
import 'supplement.dart';
import 'supplement_log.dart';

/// Represents a complete backup of the Hypertrack application data.
///
/// Contains all user-generated data, including food logs, workouts, routines,
/// measurements, supplements, and preferences.
class HypertrackBackup {
  /// The version of the database schema when the backup was created.
  final int schemaVersion;

  /// A list of all recorded food intake events.
  final List<FoodEntry> foodEntries;

  /// A list of all recorded fluid intake events.
  final List<FluidEntry> fluidEntries;

  /// A list of barcodes for food items marked as favorites by the user.
  final List<String> favoriteBarcodes;

  /// A list of food items created or modified by the user.
  final List<FoodItem> customFoodItems;

  /// A list of all body measurement sessions.
  final List<MeasurementSession> measurementSessions;

  /// A list of all user-defined workout routines.
  final List<Routine> routines;

  /// A list of all completed workout logs.
  final List<WorkoutLog> workoutLogs;

  /// A map containing various user settings and preferences.
  final Map<String, dynamic> userPreferences;

  /// A list of all supplements defined in the system.
  final List<Supplement> supplements;

  /// A list of all recorded supplement intake events.
  final List<SupplementLog> supplementLogs;

  /// A list of exercises created or modified by the user.
  final List<Exercise> customExercises;

  /// Historical daily goal snapshots (DailyGoalsHistory table).
  final List<Map<String, dynamic>> dailyGoalsHistory;

  /// Historical supplement settings snapshots (SupplementSettingsHistory table).
  final List<Map<String, dynamic>> supplementSettingsHistory;

  /// Current app settings row (AppSettings table), nullable for backward compat.
  final Map<String, dynamic>? appSettings;

  /// User profile row (Profiles table), nullable for backward compat.
  final Map<String, dynamic>? profile;

  /// Raw imported health step segments for deduplicated restoration.
  final List<Map<String, dynamic>> healthStepSegments;

  /// Creates a new [HypertrackBackup] instance.
  HypertrackBackup({
    required this.schemaVersion,
    required this.foodEntries,
    required this.fluidEntries,
    required this.favoriteBarcodes,
    required this.customFoodItems,
    required this.measurementSessions,
    required this.routines,
    required this.workoutLogs,
    required this.userPreferences, // HINZUGEFÜGT
    required this.supplements,
    required this.supplementLogs,
    required this.customExercises,
    this.dailyGoalsHistory = const [],
    this.supplementSettingsHistory = const [],
    this.appSettings,
    this.profile,
    this.healthStepSegments = const [],
  });

  /// Creates a [HypertrackBackup] instance from a JSON map.
  ///
  /// This factory method handles complex nested deserialization for all data types.
  factory HypertrackBackup.fromJson(Map<String, dynamic> json) {
    return HypertrackBackup(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      foodEntries:
          (json['foodEntries'] as List<dynamic>?)
              ?.map(
                (e) => FoodEntry(
                  id: e['id'],
                  barcode: e['barcode'],
                  timestamp: DateTime.parse(e['timestamp']),
                  quantityInGrams: e['quantity_in_grams'],
                  mealType: e['meal_type'],
                ),
              )
              .toList() ??
          [],
      fluidEntries:
          (json['fluidEntries'] as List<dynamic>?)
              ?.map((e) => FluidEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      favoriteBarcodes: List<String>.from(json['favoriteBarcodes'] ?? []),
      customFoodItems:
          (json['customFoodItems'] as List<dynamic>?)
              ?.map(
                (e) => FoodItem.fromMap(
                  e as Map<String, dynamic>,
                  source: FoodItemSource.user,
                ),
              )
              .toList() ??
          [],
      measurementSessions:
          (json['measurementSessions'] as List<dynamic>?)?.map((s) {
            final sessionMap = s as Map<String, dynamic>;
            final measurements =
                (sessionMap['measurements'] as List<dynamic>?)
                    ?.map((m) => Measurement.fromMap(m as Map<String, dynamic>))
                    .toList() ??
                [];
            return MeasurementSession(
              id: sessionMap['id'],
              timestamp: DateTime.parse(sessionMap['timestamp']),
              measurements: measurements,
            );
          }).toList() ??
          [],

      // KORRIGIERT: Detaillierte Deserialisierung für Routinen
      routines:
          (json['routines'] as List<dynamic>?)?.map((r) {
            final routineMap = r as Map<String, dynamic>;
            return Routine(
              id: routineMap['id'],
              name: routineMap['name'],
              exercises:
                  (routineMap['exercises'] as List<dynamic>?)?.map((re) {
                    final reMap = re as Map<String, dynamic>;
                    return RoutineExercise(
                      id: reMap['id'],
                      // Rekursiver Aufruf der .fromMap Konstruktoren
                      exercise: Exercise.fromMap(
                        reMap['exercise'] as Map<String, dynamic>,
                      ),
                      setTemplates:
                          (reMap['setTemplates'] as List<dynamic>?)
                              ?.map(
                                (st) => SetTemplate.fromMap(
                                  st as Map<String, dynamic>,
                                ),
                              )
                              .toList() ??
                          [],
                      pauseSeconds: reMap['pause_seconds'],
                    );
                  }).toList() ??
                  [],
            );
          }).toList() ??
          [],

      workoutLogs:
          (json['workoutLogs'] as List<dynamic>?)?.map((log) {
            final logMap = log as Map<String, dynamic>;
            final sets =
                (logMap['sets'] as List<dynamic>?)
                    ?.map((set) => SetLog.fromMap(set as Map<String, dynamic>))
                    .toList() ??
                [];
            return WorkoutLog.fromMap(logMap, sets: sets);
          }).toList() ??
          [],
      userPreferences: Map<String, dynamic>.from(json['userPreferences'] ?? {}),
      supplements:
          (json['supplements'] as List<dynamic>?)
              ?.map((e) => Supplement.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      supplementLogs:
          (json['supplementLogs'] as List<dynamic>?)
              ?.map((e) => SupplementLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      customExercises:
          (json['customExercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyGoalsHistory:
          (json['dailyGoalsHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      supplementSettingsHistory:
          (json['supplementSettingsHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      appSettings: json['appSettings'] != null
          ? Map<String, dynamic>.from(json['appSettings'] as Map)
          : null,
      profile: json['profile'] != null
          ? Map<String, dynamic>.from(json['profile'] as Map)
          : null,
      healthStepSegments:
          (json['healthStepSegments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  /// Converts the [HypertrackBackup] instance to a JSON map for storage or export.
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'foodEntries': foodEntries.map((e) => e.toMap()).toList(),
      'fluidEntries': fluidEntries.map((e) => e.toMap()).toList(),
      'favoriteBarcodes': favoriteBarcodes,
      'customFoodItems': customFoodItems.map((e) => e.toMap()).toList(),
      'measurementSessions': measurementSessions
          .map(
            (s) => {
              'id': s.id,
              'timestamp': s.timestamp.toIso8601String(),
              'measurements': s.measurements.map((m) => m.toMap()).toList(),
            },
          )
          .toList(),
      // Platzhalter für die komplexe Serialisierung von Routinen
      'routines': routines.map((r) => r.toMap()).toList(),
      'workoutLogs': workoutLogs
          .map(
            (log) => {
              ...log.toMap(), // Nutzt die existierende toMap-Methode
              'sets': log.sets
                  .map((s) => s.toMap())
                  .toList(), // Hängt die Sets an
            },
          )
          .toList(),
      'userPreferences': userPreferences,
      'supplements': supplements.map((e) => e.toMap()).toList(),
      'supplementLogs': supplementLogs.map((e) => e.toMap()).toList(),
      'customExercises': customExercises.map((e) => e.toMap()).toList(),
      'dailyGoalsHistory': dailyGoalsHistory,
      'supplementSettingsHistory': supplementSettingsHistory,
      'appSettings': appSettings,
      'profile': profile,
      'healthStepSegments': healthStepSegments,
    };
  }
}
