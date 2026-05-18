import '../models/export_models.dart';

enum HealthExportAvailability { available, notInstalled, unsupported }

abstract class HealthExportAdapter {
  HealthExportPlatform get platform;

  Future<HealthExportAvailability> getAvailability();
  Future<bool> requestPermissions();

  Future<void> writeMeasurement(ExportMeasurementRecord record);
  Future<void> writeNutrition(ExportNutritionRecord record);
  Future<void> writeHydration(ExportHydrationRecord record);
  Future<void> writeWorkout(ExportWorkoutRecord record);

  Future<void> writeMeasurementsBatch(
    List<ExportMeasurementRecord> records,
  ) async {
    for (final record in records) {
      await writeMeasurement(record);
    }
  }

  Future<void> writeNutritionBatch(List<ExportNutritionRecord> records) async {
    for (final record in records) {
      await writeNutrition(record);
    }
  }

  Future<void> writeHydrationBatch(List<ExportHydrationRecord> records) async {
    for (final record in records) {
      await writeHydration(record);
    }
  }

  Future<void> writeWorkoutsBatch(List<ExportWorkoutRecord> records) async {
    for (final record in records) {
      await writeWorkout(record);
    }
  }
}
