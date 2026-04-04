import 'dart:math' as math;

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart';
import 'persistence/dao/sleep_canonical_dao.dart';
import 'persistence/dao/sleep_nightly_analyses_dao.dart';
import 'persistence/sleep_persistence_models.dart';
import 'processing/timeline_repair.dart';
import '../domain/metrics/nightly_metrics_calculator.dart';
import '../domain/sleep_domain.dart';

class SleepHubSummary {
  const SleepHubSummary({
    this.averageScore,
    this.averageDuration,
    this.averageBedtimeMinutes,
    this.averageInterruptions,
    this.averageWakeDuration,
    this.nightsCount = 0,
  });

  final double? averageScore;
  final Duration? averageDuration;
  final int? averageBedtimeMinutes;
  final double? averageInterruptions;
  final Duration? averageWakeDuration;
  final int nightsCount;

  bool get hasData => nightsCount > 0;
}

class SleepHubSummaryRepository {
  SleepHubSummaryRepository({
    AppDatabase? database,
    DatabaseHelper? databaseHelper,
  })  : _databaseFuture = database != null
            ? Future.value(database)
            : (databaseHelper ?? DatabaseHelper.instance).database,
        _ownsDatabase = database != null && databaseHelper == null;

  final Future<AppDatabase> _databaseFuture;
  final bool _ownsDatabase;

  AppDatabase? _database;
  SleepNightlyAnalysesDao? _analysesDao;
  SleepCanonicalSessionsDao? _sessionsDao;
  SleepCanonicalStageSegmentsDao? _segmentsDao;

  Future<SleepHubSummary> fetchSummary({
    required DateTime endDate,
    required int daysBack,
  }) async {
    if (daysBack <= 0) return const SleepHubSummary();
    await _ensureDaos();

    final endLocal = DateTime(endDate.year, endDate.month, endDate.day);
    final startLocal = endLocal.subtract(Duration(days: daysBack - 1));
    final analyses = await _analysesDao!.findByNightRange(
      fromNightDateInclusive: _nightKey(startLocal),
      toNightDateInclusive: _nightKey(endLocal),
    );

    if (analyses.isEmpty) return const SleepHubSummary();

    final latestByDate = _latestAnalysesByDate(analyses);
    final sessions = await _sessionsDao!.findByDateRange(
      fromInclusive: startLocal,
      toExclusive: endLocal.add(const Duration(days: 1)),
    );
    final sessionsById = {for (final session in sessions) session.id: session};

    final scoreValues = <double>[];
    final durationMinutes = <int>[];
    final bedtimeMinutes = <int>[];
    final interruptions = <int>[];
    final wakeMinutes = <int>[];

    for (final analysis in latestByDate.values) {
      if (analysis.score != null) {
        scoreValues.add(analysis.score!);
      }
      if (analysis.totalSleepMinutes != null &&
          analysis.totalSleepMinutes! > 0) {
        durationMinutes.add(analysis.totalSleepMinutes!);
      }

      final sessionRecord = sessionsById[analysis.sessionId];
      if (sessionRecord == null) continue;
      final session = _toDomainSession(sessionRecord);

      final localStart = session.startAtUtc.toLocal();
      bedtimeMinutes.add(localStart.hour * 60 + localStart.minute);

      final segmentRows = await _segmentsDao!.findBySessionId(session.id);
      if (segmentRows.isEmpty) continue;
      final segments =
          segmentRows.map(_toDomainSegment).toList(growable: false);
      final repaired = repairSleepTimeline(
        session: session,
        segments: segments,
      );
      if (repaired.isEmpty) continue;
      final metrics = calculateNightlySleepMetrics(
        session: session,
        repairedSegments: repaired,
      );
      interruptions.add(metrics.interruptionsCount);
      wakeMinutes.add(metrics.totalWakeDuration.inMinutes);
    }

    return SleepHubSummary(
      averageScore: _meanDouble(scoreValues),
      averageDuration: _meanDuration(durationMinutes),
      averageBedtimeMinutes: _circularMeanMinutes(bedtimeMinutes),
      averageInterruptions: _meanDouble(
        interruptions.map((value) => value.toDouble()).toList(),
      ),
      averageWakeDuration: _meanDuration(wakeMinutes),
      nightsCount: latestByDate.length,
    );
  }

  Future<void> dispose() async {
    if (_ownsDatabase) {
      final db = _database ?? await _databaseFuture;
      await db.close();
    }
  }

  Future<void> _ensureDaos() async {
    final db = _database ??= await _databaseFuture;
    _analysesDao ??= SleepNightlyAnalysesDao(db);
    _sessionsDao ??= SleepCanonicalSessionsDao(db);
    _segmentsDao ??= SleepCanonicalStageSegmentsDao(db);
  }

  Map<DateTime, SleepNightlyAnalysisRecord> _latestAnalysesByDate(
    List<SleepNightlyAnalysisRecord> analyses,
  ) {
    final byDate = <DateTime, SleepNightlyAnalysisRecord>{};
    for (final analysis in analyses) {
      final key = _normalizeDate(DateTime.parse(analysis.nightDate));
      final existing = byDate[key];
      if (existing == null ||
          analysis.analyzedAt.isAfter(existing.analyzedAt)) {
        byDate[key] = analysis;
      }
    }
    return byDate;
  }

  double? _meanDouble(List<double> values) {
    if (values.isEmpty) return null;
    final sum = values.fold<double>(0, (total, value) => total + value);
    return sum / values.length;
  }

  Duration? _meanDuration(List<int> minutes) {
    if (minutes.isEmpty) return null;
    final sum = minutes.fold<int>(0, (total, value) => total + value);
    return Duration(minutes: (sum / minutes.length).round());
  }

  int? _circularMeanMinutes(List<int> minutes) {
    if (minutes.isEmpty) return null;
    var sumSin = 0.0;
    var sumCos = 0.0;
    for (final value in minutes) {
      final angle = (value / 1440) * 2 * math.pi;
      sumSin += math.sin(angle);
      sumCos += math.cos(angle);
    }
    if (sumSin.abs() < 1e-6 && sumCos.abs() < 1e-6) return null;
    final avgAngle = math.atan2(
      sumSin / minutes.length,
      sumCos / minutes.length,
    );
    final normalized = avgAngle < 0 ? avgAngle + 2 * math.pi : avgAngle;
    final avgMinutes = (normalized / (2 * math.pi) * 1440).round() % 1440;
    return avgMinutes;
  }

  SleepSession _toDomainSession(SleepCanonicalSessionRecord record) {
    return SleepSession(
      id: record.id,
      startAtUtc: record.startedAt,
      endAtUtc: record.endedAt,
      sessionType: _parseSessionType(record.sessionType),
      sourcePlatform: record.sourcePlatform,
      sourceAppId: record.sourceAppId,
      sourceRecordHash: record.sourceRecordHash,
      sourceConfidence: record.sourceConfidence,
      stageConfidence: _parseStageConfidence(record.sourceConfidence),
      overallConfidence: _parseOverallConfidence(record.sourceConfidence),
      normalizationVersion: record.normalizationVersion,
    );
  }

  SleepStageSegment _toDomainSegment(SleepCanonicalStageSegmentRecord row) {
    return SleepStageSegment(
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
    );
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

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _nightKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
