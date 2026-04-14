// lib/dialogs/log_supplement_menu.dart
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import 'log_supplement_dialog_content.dart';
import '../generated/app_localizations.dart';
import '../models/supplement.dart';
import '../util/supplement_l10n.dart';

/// Ein Menü, das eine Liste von Supplements zur Auswahl anzeigt.
/// A selection menu for choosing a supplement to log.
///
/// Displays a list of all available supplements from the database.
class LogSupplementMenu extends StatefulWidget {
  const LogSupplementMenu({super.key, required this.close});

  final VoidCallback close;

  @override
  State<LogSupplementMenu> createState() => _LogSupplementMenuState();
}

class _LogSupplementMenuState extends State<LogSupplementMenu> {
  List<Supplement> _supplements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplements();
  }

  Future<void> _loadSupplements() async {
    final supplements = await DatabaseHelper.instance.getAllSupplements();
    if (mounted) {
      setState(() {
        _supplements = supplements;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_supplements.isEmpty) {
      return Center(child: Text(l10n.emptySupplements));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._supplements.map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Material(
              color: Colors.white.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.06
                    : 0.08,
              ),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).pop(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medication_outlined),
                      const SizedBox(width: 12),
                      Expanded(child: Text(localizeSupplementName(s, l10n))),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.close,
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ein wiederverwendbares Widget für die Eingabe von Dosis und Zeit eines Supplements.
class LogSupplementDoseBody extends StatefulWidget {
  final Supplement supplement;
  final double? initialDose;
  final DateTime? initialTimestamp;
  final String primaryLabel;
  final VoidCallback onCancel;
  final void Function(double dose, DateTime timestamp) onSubmit;

  const LogSupplementDoseBody({
    super.key,
    required this.supplement,
    this.initialDose,
    this.initialTimestamp,
    required this.primaryLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<LogSupplementDoseBody> createState() => _LogSupplementDoseBodyState();
}

class _LogSupplementDoseBodyState extends State<LogSupplementDoseBody> {
  final _key = GlobalKey<LogSupplementDialogContentState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogSupplementDialogContent(
          key: _key,
          supplement: widget.supplement,
          initialDose: widget.initialDose,
          initialTimestamp: widget.initialTimestamp,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final st = _key.currentState;
                  if (st == null) return;
                  final dose = double.tryParse(
                    st.doseText.replaceAll(',', '.'),
                  );
                  if (dose == null || dose <= 0) return;
                  widget.onSubmit(dose, st.selectedDateTime);
                },
                child: Text(widget.primaryLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
