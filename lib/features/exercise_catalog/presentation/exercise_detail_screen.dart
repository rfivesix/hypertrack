// lib/features/exercise_catalog/presentation/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import '../../../generated/app_localizations.dart';
import '../domain/body_slug_mapper.dart';
import '../domain/models/exercise.dart';
import '../../workout/domain/models/set_log.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/summary_card.dart';
import 'widgets/wger_attribution_widget.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../profile/presentation/widgets/measurement_chart_widget.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';
import '../../../services/profile_service.dart';

enum ExerciseMetric { maxWeight, volume, est1rm }

/// A screen displaying detailed information about a specific [Exercise].
class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final IExerciseCatalogRepository? repository;

  const ExerciseDetailScreen(
      {super.key, required this.exercise, this.repository});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final IExerciseCatalogRepository _repository =
      widget.repository ?? context.read<IExerciseCatalogRepository>();
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

    final String? exerciseUuid = widget.exercise.id != null
        ? await _repository.getExerciseUuidByLocalId(widget.exercise.id!)
        : null;

    final altName = widget.exercise.nameEn.isNotEmpty &&
            widget.exercise.nameEn != widget.exercise.nameDe
        ? widget.exercise.nameEn
        : null;

    // Use DB helper directly via repository delegate or repository
    // Let's implement these two methods in ExerciseCatalogRepository to avoid direct DB helper call.
    // Wait, did we define getExercisePRs and getExerciseTimeSeriesData in ExerciseCatalogRepository?
    // Let's check! In ExerciseCatalogRepository:
    // Future<List<Map<String, dynamic>>> getExercisePRs(String exerciseUuid) => _dbHelper.getExercisePRs(exerciseUuid);
    // Wait! In the original _loadData:
    // WorkoutLocalDataSource.instance.getExercisePRs(widget.exercise.nameDe, altName: altName, exerciseUuid: exerciseUuid);
    // So the signature of getExercisePRs is `getExercisePRs(String nameDe, {String? altName, String? exerciseUuid})`.
    // Let's update `ExerciseCatalogRepository`'s methods to match exactly the signature!
    // Wait! We can call `_repository._dbHelper.getExercisePRs(...)` and `_repository._dbHelper.getExerciseTimeSeriesData(...)` directly!
    // Or we can just use `_repository.getExercisePRs(...)` and `_repository.getExerciseTimeSeriesData(...)` if we adapt their signatures.
    // Let's check: our `ExerciseCatalogRepository` was written with:
    // `Future<List<Map<String, dynamic>>> getExercisePRs(String exerciseUuid)` and `Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(String exerciseUuid)`.
    // But `WorkoutLocalDataSource` has:
    // `Future<Map<String, SetLog?>> getExercisePRs(String nameDe, {String? altName, String? exerciseUuid})`
    // and `Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(String nameDe, {String? altName, String? exerciseUuid})`.
    // Let's modify `ExerciseCatalogRepository` to match exactly, or call them directly from repository._dbHelper.
    // Since `repository` is an instance of `ExerciseCatalogRepository` which wraps `WorkoutLocalDataSource`,
    // let's update `ExerciseCatalogRepository` to have the exact correct signatures, so it's a 100% clean proxy!
    // Let's do that in a single file replacement. But first, let's complete `ExerciseDetailScreen` using `_repository._dbHelper`
    // which is perfectly clean since it still delegates through the injected repository interface, OR update the repository file.
    // Actually, calling the repository's methods is cleaner. Let's make `ExerciseDetailScreen` call the repository's database helper.
    // Wait, `_repository._dbHelper` is private in `ExerciseCatalogRepository`. Let's make it public as `dbHelper` or expose the methods correctly.
    // Exposing the methods correctly in the repository is the absolute standard!
    // Let's update `lib/features/exercise_catalog/data/exercise_catalog_repository.dart` to have the correct signatures.
    // Wait, let's write `ExerciseDetailScreen` first using `_repository.getExercisePRs` and `_repository.getExerciseTimeSeriesData`.

    final prs = await _repository.getExercisePRs(
      widget.exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    final timeSeries = await _repository.getExerciseTimeSeriesData(
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
            AppSectionHeader(title: l10n.descriptionLabel),
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
            AppSectionHeader(title: l10n.involvedMuscles),
            _ExerciseMuscleBodyView(exercise: widget.exercise),
            const SizedBox(height: DesignConstants.spacingXL),
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
              AppSectionHeader(title: l10n.workoutHistoryButton),
              _buildConsolidatedChart(l10n),
              const SizedBox(height: DesignConstants.spacingXL),
              _buildPRSummarySection(l10n),
            ],
            const SizedBox(height: DesignConstants.spacingXL),
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
        AppSectionHeader(title: l10n.exerciseAnalyticsPrsLabel),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _prMap.entries.map((entry) {
            final bracket = entry.key;
            final prSet = entry.value;

            return Container(
              width: (MediaQuery.of(context).size.width - 40) / 2,
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
                        '${context.read<UnitService>().convertDisplayValue(prSet.weightKg! * (36 / (37 - prSet.reps!)), UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        '${context.read<UnitService>().convertDisplayValue(prSet.weightKg ?? 0.0, UnitDimension.weight).toStringAsFixed(1)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}',
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
    final unitService = context.watch<UnitService>();
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
            unit: unitService.suffixFor(UnitDimension.weight),
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
}

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

/// Displays front + back [BodyHighlighter] views side by side, plus a compact
/// chip legend listing primary and secondary muscle names.
class _ExerciseMuscleBodyView extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseMuscleBodyView({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasMuscles = exercise.primaryMuscles.isNotEmpty ||
        exercise.secondaryMuscles.isNotEmpty;

    if (!hasMuscles) {
      return SummaryCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            l10n.noMusclesSpecified,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    final allHighlights = BodySlugMapper.mergedHighlights(
      primaryMuscles: exercise.primaryMuscles,
      secondaryMuscles: exercise.secondaryMuscles,
    );

    final frontHighlights = BodySlugMapper.forSide(allHighlights, BodySide.front);
    final backHighlights  = BodySlugMapper.forSide(allHighlights, BodySide.back);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Body diagrams ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.frontLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 200,
                        child: BodyHighlighter(
                          gender: context.watch<ProfileService>().gender.toBodyGender(),
                          highlightedParts: frontHighlights,
                          side: BodySide.front,
                          outlineWidth: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.backLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 200,
                        child: BodyHighlighter(
                          gender: context.watch<ProfileService>().gender.toBodyGender(),
                          highlightedParts: backHighlights,
                          side: BodySide.back,
                          outlineWidth: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── Legend ─────────────────────────────────────────────────────
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _MuscleChipRow(
              label: l10n.primaryLabel,
              muscles: exercise.primaryMuscles,
              color: theme.colorScheme.primary,
            ),
            if (exercise.secondaryMuscles.isNotEmpty) ...[
              const SizedBox(height: 6),
              _MuscleChipRow(
                label: l10n.secondaryLabel,
                muscles: exercise.secondaryMuscles,
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A labelled row of compact muscle-name chips used as a text legend.
class _MuscleChipRow extends StatelessWidget {
  final String label;
  final List<String> muscles;
  final Color color;

  const _MuscleChipRow({
    required this.label,
    required this.muscles,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: muscles
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      m,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}
