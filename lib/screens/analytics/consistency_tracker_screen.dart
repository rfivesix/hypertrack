import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../features/statistics/domain/consistency_domain_service.dart';
import '../../features/statistics/domain/consistency_payload_models.dart';
import '../../data/workout_database_helper.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../widgets/analytics_section_header.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/summary_card.dart';

enum _ConsistencyMetric { volume, duration, frequency }

class ConsistencyTrackerScreen extends StatefulWidget {
  const ConsistencyTrackerScreen({super.key});

  @override
  State<ConsistencyTrackerScreen> createState() =>
      _ConsistencyTrackerScreenState();
}

class _ConsistencyTrackerScreenState extends State<ConsistencyTrackerScreen> {
  bool _isLoading = true;
  TrainingStatsPayload _trainingStats = const TrainingStatsPayload(
    totalWorkouts: 0,
    thisWeekCount: 0,
    avgPerWeek: 0.0,
    streakWeeks: 0,
  );
  List<WeeklyConsistencyMetricPayload> _weeklyMetrics = const [];
  Map<DateTime, int> _workoutDayCounts = const {};
  _ConsistencyMetric _selectedMetric = _ConsistencyMetric.volume;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = WorkoutDatabaseHelper.instance.getTrainingStats();
    final weekly = WorkoutDatabaseHelper.instance
        .getWeeklyConsistencyMetrics(weeksBack: 12);
    final dayCounts =
        WorkoutDatabaseHelper.instance.getWorkoutDayCounts(daysBack: 120);

    final results = await Future.wait([stats, weekly, dayCounts]);
    if (!mounted) return;

    setState(() {
      _trainingStats =
          TrainingStatsPayload.fromMap(results[0] as Map<String, dynamic>);
      _weeklyMetrics = (results[1] as List<Map<String, dynamic>>)
          .map(WeeklyConsistencyMetricPayload.fromMap)
          .toList();
      _workoutDayCounts = results[2] as Map<DateTime, int>;
      _isLoading = false;
    });
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _dailyCount(DateTime day) => _workoutDayCounts[_normalize(day)] ?? 0;

  double _metricValue(WeeklyConsistencyMetricPayload row) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume => row.tonnage,
      _ConsistencyMetric.duration => row.durationMinutes,
      _ConsistencyMetric.frequency => row.count.toDouble(),
    };
  }

  String _metricName(AppLocalizations l10n) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume => l10n.metricsVolumeLifted,
      _ConsistencyMetric.duration => l10n.durationLabel,
      _ConsistencyMetric.frequency => l10n.workoutsPerWeekLabel,
    };
  }

  String _metricUnit(AppLocalizations l10n) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume => l10n.analyticsUnitKg,
      _ConsistencyMetric.duration => 'min',
      _ConsistencyMetric.frequency => l10n.analyticsPerWeekAbbrev,
    };
  }

  String _formatAxisValue(double value) {
    if (_selectedMetric == _ConsistencyMetric.volume) {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}k';
      }
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final thisWeek = _trainingStats.thisWeekCount;
    final avgPerWeek = _trainingStats.avgPerWeek;
    final streak = _trainingStats.streakWeeks;
    final total = _trainingStats.totalWorkouts;
    final trainingDaysPerWeek =
        ConsistencyDomainService.computeTrainingDaysPerWeekLast4(
      workoutDayCounts: _workoutDayCounts,
    );
    final rhythmDelta = ConsistencyDomainService.computeRhythmDelta(
      weeklyMetrics: _weeklyMetrics,
    );
    final rollingConsistency = ConsistencyDomainService.rollingConsistencyPercent(
      weeklyMetrics: _weeklyMetrics,
    );

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.consistencyTrackerTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(l10n.analyticsKpisHeader),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricCard(l10n.metricsWorkoutsWeek, '$thisWeek',
                          l10n.thisWeekLabel),
                      _metricCard(
                          l10n.analyticsTrainingDaysPerWeek,
                          trainingDaysPerWeek.toStringAsFixed(1),
                          l10n.analyticsLast4Weeks),
                      _metricCard(
                          l10n.avgPerWeekLabel,
                          avgPerWeek.toStringAsFixed(1),
                          l10n.workoutsPerWeekLabel),
                      _metricCard(l10n.streakLabel, '$streak', l10n.weeksLabel),
                      _metricCard(
                          l10n.analyticsRhythm,
                          ConsistencyDomainService.formatTrend(rhythmDelta),
                          l10n.analyticsVsPrior4Weeks),
                      _metricCard(
                          l10n.analyticsRollingConsistency,
                          '${rollingConsistency.toStringAsFixed(0)}%',
                          l10n.analyticsWeeksAtLeast2Workouts),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionHeader(_metricName(l10n)),
                  SummaryCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.metricsVolumeLifted),
                              selected:
                                  _selectedMetric == _ConsistencyMetric.volume,
                              onSelected: (_) {
                                setState(() => _selectedMetric =
                                    _ConsistencyMetric.volume);
                              },
                            ),
                            ChoiceChip(
                              label: Text(l10n.durationLabel),
                              selected: _selectedMetric ==
                                  _ConsistencyMetric.duration,
                              onSelected: (_) {
                                setState(() => _selectedMetric =
                                    _ConsistencyMetric.duration);
                              },
                            ),
                            ChoiceChip(
                              label: Text(l10n.workoutsPerWeekLabel),
                              selected: _selectedMetric ==
                                  _ConsistencyMetric.frequency,
                              onSelected: (_) {
                                setState(() => _selectedMetric =
                                    _ConsistencyMetric.frequency);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Y: ${_metricName(l10n)} (${_metricUnit(l10n)})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 210,
                          child: _weeklyMetrics.isEmpty
                              ? Center(child: Text(l10n.noWorkoutDataLabel))
                              : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    borderData: FlBorderData(show: false),
                                    gridData: const FlGridData(
                                        show: true, drawVerticalLine: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 28,
                                          getTitlesWidget: (value, meta) =>
                                              Text(
                                            _formatAxisValue(value),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            final i = value.toInt();
                                            if (i < 0 ||
                                                i >= _weeklyMetrics.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final label =
                                                _weeklyMetrics[i].weekLabel;
                                            return Text(label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall);
                                          },
                                        ),
                                      ),
                                    ),
                                    barGroups: _weeklyMetrics
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final value = _metricValue(entry.value);
                                      return BarChartGroupData(
                                        x: entry.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: value,
                                            width: 12,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'X: ${l10n.analyticsViewWeek.toLowerCase()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionHeader(l10n.trainingCalendarLabel),
                  SummaryCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.analyticsCalendarExplainer,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.25),
                          ),
                          child: TableCalendar<int>(
                            firstDay: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDay:
                                DateTime.now().add(const Duration(days: 30)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                _selectedDay != null &&
                                isSameDay(_selectedDay, day),
                            eventLoader: (day) {
                              final count = _dailyCount(day);
                              if (count <= 0) return const [];
                              return List<int>.filled(count, 1);
                            },
                            headerStyle: HeaderStyle(
                              titleCentered: true,
                              formatButtonVisible: false,
                              titleTextStyle: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold) ??
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: false,
                              defaultTextStyle:
                                  Theme.of(context).textTheme.bodySmall ??
                                      const TextStyle(),
                            ),
                            calendarBuilders: CalendarBuilders<int>(
                              defaultBuilder: (context, day, _) {
                                final count = _dailyCount(day);
                                if (count <= 0) return null;
                                final intensity =
                                    (0.18 + (count * 0.14)).clamp(0.18, 0.65);
                                return Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: intensity),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                              markerBuilder: (context, day, events) {
                                final count = _dailyCount(day);
                                if (count <= 0) return const SizedBox.shrink();
                                return Positioned(
                                  bottom: 3,
                                  child: Text(
                                    count.toString(),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                );
                              },
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() => _focusedDay = focusedDay);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDay == null
                              ? l10n.analyticsSelectDayPrompt
                              : l10n.analyticsSelectedDayWorkouts(
                                  '${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}',
                                  _dailyCount(_selectedDay!),
                                ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  SummaryCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.analyticsTotalSessions),
                      trailing: Text(
                        '$total',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String text) {
    return AnalyticsSectionHeader(title: text);
  }

  Widget _metricCard(String label, String value, String subtitle) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
