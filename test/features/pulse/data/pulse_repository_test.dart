import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/pulse/application/pulse_tracking_service.dart';
import 'package:train_libre/features/pulse/data/pulse_repository.dart';
import 'package:train_libre/features/pulse/domain/pulse_models.dart';
import 'package:train_libre/services/health/health_platform_heart_rate.dart';

class _FakeHeartRateDataSource implements HealthHeartRateDataSource {
  _FakeHeartRateDataSource({this.samples = const [], this.error});

  final List<HealthHeartRateSampleDto> samples;
  final Object? error;
  final requests = <(DateTime, DateTime)>[];

  @override
  Future<List<HealthHeartRateSampleDto>> readHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    requests.add((fromUtc, toUtc));
    if (error != null) throw error!;
    return samples
        .where(
          (sample) =>
              !sample.sampledAtUtc.isBefore(fromUtc) &&
              sample.sampledAtUtc.isBefore(toUtc),
        )
        .toList(growable: false);
  }
}

class _FakePulseSettings implements PulseTrackingSettingsService {
  const _FakePulseSettings(this.enabled);

  final bool enabled;

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> setTrackingEnabled(bool enabled) async {}
}

void main() {
  test('does not query platform when pulse tracking is disabled', () async {
    final dataSource = _FakeHeartRateDataSource();
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(false),
    );
    final window = PulseAnalysisWindow(
      startUtc: DateTime.utc(2026, 4, 20),
      endUtc: DateTime.utc(2026, 4, 21),
    );

    final summary = await repository.getAnalysis(window: window);

    expect(summary.noDataReason, PulseNoDataReason.disabled);
    expect(dataSource.requests, isEmpty);
  });

  test('queries padded window and filters final samples to selected window',
      () async {
    final start = DateTime.utc(2026, 4, 20);
    final end = DateTime.utc(2026, 4, 21);
    final dataSource = _FakeHeartRateDataSource(
      samples: [
        HealthHeartRateSampleDto(
          sampledAtUtc: start.subtract(const Duration(minutes: 1)),
          bpm: 60,
        ),
        HealthHeartRateSampleDto(
          sampledAtUtc: start.add(const Duration(hours: 1)),
          bpm: 70,
        ),
      ],
    );
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(true),
      database: database,
    );

    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(startUtc: start, endUtc: end),
    );

    expect(dataSource.requests.single, (
      start.subtract(const Duration(hours: 24)),
      end.add(const Duration(hours: 24))
    ));
    expect(summary.sampleCount, 1);
    expect(summary.averageBpm, 70);
  });

  test('maps permission error to permission no-data state', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(
        error: PlatformException(code: 'permission_denied'),
      ),
      trackingService: const _FakePulseSettings(true),
      database: database,
    );
    final window = PulseAnalysisWindow(
      startUtc: DateTime.utc(2026, 4, 20),
      endUtc: DateTime.utc(2026, 4, 21),
    );

    final summary = await repository.getAnalysis(window: window);

    expect(summary.noDataReason, PulseNoDataReason.permissionDenied);
  });

  test(
      'uses aggregate cache on second hub open without reprocessing raw samples',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = _syntheticSamples(start, 160000);
    final dataSource = _FakeHeartRateDataSource(samples: samples);
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(days: 120)),
    );

    final first = await repository.getAnalysis(window: window);
    final second = await repository.getAnalysis(window: window);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(first.sampleCount, 160000);
    expect(second.sampleCount, 160000);
    expect(dataSource.requests.length, lessThanOrEqualTo(2));
    if (dataSource.requests.length == 2) {
      expect(dataSource.requests.last.$1.isAfter(start), isTrue);
    }
  });

  test('larger older window triggers leading backfill before summary',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = _syntheticSamples(
      start,
      30 * 24,
      step: const Duration(hours: 1),
    );
    final dataSource = _FakeHeartRateDataSource(samples: samples);
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );
    final recentWindow = PulseAnalysisWindow(
      startUtc: start.add(const Duration(days: 23)),
      endUtc: start.add(const Duration(days: 30)),
    );
    final fullWindow = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(days: 30)),
    );

    await repository.getAnalysis(window: recentWindow);
    final summary = await repository.getAnalysis(window: fullWindow);

    expect(dataSource.requests.length, 2);
    expect(
        dataSource.requests.last, (fullWindow.startUtc, recentWindow.startUtc));
    expect(summary.sampleCount, 30 * 24);
  });

  test('single cached bucket does not cover a much larger window', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final sampleAt = start.add(const Duration(days: 10));
    final dataSource = _FakeHeartRateDataSource(
      samples: [
        HealthHeartRateSampleDto(sampledAtUtc: sampleAt, bpm: 70),
      ],
    );
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: sampleAt,
        endUtc: sampleAt.add(const Duration(hours: 1)),
      ),
    );
    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 20)),
      ),
    );

    expect(dataSource.requests.length, greaterThanOrEqualTo(2));
    expect(dataSource.requests[1].$1, start);
    expect(dataSource.requests[1].$2, sampleAt);
    expect(summary.sampleCount, 1);
  });

  test('trailing new data is refreshed incrementally after cached range',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = _syntheticSamples(
      start,
      48,
      step: const Duration(hours: 1),
    );
    final dataSource = _FakeHeartRateDataSource(samples: samples);
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(days: 1)),
    );
    final expandedWindow = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(days: 2)),
    );

    await repository.getAnalysis(window: window);
    final cachedSummary = await repository.getAnalysis(window: expandedWindow);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(dataSource.requests.length, 2);
    expect(cachedSummary.sampleCount, 24);
    expect(dataSource.requests.last.$1, start.add(const Duration(days: 1)));
  });

  test('weighted aggregate average and min/max preserve raw values', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = [
      HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 50),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(minutes: 10)),
        bpm: 100,
      ),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(hours: 1)),
        bpm: 200,
      ),
    ];
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(hours: 2)),
      ),
    );

    expect(summary.averageBpm, closeTo((50 + 100 + 200) / 3, 0.001));
    expect(summary.minBpm, 50);
    expect(summary.maxBpm, 200);
  });

  test('weighted aggregate metrics include leading backfilled range', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = [
      HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 40),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(hours: 1)),
        bpm: 80,
      ),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(days: 7)),
        bpm: 120,
      ),
    ];
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start.add(const Duration(days: 7)),
        endUtc: start.add(const Duration(days: 7, hours: 1)),
      ),
    );
    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 8)),
      ),
    );

    expect(summary.sampleCount, 3);
    expect(summary.averageBpm, closeTo(80, 0.001));
    expect(summary.minBpm, 40);
    expect(summary.maxBpm, 120);
  });

  test('resting estimate is stable from aggregate buckets', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = [
      for (var hour = 0; hour < 10; hour++)
        HealthHeartRateSampleDto(
          sampledAtUtc: start.add(Duration(hours: hour)),
          bpm: (60 + hour).toDouble(),
        ),
    ];
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(hours: 10)),
      ),
    );

    expect(summary.restingBpm, closeTo(60.5, 0.001));
  });

  test('detail chart is capped and covers the selected range', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 1, 1);
    final samples = _syntheticSamples(start, 160000);
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(Duration(minutes: samples.length)),
    );

    final summary = await repository.getAnalysis(window: window);

    expect(summary.chartSamples.length, lessThanOrEqualTo(2000));
    expect(summary.chartSamples.first.sampledAtUtc.isAfter(window.startUtc),
        isTrue);
    expect(
        summary.chartSamples.last.sampledAtUtc.isBefore(window.endUtc), isTrue);
  });
}

List<HealthHeartRateSampleDto> _syntheticSamples(
  DateTime start,
  int count, {
  Duration step = const Duration(minutes: 1),
}) {
  return [
    for (var i = 0; i < count; i++)
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(step * i),
        bpm: (55 + (i % 80)).toDouble(),
      ),
  ];
}
