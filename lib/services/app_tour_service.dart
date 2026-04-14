import 'package:shared_preferences/shared_preferences.dart';

/// Entry trigger describing how the app tour should start.
enum AppTourEntryPoint {
  postOnboardingOffer,
  settingsRestart,
}

/// Persisted progress metadata for the lightweight app tour.
class AppTourProgress {
  final bool hasBeenOffered;
  final bool wasCompleted;
  final bool wasSkipped;

  const AppTourProgress({
    required this.hasBeenOffered,
    required this.wasCompleted,
    required this.wasSkipped,
  });
}

/// Handles app-tour persistence and start triggers.
class AppTourService {
  AppTourService._();

  static final AppTourService instance = AppTourService._();

  static const String offeredKey = 'app_tour_offered';
  static const String completedKey = 'app_tour_completed';
  static const String skippedKey = 'app_tour_skipped';
  static const String pendingOfferKey = 'app_tour_pending_offer';
  static const String pendingStartKey = 'app_tour_pending_start';

  Future<void> queuePostOnboardingOffer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pendingOfferKey, true);
  }

  Future<void> requestRestartFromSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pendingStartKey, true);
    await prefs.setBool(pendingOfferKey, false);
    await prefs.setBool(offeredKey, true);
    await prefs.setBool(completedKey, false);
    await prefs.setBool(skippedKey, false);
  }

  Future<AppTourEntryPoint?> consumePendingEntryPoint() async {
    final prefs = await SharedPreferences.getInstance();

    final hasPendingStart = prefs.getBool(pendingStartKey) ?? false;
    if (hasPendingStart) {
      await prefs.setBool(pendingStartKey, false);
      return AppTourEntryPoint.settingsRestart;
    }

    final hasPendingOffer = prefs.getBool(pendingOfferKey) ?? false;
    if (hasPendingOffer) {
      await prefs.setBool(pendingOfferKey, false);
      return AppTourEntryPoint.postOnboardingOffer;
    }

    return null;
  }

  Future<void> markOfferShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(offeredKey, true);
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(offeredKey, true);
    await prefs.setBool(completedKey, true);
    await prefs.setBool(skippedKey, false);
  }

  Future<void> markSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(offeredKey, true);
    await prefs.setBool(skippedKey, true);
    await prefs.setBool(completedKey, false);
  }

  Future<AppTourProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return AppTourProgress(
      hasBeenOffered: prefs.getBool(offeredKey) ?? false,
      wasCompleted: prefs.getBool(completedKey) ?? false,
      wasSkipped: prefs.getBool(skippedKey) ?? false,
    );
  }
}
