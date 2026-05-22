import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/routine_exercise.dart';
import '../../domain/models/set_template.dart';
import '../../../exercise_catalog/presentation/exercise_detail_screen.dart';
import 'workout_card.dart';
import 'routine_set_row_widget.dart';

class EditRoutineExerciseCard extends StatelessWidget {
  final RoutineExercise routineExercise;
  final int index;
  final bool isCardio;
  final Map<int, TextEditingController> repsControllers;
  final Map<int, TextEditingController> weightControllers;
  final Map<int, TextEditingController> rirControllers;
  final VoidCallback onEditNotes;
  final VoidCallback onEditPauseTime;
  final VoidCallback onDeleteExercise;
  final VoidCallback onAddSet;
  final Function(SetTemplate) onShowSetTypePicker;
  final Function(SetTemplate, int listIndex) onRemoveSet;

  const EditRoutineExerciseCard({
    super.key,
    required this.routineExercise,
    required this.index,
    required this.isCardio,
    required this.repsControllers,
    required this.weightControllers,
    required this.rirControllers,
    required this.onEditNotes,
    required this.onEditPauseTime,
    required this.onDeleteExercise,
    required this.onAddSet,
    required this.onShowSetTypePicker,
    required this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(
                    exercise: routineExercise.exercise,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  routineExercise.exercise.getLocalizedName(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (routineExercise.pauseSeconds != null &&
                    routineExercise.pauseSeconds! > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      "${routineExercise.pauseSeconds}s",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Notizen bearbeiten",
                  onPressed: onEditNotes,
                ),
                IconButton(
                  icon: const Icon(Icons.timer_outlined),
                  tooltip: l10n.editPauseTime,
                  onPressed: onEditPauseTime,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: l10n.removeExercise,
                  onPressed: onDeleteExercise,
                ),
              ],
            ),
          ),
          if (routineExercise.notes != null &&
              routineExercise.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 12.0,
              ),
              child: InkWell(
                onTap: onEditNotes,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          routineExercise.notes!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(context, routineExercise, l10n),
                ...routineExercise.setTemplates.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final setTemplate = entry.value;

                  int workingSetIndex = 0;
                  for (int i = 0; i <= setIndex; i++) {
                    if (routineExercise.setTemplates[i].setType != 'warmup') {
                      workingSetIndex++;
                    }
                  }

                  return RoutineSetRowWidget(
                    key: ValueKey(setTemplate.id),
                    setIndex: workingSetIndex,
                    rowIndex: setIndex,
                    routineExercise: routineExercise,
                    template: setTemplate,
                    listIndex: setIndex,
                    isCardio: isCardio,
                    repsController: repsControllers[setTemplate.id!]!,
                    weightController: weightControllers[setTemplate.id!]!,
                    rirController: rirControllers[setTemplate.id!]!,
                    onShowSetTypePicker: () => onShowSetTypePicker(setTemplate),
                    onRemoveSet: () => onRemoveSet(setTemplate, setIndex),
                  );
                }),
                const SizedBox(height: DesignConstants.spacingS),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextButton.icon(
                    onPressed: onAddSet,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addSetButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    RoutineExercise re,
    AppLocalizations l10n,
  ) {
    if (isCardio) {
      return Row(
        children: [
          _buildHeader(l10n.setLabel, flex: 2),
          _buildHeader(l10n.cardioDistanceLabel, flex: 4),
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioTimeLabel, flex: 4),
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioIntensityLabel, flex: 2),
          const SizedBox(width: 48),
        ],
      );
    }
    return Row(
      children: [
        _buildHeader(l10n.setLabel, flex: 2),
        _buildHeader(
          context.read<UnitService>().suffixFor(UnitDimension.weight),
          flex: 2,
        ),
        const SizedBox(width: 8),
        _buildHeader(l10n.repsLabel, flex: 2),
        const SizedBox(width: 8),
        _buildHeader("RIR", flex: 2),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildHeader(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
