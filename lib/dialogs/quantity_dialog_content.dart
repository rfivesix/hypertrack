// lib/dialogs/quantity_dialog_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../models/food_item.dart';
import '../util/design_constants.dart';

/// A dialog content widget for logging food and liquid quantities.
///
/// Provides fields for quantity (grams or milliliters), meal type,
/// and optional nutrient overrides for liquids.
class QuantityDialogContent extends StatefulWidget {
  final FoodItem item;
  final int? initialQuantity;
  final DateTime? initialTimestamp;
  final String? initialMealType;

  const QuantityDialogContent({
    super.key,
    required this.item,
    this.initialQuantity,
    this.initialTimestamp,
    this.initialMealType,
  });

  @override
  QuantityDialogContentState createState() => QuantityDialogContentState();
}

class QuantityDialogContentState extends State<QuantityDialogContent> {
  late final TextEditingController _quantityController;
  late final TextEditingController _caffeineController;
  late final TextEditingController _sugarController;
  late DateTime _selectedDateTime;
  final List<String> _mealTypes = [
    "mealtypeBreakfast",
    "mealtypeLunch",
    "mealtypeDinner",
    "mealtypeSnack",
  ];
  late String _selectedMealType;
  late bool _isLiquid;

  // Public Getters
  String get quantityText => _quantityController.text;
  String get caffeineText => _caffeineController.text;
  String get sugarText => _sugarController.text;
  DateTime get selectedDateTime => _selectedDateTime;
  String get selectedMealType => _selectedMealType;
  bool get isLiquid => _isLiquid;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.initialQuantity?.toString() ?? '100',
    );
    _sugarController = TextEditingController(
      text: widget.item.sugar?.toStringAsFixed(1).replaceAll('.0', '') ?? '',
    );
    _caffeineController = TextEditingController(
      text:
          widget.item.caffeineMgPer100ml
              ?.toStringAsFixed(1)
              .replaceAll('.0', '') ??
          '',
    );
    _selectedDateTime = widget.initialTimestamp ?? DateTime.now();
    _selectedMealType = widget.initialMealType ?? "mealtypeSnack";
    _isLiquid = widget.item.isLiquid ?? false;
  }

  @override
  void dispose() {
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
    final unit = _isLiquid ? 'ml' : 'g';

    String getLocalizedMealName(String key) {
      switch (key) {
        case "mealtypeBreakfast":
          return l10n.mealtypeBreakfast;
        case "mealtypeLunch":
          return l10n.mealtypeLunch;
        case "mealtypeDinner":
          return l10n.mealtypeDinner;
        case "mealtypeSnack":
          return l10n.mealtypeSnack;
        default:
          return "Snack";
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _isLiquid
                ? l10n.amount_in_milliliters
                : l10n.amount_in_grams,
            suffixText: unit,
          ),
          autofocus: true,
        ),
        const SizedBox(height: DesignConstants.spacingL),
        DropdownButtonFormField<String>(
          initialValue: _selectedMealType,
          decoration: InputDecoration(labelText: l10n.meal_label),
          items: _mealTypes.map((String key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(getLocalizedMealName(key)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) setState(() => _selectedMealType = newValue);
          },
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
        const Divider(height: 24),
        SwitchListTile(
          title: Text(l10n.add_to_water_intake),
          value: _isLiquid,
          onChanged: (bool value) => setState(() => _isLiquid = value),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isLiquid) ...[
          const SizedBox(height: DesignConstants.spacingS),
          TextFormField(
            controller: _sugarController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${l10n.sugar} (g / 100ml)',
              suffixText: 'g',
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          TextFormField(
            controller: _caffeineController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.caffeinePrompt,
              suffixText: 'mg / 100ml',
            ),
          ),
        ],
      ],
    );
  }
}
