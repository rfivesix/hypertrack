// lib/data/workout_database_helper.dart

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'database_helper.dart';
import 'drift_database.dart' as db;
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../models/set_log.dart';
import '../models/set_template.dart';
import '../models/workout_log.dart';
import '../features/statistics/domain/recovery_domain_service.dart';
import '../util/muscle_analytics_utils.dart';

/// Helper class for managing workout-specific data in the Drift database.
///
/// Handles routines, exercises, set templates, and historical workout logs.
class WorkoutDatabaseHelper {
  /// Singleton instance of [WorkoutDatabaseHelper].
  static final WorkoutDatabaseHelper instance = WorkoutDatabaseHelper._init();

  final DatabaseHelper _databaseHelper;

  WorkoutDatabaseHelper._init() : _databaseHelper = DatabaseHelper.instance;
  WorkoutDatabaseHelper.forTesting({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  // Access the central Drift instance from DatabaseHelper.
  Future<db.AppDatabase> get database async => _databaseHelper.database;

  // ===========================================================================
  // HELPER METHODS (Mapping & IDs)
  // ===========================================================================

  /// Converts a local integer ID into the UUID used in relational references.
  Future<String?> _getUuidFromLocalId<T extends drift.Table, D>(
    drift.TableInfo<T, D> table,
    int localId,
  ) async {
    final dbInstance = await database;
    // Assumption: all relevant tables expose `localId` and `id` via HybridId.
    final query = dbInstance.select(table)
      ..where((tbl) => (tbl as dynamic).localId.equals(localId));
    final row = await query.getSingleOrNull();
    return (row as dynamic)?.id;
  }

  /// Converts a UUID back to its local integer ID when needed.
  Future<int?> _getLocalIdFromUuid<T extends drift.Table, D>(
    drift.TableInfo<T, D> table,
    String uuid,
  ) async {
    final dbInstance = await database;
    final query = dbInstance.select(table)
      ..where((tbl) => (tbl as dynamic).id.equals(uuid));
    final row = await query.getSingleOrNull();
    return (row as dynamic)?.localId;
  }

  List<String> _parseMuscleList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    // Fallback for legacy CSV-style muscle lists.
    if (jsonStr.contains(',')) {
      return jsonStr.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  /// Maps a Drift exercise row to the app-level [Exercise] model.
  Exercise _mapExerciseToModel(db.Exercise row) {
    return Exercise(
      id: row.localId,
      nameDe: row.nameDe,
      nameEn: row.nameEn,
      descriptionDe: row.descriptionDe ?? '',
      descriptionEn: row.descriptionEn ?? '',
      categoryName: row.categoryName ?? 'Other',
      imagePath: row.imagePath,
      primaryMuscles: _parseMuscleList(row.musclesPrimary),
      secondaryMuscles: _parseMuscleList(row.musclesSecondary),
    );
  }

  // ===========================================================================
  // EXERCISES
  // ===========================================================================

  /// Retrieves all unique exercise categories present in the database.
  Future<List<String>> getAllCategories() async {
    final dbInstance = await database;
    final query = dbInstance.selectOnly(dbInstance.exercises, distinct: true)
      ..addColumns([dbInstance.exercises.categoryName]);

    final rows = await query.get();
    final categories = rows
        .map((r) => r.read(dbInstance.exercises.categoryName))
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toList();

    return categories..sort();
  }

  Future<List<String>> getAllMuscleGroups() async {
    final dbInstance = await database;
    final exercises = await dbInstance.select(dbInstance.exercises).get();
    final Set<String> muscles = {};

    for (var ex in exercises) {
      muscles.addAll(_parseMuscleList(ex.musclesPrimary));
      muscles.addAll(_parseMuscleList(ex.musclesSecondary));
    }
    return muscles.toList()..sort();
  }

  /// Searches for exercises matching the [query] and [selectedCategories].
  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
  }) async {
    final dbInstance = await database;

    var stmt = dbInstance.select(dbInstance.exercises);

    if (query.isNotEmpty) {
      stmt = stmt
        ..where(
          (tbl) => tbl.nameDe.like('%$query%') | tbl.nameEn.like('%$query%'),
        );
    }

    if (selectedCategories.isNotEmpty) {
      stmt = stmt..where((tbl) => tbl.categoryName.isIn(selectedCategories));
    }

    stmt = stmt..orderBy([(t) => drift.OrderingTerm(expression: t.nameDe)]);

    final rows = await stmt.get();
    return rows.map(_mapExerciseToModel).toList();
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.exercises)
          ..where(
            (tbl) => tbl.nameDe.equals(name) | tbl.nameEn.equals(name),
          )
          ..limit(1))
        .getSingleOrNull();

    return row != null ? _mapExerciseToModel(row) : null;
  }

  Future<Exercise?> getExerciseByUuid(String exerciseUuid) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.id.equals(exerciseUuid))
          ..limit(1))
        .getSingleOrNull();

    return row != null ? _mapExerciseToModel(row) : null;
  }

  Future<Exercise?> resolveExerciseForSetLog(SetLog setLog) async {
    final dbInstance = await database;
    String? exerciseUuid;

    if (setLog.id != null) {
      final setRow = await (dbInstance.select(dbInstance.setLogs)
            ..where((tbl) => tbl.localId.equals(setLog.id!))
            ..limit(1))
          .getSingleOrNull();
      exerciseUuid = setRow?.exerciseId;
    }

    if (exerciseUuid != null && exerciseUuid.isNotEmpty) {
      final exercise = await getExerciseByUuid(exerciseUuid);
      if (exercise != null) return exercise;
    }

    return getExerciseByName(setLog.exerciseName);
  }

  Future<Exercise> insertExercise(Exercise exercise) async {
    final dbInstance = await database;

    final companion = db.ExercisesCompanion(
      nameDe: drift.Value(exercise.nameDe),
      nameEn: drift.Value(exercise.nameEn),
      descriptionDe: drift.Value(exercise.descriptionDe),
      descriptionEn: drift.Value(exercise.descriptionEn),
      categoryName: drift.Value(exercise.categoryName),
      musclesPrimary: drift.Value(jsonEncode(exercise.primaryMuscles)),
      musclesSecondary: drift.Value(jsonEncode(exercise.secondaryMuscles)),
      imagePath: drift.Value(exercise.imagePath),
      isCustom: const drift.Value(true),
    );

    final row =
        await dbInstance.into(dbInstance.exercises).insertReturning(companion);
    return _mapExerciseToModel(row);
  }

  Future<List<Exercise>> getCustomExercises() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(
      dbInstance.exercises,
    )..where((tbl) => tbl.isCustom.equals(true)))
        .get();
    return rows.map(_mapExerciseToModel).toList();
  }

  Future<void> importCustomExercises(List<Exercise> exercises) async {
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final ex in exercises) {
        batch.insert(
          dbInstance.exercises,
          db.ExercisesCompanion(
            nameDe: drift.Value(ex.nameDe),
            nameEn: drift.Value(ex.nameEn),
            descriptionDe: drift.Value(ex.descriptionDe),
            descriptionEn: drift.Value(ex.descriptionEn),
            categoryName: drift.Value(ex.categoryName),
            musclesPrimary: drift.Value(jsonEncode(ex.primaryMuscles)),
            musclesSecondary: drift.Value(jsonEncode(ex.secondaryMuscles)),
            imagePath: drift.Value(ex.imagePath),
            isCustom: const drift.Value(true),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  // ===========================================================================
  // ROUTINES
  // ===========================================================================

  Future<List<Routine>> getAllRoutines() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(
      dbInstance.routines,
    )..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();

    return rows.map((r) => Routine(id: r.localId, name: r.name)).toList();
  }

  Future<List<Routine>> getAllRoutinesWithDetails() async {
    final basicRoutines = await getAllRoutines();
    final detailed = <Routine>[];
    for (var r in basicRoutines) {
      if (r.id != null) {
        final d = await getRoutineById(r.id!);
        if (d != null) detailed.add(d);
      }
    }
    return detailed;
  }

  Future<Routine> createRoutine(String name) async {
    final dbInstance = await database;
    final row = await dbInstance
        .into(dbInstance.routines)
        .insertReturning(db.RoutinesCompanion(name: drift.Value(name)));
    return Routine(id: row.localId, name: row.name);
  }

  Future<void> updateRoutineName(int routineId, String newName) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.routines)
          ..where((tbl) => tbl.localId.equals(routineId)))
        .write(db.RoutinesCompanion(name: drift.Value(newName)));
  }

  // FIX: Parameter initialSetCount hinzugefügt
  Future<RoutineExercise?> addExerciseToRoutine(
    int routineId,
    int exerciseId, {
    int initialSetCount = 3,
  }) async {
    final dbInstance = await database;

    // UUIDs holen
    final routineUuid = await _getUuidFromLocalId(
      dbInstance.routines,
      routineId,
    );
    final exerciseUuid = await _getUuidFromLocalId(
      dbInstance.exercises,
      exerciseId,
    );

    if (routineUuid == null || exerciseUuid == null) return null;

    // Max Order ermitteln
    final maxOrderQuery = dbInstance.selectOnly(dbInstance.routineExercises)
      ..addColumns([dbInstance.routineExercises.orderIndex.max()])
      ..where(dbInstance.routineExercises.routineId.equals(routineUuid));
    final maxOrderResult = await maxOrderQuery.getSingle();
    final maxOrder =
        maxOrderResult.read(dbInstance.routineExercises.orderIndex.max()) ?? -1;

    // RoutineExercise einfügen
    final reRow =
        await dbInstance.into(dbInstance.routineExercises).insertReturning(
              db.RoutineExercisesCompanion(
                routineId: drift.Value(routineUuid),
                exerciseId: drift.Value(exerciseUuid),
                orderIndex: drift.Value(maxOrder + 1),
              ),
            );

    // FIX: Dynamische Anzahl von Sets (statt hardcoded 3)
    final templates = <SetTemplate>[];
    for (int i = 0; i < initialSetCount; i++) {
      final stRow =
          await dbInstance.into(dbInstance.routineSetTemplates).insertReturning(
                db.RoutineSetTemplatesCompanion(
                  routineExerciseId: drift.Value(reRow.id),
                  setType: const drift.Value('normal'),
                  targetReps: const drift.Value('8-12'),
                ),
              );
      templates.add(
        SetTemplate(id: stRow.localId, setType: 'normal', targetReps: '8-12'),
      );
    }

    // Exercise Daten laden für Rückgabe
    final exRow = await (dbInstance.select(
      dbInstance.exercises,
    )..where((tbl) => tbl.id.equals(exerciseUuid)))
        .getSingle();

    return RoutineExercise(
      id: reRow.localId,
      exercise: _mapExerciseToModel(exRow),
      setTemplates: templates,
    );
  }

  Future<void> removeExerciseFromRoutine(int routineExerciseId) async {
    final dbInstance = await database;
    // OnDelete Cascade in DB Definition sollte Kinder löschen
    await (dbInstance.delete(
      dbInstance.routineExercises,
    )..where((tbl) => tbl.localId.equals(routineExerciseId)))
        .go();
  }

  Future<void> updateExerciseOrder(
    int routineId,
    List<RoutineExercise> orderedExercises,
  ) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      for (int i = 0; i < orderedExercises.length; i++) {
        final re = orderedExercises[i];
        if (re.id != null) {
          await (dbInstance.update(dbInstance.routineExercises)
                ..where((tbl) => tbl.localId.equals(re.id!)))
              .write(db.RoutineExercisesCompanion(orderIndex: drift.Value(i)));
        }
      }
    });
  }

  /// Retrieves a detailed [Routine] including all exercises and set templates.
  Future<Routine?> getRoutineById(int id) async {
    final dbInstance = await database;

    // 1. Routine laden
    final routineRow = await (dbInstance.select(
      dbInstance.routines,
    )..where((tbl) => tbl.localId.equals(id)))
        .getSingleOrNull();

    if (routineRow == null) return null;

    // 2. RoutineExercises laden
    final routineExercisesQuery =
        dbInstance.select(dbInstance.routineExercises).join([
      drift.innerJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(
          dbInstance.routineExercises.exerciseId,
        ),
      ),
    ])
          ..where(dbInstance.routineExercises.routineId.equals(routineRow.id))
          ..orderBy([
            drift.OrderingTerm(
              expression: dbInstance.routineExercises.orderIndex,
            ),
          ]);

    final reRows = await routineExercisesQuery.get();
    final List<RoutineExercise> exercisesList = [];

    for (final row in reRows) {
      final reData = row.readTable(dbInstance.routineExercises);
      final exData = row.readTable(dbInstance.exercises);

      // 3. SetTemplates laden
      final templates = await (dbInstance.select(dbInstance.routineSetTemplates)
            ..where((tbl) => tbl.routineExerciseId.equals(reData.id))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.localId)]))
          .get();

      final setTemplates = templates
          .map(
            (t) => SetTemplate(
              id: t.localId,
              setType: t.setType,
              targetReps: t.targetReps,
              targetWeight: t.targetWeight,
              targetRir: t.targetRir, // <--- NEU
            ),
          )
          .toList();

      exercisesList.add(
        RoutineExercise(
          id: reData.localId,
          exercise: _mapExerciseToModel(exData),
          setTemplates: setTemplates,
          pauseSeconds: reData.pauseSeconds,
        ),
      );
    }

    return Routine(
      id: routineRow.localId,
      name: routineRow.name,
      exercises: exercisesList,
    );
  }

  Future<void> updateSetTemplate(SetTemplate setTemplate) async {
    if (setTemplate.id == null) return;
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.routineSetTemplates,
    )..where((tbl) => tbl.localId.equals(setTemplate.id!)))
        .write(
      db.RoutineSetTemplatesCompanion(
        setType: drift.Value(setTemplate.setType),
        targetReps: drift.Value(setTemplate.targetReps),
        targetWeight: drift.Value(setTemplate.targetWeight),
        targetRir: drift.Value(setTemplate.targetRir), // <--- NEU
      ),
    );
  }

  Future<void> replaceSetTemplatesForExercise(
    int routineExerciseId,
    List<SetTemplate> newTemplates,
  ) async {
    final dbInstance = await database;
    final reUuid = await _getUuidFromLocalId(
      dbInstance.routineExercises,
      routineExerciseId,
    );
    if (reUuid == null) return;

    await dbInstance.transaction(() async {
      // Löschen
      await (dbInstance.delete(
        dbInstance.routineSetTemplates,
      )..where((tbl) => tbl.routineExerciseId.equals(reUuid)))
          .go();

      // Neu einfügen
      for (final t in newTemplates) {
        await dbInstance.into(dbInstance.routineSetTemplates).insert(
              db.RoutineSetTemplatesCompanion(
                routineExerciseId: drift.Value(reUuid),
                setType: drift.Value(t.setType),
                targetReps: drift.Value(t.targetReps),
                targetWeight: drift.Value(t.targetWeight),
                targetRir: drift.Value(t.targetRir), // <--- NEU
              ),
            );
      }
    });
  }

  Future<void> deleteRoutine(int routineId) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.routines,
    )..where((tbl) => tbl.localId.equals(routineId)))
        .go();
  }

  Future<void> duplicateRoutine(int routineId) async {
    final original = await getRoutineById(routineId);
    if (original == null) return;

    final newRoutine = await createRoutine('${original.name} (Kopie)');
    if (newRoutine.id == null) return;

    for (final re in original.exercises) {
      if (re.exercise.id == null) continue;
      // Exercise hinzufügen (erstellt default templates)
      final newRe = await addExerciseToRoutine(newRoutine.id!, re.exercise.id!);

      if (newRe != null) {
        // Templates überschreiben mit den kopierten Werten
        await replaceSetTemplatesForExercise(newRe.id!, re.setTemplates);
        // Pause kopieren
        await updatePauseTime(newRe.id!, re.pauseSeconds);
      }
    }
  }

  Future<void> updatePauseTime(int routineExerciseId, int? seconds) async {
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.routineExercises,
    )..where((tbl) => tbl.localId.equals(routineExerciseId)))
        .write(
      db.RoutineExercisesCompanion(pauseSeconds: drift.Value(seconds)),
    );
  }

  Future<Routine?> getRoutineByName(String name) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.routines)
          ..where((tbl) => tbl.name.equals(name))
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getRoutineById(row.localId);
    }
    return null;
  }

  // ===========================================================================
  // WORKOUT LOGGING
  // ===========================================================================

  /// Creates a new [WorkoutLog] and marks it as "ongoing".
  Future<WorkoutLog> startWorkout({String? routineName}) async {
    final dbInstance = await database;
    final now = DateTime.now();

    // Versuche Routine-UUID zu finden für Verknüpfung (optional)
    String? routineId;
    String? routineNameSnapshot = routineName;

    if (routineName != null) {
      final rRow = await (dbInstance.select(dbInstance.routines)
            ..where((tbl) => tbl.name.equals(routineName))
            ..limit(1))
          .getSingleOrNull();
      routineId = rRow?.id;
    }

    final row = await dbInstance.into(dbInstance.workoutLogs).insertReturning(
          db.WorkoutLogsCompanion(
            startTime: drift.Value(now),
            status: const drift.Value('ongoing'),
            routineId: drift.Value(routineId),
            routineNameSnapshot: drift.Value(routineNameSnapshot),
          ),
        );

    return WorkoutLog(
      id: row.localId,
      routineName: routineName,
      startTime: row.startTime,
      // status field removed from WorkoutLog model in UI, handling internally if needed
    );
  }

  Future<void> finishWorkout(
    int workoutLogId, {
    String? title,
    String? notes,
  }) async {
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(workoutLogId)))
        .write(
      db.WorkoutLogsCompanion(
        endTime: drift.Value(DateTime.now()),
        status: const drift.Value('completed'),
        routineNameSnapshot:
            title != null ? drift.Value(title) : const drift.Value.absent(),
        notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
      ),
    );
  }

  Future<int> insertSetLog(SetLog setLog) async {
    final dbInstance = await database;
    final workoutLogUuid = await _getUuidFromLocalId(
      dbInstance.workoutLogs,
      setLog.workoutLogId,
    );

    if (workoutLogUuid == null) {
      throw Exception(
        "WorkoutLog UUID not found for localId ${setLog.workoutLogId}",
      );
    }

    // Exercise UUID suchen
    String? exerciseUuid;
    final exRow = await (dbInstance.select(dbInstance.exercises)
          ..where(
            (tbl) =>
                tbl.nameDe.equals(setLog.exerciseName) |
                tbl.nameEn.equals(setLog.exerciseName),
          )
          ..limit(1))
        .getSingleOrNull();
    exerciseUuid = exRow?.id;

    // Keep existing exercise linkage on updates when name-based lookup fails.
    if (setLog.id != null && (exerciseUuid == null || exerciseUuid.isEmpty)) {
      final existingSetRow = await (dbInstance.select(dbInstance.setLogs)
            ..where((tbl) => tbl.localId.equals(setLog.id!))
            ..limit(1))
          .getSingleOrNull();
      exerciseUuid = existingSetRow?.exerciseId;
    }

    final companion = db.SetLogsCompanion(
      workoutLogId: drift.Value(workoutLogUuid),
      exerciseId: drift.Value(exerciseUuid),
      exerciseNameSnapshot: drift.Value(setLog.exerciseName),
      weight: drift.Value(setLog.weightKg),
      reps: drift.Value(setLog.reps),
      setType: drift.Value(setLog.setType),
      restTimeSeconds: drift.Value(setLog.restTimeSeconds),
      isCompleted: drift.Value(setLog.isCompleted ?? false),
      logOrder: drift.Value(setLog.logOrder ?? 0),
      notes: drift.Value(setLog.notes),
      distance: drift.Value(setLog.distanceKm),
      durationSeconds: drift.Value(setLog.durationSeconds),
      rpe: drift.Value(setLog.rpe),
      rir: drift.Value(setLog.rir), // Jetzt direkt int, perfekt!
    );

    if (setLog.id != null) {
      // Update
      await (dbInstance.update(
        dbInstance.setLogs,
      )..where((tbl) => tbl.localId.equals(setLog.id!)))
          .write(companion);
      return setLog.id!;
    } else {
      // Insert
      final row =
          await dbInstance.into(dbInstance.setLogs).insertReturning(companion);
      return row.localId;
    }
  }

  Future<WorkoutLog?> getWorkoutLogById(int id) async {
    final dbInstance = await database;
    final logRow = await (dbInstance.select(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(id)))
        .getSingleOrNull();

    if (logRow == null) return null;

    final setRows = await (dbInstance.select(dbInstance.setLogs)
          ..where((tbl) => tbl.workoutLogId.equals(logRow.id))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.logOrder)]))
        .get();

    final sets = setRows
        .map(
          (row) => SetLog(
            id: row.localId,
            workoutLogId: id,
            exerciseName: row.exerciseNameSnapshot ?? 'Unknown',
            setType: row.setType,
            weightKg: row.weight,
            reps: row.reps,
            restTimeSeconds: row.restTimeSeconds,
            isCompleted: row.isCompleted,
            logOrder: row.logOrder,
            notes: row.notes,
            distanceKm: row.distance,
            durationSeconds: row.durationSeconds,
            rpe: row.rpe,
            rir: row.rir, // Direkt übernehmen
          ),
        )
        .toList();

    return WorkoutLog(
      id: logRow.localId,
      routineName: logRow.routineNameSnapshot,
      startTime: logRow.startTime,
      endTime: logRow.endTime,
      notes: logRow.notes,
      sets: sets,
    );
  }

  Future<void> updateSetLogs(List<SetLog> updatedSets) async {
    if (updatedSets.isEmpty) return;
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final s in updatedSets) {
        if (s.id != null) {
          batch.update(
            dbInstance.setLogs,
            db.SetLogsCompanion(
              weight: drift.Value(s.weightKg),
              reps: drift.Value(s.reps),
              isCompleted: drift.Value(s.isCompleted ?? false),
              notes: drift.Value(s.notes),
              rir: drift.Value(s.rir),
              // FIX: logOrder muss mit aktualisiert werden, damit Reordering gespeichert wird
              logOrder: drift.Value(s.logOrder ?? 0),
            ),
            where: (tbl) => tbl.localId.equals(s.id!),
          );
        }
      }
    });
  }

  Future<SetLog?> getLastPerformance(String exerciseName) async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.setLogs)
      ..where(
        (tbl) =>
            tbl.exerciseNameSnapshot.equals(exerciseName) &
            tbl.setType.isNotValue('warmup') &
            tbl.weight.isNotNull() &
            tbl.reps.isNotNull(),
      )
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.localId,
              mode: drift.OrderingMode.desc,
            ),
      ])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final wLogId = await _getLocalIdFromUuid(
      dbInstance.workoutLogs,
      row.workoutLogId,
    );

    return SetLog(
      id: row.localId,
      workoutLogId: wLogId ?? 0,
      exerciseName: row.exerciseNameSnapshot ?? 'Unknown',
      setType: row.setType,
      weightKg: row.weight,
      reps: row.reps,
      isCompleted: row.isCompleted,
      rir: row.rir, // Direkt übernehmen
    );
  }

  // ===========================================================================
  // WORKOUT HISTORY
  // ===========================================================================

  Future<void> deleteWorkoutLog(int logId) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(logId)))
        .go();
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    // Gibt nur abgeschlossene Logs zurück (Basis-Infos)
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]))
        .get();

    return rows
        .map(
          (r) => WorkoutLog(
            id: r.localId,
            routineName: r.routineNameSnapshot,
            startTime: r.startTime,
            endTime: r.endTime,
            notes: r.notes,
          ),
        )
        .toList();
  }

  Future<List<WorkoutLog>> getFullWorkoutLogs() async {
    final basicLogs = await getWorkoutLogs();
    final fullLogs = <WorkoutLog>[];
    for (var log in basicLogs) {
      if (log.id != null) {
        final full = await getWorkoutLogById(log.id!);
        if (full != null) fullLogs.add(full);
      }
    }
    return fullLogs;
  }

  Future<WorkoutLog?> getLatestWorkoutLog() async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.workoutLogs)
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getWorkoutLogById(row.localId);
    }
    return null;
  }

  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final dbInstance = await database;

    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.startTime.isBetweenValues(
                  effectiveStart,
                  effectiveEnd,
                ) &
                tbl.status.equals('completed'),
          )
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]))
        .get();

    final list = <WorkoutLog>[];
    for (var r in rows) {
      final full = await getWorkoutLogById(r.localId);
      if (full != null) list.add(full);
    }
    return list;
  }

  Future<void> updateWorkoutLogDetails(
    int logId,
    DateTime startTime,
    String? notes,
  ) async {
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(logId)))
        .write(
      db.WorkoutLogsCompanion(
        startTime: drift.Value(startTime),
        notes: drift.Value(notes),
      ),
    );
  }

  Future<void> deleteSetLogs(List<int> idsToDelete) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.setLogs,
    )..where((tbl) => tbl.localId.isIn(idsToDelete)))
        .go();
  }

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async {
    final full = await getWorkoutLogById(workoutLogId);
    return full?.sets ?? [];
  }

  // ===========================================================================
  // MISC / BACKUP / SPECIALS
  // ===========================================================================

  Future<void> importWorkoutData({
    required List<Routine> routines,
    required List<WorkoutLog> workoutLogs,
  }) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      // Routines
      for (final r in routines) {
        final rRow = await dbInstance
            .into(dbInstance.routines)
            .insertReturning(db.RoutinesCompanion(name: drift.Value(r.name)));
        final newRoutineId = rRow.id; // UUID

        for (int orderIndex = 0;
            orderIndex < r.exercises.length;
            orderIndex++) {
          final re = r.exercises[orderIndex];
          // Exercise Mapping checken (Name -> UUID)
          // Wir suchen die Übung in der DB. Falls custom und im Backup vorhanden, sollte sie bereits importiert sein.
          final exModel = re.exercise;
          final exRow = await (dbInstance.select(dbInstance.exercises)
                ..where(
                  (tbl) =>
                      tbl.nameEn.equals(exModel.nameEn) |
                      tbl.nameDe.equals(exModel.nameDe),
                )
                ..limit(1))
              .getSingleOrNull();

          if (exRow == null) continue;

          final reRow = await dbInstance
              .into(dbInstance.routineExercises)
              .insertReturning(
                db.RoutineExercisesCompanion(
                  routineId: drift.Value(newRoutineId),
                  exerciseId: drift.Value(exRow.id),
                  orderIndex: drift.Value(orderIndex),
                  pauseSeconds: drift.Value(re.pauseSeconds),
                ),
              );

          // Templates
          for (final t in re.setTemplates) {
            await dbInstance.into(dbInstance.routineSetTemplates).insert(
                  db.RoutineSetTemplatesCompanion(
                    routineExerciseId: drift.Value(reRow.id),
                    setType: drift.Value(t.setType),
                    targetReps: drift.Value(t.targetReps),
                    targetWeight: drift.Value(t.targetWeight),
                    targetRir: drift.Value(t.targetRir),
                  ),
                );
          }
        }
      }

      // WorkoutLogs
      for (final w in workoutLogs) {
        final wRow =
            await dbInstance.into(dbInstance.workoutLogs).insertReturning(
                  db.WorkoutLogsCompanion(
                    startTime: drift.Value(w.startTime),
                    endTime: drift.Value(w.endTime),
                    status: const drift.Value('completed'),
                    routineNameSnapshot: drift.Value(w.routineName),
                    notes: drift.Value(w.notes),
                  ),
                );

        for (final s in w.sets) {
          final exRow = await (dbInstance.select(dbInstance.exercises)
                ..where(
                  (tbl) =>
                      tbl.nameEn.equals(s.exerciseName) |
                      tbl.nameDe.equals(s.exerciseName),
                )
                ..limit(1))
              .getSingleOrNull();

          await dbInstance.into(dbInstance.setLogs).insert(
                db.SetLogsCompanion(
                  workoutLogId: drift.Value(wRow.id),
                  exerciseNameSnapshot: drift.Value(s.exerciseName),
                  exerciseId: drift.Value(exRow?.id),
                  weight: drift.Value(s.weightKg),
                  reps: drift.Value(s.reps),
                  setType: drift.Value(s.setType),
                  restTimeSeconds: drift.Value(s.restTimeSeconds),
                  isCompleted: drift.Value(s.isCompleted ?? true),
                  logOrder: drift.Value(s.logOrder ?? 0),
                  notes: drift.Value(s.notes),
                  distance: drift.Value(s.distanceKm),
                  durationSeconds: drift.Value(s.durationSeconds),
                  rpe: drift.Value(s.rpe),
                  rir: drift.Value(s.rir),
                ),
              );
        }
      }
    });
  }

  Future<List<String>> findUnknownExerciseNames() async {
    final dbInstance = await database;
    // Drift hat keinen direkten Weg für dieses komplexe Join + IS NULL Check in Dart-Syntax
    // Daher Custom Query.
    final result = await dbInstance.customSelect('''
      SELECT DISTINCT sl.exercise_name_snapshot
      FROM set_logs sl
      LEFT JOIN exercises e ON sl.exercise_id = e.id
      WHERE e.id IS NULL AND sl.exercise_name_snapshot IS NOT NULL
      ORDER BY sl.exercise_name_snapshot ASC
    ''').get();

    return result.map((r) => r.read<String>('exercise_name_snapshot')).toList();
  }

  Future<void> applyExerciseNameMapping(Map<String, String> map) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      for (final entry in map.entries) {
        final oldName = entry.key;
        final newName = entry.value;

        // Finde die neue Exercise UUID
        final exRow = await (dbInstance.select(dbInstance.exercises)
              ..where(
                (tbl) =>
                    tbl.nameEn.equals(newName) | tbl.nameDe.equals(newName),
              )
              ..limit(1))
            .getSingleOrNull();

        if (exRow != null) {
          // Update SetLogs
          await (dbInstance.update(
            dbInstance.setLogs,
          )..where((tbl) => tbl.exerciseNameSnapshot.equals(oldName)))
              .write(
            db.SetLogsCompanion(
              exerciseId: drift.Value(exRow.id),
              exerciseNameSnapshot: drift.Value(newName),
            ),
          );
        }
      }
    });
  }

  Future<Set<int>> getWorkoutDaysInMonth(DateTime month) async {
    final dbInstance = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final rows = await (dbInstance.selectOnly(dbInstance.workoutLogs)
          ..addColumns([dbInstance.workoutLogs.startTime])
          ..where(
            dbInstance.workoutLogs.startTime.isBetweenValues(start, end),
          ))
        .get();

    return rows
        .map((r) => r.read(dbInstance.workoutLogs.startTime)!.day)
        .toSet();
  }

  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) async {
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.workoutLogs).join([
      drift.innerJoin(
        dbInstance.setLogs,
        dbInstance.setLogs.workoutLogId.equalsExp(
          dbInstance.workoutLogs.id,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.exerciseNameSnapshot.equals(exerciseName) &
            dbInstance.workoutLogs.status.equals('completed'),
      )
      ..orderBy([
        drift.OrderingTerm(
          expression: dbInstance.workoutLogs.startTime,
          mode: drift.OrderingMode.desc,
        ),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    if (result == null) return [];

    final logUuid = result.readTable(dbInstance.workoutLogs).id;
    final wLogId = result.readTable(dbInstance.workoutLogs).localId;

    final setRows = await (dbInstance.select(dbInstance.setLogs)
          ..where(
            (tbl) =>
                tbl.workoutLogId.equals(logUuid) &
                tbl.exerciseNameSnapshot.equals(exerciseName),
          )
          ..orderBy([(t) => drift.OrderingTerm(expression: t.logOrder)]))
        .get();

    return setRows
        .map(
          (r) => SetLog(
            id: r.localId,
            workoutLogId: wLogId,
            exerciseName: r.exerciseNameSnapshot ?? '',
            setType: r.setType,
            weightKg: r.weight,
            reps: r.reps,
            isCompleted: r.isCompleted,
            rir: r.rir, // Direkt übernehmen
          ),
        )
        .toList();
  }

  Future<void> clearAllWorkoutData() async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      await dbInstance.delete(dbInstance.setLogs).go();
      await dbInstance.delete(dbInstance.workoutLogs).go();
      await dbInstance.delete(dbInstance.routineSetTemplates).go();
      await dbInstance.delete(dbInstance.routineExercises).go();
      await dbInstance.delete(dbInstance.routines).go();
      // Lösche nur custom exercises
      await (dbInstance.delete(
        dbInstance.exercises,
      )..where((tbl) => tbl.isCustom.equals(true)))
          .go();
    });
  }

  Future<WorkoutLog?> getOngoingWorkout() async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('ongoing'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getWorkoutLogById(row.localId);
    }
    return null;
  }

  // ===========================================================================
  // EXERCISE ANALYTICS (v1)
  // ===========================================================================

  /// Retrieves the UUID (string) for an exercise given its local integer ID.
  Future<String?> getExerciseUuidByLocalId(int localId) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.localId.equals(localId))
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  /// Builds a Drift expression that matches set_logs by exercise name snapshot
  /// (nameDe, optional nameEn) or by exercise UUID.
  drift.Expression<bool> _buildExerciseMatchCondition(
    db.AppDatabase dbInstance,
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    drift.Expression<bool> nameExpr =
        dbInstance.setLogs.exerciseNameSnapshot.equals(exerciseName);

    if (altName != null && altName.isNotEmpty && altName != exerciseName) {
      nameExpr =
          nameExpr | dbInstance.setLogs.exerciseNameSnapshot.equals(altName);
    }

    if (exerciseUuid != null && exerciseUuid.isNotEmpty) {
      return nameExpr | dbInstance.setLogs.exerciseId.equals(exerciseUuid);
    }
    return nameExpr;
  }

  /// Represents a single PR for a specific rep bracket.
  /// (Using a map/record or a specific class here; we will use a raw map structure
  /// for simplicity or a custom class if preferred. We'll use a Record for modern Dart.)
  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) async {
    final dbInstance = await database;

    final exerciseMatch = _buildExerciseMatchCondition(
      dbInstance,
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    // Qualifying sets for PRs:
    // isCompleted == true, setType != 'warmup', weight > 0, reps > 0
    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        exerciseMatch &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0),
      );

    final rows = await query.get();

    final prMap = <String, SetLog?>{
      '1 RM': null,
      '2-3 RM': null,
      '4-6 RM': null,
      '7-10 RM': null,
      '11-15 RM': null,
      '15+ RM': null,
    };

    // Helferfunktion, um den Bracket-Namen zu ermitteln
    String getBracket(int reps) {
      if (reps == 1) return '1 RM';
      if (reps >= 2 && reps <= 3) return '2-3 RM';
      if (reps >= 4 && reps <= 6) return '4-6 RM';
      if (reps >= 7 && reps <= 10) return '7-10 RM';
      if (reps >= 11 && reps <= 15) return '11-15 RM';
      return '15+ RM';
    }

    // Mapping von Drift-Rows auf SetLog Objekte inkl. Datum
    final List<Map<String, dynamic>> qualifyingSets = rows.map((r) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);

      return {
        'set': SetLog(
          id: setRow.localId,
          workoutLogId: logRow.localId,
          exerciseName: setRow.exerciseNameSnapshot ?? exerciseName,
          setType: setRow.setType,
          weightKg: setRow.weight,
          reps: setRow.reps,
          isCompleted: setRow.isCompleted,
        ),
        'date': logRow.startTime,
      };
    }).toList();

    // Tie-breaker logic: Max weight, then max reps, then most recent date
    for (final s in qualifyingSets) {
      final setLog = s['set'] as SetLog;
      // Date parameter would be used here if needed for deeper tie-breaking
      // but 'most recent date wins' is handled naturally by list order iteration
      final bracket = getBracket(setLog.reps ?? 0);

      final currentPr = prMap[bracket];

      if (currentPr == null) {
        prMap[bracket] = setLog;
        // Speichern Sie das Datum temporär auf dem SetLog, falls wir es später brauchen,
        // oder vergleichen Sie es direkt hier (hier einfach im Scope).
      } else {
        // Compare with current PR
        if (setLog.weightKg! > currentPr.weightKg!) {
          prMap[bracket] = setLog;
        } else if (setLog.weightKg == currentPr.weightKg) {
          if (setLog.reps! > currentPr.reps!) {
            prMap[bracket] = setLog;
          } else if (setLog.reps == currentPr.reps) {
            // Um das Datum aus dem "aktuellen" PR zu kriegen, müssten wir es mitspeichern.
            // Für v1 ersetzen wir einfach das aktuelle, da die Liste normalerweise chronologisch
            // nach hinten iteriert wird, ODER wir speichern eine interne Struktur.
            // Wir überschreiben es der Einfachheit halber (die jüngste Session gewinnt, falls
            // die Liste aufsteigend ist).
            prMap[bracket] =
                setLog; // Simplifikation für "letztes Datum gewinnt"
          }
        }
      }
    }

    return prMap;
  }

  /// Calculates Time-Series data points for Weight, Volume, and Sets per session.
  /// Result is a List of Maps containing Date and the metrics.
  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) async {
    final dbInstance = await database;

    final exerciseMatch = _buildExerciseMatchCondition(
      dbInstance,
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        exerciseMatch &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.workoutLogs.status.equals('completed'),
      )
      ..orderBy([
        drift.OrderingTerm(
          expression: dbInstance.workoutLogs.startTime,
          mode: drift.OrderingMode.asc,
        ),
      ]);

    final rows = await query.get();

    // Group by session (WorkoutLog UUID or LocalID)
    final Map<int, Map<String, dynamic>> sessionAggregates = {};

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final wLogId = logRow.localId;

      if (!sessionAggregates.containsKey(wLogId)) {
        sessionAggregates[wLogId] = {
          'date': logRow.startTime,
          'maxWeight': 0.0,
          'totalVolume': 0.0,
          'setCount': 0,
        };
      }

      final agg = sessionAggregates[wLogId]!;
      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;

      // Update Max Weight
      if (weight > agg['maxWeight']) {
        agg['maxWeight'] = weight;
      }

      // Update Volume
      agg['totalVolume'] += (weight * reps);

      // Update Set Count
      agg['setCount'] += 1;
    }

    // Return as chronologisch sortierte Liste
    final resultList = sessionAggregates.values.toList();
    resultList.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return resultList;
  }

  /// Returns the most recently updated all-time weight PRs across all exercises.
  ///
  /// For each exercise, the set with the highest recorded weight is returned.
  /// Results are sorted by the workout date of the latest session in which
  /// that PR weight was achieved, so recently active exercises appear first.
  ///
  /// Each entry contains: 'exerciseName' (String), 'weight' (double), 'reps' (int).
  Future<List<Map<String, dynamic>>> getRecentGlobalPRs({int limit = 3}) async {
    final dbInstance = await database;

    final rows = await dbInstance.customSelect(
      '''
      SELECT
        s1.exercise_name_snapshot AS exerciseName,
        s1.weight                 AS weight,
        s1.reps                   AS reps
      FROM set_logs s1
      JOIN workout_logs wl ON wl.id = s1.workout_log_id
      WHERE s1.is_completed = 1
        AND s1.set_type != 'warmup'
        AND s1.weight > 0
        AND s1.reps  > 0
        AND wl.status = 'completed'
        AND s1.weight = (
          SELECT MAX(s2.weight)
          FROM set_logs s2
          WHERE s2.exercise_name_snapshot = s1.exercise_name_snapshot
            AND s2.is_completed = 1
            AND s2.set_type != 'warmup'
            AND s2.weight > 0
        )
      GROUP BY s1.exercise_name_snapshot
      ORDER BY MAX(wl.start_time) DESC
      LIMIT ?
      ''',
      variables: [drift.Variable.withInt(limit)],
    ).get();

    return rows
        .map(
          (row) => {
            'exerciseName': row.read<String>('exerciseName'),
            'weight': row.read<double>('weight'),
            'reps': row.read<int>('reps'),
          },
        )
        .toList();
  }

  // ===========================================================================
  // AGGREGATE ANALYTICS
  // ===========================================================================

  /// Weekly tonnage (kg) for the last [weeksBack] weeks.
  /// Each entry: {weekStart: DateTime, weekLabel: String, tonnage: double, setCount: int}
  Future<List<Map<String, dynamic>>> getWeeklyVolumeData({
    int weeksBack = 8,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: weeksBack * 7));
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      )
      ..orderBy([
        drift.OrderingTerm(expression: dbInstance.workoutLogs.startTime),
      ]);

    final rows = await query.get();

    final Map<String, Map<String, dynamic>> weekMap = {};

    void ensureWeek(DateTime date) {
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      weekMap.putIfAbsent(
        key,
        () => {
          'weekStart': mondayNorm,
          'weekLabel': '${mondayNorm.day}.${mondayNorm.month}.',
          'tonnage': 0.0,
          'setCount': 0,
        },
      );
    }

    // Pre-fill all weeks so missing weeks show as 0
    for (int w = 0; w < weeksBack; w++) {
      ensureWeek(now.subtract(Duration(days: w * 7)));
    }

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final date = logRow.startTime;
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';

      ensureWeek(date);

      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      weekMap[key]!['tonnage'] =
          (weekMap[key]!['tonnage'] as double) + weight * reps;
      weekMap[key]!['setCount'] = (weekMap[key]!['setCount'] as int) + 1;
    }

    final result = weekMap.values.toList()
      ..sort(
        (a, b) =>
            (a['weekStart'] as DateTime).compareTo(b['weekStart'] as DateTime),
      );
    return result;
  }

  /// Volume (tonnage) grouped by primary muscle group for the last [daysBack] days.
  /// Returns list sorted descending by tonnage: {muscleGroup: String, tonnage: double}
  Future<List<Map<String, dynamic>>> getVolumeByMuscleGroup({
    int daysBack = 30,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();
    final Map<String, double> muscleVolume = {};

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final exRow = r.readTableOrNull(dbInstance.exercises);
      final volume = (setRow.weight ?? 0.0) * (setRow.reps ?? 0);

      if (exRow != null) {
        final muscles = _parseMuscleList(exRow.musclesPrimary);
        if (muscles.isNotEmpty) {
          for (final m in muscles) {
            muscleVolume[m] = (muscleVolume[m] ?? 0.0) + volume;
          }
        } else {
          muscleVolume['Other'] = (muscleVolume['Other'] ?? 0.0) + volume;
        }
      } else {
        muscleVolume['Other'] = (muscleVolume['Other'] ?? 0.0) + volume;
      }
    }

    final result = muscleVolume.entries
        .map((e) => {'muscleGroup': e.key, 'tonnage': e.value})
        .toList()
      ..sort(
        (a, b) => (b['tonnage'] as double).compareTo(a['tonnage'] as double),
      );
    return result;
  }

  /// Equivalent hard-set analytics for muscle groups.
  ///
  /// Uses shared analytics rules:
  /// - qualifying work sets only
  /// - primary muscles weighted at 1.0
  /// - secondary muscles weighted at 0.5
  /// - frequency day counts when a muscle reaches >= 1.0 equivalent sets
  ///
  /// Returns summary map with:
  /// - `muscles`: per-muscle equivalent sets, trained days, frequency/week, share
  /// - `weekly`: weekly buckets containing per-muscle equivalent sets
  /// - `undertrained`: soft guidance candidate list
  /// - `dataQualityOk`: suppression flag based on shared minimum requirements
  Future<Map<String, dynamic>> getMuscleGroupAnalytics({
    int daysBack = 30,
    int weeksBack = 8,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();

    final contributions = <Map<String, dynamic>>[];

    for (final row in rows) {
      final logRow = row.readTable(dbInstance.workoutLogs);
      final exRow = row.readTableOrNull(dbInstance.exercises);

      final primary = <String>{
        ..._parseMuscleList(
          exRow?.musclesPrimary,
        ).map((m) => m.trim()).where((m) => m.isNotEmpty),
      };
      final secondary = <String>{
        ..._parseMuscleList(
          exRow?.musclesSecondary,
        ).map((m) => m.trim()).where((m) => m.isNotEmpty),
      }..removeAll(primary);

      if (primary.isEmpty && secondary.isEmpty) {
        contributions.add({
          'day': logRow.startTime,
          'muscleGroup': 'Other',
          'equivalentSets': 1.0,
        });
        continue;
      }

      for (final muscle in primary) {
        contributions.add({
          'day': logRow.startTime,
          'muscleGroup': muscle,
          'equivalentSets': 1.0,
        });
      }

      for (final muscle in secondary) {
        contributions.add({
          'day': logRow.startTime,
          'muscleGroup': muscle,
          'equivalentSets': 0.5,
        });
      }
    }

    return MuscleAnalyticsUtils.buildSummary(
      contributions: contributions,
      daysBack: daysBack,
      weeksBack: weeksBack,
      now: now,
    );
  }

  /// Recovery analytics based on shared v1 heuristics.
  ///
  /// Rules:
  /// - Significant loading for a muscle session is >= 1.0 equivalent sets
  /// - Base thresholds: <48h recovering, 48-72h ready, >72h fresh
  /// - Modifier: +24h when avg RIR == 0 or avg RPE >= 9 for that muscle session
  ///
  /// Returns:
  /// - `muscles`: per-muscle recovery rows with explainability fields
  /// - `totals`: aggregate counts for recovering/ready/fresh
  /// - `overallState`: low-precision overall summary key
  /// - `hasData`: false when no significant loading exists
  Future<Map<String, dynamic>> getRecoveryAnalytics() async {
    final now = DateTime.now();
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed'),
      );

    final rows = await query.get();

    final Map<String, Map<String, dynamic>> muscleSessionMap = {};

    void addMuscleContribution({
      required String workoutLogId,
      required DateTime startTime,
      required String muscle,
      required double equivalentSets,
      required int? rir,
      required int? rpe,
    }) {
      final normalizedMuscle = muscle.trim();
      if (normalizedMuscle.isEmpty) return;

      final key = '$workoutLogId::$normalizedMuscle';
      final session = muscleSessionMap.putIfAbsent(
        key,
        () => {
          'muscleGroup': normalizedMuscle,
          'workoutLogId': workoutLogId,
          'startTime': startTime,
          'equivalentSets': 0.0,
          'rirSum': 0.0,
          'rirCount': 0,
          'rpeSum': 0.0,
          'rpeCount': 0,
        },
      );

      session['equivalentSets'] =
          (session['equivalentSets'] as double) + equivalentSets;

      if (rir != null) {
        session['rirSum'] = (session['rirSum'] as double) + rir;
        session['rirCount'] = (session['rirCount'] as int) + 1;
      }

      if (rpe != null) {
        session['rpeSum'] = (session['rpeSum'] as double) + rpe;
        session['rpeCount'] = (session['rpeCount'] as int) + 1;
      }
    }

    for (final row in rows) {
      final logRow = row.readTable(dbInstance.workoutLogs);
      final setRow = row.readTable(dbInstance.setLogs);
      final exRow = row.readTableOrNull(dbInstance.exercises);

      final primary = <String>{
        ..._parseMuscleList(
          exRow?.musclesPrimary,
        ).map((m) => m.trim()).where((m) => m.isNotEmpty),
      };
      final secondary = <String>{
        ..._parseMuscleList(
          exRow?.musclesSecondary,
        ).map((m) => m.trim()).where((m) => m.isNotEmpty),
      }..removeAll(primary);

      for (final muscle in primary) {
        addMuscleContribution(
          workoutLogId: logRow.id,
          startTime: logRow.startTime,
          muscle: muscle,
          equivalentSets: 1.0,
          rir: setRow.rir,
          rpe: setRow.rpe,
        );
      }

      for (final muscle in secondary) {
        addMuscleContribution(
          workoutLogId: logRow.id,
          startTime: logRow.startTime,
          muscle: muscle,
          equivalentSets: 0.5,
          rir: setRow.rir,
          rpe: setRow.rpe,
        );
      }
    }

    final Map<String, List<Map<String, dynamic>>> significantByMuscle = {};

    for (final session in muscleSessionMap.values) {
      final eqSets = (session['equivalentSets'] as double);
      if (eqSets < 1.0) continue;

      final muscle = session['muscleGroup'] as String;
      significantByMuscle.putIfAbsent(muscle, () => []).add(session);
    }

    final List<Map<String, dynamic>> muscles = [];

    for (final entry in significantByMuscle.entries) {
      final muscle = entry.key;
      final sessions = entry.value;
      sessions.sort(
        (a, b) =>
            (b['startTime'] as DateTime).compareTo(a['startTime'] as DateTime),
      );

      final lastSession = sessions.first;
      final lastTime = lastSession['startTime'] as DateTime;
      final hoursSince = now.difference(lastTime).inMinutes / 60.0;

      final rirCount = lastSession['rirCount'] as int;
      final rpeCount = lastSession['rpeCount'] as int;

      final avgRir =
          rirCount > 0 ? (lastSession['rirSum'] as double) / rirCount : null;
      final avgRpe =
          rpeCount > 0 ? (lastSession['rpeSum'] as double) / rpeCount : null;

      final highSessionFatigue = RecoveryDomainService.hasHighSessionFatigue(
        avgRir: avgRir,
        avgRpe: avgRpe,
      );

      final recoveringUpper = RecoveryDomainService.recoveringUpperHours(
        highSessionFatigue: highSessionFatigue,
      );
      final readyUpper = RecoveryDomainService.readyUpperHours(
        highSessionFatigue: highSessionFatigue,
      );

      final state = RecoveryDomainService.muscleState(
        hoursSinceLastSignificantLoad: hoursSince,
        highSessionFatigue: highSessionFatigue,
      );

      muscles.add({
        'muscleGroup': muscle,
        'state': state,
        'hoursSinceLastSignificantLoad': hoursSince,
        'lastSignificantLoadAt': lastTime,
        'lastEquivalentSets': lastSession['equivalentSets'] as double,
        'avgRir': avgRir,
        'avgRpe': avgRpe,
        'highSessionFatigue': highSessionFatigue,
        'recoveringUpperHours': recoveringUpper,
        'readyUpperHours': readyUpper,
      });
    }

    muscles.sort((a, b) {
      const stateOrder = {
        RecoveryDomainService.stateRecovering: 0,
        RecoveryDomainService.stateReady: 1,
        RecoveryDomainService.stateFresh: 2,
      };
      final stateCmp = (stateOrder[a['state'] as String] ?? 9).compareTo(
        stateOrder[b['state'] as String] ?? 9,
      );
      if (stateCmp != 0) return stateCmp;
      return ((a['hoursSinceLastSignificantLoad'] as num).toDouble()).compareTo(
        (b['hoursSinceLastSignificantLoad'] as num).toDouble(),
      );
    });

    final recoveringCount = muscles
        .where((m) => m['state'] == RecoveryDomainService.stateRecovering)
        .length;
    final readyCount = muscles
        .where((m) => m['state'] == RecoveryDomainService.stateReady)
        .length;
    final freshCount = muscles
        .where((m) => m['state'] == RecoveryDomainService.stateFresh)
        .length;
    final total = muscles.length;

    final overallState = RecoveryDomainService.overallState(
      totalTrackedMuscles: total,
      recoveringCount: recoveringCount,
    );

    return {
      'hasData': total > 0,
      'overallState': overallState,
      'totals': {
        RecoveryDomainService.stateRecovering: recoveringCount,
        RecoveryDomainService.stateReady: readyCount,
        RecoveryDomainService.stateFresh: freshCount,
        'tracked': total,
      },
      'muscles': muscles,
    };
  }

  /// Top [limit] exercises by tonnage for the last [daysBack] days.
  /// Each entry: {exerciseName: String, tonnage: double}
  Future<List<Map<String, dynamic>>> getTopExercisesByVolume({
    int daysBack = 30,
    int limit = 5,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();
    final Map<String, double> exVolume = {};

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final name = setRow.exerciseNameSnapshot ?? 'Unknown';
      exVolume[name] =
          (exVolume[name] ?? 0.0) + (setRow.weight ?? 0.0) * (setRow.reps ?? 0);
    }

    return (exVolume.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(limit)
        .map((e) => {'exerciseName': e.key, 'tonnage': e.value})
        .toList();
  }

  /// Workouts logged per week for the last [weeksBack] weeks.
  /// Each entry: {weekStart: DateTime, weekLabel: String, count: int}
  Future<List<Map<String, dynamic>>> getWorkoutsPerWeek({
    int weeksBack = 12,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: weeksBack * 7));
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          )
          ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime)]))
        .get();

    final Map<String, Map<String, dynamic>> weekMap = {};

    // Pre-fill all weeks
    for (int w = weeksBack - 1; w >= 0; w--) {
      final day = now.subtract(Duration(days: w * 7));
      final monday = day.subtract(Duration(days: day.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      weekMap[key] = {
        'weekStart': mondayNorm,
        'weekLabel': '${mondayNorm.day}.${mondayNorm.month}.',
        'count': 0,
      };
    }

    for (final row in rows) {
      final date = row.startTime;
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      if (weekMap.containsKey(key)) {
        weekMap[key]!['count'] = (weekMap[key]!['count'] as int) + 1;
      }
    }

    return weekMap.values.toList()
      ..sort(
        (a, b) =>
            (a['weekStart'] as DateTime).compareTo(b['weekStart'] as DateTime),
      );
  }

  /// Returns per-week consistency metrics for the last [weeksBack] weeks.
  ///
  /// Each entry contains:
  /// - weekStart: DateTime
  /// - weekLabel: String
  /// - count: int (workout frequency)
  /// - durationMinutes: double
  /// - tonnage: double (moved weight from work sets)
  Future<List<Map<String, dynamic>>> getWeeklyConsistencyMetrics({
    int weeksBack = 12,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: weeksBack * 7));
    final dbInstance = await database;

    final weekMap = <String, Map<String, dynamic>>{};

    void ensureWeek(DateTime date) {
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      weekMap.putIfAbsent(
        key,
        () => {
          'weekStart': mondayNorm,
          'weekLabel': '${mondayNorm.day}.${mondayNorm.month}.',
          'count': 0,
          'durationMinutes': 0.0,
          'tonnage': 0.0,
        },
      );
    }

    for (int w = weeksBack - 1; w >= 0; w--) {
      ensureWeek(now.subtract(Duration(days: w * 7)));
    }

    final workoutRows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          )
          ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime)]))
        .get();

    for (final row in workoutRows) {
      final start = row.startTime;
      ensureWeek(start);

      final monday = start.subtract(Duration(days: start.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';

      final durationMinutes = row.endTime == null
          ? 0.0
          : row.endTime!
                  .difference(start)
                  .inSeconds
                  .clamp(0, 24 * 60 * 60)
                  .toDouble() /
              60.0;

      weekMap[key]!['count'] = (weekMap[key]!['count'] as int) + 1;
      weekMap[key]!['durationMinutes'] =
          (weekMap[key]!['durationMinutes'] as double) + durationMinutes;
    }

    final tonnageRows = await (dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
          ..where(
            dbInstance.setLogs.isCompleted.equals(true) &
                dbInstance.setLogs.setType.isNotIn(['warmup']) &
                dbInstance.setLogs.weight.isBiggerThanValue(0) &
                dbInstance.setLogs.reps.isBiggerThanValue(0) &
                dbInstance.workoutLogs.status.equals('completed') &
                dbInstance.workoutLogs.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          ))
        .get();

    for (final row in tonnageRows) {
      final setRow = row.readTable(dbInstance.setLogs);
      final logRow = row.readTable(dbInstance.workoutLogs);
      final start = logRow.startTime;
      ensureWeek(start);

      final monday = start.subtract(Duration(days: start.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';

      final tonnage = (setRow.weight ?? 0.0) * (setRow.reps ?? 0);
      weekMap[key]!['tonnage'] = (weekMap[key]!['tonnage'] as double) + tonnage;
    }

    return weekMap.values.toList()
      ..sort(
        (a, b) =>
            (a['weekStart'] as DateTime).compareTo(b['weekStart'] as DateTime),
      );
  }

  /// Returns key training stats: totalWorkouts, thisWeekCount, avgPerWeek (last 4 wks), streakWeeks.
  Future<Map<String, dynamic>> getTrainingStats() async {
    final now = DateTime.now();
    final dbInstance = await database;

    final allLogs = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]))
        .get();

    final totalWorkouts = allLogs.length;

    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final thisWeekCount = allLogs
        .where(
          (r) =>
              !r.startTime.isBefore(thisMonday) &&
              r.startTime.isBefore(thisMonday.add(const Duration(days: 7))),
        )
        .length;

    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final last4Count =
        allLogs.where((r) => r.startTime.isAfter(fourWeeksAgo)).length;
    final avgPerWeek = last4Count / 4.0;

    // Current weekly streak
    int streakWeeks = 0;
    for (int w = 0; w < 52; w++) {
      final weekStart = thisMonday.subtract(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final hasWorkout = allLogs.any(
        (r) =>
            !r.startTime.isBefore(weekStart) && r.startTime.isBefore(weekEnd),
      );
      if (hasWorkout) {
        streakWeeks++;
      } else {
        break;
      }
    }

    return {
      'totalWorkouts': totalWorkouts,
      'thisWeekCount': thisWeekCount,
      'avgPerWeek': avgPerWeek,
      'streakWeeks': streakWeeks,
    };
  }

  /// Returns the set of dates (normalized to midnight) that had completed workouts
  /// within the last [daysBack] days.
  Future<Set<DateTime>> getWorkoutDatesSet({int daysBack = 91}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          ))
        .get();

    return rows.map((r) {
      final d = r.startTime;
      return DateTime(d.year, d.month, d.day);
    }).toSet();
  }

  /// Returns workout counts per day (normalized to midnight) for the last [daysBack] days.
  Future<Map<DateTime, int>> getWorkoutDayCounts({int daysBack = 120}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          ))
        .get();

    final Map<DateTime, int> counts = {};
    for (final row in rows) {
      final d = row.startTime;
      final day = DateTime(d.year, d.month, d.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns the all-time best set for each rep bracket across all exercises.
  /// Map key = bracket label, value = {exerciseName, weight, reps} or null.
  Future<Map<String, Map<String, dynamic>?>> getAllTimePRsByRepBracket() async {
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed'),
      );

    final rows = await query.get();

    String bracket(int reps) {
      if (reps == 1) return '1 RM';
      if (reps <= 3) return '2–3 RM';
      if (reps <= 6) return '4–6 RM';
      if (reps <= 10) return '7–10 RM';
      if (reps <= 15) return '11–15 RM';
      return '15+ RM';
    }

    final result = <String, Map<String, dynamic>?>{
      '1 RM': null,
      '2–3 RM': null,
      '4–6 RM': null,
      '7–10 RM': null,
      '11–15 RM': null,
      '15+ RM': null,
    };

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final reps = setRow.reps ?? 0;
      final weight = setRow.weight ?? 0.0;
      if (reps <= 0 || weight <= 0) continue;

      final b = bracket(reps);
      final current = result[b];
      if (current == null || weight > (current['weight'] as double)) {
        result[b] = {
          'exerciseName': setRow.exerciseNameSnapshot ?? '',
          'weight': weight,
          'reps': reps,
        };
      }
    }

    return result;
  }

  /// Returns top all-time PR entries across exercises, sorted by weight desc.
  /// Each entry: {exerciseName: String, weight: double, reps: int}
  Future<List<Map<String, dynamic>>> getAllTimeGlobalPRs({
    int limit = 10,
  }) async {
    final dbInstance = await database;

    final rows = await dbInstance.customSelect(
      '''
      SELECT
        s1.exercise_name_snapshot AS exerciseName,
        s1.weight                 AS weight,
        s1.reps                   AS reps
      FROM set_logs s1
      JOIN workout_logs wl ON wl.id = s1.workout_log_id
      WHERE s1.is_completed = 1
        AND s1.set_type != 'warmup'
        AND s1.weight > 0
        AND s1.reps  > 0
        AND wl.status = 'completed'
        AND s1.weight = (
          SELECT MAX(s2.weight)
          FROM set_logs s2
          WHERE s2.exercise_name_snapshot = s1.exercise_name_snapshot
            AND s2.is_completed = 1
            AND s2.set_type != 'warmup'
            AND s2.weight > 0
        )
      GROUP BY s1.exercise_name_snapshot
      ORDER BY s1.weight DESC
      LIMIT ?
      ''',
      variables: [drift.Variable.withInt(limit)],
    ).get();

    return rows
        .map(
          (row) => {
            'exerciseName': row.read<String>('exerciseName'),
            'weight': row.read<double>('weight'),
            'reps': row.read<int>('reps'),
          },
        )
        .toList();
  }

  /// Monthly volume buckets for the last [monthsBack] months.
  /// Each entry: {monthStart: DateTime, monthLabel: String, tonnage: double, setCount: int}
  Future<List<Map<String, dynamic>>> getMonthlyVolumeData({
    int monthsBack = 6,
  }) async {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final since = DateTime(
      firstOfThisMonth.year,
      firstOfThisMonth.month - (monthsBack - 1),
      1,
    );
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      )
      ..orderBy([
        drift.OrderingTerm(expression: dbInstance.workoutLogs.startTime),
      ]);

    final rows = await query.get();

    final Map<String, Map<String, dynamic>> monthMap = {};

    void ensureMonth(DateTime date) {
      final start = DateTime(date.year, date.month, 1);
      final key = '${start.year}-${start.month.toString().padLeft(2, '0')}';
      monthMap.putIfAbsent(
        key,
        () => {
          'monthStart': start,
          'monthLabel': '${start.month}/${start.year.toString().substring(2)}',
          'tonnage': 0.0,
          'setCount': 0,
        },
      );
    }

    for (int i = monthsBack - 1; i >= 0; i--) {
      ensureMonth(
        DateTime(firstOfThisMonth.year, firstOfThisMonth.month - i, 1),
      );
    }

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final monthStart = DateTime(
        logRow.startTime.year,
        logRow.startTime.month,
        1,
      );
      final key =
          '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';

      ensureMonth(logRow.startTime);

      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      monthMap[key]!['tonnage'] =
          (monthMap[key]!['tonnage'] as double) + weight * reps;
      monthMap[key]!['setCount'] = (monthMap[key]!['setCount'] as int) + 1;
    }

    final result = monthMap.values.toList()
      ..sort(
        (a, b) => (a['monthStart'] as DateTime).compareTo(
          b['monthStart'] as DateTime,
        ),
      );
    return result;
  }

  /// Finds exercises with the strongest PR momentum over the last [daysWindow] days.
  /// Compares best estimated 1RM in the recent window vs. the prior same-length window.
  /// Each entry: {exerciseName, previousBestE1rm, recentBestE1rm, improvementPct}
  Future<List<Map<String, dynamic>>> getNotablePrImprovements({
    int daysWindow = 30,
    int limit = 5,
  }) async {
    final now = DateTime.now();
    final recentStart = now.subtract(Duration(days: daysWindow));
    final previousStart = recentStart.subtract(Duration(days: daysWindow));
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              previousStart,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();

    final Map<String, double> previousBest = {};
    final Map<String, double> recentBest = {};

    double e1rm(double weight, int reps) => weight * (1 + (reps / 30.0));

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final name = (setRow.exerciseNameSnapshot ?? '').trim();
      if (name.isEmpty) continue;

      final value = e1rm(setRow.weight ?? 0.0, setRow.reps ?? 0);
      if (value <= 0) continue;

      final isRecent = !logRow.startTime.isBefore(recentStart);
      if (isRecent) {
        if (value > (recentBest[name] ?? 0.0)) recentBest[name] = value;
      } else {
        if (value > (previousBest[name] ?? 0.0)) previousBest[name] = value;
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final entry in recentBest.entries) {
      final name = entry.key;
      final recent = entry.value;
      final previous = previousBest[name] ?? 0.0;
      if (previous <= 0 || recent <= previous) continue;

      final improvementPct = ((recent - previous) / previous) * 100;
      result.add({
        'exerciseName': name,
        'previousBestE1rm': previous,
        'recentBestE1rm': recent,
        'improvementPct': improvementPct,
      });
    }

    result.sort(
      (a, b) => (b['improvementPct'] as double).compareTo(
        a['improvementPct'] as double,
      ),
    );
    return result.take(limit).toList();
  }
}
