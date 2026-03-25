// lib/screens/app_initializer_screen.dart

import 'package:flutter/material.dart';
import '../data/backup_manager.dart';
import '../data/basis_data_manager.dart';
// import '../generated/app_localizations.dart'; // Not required here because status text is dynamic.
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A splash screen responsible for app-wide initialization.
///
/// It handles database updates, auto-backup checks, and determines
/// whether to navigate to [OnboardingScreen] or [MainScreen].
class AppInitializerScreen extends StatefulWidget {
  const AppInitializerScreen({super.key});

  @override
  State<AppInitializerScreen> createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends State<AppInitializerScreen> {
  // UI state displayed while initialization is running.
  String _currentTask = "Starting app...";
  String _currentDetail = "Initializing...";
  double _progress = 0.0;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    // Start initialization right after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    // 1) Run basis-data update checks and stream progress to the UI.
    await BasisDataManager.instance.checkForBasisDataUpdate(
      force: false,
      onProgress: (task, detail, progress) {
        if (!mounted) return;
        setState(() {
          _currentTask = task;
          _currentDetail = detail;
          _progress = progress;
        });
      },
    );

    // Show completion feedback before navigation.
    if (mounted) {
      setState(() {
        _currentTask = "Finalizing";
        _currentDetail = "Checking backups...";
        _progress = 1.0;
      });
    }

    // 2) Trigger due auto-backup checks.
    try {
      await BackupManager.instance.runAutoBackupIfDue();
    } catch (e) {
      debugPrint("Auto-backup startup failed: $e");
    }

    // 3) Decide target route based on onboarding state.
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') == true;

    if (!mounted) return;

    // Navigate to the next screen.
    setState(() => _isDone = true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            hasSeenOnboarding ? const MainScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If initialization is done, render an empty container until navigation completes.
    if (_isDone) {
      return Container(color: Theme.of(context).scaffoldBackgroundColor);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon shown during startup.
            Icon(
              Icons.system_update_alt_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 40),

            // Main status text.
            Text(
              _currentTask,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress > 0
                    ? _progress
                    : null, // null renders an indeterminate spinner style.
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Secondary detail text.
            Text(
              _currentDetail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
