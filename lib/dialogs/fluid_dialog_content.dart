// lib/dialogs/fluid_dialog_content.dart - ERSETZE DIE GESAMTE DATEI

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';

/// A dialog content widget for logging fluid intake (water, coffee, etc.).
///
/// Allows users to specify name, quantity, timestamp, sugar, and caffeine content.
class FluidDialogContent extends StatefulWidget {
  final int? initialQuantity;
  final DateTime? initialTimestamp;
  final String? initialName; // <--- NEU
  final double? initialSugar; // <--- NEU
  final double? initialCaffeine; // <--- NEU

  const FluidDialogContent({
    super.key,
    this.initialQuantity,
    this.initialTimestamp,
    this.initialName, // <--- NEU
    this.initialSugar, // <--- NEU
    this.initialCaffeine, // <--- NEU
  });

  @override
  FluidDialogContentState createState() => FluidDialogContentState();
}

class FluidDialogContentState extends State<FluidDialogContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _caffeineController;
  late final TextEditingController _sugarController;
  late DateTime _selectedDateTime;

  String get nameText => _nameController.text;
  String get quantityText => _quantityController.text;
  String get caffeineText => _caffeineController.text;
  String get sugarText => _sugarController.text;
  DateTime get selectedDateTime => _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ?? 'Water',
    ); // <--- Initialisierung anpassen
    _quantityController = TextEditingController(
      text: widget.initialQuantity?.toString() ?? '',
    );
    // <--- Hinzufügen der Initialisierung für Nährstoffe
    _caffeineController = TextEditingController(
      text:
          widget.initialCaffeine?.toStringAsFixed(1).replaceAll('.0', '') ?? '',
    );
    _sugarController = TextEditingController(
      text: widget.initialSugar?.toStringAsFixed(1).replaceAll('.0', '') ?? '',
    );
    _selectedDateTime = widget.initialTimestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _caffeineController.dispose();
    _sugarController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final locale = Localizations.localeOf(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: locale,
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat.yMd(locale).format(_selectedDateTime);
    final formattedTime = DateFormat.Hm(locale).format(_selectedDateTime);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        const SizedBox(height: DesignConstants.spacingL),
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.amount_in_milliliters,
            suffixText: 'ml',
          ),
          autofocus: true,
        ),
        const SizedBox(height: DesignConstants.spacingL),
        TextField(
          controller: _sugarController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '${l10n.sugar} (g / 100ml)',
            suffixText: 'g',
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),
        TextField(
          controller: _caffeineController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.caffeinePrompt,
            suffixText: 'mg / 100ml',
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 20),
              label: Text(formattedDate, style: const TextStyle(fontSize: 16)),
              onPressed: _selectDate,
            ),
            TextButton.icon(
              icon: const Icon(Icons.access_time, size: 20),
              label: Text(formattedTime, style: const TextStyle(fontSize: 16)),
              onPressed: _selectTime,
            ),
          ],
        ),
      ],
    );
  }
}
