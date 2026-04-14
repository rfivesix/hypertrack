// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/backup_manager.dart';
import '../data/database_helper.dart';
import '../generated/app_localizations.dart';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../features/nutrition_recommendation/data/recommendation_service.dart';
import '../features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import '../features/nutrition_recommendation/domain/confidence_models.dart';
import '../features/nutrition_recommendation/presentation/body_fat_guidance_sheet.dart';
import '../features/nutrition_recommendation/presentation/prior_activity_help_block.dart';
import '../features/nutrition_recommendation/presentation/recommendation_ui_copy.dart';
import '../features/nutrition_recommendation/domain/goal_models.dart';
import '../features/nutrition_recommendation/domain/recommendation_models.dart';
import '../services/app_tour_service.dart';
import '../widgets/glass_bottom_menu.dart';

/// The initial setup flow for new users.
///
/// Collects user profile data (name, DOB, anthropometrics) and initial
/// nutrition/health goals to populate the database and preferences.
class OnboardingScreen extends StatefulWidget {
  final AdaptiveNutritionRecommendationService? recommendationService;
  final DatabaseHelper? databaseHelper;

  const OnboardingScreen({
    super.key,
    this.recommendationService,
    this.databaseHelper,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _adaptiveGoalPageIndex = 4;
  static const int _pageCount = 8;
  static const int _lastPageIndex = _pageCount - 1;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRestoring = false;
  bool _isGeneratingOnboardingRecommendation = false;

  late final AdaptiveNutritionRecommendationService _recommendationService;
  late final DatabaseHelper _databaseHelper;
  BodyweightGoal _selectedGoal = BodyweightGoal.maintainWeight;
  double _selectedTargetRateKgPerWeek = WeeklyTargetRateCatalog.defaultForGoal(
    BodyweightGoal.maintainWeight,
  ).kgPerWeek;
  NutritionRecommendation? _onboardingRecommendation;
  BayesianMaintenanceEstimate? _onboardingMaintenanceEstimate;
  bool _hasAppliedOnboardingRecommendationToGoals = false;

  // --- CONTROLLER ---
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _heightController =
      TextEditingController(); // NEU
  String? _selectedGender; // NEU (male, female, diverse)
  final TextEditingController _bodyFatPercentController =
      TextEditingController();
  PriorActivityLevel _selectedPriorActivityLevel =
      PriorActivityLevelCatalog.defaultLevel;
  ExtraCardioHoursOption _selectedExtraCardioHoursOption =
      ExtraCardioHoursCatalog.defaultOption;

  final TextEditingController _weightController = TextEditingController();

  final TextEditingController _calController = TextEditingController(
    text: '2500',
  );
  final TextEditingController _protController = TextEditingController(
    text: '180',
  );
  final TextEditingController _carbController = TextEditingController(
    text: '250',
  );
  final TextEditingController _fatController = TextEditingController(
    text: '80',
  );
  final TextEditingController _waterController = TextEditingController(
    text: '3000',
  );

  @override
  void initState() {
    super.initState();
    _databaseHelper = widget.databaseHelper ?? DatabaseHelper.instance;
    _recommendationService = widget.recommendationService ??
        AdaptiveNutritionRecommendationService(databaseHelper: _databaseHelper);
    _loadAdaptiveGoalSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _bodyFatPercentController.dispose();
    _weightController.dispose();
    _calController.dispose();
    _protController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  // lib/screens/onboarding_screen.dart

  Future<void> _loadAdaptiveGoalSettings() async {
    final goal = await _recommendationService.getGoal();
    final rate = await _recommendationService.getTargetRateKgPerWeek();
    final priorActivityLevel =
        await _recommendationService.getPriorActivityLevel();
    final extraCardioHoursOption =
        await _recommendationService.getExtraCardioHoursOption();
    if (!mounted) return;
    setState(() {
      _selectedGoal = goal;
      _selectedTargetRateKgPerWeek = WeeklyTargetRateCatalog.coerceTargetRate(
        goal: goal,
        kgPerWeek: rate,
      );
      _selectedPriorActivityLevel = priorActivityLevel;
      _selectedExtraCardioHoursOption = extraCardioHoursOption;
    });
  }

  Future<void> _refreshOnboardingRecommendationPreview() async {
    if (_isGeneratingOnboardingRecommendation) return;
    setState(() => _isGeneratingOnboardingRecommendation = true);

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = int.tryParse(_heightController.text);
    final bodyFatPercent =
        double.tryParse(_bodyFatPercentController.text.replaceAll(',', '.'));
    try {
      final preview =
          await _recommendationService.generateOnboardingRecommendationPreview(
        goal: _selectedGoal,
        targetRateKgPerWeek: _selectedTargetRateKgPerWeek,
        weightKg: weight,
        heightCm: height,
        birthday: _selectedDate,
        gender: _selectedGender,
        bodyFatPercent: bodyFatPercent,
        declaredActivityLevel: _selectedPriorActivityLevel,
        extraCardioHoursOption: _selectedExtraCardioHoursOption,
        persistGenerated: false,
        markAsApplied: false,
      );

      if (!mounted) return;
      setState(() {
        _onboardingRecommendation = preview.recommendation;
        _onboardingMaintenanceEstimate = preview.maintenanceEstimate;
      });
    } finally {
      if (mounted) {
        setState(() => _isGeneratingOnboardingRecommendation = false);
      }
    }
  }

  void _applyOnboardingRecommendationToGoals() {
    final recommendation = _onboardingRecommendation;
    if (recommendation == null) return;
    setState(() {
      _calController.text = recommendation.recommendedCalories.toString();
      _protController.text = recommendation.recommendedProteinGrams.toString();
      _carbController.text = recommendation.recommendedCarbsGrams.toString();
      _fatController.text = recommendation.recommendedFatGrams.toString();
      _hasAppliedOnboardingRecommendationToGoals = true;
    });
  }

  bool _activeGoalInputsMatchRecommendation(
      NutritionRecommendation recommendation) {
    return (int.tryParse(_calController.text) ?? -1) ==
            recommendation.recommendedCalories &&
        (int.tryParse(_protController.text) ?? -1) ==
            recommendation.recommendedProteinGrams &&
        (int.tryParse(_carbController.text) ?? -1) ==
            recommendation.recommendedCarbsGrams &&
        (int.tryParse(_fatController.text) ?? -1) ==
            recommendation.recommendedFatGrams;
  }

  Future<void> _finishOnboarding() async {
    final db = _databaseHelper;
    final prefs = await SharedPreferences.getInstance();

    final int calories = int.tryParse(_calController.text) ?? 2500;
    final int protein = int.tryParse(_protController.text) ?? 180;
    final int carbs = int.tryParse(_carbController.text) ?? 250;
    final int fat = int.tryParse(_fatController.text) ?? 80;
    final int water = int.tryParse(_waterController.text) ?? 3000;
    final int? height = int.tryParse(_heightController.text);
    final double? weight = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final double? bodyFatPercent = double.tryParse(
      _bodyFatPercentController.text.replaceAll(',', '.'),
    );

    final onboardingRecommendation = _onboardingRecommendation ??
        await _recommendationService.generateOnboardingRecommendation(
          goal: _selectedGoal,
          targetRateKgPerWeek: _selectedTargetRateKgPerWeek,
          weightKg: weight,
          heightCm: height,
          birthday: _selectedDate,
          gender: _selectedGender,
          bodyFatPercent: bodyFatPercent,
          declaredActivityLevel: _selectedPriorActivityLevel,
          extraCardioHoursOption: _selectedExtraCardioHoursOption,
          persistGenerated: false,
          markAsApplied: false,
        );

    // 1. Profil speichern (DB)
    await db.saveUserProfile(
      name: _nameController.text.trim(),
      birthday: _selectedDate,
      height: height,
      gender: _selectedGender,
    );

    // Height auch kurz in Prefs cachen für GoalsScreen Fallback (optional)
    if (height != null) await prefs.setInt('userHeight', height);

    // 2. Startgewicht (DB)
    if (weight != null) {
      await db.saveInitialWeight(weight);
    }
    if (bodyFatPercent != null && bodyFatPercent > 0 && bodyFatPercent <= 100) {
      await db.saveInitialBodyFatPercentage(bodyFatPercent);
    }

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

    await _recommendationService.persistGeneratedRecommendation(
      recommendation: onboardingRecommendation,
      markAsApplied: _activeGoalInputsMatchRecommendation(
        onboardingRecommendation,
      ),
    );

    // 3. Ziele speichern (DB - DAS IST JETZT DIE QUELLE FÜR ALLES)
    await db.saveUserGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      water: water,
      steps: 8000,
    );

    // 4. Extra Werte (Sugar/Fiber/Salt) Defaults in Prefs setzen (da noch nicht in DB Schema)
    if (prefs.getInt('targetSugar') == null) {
      await prefs.setInt('targetSugar', 50);
    }
    if (prefs.getInt('targetFiber') == null) {
      await prefs.setInt('targetFiber', 30);
    }
    if (prefs.getInt('targetSalt') == null) await prefs.setInt('targetSalt', 6);

    // 5. Fertig markieren
    await prefs.setBool('hasSeenOnboarding', true);
    await AppTourService.instance.queuePostOnboardingOffer();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  /// Lets the user pick a backup JSON file and import it, skipping onboarding.
  Future<void> _restoreFromBackup() async {
    final l10n = AppLocalizations.of(context)!;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isRestoring = true);
    final filePath = result.files.single.path!;

    bool success = await BackupManager.instance.importFullBackupAuto(filePath);

    // If plain import failed, the file might be encrypted — ask for password.
    if (!success && mounted) {
      final pw = await _askRestorePassword(l10n);
      if (pw != null) {
        success = await BackupManager.instance.importFullBackupAuto(
          filePath,
          passphrase: pw,
        );
      }
    }

    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      await AppTourService.instance.queuePostOnboardingOffer();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.onboardingRestoreSuccess)));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.onboardingRestoreFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _askRestorePassword(AppLocalizations l10n) async {
    final controller = TextEditingController();
    return showGlassBottomMenu<String?>(
      context: context,
      title: l10n.dialogEnterPasswordImport,
      contentBuilder: (ctx, close) => Column(
        key: const Key('onboarding_restore_password_sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(controller.text.trim()),
                  child: Text(l10n.onboardingNext),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 1) {
      if (_nameController.text.trim().isEmpty) return;
    }

    if (_currentPage < _lastPageIndex) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / _pageCount,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 4,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  if (i == _adaptiveGoalPageIndex) {
                    _refreshOnboardingRecommendationPreview();
                  }
                },
                children: [
                  _buildWelcomePage(l10n),
                  _buildProfilePage(l10n),
                  _buildWeightPage(l10n),
                  _buildBodyFatPage(l10n),
                  _buildAdaptiveGoalPage(l10n),
                  _buildCaloriesPage(l10n),
                  _buildMacrosPage(l10n),
                  _buildWaterPage(l10n),
                ],
              ),
            ),
            // Hide bottom nav on the welcome page (page 0) — it has its own buttons.
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      key: const Key('onboarding_bottom_next_button'),
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _lastPageIndex
                            ? l10n.onboardingFinish.toUpperCase()
                            : l10n.onboardingNext.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWelcomeTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Primary CTA — continue with profile setup
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('onboarding_continue_setup_button'),
              onPressed: _isRestoring ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.onboardingContinueSetup.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary CTA — restore from backup
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isRestoring ? null : _restoreFromBackup,
              icon: _isRestoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text(
                _isRestoring
                    ? l10n.onboardingRestoreImporting
                    : l10n.onboardingRestoreFromBackup,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const Key('onboarding_profile_page'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _StepTitle(title: l10n.onboardingNameTitle),
          const SizedBox(height: 16),
          TextField(
            key: const Key('onboarding_name_text_field'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 32),
          _StepTitle(title: l10n.onboardingDobTitle),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                if (_currentPage >= _adaptiveGoalPageIndex) {
                  _refreshOnboardingRecommendationPreview();
                }
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.onboardingDobLabel,
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedDate == null
                    ? 'DD.MM.YYYY'
                    : DateFormat.yMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(_selectedDate!),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      title: l10n.onboardingHeightLabel,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('onboarding_height_text_field'),
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        setState(() {
                          _hasAppliedOnboardingRecommendationToGoals = false;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: l10n.onboardingHeightLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      title: l10n.onboardingGenderLabel,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('onboarding_gender_dropdown'),
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(l10n.genderMale),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(l10n.genderFemale),
                        ),
                        DropdownMenuItem(
                          value: 'diverse',
                          child: Text(l10n.genderDiverse),
                        ),
                      ],
                      onChanged: (val) => setState(() {
                        _selectedGender = val;
                        _hasAppliedOnboardingRecommendationToGoals = false;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... Restliche Pages bleiben identisch zum vorherigen Code ...

  Widget _buildWeightPage(AppLocalizations l10n) {
    return Padding(
      key: const Key('onboarding_weight_page'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepTitle(
            title: l10n.onboardingWeightTitle,
            align: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {
                _hasAppliedOnboardingRecommendationToGoals = false;
              });
            },
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyFatPage(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const Key('onboarding_body_fat_page'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _StepTitle(
            title: l10n.onboardingBodyFatPageTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingBodyFatPageSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('onboarding_body_fat_text_field'),
            controller: _bodyFatPercentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {
                _hasAppliedOnboardingRecommendationToGoals = false;
              });
              if (_currentPage >= _adaptiveGoalPageIndex) {
                _refreshOnboardingRecommendationPreview();
              }
            },
            decoration: InputDecoration(
              labelText: l10n.onboardingBodyFatOptionalLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingBodyFatOptionalHelper,
            key: const Key('onboarding_body_fat_helper_text'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('onboarding_body_fat_help_button'),
              onPressed: _openBodyFatHelperEntryPoint,
              child: Text(l10n.onboardingBodyFatHelpAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveGoalPage(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const Key('onboarding_adaptive_goal_page'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _StepTitle(
            title: l10n.onboardingAdaptiveGoalTitle,
            align: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingAdaptiveGoalSubtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<BodyweightGoal>(
            initialValue: _selectedGoal,
            decoration: InputDecoration(
              labelText: l10n.adaptiveGoalDirectionLabel,
            ),
            items: BodyweightGoal.values
                .map(
                  (goal) => DropdownMenuItem<BodyweightGoal>(
                    value: goal,
                    child: Text(_goalLabel(l10n, goal)),
                  ),
                )
                .toList(growable: false),
            onChanged: (goal) {
              if (goal == null) return;
              setState(() {
                _selectedGoal = goal;
                _selectedTargetRateKgPerWeek =
                    WeeklyTargetRateCatalog.defaultForGoal(goal).kgPerWeek;
                _hasAppliedOnboardingRecommendationToGoals = false;
              });
              _refreshOnboardingRecommendationPreview();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PriorActivityLevel>(
            key: const Key('onboarding_prior_activity_dropdown'),
            initialValue: _selectedPriorActivityLevel,
            decoration: InputDecoration(
              labelText: l10n.adaptivePriorActivityLabel,
            ),
            items: PriorActivityLevel.values
                .map(
                  (level) => DropdownMenuItem<PriorActivityLevel>(
                    value: level,
                    child: Text(_priorActivityLabel(l10n, level)),
                  ),
                )
                .toList(growable: false),
            onChanged: (level) {
              if (level == null) return;
              setState(() {
                _selectedPriorActivityLevel = level;
                _hasAppliedOnboardingRecommendationToGoals = false;
              });
              _refreshOnboardingRecommendationPreview();
            },
          ),
          const SizedBox(height: 12),
          PriorActivityHelpBlock(
            key: const Key('onboarding_prior_activity_help_block'),
            l10n: l10n,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExtraCardioHoursOption>(
            key: const Key('onboarding_extra_cardio_dropdown'),
            initialValue: _selectedExtraCardioHoursOption,
            decoration: InputDecoration(
              labelText: l10n.adaptiveExtraCardioLabel,
            ),
            items: ExtraCardioHoursCatalog.supportedOptions
                .map(
                  (option) => DropdownMenuItem<ExtraCardioHoursOption>(
                    value: option,
                    child: Text(_extraCardioLabel(l10n, option)),
                  ),
                )
                .toList(growable: false),
            onChanged: (option) {
              if (option == null) return;
              setState(() {
                _selectedExtraCardioHoursOption = option;
                _hasAppliedOnboardingRecommendationToGoals = false;
              });
              _refreshOnboardingRecommendationPreview();
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adaptiveExtraCardioHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WeeklyTargetRateCatalog.optionsForGoal(_selectedGoal)
                .map((option) {
              final isSelected =
                  option.kgPerWeek == _selectedTargetRateKgPerWeek;
              return ChoiceChip(
                label: Text(
                  _rateLabel(l10n, option.kgPerWeek),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedTargetRateKgPerWeek = option.kgPerWeek;
                    _hasAppliedOnboardingRecommendationToGoals = false;
                  });
                  _refreshOnboardingRecommendationPreview();
                },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: _isGeneratingOnboardingRecommendation
                ? null
                : _refreshOnboardingRecommendationPreview,
            child: Text(
              _isGeneratingOnboardingRecommendation
                  ? l10n.adaptiveRecommendationGenerating
                  : l10n.adaptiveRecommendationRefresh,
            ),
          ),
          const SizedBox(height: 12),
          _buildOnboardingRecommendationSummary(),
        ],
      ),
    );
  }

  Widget _buildOnboardingRecommendationSummary() {
    final l10n = AppLocalizations.of(context)!;
    final recommendation = _onboardingRecommendation;
    final maintenanceEstimate = _onboardingMaintenanceEstimate;
    if (recommendation == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          l10n.onboardingAdaptiveSummaryEmpty,
        ),
      );
    }
    final warningMessage = RecommendationUiCopy.warningMessage(
      l10n,
      recommendation,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingAdaptiveSummaryTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingAdaptiveSummaryCalories(
              recommendation.recommendedCalories,
            ),
          ),
          Text(
            l10n.onboardingAdaptiveSummaryProtein(
              recommendation.recommendedProteinGrams,
            ),
          ),
          Text(
            l10n.onboardingAdaptiveSummaryCarbs(
              recommendation.recommendedCarbsGrams,
            ),
          ),
          Text(
            l10n.onboardingAdaptiveSummaryFat(
              recommendation.recommendedFatGrams,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingAdaptiveSummaryConfidence(
              RecommendationUiCopy.confidenceLabel(
                l10n,
                recommendation.confidence,
              ),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (maintenanceEstimate != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.adaptiveRecommendationMaintenanceLine(
                recommendation.estimatedMaintenanceCalories,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adaptiveRecommendationMaintenanceRangeLine(
                maintenanceEstimate.credibleIntervalLowerCalories(),
                maintenanceEstimate.credibleIntervalUpperCalories(),
              ),
              key: const Key('onboarding_adaptive_summary_range_line'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              RecommendationUiCopy.uncertaintyHint(l10n, maintenanceEstimate),
              key: const Key('onboarding_adaptive_summary_uncertainty_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (RecommendationUiCopy.isStabilizing(maintenanceEstimate))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.adaptiveRecommendationStabilizingHint,
                  key:
                      const Key('onboarding_adaptive_summary_stabilizing_hint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.adaptiveRecommendationDataBasisLine(
              recommendation.inputSummary.windowDays,
              recommendation.inputSummary.weightLogCount,
              recommendation.inputSummary.intakeLoggedDays,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            RecommendationUiCopy.dataBasisMessage(l10n, recommendation),
            key: const Key('onboarding_adaptive_summary_data_basis_message'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (warningMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: recommendation.warningState.warningLevel ==
                        RecommendationWarningLevel.high
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                warningMessage,
                key: const Key('onboarding_adaptive_summary_warning_text'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _applyOnboardingRecommendationToGoals,
            child: Text(
              _hasAppliedOnboardingRecommendationToGoals
                  ? l10n.onboardingAdaptiveSummaryApplied
                  : l10n.onboardingAdaptiveSummaryApply,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBodyFatHelperEntryPoint() async {
    await showBodyFatGuidanceSheet(context);
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

  Widget _buildCaloriesPage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepTitle(title: l10n.onboardingGoalsTitle, align: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingGoalCalories,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _calController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            decoration: InputDecoration(
              suffixText: 'kcal',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosPage(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(title: "Makronährstoffe"),
          const SizedBox(height: 8),
          Text(
            "Wie setzt sich deine Ernährung zusammen?",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),
          _MacroInput(
            controller: _protController,
            label: l10n.onboardingGoalProtein,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          _MacroInput(
            controller: _carbController,
            label: l10n.onboardingGoalCarbs,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _MacroInput(
            controller: _fatController,
            label: l10n.onboardingGoalFat,
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildWaterPage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepTitle(title: l10n.onboardingGoalWater, align: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _waterController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              suffixText: 'ml',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final TextAlign align;
  const _StepTitle({required this.title, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: align,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _MacroInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;
  const _MacroInput({
    required this.controller,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 1,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: const InputDecoration(
              suffixText: ' g',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
