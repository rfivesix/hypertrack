// lib/dialogs/log_supplement_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../models/supplement.dart';
import '../util/design_constants.dart';

/// A dialog content widget for logging supplement intake.
///
/// Specifically designed for standalone supplement logging, allowing
/// manual entry of the dose and timestamp.
class LogSupplementDialogContent extends StatefulWidget {
  final Supplement supplement;
  final double? initialDose;
  final DateTime? initialTimestamp;

  const LogSupplementDialogContent({
    super.key,
    required this.supplement,
    this.initialDose,
    this.initialTimestamp,
  });

  @override
  LogSupplementDialogContentState createState() =>
      LogSupplementDialogContentState();
}

class LogSupplementDialogContentState
    extends State<LogSupplementDialogContent> {
  late final TextEditingController _doseController;
  late DateTime _selectedDateTime;

  // Getter für den Zugriff von außen
  String get doseText => _doseController.text;
  DateTime get selectedDateTime => _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(
      text:
          widget.initialDose?.toStringAsFixed(1).replaceAll('.0', '') ??
          widget.supplement.defaultDose.toStringAsFixed(1).replaceAll('.0', ''),
    );
    _selectedDateTime = widget.initialTimestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Holen der l10n Instanz
    final formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDateTime);
    final formattedTime = DateFormat.Hm().format(_selectedDateTime);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _doseController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.doseLabel, // LOKALISIERT
            suffixText: widget.supplement.unit,
          ),
          autofocus: true,
        ),
        const SizedBox(height: DesignConstants.spacingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: _selectDate,
              child: Padding(
                padding: DesignConstants.cardMargin,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(formattedDate, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: _selectTime,
              child: Padding(
                padding: DesignConstants.cardMargin,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(formattedTime, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
