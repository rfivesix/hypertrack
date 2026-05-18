// lib/features/supplements/data/supplement_repository_impl.dart
import '../../../data/database_helper.dart';
import '../domain/models/supplement.dart';
import '../domain/models/supplement_log.dart';
import '../domain/repositories/supplement_repository.dart';

/// Concrete implementation of [SupplementRepository] utilizing the [DatabaseHelper] singleton.
class SupplementRepositoryImpl implements SupplementRepository {
  final DatabaseHelper _dbHelper;

  SupplementRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Supplement>> getAllSupplements() {
    return _dbHelper.getAllSupplements();
  }

  @override
  Future<List<Supplement>> getSupplementsForDate(DateTime date) {
    return _dbHelper.getSupplementsForDate(date);
  }

  @override
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) {
    return _dbHelper.getSupplementLogsForDate(date);
  }

  @override
  Future<void> insertSupplement(Supplement supplement) {
    return _dbHelper.insertSupplement(supplement);
  }

  @override
  Future<void> updateSupplement(Supplement supplement) {
    return _dbHelper.updateSupplement(supplement);
  }

  @override
  Future<void> deleteSupplement(int id) {
    return _dbHelper.deleteSupplement(id);
  }

  @override
  Future<void> insertSupplementLog(SupplementLog log) {
    return _dbHelper.insertSupplementLog(log);
  }

  @override
  Future<void> updateSupplementLog(SupplementLog log) {
    return _dbHelper.updateSupplementLog(log);
  }

  @override
  Future<void> deleteSupplementLog(int id) {
    return _dbHelper.deleteSupplementLog(id);
  }
}
