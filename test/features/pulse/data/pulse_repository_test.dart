import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/pulse/application/pulse_tracking_service.dart';
import 'package:hypertrack/features/pulse/data/pulse_repository.dart';
import 'package:hypertrack/features/pulse/domain/pulse_models.dart';
import 'package:hypertrack/services/health/health_platform_heart_rate.dart';

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
    return samples;
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
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(true),
    );

    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(startUtc: start, endUtc: end),
    );

    expect(dataSource.requests.single, (
      start.subtract(const Duration(hours: 24)),
      end.add(const Duration(hours: 24))
    ));
    expect(summary.sampleCount, 1);
    expect(summary.samples.single.bpm, 70);
  });

  test('maps permission error to permission no-data state', () async {
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(
        error: PlatformException(code: 'permission_denied'),
      ),
      trackingService: const _FakePulseSettings(true),
    );
    final window = PulseAnalysisWindow(
      startUtc: DateTime.utc(2026, 4, 20),
      endUtc: DateTime.utc(2026, 4, 21),
    );

    final summary = await repository.getAnalysis(window: window);

    expect(summary.noDataReason, PulseNoDataReason.permissionDenied);
  });
}
