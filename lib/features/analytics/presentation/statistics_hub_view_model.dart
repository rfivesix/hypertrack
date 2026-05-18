import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../data/workout_database_helper.dart';
import '../../statistics/data/statistics_hub_data_adapter.dart';
import '../../statistics/domain/body_nutrition_analytics_models.dart';
import '../../statistics/domain/consistency_payload_models.dart';
import '../../statistics/domain/recovery_payload_models.dart';
import '../../statistics/domain/hub_payload_models.dart';
import '../../statistics/domain/statistics_range_policy.dart';
import '../../pulse/application/pulse_tracking_service.dart';
import '../../pulse/data/pulse_repository.dart';
import '../../pulse/domain/pulse_models.dart';
import '../../sleep/data/sleep_hub_summary_repository.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../steps/domain/steps_models.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../../util/perf_debug_timer.dart';

class SectionLoadState<T> {
  final T? data;
  final bool isLoading;
  final Object? error;
  final StackTrace? stackTrace;
  final int generation;

  const SectionLoadState({
    this.data,
    this.isLoading = false,
    this.error,
    this.stackTrace,
    this.generation = 0,
  });

  bool get hasData => data != null;
  bool get hasError => error != null;

  SectionLoadState<T> copyWith({
    T? data,
    bool? isLoading,
    Object? error,
    StackTrace? stackTrace,
    int? generation,
    bool clearError = false,
  }) {
    return SectionLoadState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      stackTrace: clearError ? null : stackTrace ?? this.stackTrace,
      generation: generation ?? this.generation,
    );
  }

  SectionLoadState<T> loading(int generation) {
    return copyWith(
      isLoading: true,
      generation: generation,
      clearError: true,
    );
  }

  SectionLoadState<T> success(T data, int generation) {
    return SectionLoadState<T>(
      data: data,
      generation: generation,
    );
  }

  SectionLoadState<T> failure(
    Object error,
    StackTrace stackTrace,
    int generation,
  ) {
    return SectionLoadState<T>(
      data: data,
      isLoading: false,
      error: error,
      stackTrace: stackTrace,
      generation: generation,
    );
  }
}

class StepsSectionData {
  final RangeStepsAggregation range;
  final bool trackingEnabled;
  final int targetSteps;
  final String providerName;

  const StepsSectionData({
    required this.range,
    required this.trackingEnabled,
    required this.targetSteps,
    required this.providerName,
  });
}

class ConsistencySectionData {
  final List<Map<String, dynamic>> workoutsPerWeek;
  final List<WeeklyConsistencyMetricPayload> weeklyConsistencyMetrics;
  final TrainingStatsPayload trainingStats;

  const ConsistencySectionData({
    required this.workoutsPerWeek,
    required this.weeklyConsistencyMetrics,
    required this.trainingStats,
  });
}

class PerformanceRecordsSectionData {
  final List<Map<String, dynamic>> recentPrs;
  final List<Map<String, dynamic>> notableImprovements;

  const PerformanceRecordsSectionData({
    required this.recentPrs,
    required this.notableImprovements,
  });
}

class VolumeMusclesSectionData {
  final List<Map<String, dynamic>> weeklyVolume;
  final Map<String, dynamic> muscleAnalytics;

  const VolumeMusclesSectionData({
    required this.weeklyVolume,
    required this.muscleAnalytics,
  });
}

class HubRangeContext {
  final int selectedDays;
  final int daysBack;

  const HubRangeContext({
    required this.selectedDays,
    required this.daysBack,
  });
}

enum StatisticsHubSectionId {
  steps,
  recovery,
  sleep,
  pulse,
  consistency,
  performanceRecords,
  volumeMuscles,
  bodyNutrition,
}

class StatisticsHubViewModel extends ChangeNotifier {
  static const Duration _sleepSyncInterval = Duration(hours: 6);

  static const _defaultTrainingStats = TrainingStatsPayload(
    totalWorkouts: 0,
    thisWeekCount: 0,
    avgPerWeek: 0.0,
    streakWeeks: 0,
  );
  static const _defaultRecoveryAnalytics = RecoveryAnalyticsPayload(
    hasData: false,
    overallState: '',
    totals: RecoveryTotalsPayload(
      recovering: 0,
      ready: 0,
      fresh: 0,
      tracked: 0,
    ),
    muscles: [],
  );

  final StatisticsHubDataAdapter _hubDataAdapter;
  final StepsAggregationRepository _stepsRepository;
  final SleepHubSummaryRepository _sleepSummaryRepository;
  final PulseAnalysisRepository _pulseRepository;
  final StepsSyncService _stepsSyncService;
  final SleepSyncService _sleepSyncService;
  final _rangePolicy = StatisticsRangePolicyService.instance;

  StatisticsRangePolicyService get rangePolicy => _rangePolicy;

  final Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> Function(
    int selectedTimeRangeIndex,
  )? _fetchHubAnalyticsOverride;
  final Future<SleepSyncResult?> Function({
    int lookbackDays,
    Duration minInterval,
    bool force,
  })? _importSleepIfDueOverride;
  final Future<bool> Function()? _isSleepTrackingEnabledOverride;
  final Future<int> Function()? _targetStepsLoaderOverride;
  final Future<String> Function()? _stepsProviderNameLoaderOverride;

  int _selectedTimeRangeIndex = 1;
  int get selectedTimeRangeIndex => _selectedTimeRangeIndex;

  set selectedTimeRangeIndex(int index) {
    if (_selectedTimeRangeIndex != index) {
      _selectedTimeRangeIndex = index;
      notifyListeners();
      loadHubAnalytics();
    }
  }

  SectionLoadState<StepsSectionData> _stepsState =
      const SectionLoadState<StepsSectionData>();
  SectionLoadState<StepsSectionData> get stepsState => _stepsState;

  SectionLoadState<RecoveryAnalyticsPayload> _recoveryState =
      const SectionLoadState<RecoveryAnalyticsPayload>();
  SectionLoadState<RecoveryAnalyticsPayload> get recoveryState => _recoveryState;

  SectionLoadState<SleepHubSummary> _sleepState =
      const SectionLoadState<SleepHubSummary>();
  SectionLoadState<SleepHubSummary> get sleepState => _sleepState;

  SectionLoadState<PulseAnalysisSummary> _pulseState =
      const SectionLoadState<PulseAnalysisSummary>();
  SectionLoadState<PulseAnalysisSummary> get pulseState => _pulseState;

  SectionLoadState<ConsistencySectionData> _consistencyState =
      const SectionLoadState<ConsistencySectionData>();
  SectionLoadState<ConsistencySectionData> get consistencyState => _consistencyState;

  SectionLoadState<PerformanceRecordsSectionData> _performanceState =
      const SectionLoadState<PerformanceRecordsSectionData>();
  SectionLoadState<PerformanceRecordsSectionData> get performanceState => _performanceState;

  SectionLoadState<VolumeMusclesSectionData> _volumeMusclesState =
      const SectionLoadState<VolumeMusclesSectionData>();
  SectionLoadState<VolumeMusclesSectionData> get volumeMusclesState => _volumeMusclesState;

  SectionLoadState<BodyNutritionAnalyticsResult> _bodyNutritionState =
      const SectionLoadState<BodyNutritionAnalyticsResult>();
  SectionLoadState<BodyNutritionAnalyticsResult> get bodyNutritionState => _bodyNutritionState;

  bool _stepsTrackingEnabled = false;
  bool get stepsTrackingEnabled => _stepsTrackingEnabled;

  bool _sleepTrackingEnabled = false;
  bool get sleepTrackingEnabled => _sleepTrackingEnabled;

  bool _pulseTrackingEnabled = false;
  bool get pulseTrackingEnabled => _pulseTrackingEnabled;

  int _hubAnalyticsLoadGeneration = 0;

  List<Map<String, dynamic>> get workoutsPerWeek =>
      _consistencyState.data?.workoutsPerWeek ?? const [];

  Map<String, dynamic> get muscleAnalytics =>
      _volumeMusclesState.data?.muscleAnalytics ?? const {};

  List<Map<String, dynamic>> get notableImprovements =>
      _performanceState.data?.notableImprovements ?? const [];

  TrainingStatsPayload get trainingStats =>
      _consistencyState.data?.trainingStats ?? _defaultTrainingStats;

  RecoveryAnalyticsPayload get recoveryAnalytics =>
      _recoveryState.data ?? _defaultRecoveryAnalytics;

  BodyNutritionAnalyticsResult? get bodyNutrition => _bodyNutritionState.data;

  RangeStepsAggregation? get stepsRange => _stepsState.data?.range;

  SleepHubSummary? get sleepSummary => _sleepState.data;

  PulseAnalysisSummary? get pulseSummary => _pulseState.data;

  int get targetSteps =>
      _stepsState.data?.targetSteps ?? StepsSyncService.defaultStepsGoal;

  StatisticsHubViewModel({
    StatisticsHubDataAdapter? hubDataAdapter,
    StepsAggregationRepository? stepsRepository,
    SleepHubSummaryRepository? sleepSummaryRepository,
    PulseAnalysisRepository? pulseRepository,
    StepsSyncService? stepsSyncService,
    SleepSyncService? sleepSyncService,
    Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> Function(
      int selectedTimeRangeIndex,
    )? fetchHubAnalytics,
    Future<SleepSyncResult?> Function({
      int lookbackDays,
      Duration minInterval,
      bool force,
    })? importSleepIfDue,
    Future<bool> Function()? isSleepTrackingEnabled,
    Future<int> Function()? targetStepsLoader,
    Future<String> Function()? stepsProviderNameLoader,
  })  : _hubDataAdapter = hubDataAdapter ??
            StatisticsHubDataAdapter(
              workoutDatabaseHelper: WorkoutDatabaseHelper.instance,
            ),
        _stepsRepository =
            stepsRepository ?? HealthStepsAggregationRepository(),
        _sleepSummaryRepository =
            sleepSummaryRepository ?? SleepHubSummaryRepository(),
        _pulseRepository =
            pulseRepository ?? HealthPulseAnalysisRepository(),
        _stepsSyncService = stepsSyncService ?? StepsSyncService(),
        _sleepSyncService = sleepSyncService ?? SleepSyncService(),
        _fetchHubAnalyticsOverride = fetchHubAnalytics,
        _importSleepIfDueOverride = importSleepIfDue,
        _isSleepTrackingEnabledOverride = isSleepTrackingEnabled,
        _targetStepsLoaderOverride = targetStepsLoader,
        _stepsProviderNameLoaderOverride = stepsProviderNameLoader {
    StepsSyncService.trackingEnabledListenable.addListener(
      _onTrackingEnabledChanged,
    );
    SleepSyncService.trackingEnabledListenable.addListener(
      _onSleepTrackingEnabledChanged,
    );
    PulseTrackingService.trackingEnabledListenable.addListener(
      _onPulseTrackingEnabledChanged,
    );
    _syncTrackingEnabledFromSettings();
    loadHubAnalytics();
  }

  @override
  void dispose() {
    StepsSyncService.trackingEnabledListenable.removeListener(
      _onTrackingEnabledChanged,
    );
    SleepSyncService.trackingEnabledListenable.removeListener(
      _onSleepTrackingEnabledChanged,
    );
    PulseTrackingService.trackingEnabledListenable.removeListener(
      _onPulseTrackingEnabledChanged,
    );
    _sleepSummaryRepository.dispose();
    super.dispose();
  }

  void _onTrackingEnabledChanged() {
    final enabled = StepsSyncService.trackingEnabledListenable.value;
    if (enabled == null) return;
    if (!enabled) {
      if (_stepsTrackingEnabled) {
        _stepsTrackingEnabled = false;
        notifyListeners();
      }
      return;
    }
    if (!_stepsTrackingEnabled) {
      _stepsTrackingEnabled = true;
      notifyListeners();
    }
    loadHubAnalytics();
  }

  void _onPulseTrackingEnabledChanged() {
    final enabled = PulseTrackingService.trackingEnabledListenable.value;
    if (enabled == null) return;
    if (!enabled) {
      _pulseTrackingEnabled = false;
      _pulseState = SectionLoadState<PulseAnalysisSummary>(
        generation: _pulseState.generation + 1,
      );
      notifyListeners();
      return;
    }
    if (!_pulseTrackingEnabled) {
      _pulseTrackingEnabled = true;
      notifyListeners();
    }
    if (_pulseState.isLoading) return;
    loadHubAnalytics();
  }

  void _onSleepTrackingEnabledChanged() {
    final enabled = SleepSyncService.trackingEnabledListenable.value;
    if (enabled == null) return;
    if (!enabled) {
      _sleepTrackingEnabled = false;
      _sleepState = SectionLoadState<SleepHubSummary>(
        generation: _sleepState.generation + 1,
      );
      notifyListeners();
      return;
    }
    if (!_sleepTrackingEnabled) {
      _sleepTrackingEnabled = true;
      notifyListeners();
    }
    if (_sleepState.isLoading) return;
    loadHubAnalytics();
  }

  Future<void> _syncTrackingEnabledFromSettings() async {
    final enabled = await _stepsSyncService.isTrackingEnabled();
    if (enabled == _stepsTrackingEnabled) return;
    _stepsTrackingEnabled = enabled;
    notifyListeners();
  }

  Future<void> loadHubAnalytics() async {
    final loadGeneration = ++_hubAnalyticsLoadGeneration;
    final selectedRangeIndex = _selectedTimeRangeIndex;
    final rangeContextFuture = _resolveHubRangeContext(
      selectedRangeIndex: selectedRangeIndex,
    );

    _stepsState = _stepsState.loading(loadGeneration);
    _recoveryState = _recoveryState.loading(loadGeneration);
    _sleepState = _sleepState.loading(loadGeneration);
    _pulseState = _pulseState.loading(loadGeneration);
    _consistencyState = _consistencyState.loading(loadGeneration);
    _performanceState = _performanceState.loading(loadGeneration);
    _volumeMusclesState = _volumeMusclesState.loading(loadGeneration);
    _bodyNutritionState = _bodyNutritionState.loading(loadGeneration);
    notifyListeners();

    unawaited(_loadStepsSection(loadGeneration, rangeContextFuture));
    unawaited(_loadSleepSection(loadGeneration, rangeContextFuture));
    unawaited(_loadPulseSection(loadGeneration, rangeContextFuture));

    if (_fetchHubAnalyticsOverride != null) {
      unawaited(_loadLegacyAggregateSections(
        loadGeneration,
        selectedRangeIndex,
      ));
      return;
    }

    unawaited(_loadRecoverySection(loadGeneration, selectedRangeIndex));
    unawaited(_loadConsistencySection(loadGeneration, selectedRangeIndex));
    unawaited(_loadPerformanceRecordsSection(
      loadGeneration,
      selectedRangeIndex,
    ));
    unawaited(_loadVolumeMusclesSection(loadGeneration, selectedRangeIndex));
    unawaited(_loadBodyNutritionSection(loadGeneration, selectedRangeIndex));
  }

  bool _isCurrentStepsLoad(int generation) =>
      _stepsState.generation == generation;

  bool _isCurrentRecoveryLoad(int generation) =>
      _recoveryState.generation == generation;

  bool _isCurrentSleepLoad(int generation) =>
      _sleepState.generation == generation;

  bool _isCurrentPulseLoad(int generation) =>
      _pulseState.generation == generation;

  bool _isCurrentConsistencyLoad(int generation) =>
      _consistencyState.generation == generation;

  bool _isCurrentPerformanceLoad(int generation) =>
      _performanceState.generation == generation;

  bool _isCurrentVolumeMusclesLoad(int generation) =>
      _volumeMusclesState.generation == generation;

  bool _isCurrentBodyNutritionLoad(int generation) =>
      _bodyNutritionState.generation == generation;

  Future<HubRangeContext> _resolveHubRangeContext({
    required int selectedRangeIndex,
  }) async {
    final selectedDays = _rangePolicy.selectedDaysFromIndex(
      selectedRangeIndex,
    );
    final earliest = await PerfDebugTimer.time(
      area: 'statistics',
      label: 'stepsEarliest',
      action: _stepsRepository.getEarliestAvailableDate,
    );
    final resolvedRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      selectedRangeIndex: selectedRangeIndex,
      selectedDays: selectedDays,
      earliestAvailableDay: earliest,
    );
    return HubRangeContext(
      selectedDays: selectedDays,
      daysBack: resolvedRange.effectiveDays ?? selectedDays,
    );
  }

  Future<void> _loadStepsSection(
    int generation,
    Future<HubRangeContext> rangeContextFuture,
  ) async {
    final stopwatch = Stopwatch()..start();
    var rangeLabel = '';
    try {
      final rangeContext = await rangeContextFuture;
      rangeLabel = '${rangeContext.daysBack}d';
      final endDate = DateTime.now();
      final results = await Future.wait<dynamic>([
        _stepsRepository.getRangeAggregation(
          endDate: endDate,
          daysBack: rangeContext.daysBack,
        ),
        _stepsRepository.isTrackingEnabled(),
        _targetStepsLoaderOverride?.call() ??
            _stepsRepository.getCurrentTargetStepsOrDefault(),
        _stepsProviderNameLoaderOverride?.call() ?? _loadStepsProviderNameDefault(),
      ]);
      if (!_isCurrentStepsLoad(generation)) return;

      final enabled = StepsSyncService.trackingEnabledListenable.value ??
          (results[1] as bool);
      _stepsTrackingEnabled = enabled;
      _stepsState = _stepsState.success(
        StepsSectionData(
          range: results[0] as RangeStepsAggregation,
          trackingEnabled: enabled,
          targetSteps: results[2] as int,
          providerName: results[3] as String,
        ),
        generation,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(StatisticsHubSectionId.steps, error, stackTrace);
      if (!_isCurrentStepsLoad(generation)) return;
      _stepsState = _stepsState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.steps',
        elapsed: stopwatch.elapsed,
        fields: {'range': rangeLabel},
      );
    }
  }

  Future<void> _loadSleepSection(
    int generation,
    Future<HubRangeContext> rangeContextFuture,
  ) async {
    final stopwatch = Stopwatch()..start();
    var rangeLabel = '';
    try {
      final trackingEnabled = await (_isSleepTrackingEnabledOverride?.call() ??
          _sleepSyncService.isTrackingEnabled());
      if (!_isCurrentSleepLoad(generation)) return;

      if (!trackingEnabled) {
        _sleepTrackingEnabled = false;
        _sleepState = SectionLoadState<SleepHubSummary>(
          generation: generation,
        );
        notifyListeners();
        return;
      }

      if (!_sleepTrackingEnabled) {
        _sleepTrackingEnabled = true;
      }

      final results = await Future.wait<dynamic>([
        _importSleepIfDueOverride?.call(minInterval: _sleepSyncInterval) ??
            _sleepSyncService.importRecentIfDue(
              minInterval: _sleepSyncInterval,
            ),
        rangeContextFuture,
      ]);
      final rangeContext = results[1] as HubRangeContext;
      rangeLabel = '${rangeContext.daysBack}d';
      final summary = await _sleepSummaryRepository.fetchSummary(
        endDate: DateTime.now(),
        daysBack: rangeContext.daysBack,
      );
      if (!_isCurrentSleepLoad(generation) || !_sleepTrackingEnabled) return;
      _sleepState = _sleepState.success(summary, generation);
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(StatisticsHubSectionId.sleep, error, stackTrace);
      if (!_isCurrentSleepLoad(generation)) return;
      _sleepState = _sleepState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.sleep',
        elapsed: stopwatch.elapsed,
        fields: {'range': rangeLabel},
      );
    }
  }

  Future<void> _loadPulseSection(
    int generation,
    Future<HubRangeContext> rangeContextFuture,
  ) async {
    final stopwatch = Stopwatch()..start();
    var rangeLabel = '';
    try {
      final trackingEnabled = await _pulseRepository.isTrackingEnabled();
      if (!trackingEnabled) {
        if (!_isCurrentPulseLoad(generation)) return;
        _pulseTrackingEnabled = false;
        _pulseState = const SectionLoadState<PulseAnalysisSummary>();
        notifyListeners();
        return;
      }

      if (!_pulseTrackingEnabled && _isCurrentPulseLoad(generation)) {
        _pulseTrackingEnabled = true;
      }

      final rangeContext = await rangeContextFuture;
      rangeLabel = '${rangeContext.daysBack}d';
      final summary = await _pulseRepository.getAnalysis(
        window: _pulseWindowForDaysBack(rangeContext.daysBack),
      );
      if (!_isCurrentPulseLoad(generation) || !_pulseTrackingEnabled) return;
      _pulseTrackingEnabled = true;
      _pulseState = _pulseState.success(summary, generation);
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(StatisticsHubSectionId.pulse, error, stackTrace);
      if (!_isCurrentPulseLoad(generation)) return;
      _pulseState = _pulseState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.pulse',
        elapsed: stopwatch.elapsed,
        fields: {'range': rangeLabel},
      );
    }
  }

  Future<void> _loadLegacyAggregateSections(
    int generation,
    int selectedRangeIndex,
  ) async {
    final stopwatch = Stopwatch()..start();
    final selectedDays = _rangePolicy.selectedDaysFromIndex(selectedRangeIndex);
    try {
      final tuple = await _fetchHubAnalytics(
        selectedTimeRangeIndex: selectedRangeIndex,
      );
      if (!_isCurrentRecoveryLoad(generation)) return;
      final hub = tuple.$1;
      final bodyNutrition = tuple.$2;
      _recoveryState =
          _recoveryState.success(hub.recoveryAnalytics, generation);
      _consistencyState = _consistencyState.success(
        ConsistencySectionData(
          workoutsPerWeek: hub.workoutsPerWeek,
          weeklyConsistencyMetrics: hub.weeklyConsistencyMetrics,
          trainingStats: hub.trainingStats,
        ),
        generation,
      );
      _performanceState = _performanceState.success(
        PerformanceRecordsSectionData(
          recentPrs: hub.recentPrs,
          notableImprovements: hub.notableImprovements,
        ),
        generation,
      );
      _volumeMusclesState = _volumeMusclesState.success(
        VolumeMusclesSectionData(
          weeklyVolume: hub.weeklyVolume,
          muscleAnalytics: hub.muscleAnalytics,
        ),
        generation,
      );
      _bodyNutritionState =
          _bodyNutritionState.success(bodyNutrition, generation);
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(
        StatisticsHubSectionId.performanceRecords,
        error,
        stackTrace,
      );
      if (!_isCurrentRecoveryLoad(generation)) return;
      _recoveryState = _recoveryState.failure(error, stackTrace, generation);
      _consistencyState =
          _consistencyState.failure(error, stackTrace, generation);
      _performanceState =
          _performanceState.failure(error, stackTrace, generation);
      _volumeMusclesState =
          _volumeMusclesState.failure(error, stackTrace, generation);
      _bodyNutritionState =
          _bodyNutritionState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.legacyAggregate',
        elapsed: stopwatch.elapsed,
        fields: {'range': '${selectedDays}d'},
      );
    }
  }

  Future<void> _loadRecoverySection(
    int generation,
    int selectedRangeIndex,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final data = await _hubDataAdapter.fetchRecovery(
        selectedTimeRangeIndex: selectedRangeIndex,
      );
      if (!_isCurrentRecoveryLoad(generation)) return;
      _recoveryState = _recoveryState.success(
        data,
        generation,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(StatisticsHubSectionId.recovery, error, stackTrace);
      if (!_isCurrentRecoveryLoad(generation)) return;
      _recoveryState = _recoveryState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.recovery',
        elapsed: stopwatch.elapsed,
        fields: const {'fixed': '14d'},
      );
    }
  }

  Future<void> _loadConsistencySection(
    int generation,
    int selectedRangeIndex,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final data = await _hubDataAdapter.fetchConsistency(
        selectedTimeRangeIndex: selectedRangeIndex,
      );
      if (!_isCurrentConsistencyLoad(generation)) return;
      _consistencyState = _consistencyState.success(
        ConsistencySectionData(
          workoutsPerWeek: data.workoutsPerWeek,
          weeklyConsistencyMetrics: data.weeklyConsistencyMetrics,
          trainingStats: data.trainingStats,
        ),
        generation,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(StatisticsHubSectionId.consistency, error, stackTrace);
      if (!_isCurrentConsistencyLoad(generation)) return;
      _consistencyState =
          _consistencyState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.consistency',
        elapsed: stopwatch.elapsed,
        fields: const {'fixed': '6w'},
      );
    }
  }

  Future<void> _loadPerformanceRecordsSection(
    int generation,
    int selectedRangeIndex,
  ) async {
    final stopwatch = Stopwatch()..start();
    final selectedDays = _rangePolicy.selectedDaysFromIndex(selectedRangeIndex);
    try {
      final data = await _hubDataAdapter.fetchPerformanceRecords(
        selectedTimeRangeIndex: selectedRangeIndex,
      );
      if (!_isCurrentPerformanceLoad(generation)) return;
      _performanceState = _performanceState.success(
        PerformanceRecordsSectionData(
          recentPrs: data.recentPrs,
          notableImprovements: data.notableImprovements,
        ),
        generation,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(
        StatisticsHubSectionId.performanceRecords,
        error,
        stackTrace,
      );
      if (!_isCurrentPerformanceLoad(generation)) return;
      _performanceState =
          _performanceState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.performanceRecords',
        elapsed: stopwatch.elapsed,
        fields: {'range': '${selectedDays}d'},
      );
    }
  }

  Future<void> _loadVolumeMusclesSection(
    int generation,
    int selectedRangeIndex,
  ) async {
    final stopwatch = Stopwatch()..start();
    final selectedDays = _rangePolicy.selectedDaysFromIndex(selectedRangeIndex);
    try {
      final data = await _hubDataAdapter.fetchVolumeMuscles(
        selectedTimeRangeIndex: selectedRangeIndex,
      );
      if (!_isCurrentVolumeMusclesLoad(generation)) return;
      _volumeMusclesState = _volumeMusclesState.success(
        VolumeMusclesSectionData(
          weeklyVolume: data.weeklyVolume,
          muscleAnalytics: data.muscleAnalytics,
        ),
        generation,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(
        StatisticsHubSectionId.volumeMuscles,
        error,
        stackTrace,
      );
      if (!_isCurrentVolumeMusclesLoad(generation)) return;
      _volumeMusclesState =
          _volumeMusclesState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.volumeMuscles',
        elapsed: stopwatch.elapsed,
        fields: {'range': '${selectedDays}d'},
      );
    }
  }

  Future<void> _loadBodyNutritionSection(
    int generation,
    int selectedRangeIndex,
  ) async {
    final stopwatch = Stopwatch()..start();
    final selectedDays = _rangePolicy.selectedDaysFromIndex(selectedRangeIndex);
    final rangeLabel = _rangePolicy.isAllTimeRangeIndex(selectedRangeIndex)
        ? 'All'
        : '${selectedDays}d';
    try {
      final data = await _hubDataAdapter.fetchBodyNutrition(
        selectedTimeRangeIndex: selectedRangeIndex,
      );
      if (!_isCurrentBodyNutritionLoad(generation)) return;
      _bodyNutritionState = _bodyNutritionState.success(data, generation);
      notifyListeners();
    } catch (error, stackTrace) {
      _logSectionFailure(
        StatisticsHubSectionId.bodyNutrition,
        error,
        stackTrace,
      );
      if (!_isCurrentBodyNutritionLoad(generation)) return;
      _bodyNutritionState =
          _bodyNutritionState.failure(error, stackTrace, generation);
      notifyListeners();
    } finally {
      stopwatch.stop();
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'section.bodyNutrition',
        elapsed: stopwatch.elapsed,
        fields: {'range': rangeLabel},
      );
    }
  }

  void _logSectionFailure(
    StatisticsHubSectionId sectionId,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint('[perf][statistics] section.${sectionId.name} error=$error');
    final stackLines = stackTrace.toString().trimRight().split('\n');
    debugPrint(stackLines.take(8).join('\n'));
  }

  PulseAnalysisWindow _pulseWindowForDaysBack(int daysBack) {
    final safeDays = daysBack < 1 ? 1 : daysBack;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: safeDays - 1));
    final endExclusive = today.add(const Duration(days: 1));
    return PulseAnalysisWindow(
      startUtc: start.toUtc(),
      endUtc: endExclusive.toUtc(),
    );
  }

  Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)>
      _fetchHubAnalytics({required int selectedTimeRangeIndex}) {
    final override = _fetchHubAnalyticsOverride;
    if (override != null) {
      return override(selectedTimeRangeIndex);
    }
    return _hubDataAdapter.fetch(
      selectedTimeRangeIndex: selectedTimeRangeIndex,
    );
  }

  Future<String> _loadStepsProviderNameDefault() async {
    final providerFilter = await _stepsSyncService.getProviderFilter();
    final providerRaw = StepsSyncService.providerFilterToRaw(providerFilter);
    return providerRaw;
  }
}
