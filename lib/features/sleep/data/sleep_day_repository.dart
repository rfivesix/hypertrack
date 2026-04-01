import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart';
import '../domain/sleep_domain.dart';
import 'persistence/dao/sleep_canonical_dao.dart';
import 'persistence/dao/sleep_nightly_analyses_dao.dart';

class SleepRegularityNight {
  const SleepRegularityNight({
    required this.nightDate,
    required this.bedtimeMinutes,
    required this.wakeMinutes,
  });

  final DateTime nightDate;
  final int bedtimeMinutes;
  final int wakeMinutes;
}

class SleepDayOverviewData {
  const SleepDayOverviewData({
    required this.analysis,
    required this.session,
    required this.timelineSegments,
    required this.stageDataConfidence,
    required this.totalSleepMinutes,
    required this.sleepHrAvg,
    this.baselineSleepHr,
    this.deltaSleepHr,
    this.interruptionsCount,
    this.interruptionsWakeDuration,
    this.deepDuration,
    this.lightDuration,
    this.remDuration,
    this.regularityNights = const <SleepRegularityNight>[],
  });

  final NightlySleepAnalysis analysis;
  final SleepSession session;
  final List<SleepStageSegment> timelineSegments;
  final SleepStageConfidence stageDataConfidence;
  final int? totalSleepMinutes;
  final double? sleepHrAvg;
  final double? baselineSleepHr;
  final double? deltaSleepHr;
  final int? interruptionsCount;
  final Duration? interruptionsWakeDuration;
  final Duration? deepDuration;
  final Duration? lightDuration;
  final Duration? remDuration;
  final List<SleepRegularityNight> regularityNights;

  Duration get totalSleepDuration {
    if (totalSleepMinutes != null) {
      return Duration(minutes: totalSleepMinutes!);
    }
    return session.endAtUtc.difference(session.startAtUtc);
  }

  bool get hasStageData => timelineSegments.any(
        (segment) =>
            segment.stage == CanonicalSleepStage.deep ||
            segment.stage == CanonicalSleepStage.light ||
            segment.stage == CanonicalSleepStage.rem ||
            segment.stage == CanonicalSleepStage.asleepUnspecified,
      );

  bool get hasStageDurations =>
      (deepDuration?.inMinutes ?? 0) > 0 ||
      (lightDuration?.inMinutes ?? 0) > 0 ||
      (remDuration?.inMinutes ?? 0) > 0;

  bool get hasHeartRateBaseline =>
      baselineSleepHr != null && deltaSleepHr != null;
}

abstract class SleepDayDataRepository {
  Future<SleepDayOverviewData?> fetchOverview(DateTime day);
  Future<void> dispose();
}

class SleepDayRepository implements SleepDayDataRepository {
  SleepDayRepository({
    AppDatabase? database,
    DatabaseHelper? databaseHelper,
    bool ownsDatabase = false,
  })  : _databaseFuture = database != null
            ? Future.value(database)
            : (databaseHelper ?? DatabaseHelper.instance).database,
        _ownsDatabase = ownsDatabase && database != null;

  final Future<AppDatabase> _databaseFuture;
  final bool _ownsDatabase;
  AppDatabase? _database;
  SleepNightlyAnalysesDao? _analysesDao;
  SleepCanonicalSessionsDao? _sessionsDao;
  SleepCanonicalStageSegmentsDao? _segmentsDao;

  @override
  Future<SleepDayOverviewData?> fetchOverview(DateTime day) async {
    await _ensureDaos();
    final key = _nightKey(day);
    final analyses = await _analysesDao!.findByNightRange(
      fromNightDateInclusive: key,
      toNightDateInclusive: key,
    );
    if (analyses.isEmpty) return null;

    analyses.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    final record = analyses.first;
    final sessionRecord = await _sessionsDao!.findById(record.sessionId);
    if (sessionRecord == null) return null;

    final segments = (await _segmentsDao!.findBySessionId(record.sessionId))
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
            stageConfidence: _parseStageConfidence(row.sourceConfidence),
          ),
        )
        .toList(growable: false);

    final session = SleepSession(
      id: sessionRecord.id,
      startAtUtc: sessionRecord.startedAt,
      endAtUtc: sessionRecord.endedAt,
      sessionType: _parseSessionType(sessionRecord.sessionType),
      sourcePlatform: sessionRecord.sourcePlatform,
      sourceAppId: sessionRecord.sourceAppId,
      sourceRecordHash: sessionRecord.sourceRecordHash,
      sourceConfidence: sessionRecord.sourceConfidence,
      stageConfidence: _parseStageConfidence(sessionRecord.sourceConfidence),
      overallConfidence: _parseOverallConfidence(
        sessionRecord.sourceConfidence,
      ),
      normalizationVersion: sessionRecord.normalizationVersion,
    );

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

    final deepDuration = _sumStageDuration(segments, CanonicalSleepStage.deep);
    final lightDuration = _sumStageDuration(
      segments,
      CanonicalSleepStage.light,
    );
    final remDuration = _sumStageDuration(segments, CanonicalSleepStage.rem);
    final regularityNights = await _fetchRegularityNights(day);

    return SleepDayOverviewData(
      analysis: analysis,
      session: session,
      timelineSegments: segments,
      stageDataConfidence: _timelineConfidence(segments),
      totalSleepMinutes: record.totalSleepMinutes,
      sleepHrAvg: record.restingHeartRateBpm,
      interruptionsCount: null,
      interruptionsWakeDuration: null,
      deepDuration: deepDuration,
      lightDuration: lightDuration,
      remDuration: remDuration,
      regularityNights: regularityNights,
    );
  }

  @override
  Future<void> dispose() async {
    if (_ownsDatabase) {
      final db = _database ?? await _databaseFuture;
      await db.close();
    }
  }

  CanonicalSleepStage _parseStage(String value) {
    return CanonicalSleepStage.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => CanonicalSleepStage.unknown,
    );
  }

  SleepSessionType _parseSessionType(String value) {
    return SleepSessionType.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => SleepSessionType.unknown,
    );
  }

  SleepStageConfidence _parseStageConfidence(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'high' => SleepStageConfidence.high,
      'medium' => SleepStageConfidence.medium,
      'low' => SleepStageConfidence.low,
      _ => SleepStageConfidence.unknown,
    };
  }

  SleepOverallConfidence _parseOverallConfidence(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'high' => SleepOverallConfidence.high,
      'medium' => SleepOverallConfidence.medium,
      'low' => SleepOverallConfidence.low,
      _ => SleepOverallConfidence.unknown,
    };
  }

  SleepStageConfidence _timelineConfidence(List<SleepStageSegment> segments) {
    if (segments.isEmpty) return SleepStageConfidence.unknown;
    if (segments.every(
      (segment) => segment.stageConfidence == SleepStageConfidence.unknown,
    )) {
      return SleepStageConfidence.unknown;
    }
    if (segments.any(
      (segment) => segment.stageConfidence == SleepStageConfidence.low,
    )) {
      return SleepStageConfidence.low;
    }
    if (segments.any(
      (segment) => segment.stageConfidence == SleepStageConfidence.medium,
    )) {
      return SleepStageConfidence.medium;
    }
    if (segments.any(
      (segment) => segment.stageConfidence == SleepStageConfidence.high,
    )) {
      return SleepStageConfidence.high;
    }
    return SleepStageConfidence.unknown;
  }

  SleepQualityBucket _qualityFromScore(double? score) {
    if (score == null) return SleepQualityBucket.unavailable;
    if (score >= 80) return SleepQualityBucket.good;
    if (score >= 60) return SleepQualityBucket.average;
    return SleepQualityBucket.poor;
  }

  Future<List<SleepRegularityNight>> _fetchRegularityNights(
    DateTime day,
  ) async {
    await _ensureDaos();
    final to = _nightKey(day);
    final from = _nightKey(day.subtract(const Duration(days: 6)));
    final analyses = await _analysesDao!.findByNightRange(
      fromNightDateInclusive: from,
      toNightDateInclusive: to,
    );
    final result = <SleepRegularityNight>[];
    for (final analysis in analyses) {
      final session = await _sessionsDao!.findById(analysis.sessionId);
      if (session == null) continue;
      result.add(
        SleepRegularityNight(
          nightDate: DateTime.parse(analysis.nightDate),
          bedtimeMinutes: session.startedAt.toLocal().hour * 60 +
              session.startedAt.toLocal().minute,
          wakeMinutes: session.endedAt.toLocal().hour * 60 +
              session.endedAt.toLocal().minute,
        ),
      );
    }
    result.sort((a, b) => a.nightDate.compareTo(b.nightDate));
    return result;
  }

  Duration _sumStageDuration(
    List<SleepStageSegment> segments,
    CanonicalSleepStage stage,
  ) {
    return segments.where((segment) => segment.stage == stage).fold<Duration>(
          Duration.zero,
          (total, segment) =>
              total + segment.endAtUtc.difference(segment.startAtUtc),
        );
  }

  String _nightKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final dayPart = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$dayPart';
  }

  Future<void> _ensureDaos() async {
    if (_analysesDao != null) return;
    final db = _database ??= await _databaseFuture;
    _analysesDao = SleepNightlyAnalysesDao(db);
    _sessionsDao = SleepCanonicalSessionsDao(db);
    _segmentsDao = SleepCanonicalStageSegmentsDao(db);
  }
}
