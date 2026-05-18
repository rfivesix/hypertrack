// lib/features/supplements/data/supplement_repository.dart
import '../../../data/database_helper.dart';
import '../domain/models/supplement.dart';
import '../domain/models/supplement_log.dart';

class SupplementRepository {
  final DatabaseHelper _dbHelper;

  SupplementRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Supplement>> getAllSupplements() {
    return _dbHelper.getAllSupplements();
  }

  Future<List<Supplement>> getSupplementsForDate(DateTime date) {
    return _dbHelper.getSupplementsForDate(date);
  }

  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) {
    return _dbHelper.getSupplementLogsForDate(date);
  }

  Future<void> insertSupplement(Supplement supplement) {
    return _dbHelper.insertSupplement(supplement);
  }

  Future<void> updateSupplement(Supplement supplement) {
    return _dbHelper.updateSupplement(supplement);
  }

  Future<void> deleteSupplement(int id) {
    return _dbHelper.deleteSupplement(id);
  }

  Future<void> insertSupplementLog(SupplementLog log) {
    return _dbHelper.insertSupplementLog(log);
  }

  Future<void> updateSupplementLog(SupplementLog log) {
    return _dbHelper.updateSupplementLog(log);
  }

  Future<void> deleteSupplementLog(int id) {
    return _dbHelper.deleteSupplementLog(id);
  }
}
