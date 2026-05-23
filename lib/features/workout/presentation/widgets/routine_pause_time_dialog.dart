import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';

class RoutinePauseTimeDialog extends StatefulWidget {
  final int? initialPauseSeconds;
  final Function(int?) onSave;
  final VoidCallback onCancel;

  const RoutinePauseTimeDialog({
    super.key,
    this.initialPauseSeconds,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<RoutinePauseTimeDialog> createState() => _RoutinePauseTimeDialogState();
}

class _RoutinePauseTimeDialogState extends State<RoutinePauseTimeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPauseSeconds?.toString() ?? '',
    );
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
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.pauseInSeconds,
            hintText: "z.B. 90",
            suffixText: "s",
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
                  final seconds = int.tryParse(_controller.text);
                  widget.onSave(seconds);
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
