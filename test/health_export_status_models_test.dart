import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/health_export/models/export_models.dart';

void main() {
  group('Health export status model serialization', () {
    test('decode returns initial idle status map for null/empty input', () {
      final fromNull = decodePlatformStatusMap(null);
      final fromEmpty = decodePlatformStatusMap('');

      for (final map in [fromNull, fromEmpty]) {
        expect(map.keys.toSet(), HealthExportPlatform.values.toSet());
        for (final platform in HealthExportPlatform.values) {
          final status = map[platform]!;
          for (final domain in HealthExportDomain.values) {
            expect(status.statusFor(domain).state, HealthExportState.idle);
            expect(status.statusFor(domain).lastError, isNull);
            expect(status.statusFor(domain).lastSuccessfulExportAtUtc, isNull);
          }
        }
      }
    });

    test('decode falls back safely for malformed payloads', () {
      final decoded = decodePlatformStatusMap('{not-valid-json');

      expect(decoded.keys.toSet(), HealthExportPlatform.values.toSet());
      for (final platform in HealthExportPlatform.values) {
        for (final domain in HealthExportDomain.values) {
          expect(decoded[platform]!.statusFor(domain).state,
              HealthExportState.idle);
        }
      }
    });

    test('encode/decode round-trip preserves state, timestamps and errors', () {
      final timestamp = DateTime.utc(2026, 4, 4, 10, 15, 30);
      final statuses = <HealthExportPlatform, HealthExportPlatformStatus>{
        HealthExportPlatform.appleHealth: HealthExportPlatformStatus(
          platform: HealthExportPlatform.appleHealth,
          byDomain: {
            HealthExportDomain.measurements: HealthExportDomainStatus(
              state: HealthExportState.success,
              lastSuccessfulExportAtUtc: timestamp,
            ),
            HealthExportDomain.nutritionHydration:
                const HealthExportDomainStatus(
              state: HealthExportState.failed,
              lastError: 'network timeout',
            ),
            HealthExportDomain.workouts: const HealthExportDomainStatus(
                state: HealthExportState.exporting),
          },
        ),
        HealthExportPlatform.healthConnect: HealthExportPlatformStatus.initial(
            HealthExportPlatform.healthConnect),
      };

      final encoded = encodePlatformStatusMap(statuses);
      final decoded = decodePlatformStatusMap(encoded);
      final apple = decoded[HealthExportPlatform.appleHealth]!;

      expect(
        apple.statusFor(HealthExportDomain.measurements).state,
        HealthExportState.success,
      );
      expect(
        apple
            .statusFor(HealthExportDomain.measurements)
            .lastSuccessfulExportAtUtc,
        timestamp,
      );
      expect(
        apple.statusFor(HealthExportDomain.nutritionHydration).state,
        HealthExportState.failed,
      );
      expect(
        apple.statusFor(HealthExportDomain.nutritionHydration).lastError,
        'network timeout',
      );
      expect(
        apple.statusFor(HealthExportDomain.workouts).state,
        HealthExportState.exporting,
      );
    });

    test('unknown domain state values degrade to idle for safety', () {
      final raw = '''
{
  "appleHealth": {
    "platform": "appleHealth",
    "byDomain": {
      "measurements": {"state": "unknown_state"}
    }
  }
}
''';

      final decoded = decodePlatformStatusMap(raw);
      final apple = decoded[HealthExportPlatform.appleHealth]!;

      expect(
        apple.statusFor(HealthExportDomain.measurements).state,
        HealthExportState.idle,
      );
      expect(
        apple.statusFor(HealthExportDomain.nutritionHydration).state,
        HealthExportState.idle,
      );
      expect(
        apple.statusFor(HealthExportDomain.workouts).state,
        HealthExportState.idle,
      );
    });
  });
}
