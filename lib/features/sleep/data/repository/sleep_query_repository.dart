import '../../../../data/drift_database.dart';
import '../../domain/derived/nightly_sleep_analysis.dart';
import '../../domain/sleep_enums.dart';
import '../persistence/dao/sleep_nightly_analyses_dao.dart';
import '../persistence/sleep_persistence_models.dart';

abstract class SleepQueryRepository {
  Future<NightlySleepAnalysis?> getNightlyAnalysisByDate(DateTime day);
  Future<List<NightlySleepAnalysis>> getAnalysesInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  });
}

class DriftSleepQueryRepository implements SleepQueryRepository {
  DriftSleepQueryRepository({AppDatabase? database})
    : _database = database ?? AppDatabase(),
      _ownsDatabase = database == null {
    _dao = SleepNightlyAnalysesDao(_database);
  }

  final AppDatabase _database;
  final bool _ownsDatabase;
  late final SleepNightlyAnalysesDao _dao;

  @override
  Future<NightlySleepAnalysis?> getNightlyAnalysisByDate(DateTime day) async {
    final key = _nightKey(day);
    final rows = await _dao.findByNightRange(
      fromNightDateInclusive: key,
      toNightDateInclusive: key,
    );
    if (rows.isEmpty) return null;
    rows.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    return _toDomain(rows.first);
  }

  @override
  Future<List<NightlySleepAnalysis>> getAnalysesInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final rows = await _dao.findByNightRange(
      fromNightDateInclusive: _nightKey(fromInclusive),
      toNightDateInclusive: _nightKey(toInclusive),
    );
    return rows.map(_toDomain).toList(growable: false);
  }

  NightlySleepAnalysis _toDomain(SleepNightlyAnalysisRecord record) {
    return NightlySleepAnalysis(
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
  }

  SleepQualityBucket _qualityFromScore(double? score) {
    if (score == null) return SleepQualityBucket.unavailable;
    if (score >= 80) return SleepQualityBucket.good;
    if (score >= 60) return SleepQualityBucket.average;
    return SleepQualityBucket.poor;
  }

  String _nightKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  Future<void> dispose() async {
    if (_ownsDatabase) {
      await _database.close();
    }
  }
}
