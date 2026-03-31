import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/sleep_day_repository.dart';
import '../../platform/sleep_sync_service.dart';

class SleepDayViewModel extends ChangeNotifier {
  SleepDayViewModel({
    required SleepDayDataRepository repository,
    SleepImportService? syncService,
    DateTime? selectedDay,
  })  : _repository = repository,
        _syncService = syncService ?? SleepSyncService(),
        _selectedDay = _normalizeDate(selectedDay ?? DateTime.now()) {
    SleepSyncService.lastImportAtListenable.addListener(_onSleepImportCompleted);
  }

  final SleepDayDataRepository _repository;
  final SleepImportService _syncService;

  DateTime _selectedDay;
  DateTime get selectedDay => _selectedDay;

  int _selectedScopeIndex = 0;
  int get selectedScopeIndex => _selectedScopeIndex;
  bool get isDayScope => _selectedScopeIndex == 0;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  SleepDayOverviewData? _overview;
  SleepDayOverviewData? get overview => _overview;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  static DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _overview = await _repository.fetchOverview(_selectedDay);
    } catch (_) {
      _errorMessage = 'Unable to load sleep day.';
      _overview = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedDay(DateTime day) async {
    _selectedDay = _normalizeDate(day);
    await load();
  }

  void setScopeIndex(int index) {
    _selectedScopeIndex = index;
    notifyListeners();
  }

  Future<bool> importNow() async {
    final result = await _syncService.importRecent();
    if (result.success) {
      await load();
      return true;
    }
    return false;
  }

  void _onSleepImportCompleted() {
    unawaited(load());
  }

  @override
  void dispose() {
    SleepSyncService.lastImportAtListenable
        .removeListener(_onSleepImportCompleted);
    unawaited(_syncService.dispose());
    unawaited(_repository.dispose());
    super.dispose();
  }
}
