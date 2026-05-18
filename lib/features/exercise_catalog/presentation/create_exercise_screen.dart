// lib/features/exercise_catalog/presentation/create_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/exercise_catalog_repository.dart';
import '../domain/models/exercise.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';

/// A screen for creating custom exercises.
class CreateExerciseScreen extends StatefulWidget {
  final IExerciseCatalogRepository? repository;

  const CreateExerciseScreen({super.key, this.repository});
  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  late final IExerciseCatalogRepository _repository =
      widget.repository ?? context.read<IExerciseCatalogRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;

  // Fallback lists if the DB is empty
  final List<String> _defaultCategories = [
    'Abs',
    'Arms',
    'Back',
    'Calves',
    'Chest',
    'Legs',
    'Shoulders',
    'Cardio',
  ];
  final List<String> _defaultMuscles = [
    'Biceps',
    'Triceps',
    'Quadriceps',
    'Hamstrings',
    'Calves',
    'Chest',
    'Back',
    'Shoulders',
    'Abs',
    'Glutes',
    'Forearms',
    'Traps',
  ];

  List<String> _allCategories = [];
  List<String> _allMuscleGroups = [];

  final List<String> _selectedPrimaryMuscles = [];
  final List<String> _selectedSecondaryMuscles = [];

  bool _isLoading = true;
  bool _saving = false;

  late final l10n = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _repository.getAllCategories();
      // Muscle groups are not in catalog repository yet, but let's see how they are implemented in WorkoutLocalDataSource.
      // WorkoutLocalDataSource has `getAllMuscleGroups`. Let's use `WorkoutLocalDataSource.instance.getAllMuscleGroups()` for muscle groups
      // as muscles are shared. Or let's proxy muscle groups in ExerciseCatalogRepository too.
      // Wait, is there any other place? Let's check. Yes, let's keep it robust.
      final muscles = await _repository.getAllMuscleGroups();

      if (mounted) {
        setState(() {
          _allCategories =
              categories.isNotEmpty ? categories : _defaultCategories;
          _allMuscleGroups = muscles.isNotEmpty ? muscles : _defaultMuscles;

          _allCategories.sort();
          _allMuscleGroups.sort();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) {
        setState(() {
          _allCategories = _defaultCategories;
          _allMuscleGroups = _defaultMuscles;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveExercise() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final newExercise = Exercise(
        nameDe: _nameController.text.trim(),
        nameEn: _nameController.text.trim(),
        descriptionDe: _descriptionController.text.trim(),
        descriptionEn: _descriptionController.text.trim(),
        categoryName: _selectedCategory ?? 'Other',
        primaryMuscles: _selectedPrimaryMuscles,
        secondaryMuscles: _selectedSecondaryMuscles,
        imagePath: null,
      );

      await _repository.insertExercise(newExercise);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackbarSaveSuccess(newExercise.nameDe))),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.create_exercise_screen_title,
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveExercise,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: TextStyle(
                      color: _saving
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top + topPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.exercise_name_label,
                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.validatorPleaseEnterName;
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      items: _allCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategory = val);
                      },
                      decoration: InputDecoration(
                        labelText: l10n.category_label,
                        hintText: l10n.categoryHint,
                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.validatorPleaseEnterCategory;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description_optional_label,
                        filled: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),
                    AppSectionHeader(title: l10n.primary_muscles_label),
                    const SizedBox(height: 8),
                    _buildMuscleSelector(
                      availableMuscles: _allMuscleGroups,
                      selectedMuscles: _selectedPrimaryMuscles,
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),
                    AppSectionHeader(title: l10n.secondary_muscles_label),
                    const SizedBox(height: 8),
                    _buildMuscleSelector(
                      availableMuscles: _allMuscleGroups,
                      selectedMuscles: _selectedSecondaryMuscles,
                    ),
                    const SizedBox(height: DesignConstants.spacingXXL),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMuscleSelector({
    required List<String> availableMuscles,
    required List<String> selectedMuscles,
  }) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: availableMuscles.map((muscle) {
        final isSelected = selectedMuscles.contains(muscle);
        return FilterChip(
          label: Text(muscle),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedMuscles.add(muscle);
              } else {
                selectedMuscles.remove(muscle);
              }
            });
          },
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }
}
