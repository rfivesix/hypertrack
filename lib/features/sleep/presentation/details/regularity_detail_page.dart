import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/summary_card.dart';
import '../../data/sleep_day_repository.dart';
import 'regularity_chart_math.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class RegularityDetailPage extends StatelessWidget {
  const RegularityDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final nights = overview?.regularityNights ?? const <SleepRegularityNight>[];
    if (nights.isEmpty) {
      return const SleepDetailUnavailablePage(
        title: 'Regularity',
        message: 'Regularity data is unavailable.',
      );
    }

    final bedtimeAvg = circularAverageMinutes(
      nights.map((night) => night.bedtimeMinutes),
    );
    final wakeAvg = circularAverageMinutes(
      nights.map((night) => night.wakeMinutes),
    );

    return SleepDetailPageShell(
      title: 'Regularity',
      value: '${nights.length}-night range',
      statusLabel:
          nights.length >= 7 ? 'Sufficient trend data' : 'Limited trend data',
      subtitle: 'Bedtime and wake windows for recent nights.',
      children: [
        _RegularityChart(nights: nights),
        const SizedBox(height: 12),
        _RegularitySummaryRow(
          label: 'Average bedtime',
          value: formatBedtimeMinutes(bedtimeAvg),
        ),
        _RegularitySummaryRow(
          label: 'Average wake',
          value: formatBedtimeMinutes(wakeAvg),
        ),
      ],
    );
  }
}

class _RegularityChart extends StatelessWidget {
  const _RegularityChart({required this.nights});

  final List<SleepRegularityNight> nights;
  static const int _defaultAxisStart = 18 * 60;
  static const int _defaultAxisEnd = 12 * 60 + 1440;

  @override
  Widget build(BuildContext context) {
    final displayNights =
        nights.length <= 7 ? nights : nights.sublist(nights.length - 7);
    final adjusted = displayNights
        .map((night) => _AdjustedNight.from(night, _defaultAxisStart))
        .toList(growable: false);
    final minBed = adjusted.map((night) => night.bedAdjusted).reduce(math.min);
    final maxWake =
        adjusted.map((night) => night.wakeAdjusted).reduce(math.max);
    final axisStart = math.min(_defaultAxisStart, minBed).toInt();
    final axisEnd = math.max(_defaultAxisEnd, maxWake).toInt();
    final ticks = _buildTicks(axisStart, axisEnd);
    final dateFormat = DateFormat('MM/dd');
    return SummaryCard(
      child: SizedBox(
        height: 240,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 52,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    return Stack(
                      children: [
                        for (final tick in ticks)
                          Positioned(
                            top: _yFor(tick, height, axisStart, axisEnd) -
                                8,
                            left: 0,
                            right: 0,
                            child: Text(
                              formatBedtimeMinutes(tick),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = constraints.maxHeight;
                          final columnWidth = width / adjusted.length;
                          final barWidth = (columnWidth * 0.55)
                              .clamp(6.0, 18.0)
                              .toDouble();
                          return Stack(
                            children: [
                              for (final tick in ticks)
                                Positioned(
                                  top: _yFor(tick, height, axisStart, axisEnd),
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 1,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                              for (var i = 0; i < adjusted.length; i++)
                                _SleepWindowBar(
                                  bed: adjusted[i].bedAdjusted,
                                  wake: adjusted[i].wakeAdjusted,
                                  axisStart: axisStart,
                                  axisEnd: axisEnd,
                                  height: height,
                                  left: (columnWidth * i) +
                                      (columnWidth / 2) -
                                      (barWidth / 2),
                                  width: barWidth,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.85),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final night in adjusted)
                          Expanded(
                            child: Text(
                              dateFormat.format(night.nightDate),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdjustedNight {
  const _AdjustedNight({
    required this.nightDate,
    required this.bedAdjusted,
    required this.wakeAdjusted,
  });

  final DateTime nightDate;
  final int bedAdjusted;
  final int wakeAdjusted;

  factory _AdjustedNight.from(SleepRegularityNight night, int axisStart) {
    final bed = _adjustMinutes(night.bedtimeMinutes, axisStart);
    var wake = _adjustMinutes(night.wakeMinutes, axisStart);
    if (wake <= bed) {
      wake += 1440;
    }
    return _AdjustedNight(
      nightDate: night.nightDate.toLocal(),
      bedAdjusted: bed,
      wakeAdjusted: wake,
    );
  }
}

class _SleepWindowBar extends StatelessWidget {
  const _SleepWindowBar({
    required this.bed,
    required this.wake,
    required this.axisStart,
    required this.axisEnd,
    required this.height,
    required this.left,
    required this.width,
    required this.color,
  });

  final int bed;
  final int wake;
  final int axisStart;
  final int axisEnd;
  final double height;
  final double left;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bedY = _yFor(bed, height, axisStart, axisEnd);
    final wakeY = _yFor(wake, height, axisStart, axisEnd);
    final barTop = math.min(bedY, wakeY);
    final barHeight =
        (wakeY - bedY).abs().clamp(2.0, height).toDouble();
    return Positioned(
      top: barTop,
      left: left,
      width: width,
      height: barHeight,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

List<int> _buildTicks(int axisStart, int axisEnd) {
  const step = 4 * 60;
  final ticks = <int>[];
  var tick = axisStart - (axisStart % step);
  if (tick < axisStart) tick += step;
  for (var value = tick; value <= axisEnd; value += step) {
    ticks.add(value);
  }
  if (ticks.isEmpty || ticks.first != axisStart) {
    ticks.insert(0, axisStart);
  }
  if (ticks.last != axisEnd) {
    ticks.add(axisEnd);
  }
  return ticks;
}

int _adjustMinutes(int minutes, int axisStart) {
  var normalized = ((minutes % 1440) + 1440) % 1440;
  if (normalized < axisStart) {
    normalized += 1440;
  }
  return normalized;
}

double _yFor(num minutes, double height, int axisStart, int axisEnd) {
  final range = math.max(1, axisEnd - axisStart).toDouble();
  return ((minutes.toDouble() - axisStart) / range) * height;
}

class _RegularitySummaryRow extends StatelessWidget {
  const _RegularitySummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}
