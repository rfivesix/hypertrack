// lib/screens/goals_screen.dart

import 'package:flutter/material.dart';
import '../util/design_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';
import '../widgets/global_app_bar.dart';
import '../data/database_helper.dart';
import '../features/nutrition_recommendation/data/recommendation_service.dart';
import '../features/nutrition_recommendation/domain/goal_models.dart';
import '../features/nutrition_recommendation/presentation/prior_activity_help_block.dart';

/// A screen for defining daily health and nutrition targets.
///
/// Users can set goals for calories, macronutrients (protein, carbs, fat),
/// water intake, and other detailed metrics like sugar or fiber.
class GoalsScreen extends StatefulWidget {
  final AdaptiveNutritionRecommendationService? recommendationService;
  final DatabaseHelper? databaseHelper;

  const GoalsScreen({
    super.key,
    this.recommendationService,
    this.databaseHelper,
  });

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late final AdaptiveNutritionRecommendationService _recommendationService;
  late final DatabaseHelper _databaseHelper;

  BodyweightGoal _selectedGoal = BodyweightGoal.maintainWeight;
  double _selectedTargetRateKgPerWeek = 0;
  PriorActivityLevel _selectedPriorActivityLevel =
      PriorActivityLevelCatalog.defaultLevel;
  ExtraCardioHoursOption _selectedExtraCardioHoursOption =
      ExtraCardioHoursCatalog.defaultOption;

  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _waterController = TextEditingController();
  final _stepsController = TextEditingController();
  final _heightController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  final _saltController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _databaseHelper = widget.databaseHelper ?? DatabaseHelper.instance;
    _recommendationService = widget.recommendationService ??
        AdaptiveNutritionRecommendationService(databaseHelper: _databaseHelper);
    _loadSettings();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    _stepsController.dispose();
    _heightController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences
          .getInstance(); // Only needed for height if it is not in the profile.
      final selectedGoal = await _recommendationService.getGoal();
      final selectedTargetRate =
          await _recommendationService.getTargetRateKgPerWeek();
      final selectedPriorActivityLevel =
          await _recommendationService.getPriorActivityLevel();
      final selectedExtraCardioHoursOption =
          await _recommendationService.getExtraCardioHoursOption();

      // Load goals from the DB
      final settings = await _databaseHelper.getAppSettings();
      final targetSteps =
          await _databaseHelper.getCurrentTargetStepsOrDefault();
      // Load profile for height
      // Optional: `getProfile` could also be added to the helper, but prefs are ok as a height transition.

      if (!mounted) return;
      setState(() {
        _heightController.text = (prefs.getInt('userHeight') ?? 180).toString();

        // Values from DB or defaults
        _caloriesController.text =
            (settings?.targetCalories ?? 2500).toString();
        _proteinController.text = (settings?.targetProtein ?? 180).toString();
        _carbsController.text = (settings?.targetCarbs ?? 250).toString();
        _fatController.text = (settings?.targetFat ?? 80).toString();
        _waterController.text = (settings?.targetWater ?? 3000).toString();
        _stepsController.text = targetSteps.toString();

        // Note: sugar, fiber, and salt are not defined in Drift's AppSettings schema yet.
        // Extend the AppSettings table in drift_database.dart if these should sync too.
        // For now, still load these from prefs because they were missing from the schema:
        _sugarController.text = (prefs.getInt('targetSugar') ?? 50).toString();
        _fiberController.text = (prefs.getInt('targetFiber') ?? 30).toString();
        _saltController.text = (prefs.getInt('targetSalt') ?? 6).toString();
        _selectedGoal = selectedGoal;
        _selectedTargetRateKgPerWeek = WeeklyTargetRateCatalog.coerceTargetRate(
          goal: selectedGoal,
          kgPerWeek: selectedTargetRate,
        );
        _selectedPriorActivityLevel = selectedPriorActivityLevel;
        _selectedExtraCardioHoursOption = selectedExtraCardioHoursOption;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('GoalsScreen: failed to load settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Height in prefs (or later DB profile update)
    await prefs.setInt('userHeight', int.parse(_heightController.text));

    await _recommendationService.saveGoalAndTargetRate(
      goal: _selectedGoal,
      targetRateKgPerWeek: _selectedTargetRateKgPerWeek,
    );
    await _recommendationService.savePriorActivityLevel(
      _selectedPriorActivityLevel,
    );
    await _recommendationService.saveExtraCardioHoursOption(
      _selectedExtraCardioHoursOption,
    );

    // 2. Important: save goals to the database.
    await _databaseHelper.saveUserGoals(
      calories: int.parse(_caloriesController.text),
      protein: int.parse(_proteinController.text),
      carbs: int.parse(_carbsController.text),
      fat: int.parse(_fatController.text),
      water: int.parse(_waterController.text),
      steps: int.parse(_stepsController.text),
    );

    // 3. The extra values (sugar/fiber/salt) stay in prefs for now,
    // until the DB schema is extended (recommended later).
    await prefs.setInt('targetSugar', int.parse(_sugarController.text));
    await prefs.setInt('targetFiber', int.parse(_fiberController.text));
    await prefs.setInt('targetSalt', int.parse(_saltController.text));

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snackbarGoalsSaved)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,

      // New: our GlobalAppBar
      appBar: GlobalAppBar(
        title: l10n.my_goals,
        actions: [
          // The save button stays, just wrapped a little differently.
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _saveSettings,
              child: Text(
                l10n.buttonSave,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // New padding logic
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top +
                    MediaQuery.of(context).padding.top +
                    kToolbarHeight,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(
                      context,
                      l10n.personalDataCL,
                      key: const Key('goals_personal_section_title'),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    _buildSettingsField(
                      controller: _heightController,
                      label: l10n.profileUserHeight,
                      fieldKey: const Key('goals_height_field'),
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildSectionTitle(
                      context,
                      l10n.adaptiveBodyweightTargetSectionTitle,
                      key: const Key('goals_adaptive_section_title'),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    DropdownButtonFormField<BodyweightGoal>(
                      initialValue: _selectedGoal,
                      decoration: InputDecoration(
                        labelText: l10n.adaptiveGoalDirectionLabel,
                      ),
                      items: BodyweightGoal.values
                          .map(
                            (goal) => DropdownMenuItem<BodyweightGoal>(
                              value: goal,
                              child: Text(
                                _goalLabel(l10n, goal),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (goal) {
                        if (goal == null) return;
                        setState(() {
                          _selectedGoal = goal;
                          _selectedTargetRateKgPerWeek =
                              WeeklyTargetRateCatalog.defaultForGoal(goal)
                                  .kgPerWeek;
                        });
                      },
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: WeeklyTargetRateCatalog.optionsForGoal(
                        _selectedGoal,
                      ).map((option) {
                        final selected =
                            option.kgPerWeek == _selectedTargetRateKgPerWeek;
                        return ChoiceChip(
                          label: Text(
                            _rateLabel(l10n, option.kgPerWeek),
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedTargetRateKgPerWeek = option.kgPerWeek;
                            });
                          },
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildSectionTitle(
                      context,
                      l10n.adaptiveRecommendationSettingsSectionTitle,
                      key: const Key(
                        'goals_recommendation_settings_section_title',
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    DropdownButtonFormField<PriorActivityLevel>(
                      key: const Key('goals_prior_activity_dropdown'),
                      initialValue: _selectedPriorActivityLevel,
                      decoration: InputDecoration(
                        labelText: l10n.adaptivePriorActivityLabel,
                      ),
                      items: PriorActivityLevel.values
                          .map(
                            (level) => DropdownMenuItem<PriorActivityLevel>(
                              value: level,
                              child: Text(
                                _priorActivityLabel(l10n, level),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (level) {
                        if (level == null) return;
                        setState(() {
                          _selectedPriorActivityLevel = level;
                        });
                      },
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    PriorActivityHelpBlock(
                      key: const Key('goals_prior_activity_help_block'),
                      l10n: l10n,
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    DropdownButtonFormField<ExtraCardioHoursOption>(
                      key: const Key('goals_extra_cardio_dropdown'),
                      initialValue: _selectedExtraCardioHoursOption,
                      decoration: InputDecoration(
                        labelText: l10n.adaptiveExtraCardioLabel,
                      ),
                      items: ExtraCardioHoursCatalog.supportedOptions
                          .map(
                            (option) =>
                                DropdownMenuItem<ExtraCardioHoursOption>(
                              value: option,
                              child: Text(_extraCardioLabel(l10n, option)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (option) {
                        if (option == null) return;
                        setState(() {
                          _selectedExtraCardioHoursOption = option;
                        });
                      },
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    Text(
                      l10n.adaptiveExtraCardioHelp,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildSectionTitle(
                      context,
                      l10n.profileDailyGoalsCL,
                      key: const Key('goals_daily_section_title'),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    _buildSettingsField(
                      controller: _caloriesController,
                      label: l10n.calories,
                    ),
                    //const SizedBox(height: DesignConstants.spacingL),
                    //_buildMacroCalculator(),
                    //const SizedBox(height: DesignConstants.spacingL),
                    _buildSettingsField(
                      controller: _proteinController,
                      label: l10n.protein,
                    ),
                    _buildSettingsField(
                      controller: _carbsController,
                      label: l10n.carbs,
                    ),
                    _buildSettingsField(
                      controller: _fatController,
                      label: l10n.fat,
                    ),
                    _buildSettingsField(
                      controller: _waterController,
                      label: l10n.water,
                    ),
                    _buildSettingsField(
                      controller: _stepsController,
                      label: l10n.steps,
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildSectionTitle(context, l10n.detailedNutrientGoalsCL),
                    const SizedBox(height: DesignConstants.spacingM),
                    _buildSettingsField(
                      controller: _sugarController,
                      label: l10n.sugar,
                    ),
                    _buildSettingsField(
                      controller: _fiberController,
                      label: l10n.fiber,
                    ),
                    _buildSettingsField(
                      controller: _saltController,
                      label: l10n.salt,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSettingsField({
    required TextEditingController controller,
    required String label,
    Key? fieldKey,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty || num.tryParse(value) == null) {
            return l10n.validatorPleaseEnterNumber;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    Key? key,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        key: key,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _goalLabel(AppLocalizations l10n, BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return l10n.adaptiveGoalLose;
      case BodyweightGoal.maintainWeight:
        return l10n.adaptiveGoalMaintain;
      case BodyweightGoal.gainWeight:
        return l10n.adaptiveGoalGain;
    }
  }

  String _rateLabel(AppLocalizations l10n, double kgPerWeek) {
    final sign = kgPerWeek > 0 ? '+' : '';
    return l10n.adaptiveRatePerWeek('$sign${kgPerWeek.toStringAsFixed(2)}');
  }

  String _priorActivityLabel(
    AppLocalizations l10n,
    PriorActivityLevel level,
  ) {
    switch (level) {
      case PriorActivityLevel.low:
        return l10n.adaptivePriorActivityLow;
      case PriorActivityLevel.moderate:
        return l10n.adaptivePriorActivityModerate;
      case PriorActivityLevel.high:
        return l10n.adaptivePriorActivityHigh;
      case PriorActivityLevel.veryHigh:
        return l10n.adaptivePriorActivityVeryHigh;
    }
  }

  String _extraCardioLabel(
    AppLocalizations l10n,
    ExtraCardioHoursOption option,
  ) {
    switch (option) {
      case ExtraCardioHoursOption.h0:
        return l10n.adaptiveExtraCardioOption0;
      case ExtraCardioHoursOption.h1:
        return l10n.adaptiveExtraCardioOption1;
      case ExtraCardioHoursOption.h2:
        return l10n.adaptiveExtraCardioOption2;
      case ExtraCardioHoursOption.h3:
        return l10n.adaptiveExtraCardioOption3;
      case ExtraCardioHoursOption.h5:
        return l10n.adaptiveExtraCardioOption5;
      case ExtraCardioHoursOption.h7Plus:
        return l10n.adaptiveExtraCardioOption7Plus;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
