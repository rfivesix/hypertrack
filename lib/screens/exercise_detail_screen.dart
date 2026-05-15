import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/set_log.dart';
import '../models/chart_data_point.dart';
import '../data/workout_database_helper.dart';
import '../util/design_constants.dart';
import '../widgets/summary_card.dart';
import '../widgets/wger_attribution_widget.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/measurement_chart_widget.dart';

enum ExerciseMetric { maxWeight, volume, est1rm }

/// A screen displaying detailed information about a specific [Exercise].
///
/// Shows descriptions, involved muscles, and instructional images if available,
/// as well as dynamic analytics: PRs and Trend charts.
class ExerciseDetailScreen extends StatefulWidget {
  /// The [Exercise] whose details are to be displayed.
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _isLoading = true;
  ExerciseMetric _selectedMetric = ExerciseMetric.maxWeight;
  String _selectedRange = '30D';

  Map<String, SetLog?> _prMap = {};
  List<Map<String, dynamic>> _timeSeriesData = [];

  int? get _selectedRangeDays {
    if (_selectedRange == '30D') return 30;
    if (_selectedRange == '90D') return 90;
    return null; // 'All'
  }

  List<Map<String, dynamic>> get _filteredTimeSeriesData {
    if (_selectedRangeDays == null) return _timeSeriesData;
    final cutoff = DateTime.now().subtract(Duration(days: _selectedRangeDays!));
    return _timeSeriesData
        .where((data) => (data['date'] as DateTime).isAfter(cutoff))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Look up the exercise UUID so we can also match set_logs that were stored
    // under a different name snapshot (e.g. English name or legacy name).
    final String? exerciseUuid = widget.exercise.id != null
        ? await WorkoutDatabaseHelper.instance.getExerciseUuidByLocalId(
            widget.exercise.id!,
          )
        : null;

    final altName = widget.exercise.nameEn.isNotEmpty &&
            widget.exercise.nameEn != widget.exercise.nameDe
        ? widget.exercise.nameEn
        : null;

    final prs = await WorkoutDatabaseHelper.instance.getExercisePRs(
      widget.exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    final timeSeries =
        await WorkoutDatabaseHelper.instance.getExerciseTimeSeriesData(
      widget.exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    if (mounted) {
      setState(() {
        _prMap = prs;
        _timeSeriesData = timeSeries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: widget.exercise.getLocalizedName(context),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CategoryBadge(text: widget.exercise.categoryName),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / GIF
            if ((widget.exercise.imagePath ?? '').isNotEmpty)
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusL),
                ),
                child: Image.asset(
                  widget.exercise.imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    color: Colors.black12,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusL),
                    ),
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),

            if ((widget.exercise.imagePath ?? '').isNotEmpty)
              const SizedBox(height: DesignConstants.spacingXL),

            // Beschreibung
            _buildSectionTitle(context, l10n.descriptionLabel.toUpperCase()),
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Text(
                  widget.exercise.getLocalizedDescription(context).isNotEmpty
                      ? widget.exercise.getLocalizedDescription(context)
                      : l10n.noDescriptionAvailable,
                  style: textTheme.bodyMedium,
                ),
              ),
            ),

            const SizedBox(height: DesignConstants.spacingXL),

            // Muskeln
            _buildSectionTitle(context, l10n.involvedMuscles.toUpperCase()),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MuscleGroupCard(
                    title: l10n.primaryLabel,
                    muscles: widget.exercise.primaryMuscles,
                    fallback: l10n.noMusclesSpecified,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: _MuscleGroupCard(
                    title: l10n.secondaryLabel,
                    muscles: widget.exercise.secondaryMuscles,
                    fallback: l10n.noMusclesSpecified,
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignConstants.spacingXL),

            // Analytics Section
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_timeSeriesData.isEmpty &&
                _prMap.values.every((v) => v == null))
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    l10n.exerciseAnalyticsNoData,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else ...[
              _buildSectionTitle(
                context,
                l10n.workoutHistoryButton.toUpperCase(),
              ),
              _buildConsolidatedChart(l10n),
              const SizedBox(height: DesignConstants.spacingXL),
              _buildPRSummarySection(l10n),
            ],

            const SizedBox(height: DesignConstants.spacingXL),

            // Attribution
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: DesignConstants.spacingM,
                ),
                child: WgerAttributionWidget(
                  textStyle: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRSummarySection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.exerciseAnalyticsPrsLabel),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _prMap.entries.map((entry) {
            final bracket = entry.key;
            final prSet = entry.value;

            return Container(
              width: (MediaQuery.of(context).size.width - 40) / 2, // 2 cols
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: prSet != null
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bracket,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (prSet != null) ...[
                    if (bracket == 'Est. 1RM')
                      Text(
                        '${(prSet.weightKg! * (36 / (37 - prSet.reps!))).toStringAsFixed(1).replaceAll('.0', '')} kg',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        '${prSet.weightKg?.toStringAsFixed(1).replaceAll('.0', '')} kg',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      '${prSet.reps} Reps',
                      style: theme.textTheme.bodySmall,
                    ),
                  ] else ...[
                    Text(
                      '-',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'No data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConsolidatedChart(AppLocalizations l10n) {
    final filteredData = _filteredTimeSeriesData;

    if (filteredData.isEmpty) {
      return SummaryCard(
        child: Column(
          children: [
            _buildChartHeader(l10n),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(l10n.exerciseAnalyticsNotEnoughData),
            ),
          ],
        ),
      );
    }

    final dataPoints = filteredData.map((e) {
      double y;
      switch (_selectedMetric) {
        case ExerciseMetric.maxWeight:
          y = (e['maxWeight'] as num).toDouble();
          break;
        case ExerciseMetric.volume:
          y = (e['totalVolume'] as num).toDouble();
          break;
        case ExerciseMetric.est1rm:
          y = (e['maxEst1rm'] as num).toDouble();
          break;
      }
      return ChartDataPoint(date: e['date'] as DateTime, value: y);
    }).toList();

    return SummaryCard(
      padding: DesignConstants.cardPadding,
      child: Column(
        children: [
          _buildChartHeader(l10n),
          const SizedBox(height: DesignConstants.spacingS),
          MeasurementChartWidget.fromData(
            dataPoints: dataPoints,
            unit: 'kg',
            axisMode: MeasurementChartAxisMode.day,
          ),
        ],
      ),
    );
  }

  Widget _buildChartHeader(AppLocalizations l10n) {
    final theme = Theme.of(context);
    String metricTitle = '';
    switch (_selectedMetric) {
      case ExerciseMetric.maxWeight:
        metricTitle = l10n.exerciseMetricMaxWeight;
        break;
      case ExerciseMetric.volume:
        metricTitle = l10n.exerciseMetricVolume;
        break;
      case ExerciseMetric.est1rm:
        metricTitle = l10n.exerciseMetricEst1RM;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MenuAnchor(
          builder: (context, controller, child) {
            return GestureDetector(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metricTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            );
          },
          menuChildren: [
            MenuItemButton(
              onPressed: () =>
                  setState(() => _selectedMetric = ExerciseMetric.maxWeight),
              child: Text(l10n.exerciseMetricMaxWeight),
            ),
            MenuItemButton(
              onPressed: () =>
                  setState(() => _selectedMetric = ExerciseMetric.volume),
              child: Text(l10n.exerciseMetricVolume),
            ),
            MenuItemButton(
              onPressed: () =>
                  setState(() => _selectedMetric = ExerciseMetric.est1rm),
              child: Text(l10n.exerciseMetricEst1RM),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: [
            _buildFilterButton('30D', '30D'),
            _buildFilterButton('90D', '90D'),
            _buildFilterButton('All', 'All'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedRange == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedRange = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // Heading style
  // -----------------------------
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// -----------------------------
// Category pill at top right
// -----------------------------
class _CategoryBadge extends StatelessWidget {
  final String text;
  const _CategoryBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary.withValues(alpha: 0.15);
    final fg = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// -----------------------------
// Single tile for primary / secondary
// -----------------------------
class _MuscleGroupCard extends StatelessWidget {
  final String title;
  final List<String> muscles;
  final String fallback;

  const _MuscleGroupCard({
    required this.title,
    required this.muscles,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (muscles.isEmpty)
            Text(
              fallback,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles
                  .map(
                    (m) => Chip(
                      label: Text(m),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}
