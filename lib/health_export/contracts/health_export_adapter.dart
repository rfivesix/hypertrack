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
}
