import '../../data/database_helper.dart';
import '../../data/drift_database.dart' as db;
import '../../models/fluid_entry.dart';
import '../../models/measurement_session.dart';
import '../../models/workout_log.dart';
import '../models/export_models.dart';

// Nutrition labels often provide salt (NaCl) while platform schemas expect
// sodium; sodium is approximately salt / 2.5 by mass.
const double _saltToSodiumFactor = 2.5;
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
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'weight') return ExportMeasurementType.weight;
    if (normalized == 'body fat' ||
        normalized == 'body_fat' ||
        normalized == 'body fat %' ||
        normalized == 'bodyfat') {
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
      if (normalizedUnit == '%' || normalizedUnit == 'percent') {
        return value;
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
    final byBarcode = {for (final product in products) product.barcode: product};

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
    return rows
        .map(
          (row) => WorkoutLog(
            id: row.localId,
            routineName: row.routineNameSnapshot,
            startTime: row.startTime,
            endTime: row.endTime,
            notes: row.notes,
          ),
        )
        .toList(growable: false);
  }
}
