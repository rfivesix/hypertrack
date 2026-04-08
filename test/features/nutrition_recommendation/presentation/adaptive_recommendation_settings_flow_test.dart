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

    testWidgets(
        'onboarding flow includes dedicated body-fat page after bodyweight',
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
      await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')),
        'Alex',
      );
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_weight_page')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_body_fat_page')), findsOneWidget);
      expect(
        find.byKey(const Key('onboarding_body_fat_helper_text')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_body_fat_help_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('onboarding_adaptive_goal_page')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_extra_cardio_dropdown')),
        findsOneWidget,
      );
    });

    testWidgets(
        'onboarding body-fat help opens guidance and shows male/female texts',
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

      await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')),
        'Alex',
      );
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      final bodyFatHelpButton =
          find.byKey(const Key('onboarding_body_fat_help_button'));
      await tester.tap(bodyFatHelpButton);
      await tester.pumpAndSettle();

      final sheet = find.byKey(const Key('body_fat_guidance_sheet'));
      expect(sheet, findsOneWidget);

      final context = tester.element(sheet);
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.bodyFatGuidanceTitle), findsOneWidget);
      expect(find.text(l10n.bodyFatGuidanceMale10), findsOneWidget);

      await tester.tap(find.byKey(const Key('body_fat_guidance_sex_female')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.bodyFatGuidanceFemale15), findsOneWidget);
    });

    testWidgets(
        'prior activity dropdowns include the very-high activity option',
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

      final onboardingContext = tester.element(find.byType(OnboardingScreen));
      final l10n = AppLocalizations.of(onboardingContext)!;

      await tester
          .tap(find.byKey(const Key('onboarding_continue_setup_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')),
        'Alex',
      );
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      final onboardingDropdown =
          find.byKey(const Key('onboarding_prior_activity_dropdown'));
      expect(onboardingDropdown, findsOneWidget);
      await tester.tap(onboardingDropdown);
      await tester.pumpAndSettle();
      expect(find.text(l10n.adaptivePriorActivityVeryHigh), findsOneWidget);
      await tester.tap(find.text(l10n.adaptivePriorActivityVeryHigh).last);
      await tester.pumpAndSettle();

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

      final goalsDropdown =
          find.byKey(const Key('goals_prior_activity_dropdown'));
      expect(goalsDropdown, findsOneWidget);
      await tester.tap(goalsDropdown);
      await tester.pumpAndSettle();
      expect(find.text(l10n.adaptivePriorActivityVeryHigh), findsOneWidget);
    });

    testWidgets('onboarding preview surfaces prior-only data basis state',
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
      await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')),
        'Alex',
      );
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(OnboardingScreen));
      final l10n = AppLocalizations.of(context)!;
      expect(
        find.byKey(const Key('onboarding_adaptive_summary_data_basis_message')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.adaptiveRecommendationDataBasisHintPriorOnly),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_adaptive_summary_stabilizing_hint')),
        findsOneWidget,
      );
    });

    testWidgets('onboarding final page shows finish action', (tester) async {
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

      final context = tester.element(find.byType(OnboardingScreen));
      final l10n = AppLocalizations.of(context)!;
      final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));

      await tester
          .tap(find.byKey(const Key('onboarding_continue_setup_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')),
        'Alex',
      );
      await tester.tap(nextButton); // profile -> weight
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // weight -> body fat
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // body fat -> adaptive
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // adaptive -> calories
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // calories -> macros
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // macros -> water
      await tester.pumpAndSettle();

      expect(find.text(l10n.onboardingFinish.toUpperCase()), findsOneWidget);
    });
  });
}
