// lib/features/supplements/presentation/supplement_track_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/supplement_repository.dart';
import 'supplements_view_model.dart';
import '../../../dialogs/log_supplement_menu.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/supplement.dart';
import '../domain/models/supplement_log.dart';
import '../domain/models/tracked_supplement.dart';
import 'create_supplement_screen.dart';
import 'manage_supplements_screen.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import '../../../util/supplement_l10n.dart';
import '../../../widgets/common/common.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/glass_progress_bar.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/swipe_action_background.dart';

DateTime resolveSupplementTrackLogTimestamp({
  required DateTime selectedDate,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  if (selectedDate.isSameDate(currentTime)) {
    return currentTime;
  }

  return DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    currentTime.hour,
    currentTime.minute,
  );
}

/// A screen for tracking daily supplement intake.
class SupplementTrackScreen extends StatelessWidget {
  /// The initial date to be displayed in the tracker.
  final DateTime? initialDate;
  final SupplementRepository? repository;

  const SupplementTrackScreen({super.key, this.initialDate, this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupplementsViewModel(repository: repository)
        ..setSelectedDate((initialDate ?? DateTime.now()).dateOnly),
      child: const _SupplementTrackScreenContent(),
    );
  }
}

class _SupplementTrackScreenContent extends StatefulWidget {
  const _SupplementTrackScreenContent();

  @override
  State<_SupplementTrackScreenContent> createState() => _SupplementTrackScreenContentState();
}

class _SupplementTrackScreenContentState extends State<_SupplementTrackScreenContent> {
  Future<void> _logSupplement(BuildContext context, SupplementsViewModel model, Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showGlassBottomMenu<(double, DateTime)?>(
      context: context,
      title: localizeSupplementName(supplement, l10n),
      contentBuilder: (ctx, close) {
        return LogSupplementDoseBody(
          supplement: supplement,
          primaryLabel: l10n.add_button,
          initialTimestamp: resolveSupplementTrackLogTimestamp(
            selectedDate: model.selectedDate,
          ),
          onCancel: close,
          onSubmit: (dose, ts) {
            close();
            Navigator.of(ctx).pop((dose, ts));
          },
        );
      },
    );

    if (result == null) return;

    await model.logSupplementDose(supplement, result.$1, result.$2);
  }

  Future<void> _editLogEntry(BuildContext context, SupplementsViewModel model, SupplementLog log) async {
    final l10n = AppLocalizations.of(context)!;
    final supplement = model.supplementsById[log.supplementId]!;

    final result = await showGlassBottomMenu<(double, DateTime)?>(
      context: context,
      title: localizeSupplementName(supplement, l10n),
      contentBuilder: (ctx, close) {
        return LogSupplementDoseBody(
          supplement: supplement,
          initialDose: log.dose,
          initialTimestamp: log.timestamp,
          primaryLabel: l10n.save,
          onCancel: close,
          onSubmit: (dose, ts) {
            close();
            Navigator.of(ctx).pop((dose, ts));
          },
        );
      },
    );

    if (result == null) return;

    final updated = SupplementLog(
      id: log.id,
      supplementId: supplement.id!,
      dose: result.$1,
      unit: supplement.unit,
      timestamp: result.$2,
    );
    await model.updateSupplementLog(updated);
  }

  Future<void> _deleteLogEntry(SupplementsViewModel model, SupplementLog log) async {
    await model.deleteSupplementLog(log.id!);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.deleted),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            final restored = SupplementLog(
              supplementId: log.supplementId,
              dose: log.dose,
              unit: log.unit,
              timestamp: log.timestamp,
            );
            await model.insertSupplementLogRaw(restored);
          },
        ),
      ),
    );
  }

  Widget _progressCard(BuildContext context, TrackedSupplement ts) {
    final s = ts.supplement;
    final isLimit = s.dailyLimit != null;
    final target = (isLimit ? s.dailyLimit : s.dailyGoal) ?? 0.0;
    final overTarget = isLimit && ts.totalDosedToday > target;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final color = overTarget
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GlassProgressBar(
        label: localizeSupplementName(s, l10n),
        unit: s.unit,
        value: ts.totalDosedToday,
        target: target,
        color: color,
      ),
    );
  }

  Widget _logActionTile(BuildContext context, SupplementsViewModel model, Supplement s) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.add_circle_outline),
        title: Text(localizeSupplementName(s, l10n)),
        onTap: () => _logSupplement(context, model, s),
      ),
    );
  }

  Widget _logEntryTile(BuildContext context, SupplementsViewModel model, SupplementLog log, AppLocalizations l10n) {
    final s = model.supplementsById[log.supplementId];
    final titleText = (s == null) ? 'Unknown' : localizeSupplementName(s, l10n);

    return Dismissible(
      key: Key('log_${log.id}'),
      direction: DismissDirection.horizontal,
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editLogEntry(context, model, log);
          return false;
        }
        return await showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) _deleteLogEntry(model, log);
      },
      child: SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.grey),
          title: Text(titleText),
          subtitle: Text(DateFormat.Hm().format(log.timestamp)),
          trailing: Text('${log.dose.toStringAsFixed(1)} ${log.unit}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SupplementsViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.supplementTrackerTitle,
        actions: [
          IconButton(
            tooltip: l10n.manageSupplementsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ManageSupplementsScreen(repository: model.repository),
                ),
              );
              if (changed == true) model.loadData();
            },
          ),
        ],
      ),
      body: model.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => model.loadData(),
              child: ListView(
                padding: DesignConstants.cardPadding.copyWith(
                  top: DesignConstants.cardPadding.top + topPadding,
                ),
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => model.navigateDay(false),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: model.selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                model.setSelectedDate(picked);
                              }
                            },
                            child: Text(
                              DateFormat.yMMMMd(locale).format(model.selectedDate),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: model.selectedDate.isSameDate(DateTime.now())
                              ? null
                              : () => model.navigateDay(true),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),

                  // Progress section
                  AppSectionHeader(title: l10n.dailyProgressTitle),
                  if (model.tracked
                      .where(
                        (t) =>
                            t.supplement.dailyGoal != null ||
                            t.supplement.dailyLimit != null,
                      )
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        l10n.emptySupplementGoals,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ...model.tracked
                      .where(
                        (t) =>
                            t.supplement.dailyGoal != null ||
                            t.supplement.dailyLimit != null,
                      )
                      .map((ts) => _progressCard(context, ts)),

                  const SizedBox(height: DesignConstants.spacingXL),

                  // Log intake
                  AppSectionHeader(title: l10n.logIntakeTitle),
                  ...model.tracked.map((t) => _logActionTile(context, model, t.supplement)),

                  const SizedBox(height: DesignConstants.spacingXL),

                  // Today's logs
                  AppSectionHeader(title: l10n.todaysLogTitle),
                  if (model.todaysLogs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        l10n.emptySupplementLogs,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...model.todaysLogs.map((log) => _logEntryTile(context, model, log, l10n)),
                ],
              ),
            ),
      floatingActionButton: GlassFab(
        label: l10n.createSupplementTitle,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
               builder: (context) => CreateSupplementScreen(repository: model.repository),
            ),
          );
          if (created == true) {
            model.loadData();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
