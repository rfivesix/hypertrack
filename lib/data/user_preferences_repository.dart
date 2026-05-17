import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesRepository {
  static final UserPreferencesRepository instance = UserPreferencesRepository._init();
  UserPreferencesRepository._init();

  Future<int?> getTargetSugar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('targetSugar');
  }

  Future<int?> getTargetCaffeine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('targetCaffeine');
  }

  Future<bool> getShowSugarInDiaryOverview() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showSugarInDiaryOverview') ?? false;
  }
}
