// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/backup_manager.dart';
import '../data/database_helper.dart';
import '../generated/app_localizations.dart';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// The initial setup flow for new users.
///
/// Collects user profile data (name, DOB, anthropometrics) and initial
/// nutrition/health goals to populate the database and preferences.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;
  bool _isRestoring = false;

  // --- CONTROLLER ---
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _heightController =
      TextEditingController(); // NEU
  String? _selectedGender; // NEU (male, female, diverse)

  final TextEditingController _weightController = TextEditingController();

  final TextEditingController _calController =
      TextEditingController(text: '2500');
  final TextEditingController _protController =
      TextEditingController(text: '180');
  final TextEditingController _carbController =
      TextEditingController(text: '250');
  final TextEditingController _fatController =
      TextEditingController(text: '80');
  final TextEditingController _waterController =
      TextEditingController(text: '3000');

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
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

  Future<void> _finishOnboarding() async {
    final db = DatabaseHelper.instance;
    final prefs = await SharedPreferences.getInstance();

    final int calories = int.tryParse(_calController.text) ?? 2500;
    final int protein = int.tryParse(_protController.text) ?? 180;
    final int carbs = int.tryParse(_carbController.text) ?? 250;
    final int fat = int.tryParse(_fatController.text) ?? 80;
    final int water = int.tryParse(_waterController.text) ?? 3000;
    final int? height = int.tryParse(_heightController.text);

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
    final double? weight =
        double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight != null) {
      await db.saveInitialWeight(weight);
    }

    // 3. Ziele speichern (DB - DAS IST JETZT DIE QUELLE FÜR ALLES)
    await db.saveUserGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      water: water,
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

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  /// Lets the user pick a backup JSON file and import it, skipping onboarding.
  Future<void> _restoreFromBackup() async {
    final l10n = AppLocalizations.of(context)!;

    final result = await FilePicker.platform.pickFiles(
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingRestoreSuccess)),
      );
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
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogEnterPasswordImport),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.passwordLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.onboardingNext),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 1) {
      if (_nameController.text.trim().isEmpty) return;
    }

    if (_currentPage < _totalPages) {
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
              value: (_currentPage + 1) / (_totalPages + 1),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 4,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(l10n),
                  _buildProfilePage(l10n), // <-- Hier ist das Update
                  _buildWeightPage(l10n),
                  _buildCaloriesPage(l10n),
                  _buildMacrosPage(l10n),
                  _buildWaterPage(l10n),
                  _buildFinishPage(l10n),
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
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentPage == _totalPages
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
          Icon(Icons.waving_hand_rounded,
              size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWelcomeTitle,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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
              onPressed: _isRestoring ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATE: PROFILE PAGE MIT GRÖSSE & GESCHLECHT ---
  Widget _buildProfilePage(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _StepTitle(title: l10n.onboardingNameTitle),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              prefixIcon: const Icon(Icons.person_outline),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.onboardingDobLabel,
                prefixIcon: const Icon(Icons.cake_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedDate == null
                    ? 'DD.MM.YYYY'
                    : DateFormat.yMMMd(
                            Localizations.localeOf(context).toString())
                        .format(_selectedDate!),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // GRÖSSE & GESCHLECHT NEBENEINANDER
          Row(
            children: [
              // GRÖSSE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StepTitle(
                        title: "Größe"), // oder l10n.onboardingHeightLabel
                    const SizedBox(height: 8),
                    TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "cm",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // GESCHLECHT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StepTitle(
                        title: "Geschlecht"), // oder l10n.onboardingGenderLabel
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'male', child: Text(l10n.genderMale)),
                        DropdownMenuItem(
                            value: 'female', child: Text(l10n.genderFemale)),
                        DropdownMenuItem(
                            value: 'diverse', child: Text(l10n.genderDiverse)),
                      ],
                      onChanged: (val) => setState(() => _selectedGender = val),
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepTitle(
              title: l10n.onboardingWeightTitle, align: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: 'kg',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesPage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepTitle(title: l10n.onboardingGoalsTitle, align: TextAlign.center),
          const SizedBox(height: 8),
          Text(l10n.onboardingGoalCalories,
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 32),
          TextField(
            controller: _calController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.orange),
            decoration: InputDecoration(
              suffixText: 'kcal',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
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
              color: Colors.redAccent),
          const SizedBox(height: 16),
          _MacroInput(
              controller: _carbController,
              label: l10n.onboardingGoalCarbs,
              color: Colors.green),
          const SizedBox(height: 16),
          _MacroInput(
              controller: _fatController,
              label: l10n.onboardingGoalFat,
              color: Colors.blueAccent),
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
                fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
            decoration: InputDecoration(
              suffixText: 'ml',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishPage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingFinish,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingGoalsSubtitle,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
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
    return Text(title,
        textAlign: align,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _MacroInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;
  const _MacroInput(
      {required this.controller, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold))),
        Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
              decoration: const InputDecoration(
                  suffixText: ' g',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            )),
      ],
    );
  }
}
