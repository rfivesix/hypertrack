import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../dialogs/log_supplement_menu.dart';
import '../generated/app_localizations.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../models/tracked_supplement.dart';
import 'create_supplement_screen.dart';
import '../util/date_util.dart';
import '../util/design_constants.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/glass_fab.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/swipe_action_background.dart';

/// A central dashboard for tracking supplement intake and progress.
///
/// Provides a date-based view of supplement logs, visualizes progress towards
/// daily goals, and allows quick logging of doses.
class SupplementHubScreen extends StatefulWidget {
  const SupplementHubScreen({super.key});
  @override
  State<SupplementHubScreen> createState() => _SupplementHubScreenState();
}

class _SupplementHubScreenState extends State<SupplementHubScreen> {
  bool _isLoading = true;
  List<TrackedSupplement> _trackedSupplements = [];
  List<SupplementLog> _todaysLogs = [];
  final Map<int, Supplement> _supplementsById = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData(_selectedDate);
  }

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

  Future<void> _loadData(DateTime date) async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final supplementsForDate = await db.getSupplementsForDate(date);
    final logsForDate = await db.getSupplementLogsForDate(date);

    final Map<int, Supplement> byId = {
      for (final s in supplementsForDate)
        if (s.id != null) s.id!: s,
    };

    final allSupplements = await db.getAllSupplements();
    for (final s in allSupplements) {
      if (s.id != null && !byId.containsKey(s.id!)) {
        byId[s.id!] = s;
      }
    }

    final Map<int, double> todaysDoses = {};
    for (final log in logsForDate) {
      todaysDoses.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    final List<TrackedSupplement> tracked = [];
    for (final s in supplementsForDate) {
      final hasLog = todaysDoses.containsKey(s.id);
      if (s.isTracked || hasLog) {
        tracked.add(
          TrackedSupplement(
            supplement: s,
            totalDosedToday: todaysDoses[s.id] ?? 0.0,
          ),
        );
      }
    }

    for (final id in todaysDoses.keys) {
      if (!tracked.any((ts) => ts.supplement.id == id)) {
        if (byId.containsKey(id)) {
          tracked.add(
            TrackedSupplement(
              supplement: byId[id]!,
              totalDosedToday: todaysDoses[id]!,
            ),
          );
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _supplementsById
        ..clear()
        ..addAll(byId);
      _trackedSupplements = tracked;
      _todaysLogs = logsForDate;
      _isLoading = false;
    });
  }

  Future<void> _logSupplement(Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showGlassBottomMenu<bool>(
      context: context,
      title: localizeSupplementName(supplement, l10n),
      contentBuilder: (ctx, close) {
        return LogSupplementDoseBody(
          supplement: supplement,
          primaryLabel: l10n.add_button,
          onCancel: close,
          onSubmit: (dose, ts) async {
            await DatabaseHelper.instance.insertSupplementLog(
              SupplementLog(
                supplementId: supplement.id!,
                dose: dose,
                unit: supplement.unit,
                timestamp: ts,
              ),
            );
            if (!ctx.mounted) return;
            close();
            Navigator.of(ctx).pop(true);
          },
        );
      },
    );

    if (result == true) {
      _loadData(_selectedDate);
    }
  }

  Future<void> _editLogEntry(SupplementLog log) async {
    final l10n = AppLocalizations.of(context)!;
    final supplement = _supplementsById[log.supplementId]!;

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
      await DatabaseHelper.instance.updateSupplementLog(updated);
      _loadData(_selectedDate);
    }
  }

  Future<void> _deleteLogEntry(int logId) async {
    // NEU: Verwendung des standardisierten Helpers
    final confirmed = await showDeleteConfirmation(context);

    if (confirmed) {
      await DatabaseHelper.instance.deleteSupplementLog(logId);
      _loadData(_selectedDate);
    }
  }

  Future<void> _deleteSupplement(Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;

    // NEU: Verwendung des Helpers mit spezifischem Text
    final confirmed = await showDeleteConfirmation(
      context,
      content: l10n.deleteSupplementConfirm,
    );

    if (confirmed) {
      await DatabaseHelper.instance.deleteSupplement(supplement.id!);
      _loadData(_selectedDate);
    }
  }

  void _navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    if (forward && newDay.isAfter(DateTime.now())) return;
    setState(() {
      _selectedDate = newDay;
    });
    _loadData(_selectedDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData(_selectedDate);
    }
  }

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

  Widget _buildProgressCard(TrackedSupplement ts) {
    final supplement = ts.supplement;
    final isLimit = supplement.dailyLimit != null;
    final target = (isLimit ? supplement.dailyLimit : supplement.dailyGoal)!;
    final overTarget = isLimit && ts.totalDosedToday > target;
    final hasTarget = target > 0;
    final rawProgress = hasTarget ? (ts.totalDosedToday / target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);
    final progressColor =
        overTarget ? Colors.red.shade400 : Colors.green.shade400;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(color: progressColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      localizeSupplementName(supplement, l10n),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ts.totalDosedToday.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} ${supplement.unit}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 14,
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

  Widget _buildLogEntry(SupplementLog log, AppLocalizations l10n) {
    final s = _supplementsById[log.supplementId];
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
          _editLogEntry(log);
          return false; // Nicht dismissen, da Edit-Dialog aufging
        } else {
          // Für Delete (EndToStart): Wir geben true zurück, damit die Animation läuft,
          // ABER wir rufen die Lösch-Logik erst in onDismissed auf.
          // ODER wir zeigen hier den Dialog. Da Dismissible sofort entfernt, ist Dialog hier besser:

          // Wir rufen unsere _deleteLogEntry Methode auf, die den Dialog zeigt.
          // Aber Dismissible erwartet ein Future<bool>.
          // Einfacherer Weg für Dismissible mit Dialog:

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
          _deleteLogEntry(log.id!);
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

  Future<void> _navigateToEditSupplement(Supplement supplement) async {
    final reloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CreateSupplementScreen(supplementToEdit: supplement),
      ),
    );
    if (reloaded == true) {
      _loadData(_selectedDate);
    }
  }

  Widget _buildLogActionCard(Supplement supplement) {
    final l10n = AppLocalizations.of(context)!;
    final isBuiltin = supplement.isBuiltin || supplement.code == 'caffeine';

    if (isBuiltin) {
      return SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(localizeSupplementName(supplement, l10n)),
          onTap: () => _logSupplement(supplement),
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
          _navigateToEditSupplement(supplement);
          return false;
        } else {
          _deleteSupplement(supplement);
          return false;
        }
      },
      child: SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(localizeSupplementName(supplement, l10n)),
          onTap: () => _logSupplement(supplement),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains the same)
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
                  onPressed: () => _navigateDay(false),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Text(
                      DateFormat.yMMMMd(locale).format(_selectedDate),
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
                  onPressed: _selectedDate.isSameDate(DateTime.now())
                      ? null
                      : () => _navigateDay(true),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadData(_selectedDate),
                    child: ListView(
                      padding: DesignConstants.cardPadding,
                      children: [
                        _buildSectionTitle(context, l10n.dailyProgressTitle),
                        if (_trackedSupplements
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
                        ..._trackedSupplements
                            .where(
                              (ts) =>
                                  ts.supplement.dailyGoal != null ||
                                  ts.supplement.dailyLimit != null,
                            )
                            .map((ts) => _buildProgressCard(ts)),
                        const SizedBox(height: DesignConstants.spacingXL),
                        _buildSectionTitle(context, l10n.logIntakeTitle),
                        ..._trackedSupplements.map(
                          (ts) => _buildLogActionCard(ts.supplement),
                        ),
                        const SizedBox(height: DesignConstants.spacingXL),
                        _buildSectionTitle(context, l10n.todaysLogTitle),
                        if (_todaysLogs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              l10n.emptySupplementLogs,
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ..._todaysLogs.map(
                            (log) => _buildLogEntry(log, l10n),
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
              builder: (context) => const CreateSupplementScreen(),
            ),
          );
          if (created == true) {
            _loadData(_selectedDate);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
