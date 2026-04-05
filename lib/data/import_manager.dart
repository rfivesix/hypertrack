// lib/data/import_manager.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Für debugPrint
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
      // 1. Datei auswählen
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) return 0;

      final filePath = result.files.single.path!;
      final file = File(filePath);
      final content = await file.readAsString();

      // 2. CSV parsen
      final List<List<dynamic>> rows = Csv(
        dynamicTyping: false,
      ).decode(content);

      if (rows.length < 2) return 0; // Nur Header oder leer

      // 3. Header mappen
      final header = rows.first.map((e) => e.toString().trim()).toList();

      // 4. Zeilen gruppieren (Ein Workout hat mehrere Sets in mehreren Zeilen)
      final workoutGroups = <String, List<Map<String, dynamic>>>{};

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length != header.length) continue;

        final rowMap = Map<String, dynamic>.fromIterables(header, row);

        // Ohne Startzeit kein valides Workout
        if (rowMap['start_time'] == null ||
            rowMap['start_time'].toString().trim().isEmpty) {
          continue;
        }

        // Gruppierungsschlüssel: Titel + Startzeit
        final key = "${rowMap['title']}_${rowMap['start_time']}";
        workoutGroups.putIfAbsent(key, () => []).add(rowMap);
      }

      // 5. Workouts in DB schreiben
      final workoutHelper = WorkoutDatabaseHelper.instance;
      final database =
          await workoutHelper.database; // Zugriff auf Drift DB Instanz

      int importedWorkouts = 0;

      // KORREKTUR: Die Methode getExerciseMappings existiert im neuen Helper nicht mehr.
      // Wir initialisieren eine leere Map. Das Mapping erfolgt im neuen Flow NACH dem Import
      // über 'findUnknownExerciseNames'.
      final knownMap = <String, String>{};

      for (var group in workoutGroups.values) {
        final firstRow = group.first;
        final routineName = firstRow['title'] ?? 'Importiertes Workout';
        final notes = firstRow['description'];

        // A. Workout anlegen (Initial als 'ongoing' mit current time)
        final newLog = await workoutHelper.startWorkout(
          routineName: routineName,
        );

        if (newLog.id == null) continue;

        // B. Zeitstempel parsen
        final startTime = _parseHevyDate(firstRow['start_time']);
        final endTime = _parseHevyDate(firstRow['end_time']);

        // C. Workout-Details aktualisieren (Zeiten & Status korrigieren)
        // Wir nutzen hier direkt Drift Updates, um historische Daten korrekt zu setzen
        // (da finishWorkout DateTime.now() verwenden würde)
        final updateCompanion = db.WorkoutLogsCompanion(
          startTime: drift.Value(startTime),
          endTime: drift.Value(endTime),
          status: const drift.Value('completed'),
          notes: drift.Value(notes),
        );

        await (database.update(database.workoutLogs)
              ..where((tbl) => tbl.localId.equals(newLog.id!)))
            .write(updateCompanion);

        // D. Sets iterieren und einfügen
        int setOrder = 0;
        for (var row in group) {
          final rawName = row['exercise_title']?.toString() ?? '';

          // Mapping prüfen (falls User schon mal gemappt hat - aktuell leer)
          final mappedName = knownMap[rawName.trim().toLowerCase()] ?? rawName;

          // Daten für SetLog extrahieren
          final setLog = SetLog(
            workoutLogId: newLog.id!, // Verknüpfung via lokaler ID
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

            log_order: setOrder++,
            notes: row['exercise_notes'],
            isCompleted: true, // Importierte Sets sind immer fertig
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

  /// Hilfsmethode um Hevy Set-Types auf interne Types zu mappen
  String _mapSetType(dynamic rawType) {
    final t = rawType?.toString().toLowerCase() ?? '';
    if (t == 'warmup') return 'warmup';
    if (t == 'failure') return 'failure';
    if (t == 'drop_set' || t == 'dropset') return 'dropset';
    return 'normal';
  }

  /// Robuste Datums-Parsing-Funktion
  DateTime _parseHevyDate(dynamic rawDateString) {
    final dateString = rawDateString?.toString().trim();
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    // Liste unterstützter Formate (Erweitert um DE und EN)
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
