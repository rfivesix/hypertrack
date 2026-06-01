import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/routine_exercise.dart';
import '../../domain/models/set_template.dart';
import 'set_type_chip.dart';

class RoutineSetRowWidget extends StatelessWidget {
  final int setIndex;
  final int rowIndex;
  final RoutineExercise routineExercise;
  final SetTemplate template;
  final int listIndex;
  final bool isCardio;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController rirController;
  final VoidCallback onShowSetTypePicker;
  final VoidCallback onRemoveSet;

  const RoutineSetRowWidget({
    super.key,
    required this.setIndex,
    required this.rowIndex,
    required this.routineExercise,
    required this.template,
    required this.listIndex,
    required this.isCardio,
    required this.repsController,
    required this.weightController,
    required this.rirController,
    required this.onShowSetTypePicker,
    required this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;

    final Color rowColor;
    if (isColoredRow) {
      rowColor = isLightMode
          ? Colors.grey.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.05);
    } else {
      rowColor = Colors.transparent;
    }

    return Container(
      color: rowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              flex: isCardio ? 2 : 2,
              child: Center(
                child: SetTypeChip(
                  setType: template.setType,
                  setIndex: (template.setType == 'warmup') ? null : setIndex,
                  onTap: onShowSetTypePicker,
                ),
              ),
            ),
            if (isCardio) ...[
              // CARDIO FIELDS
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: weightController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: repsController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: rirController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
            ] else ...[
              // STRENGTH FIELDS
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: weightController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: context
                        .read<UnitService>()
                        .suffixFor(UnitDimension.weight),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: repsController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: l10n.set_reps_hint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: rirController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 48,
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: onRemoveSet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
