import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/services/health/health_platform_heart_rate.dart';
import 'package:hypertrack/services/health/workout_heart_rate_models.dart';
import 'package:hypertrack/services/health/workout_heart_rate_service.dart';

class _FakeHeartRateDataSource implements HealthHeartRateDataSource {
  _FakeHeartRateDataSource({
    this.samples = const <HealthHeartRateSampleDto>[],
    this.error,
    this.onRead,
  });

  final List<HealthHeartRateSampleDto> samples;
  final Object? error;
  final List<HealthHeartRateSampleDto> Function(
      DateTime fromUtc, DateTime toUtc)? onRead;

  @override
  Future<List<HealthHeartRateSampleDto>> readHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (error != null) throw error!;
    final custom = onRead;
    if (custom != null) return custom(fromUtc, toUtc);
    return samples;
  }
}

class _ReadRequest {
  const _ReadRequest({
    required this.fromUtc,
    required this.toUtc,
  });

  final DateTime fromUtc;
  final DateTime toUtc;
}

void main() {
  group('WorkoutHeartRateService', () {
    test('computes avg/max/min and ready quality for dense data', () async {
      final start = DateTime.utc(2026, 1, 15, 10, 0);
      final end = DateTime.utc(2026, 1, 15, 11, 0);
      final samples = List.generate(
        12,
        (i) => HealthHeartRateSampleDto(
          sampledAtUtc: start.add(Duration(minutes: i * 5)),
          bpm: 110 + i.toDouble(),
        ),
      );
      final service = WorkoutHeartRateService(
        dataSource: _FakeHeartRateDataSource(samples: samples),
      );

      final summary = await service.loadForWorkoutWindow(
        startTime: start,
        endTime: end,
      );

      expect(summary.sampleCount, 12);
      expect(summary.averageBpm, closeTo(115.5, 0.001));
      expect(summary.maxBpm, 121);
      expect(summary.minBpm, 110);
      expect(summary.quality, WorkoutHeartRateDataQuality.ready);
      expect(summary.noDataReason, WorkoutHeartRateNoDataReason.none);
    });

    test('returns noData when no matching samples exist', () async {
      final start = DateTime.utc(2026, 2, 1, 8, 0);
      final end = DateTime.utc(2026, 2, 1, 9, 0);
      final service = WorkoutHeartRateService(
        dataSource: _FakeHeartRateDataSource(),
      );

      final summary = await service.loadForWorkoutWindow(
        startTime: start,
        endTime: end,
      );

      expect(summary.quality, WorkoutHeartRateDataQuality.noData);
      expect(summary.noDataReason, WorkoutHeartRateNoDataReason.noSamples);
      expect(summary.sampleCount, 0);
      expect(summary.hasSummaryMetrics, isFalse);
    });

    test('uses workout time-window matching and sorts chronologically',
        () async {
      final start = DateTime.utc(2026, 3, 1, 12, 0);
      final end = DateTime.utc(2026, 3, 1, 12, 40);
      final service = WorkoutHeartRateService(
        dataSource: _FakeHeartRateDataSource(
          samples: [
            HealthHeartRateSampleDto(
              sampledAtUtc: start.subtract(const Duration(minutes: 5)),
              bpm: 105,
            ),
            HealthHeartRateSampleDto(
              sampledAtUtc: start.add(const Duration(minutes: 20)),
              bpm: 130,
            ),
            HealthHeartRateSampleDto(
              sampledAtUtc: start.add(const Duration(minutes: 10)),
              bpm: 125,
            ),
            HealthHeartRateSampleDto(
              sampledAtUtc: end.add(const Duration(minutes: 3)),
              bpm: 99,
            ),
            HealthHeartRateSampleDto(
              sampledAtUtc: start.add(const Duration(minutes: 10)),
              bpm: 127,
            ),
          ],
        ),
      );

      final summary = await service.loadForWorkoutWindow(
        startTime: start,
        endTime: end,
      );

      expect(summary.sampleCount, 2);
      expect(summary.samples.first.sampledAtUtc,
          start.add(const Duration(minutes: 10)));
      expect(summary.samples.last.sampledAtUtc,
          start.add(const Duration(minutes: 20)));
      expect(summary.samples.first.bpm, closeTo(126, 0.001));
      expect(summary.quality, WorkoutHeartRateDataQuality.insufficient);
    });

    test('downsamples long sessions while keeping chronological endpoints',
        () async {
      final start = DateTime.utc(2026, 4, 1, 6, 0);
      final end = start.add(const Duration(hours: 8));
      final samples = List.generate(
        480,
        (i) => HealthHeartRateSampleDto(
          sampledAtUtc: start.add(Duration(minutes: i)),
          bpm: 100 + (i % 40).toDouble(),
        ),
      );
      final service = WorkoutHeartRateService(
        dataSource: _FakeHeartRateDataSource(samples: samples),
        maxChartPoints: 80,
      );

      final summary = await service.loadForWorkoutWindow(
        startTime: start,
        endTime: end,
      );

      expect(summary.chartSamples.length, lessThanOrEqualTo(81));
      expect(summary.chartSamples.first.sampledAtUtc,
          summary.samples.first.sampledAtUtc);
      expect(summary.chartSamples.last.sampledAtUtc,
          summary.samples.last.sampledAtUtc);
    });

    test('maps permission errors to noData permissionDenied state', () async {
      final start = DateTime.utc(2026, 5, 1, 10, 0);
      final end = DateTime.utc(2026, 5, 1, 11, 0);
      final service = WorkoutHeartRateService(
        dataSource: _FakeHeartRateDataSource(
          error: PlatformException(
            code: 'permission_denied',
            message: 'Permissions not granted',
          ),
        ),
      );

      final summary = await service.loadForWorkoutWindow(
        startTime: start,
        endTime: end,
      );

      expect(summary.quality, WorkoutHeartRateDataQuality.noData);
      expect(
        summary.noDataReason,
        WorkoutHeartRateNoDataReason.permissionDenied,
      );
    });

    test(
      'retries HR read with a wider window when direct query returns no records',
      () async {
        final start = DateTime.utc(2026, 5, 12, 18, 0);
        final end = DateTime.utc(2026, 5, 12, 19, 0);
        final requests = <_ReadRequest>[];
        final insideWindow = HealthHeartRateSampleDto(
          sampledAtUtc: start.add(const Duration(minutes: 10)),
          bpm: 132,
        );
        final outsideWindow = HealthHeartRateSampleDto(
          sampledAtUtc: start.subtract(const Duration(hours: 1)),
          bpm: 80,
        );
        final service = WorkoutHeartRateService(
          dataSource: _FakeHeartRateDataSource(
            onRead: (fromUtc, toUtc) {
              requests.add(_ReadRequest(fromUtc: fromUtc, toUtc: toUtc));
              if (requests.length == 1) {
                return const <HealthHeartRateSampleDto>[];
              }
              return <HealthHeartRateSampleDto>[outsideWindow, insideWindow];
            },
          ),
        );

        final summary = await service.loadForWorkoutWindow(
          startTime: start,
          endTime: end,
        );

        expect(requests.length, 2);
        expect(requests.first.fromUtc, start);
        expect(requests.first.toUtc, end);
        expect(
          requests.last.fromUtc,
          start.subtract(const Duration(hours: 24)),
        );
        expect(
          requests.last.toUtc,
          end.add(const Duration(hours: 24)),
        );
        expect(summary.sampleCount, 1);
        expect(summary.samples.single.sampledAtUtc, insideWindow.sampledAtUtc);
      },
    );

    test('returns noData for unfinished workouts', () async {
      final start = DateTime.utc(2026, 6, 1, 7, 0);
      final service = WorkoutHeartRateService(
        dataSource: _FakeHeartRateDataSource(),
      );

      final summary = await service.loadForWorkoutWindow(
        startTime: start,
        endTime: null,
      );

      expect(summary.quality, WorkoutHeartRateDataQuality.noData);
      expect(
        summary.noDataReason,
        WorkoutHeartRateNoDataReason.workoutNotFinished,
      );
    });
  });
}
