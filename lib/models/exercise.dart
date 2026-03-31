// lib/models/exercise.dart
import 'dart:convert' show jsonDecode, jsonEncode;

/// Represents a physical exercise in the system.
///
/// Contains information about the exercise name, description, category,
/// and the muscles targeted (primary and secondary).
class Exercise {
  /// Unique identifier for the exercise.
  ///
  /// Can be null if the exercise is newly created and not yet saved to the database.
  final int? id; // optional für neu angelegte Datensätze

  /// The name of the exercise in German.
  final String nameDe;

  /// The name of the exercise in English.
  final String nameEn;

  /// A detailed description of the exercise in German.
  final String descriptionDe;

  /// A detailed description of the exercise in English.
  final String descriptionEn;

  /// The category of the exercise (e.g., "Strength", "Cardio").
  final String categoryName;

  /// An optional path to an image representing the exercise.
  final String? imagePath;

  /// A list of primary muscles targeted by this exercise.
  final List<String> primaryMuscles;

  /// A list of secondary muscles targeted by this exercise.
  final List<String> secondaryMuscles;

  /// Creates a new [Exercise] instance.
  const Exercise({
    this.id,
    required this.nameDe,
    required this.nameEn,
    required this.descriptionDe,
    required this.descriptionEn,
    required this.categoryName,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.imagePath,
  });

  // ---------- Parsing helpers ----------
  static List<String> _parseMuscleList(dynamic raw) {
    if (raw == null) return const [];
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];

    // JSON-Array?
    if (s.startsWith('[')) {
      try {
        final data = jsonDecode(s);
        if (data is List) {
          return data
              .map((e) => (e ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .cast<String>()
              .toList(growable: false);
        }
      } catch (_) {
        // fällt auf CSV zurück
      }
    }

    // CSV (GROUP_CONCAT)
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// Creates an [Exercise] instance from a Map, typically from a database row.
  ///
  /// The [m] parameter must contain keys like 'id', 'name_de', 'name_en', etc.
  factory Exercise.fromMap(Map<String, Object?> m) {
    final primRaw = m['primaryMuscles_json_de'] ??
        m['primaryMuscles_json_en'] ??
        m['primaryMuscles'];
    final secRaw = m['secondaryMuscles_json_de'] ??
        m['secondaryMuscles_json_en'] ??
        m['secondaryMuscles'];

    return Exercise(
      id: (m['id'] is num) ? (m['id'] as num).toInt() : m['id'] as int?,
      nameDe: (m['name_de'] ?? '') as String,
      nameEn: (m['name_en'] ?? '') as String,
      descriptionDe: (m['description_de'] ?? '') as String,
      descriptionEn: (m['description_en'] ?? '') as String,
      categoryName: (m['category_name'] ?? '') as String,
      imagePath: m['image_path'] as String?,
      primaryMuscles: _parseMuscleList(primRaw),
      secondaryMuscles: _parseMuscleList(secRaw),
    );
  }

  // ---------- Model -> DB (für Inserts/Updates) ----------
  //
  // Achtung: Wir serialisieren Muskulatur als CSV, weil dein Insert
  // in workout_database_helper aktuell CSV erwartet.
  /// Converts the [Exercise] instance to a Map for database storage.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'name_de': nameDe,
      'name_en': nameEn,
      'description_de': descriptionDe,
      'description_en': descriptionEn,
      'category_name': categoryName,
      'image_path': imagePath,
      'primaryMuscles': jsonEncode(primaryMuscles),
      'secondaryMuscles': jsonEncode(secondaryMuscles),
    };
  }

  // ---------- convenient ----------
  /// Creates a copy of this [Exercise] with the given fields replaced by the new values.
  Exercise copyWith({
    int? id,
    String? nameDe,
    String? nameEn,
    String? descriptionDe,
    String? descriptionEn,
    String? categoryName,
    String? imagePath,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
  }) {
    return Exercise(
      id: id ?? this.id,
      nameDe: nameDe ?? this.nameDe,
      nameEn: nameEn ?? this.nameEn,
      descriptionDe: descriptionDe ?? this.descriptionDe,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      categoryName: categoryName ?? this.categoryName,
      imagePath: imagePath ?? this.imagePath,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    );
  }

  // Optional hilfreich im UI:
  /// Returns the name of the exercise localized to the user's language.
  ///
  /// Currently fallbacks to [nameDe] if available, otherwise [nameEn].
  String getLocalizedName(context) => nameDe.isNotEmpty ? nameDe : nameEn;

  /// Returns the description of the exercise localized to the user's language.
  ///
  /// Currently fallbacks to [descriptionDe] if available, otherwise [descriptionEn].
  String getLocalizedDescription(context) =>
      descriptionDe.isNotEmpty ? descriptionDe : descriptionEn;
}
