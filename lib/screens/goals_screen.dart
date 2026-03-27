// lib/screens/goals_screen.dart

import 'package:flutter/material.dart';
import '../util/design_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';
import '../widgets/global_app_bar.dart';
import '../data/database_helper.dart';

/// A screen for defining daily health and nutrition targets.
///
/// Users can set goals for calories, macronutrients (protein, carbs, fat),
/// water intake, and other detailed metrics like sugar or fiber.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

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
    final dbHelper = DatabaseHelper.instance;
    final prefs = await SharedPreferences
        .getInstance(); // Nur noch für Height gebraucht falls nicht im Profil

    // Lade Ziele aus der DB
    final settings = await dbHelper.getAppSettings();
    final targetSteps = await dbHelper.getCurrentTargetStepsOrDefault();
    // Lade Profil für Größe
    // (Optional: Du könntest auch 'getProfile' im Helper bauen, aber prefs für Height ist ok als Übergang)

    setState(() {
      _heightController.text = (prefs.getInt('userHeight') ?? 180).toString();

      // Werte aus DB oder Default
      _caloriesController.text = (settings?.targetCalories ?? 2500).toString();
      _proteinController.text = (settings?.targetProtein ?? 180).toString();
      _carbsController.text = (settings?.targetCarbs ?? 250).toString();
      _fatController.text = (settings?.targetFat ?? 80).toString();
      _waterController.text = (settings?.targetWater ?? 3000).toString();
      _stepsController.text = targetSteps.toString();

      // Hinweis: Sugar, Fiber, Salt sind noch nicht im AppSettings Schema von Drift definiert?
      // Falls du diese auch syncen willst, musst du die Tabelle AppSettings in drift_database.dart erweitern.
      // Vorerst laden wir diese noch aus Prefs, da sie im Schema fehlten:
      _sugarController.text = (prefs.getInt('targetSugar') ?? 50).toString();
      _fiberController.text = (prefs.getInt('targetFiber') ?? 30).toString();
      _saltController.text = (prefs.getInt('targetSalt') ?? 6).toString();

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Größe in Prefs (oder später DB Profile update)
    await prefs.setInt('userHeight', int.parse(_heightController.text));

    // 2. WICHTIG: Ziele in die Datenbank speichern
    await DatabaseHelper.instance.saveUserGoals(
      calories: int.parse(_caloriesController.text),
      protein: int.parse(_proteinController.text),
      carbs: int.parse(_carbsController.text),
      fat: int.parse(_fatController.text),
      water: int.parse(_waterController.text),
      steps: int.parse(_stepsController.text),
    );

    // 3. Die "Extra"-Werte (Sugar/Fiber/Salt) bleiben vorerst in Prefs,
    // bis du das DB-Schema erweiterst (Empfehlung für später).
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

      // NEU: Unsere GlobalAppBar
      appBar: GlobalAppBar(
        title: l10n.my_goals,
        actions: [
          // Der Save-Button bleibt, nur etwas anders verpackt
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
              // Die neue Padding-Logik
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
                    _buildSectionTitle(context, l10n.personalDataCL),
                    const SizedBox(height: DesignConstants.spacingM),
                    _buildSettingsField(
                      controller: _heightController,
                      label: l10n.profileUserHeight,
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildSectionTitle(context, l10n.profileDailyGoalsCL),
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
                      label: 'Steps', // TODO(alpha): localize steps label
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

                    // KORREKTUR: Der untere Button wurde entfernt
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSettingsField({
    required TextEditingController controller,
    required String label,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
