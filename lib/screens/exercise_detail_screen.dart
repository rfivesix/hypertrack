import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/set_log.dart';
import '../data/workout_database_helper.dart';
import '../util/design_constants.dart';
import '../widgets/summary_card.dart';
import '../widgets/wger_attribution_widget.dart';
import '../widgets/global_app_bar.dart';

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
  int _selectedTimeRangeIndex = 1; // Default 30 Days

  Map<String, SetLog?> _prMap = {};
  List<Map<String, dynamic>> _timeSeriesData = [];

  List<String> get _timeRanges {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.filter7Days,
      l10n.filter30Days,
      l10n.filter3Months,
      l10n.filter6Months,
      l10n.filterAll,
    ];
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
            // Bild / GIF
            if ((widget.exercise.imagePath ?? '').isNotEmpty)
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  widget.exercise.imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    color: Colors.black12,
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
              _buildTimeRangeFilter(),
              const SizedBox(height: DesignConstants.spacingL),
              _buildPRSummarySection(l10n),
              const SizedBox(height: DesignConstants.spacingL),
              _buildChartsSection(l10n),
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

  Widget _buildTimeRangeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_timeRanges.length, (index) {
          final range = _timeRanges[index];
          final isSelected = _selectedTimeRangeIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(range),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeRangeIndex = index);
                  // Not hooked up for v1
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPRSummarySection(AppLocalizations l10n) {
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
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: prSet != null
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bracket,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (prSet != null) ...[
                    Text(
                      '${prSet.weightKg?.toStringAsFixed(1).replaceAll('.0', '')} kg',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${prSet.reps} Reps',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    Text(
                      '-',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      'No data',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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

  Widget _buildChartsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.exerciseAnalyticsTrendsLabel),
        _buildLineChart(
          title: l10n.exerciseAnalyticsChartWeight,
          dataPoints: _timeSeriesData,
          yValueExtractor: (data) => (data['maxWeight'] as num).toDouble(),
          color: Theme.of(context).colorScheme.primary,
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        _buildLineChart(
          title: l10n.exerciseAnalyticsChartVolume,
          dataPoints: _timeSeriesData,
          yValueExtractor: (data) => (data['totalVolume'] as num).toDouble(),
          color: Colors.orange, // Distinct color for volume
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        _buildLineChart(
          title: l10n.exerciseAnalyticsChartSets,
          dataPoints: _timeSeriesData,
          yValueExtractor: (data) => (data['setCount'] as num).toDouble(),
          color: Colors.blue, // Distinct color for sets
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _buildLineChart({
    required String title,
    required List<Map<String, dynamic>> dataPoints,
    required double Function(Map<String, dynamic>) yValueExtractor,
    required Color color,
    required AppLocalizations l10n,
  }) {
    if (dataPoints.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(l10n.exerciseAnalyticsNotEnoughData)),
      );
    }

    final spots = dataPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), yValueExtractor(e.value));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 180,
          width: double.infinity,
          padding: const EdgeInsets.only(
            right: 16,
            left: 0,
            top: 16,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (LineBarSpot touchedSpot) =>
                      Theme.of(context).colorScheme.inverseSurface,
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      final int index = touchedSpot.x.toInt();
                      final DateTime? date =
                          (index >= 0 && index < dataPoints.length)
                              ? dataPoints[index]['date'] as DateTime?
                              : null;
                      final String dateStr = date != null
                          ? '${date.day}.${date.month}.${date.year}'
                          : '';
                      final String valueStr = touchedSpot.y
                          .toStringAsFixed(1)
                          .replaceAll(RegExp(r'\.0$'), '');

                      return LineTooltipItem(
                        '$dateStr\n',
                        Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onInverseSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                        children: [
                          TextSpan(
                            text: valueStr,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index < 0 || index >= dataPoints.length) {
                        return const SizedBox.shrink();
                      }

                      // Calculate step to avoid overlapping labels
                      final step = (dataPoints.length / 5).ceil();
                      if (index % step != 0 &&
                          index != dataPoints.length - 1 &&
                          index != 0) {
                        return const SizedBox.shrink();
                      }

                      final date = dataPoints[index]['date'] as DateTime;
                      final dateStr = '${date.day}.${date.month}.';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dateStr,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          value.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------
  // Überschriften-Stil
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
// Kategorie-Pill oben rechts
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
// Einzel-Kachel für Primär / Sekundär
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
