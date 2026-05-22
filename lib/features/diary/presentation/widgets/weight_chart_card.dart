import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../profile/presentation/widgets/measurement_chart_widget.dart';

class WeightChartCard extends StatefulWidget {
  const WeightChartCard({super.key});

  @override
  State<WeightChartCard> createState() => _WeightChartCardState();
}

class _WeightChartCardState extends State<WeightChartCard> {
  String _selectedChartRangeKey = '30D';

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedChartRangeKey == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartRangeKey = key;
        });
      },
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
          ),
        ),
      ),
    );
  }

  DateTimeRange _calculateDateRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    DateTime start;
    switch (_selectedChartRangeKey) {
      case '90D':
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 89));
        break;
      case 'All':
        start = DateTime(2020);
        break;
      case '30D':
      default:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
    }
    return DateTimeRange(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
      padding: DesignConstants.cardPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.weightHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8.0,
                children: [
                  '30D',
                  '90D',
                  'All',
                ].map((key) => _buildFilterButton(key, key)).toList(),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          MeasurementChartWidget(
            chartType: 'weight',
            dateRange: _calculateDateRange(),
            unit: context.read<UnitService>().suffixFor(UnitDimension.weight),
          ),
        ],
      ),
    );
  }
}
