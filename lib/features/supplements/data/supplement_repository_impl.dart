// lib/features/supplements/data/supplement_repository_impl.dart
import 'sources/supplement_local_data_source.dart';
import '../domain/models/supplement.dart';
import '../domain/models/supplement_log.dart';
import '../domain/repositories/supplement_repository.dart';

/// Concrete implementation of [SupplementRepository] utilizing the isolated [SupplementLocalDataSource].
class SupplementRepositoryImpl implements SupplementRepository {
  final SupplementLocalDataSource _localDataSource;

  SupplementRepositoryImpl({required SupplementLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<List<Supplement>> getAllSupplements() {
    return _localDataSource.getAllSupplements();
  }

  @override
  Future<List<Supplement>> getSupplementsForDate(DateTime date) {
    return _localDataSource.getSupplementsForDate(date);
  }

  @override
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) {
    return _localDataSource.getSupplementLogsForDate(date);
  }

  @override
  Future<int> insertSupplement(Supplement supplement) {
    return _localDataSource.insertSupplement(supplement);
  }

  @override
  Future<void> updateSupplement(Supplement supplement) {
    return _localDataSource.updateSupplement(supplement);
  }

  @override
  Future<void> deleteSupplement(int id) {
    return _localDataSource.deleteSupplement(id);
  }

  @override
  Future<void> insertSupplementLog(SupplementLog log) {
    return _localDataSource.insertSupplementLog(log);
  }

  @override
  Future<void> updateSupplementLog(SupplementLog log) {
    return _localDataSource.updateSupplementLog(log);
  }

  @override
  Future<void> deleteSupplementLog(int id) {
    return _localDataSource.deleteSupplementLog(id);
  }
}
