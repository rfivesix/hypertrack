import 'package:flutter/foundation.dart';

import '../../data/repository/sleep_query_repository.dart';
import '../../domain/derived/nightly_sleep_analysis.dart';

class SleepDayState {
  const SleepDayState({
    required this.isLoading,
    this.analysis,
    this.errorMessage,
  });

  final bool isLoading;
  final NightlySleepAnalysis? analysis;
  final String? errorMessage;
}

class SleepRangeState {
  const SleepRangeState({
    required this.isLoading,
    required this.items,
    this.errorMessage,
  });

  final bool isLoading;
  final List<NightlySleepAnalysis> items;
  final String? errorMessage;
}

class SleepDerivedProvider extends ChangeNotifier {
  SleepDerivedProvider(this._repository);

  final SleepQueryRepository _repository;

  SleepDayState _day = const SleepDayState(isLoading: false);
  SleepRangeState _week = const SleepRangeState(isLoading: false, items: []);
  SleepRangeState _month = const SleepRangeState(isLoading: false, items: []);

  SleepDayState get day => _day;
  SleepRangeState get week => _week;
  SleepRangeState get month => _month;

  Future<void> loadDay(DateTime day) async {
    _day = const SleepDayState(isLoading: true);
    notifyListeners();
    try {
      final analysis = await _repository.getNightlyAnalysisByDate(day);
      _day = SleepDayState(isLoading: false, analysis: analysis);
    } catch (_) {
      _day = const SleepDayState(
        isLoading: false,
        errorMessage: 'Failed to load sleep day.',
      );
    }
    notifyListeners();
  }

  Future<void> loadWeek(DateTime anchorDay) async {
    _week = const SleepRangeState(isLoading: true, items: []);
    notifyListeners();
    final start = DateTime(anchorDay.year, anchorDay.month, anchorDay.day)
        .subtract(Duration(days: anchorDay.weekday - DateTime.monday));
    final end = start.add(const Duration(days: 6));
    await _loadRange(start, end, isWeek: true);
  }

  Future<void> loadMonth(DateTime anchorDay) async {
    _month = const SleepRangeState(isLoading: true, items: []);
    notifyListeners();
    final start = DateTime(anchorDay.year, anchorDay.month, 1);
    final end = DateTime(anchorDay.year, anchorDay.month + 1, 0);
    await _loadRange(start, end, isWeek: false);
  }

  Future<void> _loadRange(
    DateTime start,
    DateTime end, {
    required bool isWeek,
  }) async {
    try {
      final items = await _repository.getAnalysesInRange(
        fromInclusive: start,
        toInclusive: end,
      );
      if (isWeek) {
        _week = SleepRangeState(isLoading: false, items: items);
      } else {
        _month = SleepRangeState(isLoading: false, items: items);
      }
    } catch (_) {
      if (isWeek) {
        _week = const SleepRangeState(
          isLoading: false,
          items: [],
          errorMessage: 'Failed to load sleep week.',
        );
      } else {
        _month = const SleepRangeState(
          isLoading: false,
          items: [],
          errorMessage: 'Failed to load sleep month.',
        );
      }
    }
    notifyListeners();
  }
}

