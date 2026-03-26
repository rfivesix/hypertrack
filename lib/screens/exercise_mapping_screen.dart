// lib/screens/exercise_mapping_screen.dart
import 'package:flutter/material.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/exercise.dart';
import 'general_exercise_selection_screen.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';

/// A screen for mapping unknown exercise names to known database [Exercise] objects.
///
/// Typically used after importing workout data where some items don't have direct matches.
class ExerciseMappingScreen extends StatefulWidget {
  /// A list of exercise names that could not be matched automatically.
  final List<String> unknownNames;
  const ExerciseMappingScreen({super.key, required this.unknownNames});

  @override
  State<ExerciseMappingScreen> createState() => _ExerciseMappingScreenState();
}

class _ExerciseMappingScreenState extends State<ExerciseMappingScreen> {
  final Map<String, Exercise> _selection = {};
  bool _applying = false;

  Future<void> _pickTarget(String sourceName) async {
    final Exercise? picked = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GeneralExerciseSelectionScreen()),
    );
    if (picked != null && mounted) {
      setState(() => _selection[sourceName] = picked);
    }
  }

  Future<void> _apply() async {
    if (_selection.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _applying = true);
    final mapping = <String, String>{
      for (final e in _selection.entries)
        e.key: e.value.nameDe.isNotEmpty ? e.value.nameDe : e.value.nameEn,
    };
    await WorkoutDatabaseHelper.instance.applyExerciseNameMapping(mapping);
    if (mounted) {
      setState(() => _applying = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.mapExercisesTitle),
      body: Padding(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Column(
          children: [
            const SizedBox(height: DesignConstants.spacingS),
            Expanded(
              child: ListView.builder(
                itemCount: widget.unknownNames.length,
                itemBuilder: (context, index) {
                  final src = widget.unknownNames[index];
                  final picked = _selection[src];
                  return ListTile(
                    title: Text(src),
                    subtitle: picked == null
                        ? Text(l10n.noSelection)
                        : Text('→ ${picked.nameDe} / ${picked.nameEn}'),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(l10n.selectButton),
                      onPressed: () => _pickTarget(src),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: DesignConstants.spacingM,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _applying ? null : _apply,
                    icon: _applying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _applying ? l10n.applyingChanges : l10n.applyMapping,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
