// lib/data/import_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:excel_community/excel_community.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../features/workout/data/sources/workout_local_data_source.dart';
import 'drift_database.dart' as db;
import '../features/workout/domain/models/set_log.dart';
import '../services/unit_service.dart';

class WorkoutImportData {
  final String title;
  final String? notes;
  final DateTime startTime;
  final DateTime? endTime;
  final List<SetLog> sets;

  WorkoutImportData({
    required this.title,
    this.notes,
    required this.startTime,
    this.endTime,
    required this.sets,
  });
}

class ImportBackgroundTaskParams {
  final Uint8List fileBytes;
  final String extension;
  final bool isImperial;

  ImportBackgroundTaskParams({
    required this.fileBytes,
    required this.extension,
    required this.isImperial,
  });
}

/// Manager responsible for importing workout data from external sources (CSV/Excel).
class ImportManager {
  /// Imports workout data from a CSV or Excel file.
  ///
  /// [isImperial] if true, incoming weight values are treated as lbs and converted to kg.
  Future<int> importWorkoutFile({required bool isImperial}) async {
    try {
      // 1. Select file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result == null || result.files.single.path == null) return 0;

      final filePath = result.files.single.path!;
      final extension = result.files.single.extension?.toLowerCase() ?? '';
      final fileBytes = await File(filePath).readAsBytes();

      // 2. Offload decoding and grouping to background isolate
      final workoutGroups = await compute(
        _decodeAndGroupWorkouts,
        ImportBackgroundTaskParams(
          fileBytes: fileBytes,
          extension: extension,
          isImperial: isImperial,
        ),
      );

      if (workoutGroups.isEmpty) return 0;

      // 3. Write to DB in atomic batches
      final workoutHelper = WorkoutLocalDataSource.instance;
      final database = await workoutHelper.database;

      int importedWorkouts = 0;

      // Use a single transaction for all imported workouts to ensure integrity and performance
      await database.transaction(() async {
        for (var workoutData in workoutGroups) {
          // A. Create workout
          final newLog = await workoutHelper.startWorkout(
            routineName: workoutData.title,
          );

          if (newLog.id == null) continue;

          // B. Update workout details
          await (database.update(database.workoutLogs)
                ..where((tbl) => tbl.localId.equals(newLog.id!)))
              .write(db.WorkoutLogsCompanion(
            startTime: drift.Value(workoutData.startTime),
            endTime: drift.Value(workoutData.endTime),
            status: const drift.Value('completed'),
            notes: drift.Value(workoutData.notes),
          ));

          // C. Insert sets using a batch for this workout
          // Note: We use the helper's individual insert for now because it handles
          // complex exercise mapping and usage counts, but within a transaction
          // it is still significantly faster than outside.
          for (var set in workoutData.sets) {
            final setWithCorrectId = set.copyWith(workoutLogId: newLog.id!);
            await workoutHelper.insertSetLog(setWithCorrectId);
          }
          importedWorkouts++;
        }
      });

      return importedWorkouts;
    } catch (e) {
      debugPrint("External Import Error: $e");
      return -1;
    }
  }

  static List<WorkoutImportData> _decodeAndGroupWorkouts(
    ImportBackgroundTaskParams params,
  ) {
    final extension = params.extension;
    final isImperial = params.isImperial;
    final bytes = params.fileBytes;

    List<List<dynamic>> rows = [];

    try {
      if (extension == 'csv') {
        final content = utf8.decode(bytes);
        rows = csv.decode(content);
      } else if (extension == 'xlsx') {
        final excel = xl.Excel.decodeBytes(bytes);
        // Take first sheet
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName]!;
        for (var row in sheet.rows) {
          rows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Decoding Error in Isolate: $e");
      return [];
    }

    if (rows.length < 2) return [];

    // Map header and normalize
    final rawHeader =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final headerMap = _mapHeader(rawHeader);

    // Group rows (one workout has multiple sets across multiple rows).
    final workoutGroupsMap = <String, List<Map<String, dynamic>>>{};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < rawHeader.length) continue;

      final rowData = <String, dynamic>{};
      for (var entry in headerMap.entries) {
        final index = entry.value;
        if (index < row.length) {
          rowData[entry.key] = row[index];
        }
      }

      final title = rowData['title']?.toString() ?? 'Importiertes Workout';
      final startTimeRaw = rowData['start_time']?.toString() ?? '';

      if (startTimeRaw.trim().isEmpty) continue;

      final key = "${title}_$startTimeRaw";
      workoutGroupsMap.putIfAbsent(key, () => []).add(rowData);
    }

    final List<WorkoutImportData> result = [];

    for (var group in workoutGroupsMap.values) {
      final firstRow = group.first;
      final title = firstRow['title']?.toString() ?? 'Importiertes Workout';
      final notes = firstRow['description']?.toString();
      final startTime = _parseDate(firstRow['start_time']);
      final endTime = _parseDate(firstRow['end_time']);

      final List<SetLog> sets = [];
      int setOrder = 0;
      for (var row in group) {
        final rawExerciseName =
            row['exercise']?.toString() ?? 'Unbekannte Übung';

        double? weight = double.tryParse(row['weight']?.toString() ?? '');
        if (weight != null && isImperial) {
          weight = UnitService.lbsToKg(weight);
        }

        sets.add(SetLog(
          workoutLogId: 0,
          exerciseName: rawExerciseName,
          setType: _mapSetType(row['set_type']),
          weightKg: weight,
          reps: int.tryParse(row['reps']?.toString() ?? ''),
          distanceKm: double.tryParse(row['distance']?.toString() ?? ''),
          durationSeconds: int.tryParse(row['duration']?.toString() ?? ''),
          rpe: int.tryParse(row['rpe']?.toString() ?? ''),
          logOrder: setOrder++,
          notes: row['set_notes']?.toString(),
          isCompleted: true,
        ));
      }

      result.add(WorkoutImportData(
        title: title,
        notes: notes,
        startTime: startTime,
        endTime: endTime,
        sets: sets,
      ));
    }

    return result;
  }

  /// Maps generic headers to normalized internal keys.
  static Map<String, int> _mapHeader(List<String> header) {
    final map = <String, int>{};

    for (var i = 0; i < header.length; i++) {
      final h = header[i];

      // Workout Meta
      if (['title', 'routine', 'workout', 'name'].contains(h)) {
        map['title'] = i;
      } else if (['start_time', 'start', 'datum', 'date'].contains(h)) {
        map['start_time'] = i;
      } else if (['end_time', 'end'].contains(h)) {
        map['end_time'] = i;
      } else if (['description', 'notes', 'notiz'].contains(h)) {
        map['description'] = i;
      }
      // Exercise & Set
      else if (['exercise_title', 'exercise', 'übung', 'exercise_name']
          .contains(h)) {
        map['exercise'] = i;
      } else if (['set_type', 'type', 'typ'].contains(h)) {
        map['set_type'] = i;
      } else if (['weight_kg', 'weight', 'gewicht', 'mass', 'lbs']
          .contains(h)) {
        map['weight'] = i;
      } else if (['reps', 'wiederholungen', 'repetitionen', 'repetition']
          .contains(h)) {
        map['reps'] = i;
      } else if (['distance_km', 'distance', 'distanz', 'entfernung']
          .contains(h)) {
        map['distance'] = i;
      } else if (['duration_seconds', 'duration', 'dauer', 'zeit']
          .contains(h)) {
        map['duration'] = i;
      } else if (['rpe'].contains(h)) {
        map['rpe'] = i;
      } else if (['exercise_notes', 'set_notes'].contains(h)) {
        map['set_notes'] = i;
      }
    }
    return map;
  }

  static String _mapSetType(dynamic rawType) {
    final t = rawType?.toString().toLowerCase() ?? '';
    if (t.contains('warmup') || t == 'w') return 'warmup';
    if (t.contains('failure') || t == 'f') return 'failure';
    if (t.contains('dropset') || t.contains('drop_set') || t == 'd') {
      return 'dropset';
    }
    return 'normal';
  }

  static DateTime _parseDate(dynamic rawDateString) {
    final dateString = rawDateString?.toString().trim();
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    final List<DateFormat> formats = [
      DateFormat("dd MMM yyyy, HH:mm", "en_US"),
      DateFormat("dd MMM yyyy, HH:mm", "de_DE"),
      DateFormat("yyyy-MM-dd HH:mm:ss"),
      DateFormat("yyyy-MM-dd HH:mm"),
      DateFormat("dd.MM.yyyy, HH:mm"),
      DateFormat("dd.MM.yyyy HH:mm"),
      DateFormat("MM/dd/yyyy HH:mm"),
    ];

    for (final format in formats) {
      try {
        return format.parse(dateString);
      } catch (e) {
        continue;
      }
    }

    // Try ISO8601 as last resort
    try {
      return DateTime.parse(dateString);
    } catch (_) {}

    return DateTime.now();
  }
}
