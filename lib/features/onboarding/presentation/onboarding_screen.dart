// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/infrastructure/backup_manager.dart';
import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../app/presentation/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../nutrition_recommendation/presentation/body_fat_guidance_sheet.dart';
import '../../nutrition_recommendation/domain/goal_models.dart';
import '../../nutrition_recommendation/domain/recommendation_models.dart';
import '../../../services/app_tour_service.dart';
import '../../../services/unit_service.dart';
import '../../../services/profile_service.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../../profile/domain/models/user_gender.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'widgets/welcome_slide.dart';
import 'widgets/unit_system_slide.dart';
import 'widgets/profile_slide.dart';
import 'widgets/weight_slide.dart';
import 'widgets/body_fat_slide.dart';
import 'widgets/adaptive_goal_slide.dart';
import 'widgets/macro_slide.dart';
import 'widgets/water_slide.dart';

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
  static const int _profilePageIndex = 2;
  static const int _adaptiveGoalPageIndex = 5;
  static const int _pageCount = 9;
  static const int _lastPageIndex = _pageCount - 1;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRestoring = false;
  bool _isGeneratingOnboardingRecommendation = false;
  Future<void>? _onboardingRecommendationFuture;
  UnitSystem? _selectedUnitSystem;

  late final AdaptiveNutritionRecommendationService _recommendationService;
  late final DatabaseHelper _databaseHelper;
  BodyweightGoal _selectedGoal = BodyweightGoal.maintainWeight;
  double _selectedTargetRateKgPerWeek = WeeklyTargetRateCatalog.defaultForGoal(
    BodyweightGoal.maintainWeight,
  ).kgPerWeek;
  NutritionRecommendation? _onboardingRecommendation;

  // --- CONTROLLER ---
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _heightController =
      TextEditingController(); // New
  String? _selectedGender; // New (male, female, diverse)
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

  UnitService get _unitService => context.read<UnitService>();

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
    if (_isGeneratingOnboardingRecommendation &&
        _onboardingRecommendationFuture != null) {
      return _onboardingRecommendationFuture!;
    }

    _onboardingRecommendationFuture = _performRefreshOnboardingRecommendation();
    return _onboardingRecommendationFuture!;
  }

  Future<void> _performRefreshOnboardingRecommendation() async {
    setState(() => _isGeneratingOnboardingRecommendation = true);

    final unitService = _unitService;
    final weightInput = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final heightInput = double.tryParse(
      _heightController.text.replaceAll(',', '.'),
    );
    final weight = weightInput == null
        ? null
        : unitService.convertToMetric(weightInput, UnitDimension.weight);
    final height = heightInput == null
        ? null
        : unitService
            .convertToMetric(heightInput, UnitDimension.height)
            .round();
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
      });
    } catch (e) {
      debugPrint('Error refreshing onboarding recommendation: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingOnboardingRecommendation = false);
      }
    }
  }

  void _applyOnboardingRecommendationToGoals() {
    final recommendation = _onboardingRecommendation;
    if (recommendation == null) return;

    final unitService = _unitService;
    final weightInput = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final weightKg = weightInput == null
        ? null
        : unitService.convertToMetric(weightInput, UnitDimension.weight);

    setState(() {
      _calController.text = recommendation.recommendedCalories.toString();
      _protController.text = recommendation.recommendedProteinGrams.toString();
      _carbController.text = recommendation.recommendedCarbsGrams.toString();
      _fatController.text = recommendation.recommendedFatGrams.toString();

      if (weightKg != null) {
        final waterMl = (weightKg / 20.0) * 1000.0;
        final displayWater = unitService.convertDisplayValue(
          waterMl,
          UnitDimension.liquid,
        );
        _waterController.text = displayWater.round().toString();
      }
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

  Future<void> _requestStepsPermission() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.health_permission_dialog_title,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                l10n.health_permission_dialog_body,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(false);
                    },
                    child: Text(l10n.health_permission_not_now),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text(l10n.health_permission_continue),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await StepsSyncService().requestPermissions();
    }
  }

  Future<void> _finishOnboarding() async {
    final db = _databaseHelper;
    final prefs = await SharedPreferences.getInstance();
    final unitService = _unitService;

    final int calories = int.tryParse(_calController.text) ?? 2500;
    final int protein = int.tryParse(_protController.text) ?? 180;
    final int carbs = int.tryParse(_carbController.text) ?? 250;
    final int fat = int.tryParse(_fatController.text) ?? 80;
    final double? waterInput = double.tryParse(
      _waterController.text.replaceAll(',', '.'),
    );
    final double? heightInput = double.tryParse(
      _heightController.text.replaceAll(',', '.'),
    );
    final double? weightInput = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final double? bodyFatPercent = double.tryParse(
      _bodyFatPercentController.text.replaceAll(',', '.'),
    );
    final int? height = heightInput == null
        ? null
        : unitService
            .convertToMetric(heightInput, UnitDimension.height)
            .round();
    final double? weight = weightInput == null
        ? null
        : unitService.convertToMetric(weightInput, UnitDimension.weight);

    final int water = waterInput == null
        ? (weight != null ? ((weight / 20.0) * 1000.0).round() : 3000)
        : unitService.convertToMetric(waterInput, UnitDimension.liquid).round();

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

    await _requestStepsPermission();

    // 1. Save profile (DB)
    await db.saveUserProfile(
      name: _nameController.text.trim(),
      birthday: _selectedDate,
      height: height,
      gender: _selectedGender,
    );

    if (_selectedGender != null && mounted) {
      await context.read<ProfileService>().updateGender(
            UserGender.fromString(_selectedGender),
            context.read<IProfileRepository>(),
          );
    }

    // Also cache height briefly in prefs for GoalsScreen fallback (optional).
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

    // 3. Save goals (DB - this is now the source for everything).
    await db.saveUserGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      water: water,
      steps: 8000,
    );

    // 4. Store default extra values (sugar/fiber/salt) in prefs because they are not in the DB schema yet.
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

  Future<void> _nextPage() async {
    if (_currentPage == _profilePageIndex) {
      if (_nameController.text.trim().isEmpty) return;
    }

    if (_currentPage == _adaptiveGoalPageIndex) {
      // Ensure we have a recommendation and apply it automatically.
      await _refreshOnboardingRecommendationPreview();
      _applyOnboardingRecommendationToGoals();
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
                  WelcomeSlide(
                    isRestoring: _isRestoring,
                    onContinue: _nextPage,
                    onRestore: _restoreFromBackup,
                  ),
                  UnitSystemSlide(
                    selectedSystem: _selectedUnitSystem ?? context.read<UnitService>().unitSystem,
                    onSelectSystem: _selectUnitSystem,
                  ),
                  ProfileSlide(
                    nameController: _nameController,
                    selectedDate: _selectedDate,
                    heightController: _heightController,
                    selectedGender: _selectedGender,
                    onSelectDate: (picked) {
                      setState(() => _selectedDate = picked);
                      if (_currentPage >= _adaptiveGoalPageIndex) {
                        _refreshOnboardingRecommendationPreview();
                      }
                    },
                    onSelectGender: (val) {
                      setState(() => _selectedGender = val);
                    },
                  ),
                  WeightSlide(
                    weightController: _weightController,
                  ),
                  BodyFatSlide(
                    bodyFatPercentController: _bodyFatPercentController,
                    onChanged: (_) {
                      if (_currentPage >= _adaptiveGoalPageIndex) {
                        _refreshOnboardingRecommendationPreview();
                      }
                    },
                    onOpenHelp: _openBodyFatHelperEntryPoint,
                  ),
                  AdaptiveGoalSlide(
                    selectedGoal: _selectedGoal,
                    selectedPriorActivityLevel: _selectedPriorActivityLevel,
                    selectedExtraCardioHoursOption: _selectedExtraCardioHoursOption,
                    selectedTargetRateKgPerWeek: _selectedTargetRateKgPerWeek,
                    onGoalChanged: (goal) {
                      setState(() {
                        _selectedGoal = goal;
                        _selectedTargetRateKgPerWeek =
                            WeeklyTargetRateCatalog.defaultForGoal(goal).kgPerWeek;
                      });
                      _refreshOnboardingRecommendationPreview();
                    },
                    onPriorActivityLevelChanged: (level) {
                      setState(() {
                        _selectedPriorActivityLevel = level;
                      });
                      _refreshOnboardingRecommendationPreview();
                    },
                    onExtraCardioHoursOptionChanged: (option) {
                      setState(() {
                        _selectedExtraCardioHoursOption = option;
                      });
                      _refreshOnboardingRecommendationPreview();
                    },
                    onTargetRateKgPerWeekChanged: (rate) {
                      setState(() {
                        _selectedTargetRateKgPerWeek = rate;
                      });
                      _refreshOnboardingRecommendationPreview();
                    },
                  ),
                  OnboardingCaloriesSlide(
                    calController: _calController,
                  ),
                  OnboardingMacrosSlide(
                    protController: _protController,
                    carbController: _carbController,
                    fatController: _fatController,
                  ),
                  WaterSlide(
                    waterController: _waterController,
                  ),
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
                      onPressed: _isGeneratingOnboardingRecommendation
                          ? null
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isGeneratingOnboardingRecommendation &&
                              _currentPage == _adaptiveGoalPageIndex
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentPage == _lastPageIndex
                                  ? l10n.onboardingFinish.toUpperCase()
                                  : l10n.onboardingNext.toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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

  Future<void> _selectUnitSystem(UnitSystem system) async {
    setState(() => _selectedUnitSystem = system);
    await _unitService.setUnitSystem(system);

    // Update default values based on system to avoid "3000 fl oz" or "100 ml"
    if (system == UnitSystem.imperial) {
      if (_waterController.text == '3000') {
        _waterController.text = '100'; // ~3L in fl oz
      }
    } else {
      if (_waterController.text == '100') {
        _waterController.text = '3000'; // ~100 fl oz in ml
      }
    }

    if (!mounted) return;
    await _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openBodyFatHelperEntryPoint() async {
    await showBodyFatGuidanceSheet(context);
  }
}
