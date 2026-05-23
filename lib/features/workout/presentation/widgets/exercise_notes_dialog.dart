import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';

class ExerciseNotesDialog extends StatefulWidget {
  final String? initialNotes;
  final Function(String) onSave;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const ExerciseNotesDialog({
    super.key,
    this.initialNotes,
    required this.onSave,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  State<ExerciseNotesDialog> createState() => _ExerciseNotesDialogState();
}

class _ExerciseNotesDialogState extends State<ExerciseNotesDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: "Notizen oder Hinweise eingeben...",
            filled: true,
            fillColor: brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.initialNotes != null && widget.initialNotes!.isNotEmpty) ...[
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: "Notiz löschen",
                onPressed: widget.onDelete,
              ),
              const SizedBox(width: 8),
            ],
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
                  widget.onSave(_controller.text.trim());
                },
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
