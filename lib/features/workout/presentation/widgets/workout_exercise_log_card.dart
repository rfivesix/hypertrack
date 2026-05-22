import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/set_log.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../../../exercise_catalog/presentation/exercise_detail_screen.dart';
import 'workout_card.dart';
import 'workout_log_set_row.dart';

/// A card widget grouping all set logs for a single exercise.
/// Displays headers, exercise notes, set lists, and drag handle for reordering.
class WorkoutExerciseLogCard extends StatelessWidget {
  final String exerciseName;
  final Exercise? exercise;
  final List<SetLog> sets;
  final bool isEditMode;
  final bool isCardio;
  final Map<int, TextEditingController> weightControllers;
  final Map<int, TextEditingController> repsControllers;
  final Map<int, TextEditingController> rirControllers;
  final String? exerciseNote;
  final Function(String exerciseName) onEditNotes;
  final Function(String exerciseName) onDeleteExercise;
  final VoidCallback onAddSet;
  final Function(int setLogId) onDeleteSet;
  final Function(int setLogId) onSetTypeTap;
  final int index;

  const WorkoutExerciseLogCard({
    super.key,
    required this.exerciseName,
    required this.exercise,
    required this.sets,
    required this.isEditMode,
    required this.isCardio,
    required this.weightControllers,
    required this.repsControllers,
    required this.rirControllers,
    required this.exerciseNote,
    required this.onEditNotes,
    required this.onDeleteExercise,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onSetTypeTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutCard(
      key: isEditMode ? ValueKey(exerciseName) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            leading: isEditMode
                ? ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  )
                : null,
            title: InkWell(
              onTap: () {
                if (exercise != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ExerciseDetailScreen(exercise: exercise!),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  exercise?.getLocalizedName(context) ?? exerciseName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditMode)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: "Notizen bearbeiten",
                    onPressed: () => onEditNotes(exerciseName),
                  ),
                if (isEditMode)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: l10n.removeExercise,
                    onPressed: () => onDeleteExercise(exerciseName),
                  )
                else
                  const Icon(Icons.info_outline),
              ],
            ),
          ),
          if (exerciseNote != null && exerciseNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 12.0,
              ),
              child: InkWell(
                onTap: isEditMode ? () => onEditNotes(exerciseName) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exerciseNote!,
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCardio)
                  Row(
                    children: [
                      _buildHeader(l10n.setLabel, flex: 2),
                      _buildHeader(l10n.cardioDistanceLabel, flex: 4),
                      const SizedBox(width: 8),
                      _buildHeader(l10n.cardioTimeLabel, flex: 4),
                      const SizedBox(width: 8),
                      _buildHeader(l10n.cardioIntensityShortLabel, flex: 2),
                      const SizedBox(width: 48), // Space for check/delete
                    ],
                  )
                else
                  Row(
                    children: [
                      _buildHeader(l10n.setLabel, flex: 2),
                      _buildHeader(
                        context
                            .read<UnitService>()
                            .suffixFor(UnitDimension.weight),
                        flex: 2,
                      ),
                      _buildHeader(l10n.repsLabel, flex: 2),
                      _buildHeader("RIR", flex: 2),
                      const SizedBox(width: 48),
                    ],
                  ),

                // Set Rows
                ...sets.asMap().entries.map((setEntry) {
                  final setLog = setEntry.value;
                  final rowIndex = setEntry.key;
                  int workingSetIndex = 0;
                  for (int i = 0; i <= rowIndex; i++) {
                    if (sets[i].setType != 'warmup') workingSetIndex++;
                  }

                  return WorkoutLogSetRow(
                    setLog: setLog,
                    rowIndex: rowIndex,
                    workingSetIndex: workingSetIndex,
                    exerciseName: exerciseName,
                    isEditMode: isEditMode,
                    isCardio: isCardio,
                    weightController: weightControllers[setLog.id],
                    repsController: repsControllers[setLog.id],
                    rirController: rirControllers[setLog.id],
                    onDelete: () => onDeleteSet(setLog.id!),
                    onSetTypeTap: () => onSetTypeTap(setLog.id!),
                  );
                }),

                if (isEditMode)
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

  Widget _buildHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
