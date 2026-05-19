// lib/features/supplements/domain/repositories/supplement_repository.dart
import '../models/supplement.dart';
import '../models/supplement_log.dart';

/// Abstract contract for supplement data persistence.
///
/// Implemented by the data layer and consumed by the presentation layer
/// to ensure loose coupling and standard dependency inversion.
abstract class SupplementRepository {
  Stream<List<Supplement>> watchAllSupplements();
  Stream<List<Supplement>> watchSupplementsForDate(DateTime date);
  Stream<List<SupplementLog>> watchSupplementLogsForDate(DateTime date);

  @Deprecated('Use watchAllSupplements instead')
  Future<List<Supplement>> getAllSupplements();
  @Deprecated('Use watchSupplementsForDate instead')
  Future<List<Supplement>> getSupplementsForDate(DateTime date);
  @Deprecated('Use watchSupplementLogsForDate instead')
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date);

  Future<int> insertSupplement(Supplement supplement);
  Future<void> updateSupplement(Supplement supplement);
  Future<void> deleteSupplement(int id);
  Future<void> insertSupplementLog(SupplementLog log);
  Future<void> updateSupplementLog(SupplementLog log);
  Future<void> deleteSupplementLog(int id);
}
