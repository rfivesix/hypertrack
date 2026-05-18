// lib/features/supplements/presentation/supplements_view_model.dart
import 'package:flutter/material.dart';
import '../domain/repositories/supplement_repository.dart';
import '../data/supplement_repository_impl.dart';
import '../domain/models/supplement.dart';
import '../domain/models/supplement_log.dart';
import '../domain/models/tracked_supplement.dart';
import '../data/sources/supplement_local_data_source.dart';

class SupplementsViewModel extends ChangeNotifier {
  final SupplementRepository _repository;

  SupplementRepository get repository => _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  final Map<int, Supplement> _supplementsById = {};
  Map<int, Supplement> get supplementsById => _supplementsById;

  List<TrackedSupplement> _tracked = const [];
  List<TrackedSupplement> get tracked => _tracked;

  List<SupplementLog> _todaysLogs = const [];
  List<SupplementLog> get todaysLogs => _todaysLogs;

  SupplementsViewModel({SupplementRepository? repository})
      : _repository = repository ??
            SupplementRepositoryImpl(
              localDataSource: SupplementLocalDataSource.instance,
            );

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadData();
  }

  void navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    if (forward && newDay.isAfter(DateTime.now())) return;
    _selectedDate = newDay;
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final date = _selectedDate;
      final supplementsForDate = await _repository.getSupplementsForDate(date);
      final logs = await _repository.getSupplementLogsForDate(date);

      final byId = <int, Supplement>{
        for (final s in supplementsForDate)
          if (s.id != null) s.id!: s,
      };

      final allSupplements = await _repository.getAllSupplements();
      for (final s in allSupplements) {
        if (s.id != null && !byId.containsKey(s.id!)) {
          byId[s.id!] = s;
        }
      }

      final doses = <int, double>{};
      for (final log in logs) {
        doses.update(
          log.supplementId,
          (v) => v + log.dose,
          ifAbsent: () => log.dose,
        );
      }

      final List<TrackedSupplement> tracked = [];
      for (final s in supplementsForDate) {
        final hasLog = doses.containsKey(s.id);
        if (s.isTracked || hasLog) {
          tracked.add(
            TrackedSupplement(
                supplement: s, totalDosedToday: doses[s.id] ?? 0.0),
          );
        }
      }

      for (final id in doses.keys) {
        if (!tracked.any((ts) => ts.supplement.id == id)) {
          if (byId.containsKey(id)) {
            tracked.add(
              TrackedSupplement(
                supplement: byId[id]!,
                totalDosedToday: doses[id]!,
              ),
            );
          }
        }
      }

      _supplementsById.clear();
      _supplementsById.addAll(byId);
      _tracked = tracked;
      _todaysLogs = logs;
    } catch (e) {
      debugPrint("Error loading supplements: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Supplement>> getAllSupplementsDirect() {
    return _repository.getAllSupplements();
  }

  Future<void> addSupplement(Supplement supplement) async {
    await _repository.insertSupplement(supplement);
    await loadData();
  }

  Future<void> updateSupplement(Supplement supplement) async {
    await _repository.updateSupplement(supplement);
    await loadData();
  }

  Future<void> deleteSupplement(int id) async {
    await _repository.deleteSupplement(id);
    await loadData();
  }

  Future<void> logSupplementDose(
      Supplement supplement, double dose, DateTime timestamp) async {
    final log = SupplementLog(
      supplementId: supplement.id!,
      dose: dose,
      unit: supplement.unit,
      timestamp: timestamp,
    );
    await _repository.insertSupplementLog(log);
    await loadData();
  }

  Future<void> updateSupplementLog(SupplementLog log) async {
    await _repository.updateSupplementLog(log);
    await loadData();
  }

  Future<void> deleteSupplementLog(int id) async {
    await _repository.deleteSupplementLog(id);
    await loadData();
  }

  Future<void> insertSupplementLogRaw(SupplementLog log) async {
    await _repository.insertSupplementLog(log);
    await loadData();
  }
}
