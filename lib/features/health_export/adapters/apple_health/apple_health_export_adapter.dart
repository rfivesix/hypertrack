import '../../contracts/health_export_adapter.dart';
import '../../models/export_models.dart';
import '../../platform/apple_health_export_platform.dart';

class AppleHealthExportAdapter implements HealthExportAdapter {
  AppleHealthExportAdapter({AppleHealthExportPlatform? platform})
      : _platform = platform ?? const AppleHealthExportPlatform();

  final AppleHealthExportPlatform _platform;

  @override
  HealthExportPlatform get platform => HealthExportPlatform.appleHealth;

  @override
  Future<HealthExportAvailability> getAvailability() async {
    final available = await _platform.isAvailable();
    return available
        ? HealthExportAvailability.available
        : HealthExportAvailability.unsupported;
  }

  @override
  Future<bool> requestPermissions() => _platform.requestPermissions();

  @override
  Future<void> writeMeasurement(ExportMeasurementRecord record) {
    return _platform.writeMeasurement(record.toMap());
  }

  @override
  Future<void> writeMeasurementsBatch(
    List<ExportMeasurementRecord> records,
  ) async {
    for (final record in records) {
      await writeMeasurement(record);
    }
  }

  @override
  Future<void> writeNutrition(ExportNutritionRecord record) {
    return _platform.writeNutrition(record.toMap());
  }

  @override
  Future<void> writeNutritionBatch(List<ExportNutritionRecord> records) async {
    for (final record in records) {
      await writeNutrition(record);
    }
  }

  @override
  Future<void> writeHydration(ExportHydrationRecord record) {
    return _platform.writeHydration(record.toMap());
  }

  @override
  Future<void> writeHydrationBatch(List<ExportHydrationRecord> records) async {
    for (final record in records) {
      await writeHydration(record);
    }
  }

  @override
  Future<void> writeWorkout(ExportWorkoutRecord record) {
    return _platform.writeWorkout(record.toMap());
  }

  @override
  Future<void> writeWorkoutsBatch(List<ExportWorkoutRecord> records) async {
    for (final record in records) {
      await writeWorkout(record);
    }
  }
}
