import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/drift_database.dart';
import '../../domain/metrics/nightly_metrics_calculator.dart';
import '../../domain/metrics/sleep_regularity_index.dart';
import '../../domain/sleep_domain.dart';
import '../../domain/scoring/sleep_scoring_engine.dart';
import '../../platform/ingestion/sleep_ingestion_models.dart';
import '../mapping/health_connect_mapper.dart';
import '../mapping/healthkit_mapper.dart';
import '../persistence/dao/sleep_canonical_dao.dart';
import '../persistence/dao/sleep_nightly_analyses_dao.dart';
import '../persistence/dao/sleep_raw_imports_dao.dart';
import '../persistence/sleep_persistence_models.dart';
import 'timeline_repair.dart';

class SleepPipelineRunResult {
  const SleepPipelineRunResult({
    required this.importedSessions,
    required this.analyzedNights,
  });

  final int importedSessions;
  final int analyzedNights;
}

class SleepPipelineService {
  SleepPipelineService({
    required AppDatabase database,
    bool ownsDatabase = false,
  })  : _database = database,
        _ownsDatabase = ownsDatabase {
    _rawDao = SleepRawImportsDao(_database);
    _sessionsDao = SleepCanonicalSessionsDao(_database);
    _segmentsDao = SleepCanonicalStageSegmentsDao(_database);
    _hrDao = SleepCanonicalHeartRateSamplesDao(_database);
    _analysesDao = SleepNightlyAnalysesDao(_database);
  }

  final AppDatabase _database;
  final bool _ownsDatabase;
  late final SleepRawImportsDao _rawDao;
  late final SleepCanonicalSessionsDao _sessionsDao;
  late final SleepCanonicalStageSegmentsDao _segmentsDao;
  late final SleepCanonicalHeartRateSamplesDao _hrDao;
  late final SleepNightlyAnalysesDao _analysesDao;

  Future<SleepPipelineRunResult> runImport({
    required SleepRawIngestionBatch batch,
    String normalizationVersion = 'sleep-import-v1',
    String analysisVersion = 'sleep-health-score-v1',
    bool forceRecompute = false,
    DateTime? recomputeFromInclusive,
    DateTime? recomputeToExclusive,
  }) async {
    if (batch.sessions.isEmpty) {
      return const SleepPipelineRunResult(
          importedSessions: 0, analyzedNights: 0);
    }

    final importedAt = DateTime.now().toUtc();
    final from = recomputeFromInclusive ??
        batch.sessions
            .map((s) => s.startAtUtc)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final to = recomputeToExclusive ??
        batch.sessions
            .map((s) => s.endAtUtc)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .add(const Duration(seconds: 1));

    if (forceRecompute) {
      final sessionsToRecompute = await _sessionsDao.findByDateRange(
        fromInclusive: from,
        toExclusive: to,
      );
      final rawImportIds = sessionsToRecompute
          .map((session) => session.rawImportId)
          .whereType<String>()
          .toSet()
          .toList(growable: false);
      final nightDates = sessionsToRecompute
          .map((session) => _nightKey(session.endedAt))
          .toSet()
          .toList(growable: false)
        ..sort();
      if (nightDates.isNotEmpty) {
        await _analysesDao.deleteByNightRange(
          fromNightDateInclusive: nightDates.first,
          toNightDateInclusive: nightDates.last,
        );
      } else {
        final toInclusive = to.subtract(const Duration(milliseconds: 1));
        await _analysesDao.deleteByNightRange(
          fromNightDateInclusive: _nightKey(from),
          toNightDateInclusive: _nightKey(toInclusive),
        );
      }
      await _sessionsDao.deleteByDateRange(
        fromInclusive: from,
        toExclusive: to,
      );
      await _rawDao.deleteByIds(rawImportIds);
    }

    final mapped = _mapBatch(batch);
    final segmentsBySession = <String, List<SleepStageSegment>>{};
    for (final segment in mapped.stageSegments) {
      segmentsBySession
          .putIfAbsent(segment.sessionId, () => <SleepStageSegment>[])
          .add(segment);
    }
    final hrBySession = <String, List<HeartRateSample>>{};
    for (final sample in mapped.heartRateSamples) {
      hrBySession.putIfAbsent(sample.sessionId, () => <HeartRateSample>[]).add(
            sample,
          );
    }

    await _database.transaction(() async {
      final rawRows = batch.sessions
          .map(
            (session) => SleepRawImportCompanion(
              id: 'raw:${session.recordId}',
              sourcePlatform: session.sourcePlatform,
              sourceAppId: session.sourceAppId,
              sourceConfidence: session.sourceConfidence,
              sourceRecordHash: session.sourceRecordHash ??
                  _hashRecord('raw:${session.recordId}'),
              importStatus: 'success',
              importedAt: importedAt,
              payloadJson: jsonEncode(<String, dynamic>{
                'recordId': session.recordId,
                'startAtUtc': session.startAtUtc.toIso8601String(),
                'endAtUtc': session.endAtUtc.toIso8601String(),
                'platformSessionType': session.platformSessionType,
              }),
            ),
          )
          .toList(growable: false);
      await _rawDao.upsertBatch(rawRows);

      await _sessionsDao.upsertBatch(
        mapped.sessions
            .map(
              (session) => SleepCanonicalSessionCompanion(
                id: session.id,
                rawImportId: 'raw:${session.id}',
                sourcePlatform: session.sourcePlatform,
                sourceAppId: session.sourceAppId,
                sourceConfidence: session.sourceConfidence,
                sourceRecordHash: session.sourceRecordHash ??
                    _hashRecord('session:${session.id}'),
                normalizationVersion: normalizationVersion,
                sessionType: session.sessionType.name,
                startedAt: session.startAtUtc,
                endedAt: session.endAtUtc,
                timezone: null,
                importedAt: importedAt,
                normalizedAt: importedAt,
              ),
            )
            .toList(growable: false),
      );

      await _segmentsDao.upsertBatch(
        mapped.stageSegments
            .map(
              (segment) => SleepCanonicalStageSegmentCompanion(
                id: segment.id,
                sessionId: segment.sessionId,
                sourcePlatform: segment.sourcePlatform,
                sourceAppId: segment.sourceAppId,
                sourceConfidence: segment.sourceConfidence,
                sourceRecordHash: segment.sourceRecordHash ??
                    _hashRecord('segment:${segment.id}'),
                normalizationVersion: normalizationVersion,
                stage: segment.stage.name,
                startedAt: segment.startAtUtc,
                endedAt: segment.endAtUtc,
                importedAt: importedAt,
                normalizedAt: importedAt,
              ),
            )
            .toList(growable: false),
      );

      await _hrDao.upsertBatch(
        mapped.heartRateSamples
            .map(
              (sample) => SleepCanonicalHeartRateSampleCompanion(
                id: sample.id,
                sessionId: sample.sessionId,
                sourcePlatform: sample.sourcePlatform,
                sourceAppId: sample.sourceAppId,
                sourceConfidence: sample.sourceConfidence,
                sourceRecordHash:
                    sample.sourceRecordHash ?? _hashRecord('hr:${sample.id}'),
                normalizationVersion: normalizationVersion,
                sampledAt: sample.sampledAtUtc,
                bpm: sample.bpm,
                importedAt: importedAt,
                normalizedAt: importedAt,
              ),
            )
            .toList(growable: false),
      );

      final regularityByNight = await _buildRegularityByNight(
        targetSessions: mapped.sessions,
      );
      final analysisRows = <SleepNightlyAnalysisCompanion>[];
      for (final session in mapped.sessions) {
        final repaired = repairSleepTimeline(
          session: session,
          segments:
              segmentsBySession[session.id] ?? const <SleepStageSegment>[],
        );
        final metrics = calculateNightlySleepMetrics(
          session: session,
          repairedSegments: repaired,
        );
        final hr = hrBySession[session.id] ?? const <HeartRateSample>[];
        final avgHr = hr.isEmpty
            ? null
            : hr.fold<double>(0, (sum, item) => sum + item.bpm) / hr.length;
        final score = calculateSleepScore(
          SleepScoringInput(
            durationMinutes: metrics.totalSleepTime.inMinutes,
            sleepEfficiencyPct: metrics.sleepEfficiencyPct,
            wasoMinutes: metrics.wakeAfterSleepOnset.inMinutes,
            regularitySri: regularityByNight[_nightKey(session.endAtUtc)]?.sri,
            regularityValidDays:
                regularityByNight[_nightKey(session.endAtUtc)]?.validDays ?? 0,
          ),
          config: SleepScoringConfig(analysisVersion: analysisVersion),
        );
        final night = _nightKey(session.endAtUtc);
        debugPrint('SleepPipeline session=${session.id} night=$night');
        analysisRows.add(
          SleepNightlyAnalysisCompanion(
            id: 'analysis:${session.id}',
            sessionId: session.id,
            sourcePlatform: session.sourcePlatform,
            sourceAppId: session.sourceAppId,
            sourceConfidence: session.sourceConfidence,
            sourceRecordHash: session.sourceRecordHash ??
                _hashRecord('analysis:${session.id}'),
            normalizationVersion: normalizationVersion,
            analysisVersion: analysisVersion,
            nightDate: night,
            score: score.score,
            totalSleepMinutes: metrics.totalSleepTime.inMinutes,
            sleepEfficiencyPct: metrics.sleepEfficiencyPct,
            restingHeartRateBpm: avgHr,
            interruptionsCount: metrics.interruptionsCount,
            interruptionsWakeMinutes: metrics.wakeAfterSleepOnset.inMinutes,
            scoreCompleteness: score.completeness,
            regularitySri: score.regularityScore,
            regularityValidDays: score.regularityValidDays,
            regularityIsStable: score.regularityStable,
            analyzedAt: importedAt,
          ),
        );
      }
      await _analysesDao.upsertBatch(analysisRows);
    });

    return SleepPipelineRunResult(
      importedSessions: mapped.sessions.length,
      analyzedNights: mapped.sessions.length,
    );
  }

  _MappedBatch _mapBatch(SleepRawIngestionBatch batch) {
    final platform = batch.sessions.first.sourcePlatform.toLowerCase();
    if (platform.contains('apple') || platform.contains('healthkit')) {
      final mapped = const HealthKitMapper().map(batch);
      return _MappedBatch(
        sessions: mapped.sessions,
        stageSegments: mapped.stageSegments,
        heartRateSamples: mapped.heartRateSamples,
      );
    }
    final mapped = const HealthConnectMapper().map(batch);
    return _MappedBatch(
      sessions: mapped.sessions,
      stageSegments: mapped.stageSegments,
      heartRateSamples: mapped.heartRateSamples,
    );
  }

  String _nightKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _hashRecord(String value) =>
      sha1.convert(utf8.encode(value)).toString();

  Future<Map<String, SleepRegularityIndexResult>> _buildRegularityByNight({
    required List<SleepSession> targetSessions,
  }) async {
    if (targetSessions.isEmpty) return const {};
    final targetNights = targetSessions
        .map((session) => _normalizeDay(session.endAtUtc))
        .toSet()
        .toList(growable: false)
      ..sort();
    final earliestNight = targetNights.first;
    final latestNight = targetNights.last;

    // Conservative lookback window:
    // We only need 5-7 valid days for SRI availability/stability, but use a
    // wider range so sparse data can still produce a valid window.
    final fromInclusive = earliestNight.subtract(const Duration(days: 30));
    final toExclusive = latestNight.add(const Duration(days: 1));
    final sessionRows = await _sessionsDao.findByDateRange(
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
    );
    final dayBuilders = <String, _RegularityDayBuilder>{};
    for (final sessionRow in sessionRows) {
      final segmentRows = await _segmentsDao.findBySessionId(sessionRow.id);
      if (segmentRows.isEmpty) continue;
      final session = _toDomainSession(sessionRow);
      final segments =
          segmentRows.map(_toDomainStageSegment).toList(growable: false);
      final repaired =
          repairSleepTimeline(session: session, segments: segments);
      for (final segment in repaired) {
        if (!_isSleepStage(segment.stage)) continue;
        _markSleepSegmentAcrossDays(segment, dayBuilders);
      }
    }

    final dailyStates = dayBuilders.values
        .map((builder) => builder.toState())
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    final byNight = <String, SleepRegularityIndexResult>{};
    for (final night in targetNights) {
      final history =
          dailyStates.where((state) => !state.day.isAfter(night)).toList();
      final sri = calculateSleepRegularityIndex(dailyStates: history);
      byNight[_nightKey(night)] = sri;
    }
    return byNight;
  }

  SleepSession _toDomainSession(SleepCanonicalSessionRecord row) {
    return SleepSession(
      id: row.id,
      startAtUtc: row.startedAt,
      endAtUtc: row.endedAt,
      sessionType: _parseSessionType(row.sessionType),
      sourcePlatform: row.sourcePlatform,
      sourceAppId: row.sourceAppId,
      sourceRecordHash: row.sourceRecordHash,
      sourceConfidence: row.sourceConfidence,
      stageConfidence: _parseStageConfidence(row.sourceConfidence),
      overallConfidence: _parseOverallConfidence(row.sourceConfidence),
      normalizationVersion: row.normalizationVersion,
    );
  }

  SleepStageSegment _toDomainStageSegment(
      SleepCanonicalStageSegmentRecord row) {
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

  SleepSessionType _parseSessionType(String value) {
    return SleepSessionType.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => SleepSessionType.unknown,
    );
  }

  CanonicalSleepStage _parseStage(String value) {
    return CanonicalSleepStage.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => CanonicalSleepStage.unknown,
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

  bool _isSleepStage(CanonicalSleepStage stage) {
    return stage == CanonicalSleepStage.light ||
        stage == CanonicalSleepStage.deep ||
        stage == CanonicalSleepStage.rem ||
        stage == CanonicalSleepStage.asleepUnspecified;
  }

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dayKey(DateTime value) => _nightKey(_normalizeDay(value));

  void _markSleepSegmentAcrossDays(
    SleepStageSegment segment,
    Map<String, _RegularityDayBuilder> dayBuilders,
  ) {
    var day = _normalizeDay(segment.startAtUtc);
    final lastDay = _normalizeDay(segment.endAtUtc);
    while (!day.isAfter(lastDay)) {
      final dayStart = day;
      final dayEnd = dayStart.add(const Duration(days: 1));
      final overlapStart =
          segment.startAtUtc.isAfter(dayStart) ? segment.startAtUtc : dayStart;
      final overlapEnd =
          segment.endAtUtc.isBefore(dayEnd) ? segment.endAtUtc : dayEnd;
      if (overlapEnd.isAfter(overlapStart)) {
        final builder = dayBuilders.putIfAbsent(
            _dayKey(dayStart), () => _RegularityDayBuilder(dayStart));
        final startMinute = overlapStart.difference(dayStart).inMinutes;
        final endSeconds = overlapEnd.difference(dayStart).inSeconds;
        final endMinute =
            ((endSeconds + 59) ~/ 60).clamp(0, sleepRegularityMinutesPerDay);
        builder.markSleep(
            startMinute: startMinute, endMinuteExclusive: endMinute);
      }
      day = day.add(const Duration(days: 1));
    }
  }

  Future<void> dispose() async {
    if (_ownsDatabase) {
      await _database.close();
    }
  }
}

class _MappedBatch {
  const _MappedBatch({
    required this.sessions,
    required this.stageSegments,
    required this.heartRateSamples,
  });

  final List<SleepSession> sessions;
  final List<SleepStageSegment> stageSegments;
  final List<HeartRateSample> heartRateSamples;
}

class _RegularityDayBuilder {
  _RegularityDayBuilder(this.day);

  final DateTime day;
  // Binary 1-minute day state for SRI: default wake (0), sleep minutes marked as 1.
  final Uint8List _sleepByMinute = Uint8List(sleepRegularityMinutesPerDay);
  bool _hasSleepData = false;

  void markSleep({
    required int startMinute,
    required int endMinuteExclusive,
  }) {
    final start = startMinute.clamp(0, sleepRegularityMinutesPerDay - 1);
    final end = endMinuteExclusive.clamp(0, sleepRegularityMinutesPerDay);
    if (end <= start) return;
    for (var minute = start; minute < end; minute++) {
      _sleepByMinute[minute] = 1;
    }
    _hasSleepData = true;
  }

  DailySleepWakeState toState() {
    return DailySleepWakeState(
      day: day,
      sleepByMinute: _sleepByMinute,
      hasSleepData: _hasSleepData,
    );
  }
}
