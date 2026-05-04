import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../generated/app_localizations.dart';
import '../../../models/chart_data_point.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/measurement_chart_widget.dart';
import '../../../widgets/summary_card.dart';
import '../../sleep/presentation/widgets/sleep_period_scope_layout.dart';
import '../data/pulse_repository.dart';
import '../domain/pulse_models.dart';

class PulseAnalysisScreen extends StatefulWidget {
  const PulseAnalysisScreen({
    super.key,
    PulseAnalysisRepository? repository,
    this.initialScope = SleepPeriodScope.day,
    this.initialDate,
  }) : _repository = repository;

  final PulseAnalysisRepository? _repository;
  final SleepPeriodScope initialScope;
  final DateTime? initialDate;

  @override
  State<PulseAnalysisScreen> createState() => _PulseAnalysisScreenState();
}

class _PulseAnalysisScreenState extends State<PulseAnalysisScreen> {
  static const Duration _minimumCurrentDayWindow = Duration(minutes: 1);
  late final PulseAnalysisRepository _repository;
  late SleepPeriodScope _scope;
  late DateTime _anchorDate;
  bool _isLoading = true;
  PulseAnalysisSummary? _summary;

  @override
  void initState() {
    super.initState();
    _repository = widget._repository ?? HealthPulseAnalysisRepository();
    _scope = widget.initialScope;
    final seed = widget.initialDate ?? DateTime.now();
    _anchorDate = DateTime(seed.year, seed.month, seed.day);
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    final summary = await _repository.getAnalysis(
      window: _windowFor(scope: _scope, anchorDate: _anchorDate),
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  void _onScopeChanged(SleepPeriodScope scope) {
    if (_scope == scope) return;
    setState(() => _scope = scope);
    _loadAnalysis();
  }

  void _shiftPeriod(int direction) {
    setState(() {
      switch (_scope) {
        case SleepPeriodScope.day:
          _anchorDate = DateTime(
            _anchorDate.year,
            _anchorDate.month,
            _anchorDate.day + direction,
          );
          break;
        case SleepPeriodScope.week:
          _anchorDate = _anchorDate.add(Duration(days: 7 * direction));
          break;
        case SleepPeriodScope.month:
          _anchorDate = DateTime(
            _anchorDate.year,
            _anchorDate.month + direction,
            1,
          );
          break;
      }
    });
    _loadAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PulseCopy(context);
    return SleepPeriodScopeLayout(
      appBarTitle: copy.title,
      selectedScope: _scope,
      anchorDate: _anchorDate,
      onScopeChanged: _onScopeChanged,
      onShiftPeriod: _shiftPeriod,
      child: _isLoading
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          : _PulseAnalysisContent(
              summary: _summary!,
              scope: _scope,
            ),
    );
  }

  PulseAnalysisWindow _windowFor({
    required SleepPeriodScope scope,
    required DateTime anchorDate,
  }) {
    final localNow = DateTime.now();
    final localStart = switch (scope) {
      SleepPeriodScope.day =>
        DateTime(anchorDate.year, anchorDate.month, anchorDate.day),
      SleepPeriodScope.week => DateTime(
          anchorDate.year,
          anchorDate.month,
          anchorDate.day,
        ).subtract(Duration(days: anchorDate.weekday - DateTime.monday)),
      SleepPeriodScope.month => DateTime(anchorDate.year, anchorDate.month, 1),
    };
    final fullLocalEndExclusive = switch (scope) {
      SleepPeriodScope.day => localStart.add(const Duration(days: 1)),
      SleepPeriodScope.week => localStart.add(const Duration(days: 7)),
      SleepPeriodScope.month => DateTime(localStart.year, localStart.month + 1),
    };
    final isCurrentLocalDay = scope == SleepPeriodScope.day &&
        anchorDate.year == localNow.year &&
        anchorDate.month == localNow.month &&
        anchorDate.day == localNow.day;
    final localEndExclusive = isCurrentLocalDay
        ? (localNow.isAfter(localStart)
            ? localNow
            // Guard against zero-length windows during local midnight rollover.
            : localStart.add(_minimumCurrentDayWindow))
        : fullLocalEndExclusive;
    return PulseAnalysisWindow(
      startUtc: localStart.toUtc(),
      endUtc: localEndExclusive.toUtc(),
    );
  }
}

class _PulseAnalysisContent extends StatelessWidget {
  const _PulseAnalysisContent({
    required this.summary,
    required this.scope,
  });

  final PulseAnalysisSummary summary;
  final SleepPeriodScope scope;

  @override
  Widget build(BuildContext context) {
    final copy = _PulseCopy(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final timeFormatter = DateFormat.Hm(locale);
    final points = summary.chartSamples
        .map(
          (sample) => ChartDataPoint(
            date: sample.sampledAtUtc.toLocal(),
            value: sample.bpm,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KpiCard(summary: summary),
        const SizedBox(height: DesignConstants.spacingM),
        SummaryCard(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.chartTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                if (summary.canRenderChart)
                  MeasurementChartWidget.fromData(
                    dataPoints: points,
                    unit: l10n.sleepBpmUnit,
                    axisMode: MeasurementChartAxisMode.time,
                    valueFractionDigits: 0,
                    valueLabelBuilder: (value, unit) =>
                        '${value.round()} $unit',
                    selectedDateLabelBuilder: (value) =>
                        scope == SleepPeriodScope.day
                            ? timeFormatter.format(value)
                            : DateFormat.MMMd(locale).add_Hm().format(value),
                    axisLabelBuilder: (value, _) =>
                        scope == SleepPeriodScope.day
                            ? timeFormatter.format(value)
                            : DateFormat.MMMd(locale).format(value),
                    emptyStateLabel: copy.noDataMessage(summary.noDataReason),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        summary.hasData
                            ? copy.insufficientData
                            : copy.noDataMessage(summary.noDataReason),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${copy.sampleCount(summary.sampleCount)} - ${copy.qualityLabel(summary.quality)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Text(
          copy.methodNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.summary});

  final PulseAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final copy = _PulseCopy(context);
    final l10n = AppLocalizations.of(context)!;
    final range = summary.minBpm == null || summary.maxBpm == null
        ? '--'
        : '${summary.minBpm!.round()}-${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}';
    final average = summary.averageBpm == null
        ? '--'
        : '${summary.averageBpm!.round()} ${l10n.sleepBpmUnit}';
    final resting = summary.restingBpm == null
        ? '--'
        : '${summary.restingBpm!.round()} ${l10n.sleepBpmUnit}';
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricTile(label: copy.rangeLabel, value: range),
            _MetricTile(label: copy.averageLabel, value: average),
            _MetricTile(label: copy.restingLabel, value: resting),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PulseCopy {
  _PulseCopy(BuildContext context) : l10n = AppLocalizations.of(context)!;

  final AppLocalizations l10n;

  String get title => l10n.pulseTitle;
  String get chartTitle => l10n.pulseChartTitle;
  String get rangeLabel => l10n.pulseRangeLabel;
  String get averageLabel => l10n.pulseAverageLabel;
  String get restingLabel => l10n.pulseRestingLabel;
  String get insufficientData => l10n.pulseInsufficientData;
  String get methodNote => l10n.pulseMethodNote;

  String sampleCount(int count) => l10n.pulseSampleCount(count);

  String qualityLabel(PulseDataQuality quality) {
    return switch (quality) {
      PulseDataQuality.ready => l10n.pulseQualityReady,
      PulseDataQuality.limited => l10n.pulseQualityLimited,
      PulseDataQuality.insufficient => l10n.pulseQualityInsufficient,
      PulseDataQuality.noData => l10n.pulseQualityNoData,
    };
  }

  String noDataMessage(PulseNoDataReason reason) {
    return switch (reason) {
      PulseNoDataReason.disabled => l10n.pulseNoDataDisabled,
      PulseNoDataReason.permissionDenied => l10n.pulseNoDataPermissionDenied,
      PulseNoDataReason.platformUnavailable => l10n.pulseNoDataUnavailable,
      PulseNoDataReason.queryFailed => l10n.pulseNoDataQueryFailed,
      _ => l10n.pulseNoDataDefault,
    };
  }
}
