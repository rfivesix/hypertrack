import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/global_app_bar.dart';
import '../../../../widgets/summary_card.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/sleep_enums.dart';
import '../details/sleep_data_unavailable_card.dart';
import '../sleep_navigation.dart';
import 'sleep_day_view_model.dart';

class SleepDayOverviewPage extends StatelessWidget {
  const SleepDayOverviewPage({
    super.key,
    SleepDayDataRepository? repository,
    SleepDayViewModel? viewModel,
  })  : _repository = repository,
        _viewModel = viewModel;

  final SleepDayDataRepository? _repository;
  final SleepDayViewModel? _viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SleepDayViewModel>(
      create: (_) {
        final model = _viewModel ??
            SleepDayViewModel(repository: _repository ?? SleepDayRepository());
        model.load();
        return model;
      },
      child: const _SleepDayOverviewBody(),
    );
  }
}

class _SleepDayOverviewBody extends StatelessWidget {
  const _SleepDayOverviewBody();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SleepDayViewModel>();
    final overview = model.overview;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlobalAppBar(title: 'Sleep'),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top +
              MediaQuery.of(context).padding.top +
              16,
        ),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Day')),
              ButtonSegment(value: 1, label: Text('Week')),
              ButtonSegment(value: 2, label: Text('Month')),
            ],
            selected: {model.selectedScopeIndex},
            onSelectionChanged: (selection) {
              final selected = selection.first;
              model.setScopeIndex(selected);
              if (selected != 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Week and Month views are not available in this batch yet.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          if (model.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!model.isDayScope)
            const _SleepScopeNotAvailableCard()
          else if (overview == null)
            const _SleepEmptyStateCard()
          else ...[
            _SleepTimelineCard(overview: overview),
            const SizedBox(height: 12),
            _SleepScoreCard(overview: overview),
            const SizedBox(height: 12),
            _SleepMetricTileGrid(overview: overview),
          ],
        ],
      ),
    );
  }
}

class _SleepEmptyStateCard extends StatelessWidget {
  const _SleepEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: const Text('No sleep data available for this day.'),
      ),
    );
  }
}

class _SleepScopeNotAvailableCard extends StatelessWidget {
  const _SleepScopeNotAvailableCard();

  @override
  Widget build(BuildContext context) {
    return const SleepDataUnavailableCard(
      message: 'Week and Month views are not implemented in this batch yet.',
    );
  }
}

class _SleepTimelineCard extends StatelessWidget {
  const _SleepTimelineCard({required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final segments = overview.timelineSegments;
    if (segments.isEmpty) {
      return SummaryCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('No stage timeline available for this night.'),
            ],
          ),
        ),
      );
    }

    final duration = overview.session.endAtUtc.difference(overview.session.startAtUtc);
    final totalMinutes = duration.inMinutes <= 0 ? 1 : duration.inMinutes;
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 16,
              child: Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      flex: (segment.endAtUtc
                              .difference(segment.startAtUtc)
                              .inMinutes
                              .clamp(1, totalMinutes))
                          .toInt(),
                      child: Container(
                        color: _timelineStageColor(context, segment.stage),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _timelineStageColor(BuildContext context, CanonicalSleepStage stage) {
    switch (stage) {
      case CanonicalSleepStage.deep:
        return Colors.indigo;
      case CanonicalSleepStage.rem:
        return Colors.purple;
      case CanonicalSleepStage.light:
      case CanonicalSleepStage.asleepUnspecified:
        return Colors.blue;
      case CanonicalSleepStage.awake:
      case CanonicalSleepStage.outOfBed:
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.outlineVariant;
    }
  }
}

class _SleepScoreCard extends StatelessWidget {
  const _SleepScoreCard({required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final score = overview.analysis.score;
    final scoreText = score == null ? '--' : score.round().toString();
    final quality = overview.analysis.sleepQuality;
    final subtitle = overview.analysis.score == null
        ? 'Score unavailable for this night.'
        : _qualitySubtitle(quality);
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score == null
                        ? 0
                        : (score.clamp(0.0, 100.0) / 100.0).toDouble(),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: _qualityColor(quality),
                  ),
                  Text(scoreText),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sleep quality'),
                  Text(
                    _qualityLabel(quality),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _qualityColor(SleepQualityBucket quality) {
    return switch (quality) {
      SleepQualityBucket.good => Colors.green,
      SleepQualityBucket.average => Colors.orange,
      SleepQualityBucket.poor => Colors.red,
      SleepQualityBucket.unavailable => Colors.grey,
    };
  }

  String _qualityLabel(SleepQualityBucket quality) {
    return switch (quality) {
      SleepQualityBucket.good => 'Good',
      SleepQualityBucket.average => 'Average',
      SleepQualityBucket.poor => 'Poor',
      SleepQualityBucket.unavailable => 'Unavailable',
    };
  }

  String _qualitySubtitle(SleepQualityBucket quality) {
    return switch (quality) {
      SleepQualityBucket.good => 'Recovery looked strong overnight.',
      SleepQualityBucket.average => 'Sleep was okay with room for improvement.',
      SleepQualityBucket.poor => 'Recovery signals were weak tonight.',
      SleepQualityBucket.unavailable => 'Not enough data to score this night.',
    };
  }
}

class _SleepMetricTileGrid extends StatelessWidget {
  const _SleepMetricTileGrid({required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final regularitySubtitle = overview.regularityNights.isEmpty
        ? 'Unavailable'
        : '${overview.regularityNights.length.clamp(0, 7)}-night view';
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      children: [
        _MetricTile(
          title: 'Duration',
          subtitle: '${overview.totalSleepDuration.inHours}h ${overview.totalSleepDuration.inMinutes.remainder(60)}m',
          onTap: () => SleepNavigation.openDurationDetail(
            context,
            overview: overview,
          ),
        ),
        _MetricTile(
          title: 'Heart rate',
          subtitle: overview.sleepHrAvg == null
              ? 'Unavailable'
              : '${overview.sleepHrAvg!.round()} bpm',
          onTap: () => SleepNavigation.openHeartRateDetail(
            context,
            overview: overview,
          ),
        ),
        _MetricTile(
          title: 'Regularity',
          subtitle: regularitySubtitle,
          onTap: () => SleepNavigation.openRegularityDetail(
            context,
            overview: overview,
          ),
        ),
        _MetricTile(
          title: 'Depth',
          subtitle: overview.stageDataConfidence == SleepStageConfidence.low
              ? 'Low confidence'
              : (overview.hasStageData ? 'Stages available' : 'Unavailable'),
          onTap: () => SleepNavigation.openDepthDetail(
            context,
            overview: overview,
          ),
        ),
        _MetricTile(
          title: 'Interruptions',
          subtitle: overview.interruptionsCount == null
              ? 'Unavailable'
              : '${overview.interruptionsCount}',
          onTap: () => SleepNavigation.openInterruptionsDetail(
            context,
            overview: overview,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}
