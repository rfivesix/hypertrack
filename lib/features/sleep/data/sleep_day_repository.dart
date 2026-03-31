import '../../../data/drift_database.dart';
import '../domain/derived/nightly_sleep_analysis.dart';
import '../domain/sleep_domain.dart';
import 'persistence/dao/sleep_canonical_dao.dart';
import 'persistence/dao/sleep_nightly_analyses_dao.dart';

class SleepHeartRateContext {
  const SleepHeartRateContext({
    required this.sleepHrAvg,
    required this.baselineSleepHr,
    required this.deltaSleepHr,
    required this.isBaselineEstablished,
  });

  final double? sleepHrAvg;
  final double? baselineSleepHr;
  final double? deltaSleepHr;
  final bool isBaselineEstablished;
}

class SleepDayOverviewData {
  const SleepDayOverviewData({
    required this.analysis,
    required this.session,
    required this.timelineSegments,
    required this.totalSleepMinutes,
    required this.sleepHrAvg,
    required this.baselineSleepHr,
    required this.deltaSleepHr,
    required this.isHrBaselineEstablished,
    required this.interruptionsCount,
    required this.interruptionsWakeDuration,
    required this.deepDuration,
    required this.lightDuration,
    required this.remDuration,
    required this.regularityNights,
    required this.stageDataConfidence,
  });

  final NightlySleepAnalysis analysis;
  final SleepSession session;
  final List<SleepStageSegment> timelineSegments;
  final int? totalSleepMinutes;
  final double? sleepHrAvg;
  final double? baselineSleepHr;
  final double? deltaSleepHr;
  final bool isHrBaselineEstablished;
  final int interruptionsCount;
  final Duration interruptionsWakeDuration;
  final Duration deepDuration;
  final Duration lightDuration;
  final Duration remDuration;
  final List<SleepRegularityNight> regularityNights;
  final SleepStageConfidence stageDataConfidence;

  Duration get totalSleepDuration {
    if (totalSleepMinutes != null) {
      return Duration(minutes: totalSleepMinutes!);
    }
    var total = Duration.zero;
    for (final segment in timelineSegments) {
      if (segment.stage == CanonicalSleepStage.awake ||
          segment.stage == CanonicalSleepStage.outOfBed) {
        continue;
      }
      total += segment.endAtUtc.difference(segment.startAtUtc);
    }
    return total;
  }

  bool get hasStageData =>
      timelineSegments.any((segment) =>
          segment.stage == CanonicalSleepStage.deep ||
          segment.stage == CanonicalSleepStage.light ||
          segment.stage == CanonicalSleepStage.rem ||
          segment.stage == CanonicalSleepStage.asleepUnspecified);
}

abstract class SleepDayDataRepository {
  Future<SleepDayOverviewData?> fetchOverview(DateTime day);
  Future<void> dispose();
}

class SleepDayRepository implements SleepDayDataRepository {
  SleepDayRepository({AppDatabase? database})
      : this._(database ?? AppDatabase());

  SleepDayRepository._(this._database)
      : _analysesDao = SleepNightlyAnalysesDao(_database),
        _sessionsDao = SleepCanonicalSessionsDao(_database),
        _segmentsDao = SleepCanonicalStageSegmentsDao(_database),
        _heartRateDao = SleepCanonicalHeartRateSamplesDao(_database);

  final AppDatabase _database;
  final SleepNightlyAnalysesDao _analysesDao;
  final SleepCanonicalSessionsDao _sessionsDao;
  final SleepCanonicalStageSegmentsDao _segmentsDao;
  final SleepCanonicalHeartRateSamplesDao _heartRateDao;

  @override
  Future<SleepDayOverviewData?> fetchOverview(DateTime day) async {
    final key = _nightKey(day);
    final analyses = await _analysesDao.findByNightRange(
      fromNightDateInclusive: key,
      toNightDateInclusive: key,
    );
    if (analyses.isEmpty) return null;
    analyses.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    final record = analyses.first;

    final sessionRecord = await _sessionsDao.findById(record.sessionId);
    if (sessionRecord == null) return null;

    final session = SleepSession(
      id: sessionRecord.id,
      startAtUtc: sessionRecord.startedAt,
      endAtUtc: sessionRecord.endedAt,
      sessionType: _parseSessionType(sessionRecord.sessionType),
      sourcePlatform: sessionRecord.sourcePlatform,
      sourceAppId: sessionRecord.sourceAppId,
      sourceRecordHash: sessionRecord.sourceRecordHash,
      sourceConfidence: sessionRecord.sourceConfidence,
      stageConfidence: _confidenceFromSource(sessionRecord.sourceConfidence),
    );

    final segments = (await _segmentsDao.findBySessionId(session.id))
        .map(
          (row) => SleepStageSegment(
            id: row.id,
            sessionId: row.sessionId,
            stage: _parseStage(row.stage),
            startAtUtc: row.startedAt,
            endAtUtc: row.endedAt,
            sourcePlatform: row.sourcePlatform,
            sourceAppId: row.sourceAppId,
            sourceRecordHash: row.sourceRecordHash,
            sourceConfidence: row.sourceConfidence,
            stageConfidence: _confidenceFromSource(row.sourceConfidence),
          ),
        )
        .toList(growable: false);

    final regularityNights = await _fetchRegularityNights(day);
    final hrContext = await _fetchHeartRateContext(
      day: day,
      currentSessionId: session.id,
      fallbackCurrentAvg: record.restingHeartRateBpm,
    );

    final wakeSegments = segments.where((segment) {
      if (segment.stage != CanonicalSleepStage.awake &&
          segment.stage != CanonicalSleepStage.outOfBed) {
        return false;
      }
      final minutes = segment.endAtUtc
          .difference(segment.startAtUtc)
          .inMinutes;
      return minutes >= 5;
    }).toList(growable: false);

    final interruptionsWakeDuration = wakeSegments.fold<Duration>(
      Duration.zero,
      (total, segment) => total + segment.endAtUtc.difference(segment.startAtUtc),
    );

    final deepDuration = _sumStageDuration(segments, CanonicalSleepStage.deep);
    final lightDuration = _sumStageDuration(segments, CanonicalSleepStage.light);
    final remDuration = _sumStageDuration(segments, CanonicalSleepStage.rem);

    final analysis = NightlySleepAnalysis(
      id: record.id,
      sessionId: record.sessionId,
      nightDate: DateTime.parse(record.nightDate),
      analysisVersion: record.analysisVersion,
      normalizationVersion: record.normalizationVersion,
      analyzedAtUtc: record.analyzedAt.toUtc(),
      score: record.score,
      sleepQuality: _qualityFromScore(record.score),
      sourcePlatform: record.sourcePlatform,
      sourceAppId: record.sourceAppId,
      sourceRecordHash: record.sourceRecordHash,
    );

    return SleepDayOverviewData(
      analysis: analysis,
      session: session,
      timelineSegments: segments,
      totalSleepMinutes: record.totalSleepMinutes,
      sleepHrAvg: hrContext.sleepHrAvg,
      baselineSleepHr: hrContext.baselineSleepHr,
      deltaSleepHr: hrContext.deltaSleepHr,
      isHrBaselineEstablished: hrContext.isBaselineEstablished,
      interruptionsCount: wakeSegments.length,
      interruptionsWakeDuration: interruptionsWakeDuration,
      deepDuration: deepDuration,
      lightDuration: lightDuration,
      remDuration: remDuration,
      regularityNights: regularityNights,
      stageDataConfidence: _timelineConfidence(segments),
    );
  }

  Future<List<SleepRegularityNight>> _fetchRegularityNights(DateTime day) async {
    final to = day.toUtc();
    final from = to.subtract(const Duration(days: 6));
    final analyses = await _analysesDao.findByNightRange(
      fromNightDateInclusive: _nightKey(from),
      toNightDateInclusive: _nightKey(to),
    );
    if (analyses.isEmpty) return const [];
    final List<SleepRegularityNight> result = [];
    for (final analysis in analyses) {
      final sessionRecord = await _sessionsDao.findById(analysis.sessionId);
      if (sessionRecord == null) continue;
      result.add(
        SleepRegularityNight(
          nightDate: DateTime.parse(analysis.nightDate),
          bedtimeMinutes:
              sessionRecord.startedAt.toLocal().hour * 60 +
                  sessionRecord.startedAt.toLocal().minute,
          wakeMinutes:
              sessionRecord.endedAt.toLocal().hour * 60 +
                  sessionRecord.endedAt.toLocal().minute,
        ),
      );
    }
    result.sort((a, b) => a.nightDate.compareTo(b.nightDate));
    return result;
  }

  Future<SleepHeartRateContext> _fetchHeartRateContext({
    required DateTime day,
    required String currentSessionId,
    required double? fallbackCurrentAvg,
  }) async {
    double? currentAvg = await _averageHeartRateForSession(currentSessionId);
    currentAvg ??= fallbackCurrentAvg;

    final to = _nightKey(day);
    final from = _nightKey(day.subtract(const Duration(days: 14)));
    final analyses = await _analysesDao.findByNightRange(
      fromNightDateInclusive: from,
      toNightDateInclusive: to,
    );

    final baselines = <double>[];
    for (final analysis in analyses) {
      if (analysis.sessionId == currentSessionId) {
        continue;
      }
      final avg = await _averageHeartRateForSession(analysis.sessionId);
      if (avg != null) {
        baselines.add(avg);
      }
    }

    if (baselines.length < 3) {
      return SleepHeartRateContext(
        sleepHrAvg: currentAvg,
        baselineSleepHr: null,
        deltaSleepHr: null,
        isBaselineEstablished: false,
      );
    }

    final baseline =
        baselines.reduce((a, b) => a + b) / baselines.length;
    return SleepHeartRateContext(
      sleepHrAvg: currentAvg,
      baselineSleepHr: baseline,
      deltaSleepHr: currentAvg == null ? null : currentAvg - baseline,
      isBaselineEstablished: true,
    );
  }

  Future<double?> _averageHeartRateForSession(String sessionId) async {
    final samples = await _heartRateDao.findBySessionId(sessionId);
    if (samples.isEmpty) return null;
    return samples.map((sample) => sample.bpm).reduce((a, b) => a + b) /
        samples.length;
  }

  Duration _sumStageDuration(
    List<SleepStageSegment> segments,
    CanonicalSleepStage stage,
  ) {
    return segments.where((segment) => segment.stage == stage).fold<Duration>(
          Duration.zero,
          (value, segment) => value + segment.endAtUtc.difference(segment.startAtUtc),
        );
  }

  SleepStageConfidence _timelineConfidence(List<SleepStageSegment> segments) {
    if (segments.isEmpty) return SleepStageConfidence.low;
    if (segments.any((segment) => segment.stageConfidence == SleepStageConfidence.low)) {
      return SleepStageConfidence.low;
    }
    if (segments.any((segment) => segment.stageConfidence == SleepStageConfidence.medium)) {
      return SleepStageConfidence.medium;
    }
    return SleepStageConfidence.high;
  }

  SleepSessionType _parseSessionType(String value) {
    return SleepSessionType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => SleepSessionType.unknown,
    );
  }

  CanonicalSleepStage _parseStage(String value) {
    return CanonicalSleepStage.values.firstWhere(
      (item) => item.name == value,
      orElse: () => CanonicalSleepStage.unknown,
    );
  }

  SleepStageConfidence _confidenceFromSource(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'high' => SleepStageConfidence.high,
      'medium' => SleepStageConfidence.medium,
      'low' => SleepStageConfidence.low,
      _ => SleepStageConfidence.unknown,
    };
  }

  SleepQualityBucket _qualityFromScore(double? score) {
    if (score == null) return SleepQualityBucket.unavailable;
    if (score >= 80) return SleepQualityBucket.good;
    if (score >= 60) return SleepQualityBucket.average;
    return SleepQualityBucket.poor;
  }

  String _nightKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final mm = normalized.month.toString().padLeft(2, '0');
    final dd = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$mm-$dd';
  }

  @override
  Future<void> dispose() => _database.close();
}
