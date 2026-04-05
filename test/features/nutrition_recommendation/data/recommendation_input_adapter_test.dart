import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart'
    show AppDatabase, NutritionLogsCompanion, ProductsCompanion, Profile;
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_input_adapter.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/models/fluid_entry.dart';
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

      expect(high, greaterThan(low));
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
  });
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
