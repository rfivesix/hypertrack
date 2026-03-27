// lib/screens/manage_supplements_screen.dart
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/supplement.dart';
import 'create_supplement_screen.dart';
import '../util/design_constants.dart';
import '../util/supplement_l10n.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/glass_fab.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/swipe_action_background.dart';

/// A screen for managing the catalog of available supplements.
///
/// Users can view, edit, and delete custom supplements, while built-in
/// supplements remain protected from deletion.
class ManageSupplementsScreen extends StatefulWidget {
  const ManageSupplementsScreen({super.key});

  @override
  State<ManageSupplementsScreen> createState() =>
      _ManageSupplementsScreenState();
}

class _ManageSupplementsScreenState extends State<ManageSupplementsScreen> {
  bool _isLoading = true;
  List<Supplement> _supplements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllSupplements();
    if (!mounted) return;
    setState(() {
      _supplements = list;
      _isLoading = false;
    });
  }

  Future<void> _navigateToEdit(Supplement s) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateSupplementScreen(supplementToEdit: s),
      ),
    );
    if (changed == true) _load();
  }

  // In lib/screens/manage_supplements_screen.dart

  Future<void> _delete(Supplement s) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await showGlassBottomMenu<bool>(
            context: context,
            title: l10n.deleteConfirmTitle,
            contentBuilder: (ctx, close) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      l10n.deleteSupplementConfirm,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
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
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            close();
                            Navigator.of(ctx).pop(true);
                          },
                          child: Text(l10n.delete),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!ok) return;

      await DatabaseHelper.instance.deleteSupplement(s.id!);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleted)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.operationNotAllowed)));
    }
  }

  Widget _tile(Supplement s, AppLocalizations l10n) {
    final isBuiltin = s.isBuiltin || s.code == 'caffeine';
    final title = localizeSupplementName(s, l10n);

    final content = SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.set_meal_outlined),
        title: Text(title),
        subtitle: (s.dailyGoal != null || s.dailyLimit != null)
            ? Text(
                [
                  if (s.dailyGoal != null)
                    '${l10n.dailyGoalLabel}: ${s.dailyGoal} ${s.unit}',
                  if (s.dailyLimit != null)
                    '${l10n.dailyLimitLabel}: ${s.dailyLimit} ${s.unit}',
                ].join('  •  '),
              )
            : null,
        trailing: isBuiltin ? null : const Icon(Icons.chevron_right),
        onTap: () => _navigateToEdit(s),
      ),
    );

    if (isBuiltin) return content;

    return Dismissible(
      key: Key('supp_${s.id}'),
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
          _navigateToEdit(s);
          return false;
        } else {
          _delete(s);
          return false;
        }
      },
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.manageSupplementsTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: DesignConstants.cardPadding.copyWith(
                  top: DesignConstants.cardPadding.top + topPadding,
                ),
                children: [
                  if (_supplements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        l10n.emptySupplements,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._supplements.map((s) => _tile(s, l10n)),
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
          if (created == true) _load();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
