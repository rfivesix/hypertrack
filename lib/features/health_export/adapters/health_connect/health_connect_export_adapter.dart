import '../../contracts/health_export_adapter.dart';
import '../../models/export_models.dart';
import '../../platform/health_connect_export_platform.dart';

class HealthConnectExportAdapter implements HealthExportAdapter {
  HealthConnectExportAdapter({HealthConnectExportPlatform? platform})
      : _platform = platform ?? const HealthConnectExportPlatform();

  final HealthConnectExportPlatform _platform;

  @override
  HealthExportPlatform get platform => HealthExportPlatform.healthConnect;

  @override
  Future<HealthExportAvailability> getAvailability() async {
    final value = await _platform.getAvailability();
    return switch (value) {
      'available' => HealthExportAvailability.available,
      'not_installed' => HealthExportAvailability.notInstalled,
      _ => HealthExportAvailability.unsupported,
    };
  }

  @override
  Future<bool> requestPermissions() => _platform.requestPermissions();

  @override
  Future<void> writeMeasurement(ExportMeasurementRecord record) {
    return _platform.writeMeasurement(record.toMap());
  }

  @override
  Future<void> writeMeasurementsBatch(List<ExportMeasurementRecord> records) {
    return _platform.writeMeasurementsBatch(
      records.map((record) => record.toMap()).toList(growable: false),
    );
  }

  @override
  Future<void> writeNutrition(ExportNutritionRecord record) {
    return _platform.writeNutrition(record.toMap());
  }

  @override
  Future<void> writeNutritionBatch(List<ExportNutritionRecord> records) {
    return _platform.writeNutritionBatch(
      records.map((record) => record.toMap()).toList(growable: false),
    );
  }

  @override
  Future<void> writeHydration(ExportHydrationRecord record) {
    return _platform.writeHydration(record.toMap());
  }

  @override
  Future<void> writeHydrationBatch(List<ExportHydrationRecord> records) {
    return _platform.writeHydrationBatch(
      records.map((record) => record.toMap()).toList(growable: false),
    );
  }

  @override
  Future<void> writeWorkout(ExportWorkoutRecord record) {
    return _platform.writeWorkout(record.toMap());
  }

  @override
  Future<void> writeWorkoutsBatch(List<ExportWorkoutRecord> records) {
    return _platform.writeWorkoutsBatch(
      records.map((record) => record.toMap()).toList(growable: false),
    );
  }
}
