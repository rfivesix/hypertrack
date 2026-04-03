import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/services/health/health_models.dart';
import 'package:hypertrack/services/health/health_platform_steps.dart';
import 'package:hypertrack/services/health/steps_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHealthPlatformSteps extends HealthPlatformSteps {
  _FakeHealthPlatformSteps(this._reads);

  final List<List<HealthStepSegmentDto>> _reads;
  int _readCalls = 0;

  @override
  Future<StepsAvailability> getAvailability() async =>
      StepsAvailability.available;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<HealthStepSegmentDto>> readStepSegments({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (_readCalls >= _reads.length) return const [];
    final result = _reads[_readCalls];
    _readCalls += 1;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Steps sync and aggregation', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      're-enable sync with overlapping range does not inflate totals',
      () async {
        final t1 = DateTime.utc(2026, 3, 26, 12);
        final t2 = t1.add(const Duration(hours: 1));
        final dayLocal = DateTime(2026, 3, 26);

        final firstRead = <HealthStepSegmentDto>[
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 10),
            endAtUtc: DateTime.utc(2026, 3, 26, 11),
            stepCount: 400,
            sourceId: 'watch',
            nativeId: 'native-a',
          ),
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 11),
            endAtUtc: DateTime.utc(2026, 3, 26, 12),
            stepCount: 600,
            sourceId: 'watch',
            nativeId: 'native-b',
          ),
        ];
        final secondRead = <HealthStepSegmentDto>[
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 10),
            endAtUtc: DateTime.utc(2026, 3, 26, 11),
            stepCount: 400,
            sourceId: 'watch',
            nativeId: 'native-a-new',
          ),
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 11),
            endAtUtc: DateTime.utc(2026, 3, 26, 12),
            stepCount: 600,
            sourceId: 'watch',
            nativeId: 'native-b-new',
          ),
        ];

        final platform = _FakeHealthPlatformSteps([firstRead, secondRead]);
        final service = StepsSyncService(
          platform: platform,
          dbHelper: dbHelper,
        );

        await service.setTrackingEnabled(true);
        await service.sync(now: t1, forceRefresh: true);
        final totalAfterFirst = await dbHelper.getDailyStepsTotal(
          dayLocal: dayLocal,
        );
        expect(totalAfterFirst, 1000);

        await service.setTrackingEnabled(false);
        await service.setTrackingEnabled(true);
        await service.sync(now: t2, forceRefresh: false);
        final totalAfterReenable = await dbHelper.getDailyStepsTotal(
          dayLocal: dayLocal,
        );

        expect(totalAfterReenable, totalAfterFirst);
      },
    );

    test('aggregation auto policy uses dominant source per day', () async {
      await dbHelper.upsertHealthStepSegments(<Map<String, dynamic>>[
        {
          'provider': 'apple_healthkit',
          'sourceId': 'watch',
          'startAt': DateTime.utc(2026, 3, 26, 10).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'stepCount': 1000,
          'externalKey': 'k1',
        },
        {
          'provider': 'apple_healthkit',
          'sourceId': 'phone',
          'startAt': DateTime.utc(2026, 3, 26, 10).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'stepCount': 1200,
          'externalKey': 'k2',
        },
        {
          'provider': 'apple_healthkit',
          'sourceId': 'watch',
          'startAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 12).toIso8601String(),
          'stepCount': 500,
          'externalKey': 'k3',
        },
        {
          'provider': 'apple_healthkit',
          'sourceId': 'phone',
          'startAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 12).toIso8601String(),
          'stepCount': 200,
          'externalKey': 'k4',
        },
      ]);

      final dayLocal = DateTime(2026, 3, 26);
      final total = await dbHelper.getDailyStepsTotal(dayLocal: dayLocal);
      expect(total, 1500);

      final hourly = await dbHelper.getHourlyStepsTotalsForDay(
        dayLocal: dayLocal,
      );
      final hourlyTotals = hourly
          .map((row) => row['totalSteps'] as int)
          .toList(growable: false)
        ..sort();
      expect(hourlyTotals, <int>[500, 1000]);

      final range = await dbHelper.getDailyStepsTotalsForRange(
        startLocal: dayLocal,
        endLocal: dayLocal,
      );
      expect(range.length, 1);
      expect(range.first['totalSteps'], 1500);
    });

    test('aggregation max-per-hour policy remains available', () async {
      await dbHelper.upsertHealthStepSegments(<Map<String, dynamic>>[
        {
          'provider': 'apple_healthkit',
          'sourceId': 'watch',
          'startAt': DateTime.utc(2026, 3, 26, 10).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'stepCount': 1000,
          'externalKey': 'm1',
        },
        {
          'provider': 'apple_healthkit',
          'sourceId': 'phone',
          'startAt': DateTime.utc(2026, 3, 26, 10).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'stepCount': 1200,
          'externalKey': 'm2',
        },
        {
          'provider': 'apple_healthkit',
          'sourceId': 'watch',
          'startAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 12).toIso8601String(),
          'stepCount': 500,
          'externalKey': 'm3',
        },
        {
          'provider': 'apple_healthkit',
          'sourceId': 'phone',
          'startAt': DateTime.utc(2026, 3, 26, 11).toIso8601String(),
          'endAt': DateTime.utc(2026, 3, 26, 12).toIso8601String(),
          'stepCount': 200,
          'externalKey': 'm4',
        },
      ]);

      final dayLocal = DateTime(2026, 3, 26);
      final total = await dbHelper.getDailyStepsTotal(
        dayLocal: dayLocal,
        sourcePolicy: 'max_per_hour',
      );
      expect(total, 1700);

      final hourly = await dbHelper.getHourlyStepsTotalsForDay(
        dayLocal: dayLocal,
        sourcePolicy: 'max_per_hour',
      );
      final hourlyTotals = hourly
          .map((row) => row['totalSteps'] as int)
          .toList(growable: false)
        ..sort();
      expect(hourlyTotals, <int>[500, 1200]);

      final range = await dbHelper.getDailyStepsTotalsForRange(
        startLocal: dayLocal,
        endLocal: dayLocal,
        sourcePolicy: 'max_per_hour',
      );
      expect(range.length, 1);
      expect(range.first['totalSteps'], 1700);
    });
  });
}
