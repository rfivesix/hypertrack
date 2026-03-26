import 'package:flutter/material.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/exercise.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

/// A lightweight, general-purpose exercise picker that returns an [Exercise].
///
/// This screen is intentionally minimal and should be used in non-diary
/// contexts that only need to select an item.
class GeneralExerciseSelectionScreen extends StatefulWidget {
  const GeneralExerciseSelectionScreen({super.key});

  @override
  State<GeneralExerciseSelectionScreen> createState() =>
      _GeneralExerciseSelectionScreenState();
}

class _GeneralExerciseSelectionScreenState
    extends State<GeneralExerciseSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Exercise> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runFilter('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runFilter(String enteredKeyword) async {
    setState(() => _isLoading = true);
    final results = await WorkoutDatabaseHelper.instance.searchExercises(
      query: enteredKeyword,
      selectedCategories: const [],
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.exerciseCatalogTitle),
      body: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: l10n.searchHintText,
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noExercisesFound,
                            style: textTheme.titleMedium,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final exercise = _results[index];
                            return SummaryCard(
                              child: ListTile(
                                leading: const Icon(Icons.fitness_center),
                                title: Text(
                                  exercise.getLocalizedName(context),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(exercise.categoryName),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(exercise),
                                ),
                                onTap: () =>
                                    Navigator.of(context).pop(exercise),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
