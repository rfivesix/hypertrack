import 'package:flutter/material.dart';
import '../../data/workout_database_helper.dart';
import '../../features/statistics/domain/statistics_range_policy.dart';
import '../../features/statistics/presentation/statistics_formatter.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/summary_card.dart';

class PRDashboardScreen extends StatefulWidget {
  const PRDashboardScreen({super.key});

  @override
  State<PRDashboardScreen> createState() => _PRDashboardScreenState();
}

class _PRDashboardScreenState extends State<PRDashboardScreen> {
  final _rangePolicy = StatisticsRangePolicyService.instance;
  static const int _topMomentumIndex = 0;
  static const int _twoColumnGridCount = 2;
  bool _isLoading = true;
  int _selectedWindowDays = 30;

  List<Map<String, dynamic>> _recentPrs = [];
  List<Map<String, dynamic>> _allTimePrs = [];
  List<Map<String, dynamic>> _notableImprovements = [];
  Map<String, Map<String, dynamic>?> _prsByRepRange = const {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final recent = WorkoutDatabaseHelper.instance.getRecentGlobalPRs(limit: 8);
    final allTime =
        WorkoutDatabaseHelper.instance.getAllTimeGlobalPRs(limit: 10);
    final repRange = WorkoutDatabaseHelper.instance.getAllTimePRsByRepBracket();
    final improvements =
        WorkoutDatabaseHelper.instance.getNotablePrImprovements(
      daysWindow: _rangePolicy
              .resolve(
                metricId: StatisticsMetricId.prNotableImprovements,
                selectedDays: _selectedWindowDays,
              )
              .effectiveDays ??
          _selectedWindowDays,
      limit: 6,
    );

    final results = await Future.wait([
      recent,
      allTime,
      repRange,
      improvements,
    ]);

    if (!mounted) return;
    setState(() {
      _recentPrs = results[0] as List<Map<String, dynamic>>;
      _allTimePrs = results[1] as List<Map<String, dynamic>>;
      _prsByRepRange = results[2] as Map<String, Map<String, dynamic>?>;
      _notableImprovements = results[3] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  String _formatWeight(double weight) {
    return StatisticsPresentationFormatter.formatWeight(weight);
  }

  String _perfLabel(Map<String, dynamic> row) {
    final weight = (row['weight'] as num).toDouble();
    final reps = (row['reps'] as num).toInt();
    return l10n.analyticsPerfWithReps(_formatWeight(weight), reps);
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(title: l10n.prDashboardTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrimarySectionHeader(l10n.analyticsNotableImprovements),
                  Row(
                    children: [
                      _windowChip(7, l10n.filter7Days),
                      _windowChip(30, l10n.filter30Days),
                      _windowChip(90, l10n.filter3Months),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  SummaryCard(
                    child: _notableImprovements.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(l10n.analyticsNoPrTrendInWindow),
                          )
                        : Column(
                            children: _notableImprovements.asMap().entries.map((
                              entry,
                            ) {
                              final row = entry.value;
                              final previous =
                                  (row['previousBestE1rm'] as num).toDouble();
                              final recent =
                                  (row['recentBestE1rm'] as num).toDouble();
                              final improvement =
                                  (row['improvementPct'] as num).toDouble();
                              final delta = recent - previous;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                /*
                                leading: entry.key == _topMomentumIndex
                                    ? Icon(
                                        Icons.trending_up,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      )
                                    : null,
                                */
                                title: Text(
                                  row['exerciseName'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  l10n.analyticsE1rmProgress(
                                    _formatWeight(previous),
                                    _formatWeight(recent),
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${improvement.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Δ ${_formatWeight(delta)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  _buildSectionHeader(l10n.analyticsRecentRecords),
                  SummaryCard(
                    child: _recentPrs.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(l10n.noWorkoutDataLabel),
                          )
                        : Column(
                            children: _recentPrs.asMap().entries.map((entry) {
                              return _buildRankedRow(
                                rank: entry.key + 1,
                                exerciseName:
                                    entry.value['exerciseName'] as String,
                                valueLabel: _perfLabel(entry.value),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  _buildSectionHeader(l10n.allTimeRecordsLabel),
                  SummaryCard(
                    child: _allTimePrs.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(l10n.noWorkoutDataLabel),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final tileWidth =
                                  _calculateTileWidth(constraints.maxWidth);
                              return Wrap(
                                spacing: DesignConstants.spacingS,
                                runSpacing: DesignConstants.spacingS,
                                children:
                                    _allTimePrs.asMap().entries.map((entry) {
                                  return Container(
                                    width: tileWidth,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.35),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${entry.key + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _perfLabel(entry.value),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          entry.value['exerciseName'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  _buildSectionHeader(l10n.prsByRepRangeLabel),
                  SummaryCard(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth =
                            _calculateTileWidth(constraints.maxWidth);
                        return Wrap(
                          spacing: DesignConstants.spacingS,
                          runSpacing: DesignConstants.spacingS,
                          children: _prsByRepRange.entries.map((entry) {
                            final data = entry.value;
                            final hasData = data != null;
                            return Container(
                              width: tileWidth,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.replaceAll(
                                        'RM', l10n.analyticsRepRangeSuffix),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  if (hasData) ...[
                                    Text(
                                      l10n.analyticsPerfWithReps(
                                        _formatWeight(
                                            (data['weight'] as num).toDouble()),
                                        (data['reps'] as num).toInt(),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      data['exerciseName'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ] else
                                    Text(
                                      l10n.analyticsNoRecordYet,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double _calculateTileWidth(double availableWidth) {
    return (availableWidth - DesignConstants.spacingS) / _twoColumnGridCount;
  }

  Widget _buildPrimarySectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              color: Colors.grey[600],
            ),
      ),
    );
  }

  Widget _buildRankedRow({
    required int rank,
    required String exerciseName,
    required String valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank.',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              exerciseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valueLabel,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _windowChip(int days, String label) {
    final selected = _selectedWindowDays == days;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {
          if (!value || selected) return;
          setState(() => _selectedWindowDays = days);
          _loadData();
        },
      ),
    );
  }
}
