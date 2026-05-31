import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
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

class SleepPipelineBackgroundTaskParams {
  final SleepRawIngestionBatch batch;
  final String normalizationVersion;
  final String analysisVersion;
  final DateTime importedAt;
  final List<SleepCanonicalSessionRecord> lookbackSessions;
  final List<SleepCanonicalStageSegmentRecord> lookbackSegments;

  SleepPipelineBackgroundTaskParams({
    required this.batch,
    required this.normalizationVersion,
    required this.analysisVersion,
    required this.importedAt,
    required this.lookbackSessions,
    required this.lookbackSegments,
  });
}

class SleepPipelineBackgroundTaskResult {
  final List<SleepRawImportCompanion> rawRows;
  final List<SleepCanonicalSessionCompanion> sessionRows;
  final List<SleepCanonicalStageSegmentCompanion> segmentRows;
  final List<SleepCanonicalHeartRateSampleCompanion> hrRows;
  final List<SleepNightlyAnalysisCompanion> analysisRows;

  SleepPipelineBackgroundTaskResult({
    required this.rawRows,
    required this.sessionRows,
    required this.segmentRows,
    required this.hrRows,
    required this.analysisRows,
  });
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
    String analysisVersion = 'sleep-health-score-v3',
    bool forceRecompute = false,
    DateTime? recomputeFromInclusive,
    DateTime? recomputeToExclusive,
  }) async {
    final normalizedBatch = _dedupeProgressiveSessions(batch);
    if (normalizedBatch.sessions.isEmpty) {
      return const SleepPipelineRunResult(
        importedSessions: 0,
        analyzedNights: 0,
      );
    }

    final importedAt = DateTime.now().toUtc();
    final from = recomputeFromInclusive ??
        normalizedBatch.sessions
            .map((s) => s.startAtUtc)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final to = recomputeToExclusive ??
        normalizedBatch.sessions
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

    // Pre-fetch lookback data for regularity calculation
    final targetNights = normalizedBatch.sessions
        .map((session) => _normalizeDay(session.endAtUtc))
        .toSet()
        .toList(growable: false)
      ..sort();
    final earliestNight = targetNights.first;
    final latestNight = targetNights.last;
    final lookbackFromInclusive =
        earliestNight.subtract(const Duration(days: 30));
    final lookbackToExclusive = latestNight.add(const Duration(days: 1));

    final lookbackSessions = await _sessionsDao.findByDateRange(
      fromInclusive: lookbackFromInclusive,
      toExclusive: lookbackToExclusive,
    );
    final lookbackSessionIds = lookbackSessions.map((s) => s.id).toList();
    final lookbackSegments =
        await _segmentsDao.findBySessionIds(lookbackSessionIds);

    // Offload heavy processing to background isolate
    final result = await compute(
      _runSleepPipelineBackground,
      SleepPipelineBackgroundTaskParams(
        batch: normalizedBatch,
        normalizationVersion: normalizationVersion,
        analysisVersion: analysisVersion,
        importedAt: importedAt,
        lookbackSessions: lookbackSessions,
        lookbackSegments: lookbackSegments,
      ),
    );

    var insertedSessions = 0;
    await _database.transaction(() async {
      final skipSessionIds = <String>{};
      final rawImportIdsToDelete = <String>[];
      for (final session in normalizedBatch.sessions) {
        final existingSameStart = await _sessionsDao.findByStartAndSource(
          startAtUtc: session.startAtUtc,
          sourcePlatform: session.sourcePlatform,
          sourceAppId: session.sourceAppId,
        );
        final hasLongerOrEqualExisting = existingSameStart.any((existing) {
          return existing.id != session.recordId &&
              !existing.endedAt.isBefore(session.endAtUtc);
        });
        if (hasLongerOrEqualExisting) {
          skipSessionIds.add(session.recordId);
          continue;
        }

        final shorterExisting = existingSameStart.where((existing) {
          return existing.id != session.recordId &&
              existing.endedAt.isBefore(session.endAtUtc);
        });
        for (final existing in shorterExisting) {
          await _sessionsDao.deleteById(existing.id);
          rawImportIdsToDelete.add('raw:${existing.id}');
        }

        final sourceRecordHash = _resolveSourceRecordHash(session);
        final matchingExternal = await _sessionsDao.findBySourceHash(
          sourceRecordHash,
        );
        final hasExternalOverlap = matchingExternal.any((existing) {
          return existing.id != session.recordId &&
              _rangesOverlap(
                session.startAtUtc,
                session.endAtUtc,
                existing.startedAt,
                existing.endedAt,
              );
        });

        await _sessionsDao.deleteById(session.recordId);
        if (_shouldCascadeDelete(session, hasExternalOverlap)) {
          await _sessionsDao.deleteByDateRange(
            fromInclusive: session.startAtUtc,
            toExclusive: session.endAtUtc.add(const Duration(seconds: 1)),
          );
        }
      }

      if (rawImportIdsToDelete.isNotEmpty) {
        await _rawDao.deleteByIds(rawImportIdsToDelete);
      }

      final filteredRawRows = result.rawRows.where((row) {
        return !skipSessionIds.contains(_rawImportSessionId(row.id));
      }).toList(growable: false);
      final filteredSessionRows = result.sessionRows
          .where((row) => !skipSessionIds.contains(row.id))
          .toList(growable: false);
      final filteredSegmentRows = result.segmentRows
          .where((row) => !skipSessionIds.contains(row.sessionId))
          .toList(growable: false);
      final filteredHrRows = result.hrRows
          .where((row) => !skipSessionIds.contains(row.sessionId))
          .toList(growable: false);
      final filteredAnalysisRows = result.analysisRows
          .where((row) => !skipSessionIds.contains(row.sessionId))
          .toList(growable: false);

      await _rawDao.upsertBatch(filteredRawRows);
      await _sessionsDao.upsertBatch(filteredSessionRows);
      await _segmentsDao.upsertBatch(filteredSegmentRows);
      await _hrDao.upsertBatch(filteredHrRows);
      await _analysesDao.upsertBatch(filteredAnalysisRows);
      insertedSessions = filteredSessionRows.length;
    });

    _database.notifyUpdates({
      const TableUpdate('sleep_raw_imports'),
      const TableUpdate('sleep_canonical_sessions'),
      const TableUpdate('sleep_canonical_stage_segments'),
      const TableUpdate('sleep_canonical_heart_rate_samples'),
      const TableUpdate('sleep_nightly_analyses'),
    });

    return SleepPipelineRunResult(
      importedSessions: insertedSessions,
      analyzedNights: insertedSessions,
    );
  }

  static SleepPipelineBackgroundTaskResult _runSleepPipelineBackground(
    SleepPipelineBackgroundTaskParams params,
  ) {
    final batch = params.batch;
    final normalizationVersion = params.normalizationVersion;
    final analysisVersion = params.analysisVersion;
    final importedAt = params.importedAt;

    final mapped = _mapBatch(batch);
    final segmentsBySession = <String, List<SleepStageSegment>>{};
    for (final segment in mapped.stageSegments) {
      segmentsBySession
          .putIfAbsent(segment.sessionId, () => <SleepStageSegment>[])
          .add(segment);
    }
    final hrBySession = <String, List<HeartRateSample>>{};
    for (final sample in mapped.heartRateSamples) {
      hrBySession
          .putIfAbsent(sample.sessionId, () => <HeartRateSample>[])
          .add(sample);
    }

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

    final sessionRows = mapped.sessions
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
        .toList(growable: false);

    final segmentRows = mapped.stageSegments
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
        .toList(growable: false);

    final hrRows = mapped.heartRateSamples
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
        .toList(growable: false);

    final regularityByNight = _buildRegularityByNight(
      targetSessions: mapped.sessions,
      lookbackSessions: params.lookbackSessions,
      lookbackSegments: params.lookbackSegments,
      currentBatchSegments: mapped.stageSegments,
    );

    final rollingMidSleepSdByNight = _buildRollingMidSleepSdByNight(
      targetSessions: mapped.sessions,
      lookbackSessions: params.lookbackSessions,
    );

    final analysisRows = <SleepNightlyAnalysisCompanion>[];
    for (final session in mapped.sessions) {
      final repaired = repairSleepTimeline(
        session: session,
        segments: segmentsBySession[session.id] ?? const <SleepStageSegment>[],
      );
      final metrics = calculateNightlySleepMetrics(
        session: session,
        repairedSegments: repaired,
      );
      final hr = hrBySession[session.id] ?? const <HeartRateSample>[];
      final avgHr = hr.isEmpty
          ? null
          : hr.fold<double>(0, (sum, item) => sum + item.bpm) / hr.length;
          
      final localStart = session.startAtUtc.toLocal();
      final sleepOnsetHourLocal = localStart.hour + (localStart.minute / 60.0);

      final score = calculateSleepScore(
        SleepScoringInput(
          durationMinutes: metrics.totalSleepTime.inMinutes,
          sleepEfficiencyPct: metrics.sleepEfficiencyPct,
          wasoMinutes: metrics.wakeAfterSleepOnset.inMinutes,
          regularitySri: regularityByNight[_nightKey(session.endAtUtc)]?.sri,
          regularityValidDays:
              regularityByNight[_nightKey(session.endAtUtc)]?.validDays ?? 0,
          regularityValidComparisonPairs:
              regularityByNight[_nightKey(session.endAtUtc)]
                  ?.validComparisonPairs,
          lightSleepPct: metrics.stagePercentages[CanonicalSleepStage.light],
          deepSleepPct: metrics.stagePercentages[CanonicalSleepStage.deep],
          remSleepPct: metrics.stagePercentages[CanonicalSleepStage.rem],
          asleepUnspecifiedPct:
              metrics.stagePercentages[CanonicalSleepStage.asleepUnspecified],
          stageDataConfidence: _timelineConfidence(repaired),
          sourcePlatform: session.sourcePlatform,
          sourceAppId: session.sourceAppId,
          sleepOnsetHourLocal: sleepOnsetHourLocal,
          rollingMidSleepSd: rollingMidSleepSdByNight[_nightKey(session.endAtUtc)],
        ),
        config: SleepScoringConfig(analysisVersion: analysisVersion),
      );
      final night = _nightKey(session.endAtUtc);
      analysisRows.add(
        SleepNightlyAnalysisCompanion(
          id: 'analysis:${session.id}',
          sessionId: session.id,
          sourcePlatform: session.sourcePlatform,
          sourceAppId: session.sourceAppId,
          sourceConfidence: session.sourceConfidence,
          sourceRecordHash:
              session.sourceRecordHash ?? _hashRecord('analysis:${session.id}'),
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
          scoreBreakdownJson: jsonEncode(score.toJson()),
          analyzedAt: importedAt,
        ),
      );
    }

    return SleepPipelineBackgroundTaskResult(
      rawRows: rawRows,
      sessionRows: sessionRows,
      segmentRows: segmentRows,
      hrRows: hrRows,
      analysisRows: analysisRows,
    );
  }

  static _MappedBatch _mapBatch(SleepRawIngestionBatch batch) {
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

  static String _nightKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  // Nocturnal window spans 20:00-12:00 local (overnight wrap across midnight).
  static const int _nightWindowStartMinutes = 20 * 60;
  static const int _nightWindowEndMinutes = 12 * 60;
  static const String _unknownSourceAppId = '__unknown__';

  static SleepRawIngestionBatch _dedupeProgressiveSessions(
    SleepRawIngestionBatch batch,
  ) {
    if (batch.sessions.length <= 1) return batch;
    final winners = <String, SleepIngestionSession>{};
    for (final session in batch.sessions) {
      final key = _sessionDedupKey(session);
      final existing = winners[key];
      if (existing == null || session.endAtUtc.isAfter(existing.endAtUtc)) {
        winners[key] = session;
      }
    }
    if (winners.length == batch.sessions.length) return batch;
    final sessions = winners.values.toList(growable: false)
      ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
    final sessionIds = sessions.map((session) => session.recordId).toSet();
    return SleepRawIngestionBatch(
      sessions: sessions,
      stageSegments: batch.stageSegments
          .where((segment) => sessionIds.contains(segment.sessionRecordId))
          .toList(growable: false),
      heartRateSamples: batch.heartRateSamples
          .where((sample) => sessionIds.contains(sample.sessionRecordId))
          .toList(growable: false),
    );
  }

  static String _sessionDedupKey(SleepIngestionSession session) {
    final sourceKey = session.sourceAppId ?? _unknownSourceAppId;
    return '${session.startAtUtc.toIso8601String()}|${session.sourcePlatform}|$sourceKey';
  }

  static String _resolveSourceRecordHash(SleepIngestionSession session) {
    final raw = session.sourceRecordHash;
    if (raw != null && raw.isNotEmpty) return raw;
    return _hashRecord('session:${session.recordId}');
  }

  static String _rawImportSessionId(String rawImportId) {
    if (rawImportId.startsWith('raw:')) {
      return rawImportId.substring(4);
    }
    return rawImportId;
  }

  static bool _rangesOverlap(
    DateTime start,
    DateTime end,
    DateTime otherStart,
    DateTime otherEnd,
  ) {
    return start.isBefore(otherEnd) && end.isAfter(otherStart);
  }

  static bool _shouldCascadeDelete(
    SleepIngestionSession session,
    bool hasExternalOverlap,
  ) {
    return _isNocturnalWindow(session.startAtUtc, session.endAtUtc) ||
        hasExternalOverlap;
  }

  static bool _isNocturnalWindow(DateTime startUtc, DateTime endUtc) {
    final startLocal = startUtc.toLocal();
    final endLocal = endUtc.toLocal();
    final startMinutes = startLocal.hour * 60 + startLocal.minute;
    final endMinutes = endLocal.hour * 60 + endLocal.minute;
    final inNightStart = startMinutes >= _nightWindowStartMinutes ||
        startMinutes < _nightWindowEndMinutes;
    final inNightEnd = endMinutes >= _nightWindowStartMinutes ||
        endMinutes < _nightWindowEndMinutes;
    return inNightStart || inNightEnd;
  }

  static String _hashRecord(String value) =>
      sha1.convert(utf8.encode(value)).toString();

  static Map<String, SleepRegularityIndexResult> _buildRegularityByNight({
    required List<SleepSession> targetSessions,
    required List<SleepCanonicalSessionRecord> lookbackSessions,
    required List<SleepCanonicalStageSegmentRecord> lookbackSegments,
    required List<SleepStageSegment> currentBatchSegments,
  }) {
    if (targetSessions.isEmpty) return const {};
    final targetNights = targetSessions
        .map((session) => _normalizeDay(session.endAtUtc))
        .toSet()
        .toList(growable: false)
      ..sort();

    final dayBuilders = <String, _RegularityDayBuilder>{};

    // Merge sessions: current batch takes precedence over lookback from DB
    final allSessions = <String, SleepSession>{};
    for (final row in lookbackSessions) {
      allSessions[row.id] = _toDomainSession(row);
    }
    for (final session in targetSessions) {
      allSessions[session.id] = session;
    }

    // Merge segments: current batch takes precedence
    final allSegmentsBySessionId = <String, List<SleepStageSegment>>{};
    for (final row in lookbackSegments) {
      allSegmentsBySessionId
          .putIfAbsent(row.sessionId, () => <SleepStageSegment>[])
          .add(_toDomainStageSegment(row));
    }

    // Overwrite with current batch segments (grouped efficiently)
    final currentBatchSegmentsMap = <String, List<SleepStageSegment>>{};
    for (final segment in currentBatchSegments) {
      currentBatchSegmentsMap
          .putIfAbsent(segment.sessionId, () => <SleepStageSegment>[])
          .add(segment);
    }
    for (final entry in currentBatchSegmentsMap.entries) {
      allSegmentsBySessionId[entry.key] = entry.value;
    }

    for (final session in allSessions.values) {
      final segments = allSegmentsBySessionId[session.id] ?? const [];
      if (segments.isEmpty) continue;
      final repaired = repairSleepTimeline(
        session: session,
        segments: segments,
      );
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

  static Map<String, double> _buildRollingMidSleepSdByNight({
    required List<SleepSession> targetSessions,
    required List<SleepCanonicalSessionRecord> lookbackSessions,
  }) {
    if (targetSessions.isEmpty) return const {};
    
    final targetNights = targetSessions
        .map((session) => _normalizeDay(session.endAtUtc))
        .toSet()
        .toList(growable: false)
      ..sort();

    final allSessions = <String, SleepSession>{};
    for (final row in lookbackSessions) {
      allSessions[row.id] = _toDomainSession(row);
    }
    for (final session in targetSessions) {
      allSessions[session.id] = session;
    }

    final sessionsList = allSessions.values.toList()
      ..sort((a, b) => a.endAtUtc.compareTo(b.endAtUtc));

    final byNight = <String, double>{};

    for (final night in targetNights) {
      final windowStart = night.subtract(const Duration(days: 14));
      
      final windowSessions = sessionsList.where((s) {
        final d = _normalizeDay(s.endAtUtc);
        return !d.isBefore(windowStart) && !d.isAfter(night);
      }).toList();

      if (windowSessions.isEmpty) {
        byNight[_nightKey(night)] = 0.0;
        continue;
      }

      final midSleeps = windowSessions.map((s) {
        final localStart = s.startAtUtc.toLocal();
        double onset = localStart.hour + (localStart.minute / 60.0);
        if (onset > 12.0) {
          onset -= 24.0;
        }
        final durationMinutes = s.endAtUtc.difference(s.startAtUtc).inMinutes;
        double ms = onset + ((durationMinutes / 60.0) / 2.0);
        while (ms < 0) {
          ms += 24.0;
        }
        while (ms >= 24.0) {
          ms -= 24.0;
        }
        return ms;
      }).toList();

      if (midSleeps.length < 2) {
        byNight[_nightKey(night)] = 0.0;
        continue;
      }

      final mean = midSleeps.reduce((a, b) => a + b) / midSleeps.length;
      final variance = midSleeps.map((ms) => math.pow(ms - mean, 2)).reduce((a, b) => a + b) / (midSleeps.length - 1);
      byNight[_nightKey(night)] = math.sqrt(variance);
    }

    return byNight;
  }

  static SleepSession _toDomainSession(SleepCanonicalSessionRecord row) {
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

  static SleepStageSegment _toDomainStageSegment(
    SleepCanonicalStageSegmentRecord row,
  ) {
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

  static SleepSessionType _parseSessionType(String value) {
    return SleepSessionType.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => SleepSessionType.unknown,
    );
  }

  static CanonicalSleepStage _parseStage(String value) {
    return CanonicalSleepStage.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => CanonicalSleepStage.unknown,
    );
  }

  static SleepStageConfidence _parseStageConfidence(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'high' => SleepStageConfidence.high,
      'medium' => SleepStageConfidence.medium,
      'low' => SleepStageConfidence.low,
      _ => SleepStageConfidence.unknown,
    };
  }

  static SleepOverallConfidence _parseOverallConfidence(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'high' => SleepOverallConfidence.high,
      'medium' => SleepOverallConfidence.medium,
      'low' => SleepOverallConfidence.low,
      _ => SleepOverallConfidence.unknown,
    };
  }

  static SleepStageConfidence _timelineConfidence(
      List<SleepStageSegment> segments) {
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

  static bool _isSleepStage(CanonicalSleepStage stage) {
    return stage == CanonicalSleepStage.light ||
        stage == CanonicalSleepStage.deep ||
        stage == CanonicalSleepStage.rem ||
        stage == CanonicalSleepStage.asleepUnspecified;
  }

  static DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dayKey(DateTime value) => _nightKey(_normalizeDay(value));

  static void _markSleepSegmentAcrossDays(
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
          _dayKey(dayStart),
          () => _RegularityDayBuilder(dayStart),
        );
        final startMinute = overlapStart.difference(dayStart).inMinutes;
        final endSeconds = overlapEnd.difference(dayStart).inSeconds;
        final endMinute = ((endSeconds + 59) ~/ 60).clamp(
          0,
          sleepRegularityMinutesPerDay,
        );
        builder.markSleep(
          startMinute: startMinute,
          endMinuteExclusive: endMinute,
        );
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

  void markSleep({required int startMinute, required int endMinuteExclusive}) {
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
