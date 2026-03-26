// lib/widgets/editable_set_row.dart

import 'package:flutter/material.dart';
import '../models/set_log.dart';
import 'set_type_chip.dart';
import '../generated/app_localizations.dart';

/// An interactive row for editing a single workout set's weight and repetitions.
///
/// Provides text inputs for weight and reps, and a delete action.
class EditableSetRow extends StatefulWidget {
  const EditableSetRow({
    super.key,
    required this.setLog,
    required this.setIndex,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onDelete,
  });

  /// The [setLog] data being edited.
  final SetLog setLog;

  /// The [setIndex] (1-based) used for labeling.
  final int setIndex;

  /// Callback when the weight input changes.
  final ValueChanged<String> onWeightChanged;

  /// Callback when the reps input changes.
  final ValueChanged<String> onRepsChanged;

  /// Callback to request deletion of this set.
  final VoidCallback onDelete;

  @override
  State<EditableSetRow> createState() => _EditableSetRowState();
}

class _EditableSetRowState extends State<EditableSetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setLog.weightKg?.toStringAsFixed(2).replaceAll('.00', '') ??
          '',
    );
    _repsController = TextEditingController(
      text: widget.setLog.reps?.toString() ?? '',
    );

    // Melde Änderungen an den Parent-Screen
    _weightController.addListener(() {
      widget.onWeightChanged(_weightController.text);
    });
    _repsController.addListener(() {
      widget.onRepsChanged(_repsController.text);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SetTypeChip(
            setType: widget.setLog.setType,
            setIndex: widget.setIndex,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: l10n.kgLabel,
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => (value == null ||
                      value.trim().isEmpty ||
                      double.tryParse(value.replaceAll(',', '.')) == null)
                  ? "!"
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          const Text("x"),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _repsController,
              decoration: InputDecoration(
                labelText: l10n.repsLabel,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => (value == null ||
                      value.trim().isEmpty ||
                      int.tryParse(value) == null)
                  ? "!"
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: l10n.delete,
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
