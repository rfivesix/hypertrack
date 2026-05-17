import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'drift_database.g.dart';

// --- Mixins for recurring columns ---

/// Guarantees the hybrid architecture:
/// - [localId]: Internal local ID for performance and local relations.
/// - [id]: UUID for sync and server communication.
mixin HybridId on Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
}

/// Standard metadata for sync logic.
mixin MetaColumns on Table {
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// --- Table definitions ---

// 1. Profiles
/// Table definition for user profiles.
class Profiles extends Table with HybridId, MetaColumns {
  TextColumn get username => text().nullable()();
  BoolColumn get isCoach => boolean().withDefault(const Constant(false))();
  TextColumn get visibility => text().withDefault(
        const Constant('private'),
      )(); // 'public', 'private', 'friends'
  DateTimeColumn get birthday => dateTime().nullable()();
  IntColumn get height => integer().nullable()(); // in cm
  TextColumn get gender => text().nullable()(); // 'male', 'female', 'diverse'
  // From old code: store profile image path
  TextColumn get profileImagePath => text().nullable()();
}

// 2. AppSettings
class AppSettings extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().references(Profiles, #id)();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get unitSystem => text().withDefault(const Constant('metric'))();

  // From old code: daily goals (previously in SharedPreferences, better kept here for sync)
  IntColumn get targetCalories => integer().withDefault(const Constant(2500))();
  IntColumn get targetProtein => integer().withDefault(const Constant(180))();
  IntColumn get targetCarbs => integer().withDefault(const Constant(250))();
  IntColumn get targetFat => integer().withDefault(const Constant(80))();
  IntColumn get targetWater => integer().withDefault(const Constant(3000))();
  IntColumn get targetSteps => integer().withDefault(const Constant(8000))();
}

// 3. Exercises
/// Table definition for exercises.
class Exercises extends Table with HybridId, MetaColumns {
  TextColumn get createdBy =>
      text().nullable()(); // Nullable for system exercises
  TextColumn get nameDe => text()();
  TextColumn get nameEn => text()();

  // From old code: descriptions and category were important for the UI
  TextColumn get descriptionDe => text().nullable()();
  TextColumn get descriptionEn => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get imagePath => text().nullable()();

  TextColumn get musclesPrimary => text().nullable()(); // JSON String
  TextColumn get musclesSecondary =>
      text().nullable()(); // JSON string (carried over from old code)

  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('user'))();

  IntColumn get usageCount => integer().withDefault(const Constant(0))();
}

// 4. Routines
class Routines extends Table with HybridId, MetaColumns {
  TextColumn get userId =>
      text().nullable()(); // Nullable for local use without login
  TextColumn get name => text()();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
}

// 5. RoutineExercises
class RoutineExercises extends Table with HybridId, MetaColumns {
  TextColumn get routineId =>
      text().references(Routines, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get pauseSeconds => integer().nullable()();
}

// 6. RoutineSetTemplates
class RoutineSetTemplates extends Table with HybridId, MetaColumns {
  TextColumn get routineExerciseId =>
      text().references(RoutineExercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get setType => text().withDefault(
        const Constant('normal'),
      )(); // normal, warmup, dropset, failure
  TextColumn get targetReps =>
      text().nullable()(); // String because values like "8-12" are possible
  RealColumn get targetWeight => real().nullable()();
  IntColumn get targetRir => integer().nullable()();
}

// 7. WorkoutLogs
/// Table definition for historical workout logs.
class WorkoutLogs extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().nullable()();
  TextColumn get routineId => text().nullable().references(Routines, #id)();

  // From old code: routine name as fallback if the routine was deleted
  TextColumn get routineNameSnapshot => text().nullable()();

  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('ongoing'))(); // ongoing, completed
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get notes => text().nullable()();
}

// 8. SetLogs
class SetLogs extends Table with HybridId, MetaColumns {
  TextColumn get workoutLogId =>
      text().references(WorkoutLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().nullable().references(Exercises, #id)();

  // From old code: fallback name if exercise was deleted or not mapped
  TextColumn get exerciseNameSnapshot => text().nullable()();

  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get rpe => integer().nullable()();
  IntColumn get rir => integer().nullable()();
  // From old code: fields that were essential.
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  IntColumn get restTimeSeconds => integer().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get logOrder => integer().withDefault(const Constant(0))();
  RealColumn get distance => real().nullable()(); // For cardio in the set
  IntColumn get durationSeconds => integer().nullable()(); // For cardio/static
  TextColumn get notes => text().nullable()();
}

// 9. CardioActivities (new in target schema)
class CardioActivities extends Table with HybridId, MetaColumns {
  TextColumn get workoutLogId =>
      text().references(WorkoutLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // Run, Bike, etc.
  RealColumn get distance => real().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get kcal => integer().nullable()();
  TextColumn get source => text().nullable()(); // Manual, AppleHealth, etc.
}

// 10. CardioSamples (new in target schema)
class CardioSamples extends Table with HybridId, MetaColumns {
  TextColumn get cardioActivityId =>
      text().references(CardioActivities, #id, onDelete: KeyAction.cascade)();
  TextColumn get dataType => text()(); // HeartRate, Speed, Elevation
  TextColumn get dataJson => text()(); // JSON array of samples
}

// 11. Products (replaces parts of food_entries / FoodItem)
/// Table definition for food products.
class Products extends Table with HybridId, MetaColumns {
  TextColumn get barcode => text().unique()(); // Eindeutiger Identifier
  TextColumn get name => text()();
  TextColumn get nameDe => text().nullable()();
  TextColumn get nameEn => text().nullable()();
  TextColumn get brand => text().nullable()();

  // Nutrients per 100g/ml
  IntColumn get calories => integer()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fat => real()();

  // Optional nutrients (carried over from old code)
  RealColumn get sugar => real().nullable()();
  RealColumn get fiber => real().nullable()();
  RealColumn get salt => real().nullable()();
  RealColumn get caffeine =>
      real().nullable()(); // Important for supplement logic
  RealColumn get caffeineMgPer100g =>
      real().named('caffeine_mg_per_100g').nullable()();
  TextColumn get ingredientsText => text().nullable()();
  TextColumn get ingredientsAnalysisTags => text().nullable()();
  TextColumn get additivesTags => text().nullable()();
  RealColumn get productQuantity => real().nullable()();
  TextColumn get productQuantityUnit => text().nullable()();
  BoolColumn get isFluid => boolean().withDefault(const Constant(false))();

  BoolColumn get isLiquid => boolean().withDefault(const Constant(false))();
  TextColumn get source =>
      text().withDefault(const Constant('user'))(); // off, user, base

  TextColumn get category => text().nullable()(); // <-- Insert this line

  IntColumn get usageCount => integer().withDefault(const Constant(0))();
}

// 12. NutritionLogs (replaces food_entries)
/// Table definition for nutrition consumption logs.
class NutritionLogs extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().nullable()();
  TextColumn get productId => text().nullable().references(Products, #id)();

  // From old code: barcode as fallback for migration/sync
  TextColumn get legacyBarcode => text().nullable()();

  DateTimeColumn get consumedAt => dateTime()();
  RealColumn get amount => real()(); // In grams or ml
  TextColumn get mealType =>
      text().withDefault(const Constant('Snack'))(); // Breakfast, Lunch, etc.
}

// 13. Supplements
class Supplements extends Table with HybridId, MetaColumns {
  TextColumn get code =>
      text().nullable().unique()(); // e.g., 'caffeine' for logic
  TextColumn get name => text()();
  RealColumn get dose => real()(); // Standard dose
  TextColumn get unit => text()(); // mg, g, ml, pill

  // From old code
  RealColumn get dailyGoal => real().nullable()();
  RealColumn get dailyLimit => real().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  BoolColumn get isTracked => boolean().withDefault(const Constant(true))();
}

// 14. SupplementLogs
class SupplementLogs extends Table with HybridId, MetaColumns {
  TextColumn get supplementId =>
      text().references(Supplements, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get takenAt => dateTime()();
  RealColumn get amount => real()(); // Amount actually consumed

  // Links (carried over from old code for auto logic for coffee, etc.)
  TextColumn get sourceNutritionLogId => text().nullable().references(
        NutritionLogs,
        #id,
        onDelete: KeyAction.setNull,
      )();
  // Reference to FluidLogs defined below
}

// --- Addition: FluidLogs (missing from target schema, but essential for FluidEntry) ---
class FluidLogs extends Table with HybridId, MetaColumns {
  DateTimeColumn get consumedAt => dateTime()();
  IntColumn get amountMl => integer()();
  TextColumn get name => text()(); // "Water", "Coke", etc.

  // Macros for fluids (carried over from old code)
  IntColumn get kcal => integer().nullable()();
  RealColumn get sugarPer100ml => real().nullable()();
  RealColumn get caffeinePer100ml => real().nullable()();
  // Link to NutritionLogs if it was a logged drink
  TextColumn get linkedNutritionLogId => text().nullable().references(
        NutritionLogs,
        #id,
        onDelete: KeyAction.cascade,
      )();
}

// 15. Measurements
class Measurements extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().nullable()();
  TextColumn get type => text()(); // weight, chest, etc.
  RealColumn get value => real()();
  TextColumn get unit => text()(); // kg, cm, % (carried over from old code)
  DateTimeColumn get date => dateTime()();

  // From old code: session concept (grouping measurements on the same day)
  // Resolve this by date here, but legacy_session_id helps with migration.
  IntColumn get legacySessionId => integer().nullable()();
}

// 16. Posts (Social)
class Posts extends Table with HybridId, MetaColumns {
  TextColumn get userId => text()();
  TextColumn get type => text()(); // workout_share, achievement
  TextColumn get referenceId => text().nullable()(); // Workout ID, etc.
  TextColumn get metadata => text().nullable()(); // JSON
  TextColumn get content => text().nullable()();
}

// 17. SocialInteractions
class SocialInteractions extends Table with HybridId, MetaColumns {
  TextColumn get postId =>
      text().references(Posts, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // like, comment
  TextColumn get content => text().nullable()(); // Kommentartext
}

class Meals extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().nullable()(); // For future multi-user logic
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
}

class MealItems extends Table with HybridId, MetaColumns {
  TextColumn get mealId =>
      text().references(Meals, #id, onDelete: KeyAction.cascade)();

  // Store either the barcode (legacy) or the product UUID.
  TextColumn get productBarcode => text().nullable()();
  TextColumn get productId => text().nullable().references(Products, #id)();

  IntColumn get quantityInGrams => integer()();
}

class FoodCategories extends Table {
  TextColumn get key => text()(); // z.B. "obst"
  TextColumn get nameDe => text().nullable()();
  TextColumn get nameEn => text().nullable()();
  TextColumn get emoji => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

class Favorites extends Table with MetaColumns {
  TextColumn get barcode => text()();
  // createdAt is now included via MetaColumns
  // updatedAt (modified_at) is now included
  // deletedAt is now included

  @override
  Set<Column> get primaryKey => {barcode};
}

// 18. DailyGoalsHistory (new for historical goals)
class DailyGoalsHistory extends Table with HybridId, MetaColumns {
  IntColumn get targetCalories => integer()();
  IntColumn get targetProtein => integer()();
  IntColumn get targetCarbs => integer()();
  IntColumn get targetFat => integer()();
  IntColumn get targetWater => integer()();
  IntColumn get targetSteps => integer().withDefault(const Constant(8000))();
  // createdAt serves here as the valid-from timestamp
}

// 19. SupplementSettingsHistory
class SupplementSettingsHistory extends Table with HybridId, MetaColumns {
  TextColumn get supplementId =>
      text().references(Supplements, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isTracked => boolean().withDefault(const Constant(true))();
  RealColumn get dose => real()();
  RealColumn get dailyGoal => real().nullable()();
  RealColumn get dailyLimit => real().nullable()();
  // createdAt serves as the valid-from timestamp
}

class HealthStepSegments extends Table with HybridId, MetaColumns {
  TextColumn get provider => text()();
  TextColumn get sourceId => text().nullable()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  IntColumn get stepCount => integer()();
  TextColumn get externalKey => text().unique()();
}

@DriftDatabase(
  tables: [
    Profiles,
    AppSettings,
    Exercises,
    Routines,
    RoutineExercises,
    RoutineSetTemplates,
    WorkoutLogs,
    SetLogs,
    CardioActivities,
    CardioSamples,
    Products,
    NutritionLogs,
    Supplements,
    SupplementLogs,
    FluidLogs, // Added
    Measurements,
    Posts,
    SocialInteractions,
    Meals,
    MealItems,
    FoodCategories,
    Favorites,
    DailyGoalsHistory,
    SupplementSettingsHistory,
    HealthStepSegments,
  ],
)

/// The central Drift database class for the application.
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createSleepPersistenceSchema(this);
          await customStatement('''
          CREATE TABLE IF NOT EXISTS health_export_records (
            local_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            id TEXT NOT NULL UNIQUE,
            platform TEXT NOT NULL,
            domain TEXT NOT NULL,
            idempotency_key TEXT NOT NULL,
            exported_at INTEGER NOT NULL,
            UNIQUE(platform, domain, idempotency_key)
          )
        ''');
          await _createPulsePersistenceSchema(this);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS exercises_usage_count_idx ON exercises (usage_count);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS products_usage_count_idx ON products (usage_count);',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(favorites);
            // Important: add the missing column.
            await m.addColumn(products, products.category);
          }
          // Migration V2 -> V3 (sync columns & RIR)
          if (from < 3) {
            // Add RIR to SetLogs
            await m.addColumn(setLogs, setLogs.rir);

            // Make favorites syncable (add missing columns)
            // MetaColumns adds: createdAt, updatedAt, deletedAt
            // Favorites already had barcode and createdAt manually before.
            // Only updatedAt and deletedAt need to be added.
            await m.addColumn(favorites, favorites.updatedAt);
            await m.addColumn(favorites, favorites.deletedAt);
          }
          if (from < 4) {
            await m.addColumn(profiles, profiles.birthday);
          }
          if (from < 5) {
            await m.addColumn(profiles, profiles.height);
            await m.addColumn(profiles, profiles.gender);
          }
          if (from < 6) {
            await m.createTable(dailyGoalsHistory);
          }
          if (from < 7) {
            await m.addColumn(supplements, supplements.isTracked);
            await m.createTable(supplementSettingsHistory);
          }
          if (from < 8) {
            await customStatement(
              'ALTER TABLE app_settings ADD COLUMN target_steps INTEGER NOT NULL DEFAULT 8000',
            );
            await customStatement(
              'ALTER TABLE daily_goals_history ADD COLUMN target_steps INTEGER NOT NULL DEFAULT 8000',
            );
            await customStatement('''
          CREATE TABLE IF NOT EXISTS health_step_segments (
            local_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            id TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            deleted_at INTEGER NULL,
            provider TEXT NOT NULL,
            source_id TEXT NULL,
            start_at INTEGER NOT NULL,
            end_at INTEGER NOT NULL,
            step_count INTEGER NOT NULL,
            external_key TEXT NOT NULL UNIQUE
          )
        ''');
          }
          if (from < 9) {
            await _createSleepPersistenceSchema(this);
          }
          if (from >= 9 && from < 10) {
            await customStatement(
              'ALTER TABLE sleep_nightly_analyses ADD COLUMN interruptions_count INTEGER NULL',
            );
            await customStatement(
              'ALTER TABLE sleep_nightly_analyses ADD COLUMN interruptions_wake_minutes INTEGER NULL',
            );
          }
          if (from >= 10 && from < 11) {
            await customStatement(
              'ALTER TABLE sleep_nightly_analyses ADD COLUMN score_completeness REAL NULL',
            );
            await customStatement(
              'ALTER TABLE sleep_nightly_analyses ADD COLUMN regularity_sri REAL NULL',
            );
            await customStatement(
              'ALTER TABLE sleep_nightly_analyses ADD COLUMN regularity_valid_days INTEGER NULL',
            );
            await customStatement(
              'ALTER TABLE sleep_nightly_analyses ADD COLUMN regularity_is_stable INTEGER NULL',
            );
          }
          if (from < 12) {
            await customStatement('''
          CREATE TABLE IF NOT EXISTS health_export_records (
            local_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            id TEXT NOT NULL UNIQUE,
            platform TEXT NOT NULL,
            domain TEXT NOT NULL,
            idempotency_key TEXT NOT NULL,
            exported_at INTEGER NOT NULL,
            UNIQUE(platform, domain, idempotency_key)
          )
        ''');
          }
          if (from < 13) {
            await _createPulsePersistenceSchema(this);
          }
          if (from < 14) {
            await customStatement(
              'ALTER TABLE products ADD COLUMN name_de TEXT NULL',
            );
            await customStatement(
              'ALTER TABLE products ADD COLUMN name_en TEXT NULL',
            );
            // Back-fill: copy existing name into name_de for base products
            // so they have a value until the next re-import.
            await customStatement(
              "UPDATE products SET name_de = name WHERE source = 'base'",
            );
          }
          if (from < 15) {
            await m.addColumn(exercises, exercises.usageCount);
            await m.addColumn(products, products.usageCount);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS exercises_usage_count_idx ON exercises (usage_count);',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS products_usage_count_idx ON products (usage_count);',
            );
          }
          if (from < 16) {
            // Defensive migration: Check if columns exist before adding them.
            final productsColumns =
                await customSelect('PRAGMA table_info(products)').get();
            final names =
                productsColumns.map((c) => c.read<String>('name')).toSet();

            if (!names.contains('caffeine_mg_per_100g')) {
              await m.addColumn(products, products.caffeineMgPer100g);
            }
            if (!names.contains('ingredients_text')) {
              await m.addColumn(products, products.ingredientsText);
            }
            if (!names.contains('ingredients_analysis_tags')) {
              await m.addColumn(products, products.ingredientsAnalysisTags);
            }
            if (!names.contains('additives_tags')) {
              await m.addColumn(products, products.additivesTags);
            }
            if (!names.contains('product_quantity')) {
              await m.addColumn(products, products.productQuantity);
            }
            if (!names.contains('product_quantity_unit')) {
              await m.addColumn(products, products.productQuantityUnit);
            }
            if (!names.contains('is_fluid')) {
              await m.addColumn(products, products.isFluid);
            }
          }
        },
      );
}

Future<void> _createPulsePersistenceSchema(GeneratedDatabase db) async {
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS pulse_hourly_aggregates (
      bucket_start_ms INTEGER NOT NULL PRIMARY KEY,
      bucket_end_ms INTEGER NOT NULL,
      sample_count INTEGER NOT NULL,
      min_bpm REAL NOT NULL,
      max_bpm REAL NOT NULL,
      sum_bpm REAL NOT NULL,
      first_sample_ms INTEGER NOT NULL,
      last_sample_ms INTEGER NOT NULL,
      source TEXT NOT NULL DEFAULT 'platform',
      aggregation_version INTEGER NOT NULL DEFAULT 1,
      updated_at_ms INTEGER NOT NULL
    )
  ''');
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_pulse_hourly_range ON pulse_hourly_aggregates(bucket_start_ms, bucket_end_ms)',
  );
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS pulse_aggregate_metadata (
      key TEXT NOT NULL PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at_ms INTEGER NOT NULL
    )
  ''');
}

/// Sleep persistence schema foundations.
///
/// This follows a strict three-layer storage architecture:
/// 1) raw imports (`sleep_raw_imports`) for archival/provenance/debugging,
/// 2) canonical normalized records (`sleep_canonical_*`),
/// 3) derived nightly outputs (`sleep_nightly_analyses`).
///
/// Versioning fields (`normalization_version`, `analysis_version`) are stored
/// on canonical/derived records to support deterministic recomputation.
Future<void> _createSleepPersistenceSchema(GeneratedDatabase db) async {
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS sleep_raw_imports (
      id TEXT NOT NULL PRIMARY KEY,
      source_platform TEXT NOT NULL,
      source_app_id TEXT NULL,
      source_confidence TEXT NULL,
      source_record_hash TEXT NOT NULL,
      import_status TEXT NOT NULL,
      error_code TEXT NULL,
      error_message TEXT NULL,
      imported_at INTEGER NOT NULL,
      payload_json TEXT NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
      updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
    )
  ''');

  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS sleep_canonical_sessions (
      id TEXT NOT NULL PRIMARY KEY,
      raw_import_id TEXT NULL REFERENCES sleep_raw_imports(id) ON DELETE SET NULL,
      source_platform TEXT NOT NULL,
      source_app_id TEXT NULL,
      source_confidence TEXT NULL,
      source_record_hash TEXT NOT NULL,
      normalization_version TEXT NOT NULL,
      session_type TEXT NOT NULL,
      started_at INTEGER NOT NULL,
      ended_at INTEGER NOT NULL,
      timezone TEXT NULL,
      imported_at INTEGER NOT NULL,
      normalized_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
      updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
    )
  ''');

  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS sleep_canonical_stage_segments (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sleep_canonical_sessions(id) ON DELETE CASCADE,
      source_platform TEXT NOT NULL,
      source_app_id TEXT NULL,
      source_confidence TEXT NULL,
      source_record_hash TEXT NOT NULL,
      normalization_version TEXT NOT NULL,
      stage TEXT NOT NULL,
      started_at INTEGER NOT NULL,
      ended_at INTEGER NOT NULL,
      imported_at INTEGER NOT NULL,
      normalized_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
      updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
    )
  ''');

  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS sleep_canonical_heart_rate_samples (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sleep_canonical_sessions(id) ON DELETE CASCADE,
      source_platform TEXT NOT NULL,
      source_app_id TEXT NULL,
      source_confidence TEXT NULL,
      source_record_hash TEXT NOT NULL,
      normalization_version TEXT NOT NULL,
      sampled_at INTEGER NOT NULL,
      bpm REAL NOT NULL,
      imported_at INTEGER NOT NULL,
      normalized_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
      updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
    )
  ''');

  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS sleep_nightly_analyses (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sleep_canonical_sessions(id) ON DELETE CASCADE,
      source_platform TEXT NOT NULL,
      source_app_id TEXT NULL,
      source_confidence TEXT NULL,
      source_record_hash TEXT NOT NULL,
      normalization_version TEXT NOT NULL,
      analysis_version TEXT NOT NULL,
      night_date TEXT NOT NULL,
      score REAL NULL,
      total_sleep_minutes INTEGER NULL,
      sleep_efficiency_pct REAL NULL,
      resting_heart_rate_bpm REAL NULL,
      interruptions_count INTEGER NULL,
      interruptions_wake_minutes INTEGER NULL,
      score_completeness REAL NULL,
      regularity_sri REAL NULL,
      regularity_valid_days INTEGER NULL,
      regularity_is_stable INTEGER NULL,
      analyzed_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
      updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
    )
  ''');

  // Optional physiological signals are planned as nullable scalar columns in
  // canonical/derived tables (e.g. HRV/SpO₂/resp/temp delta) in future
  // migrations instead of opaque blobs, except raw archival payload JSON.
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_raw_imports_imported_at ON sleep_raw_imports(imported_at)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_raw_imports_status_hash ON sleep_raw_imports(import_status, source_record_hash)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_sessions_range ON sleep_canonical_sessions(started_at, ended_at)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_sessions_hash ON sleep_canonical_sessions(source_record_hash)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_segments_session ON sleep_canonical_stage_segments(session_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_segments_range ON sleep_canonical_stage_segments(started_at, ended_at)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_hr_session_sampled ON sleep_canonical_heart_rate_samples(session_id, sampled_at)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_analyses_night ON sleep_nightly_analyses(night_date)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sleep_analyses_session ON sleep_nightly_analyses(session_id)',
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_hybrid.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}
