import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/global_app_bar.dart';

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
      appBar: GlobalAppBar(title: appBarTitle),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding + 16,
        ),
        children: [
          SegmentedButton<SleepPeriodScope>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: SleepPeriodScope.day,
                label: Text(l10n.sleepScopeDay),
              ),
              ButtonSegment(
                value: SleepPeriodScope.week,
                label: Text(l10n.sleepScopeWeek),
              ),
              ButtonSegment(
                value: SleepPeriodScope.month,
                label: Text(l10n.sleepScopeMonth),
              ),
            ],
            selected: {selectedScope},
            onSelectionChanged: (selection) => onScopeChanged(selection.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
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
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
          child,
        ],
      ),
    );
  }

  String _periodLabel(String localeCode) {
    final normalized = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
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
        return DateFormat.yMMMM(localeCode).format(
          DateTime(normalized.year, normalized.month, 1),
        );
    }
  }
}
