import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../data/sleep_day_repository.dart';
import '../../platform/sleep_sync_service.dart';

enum SleepPeriodScope { day, week, month }

class SleepDayViewModel extends ChangeNotifier {
  SleepDayViewModel({
    required SleepDayDataRepository repository,
    SleepImportService? syncService,
    DateTime? selectedDay,
  })  : _repository = repository,
        _syncService = syncService ?? SleepSyncService(),
        _period = SleepPeriodSelection(anchorDate: selectedDay) {
    SleepSyncService.lastImportAtListenable.addListener(
      _onSleepImportCompleted,
    );
  }

  final SleepDayDataRepository _repository;
  final SleepImportService _syncService;

  final SleepPeriodSelection _period;

  DateTime get selectedDay => _period.anchorDate;
  int get selectedScopeIndex => _period.scope.index;
  bool get isDayScope => _period.scope == SleepPeriodScope.day;

  String periodLabel(String localeCode) => _period.label(localeCode);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  SleepDayOverviewData? _overview;
  SleepDayOverviewData? get overview => _overview;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (!isDayScope) {
      _overview = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      _overview = await _repository.fetchOverview(_period.anchorDate);
    } catch (_) {
      _errorMessage = 'Unable to load sleep day.';
      _overview = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedDay(DateTime day) async {
    _period.setAnchorDate(day);
    await load();
  }

  void setScopeIndex(int index) {
    final scope = SleepPeriodScope.values[index];
    if (_period.scope == scope) return;
    _period.scope = scope;
    unawaited(load());
  }

  void shiftPeriod(int delta) {
    if (delta == 0) return;
    _period.shift(delta);
    unawaited(load());
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
    SleepSyncService.lastImportAtListenable.removeListener(
      _onSleepImportCompleted,
    );
    unawaited(_syncService.dispose());
    unawaited(_repository.dispose());
    super.dispose();
  }
}

class SleepPeriodSelection {
  SleepPeriodSelection({
    DateTime? anchorDate,
    SleepPeriodScope scope = SleepPeriodScope.day,
  })  : _anchorDate = _normalizeDate(anchorDate ?? DateTime.now()),
        _scope = scope;

  DateTime _anchorDate;
  SleepPeriodScope _scope;

  DateTime get anchorDate => _anchorDate;
  SleepPeriodScope get scope => _scope;
  set scope(SleepPeriodScope value) => _scope = value;

  void setAnchorDate(DateTime value) {
    _anchorDate = _normalizeDate(value);
  }

  void shift(int delta) {
    switch (_scope) {
      case SleepPeriodScope.day:
        _anchorDate = _anchorDate.add(Duration(days: delta));
        break;
      case SleepPeriodScope.week:
        _anchorDate = _anchorDate.add(Duration(days: 7 * delta));
        break;
      case SleepPeriodScope.month:
        _anchorDate = _addMonths(_anchorDate, delta);
        break;
    }
  }

  DateTime get periodStart {
    switch (_scope) {
      case SleepPeriodScope.day:
        return _anchorDate;
      case SleepPeriodScope.week:
        return _startOfWeek(_anchorDate);
      case SleepPeriodScope.month:
        return DateTime(_anchorDate.year, _anchorDate.month, 1);
    }
  }

  DateTime get periodEnd {
    final start = periodStart;
    switch (_scope) {
      case SleepPeriodScope.day:
        return start;
      case SleepPeriodScope.week:
        return start.add(const Duration(days: 6));
      case SleepPeriodScope.month:
        return DateTime(start.year, start.month + 1, 0);
    }
  }

  String label(String localeCode) {
    switch (_scope) {
      case SleepPeriodScope.day:
        return DateFormat.yMMMd(localeCode).format(_anchorDate);
      case SleepPeriodScope.week:
        final start = periodStart;
        final end = periodEnd;
        return '${DateFormat.MMMd(localeCode).format(start)} - ${DateFormat.MMMd(localeCode).format(end)}';
      case SleepPeriodScope.month:
        return DateFormat.yMMMM(
          localeCode,
        ).format(DateTime(_anchorDate.year, _anchorDate.month, 1));
    }
  }

  static DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _startOfWeek(DateTime date) {
    final day = _normalizeDate(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime _addMonths(DateTime date, int months) {
    final base = DateTime(date.year, date.month + months, 1);
    final lastDay = DateTime(base.year, base.month + 1, 0).day;
    final clampedDay = date.day > lastDay ? lastDay : date.day;
    return DateTime(base.year, base.month, clampedDay);
  }
}
