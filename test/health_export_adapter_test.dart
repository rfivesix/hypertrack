import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/health_export/adapters/apple_health/apple_health_export_adapter.dart';
import 'package:hypertrack/health_export/adapters/health_connect/health_connect_export_adapter.dart';
import 'package:hypertrack/health_export/contracts/health_export_adapter.dart';
import 'package:hypertrack/health_export/models/export_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Health export adapters', () {
    const appleChannel = MethodChannel('hypertrack.health/export_apple_health');
    const connectChannel =
        MethodChannel('hypertrack.health/export_health_connect');

    final appleCalls = <MethodCall>[];
    final connectCalls = <MethodCall>[];

    setUp(() {
      appleCalls.clear();
      connectCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(appleChannel, (call) async {
        appleCalls.add(call);
        if (call.method == 'getAvailability') return true;
        if (call.method == 'requestPermissions') return true;
        return true;
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectChannel, (call) async {
        connectCalls.add(call);
        if (call.method == 'getAvailability') return 'available';
        if (call.method == 'requestPermissions') return true;
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(appleChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectChannel, null);
    });

    test('apple adapter forwards mapping payload to channel', () async {
      final adapter = AppleHealthExportAdapter();
      final availability = await adapter.getAvailability();
      expect(availability, HealthExportAvailability.available);

      await adapter.requestPermissions();
      await adapter.writeMeasurement(
        ExportMeasurementRecord(
          idempotencyKey: 'm1',
          timestampUtc: DateTime.utc(2026, 1, 1),
          type: ExportMeasurementType.weight,
          value: 80,
        ),
      );
      await adapter.writeNutrition(
        ExportNutritionRecord(
          idempotencyKey: 'n1',
          timestampUtc: DateTime.utc(2026, 1, 1),
          caloriesKcal: 500,
        ),
      );
      await adapter.writeHydration(
        ExportHydrationRecord(
          idempotencyKey: 'h1',
          timestampUtc: DateTime.utc(2026, 1, 1),
          volumeLiters: 1.0,
        ),
      );
      await adapter.writeWorkout(
        ExportWorkoutRecord(
          idempotencyKey: 'w1',
          startUtc: DateTime.utc(2026, 1, 1, 10),
          endUtc: DateTime.utc(2026, 1, 1, 11),
          workoutType: ExportWorkoutType.strength,
        ),
      );

      expect(
        appleCalls.map((call) => call.method),
        containsAll([
          'getAvailability',
          'requestPermissions',
          'writeMeasurement',
          'writeNutrition',
          'writeHydration',
          'writeWorkout',
        ]),
      );
    });

    test('health connect adapter maps availability and forwards writes', () async {
      final adapter = HealthConnectExportAdapter();
      final availability = await adapter.getAvailability();
      expect(availability, HealthExportAvailability.available);

      await adapter.requestPermissions();
      await adapter.writeMeasurement(
        ExportMeasurementRecord(
          idempotencyKey: 'm1',
          timestampUtc: DateTime.utc(2026, 1, 1),
          type: ExportMeasurementType.bmi,
          value: 25,
        ),
      );

      expect(
        connectCalls.map((call) => call.method),
        containsAll(['getAvailability', 'requestPermissions', 'writeMeasurement']),
      );
      final measurementCall =
          connectCalls.firstWhere((call) => call.method == 'writeMeasurement');
      final args = measurementCall.arguments as Map;
      expect(args['idempotencyKey'], 'm1');
      expect(args['type'], 'bmi');
    });
  });
}
