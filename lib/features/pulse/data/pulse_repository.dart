import 'package:flutter/services.dart';

import '../../../services/health/health_platform_heart_rate.dart';
import '../application/pulse_tracking_service.dart';
import '../domain/pulse_analysis_engine.dart';
import '../domain/pulse_models.dart';

abstract class PulseAnalysisRepository {
  Future<bool> isTrackingEnabled();
  Future<PulseAnalysisSummary> getAnalysis({
    required PulseAnalysisWindow window,
  });
}

class HealthPulseAnalysisRepository implements PulseAnalysisRepository {
  HealthPulseAnalysisRepository({
    HealthHeartRateDataSource? dataSource,
    PulseTrackingSettingsService? trackingService,
    PulseAnalysisEngine engine = const PulseAnalysisEngine(),
    this.queryPadding = const Duration(hours: 24),
  })  : _dataSource = dataSource ?? const HealthPlatformHeartRate(),
        _trackingService = trackingService ?? PulseTrackingService(),
        _engine = engine;

  final HealthHeartRateDataSource _dataSource;
  final PulseTrackingSettingsService _trackingService;
  final PulseAnalysisEngine _engine;
  final Duration queryPadding;

  @override
  Future<bool> isTrackingEnabled() => _trackingService.isTrackingEnabled();

  @override
  Future<PulseAnalysisSummary> getAnalysis({
    required PulseAnalysisWindow window,
  }) async {
    final enabled = await _trackingService.isTrackingEnabled();
    if (!enabled) {
      return _engine.analyze(
        window: window,
        rawSamples: const <PulseSamplePoint>[],
        emptyReason: PulseNoDataReason.disabled,
      );
    }

    try {
      final rows = await _dataSource.readHeartRateSamples(
        fromUtc: window.startUtc.subtract(queryPadding),
        toUtc: window.endUtc.add(queryPadding),
      );
      final samples = rows
          .map(
            (row) => PulseSamplePoint(
              sampledAtUtc: row.sampledAtUtc.toUtc(),
              bpm: row.bpm,
            ),
          )
          .toList(growable: false);
      return _engine.analyze(window: window, rawSamples: samples);
    } on MissingPluginException {
      return _empty(window, PulseNoDataReason.platformUnavailable);
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied') {
        return _empty(window, PulseNoDataReason.permissionDenied);
      }
      if (error.code == 'not_available') {
        return _empty(window, PulseNoDataReason.platformUnavailable);
      }
      return _empty(window, PulseNoDataReason.queryFailed);
    } catch (_) {
      return _empty(window, PulseNoDataReason.queryFailed);
    }
  }

  PulseAnalysisSummary _empty(
    PulseAnalysisWindow window,
    PulseNoDataReason reason,
  ) {
    return _engine.analyze(
      window: window,
      rawSamples: const <PulseSamplePoint>[],
      emptyReason: reason,
    );
  }
}
