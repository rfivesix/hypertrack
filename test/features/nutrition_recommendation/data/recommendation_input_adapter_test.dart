import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart'
    show AppDatabase, NutritionLogsCompanion, ProductsCompanion, Profile;
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_input_adapter.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/models/fluid_entry.dart';
import 'package:hypertrack/models/measurement.dart';
import 'package:hypertrack/models/measurement_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationInputAdapter', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late RecommendationInputAdapter adapter;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      adapter = RecommendationInputAdapter(databaseHelper: dbHelper);
    });

    tearDown(() async {
      await database.close();
    });

    test(
        'buildInput uses productId first, falls back to barcode, merges fluid kcal, and flags unresolved rows',
        () async {
      final byIdProduct =
          await database.into(database.products).insertReturning(
                const ProductsCompanion(
                  barcode: drift.Value('id-product'),
                  name: drift.Value('ID Product'),
                  calories: drift.Value(220),
                  protein: drift.Value(10),
                  carbs: drift.Value(20),
                  fat: drift.Value(5),
                  source: drift.Value('base'),
                ),
              );
      await database.into(database.products).insertReturning(
            const ProductsCompanion(
              barcode: drift.Value('barcode-product'),
              name: drift.Value('Barcode Product'),
              calories: drift.Value(300),
              protein: drift.Value(10),
              carbs: drift.Value(20),
              fat: drift.Value(5),
              source: drift.Value('base'),
            ),
          );

      final day = DateTime(2026, 4, 5);

      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              productId: drift.Value(byIdProduct.id),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 8, 0)),
              amount: const drift.Value(100.0),
              mealType: const drift.Value('mealtypeBreakfast'),
            ),
          );
      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              legacyBarcode: const drift.Value('barcode-product'),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 13, 0)),
              amount: const drift.Value(50.0),
              mealType: const drift.Value('mealtypeLunch'),
            ),
          );
      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              productId: drift.Value(byIdProduct.id),
              legacyBarcode: const drift.Value('barcode-product'),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 18, 0)),
              amount: const drift.Value(100.0),
              mealType: const drift.Value('mealtypeDinner'),
            ),
          );
      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              legacyBarcode: const drift.Value('missing-product'),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 19, 0)),
              amount: const drift.Value(100.0),
              mealType: const drift.Value('mealtypeDinner'),
            ),
          );
      await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: DateTime(2026, 4, 5, 20, 0),
          quantityInMl: 330,
          name: 'Soda',
          kcal: 80,
        ),
      );

      final input = await adapter.buildInput(now: day);

      expect(input.intakeLoggedDays, 1);
      expect(input.avgLoggedCalories, closeTo(670.0, 0.001));
      expect(input.qualityFlags, contains('unresolved_food_calories'));
    });

    test('estimate prior differentiates same bodyweight by body-fat percent',
        () {
      final profile = _profile(
        birthday: DateTime(1992, 3, 10),
        height: 180,
        gender: 'male',
      );

      final leaner =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 95,
        bodyFatPercent: 15,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 2,
        targetSteps: 8000,
        now: DateTime(2026, 4, 5),
      );
      final higherBodyFat =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 95,
        bodyFatPercent: 30,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 2,
        targetSteps: 8000,
        now: DateTime(2026, 4, 5),
      );

      expect(leaner, greaterThan(higherBodyFat));
    });

    test('estimate prior differentiates same profile by activity level', () {
      final profile = _profile(
        birthday: DateTime(1994, 7, 1),
        height: 178,
        gender: 'female',
      );

      final low = RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 75,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.low,
        averageCompletedWorkoutsPerWeek: 0.5,
        targetSteps: 6000,
        now: DateTime(2026, 4, 5),
      );
      final high = RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 75,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.high,
        averageCompletedWorkoutsPerWeek: 4,
        targetSteps: 11000,
        now: DateTime(2026, 4, 5),
      );
      final veryHigh =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 75,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.veryHigh,
        averageCompletedWorkoutsPerWeek: 4,
        targetSteps: 11000,
        now: DateTime(2026, 4, 5),
      );

      expect(high, greaterThan(low));
      expect(veryHigh, greaterThan(high));
    });

    test('estimate prior falls back stably when body-fat is missing', () {
      final profile = _profile(
        birthday: DateTime(1990, 1, 20),
        height: 182,
        gender: 'male',
      );

      final missingBodyFat =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 88,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 2,
        targetSteps: 9000,
        now: DateTime(2026, 4, 5),
      );
      final invalidBodyFat =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 88,
        bodyFatPercent: 0,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 2,
        targetSteps: 9000,
        now: DateTime(2026, 4, 5),
      );

      expect(missingBodyFat, invalidBodyFat);
    });

    test('estimate prior increases with extra cardio hours option', () {
      final profile = _profile(
        birthday: DateTime(1992, 3, 10),
        height: 180,
        gender: 'male',
      );

      final baseline =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 82,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        averageCompletedWorkoutsPerWeek: 2,
        targetSteps: 8000,
        now: DateTime(2026, 4, 5),
      );
      final higherCardio =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: profile,
        currentWeightKg: 82,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h7Plus,
        averageCompletedWorkoutsPerWeek: 2,
        targetSteps: 8000,
        now: DateTime(2026, 4, 5),
      );

      expect(higherCardio, greaterThan(baseline));
    });

    test('buildInput uses recent average actual steps over target steps',
        () async {
      final now = DateTime(2026, 4, 5, 12, 0);
      await dbHelper.saveUserProfile(
        name: 'Alex',
        birthday: DateTime(1994, 1, 1),
        height: 178,
        gender: 'male',
      );
      await dbHelper.saveUserGoals(
        calories: 2400,
        protein: 170,
        carbs: 260,
        fat: 75,
        water: 3000,
        steps: 15000,
      );
      for (var offset = 0; offset < 3; offset++) {
        await _insertStepTotalForDay(
          dbHelper,
          DateTime(2026, 4, 5).subtract(Duration(days: offset)),
          6000,
        );
      }
      final persistedProfile = _profile(
        birthday: DateTime(1994, 1, 1),
        height: 178,
        gender: 'male',
      );

      final input = await adapter.buildInput(now: now, rollingWindowDays: 21);

      final expectedWithActual =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: persistedProfile,
        currentWeightKg: 75,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 0,
        targetSteps: 15000,
        recentAverageSteps: 6000,
        now: now,
      );
      final expectedTargetFallback =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: persistedProfile,
        currentWeightKg: 75,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 0,
        targetSteps: 15000,
        recentAverageSteps: null,
        now: now,
      );

      expect(input.priorMaintenanceCalories, expectedWithActual);
      expect(input.priorMaintenanceCalories, isNot(expectedTargetFallback));
    });

    test('buildInput falls back to target steps when actual steps are absent',
        () async {
      final now = DateTime(2026, 4, 5, 12, 0);
      await dbHelper.saveUserProfile(
        name: 'Alex',
        birthday: DateTime(1994, 1, 1),
        height: 178,
        gender: 'male',
      );
      await dbHelper.saveUserGoals(
        calories: 2400,
        protein: 170,
        carbs: 260,
        fat: 75,
        water: 3000,
        steps: 12000,
      );
      final persistedProfile = _profile(
        birthday: DateTime(1994, 1, 1),
        height: 178,
        gender: 'male',
      );

      final input = await adapter.buildInput(now: now, rollingWindowDays: 21);

      final expected =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: persistedProfile,
        currentWeightKg: 75,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 0,
        targetSteps: 12000,
        recentAverageSteps: null,
        now: now,
      );

      expect(input.priorMaintenanceCalories, expected);
    });

    test(
        'buildInput falls back to default steps when target and actual are absent',
        () async {
      final now = DateTime(2026, 4, 5, 12, 0);

      final input = await adapter.buildInput(now: now, rollingWindowDays: 21);

      final expected =
          RecommendationInputAdapter.estimatePriorMaintenanceCalories(
        profile: null,
        currentWeightKg: 75,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        averageCompletedWorkoutsPerWeek: 0,
        targetSteps: null,
        recentAverageSteps: null,
        now: now,
      );

      expect(input.priorMaintenanceCalories, expected);
    });

    test('buildInput returns null slope when insufficient weight data exists',
        () async {
      final input = await adapter.buildInput(now: DateTime(2026, 4, 5));
      expect(input.smoothedWeightSlopeKgPerWeek, isNull);
    });

    test('buildInput returns negative slope for monotonic downward weights',
        () async {
      final endDay = DateTime(2026, 4, 5);
      for (var i = 0; i < 7; i++) {
        final day = endDay.subtract(Duration(days: 6 - i));
        await _insertWeightForDay(dbHelper, day, 90.0 - (i * 0.4));
      }

      final input = await adapter.buildInput(now: endDay);
      expect(input.smoothedWeightSlopeKgPerWeek, isNotNull);
      expect(input.smoothedWeightSlopeKgPerWeek!, lessThan(0));
    });

    test(
        'buildInput trend slope uses regression over smoothed series (not endpoint-only)',
        () async {
      final endDay = DateTime(2026, 4, 5);
      final values = <double>[90, 84, 83, 82, 81, 80, 88];
      for (var i = 0; i < values.length; i++) {
        final day = endDay.subtract(Duration(days: values.length - 1 - i));
        await _insertWeightForDay(dbHelper, day, values[i]);
      }

      final input = await adapter.buildInput(now: endDay);
      final smoothed = _ewma(values, alpha: 0.35);
      final expectedRegressionSlope = _regressionSlopeKgPerWeek(smoothed);
      final endpointSlope = _endpointSlopeKgPerWeek(smoothed);

      expect(input.smoothedWeightSlopeKgPerWeek, isNotNull);
      expect(
        input.smoothedWeightSlopeKgPerWeek!,
        closeTo(expectedRegressionSlope, 1e-9),
      );
      expect(
        (input.smoothedWeightSlopeKgPerWeek! - endpointSlope).abs(),
        greaterThan(0.5),
      );
    });
  });
}

Future<void> _insertWeightForDay(
  DatabaseHelper dbHelper,
  DateTime day,
  double kg,
) {
  return dbHelper.insertMeasurementSession(
    MeasurementSession(
      timestamp: DateTime(day.year, day.month, day.day, 7, 0),
      measurements: [
        Measurement(
          sessionId: 0,
          type: 'weight',
          value: kg,
          unit: 'kg',
        ),
      ],
    ),
  );
}

Future<void> _insertStepTotalForDay(
  DatabaseHelper dbHelper,
  DateTime day,
  int totalSteps,
) async {
  final firstHalf = totalSteps ~/ 2;
  final secondHalf = totalSteps - firstHalf;
  final startA = DateTime(day.year, day.month, day.day, 8, 0).toUtc();
  final endA = DateTime(day.year, day.month, day.day, 9, 0).toUtc();
  final startB = DateTime(day.year, day.month, day.day, 18, 0).toUtc();
  final endB = DateTime(day.year, day.month, day.day, 19, 0).toUtc();

  await dbHelper.upsertHealthStepSegments([
    {
      'provider': 'apple_healthkit',
      'sourceId': 'test-source',
      'startAt': startA.toIso8601String(),
      'endAt': endA.toIso8601String(),
      'stepCount': firstHalf,
      'externalKey': 'steps-${day.toIso8601String()}-a',
    },
    {
      'provider': 'apple_healthkit',
      'sourceId': 'test-source',
      'startAt': startB.toIso8601String(),
      'endAt': endB.toIso8601String(),
      'stepCount': secondHalf,
      'externalKey': 'steps-${day.toIso8601String()}-b',
    },
  ]);
}

List<double> _ewma(List<double> source, {required double alpha}) {
  if (source.isEmpty) return const [];
  final result = <double>[];
  var previous = source.first;
  for (final value in source) {
    final next = (alpha * value) + ((1 - alpha) * previous);
    result.add(next);
    previous = next;
  }
  return result;
}

double _regressionSlopeKgPerWeek(List<double> values) {
  if (values.length < 2) return 0;
  final count = values.length;
  final xValues = List<double>.generate(count, (index) => index.toDouble());
  final meanX = xValues.fold<double>(0.0, (sum, value) => sum + value) / count;
  final meanY = values.fold<double>(0.0, (sum, value) => sum + value) / count;
  var numerator = 0.0;
  var denominator = 0.0;
  for (var i = 0; i < count; i++) {
    final xDelta = xValues[i] - meanX;
    final yDelta = values[i] - meanY;
    numerator += xDelta * yDelta;
    denominator += xDelta * xDelta;
  }
  return denominator <= 0 ? 0 : (numerator / denominator) * 7;
}

double _endpointSlopeKgPerWeek(List<double> values) {
  if (values.length < 2) return 0;
  return ((values.last - values.first) / (values.length - 1)) * 7;
}

Profile _profile({
  required DateTime birthday,
  required int height,
  required String gender,
}) {
  return Profile(
    localId: 1,
    id: 'p1',
    username: 'User',
    isCoach: false,
    visibility: 'private',
    birthday: birthday,
    height: height,
    gender: gender,
    profileImagePath: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    deletedAt: null,
  );
}
