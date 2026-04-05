import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart' show AppDatabase;
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/screens/goals_screen.dart';
import 'package:hypertrack/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('adaptive recommendation settings flows', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late AdaptiveNutritionRecommendationService recommendationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      recommendationService = AdaptiveNutritionRecommendationService(
        repository: RecommendationRepository(),
        databaseHelper: dbHelper,
      );
      await dbHelper.saveUserGoals(
        calories: 2400,
        protein: 170,
        carbs: 260,
        fat: 75,
        water: 3000,
        steps: 8000,
      );
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('goals screen keeps adaptive sections above daily goals',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GoalsScreen(
            recommendationService: recommendationService,
            databaseHelper: dbHelper,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final adaptiveSection =
          find.byKey(const Key('goals_adaptive_section_title'));
      final personalSection =
          find.byKey(const Key('goals_personal_section_title'));
      final recommendationSettingsSection = find.byKey(
        const Key('goals_recommendation_settings_section_title'),
      );
      final dailyGoalsSection =
          find.byKey(const Key('goals_daily_section_title'));
      final heightField = find.byKey(const Key('goals_height_field'));

      expect(personalSection, findsOneWidget);
      expect(adaptiveSection, findsOneWidget);
      expect(recommendationSettingsSection, findsOneWidget);
      expect(dailyGoalsSection, findsOneWidget);
      expect(heightField, findsOneWidget);
      expect(find.byKey(const Key('goals_prior_activity_dropdown')),
          findsOneWidget);
      expect(
          find.byKey(const Key('goals_extra_cardio_dropdown')), findsOneWidget);

      final personalTop = tester.getTopLeft(personalSection).dy;
      final heightFieldTop = tester.getTopLeft(heightField).dy;
      final adaptiveTop = tester.getTopLeft(adaptiveSection).dy;
      final settingsTop = tester.getTopLeft(recommendationSettingsSection).dy;
      final dailyTop = tester.getTopLeft(dailyGoalsSection).dy;

      expect(personalTop, lessThan(adaptiveTop));
      expect(heightFieldTop, lessThan(adaptiveTop));
      expect(adaptiveTop, lessThan(settingsTop));
      expect(settingsTop, lessThan(dailyTop));
    });

    testWidgets('onboarding shows body-fat helper and cardio-hours selector',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(
            recommendationService: recommendationService,
            databaseHelper: dbHelper,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('onboarding_continue_setup_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('onboarding_body_fat_helper_text')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_body_fat_help_button')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')),
        'Alex',
      );
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('onboarding_extra_cardio_dropdown')),
        findsOneWidget,
      );
    });
  });
}
