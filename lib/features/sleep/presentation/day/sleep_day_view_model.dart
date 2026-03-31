import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/sleep_day_repository.dart';

class SleepDayViewModel extends ChangeNotifier {
  SleepDayViewModel({
    required SleepDayDataRepository repository,
    DateTime? selectedDay,
  })  : _repository = repository,
        _selectedDay = _normalizeDate(selectedDay ?? DateTime.now());

  final SleepDayDataRepository _repository;

  DateTime _selectedDay;
  DateTime get selectedDay => _selectedDay;

  int _selectedScopeIndex = 0;
  int get selectedScopeIndex => _selectedScopeIndex;

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

  @override
  void dispose() {
    unawaited(_repository.dispose());
    super.dispose();
  }
}
