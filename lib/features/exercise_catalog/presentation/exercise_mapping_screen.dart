// lib/screens/exercise_mapping_screen.dart
import 'package:flutter/material.dart';
import '../../../data/workout_database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../models/exercise.dart';
import 'general_exercise_selection_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/glass_pill_button.dart';

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
  final Map<String, List<Exercise>> _suggestions = {};
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    for (final name in widget.unknownNames) {
      final matches = await WorkoutDatabaseHelper.instance.searchExercises(
        query: name,
      );
      if (matches.isNotEmpty && mounted) {
        setState(() => _suggestions[name] = matches.take(3).toList());
      }
    }
  }

  Future<void> _pickTarget(String sourceName) async {
    final Exercise? picked = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GeneralExerciseSelectionScreen(),
      ),
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
    // Apply the selected exercise mapping to the workout database
    await WorkoutDatabaseHelper.instance.applyExerciseNameMapping(mapping);
    if (mounted) {
      setState(() => _applying = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.mapExercisesTitle),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.screenPaddingHorizontal,
          DesignConstants.cardPaddingInternal + topPadding,
          DesignConstants.screenPaddingHorizontal,
          0,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: DesignConstants.spacingS,
                  bottom: DesignConstants.spacingL,
                ),
                itemCount: widget.unknownNames.length,
                itemBuilder: (context, index) {
                  final src = widget.unknownNames[index];
                  final picked = _selection[src];
                  final suggestions = _suggestions[src] ?? [];

                  return SummaryCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            src,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: picked == null
                              ? Text(
                                  l10n.noSelection,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : Text(
                                  '→ ${picked.getLocalizedName(context)}',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          trailing: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _pickTarget(src),
                            tooltip: l10n.selectButton,
                          ),
                        ),
                        if (picked == null && suggestions.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(
                            l10n.mappingSuggestions,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: DesignConstants.spacingS),
                          Wrap(
                            spacing: DesignConstants.spacingS,
                            runSpacing: DesignConstants.spacingS,
                            children: suggestions.map((s) {
                              return GlassPillButton(
                                height: 28,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                onTap: () {
                                  setState(() => _selection[src] = s);
                                },
                                child: Text(
                                  s.getLocalizedName(context),
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
                        ] else if (picked != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() => _selection.remove(src));
                              },
                              child: Text(l10n.cancel),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignConstants.spacingM,
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
