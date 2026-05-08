import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../data/workout_database_helper.dart';
import 'ai_service.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

abstract class LocalAppDataResetter {
  Future<LocalAppDataResetReport> deleteAllLocalAppData();
}

class LocalAppDataResetReport {
  const LocalAppDataResetReport({
    required this.clearedStores,
    required this.preservedStores,
  });

  final List<String> clearedStores;
  final List<String> preservedStores;
}

class LocalAppDataResetService implements LocalAppDataResetter {
  LocalAppDataResetService({
    DatabaseHelper? databaseHelper,
    WorkoutDatabaseHelper? workoutDatabaseHelper,
    SharedPreferencesLoader? prefsLoader,
    FlutterSecureStorage? secureStorage,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _workoutDatabaseHelper =
            workoutDatabaseHelper ?? WorkoutDatabaseHelper.instance,
        _prefsLoader = prefsLoader ?? SharedPreferences.getInstance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final DatabaseHelper _databaseHelper;
  final WorkoutDatabaseHelper _workoutDatabaseHelper;
  final SharedPreferencesLoader _prefsLoader;
  final FlutterSecureStorage _secureStorage;

  Future<void> _clearAiSecureStorage() async {
    for (final provider in AiProvider.values) {
      await _secureStorage.delete(key: AiService.apiKeyStorageKeyFor(provider));
      await _secureStorage.delete(
        key: AiService.selectedModelStorageKeyFor(provider),
      );
    }
    await _secureStorage.delete(key: AiService.selectedProviderStorageKey);
  }

  @override
  Future<LocalAppDataResetReport> deleteAllLocalAppData() async {
    final prefs = await _prefsLoader();

    await prefs.clear();
    await _databaseHelper.clearAllUserData();
    await _workoutDatabaseHelper.clearAllWorkoutData();
    await _clearAiSecureStorage();

    return const LocalAppDataResetReport(
      clearedStores: [
        'SharedPreferences settings/state',
        'workout logs, routines, set logs, and custom exercises',
        'nutrition logs, meals, hydration, favorites, and custom foods',
        'measurements, supplements, supplement logs, and goals/history',
        'Health step imports and health export status cache',
        'sleep imports/canonical data/derived analyses',
        'pulse aggregate cache',
        'AI provider keys and model selections stored in secure storage',
      ],
      preservedStores: [
        'bundled app assets',
        'bundled/default exercise catalog rows',
        'bundled/base and remote public food catalog sources',
        'data already exported to Apple Health or Health Connect',
        'external provider data and remote public catalog sources',
      ],
    );
  }
}

class CallbackLocalAppDataResetter implements LocalAppDataResetter {
  CallbackLocalAppDataResetter(this.onDelete);

  final Future<LocalAppDataResetReport> Function() onDelete;

  @override
  Future<LocalAppDataResetReport> deleteAllLocalAppData() => onDelete();
}
