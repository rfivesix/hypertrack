// lib/data/export_manager.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:excel_community/excel_community.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'workout_database_helper.dart';
import 'database_helper.dart';

class ExportManager {
  static Future<void> exportToExcel() async {
    final excel = Excel.createExcel();

    // 1. Workouts Sheet
    final workoutSheet = excel['Workouts'];
    excel.delete('Sheet1'); // Remove default sheet

    workoutSheet.appendRow([
      TextCellValue('Datum'),
      TextCellValue('Workout Name'),
      TextCellValue('Übung'),
      TextCellValue('Satz Typ'),
      TextCellValue('Gewicht (kg)'),
      TextCellValue('Wdh'),
      TextCellValue('Distanz (km)'),
      TextCellValue('Dauer (s)'),
      TextCellValue('RPE'),
      TextCellValue('Notizen'),
    ]);

    final workoutHelper = WorkoutDatabaseHelper.instance;
    final allWorkoutLogs = await workoutHelper.getWorkoutLogs();

    for (var log in allWorkoutLogs) {
      if (log.id == null) continue;
      final sets = await workoutHelper.getSetLogsForWorkout(log.id!);
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(log.startTime);

      for (var set in sets) {
        workoutSheet.appendRow([
          TextCellValue(dateStr),
          TextCellValue(log.routineName ?? 'Importiertes Workout'),
          TextCellValue(set.exerciseName),
          TextCellValue(set.setType),
          DoubleCellValue(set.weightKg ?? 0),
          IntCellValue(set.reps ?? 0),
          DoubleCellValue(set.distanceKm ?? 0),
          IntCellValue(set.durationSeconds ?? 0),
          IntCellValue(set.rpe ?? 0),
          TextCellValue(set.notes ?? ''),
        ]);
      }
    }

    // 2. Nutrition Sheet
    final nutritionSheet = excel['Ernährung'];
    nutritionSheet.appendRow([
      TextCellValue('Zeitpunkt'),
      TextCellValue('Mahlzeit'),
      TextCellValue('Barcode'),
      TextCellValue('Menge (g/ml)'),
      TextCellValue('Name (falls verfügbar)'),
    ]);

    final foodHelper = DatabaseHelper.instance;
    final foodEntries = await foodHelper.getAllFoodEntries();
    final fluidEntries = await foodHelper.getAllFluidEntries();

    for (var entry in foodEntries) {
      nutritionSheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp)),
        TextCellValue(entry.mealType),
        TextCellValue(entry.barcode),
        IntCellValue(entry.quantityInGrams),
        TextCellValue(''), // Product name resolution would be slow here
      ]);
    }

    for (var entry in fluidEntries) {
      nutritionSheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp)),
        TextCellValue('Trinken'),
        TextCellValue('Drink'),
        IntCellValue(entry.quantityInMl),
        TextCellValue(entry.name),
      ]);
    }

    // 3. Measurements Sheet
    final measurementSheet = excel['Messwerte'];
    measurementSheet.appendRow([
      TextCellValue('Datum'),
      TextCellValue('Typ'),
      TextCellValue('Wert'),
      TextCellValue('Einheit'),
    ]);

    final sessions = await foodHelper.getMeasurementSessions();
    for (var session in sessions) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(session.timestamp);
      for (var m in session.measurements) {
        measurementSheet.appendRow([
          TextCellValue(dateStr),
          TextCellValue(m.type),
          DoubleCellValue(m.value),
          TextCellValue(m.unit),
        ]);
      }
    }

    // Save and Share
    final bytes = excel.encode();
    if (bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/train_libre_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
          ],
          subject: 'Train Libre Excel Export',
          sharePositionOrigin: _sharePositionOrigin(),
        ),
      );
    }
  }

  static ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
      0,
      0,
      math.max(1, logicalSize.width),
      math.max(1, logicalSize.height),
    );
  }
}
