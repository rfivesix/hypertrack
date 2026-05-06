// lib/data/import_manager.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:intl/intl.dart';
import 'workout_database_helper.dart';
import 'drift_database.dart' as db;
import '../models/set_log.dart';

/// Manager responsible for importing workout data from external sources.
class ImportManager {
  /// Imports workout data from a Hevy CSV file.
  ///
  /// Opens a file picker, parses the CSV content, and inserts the workouts and sets
  /// into the local database. Returns the number of imported workouts, or -1 on error.
  Future<int> importHevyCsv() async {
    try {
      // 1. Select file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) return 0;

      final filePath = result.files.single.path!;
      final file = File(filePath);
      final content = await file.readAsString();

      // 2. Parse CSV
      final List<List<dynamic>> rows = Csv(
        dynamicTyping: false,
      ).decode(content);

      if (rows.length < 2) return 0; // Header only or empty

      // 3. Map header
      final header = rows.first.map((e) => e.toString().trim()).toList();

      // 4. Group rows (one workout has multiple sets across multiple rows).
      final workoutGroups = <String, List<Map<String, dynamic>>>{};

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length != header.length) continue;

        final rowMap = Map<String, dynamic>.fromIterables(header, row);

        // No valid workout without a start time.
        if (rowMap['start_time'] == null ||
            rowMap['start_time'].toString().trim().isEmpty) {
          continue;
        }

        // Grouping key: title + start time
        final key = "${rowMap['title']}_${rowMap['start_time']}";
        workoutGroups.putIfAbsent(key, () => []).add(rowMap);
      }

      // 5. Write workouts to DB
      final workoutHelper = WorkoutDatabaseHelper.instance;
      final database =
          await workoutHelper.database; // Access to Drift DB instance

      int importedWorkouts = 0;

      // FIX: The getExerciseMappings method no longer exists in the new helper.
      // Initialize an empty map. Mapping happens in the new flow after import
      // via 'findUnknownExerciseNames'.
      final knownMap = <String, String>{};

      for (var group in workoutGroups.values) {
        final firstRow = group.first;
        final routineName = firstRow['title'] ?? 'Importiertes Workout';
        final notes = firstRow['description'];

        // A. Create workout (initially 'ongoing' with current time)
        final newLog = await workoutHelper.startWorkout(
          routineName: routineName,
        );

        if (newLog.id == null) continue;

        // B. Parse timestamp
        final startTime = _parseHevyDate(firstRow['start_time']);
        final endTime = _parseHevyDate(firstRow['end_time']);

        // C. Update workout details (correct times & status).
        // Use Drift updates directly here to set historical data correctly
        // because finishWorkout would use DateTime.now().
        final updateCompanion = db.WorkoutLogsCompanion(
          startTime: drift.Value(startTime),
          endTime: drift.Value(endTime),
          status: const drift.Value('completed'),
          notes: drift.Value(notes),
        );

        await (database.update(database.workoutLogs)
              ..where((tbl) => tbl.localId.equals(newLog.id!)))
            .write(updateCompanion);

        // D. Iterate and insert sets
        int setOrder = 0;
        for (var row in group) {
          final rawName = row['exercise_title']?.toString() ?? '';

          // Check mapping (if the user has mapped before; currently empty).
          final mappedName = knownMap[rawName.trim().toLowerCase()] ?? rawName;

          // Extract data for SetLog
          final setLog = SetLog(
            workoutLogId: newLog.id!, // Link via local ID
            exerciseName: mappedName,
            setType: _mapSetType(row['set_type']),

            // Metriken parsen
            weightKg: double.tryParse(row['weight_kg']?.toString() ?? ''),
            reps: int.tryParse(row['reps']?.toString() ?? ''),
            distanceKm: double.tryParse(row['distance_km']?.toString() ?? ''),
            durationSeconds: int.tryParse(
              row['duration_seconds']?.toString() ?? '',
            ),
            rpe: int.tryParse(row['rpe']?.toString() ?? ''),

            logOrder: setOrder++,
            notes: row['exercise_notes'],
            isCompleted: true, // Imported sets are always completed.
          );

          await workoutHelper.insertSetLog(setLog);
        }
        importedWorkouts++;
      }
      return importedWorkouts;
    } catch (e) {
      debugPrint("Hevy Import Error: $e");
      return -1; // Fehlercode
    }
  }

  /// Helper method to map Hevy set types to internal types.
  String _mapSetType(dynamic rawType) {
    final t = rawType?.toString().toLowerCase() ?? '';
    if (t == 'warmup') return 'warmup';
    if (t == 'failure') return 'failure';
    if (t == 'drop_set' || t == 'dropset') return 'dropset';
    return 'normal';
  }

  /// Robust date parsing function.
  DateTime _parseHevyDate(dynamic rawDateString) {
    final dateString = rawDateString?.toString().trim();
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    // List of supported formats (expanded with DE and EN).
    final List<DateFormat> formats = [
      DateFormat("dd MMM yyyy, HH:mm", "en_US"), // 18 Oct 2023, 14:30
      DateFormat("dd MMM yyyy, HH:mm", "de_DE"), // 18 Okt 2023, 14:30
      DateFormat("yyyy-MM-dd HH:mm:ss"), // Standard SQL
      DateFormat("dd.MM.yyyy, HH:mm"), // Deutsch numerisch
      DateFormat("dd.MM.yyyy HH:mm"),
    ];

    for (final format in formats) {
      try {
        return format.parse(dateString);
      } catch (e) {
        continue;
      }
    }

    debugPrint(
      "WARNUNG: Konnte Datum nicht parsen: '$dateString'. Nutze JETZT.",
    );
    return DateTime.now();
  }
}
