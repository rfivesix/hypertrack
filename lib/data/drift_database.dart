import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'drift_database.g.dart';

// --- MIXINS FÜR WIEDERKEHRENDE SPALTEN ---

/// Garantiert die Hybrid-Architektur:
/// - [localId]: Interne, lokale ID für Performance und lokale Relationen.
/// - [id]: UUID für Sync und Server-Kommunikation.
mixin HybridId on Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
}

/// Standard Meta-Daten für Sync-Logik
mixin MetaColumns on Table {
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// --- TABELLEN DEFINITIONEN ---

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
  // Aus altem Code: Profilbild-Pfad speichern
  TextColumn get profileImagePath => text().nullable()();
}

// 2. AppSettings
class AppSettings extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().references(Profiles, #id)();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get unitSystem => text().withDefault(const Constant('metric'))();

  // Aus altem Code: Tagesziele (bisher in SharedPreferences, besser hier aufgehoben für Sync)
  IntColumn get targetCalories => integer().withDefault(const Constant(2500))();
  IntColumn get targetProtein => integer().withDefault(const Constant(180))();
  IntColumn get targetCarbs => integer().withDefault(const Constant(250))();
  IntColumn get targetFat => integer().withDefault(const Constant(80))();
  IntColumn get targetWater => integer().withDefault(const Constant(3000))();
}

// 3. Exercises
/// Table definition for exercises.
class Exercises extends Table with HybridId, MetaColumns {
  TextColumn get createdBy => text().nullable()(); // Nullable wenn System-Übung
  TextColumn get nameDe => text()();
  TextColumn get nameEn => text()();

  // Aus altem Code: Beschreibungen und Kategorie waren wichtig für die UI
  TextColumn get descriptionDe => text().nullable()();
  TextColumn get descriptionEn => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get imagePath => text().nullable()();

  TextColumn get musclesPrimary => text().nullable()(); // JSON String
  TextColumn get musclesSecondary =>
      text().nullable()(); // JSON String (aus altem Code übernommen)

  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('user'))();
}

// 4. Routines
class Routines extends Table with HybridId, MetaColumns {
  TextColumn get userId =>
      text().nullable()(); // Nullable für lokale Nutzung ohne Login
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
      text().nullable()(); // String, da z.B. "8-12" möglich
  RealColumn get targetWeight => real().nullable()();
  IntColumn get targetRir => integer().nullable()();
}

// 7. WorkoutLogs
/// Table definition for historical workout logs.
class WorkoutLogs extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().nullable()();
  TextColumn get routineId => text().nullable().references(Routines, #id)();

  // Aus altem Code: Routine Name als Fallback, falls Routine gelöscht wurde
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

  // Aus altem Code: Fallback Name, falls Exercise gelöscht oder nicht gemappt
  TextColumn get exerciseNameSnapshot => text().nullable()();

  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get rpe => integer().nullable()();
  IntColumn get rir => integer().nullable()();
  // Aus altem Code: Felder die essenziell waren
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  IntColumn get restTimeSeconds => integer().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get logOrder => integer().withDefault(const Constant(0))();
  RealColumn get distance => real().nullable()(); // Für Cardio im Set
  IntColumn get durationSeconds =>
      integer().nullable()(); // Für Cardio/Statisch
  TextColumn get notes => text().nullable()();
}

// 9. CardioActivities (Neu laut Zielschema)
class CardioActivities extends Table with HybridId, MetaColumns {
  TextColumn get workoutLogId =>
      text().references(WorkoutLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // Run, Bike, etc.
  RealColumn get distance => real().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get kcal => integer().nullable()();
  TextColumn get source => text().nullable()(); // Manual, AppleHealth, etc.
}

// 10. CardioSamples (Neu laut Zielschema)
class CardioSamples extends Table with HybridId, MetaColumns {
  TextColumn get cardioActivityId =>
      text().references(CardioActivities, #id, onDelete: KeyAction.cascade)();
  TextColumn get dataType => text()(); // HeartRate, Speed, Elevation
  TextColumn get dataJson => text()(); // JSON Array der Samples
}

// 11. Products (Ersetzt Teile von food_entries / FoodItem)
/// Table definition for food products.
class Products extends Table with HybridId, MetaColumns {
  TextColumn get barcode => text().unique()(); // Eindeutiger Identifier
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();

  // Nährwerte pro 100g/ml
  IntColumn get calories => integer()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fat => real()();

  // Optionale Nährwerte (aus altem Code übernommen)
  RealColumn get sugar => real().nullable()();
  RealColumn get fiber => real().nullable()();
  RealColumn get salt => real().nullable()();
  RealColumn get caffeine => real().nullable()(); // Wichtig für Supp-Logik

  BoolColumn get isLiquid => boolean().withDefault(const Constant(false))();
  TextColumn get source =>
      text().withDefault(const Constant('user'))(); // off, user, base

  TextColumn get category => text().nullable()(); // <-- Diese Zeile einfügen
}

// 12. NutritionLogs (Ersetzt food_entries)
/// Table definition for nutrition consumption logs.
class NutritionLogs extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().nullable()();
  TextColumn get productId => text().nullable().references(Products, #id)();

  // Aus altem Code: Barcode als Fallback für Migration/Sync
  TextColumn get legacyBarcode => text().nullable()();

  DateTimeColumn get consumedAt => dateTime()();
  RealColumn get amount => real()(); // In Gramm oder ml
  TextColumn get mealType =>
      text().withDefault(const Constant('Snack'))(); // Breakfast, Lunch, etc.
}

// 13. Supplements
class Supplements extends Table with HybridId, MetaColumns {
  TextColumn get code =>
      text().nullable().unique()(); // z.B. 'caffeine' für Logik
  TextColumn get name => text()();
  RealColumn get dose => real()(); // Standard Dosis
  TextColumn get unit => text()(); // mg, g, ml, pill

  // Aus altem Code
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
  RealColumn get amount => real()(); // Tatsächlich genommene Menge

  // Verknüpfungen (Aus altem Code übernommen für Auto-Logik bei Kaffee etc.)
  TextColumn get sourceNutritionLogId => text().nullable().references(
    NutritionLogs,
    #id,
    onDelete: KeyAction.setNull,
  )();
  // Referenz auf FluidLogs unten definiert
}

// --- ZUSATZ: FluidLogs (Fehlte im Zielschema, aber essenziell für "FluidEntry") ---
class FluidLogs extends Table with HybridId, MetaColumns {
  DateTimeColumn get consumedAt => dateTime()();
  IntColumn get amountMl => integer()();
  TextColumn get name => text()(); // "Water", "Coke", etc.

  // Makros für Flüssigkeiten (Aus altem Code übernommen)
  IntColumn get kcal => integer().nullable()();
  RealColumn get sugarPer100ml => real().nullable()();
  RealColumn get caffeinePer100ml => real().nullable()();
  // Verknüpfung zu NutritionLogs falls es ein geloggtes Getränk war
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
  TextColumn get unit => text()(); // kg, cm, % (Aus altem Code übernommen)
  DateTimeColumn get date => dateTime()();

  // Aus altem Code: Session-Konzept (Gruppierung von Messungen am gleichen Tag)
  // Wir lösen das hier über das Datum, aber ein legacy_session_id hilft bei Migration
  IntColumn get legacySessionId => integer().nullable()();
}

// 16. Posts (Social)
class Posts extends Table with HybridId, MetaColumns {
  TextColumn get userId => text()();
  TextColumn get type => text()(); // workout_share, achievement
  TextColumn get referenceId => text().nullable()(); // ID des Workouts o.ä.
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
  TextColumn get userId => text().nullable()(); // Für spätere Multi-User Logik
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
}

class MealItems extends Table with HybridId, MetaColumns {
  TextColumn get mealId =>
      text().references(Meals, #id, onDelete: KeyAction.cascade)();

  // Wir speichern entweder den Barcode (Legacy) oder die Product-UUID
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
  // createdAt ist jetzt via MetaColumns dabei
  // updatedAt (modified_at) ist jetzt dabei
  // deletedAt ist jetzt dabei

  @override
  Set<Column> get primaryKey => {barcode};
}

// 18. DailyGoalsHistory (Neu für historische Ziele)
class DailyGoalsHistory extends Table with HybridId, MetaColumns {
  IntColumn get targetCalories => integer()();
  IntColumn get targetProtein => integer()();
  IntColumn get targetCarbs => integer()();
  IntColumn get targetFat => integer()();
  IntColumn get targetWater => integer()();
  // createdAt dient hier als "gültig ab" Zeitstempel
}

// 19. SupplementSettingsHistory
class SupplementSettingsHistory extends Table with HybridId, MetaColumns {
  TextColumn get supplementId =>
      text().references(Supplements, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isTracked => boolean().withDefault(const Constant(true))();
  RealColumn get dose => real()();
  RealColumn get dailyGoal => real().nullable()();
  RealColumn get dailyLimit => real().nullable()();
  // createdAt dient als "gültig ab" Zeitstempel
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
    FluidLogs, // Hinzugefügt
    Measurements,
    Posts,
    SocialInteractions,
    Meals,
    MealItems,
    FoodCategories,
    Favorites,
    DailyGoalsHistory,
    SupplementSettingsHistory,
  ],
)
/// The central Drift database class for the application.
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7; // Version auf 7 erhöhen für SupplementSettingsHistory und isTracked

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(favorites);
        // WICHTIG: Füge die fehlende Spalte hinzu!
        await m.addColumn(products, products.category);
      }
      // Migration V2 -> V3 (Sync-Spalten & RIR)
      if (from < 3) {
        // RIR zu SetLogs hinzufügen
        await m.addColumn(setLogs, setLogs.rir);

        // Favorites Sync-fähig machen (fehlende Spalten adden)
        // MetaColumns adds: createdAt, updatedAt, deletedAt
        // Favorites hatte vorher schon barcode und createdAt manuell.
        // Wir müssen nur updatedAt und deletedAt hinzufügen.
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
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_hybrid.sqlite'));
    return NativeDatabase(file);
  });
}
