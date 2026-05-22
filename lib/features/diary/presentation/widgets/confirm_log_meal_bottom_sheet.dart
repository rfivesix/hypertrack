import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/date_util.dart';
import '../../domain/models/food_item.dart';

class ConfirmLogMealBottomSheet extends StatefulWidget {
  final String mealName;
  final List<Map<String, dynamic>> rawItems;
  final Map<String, FoodItem> products;
  final DateTime initialDate;
  final String initialMealType;
  final VoidCallback onClose;
  final void Function(
    DateTime date,
    String mealType,
    Map<String, int> quantities,
  ) onSave;

  const ConfirmLogMealBottomSheet({
    super.key,
    required this.mealName,
    required this.rawItems,
    required this.products,
    required this.initialDate,
    required this.initialMealType,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<ConfirmLogMealBottomSheet> createState() =>
      _ConfirmLogMealBottomSheetState();
}

class _ConfirmLogMealBottomSheetState extends State<ConfirmLogMealBottomSheet> {
  late DateTime _selectedDate;
  late String _selectedMealType;
  late Map<String, TextEditingController> _qtyCtrls;

  final List<String> _internalTypes = const [
    'mealtypeBreakfast',
    'mealtypeLunch',
    'mealtypeDinner',
    'mealtypeSnack',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize date and meal type states
    _selectedDate = widget.initialDate.withCurrentTime;
    _selectedMealType = widget.initialMealType;
    if (!_internalTypes.contains(_selectedMealType)) {
      _selectedMealType = _internalTypes.first;
    }

    // Initialize text controllers for all ingredient quantities
    _qtyCtrls = {
      for (final it in widget.rawItems)
        (it['barcode'] as String): TextEditingController(
          text: '${it['quantity_in_grams']}',
        ),
    };
  }

  @override
  void dispose() {
    for (final ctrl in _qtyCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat.yMd(locale).format(_selectedDate);
    final formattedTime = DateFormat.Hm(locale).format(_selectedDate);

    final Map<String, String> mealTypeLabel = {
      'mealtypeBreakfast': l10n.mealtypeBreakfast,
      'mealtypeLunch': l10n.mealtypeLunch,
      'mealtypeDinner': l10n.mealtypeDinner,
      'mealtypeSnack': l10n.mealtypeSnack,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.mealName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Date & time selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(formattedDate),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      _selectedDate.hour,
                      _selectedDate.minute,
                    );
                  });
                }
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(formattedTime),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedDate),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      picked.hour,
                      picked.minute,
                    );
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          initialValue: _selectedMealType,
          decoration: InputDecoration(
            labelText: l10n.mealTypeLabel,
            border: const OutlineInputBorder(),
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
          items: _internalTypes
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Text(mealTypeLabel[key] ?? key),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedMealType = v;
              });
            }
          },
        ),

        const SizedBox(height: 12),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.rawItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final it = widget.rawItems[i];
              final bc = it['barcode'] as String;
              final fi = widget.products[bc];
              final displayName =
                  (fi?.name.isNotEmpty ?? false) ? fi!.name : bc;
              final unit = (fi?.isLiquid == true)
                  ? l10n.unit_milliliters
                  : l10n.unit_grams;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Icon(Icons.lunch_dining, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrls[bc],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: displayName,
                        suffixText: unit,
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  widget.onClose();
                  Navigator.of(context).pop(false);
                },
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  // Build final quantities map to hand over
                  final Map<String, int> finalQuantities = {};
                  for (final it in widget.rawItems) {
                    final bc = it['barcode'] as String;
                    final ctrl = _qtyCtrls[bc]!;
                    final qty = int.tryParse(ctrl.text.trim()) ??
                        (it['quantity_in_grams'] as int);
                    finalQuantities[bc] = qty;
                  }

                  widget.onSave(_selectedDate, _selectedMealType, finalQuantities);
                  widget.onClose();
                  Navigator.of(context).pop(true);
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
