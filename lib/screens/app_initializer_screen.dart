// lib/screens/app_initializer_screen.dart

import 'package:flutter/material.dart';
import '../data/backup_manager.dart';
import '../data/basis_data_manager.dart';
// import '../generated/app_localizations.dart'; // Nicht zwingend nötig hier, da wir dynamische Texte anzeigen
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
  // Zustands-Variablen für die UI
  String _currentTask = "Starte App...";
  String _currentDetail = "Initialisierung...";
  double _progress = 0.0;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    // Startet die Initialisierung direkt nach dem ersten Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    // 1. Datenbank-Updates mit Progress-Callback
    // Wir nutzen hier den neuen Callback, um die UI zu aktualisieren.
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

    // Kurzes Feedback vor dem Abschluss
    if (mounted) {
      setState(() {
        _currentTask = "Abschluss";
        _currentDetail = "Prüfe Backups...";
        _progress = 1.0;
      });
    }

    // 2. Backup Check
    try {
      await BackupManager.instance.runAutoBackupIfDue();
    } catch (e) {
      debugPrint("Fehler beim Auto-Backup Start: $e");
    }

    // 3. Onboarding Status prüfen
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') == true;

    if (!mounted) return;

    // Navigation
    setState(() => _isDone = true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            hasSeenOnboarding ? const MainScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Falls wir fertig sind, leeren Container zeigen bis Navigation greift
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
            // Logo oder Icon (optional)
            Icon(
              Icons.system_update_alt_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 40),

            // Haupt-Text (Normal groß)
            Text(
              _currentTask,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Fortschrittsbalken
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress > 0
                    ? _progress
                    : null, // null = Indeterminate wenn 0
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Detail-Text (Klein und grau)
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
