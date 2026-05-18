// lib/features/supplements/presentation/supplement_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/supplement_repository.dart';
import 'supplements_view_model.dart';
import 'dialogs/log_supplement_menu.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/supplement.dart';
import '../domain/models/supplement_log.dart';
import '../domain/models/tracked_supplement.dart';
import 'create_supplement_screen.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/glass_progress_bar.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/swipe_action_background.dart';

/// A central dashboard for tracking supplement intake and progress.
class SupplementHubScreen extends StatelessWidget {
  final SupplementRepository? repository;

  const SupplementHubScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupplementsViewModel(repository: repository)..setSelectedDate(DateTime.now()),
      child: const _SupplementHubScreenContent(),
    );
  }
}

class _SupplementHubScreenContent extends StatefulWidget {
  const _SupplementHubScreenContent();

  @override
  State<_SupplementHubScreenContent> createState() => _SupplementHubScreenContentState();
}

class _SupplementHubScreenContentState extends State<_SupplementHubScreenContent> {
  String localizeSupplementName(Supplement s, AppLocalizations l10n) {
    switch (s.code) {
      case 'caffeine':
        return l10n.supplement_caffeine;
      case 'creatine_monohydrate':
        return l10n.supplement_creatine_monohydrate;
      default:
        return s.name;
    }
  }

  Future<void> _logSupplement(BuildContext context, SupplementsViewModel model, Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showGlassBottomMenu<bool>(
      context: context,
      title: localizeSupplementName(supplement, l10n),
      contentBuilder: (ctx, close) {
        return LogSupplementDoseBody(
          supplement: supplement,
          initialTimestamp: model.selectedDate.withCurrentTime,
          primaryLabel: l10n.add_button,
          onCancel: close,
          onSubmit: (dose, ts) async {
            await model.logSupplementDose(supplement, dose, ts);
            if (!ctx.mounted) return;
            close();
            Navigator.of(ctx).pop(true);
          },
        );
      },
    );

    if (result == true) {
      model.loadData();
    }
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

    if (result != null) {
      final updated = SupplementLog(
        id: log.id,
        supplementId: supplement.id!,
        dose: result.$1,
        unit: supplement.unit,
        timestamp: result.$2,
      );
      await model.updateSupplementLog(updated);
    }
  }

  Future<void> _deleteLogEntry(BuildContext context, SupplementsViewModel model, int logId) async {
    final confirmed = await showDeleteConfirmation(context);

    if (confirmed) {
      await model.deleteSupplementLog(logId);
    }
  }

  Future<void> _deleteSupplement(BuildContext context, SupplementsViewModel model, Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDeleteConfirmation(
      context,
      content: l10n.deleteSupplementConfirm,
    );

    if (confirmed) {
      await model.deleteSupplement(supplement.id!);
    }
  }

  Widget _buildProgressCard(BuildContext context, TrackedSupplement ts) {
    final supplement = ts.supplement;
    final isLimit = supplement.dailyLimit != null;
    final target = (isLimit ? supplement.dailyLimit : supplement.dailyGoal)!;
    final overTarget = isLimit && ts.totalDosedToday > target;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final progressColor = overTarget
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GlassProgressBar(
        label: localizeSupplementName(supplement, l10n),
        unit: supplement.unit,
        value: ts.totalDosedToday,
        target: target,
        color: progressColor,
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, SupplementsViewModel model, SupplementLog log, AppLocalizations l10n) {
    final s = model.supplementsById[log.supplementId];
    final titleText = (s != null) ? localizeSupplementName(s, l10n) : 'Unknown';

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
        } else {
          final l10n = AppLocalizations.of(context)!;
          final confirmed = await showGlassBottomMenu<bool>(
            context: context,
            title: l10n.deleteConfirmTitle,
            contentBuilder: (ctx, close) {
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        close();
                        Navigator.of(ctx).pop(false);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        close();
                        Navigator.of(ctx).pop(true);
                      },
                      child: Text(l10n.delete),
                    ),
                  ),
                ],
              );
            },
          );
          return confirmed ?? false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteLogEntry(context, model, log.id!);
        }
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

  Future<void> _navigateToEditSupplement(BuildContext context, SupplementsViewModel model, Supplement supplement) async {
    final reloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CreateSupplementScreen(supplementToEdit: supplement, repository: model.repository),
      ),
    );
    if (reloaded == true) {
      model.loadData();
    }
  }

  Widget _buildLogActionCard(BuildContext context, SupplementsViewModel model, Supplement supplement) {
    final l10n = AppLocalizations.of(context)!;
    final isBuiltin = supplement.isBuiltin || supplement.code == 'caffeine';

    if (isBuiltin) {
      return SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(localizeSupplementName(supplement, l10n)),
          onTap: () => _logSupplement(context, model, supplement),
        ),
      );
    }

    return Dismissible(
      key: Key('supplement_${supplement.id}'),
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
          _navigateToEditSupplement(context, model, supplement);
          return false;
        } else {
          _deleteSupplement(context, model, supplement);
          return false;
        }
      },
      child: SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(localizeSupplementName(supplement, l10n)),
          onTap: () => _logSupplement(context, model, supplement),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SupplementsViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final textTheme = Theme.of(context).textTheme;

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.supplementTrackerTitle),
      body: Column(
        children: [
          Padding(
            padding: DesignConstants.cardPadding.copyWith(
              top: DesignConstants.cardPadding.top + topPadding,
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
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
          Expanded(
            child: model.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => model.loadData(),
                    child: ListView(
                      padding: DesignConstants.cardPadding,
                      children: [
                        AppSectionHeader(title: l10n.dailyProgressTitle),
                        if (model.tracked
                            .where(
                              (ts) =>
                                  ts.supplement.dailyGoal != null ||
                                  ts.supplement.dailyLimit != null,
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
                              (ts) =>
                                  ts.supplement.dailyGoal != null ||
                                  ts.supplement.dailyLimit != null,
                            )
                            .map((ts) => _buildProgressCard(context, ts)),
                        const SizedBox(height: DesignConstants.spacingXL),
                        AppSectionHeader(title: l10n.logIntakeTitle),
                        ...model.tracked.map(
                          (ts) => _buildLogActionCard(context, model, ts.supplement),
                        ),
                        const SizedBox(height: DesignConstants.spacingXL),
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
                          ...model.todaysLogs.map(
                            (log) => _buildLogEntry(context, model, log, l10n),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
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
