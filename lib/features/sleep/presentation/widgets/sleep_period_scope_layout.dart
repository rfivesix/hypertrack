import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/common.dart';
import '../../../../widgets/common/global_app_bar.dart';
import '../../../../widgets/common/algorithm_info_sheet.dart';

enum SleepPeriodScope { day, week, month }

class SleepPeriodScopeLayout extends StatelessWidget {
  const SleepPeriodScopeLayout({
    super.key,
    required this.appBarTitle,
    required this.selectedScope,
    required this.anchorDate,
    required this.onScopeChanged,
    required this.onShiftPeriod,
    required this.child,
  });

  final String appBarTitle;
  final SleepPeriodScope selectedScope;
  final DateTime anchorDate;
  final ValueChanged<SleepPeriodScope> onScopeChanged;
  final ValueChanged<int> onShiftPeriod;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final localeCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: appBarTitle,
        actions: [
          AlgorithmInfoButton(
            title: l10n.infoSleepTitle,
            explanation: l10n.infoSleepExplanation,
            keyPoints: l10n.infoSleepKeyPoints.split('\n'),
            technicalTitle: l10n.infoSleepTechnicalTitle,
            technicalExplanation: l10n.infoSleepTechnicalExplanation,
            markdownAssetPath: 'documentation/features/sleep_scoring_engine.md',
            iconColor: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding + 16,
          left: 0,
          right: 0,
        ),
        children: [
          TimeRangeFilter(
            ranges: [
              l10n.sleepScopeDay,
              l10n.sleepScopeWeek,
              l10n.sleepScopeMonth,
            ],
            selectedIndex: selectedScope.index,
            onSelected: (index) =>
                onScopeChanged(SleepPeriodScope.values[index]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.cardPaddingInternal,
              vertical: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  key: const Key('sleep-period-prev'),
                  onPressed: () => onShiftPeriod(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _periodLabel(localeCode),
                    key: const Key('sleep-period-label'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  key: const Key('sleep-period-next'),
                  onPressed: () => onShiftPeriod(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.cardPaddingInternal,
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  String _periodLabel(String localeCode) {
    final normalized = DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day,
    );
    switch (selectedScope) {
      case SleepPeriodScope.day:
        return DateFormat.yMMMd(localeCode).format(normalized);
      case SleepPeriodScope.week:
        final start = normalized.subtract(
          Duration(days: normalized.weekday - DateTime.monday),
        );
        final end = start.add(const Duration(days: 6));
        return '${DateFormat.MMMd(localeCode).format(start)} - ${DateFormat.MMMd(localeCode).format(end)}';
      case SleepPeriodScope.month:
        return DateFormat.yMMMM(
          localeCode,
        ).format(DateTime(normalized.year, normalized.month, 1));
    }
  }
}
