// lib/main.dart

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/sleep/presentation/sleep_navigation.dart';
import 'generated/app_localizations.dart';
import 'navigation/app_route_observer.dart';
// App startup routing is delegated to the dedicated initializer screen.
import 'features/app/presentation/app_initializer_screen.dart';
import 'services/profile_service.dart';
import 'services/unit_service.dart';
import 'features/workout/presentation/live_workout_view_model.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'theme/app_colors.dart';
import 'theme/color_constants.dart';
import 'package:intl/date_symbol_data_local.dart'; // FIX: Initialize intl formatting

import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/presentation/initial_consent_screen.dart';

import 'features/diary/domain/repositories/diary_repository.dart';
import 'features/diary/data/nutrition_repository.dart';
import 'features/workout/domain/repositories/workout_repository.dart';
import 'features/workout/data/workout_repository.dart';
import 'features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart';
import 'features/exercise_catalog/data/exercise_catalog_repository.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'data/drift_database.dart' as db;
import 'data/database_helper.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/diary/data/sources/diary_local_data_source.dart';
import 'features/workout/data/sources/workout_local_data_source.dart';
import 'features/exercise_catalog/data/sources/exercise_catalog_local_data_source.dart';
import 'features/profile/data/sources/profile_local_data_source.dart';
import 'features/supplements/domain/repositories/supplement_repository.dart';
import 'features/supplements/data/supplement_repository_impl.dart';
import 'features/supplements/data/sources/supplement_local_data_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: Ensures DateFormat does not throw LocaleDataException on non-en_US locales.
  await initializeDateFormatting();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final hasAcceptedConsent = prefs.getBool('hasAcceptedConsent') ?? false;

  final database = db.AppDatabase();
  DatabaseHelper.setDriftDb(database);
  final diaryLocalDataSource = DiaryLocalDataSource(database);
  final workoutLocalDataSource = WorkoutLocalDataSource(database);
  final exerciseCatalogLocalDataSource =
      ExerciseCatalogLocalDataSource(database);
  final profileLocalDataSource = ProfileLocalDataSource(database);
  final supplementLocalDataSource = SupplementLocalDataSource(database);

  final workoutRepository =
      WorkoutRepository(localDataSource: workoutLocalDataSource);

  // Create the workout session manager before injecting it. Restoration is
  // handled by AppInitializerScreen after the first frame is visible.
  final workoutSessionManager =
      LiveWorkoutViewModel(repository: workoutRepository);

  final themeService = ThemeService(); // Create an instance
  final unitService = UnitService();

  // Start the app with all required providers.
  runApp(
    MultiProvider(
      providers: [
        Provider<IDiaryRepository>(
          create: (_) => NutritionRepository(
            localDataSource: diaryLocalDataSource,
          ),
        ),
        Provider<IWorkoutRepository>.value(value: workoutRepository),
        Provider<SupplementRepository>(
          create: (_) => SupplementRepositoryImpl(
            localDataSource: supplementLocalDataSource,
          ),
        ),
        Provider<IExerciseCatalogRepository>(
          create: (_) => ExerciseCatalogRepository(
            localDataSource: exerciseCatalogLocalDataSource,
          ),
        ),
        Provider<IProfileRepository>(
          create: (_) => ProfileRepository(
            localDataSource: profileLocalDataSource,
          ),
        ),
        ChangeNotifierProvider.value(value: workoutSessionManager),
        ChangeNotifierProvider(
          create: (context) {
            final profileService = ProfileService();
            profileService.initialize();
            return profileService;
          },
        ),
        ChangeNotifierProvider.value(value: unitService),
        ChangeNotifierProvider.value(value: themeService),
      ],
      child: MyApp(
        home: hasAcceptedConsent
            ? const AppInitializerScreen()
            : InitialConsentScreen(nextScreen: const AppInitializerScreen()),
      ),
    ),
  );

  // Background update checks are handled by AppInitializerScreen.
}

/// The entry point of the Train Libre application.
///
/// This application is a fitness tracker that allows users to log workouts,
/// manage supplements, and track body measurements.
class MyApp extends StatefulWidget {
  final Widget home;

  /// Creates the root widget for the application.
  const MyApp({super.key, required this.home});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    const cardDark = Color(0xFF171717);
    const cardLight = Color(0xFFF3F3F3);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final themeService = context.watch<ThemeService>();
        final isAndroid =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
        final useDynamicMaterialColors =
            isAndroid && themeService.materialColorsEnabled;

        // Use brand accent by default; optional Android toggle enables dynamic Material colors.
        final Color lightSeed = useDynamicMaterialColors
            ? (lightDynamic?.primary ?? brandAccentColorLightMode)
            : brandAccentColorLightMode;
        final Color darkSeed = useDynamicMaterialColors
            ? (darkDynamic?.primary ?? brandAccentColor)
            : brandAccentColor;

        // --- Light scheme from seed, but without Material You UI ---
        final lightScheme = ColorScheme.fromSeed(
          seedColor: lightSeed,
          brightness: Brightness.light,
        ).copyWith(
          primary: lightSeed,
          onPrimary: Colors.black,
          surface: Colors.white,
        );

        // --- Dark scheme from seed + OLED black ---
        final seededDark = ColorScheme.fromSeed(
          seedColor: darkSeed,
          brightness: Brightness.dark,
        );
        final darkScheme = seededDark.copyWith(
          primary: darkSeed,
          onPrimary: Colors.black,
          surface: Colors.black,
          surfaceDim: Colors.black,
          surfaceBright: Colors.black,
          surfaceContainerLowest: Colors.black,
          surfaceContainerLow: Colors.black,
          surfaceContainer: Colors.black,
          surfaceContainerHigh: Colors.black,
          surfaceContainerHighest: Colors.black,
        );

        // --- Light theme (Material 2, but with ColorScheme from seed) ---
        final baseLightTheme = ThemeData(
          useMaterial3: false, // No Material You
          colorScheme: lightScheme,
          extensions: [
            AppSurfaces(summaryCard: cardLight),
            MacroColors(
              calories: Colors.orange,
              protein: Colors.red.shade400,
              carbs: Colors.green.shade400,
              fat: Colors.purple.shade300,
              water: Colors.blue,
              sugar: Colors.pink.shade200,
              fiber: Colors.brown.shade400,
              salt: Colors.grey.shade500,
              caffeine: Colors.brown,
            ),
          ],
          primaryColor: lightScheme.primary, // Accent in Material 2 contexts
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
          cardColor: cardLight,

          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            },
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),

          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: cardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            elevation: 0,
          ),

          snackBarTheme: SnackBarThemeData(
            backgroundColor: lightScheme.primary,
            contentTextStyle: TextStyle(
              color: lightScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          dividerTheme: DividerThemeData(
            color: Colors.black.withValues(alpha: 0.08),
            thickness: 1,
            space: 24,
          ),

          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            headlineLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            titleMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.black87,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.black87,
            ),
            bodySmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.black54,
            ),
            labelLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF757575), // grey[600]
              letterSpacing: 0.2,
            ),
            labelMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
            labelSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: lightScheme.primary,
              foregroundColor: lightScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: lightScheme.primary,
            foregroundColor: lightScheme.onPrimary,
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: lightScheme.primary,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: lightScheme.primary,
            selectionColor: lightScheme.primary.withValues(alpha: 0.25),
            selectionHandleColor: lightScheme.primary,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(lightScheme.primary),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.all(lightScheme.primary),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
              (s) => lightScheme.primary,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (s) => lightScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: cardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );

        // --- Dark theme (Material 2, OLED, accent from seed) ---
        final baseDarkTheme = ThemeData(
          useMaterial3: false, // No Material You
          colorScheme: darkScheme,
          extensions: [
            AppSurfaces(summaryCard: cardDark),
            MacroColors(
              calories: Colors.orange,
              protein: Colors.red.shade400,
              carbs: Colors.green.shade400,
              fat: Colors.purple.shade300,
              water: Colors.blue,
              sugar: Colors.pink.shade200,
              fiber: Colors.brown.shade400,
              salt: Colors.grey.shade500,
              caffeine: Colors.brown,
            ),
          ],
          primaryColor: darkScheme.primary, // Accent in Material 2 contexts
          scaffoldBackgroundColor: Colors.black,
          canvasColor: Colors.black,
          cardColor: cardDark,

          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            },
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1C1C1C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),

          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            elevation: 0,
          ),

          snackBarTheme: SnackBarThemeData(
            backgroundColor: darkScheme.primary,
            contentTextStyle: TextStyle(
              color: darkScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          dividerTheme: DividerThemeData(
            color: Colors.white.withValues(alpha: 0.08),
            thickness: 1,
            space: 24,
          ),

          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white,
            ),
            bodySmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white,
            ),
            labelLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            labelMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            labelSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkScheme.primary,
              foregroundColor: darkScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: darkScheme.primary,
            foregroundColor: darkScheme.onPrimary,
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: darkScheme.primary,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: darkScheme.primary,
            selectionColor: darkScheme.primary.withValues(alpha: 0.35),
            selectionHandleColor: darkScheme.primary,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(darkScheme.primary),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.all(darkScheme.primary),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
              (s) => darkScheme.primary,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (s) => darkScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );

        return MaterialApp(
          navigatorKey: _navigatorKey,
          navigatorObservers: [appRouteObserver],
          debugShowCheckedModeBanner: false,
          scrollBehavior: NoGlowScrollBehavior(),
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          title: "Train Libre",
          theme: baseLightTheme,
          darkTheme: baseDarkTheme,
          themeMode: themeService.themeMode,
          onGenerateRoute: SleepNavigation.onGenerateRoute,
          // FIX: The extracted screen is now used here.
          home: widget.home,
        );
      },
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // No glow effects
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // iOS-Style: Bouncing
    return const BouncingScrollPhysics();
  }
}

