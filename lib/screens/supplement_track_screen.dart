// lib/screens/supplement_track_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../dialogs/log_supplement_menu.dart';
import '../generated/app_localizations.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../models/tracked_supplement.dart';
import 'create_supplement_screen.dart';
import 'manage_supplements_screen.dart';
import '../util/date_util.dart';
import '../util/design_constants.dart';
import '../util/supplement_l10n.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/glass_fab.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/swipe_action_background.dart';

/// A screen for tracking daily supplement intake.
///
/// Similar to [SupplementHubScreen], it focuses on logging and monitoring
/// supplement consumption on a per-day basis with navigation between days.
class SupplementTrackScreen extends StatefulWidget {
  /// The initial date to be displayed in the tracker.
  final DateTime? initialDate;

  const SupplementTrackScreen({super.key, this.initialDate});

  @override
  State<SupplementTrackScreen> createState() => _SupplementTrackScreenState();
}

class _SupplementTrackScreenState extends State<SupplementTrackScreen> {
  bool _isLoading = true;
  late DateTime _selectedDate; // Spät initialisiert

  final Map<int, Supplement> _supplementsById = {};
  List<TrackedSupplement> _tracked = const [];
  List<SupplementLog> _todaysLogs = const [];

  @override
  void initState() {
    super.initState();
    // Fix #65: Starte mit dem übergebenen Datum oder Heute
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadData(_selectedDate);
  }

  Future<void> _loadData(DateTime day) async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;

    final supplementsForDate = await db.getSupplementsForDate(day);
    final logs = await db.getSupplementLogsForDate(day);

    final byId = <int, Supplement>{
      for (final s in supplementsForDate)
        if (s.id != null) s.id!: s,
    };

    final allSupplements = await db.getAllSupplements();
    for (final s in allSupplements) {
      if (s.id != null && !byId.containsKey(s.id!)) {
        byId[s.id!] = s;
      }
    }

    final doses = <int, double>{};
    for (final log in logs) {
      doses.update(
        log.supplementId,
        (v) => v + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    final List<TrackedSupplement> tracked = [];
    for (final s in supplementsForDate) {
      final hasLog = doses.containsKey(s.id);
      if (s.isTracked || hasLog) {
        tracked.add(
          TrackedSupplement(supplement: s, totalDosedToday: doses[s.id] ?? 0.0),
        );
      }
    }

    for (final id in doses.keys) {
      if (!tracked.any((ts) => ts.supplement.id == id)) {
        if (byId.containsKey(id)) {
          tracked.add(
            TrackedSupplement(
              supplement: byId[id]!,
              totalDosedToday: doses[id]!,
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
      _tracked = tracked;
      _todaysLogs = logs;
      _isLoading = false;
    });
  }

  void _navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    if (forward && newDay.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = newDay);
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
      setState(() => _selectedDate = picked);
      _loadData(_selectedDate);
    }
  }

  Future<void> _logSupplement(Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showGlassBottomMenu<(double, DateTime)?>(
      context: context,
      title: localizeSupplementName(supplement, l10n),
      contentBuilder: (ctx, close) {
        return LogSupplementDoseBody(
          supplement: supplement,
          primaryLabel: l10n.add_button,
          initialTimestamp: _selectedDate, // Fix #66: Datum übergeben
          onCancel: close,
          onSubmit: (dose, ts) {
            close();
            Navigator.of(ctx).pop((dose, ts));
          },
        );
      },
    );

    if (result == null) return;

    final log = SupplementLog(
      supplementId: supplement.id!,
      dose: result.$1,
      unit: supplement.unit,
      timestamp: result.$2,
    );
    await DatabaseHelper.instance.insertSupplementLog(log);
    _loadData(_selectedDate);
  }

  // In lib/screens/supplement_track_screen.dart

  Future<void> _editLogEntry(SupplementLog log) async {
    final l10n = AppLocalizations.of(context)!;
    final supplement = _supplementsById[log.supplementId]!;

    // KORREKTUR: showGlassBottomMenu statt showDialog
    // Wir nutzen den wiederverwendbaren LogSupplementDoseBody
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
    await DatabaseHelper.instance.updateSupplementLog(updated);
    _loadData(_selectedDate);
  }

  Future<void> _deleteLogEntry(int id) async {
    final deleted = _todaysLogs.firstWhere((l) => l.id == id);

    await DatabaseHelper.instance.deleteSupplementLog(id);
    await _loadData(_selectedDate);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.deleted),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            final restored = SupplementLog(
              supplementId: deleted.supplementId,
              dose: deleted.dose,
              unit: deleted.unit,
              timestamp: deleted.timestamp,
            );
            await DatabaseHelper.instance.insertSupplementLog(restored);
            _loadData(_selectedDate);
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
        ),
      );

  Widget _progressCard(TrackedSupplement ts) {
    final s = ts.supplement;
    final isLimit = s.dailyLimit != null;
    final target = (isLimit ? s.dailyLimit : s.dailyGoal) ?? 0.0;
    final overTarget = isLimit && ts.totalDosedToday > target;
    final hasTarget = target > 0;
    final progress =
        hasTarget ? (ts.totalDosedToday / target).clamp(0.0, 1.0) : 0.0;
    final color = overTarget ? Colors.red.shade400 : Colors.green.shade400;
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
                child: Container(color: color),
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
                      localizeSupplementName(s, l10n),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasTarget
                        ? '${ts.totalDosedToday.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} ${s.unit}'
                        : '${ts.totalDosedToday.toStringAsFixed(1)} ${s.unit}',
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

  Widget _logActionTile(Supplement s) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.add_circle_outline),
        title: Text(localizeSupplementName(s, l10n)),
        onTap: () => _logSupplement(s),
      ),
    );
  }

  Widget _logEntryTile(SupplementLog log, AppLocalizations l10n) {
    final s = _supplementsById[log.supplementId];
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
          _editLogEntry(log);
          return false;
        }
        // KORREKTUR: Neuer Glas-Dialog statt AlertDialog
        return await showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) _deleteLogEntry(log.id!);
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
                  builder: (_) => const ManageSupplementsScreen(),
                ),
              );
              if (changed == true) _loadData(_selectedDate);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(_selectedDate),
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
                          onPressed: () => _navigateDay(false),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: Text(
                              DateFormat.yMMMMd(locale).format(_selectedDate),
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
                  const SizedBox(height: DesignConstants.spacingL),

                  // Progress section
                  _sectionTitle(l10n.dailyProgressTitle),
                  if (_tracked
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
                  ..._tracked
                      .where(
                        (t) =>
                            t.supplement.dailyGoal != null ||
                            t.supplement.dailyLimit != null,
                      )
                      .map(_progressCard),

                  const SizedBox(height: DesignConstants.spacingXL),

                  // Log intake
                  _sectionTitle(l10n.logIntakeTitle),
                  ..._tracked.map((t) => _logActionTile(t.supplement)),

                  const SizedBox(height: DesignConstants.spacingXL),

                  // Today's logs
                  _sectionTitle(l10n.todaysLogTitle),
                  if (_todaysLogs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        l10n.emptySupplementLogs,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._todaysLogs.map((log) => _logEntryTile(log, l10n)),
                ],
              ),
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
