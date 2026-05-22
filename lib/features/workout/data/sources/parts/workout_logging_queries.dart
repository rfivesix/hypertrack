part of '../workout_local_data_source.dart';

extension WorkoutLoggingQueries on WorkoutLocalDataSource {
  /// Creates a new [WorkoutLog] and marks it as "ongoing".
  Future<WorkoutLog> startWorkout({String? routineName}) async {
    final dbInstance = await database;
    final now = DateTime.now();

    // Try to find routine UUID for linking (optional).
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

    // Increment usageCount for exercises used in this workout
    try {
      final logRow = await (dbInstance.select(dbInstance.workoutLogs)
            ..where((t) => t.localId.equals(workoutLogId)))
          .getSingle();

      final setLogsQuery =
          dbInstance.selectOnly(dbInstance.setLogs, distinct: true)
            ..addColumns([dbInstance.setLogs.exerciseId])
            ..where(dbInstance.setLogs.workoutLogId.equals(logRow.id))
            ..where(dbInstance.setLogs.exerciseId.isNotNull());

      final exerciseIds = (await setLogsQuery.get())
          .map((r) => r.read(dbInstance.setLogs.exerciseId))
          .whereType<String>()
          .toList();

      if (exerciseIds.isNotEmpty) {
        await dbInstance.customUpdate(
          'UPDATE exercises SET usage_count = usage_count + 1 WHERE id IN (${exerciseIds.map((_) => '?').join(',')})',
          variables:
              exerciseIds.map((id) => drift.Variable.withString(id)).toList(),
          updates: {dbInstance.exercises},
        );
      }
    } catch (e) {
      // Non-critical: don't fail finishWorkout if usageCount update fails
    }
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

    // Search for exercise UUID
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
      rir: drift.Value(setLog.rir), // Direct int now, perfect.
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

      // Increment usageCount for the exercise if linked
      if (exerciseUuid != null) {
        try {
          await dbInstance.customUpdate(
            'UPDATE exercises SET usage_count = usage_count + 1 WHERE id = ?',
            variables: [drift.Variable.withString(exerciseUuid)],
            updates: {dbInstance.exercises},
          );
        } catch (_) {
          // Non-critical
        }
      }

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

    return _mapWorkoutLogWithSets(logRow, setRows);
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
              setType: drift.Value(s.setType),
              // FIX: logOrder must also be updated so reordering is saved.
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
      rir: row.rir, // Use directly
    );
  }

  Future<void> deleteWorkoutLog(int logId) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(logId)))
        .go();
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    // Returns only completed logs (base info).
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

    return _loadWorkoutLogsWithSets(rows);
  }

  Stream<List<WorkoutLog>> watchFullWorkoutLogs() {
    final dbInstance = DatabaseHelper.instance.dbInstance;
    final query = dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]);
    return query.watch().asyncMap((rows) => _loadWorkoutLogsWithSets(rows));
  }

  Stream<List<WorkoutLog>> watchWorkoutLogsForDateRange(
      DateTime start, DateTime end) {
    final dbInstance = DatabaseHelper.instance.dbInstance;
    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.workoutLogs)
      ..where((tbl) =>
          tbl.startTime.isBetweenValues(effectiveStart, effectiveEnd) &
          tbl.status.equals('completed'))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.startTime,
              mode: drift.OrderingMode.desc,
            ),
      ]);
    return query.watch().asyncMap((rows) => _loadWorkoutLogsWithSets(rows));
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

    return _loadWorkoutLogsWithSets(rows);
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

  Stream<List<SetLog>> watchSetLogsForWorkout(int workoutLogId) async* {
    final dbInstance = DatabaseHelper.instance.dbInstance;
    final logRow = await (dbInstance.select(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(workoutLogId)))
        .getSingleOrNull();

    if (logRow == null) {
      yield [];
      return;
    }

    final query = dbInstance.select(dbInstance.setLogs)
      ..where((tbl) => tbl.workoutLogId.equals(logRow.id))
      ..orderBy([(t) => drift.OrderingTerm(expression: t.logOrder)]);
      
    yield* query.watch().map(
          (rows) => rows.map((r) => _mapSetLogToModel(r, workoutLogId)).toList(),
        );
  }

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
          // Check exercise mapping (name -> UUID).
          // Search for the exercise in the DB. If custom and present in the backup, it should already be imported.
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
    // Drift has no direct Dart-syntax path for this complex join + IS NULL check.
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

        // Find the new exercise UUID
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
            rir: r.rir, // Use directly
          ),
        )
        .toList();
  }

  Future<void> clearAllWorkoutData() async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      await dbInstance.delete(dbInstance.cardioSamples).go();
      await dbInstance.delete(dbInstance.cardioActivities).go();
      await dbInstance.delete(dbInstance.setLogs).go();
      await dbInstance.delete(dbInstance.workoutLogs).go();
      await dbInstance.delete(dbInstance.routineSetTemplates).go();
      await dbInstance.delete(dbInstance.routineExercises).go();
      await dbInstance.delete(dbInstance.routines).go();
      // Delete only custom exercises
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
}
