part of '../workout_local_data_source.dart';

extension RoutinesQueries on WorkoutLocalDataSource {
  Future<List<Routine>> getAllRoutines() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(
      dbInstance.routines,
    )..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();

    return rows.map((r) => Routine(id: r.localId, name: r.name)).toList();
  }

  Stream<List<Routine>> watchAllRoutines() {
    final dbInstance = DatabaseHelper.instance.dbInstance;
    final query = dbInstance.select(dbInstance.routines)
      ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) {
      return rows.map((r) => Routine(id: r.localId, name: r.name)).toList();
    });
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

  // FIX: Added initialSetCount parameter.
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

    // Determine max order
    final maxOrderQuery = dbInstance.selectOnly(dbInstance.routineExercises)
      ..addColumns([dbInstance.routineExercises.orderIndex.max()])
      ..where(dbInstance.routineExercises.routineId.equals(routineUuid));
    final maxOrderResult = await maxOrderQuery.getSingle();
    final maxOrder =
        maxOrderResult.read(dbInstance.routineExercises.orderIndex.max()) ?? -1;

    // Insert RoutineExercise
    final reRow =
        await dbInstance.into(dbInstance.routineExercises).insertReturning(
              db.RoutineExercisesCompanion(
                routineId: drift.Value(routineUuid),
                exerciseId: drift.Value(exerciseUuid),
                orderIndex: drift.Value(maxOrder + 1),
              ),
            );

    // FIX: Dynamic number of sets instead of hardcoded 3.
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

    // Load exercise data for return value
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
    // OnDelete cascade in the DB definition should delete children.
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

    // 1. Load routine
    final routineRow = await (dbInstance.select(
      dbInstance.routines,
    )..where((tbl) => tbl.localId.equals(id)))
        .getSingleOrNull();

    if (routineRow == null) return null;

    // 2. Load RoutineExercises
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

      // 3. Load SetTemplates
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
              targetRir: t.targetRir, // <--- New
            ),
          )
          .toList();

      exercisesList.add(
        RoutineExercise(
          id: reData.localId,
          exercise: _mapExerciseToModel(exData),
          setTemplates: setTemplates,
          pauseSeconds: reData.pauseSeconds,
          notes: reData.notes,
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
        targetRir: drift.Value(setTemplate.targetRir), // <--- New
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
      // Delete
      await (dbInstance.delete(
        dbInstance.routineSetTemplates,
      )..where((tbl) => tbl.routineExerciseId.equals(reUuid)))
          .go();

      // Insert new
      for (final t in newTemplates) {
        await dbInstance.into(dbInstance.routineSetTemplates).insert(
              db.RoutineSetTemplatesCompanion(
                routineExerciseId: drift.Value(reUuid),
                setType: drift.Value(t.setType),
                targetReps: drift.Value(t.targetReps),
                targetWeight: drift.Value(t.targetWeight),
                targetRir: drift.Value(t.targetRir), // <--- New
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
      // Add exercise (creates default templates)
      final newRe = await addExerciseToRoutine(newRoutine.id!, re.exercise.id!);

      if (newRe != null) {
        // Overwrite templates with copied values
        await replaceSetTemplatesForExercise(newRe.id!, re.setTemplates);
        // Copy rest duration
        await updatePauseTime(newRe.id!, re.pauseSeconds);
        // Copy notes
        await updateRoutineExerciseNotes(newRe.id!, re.notes);
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

  Future<void> updateRoutineExerciseNotes(int routineExerciseId, String? notes) async {
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.routineExercises,
    )..where((tbl) => tbl.localId.equals(routineExerciseId)))
        .write(
      db.RoutineExercisesCompanion(notes: drift.Value(notes)),
    );
  }

  Future<void> saveWorkoutExerciseNote({
    required int workoutLogId,
    required String exerciseName,
    required String? notes,
  }) async {
    final dbInstance = await database;
    final workoutLogUuid = await _getUuidFromLocalId(
      dbInstance.workoutLogs,
      workoutLogId,
    );
    if (workoutLogUuid == null) return;

    // Resolve exercise uuid if exists
    final exRow = await (dbInstance.select(dbInstance.exercises)
          ..where(
            (tbl) =>
                tbl.nameDe.equals(exerciseName) |
                tbl.nameEn.equals(exerciseName),
          )
          ..limit(1))
        .getSingleOrNull();
    final exerciseUuid = exRow?.id;

    // Check if a note already exists for this exercise in this workout
    final existingRow = await (dbInstance.select(dbInstance.workoutExerciseLogs)
          ..where((tbl) =>
              tbl.workoutLogId.equals(workoutLogUuid) &
              tbl.exerciseNameSnapshot.equals(exerciseName))
          ..limit(1))
        .getSingleOrNull();

    final companion = db.WorkoutExerciseLogsCompanion(
      workoutLogId: drift.Value(workoutLogUuid),
      exerciseId: drift.Value(exerciseUuid),
      exerciseNameSnapshot: drift.Value(exerciseName),
      notes: drift.Value(notes),
    );

    if (existingRow != null) {
      await (dbInstance.update(dbInstance.workoutExerciseLogs)
            ..where((tbl) => tbl.localId.equals(existingRow.localId)))
          .write(companion);
    } else {
      await dbInstance.into(dbInstance.workoutExerciseLogs).insert(companion);
    }
  }

  Future<Map<String, String>> getWorkoutExerciseNotes(int workoutLogId) async {
    final dbInstance = await database;
    final workoutLogUuid = await _getUuidFromLocalId(
      dbInstance.workoutLogs,
      workoutLogId,
    );
    if (workoutLogUuid == null) return {};

    final rows = await (dbInstance.select(dbInstance.workoutExerciseLogs)
          ..where((tbl) => tbl.workoutLogId.equals(workoutLogUuid)))
        .get();

    return {
      for (final r in rows) r.exerciseNameSnapshot ?? '': r.notes ?? '',
    };
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
}
