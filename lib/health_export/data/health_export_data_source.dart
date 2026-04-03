import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../data/database_helper.dart';
import '../../data/drift_database.dart' as db;
import '../../models/fluid_entry.dart';
import '../../models/measurement_session.dart';
import '../../models/set_log.dart';
import '../../models/workout_log.dart';
import '../models/export_models.dart';

// Nutrition labels often provide salt (NaCl) while platform schemas expect
// sodium; sodium is approximately salt / 2.5 by mass.
const double _saltToSodiumFactor = 2.5;
const bool _debugAndroidHealthExport = true;
const double _bodyFatMinPercent = 0;
const double _bodyFatMaxPercent = 100;
const List<String> _strengthWorkoutKeywords = <String>[
  'strength',
  'push',
  'pull',
  'leg',
  'gym',
];

class HealthExportPayload {
  const HealthExportPayload({
    required this.measurements,
    required this.nutrition,
    required this.hydration,
    required this.workouts,
  });

  final List<ExportMeasurementRecord> measurements;
  final List<ExportNutritionRecord> nutrition;
  final List<ExportHydrationRecord> hydration;
  final List<ExportWorkoutRecord> workouts;
}

class HealthExportDataSource {
  HealthExportDataSource({
    DatabaseHelper? databaseHelper,
  }) : _db = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<HealthExportPayload> loadPayload({int lookbackDays = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: lookbackDays));

    final measurements = await _buildMeasurements(start: start, end: now);
    final nutrition = await _buildNutrition(start: start, end: now);
    final hydration = await _buildHydration(start: start, end: now);
    final workouts = await _buildWorkouts(start: start, end: now);

    return HealthExportPayload(
      measurements: measurements,
      nutrition: nutrition,
      hydration: hydration,
      workouts: workouts,
    );
  }

  Future<List<ExportMeasurementRecord>> _buildMeasurements({
    required DateTime start,
    required DateTime end,
  }) async {
    final sessions = await _db.getMeasurementSessions();
    final records = <ExportMeasurementRecord>[];
    for (final session in sessions) {
      if (session.timestamp.isBefore(start) || session.timestamp.isAfter(end)) {
        continue;
      }
      records.addAll(_mapSessionMeasurements(session));
    }
    return records;
  }

  List<ExportMeasurementRecord> _mapSessionMeasurements(MeasurementSession s) {
    final records = <ExportMeasurementRecord>[];
    for (final measurement in s.measurements) {
      final mappedType = _mapMeasurementType(measurement.type);
      if (mappedType == null) continue;
      final normalizedValue = _normalizeMeasurementValue(
        type: mappedType,
        unit: measurement.unit,
        value: measurement.value,
      );
      if (mappedType == ExportMeasurementType.bodyFatPercentage) {
        _logBodyFatExport(
          sourceMeasurementType: measurement.type,
          rawValue: measurement.value,
          rawUnit: measurement.unit,
          normalizedValue: normalizedValue,
        );
      }
      if (normalizedValue == null) continue;
      final localId = measurement.id;
      if (localId == null) continue;
      records.add(
        ExportMeasurementRecord(
          idempotencyKey: 'measurement:$localId',
          timestampUtc: s.timestamp.toUtc(),
          type: mappedType,
          value: normalizedValue,
        ),
      );
    }
    return records;
  }

  ExportMeasurementType? _mapMeasurementType(String raw) {
    final normalized = _normalizeMeasurementType(raw);
    if (normalized == 'weight' || normalized == 'bodyweight') {
      return ExportMeasurementType.weight;
    }
    if (normalized == 'bodyfat' ||
        normalized == 'bodyfatpercent' ||
        normalized == 'bodyfatpercentage' ||
        normalized == 'fatpercent') {
      return ExportMeasurementType.bodyFatPercentage;
    }
    if (normalized == 'bmi') return ExportMeasurementType.bmi;
    return null;
  }

  double? _normalizeMeasurementValue({
    required ExportMeasurementType type,
    required String unit,
    required double value,
  }) {
    if (type == ExportMeasurementType.weight) {
      final normalizedUnit = unit.trim().toLowerCase();
      if (normalizedUnit == 'kg') return value;
      if (normalizedUnit == 'lbs' || normalizedUnit == 'lb') {
        return value * 0.45359237;
      }
      return null;
    }

    if (type == ExportMeasurementType.bodyFatPercentage) {
      final normalizedUnit = unit.trim().toLowerCase();
      if (normalizedUnit == '%' ||
          normalizedUnit == 'percent' ||
          normalizedUnit == 'percentage') {
        return (value >= _bodyFatMinPercent && value <= _bodyFatMaxPercent)
            ? value
            : null;
      }
      if (normalizedUnit == 'fraction' || normalizedUnit == 'ratio') {
        final percent = value * 100;
        return (percent >= _bodyFatMinPercent && percent <= _bodyFatMaxPercent)
            ? percent
            : null;
      }
      return null;
    }

    if (type == ExportMeasurementType.bmi) {
      return value;
    }

    return null;
  }

  Future<List<ExportNutritionRecord>> _buildNutrition({
    required DateTime start,
    required DateTime end,
  }) async {
    final entries = await _db.getEntriesForDateRange(start, end);
    if (entries.isEmpty) return const <ExportNutritionRecord>[];

    final barcodes = entries.map((entry) => entry.barcode).toSet().toList();
    final products = await _loadProductsByBarcode(barcodes);
    final byBarcode = {
      for (final product in products) product.barcode: product
    };

    final records = <ExportNutritionRecord>[];
    for (final entry in entries) {
      final product = byBarcode[entry.barcode];
      if (product == null) continue;
      if (entry.id == null) continue;
      final factor = entry.quantityInGrams / 100.0;
      // Nutritional labeling commonly uses salt; sodium = salt / 2.5.
      final sodium = ((product.salt ?? 0) > 0
          ? (product.salt! / _saltToSodiumFactor)
          : null);
      final record = ExportNutritionRecord(
        idempotencyKey: 'nutrition_entry:${entry.id}',
        timestampUtc: entry.timestamp.toUtc(),
        caloriesKcal: product.calories * factor,
        proteinGrams: product.protein * factor,
        carbsGrams: product.carbs * factor,
        fatGrams: product.fat * factor,
        fiberGrams: product.fiber == null ? null : product.fiber! * factor,
        sugarGrams: product.sugar == null ? null : product.sugar! * factor,
        sodiumGrams: sodium == null ? null : sodium * factor,
      );
      if (record.hasAnyValue) {
        records.add(record);
      }
    }
    return records;
  }

  Future<List<ExportHydrationRecord>> _buildHydration({
    required DateTime start,
    required DateTime end,
  }) async {
    final entries = await _db.getFluidEntriesForDateRange(start, end);
    return entries
        .where((entry) => entry.id != null)
        .map(_mapHydration)
        .toList(growable: false);
  }

  ExportHydrationRecord _mapHydration(FluidEntry entry) {
    final id = entry.id;
    if (id == null) {
      throw StateError('Hydration entry is missing persistent id');
    }
    return ExportHydrationRecord(
      idempotencyKey: 'hydration_entry:$id',
      timestampUtc: entry.timestamp.toUtc(),
      volumeLiters: entry.quantityInMl / 1000.0,
    );
  }

  Future<List<ExportWorkoutRecord>> _buildWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    final workouts = await _loadCompletedWorkoutLogs(start: start, end: end);
    return workouts
        .where(
          (workout) =>
              workout.endTime != null &&
              !(workout.endTime!.toUtc().isAtSameMomentAs(
                    workout.startTime.toUtc(),
                  )),
        )
        .map(_mapWorkout)
        .toList(growable: false);
  }

  ExportWorkoutRecord _mapWorkout(WorkoutLog workout) {
    final id = workout.id;
    if (id == null) {
      throw StateError('Workout session is missing persistent id');
    }
    return ExportWorkoutRecord(
      idempotencyKey: 'workout_session:$id',
      startUtc: workout.startTime.toUtc(),
      endUtc: (workout.endTime ?? workout.startTime).toUtc(),
      workoutType: _mapWorkoutType(workout),
      title: workout.routineName,
      notes: _buildWorkoutSummaryNotes(workout),
    );
  }

  ExportWorkoutType _mapWorkoutType(WorkoutLog workout) {
    final text =
        '${workout.routineName ?? ''} ${workout.notes ?? ''}'.toLowerCase();
    if (text.contains('run')) return ExportWorkoutType.running;
    if (text.contains('walk')) return ExportWorkoutType.walking;
    if (text.contains('cycle') || text.contains('bike')) {
      return ExportWorkoutType.cycling;
    }
    if (text.contains('yoga')) return ExportWorkoutType.yoga;
    if (_strengthWorkoutKeywords.any(text.contains)) {
      return ExportWorkoutType.strength;
    }
    return ExportWorkoutType.strength;
  }

  Future<List<db.Product>> _loadProductsByBarcode(List<String> barcodes) async {
    if (barcodes.isEmpty) return const <db.Product>[];
    final dbInstance = await _db.database;
    final rows = await (dbInstance.select(
      dbInstance.products,
    )..where((tbl) => tbl.barcode.isIn(barcodes)))
        .get();
    return rows;
  }

  String _normalizeMeasurementType(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  void _logBodyFatExport({
    required String sourceMeasurementType,
    required double rawValue,
    required String rawUnit,
    required double? normalizedValue,
  }) {
    if (!_debugAndroidHealthExport) return;
    developer.log(
      'BodyFat sourceType=$sourceMeasurementType raw=$rawValue$rawUnit normalizedPercent=$normalizedValue',
      name: 'HealthExport.Android',
    );
  }

  Future<List<WorkoutLog>> _loadCompletedWorkoutLogs({
    required DateTime start,
    required DateTime end,
  }) async {
    final dbInstance = await _db.database;
    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.startTime.isBetweenValues(effectiveStart, effectiveEnd) &
                tbl.status.equals('completed'),
          ))
        .get();

    if (rows.isEmpty) return const <WorkoutLog>[];

    final workoutIds = rows.map((row) => row.id).toList(growable: false);
    final setRows = await (dbInstance.select(dbInstance.setLogs)
          ..where((tbl) => tbl.workoutLogId.isIn(workoutIds))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.logOrder),
            (tbl) => OrderingTerm(expression: tbl.localId),
          ]))
        .get();

    final setsByWorkoutId = <String, List<SetLog>>{};
    final workoutLocalIdByUuid = <String, int>{
      for (final row in rows) row.id: row.localId,
    };
    for (final setRow in setRows) {
      final localWorkoutId = workoutLocalIdByUuid[setRow.workoutLogId];
      if (localWorkoutId == null) continue;
      final setLog = SetLog(
        id: setRow.localId,
        workoutLogId: localWorkoutId,
        exerciseName: (setRow.exerciseNameSnapshot ?? '').trim().isEmpty
            ? 'Unknown'
            : setRow.exerciseNameSnapshot!.trim(),
        setType: setRow.setType,
        weightKg: setRow.weight,
        reps: setRow.reps,
        restTimeSeconds: setRow.restTimeSeconds,
        isCompleted: setRow.isCompleted,
        log_order: setRow.logOrder,
        notes: setRow.notes,
        distanceKm: setRow.distance,
        durationSeconds: setRow.durationSeconds,
        rpe: setRow.rpe,
        rir: setRow.rir,
      );
      setsByWorkoutId
          .putIfAbsent(setRow.workoutLogId, () => <SetLog>[])
          .add(setLog);
    }

    return rows
        .map(
          (row) => WorkoutLog(
            id: row.localId,
            routineName: row.routineNameSnapshot,
            startTime: row.startTime,
            endTime: row.endTime,
            notes: row.notes,
            sets: setsByWorkoutId[row.id] ?? const <SetLog>[],
          ),
        )
        .toList(growable: false);
  }

  String? _buildWorkoutSummaryNotes(WorkoutLog workout) {
    if (workout.sets.isEmpty) return null;
    final linesByExercise = <String, List<String>>{};
    final exerciseOrder = <String>[];

    for (final set in workout.sets) {
      final name = set.exerciseName.trim();
      if (name.isEmpty) continue;
      final weight = set.weightKg;
      final reps = set.reps;
      if (weight == null || reps == null) continue;
      final setText =
          '${_setTypeAbbreviation(set.setType)} ${_formatWeightKg(weight)}kg x $reps';
      final exerciseSets = linesByExercise.putIfAbsent(name, () {
        exerciseOrder.add(name);
        return <String>[];
      });
      exerciseSets.add(setText);
    }

    final lines = <String>[];
    for (final exerciseName in exerciseOrder) {
      final sets = linesByExercise[exerciseName];
      if (sets == null || sets.isEmpty) continue;
      lines.add('$exerciseName — ${sets.join(', ')}');
    }

    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  String _setTypeAbbreviation(String rawSetType) {
    final normalized = rawSetType.trim().toLowerCase();
    if (normalized == 'warmup') return 'W';
    if (normalized == 'failure') return 'F';
    if (normalized == 'dropset' || normalized == 'drop_set') return 'D';
    return 'S';
  }

  String _formatWeightKg(double weightKg) {
    final rounded = double.parse(weightKg.toStringAsFixed(3));
    if ((rounded - rounded.roundToDouble()).abs() < 0.0001) {
      return rounded.round().toString();
    }
    return rounded
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
