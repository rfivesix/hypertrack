// lib/features/exercise_catalog/presentation/exercise_catalog_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'widgets/wger_attribution_widget.dart';
import 'create_exercise_screen.dart';
import '../../../widgets/common/glass_fab.dart';

/// A searchable list of all available exercises in the database.
class ExerciseCatalogScreen extends StatefulWidget {
  /// Whether the screen is used to select an exercise to return to a caller.
  final bool isSelectionMode;

  /// Optional callback for handling the selection manually instead of popping.
  final void Function(Exercise)? onExerciseSelected;
  final IExerciseCatalogRepository? repository;

  const ExerciseCatalogScreen({
    super.key,
    this.isSelectionMode = false,
    this.onExerciseSelected,
    this.repository,
  });

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  late final IExerciseCatalogRepository _repository =
      widget.repository ?? context.read<IExerciseCatalogRepository>();
  List<Exercise> _foundExercises = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  List<String> _allCategories = [];
  List<String> _selectedCategories = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runFilter(_searchController.text);
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _repository.getAllCategories();
    setState(() {
      _allCategories = categories;
      _isLoading = false;
    });
    _runFilter(_searchController.text);
  }

  void _runFilter(String enteredKeyword) async {
    final results = await _repository.searchExercises(
      query: enteredKeyword,
      categories: _selectedCategories,
    );
    if (mounted) {
      setState(() {
        _foundExercises = results;
      });
    }
  }

  void _showFilterDialog(BuildContext context, AppLocalizations l10n) {
    showGlassBottomMenu(
      context: context,
      title: l10n.filterByCategory,
      contentBuilder: (ctx, close) {
        List<String> tempSelected = List.from(_selectedCategories);

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allCategories.length,
                    itemBuilder: (context, index) {
                      final category = _allCategories[index];
                      final isSelected = tempSelected.contains(category);
                      return CheckboxListTile(
                        title: Text(category),
                        value: isSelected,
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                        onChanged: (bool? value) {
                          setStateSB(() {
                            if (value == true) {
                              tempSelected.add(category);
                            } else {
                              tempSelected.remove(category);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          close();
                        },
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategories = tempSelected;
                          });
                          _runFilter(_searchController.text);
                          close();
                        },
                        child: Text(l10n.doneButtonLabel),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.exerciseCatalogTitle,
        actions: [
          if (widget.isSelectionMode)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.doneButtonLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: DesignConstants.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchHintText,
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildFilterButton(context, l10n),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _foundExercises.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noExercisesFound,
                          style: textTheme.titleMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: DesignConstants.cardPadding,
                        itemCount: _foundExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _foundExercises[index];
                          return SummaryCard(
                            child: ListTile(
                              leading: const Icon(Icons.fitness_center),
                              title: Text(
                                exercise.getLocalizedName(context),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(exercise.categoryName),
                              trailing: widget.isSelectionMode
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color: colorScheme.primary,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(exercise),
                                    )
                                  : const Icon(
                                      Icons.chevron_right,
                                    ),
                              onTap: () {
                                if (widget.onExerciseSelected != null) {
                                  widget.onExerciseSelected!(exercise);
                                } else if (widget.isSelectionMode) {
                                  Navigator.of(context).pop(exercise);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ExerciseDetailScreen(
                                              exercise: exercise,
                                              repository: _repository),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: WgerAttributionWidget(
              textStyle: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      floatingActionButton: GlassFab(
        label: l10n.create_exercise_screen_title,
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) =>
                  CreateExerciseScreen(repository: _repository),
            ),
          )
              .then((wasCreated) {
            if (wasCreated == true) {
              _runFilter(_searchController.text);
            }
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFilterButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasFilter = _selectedCategories.isNotEmpty;

    final fillColor = hasFilter
        ? colorScheme.primary
        : (theme.inputDecorationTheme.fillColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF1C1C1C)
                : const Color(0xFFF3F3F3)));

    final iconColor = hasFilter
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: IconButton(
        icon: Icon(
          Icons.filter_list,
          color: iconColor,
          size: 22,
        ),
        onPressed: () => _showFilterDialog(context, l10n),
        tooltip: l10n.filterByCategory,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}
