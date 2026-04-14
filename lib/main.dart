// lib/main.dart

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/database_helper.dart';
import 'features/sleep/presentation/sleep_navigation.dart';
import 'generated/app_localizations.dart';
import 'navigation/app_route_observer.dart';
// App startup routing is delegated to the dedicated initializer screen.
import 'screens/app_initializer_screen.dart';
import 'services/profile_service.dart';
import 'services/local_notification_service.dart';
import 'services/workout_session_manager.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'package:intl/date_symbol_data_local.dart'; // FIX: Initialize intl formatting

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: Ensures DateFormat does not throw LocaleDataException on non-en_US locales.
  await initializeDateFormatting();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Ensure baseline data and local notifications are ready before app startup.
  await DatabaseHelper.instance.ensureStandardSupplements();
  await LocalNotificationService.instance.initialize();

  // Create and warm up the workout session manager before injecting it.
  final workoutSessionManager = WorkoutSessionManager();

  // Restore an unfinished workout session (if any) as part of cold start.
  await workoutSessionManager.tryRestoreSession();

  final themeService = ThemeService(); // Create an instance

  // Start the app with all required providers.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: workoutSessionManager),
        ChangeNotifierProvider(
          create: (context) {
            final profileService = ProfileService();
            profileService.initialize();
            return profileService;
          },
        ),
        ChangeNotifierProvider.value(value: themeService),
      ],
      child: const MyApp(),
    ),
  );

  // Background update checks are handled by AppInitializerScreen.
}

/// The entry point of the Hypertrack application.
///
/// This application is a fitness tracker that allows users to log workouts,
/// manage supplements, and track body measurements.
class MyApp extends StatefulWidget {
  /// Creates the root widget for the application.
  const MyApp({super.key});

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
    const brandAccentColor = Color(0xFFDDFF00);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final themeService = context.watch<ThemeService>();
        final isAndroid =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
        final useDynamicMaterialColors =
            isAndroid && themeService.materialColorsEnabled;

        // Use brand accent by default; optional Android toggle enables dynamic Material colors.
        final Color lightSeed = useDynamicMaterialColors
            ? (lightDynamic?.primary ?? brandAccentColor)
            : brandAccentColor;
        final Color darkSeed = useDynamicMaterialColors
            ? (darkDynamic?.primary ?? lightSeed)
            : brandAccentColor;

        // --- Light Scheme aus Seed, aber ohne Material You UI ---
        final lightScheme = ColorScheme.fromSeed(
          seedColor: lightSeed,
          brightness: Brightness.light,
        ).copyWith(surface: Colors.white);

        // --- Dark Scheme aus Seed + OLED-Schwarz ---
        final seededDark = ColorScheme.fromSeed(
          seedColor: darkSeed,
          brightness: Brightness.dark,
        );
        final darkScheme = seededDark.copyWith(
          surface: Colors.black,
          surfaceDim: Colors.black,
          surfaceBright: Colors.black,
          surfaceContainerLowest: Colors.black,
          surfaceContainerLow: Colors.black,
          surfaceContainer: Colors.black,
          surfaceContainerHigh: Colors.black,
          surfaceContainerHighest: Colors.black,
        );

        // --- Light Theme (Material2, aber mit ColorScheme aus Seed) ---
        final baseLightTheme = ThemeData(
          useMaterial3: false, // KEIN Material You
          colorScheme: lightScheme,
          primaryColor: lightScheme.primary, // Akzent in M2-Welten
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
            color: Colors.black.withOpacity(0.08),
            thickness: 1,
            space: 24,
          ),

          textTheme: ThemeData.light().textTheme.apply(
                fontFamily: 'Inter',
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
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
            selectionColor: lightScheme.primary.withOpacity(0.25),
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
              (s) => lightScheme.primary.withOpacity(0.5),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: cardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );

        // --- Dark Theme (Material2, OLED, Akzent aus Seed) ---
        final baseDarkTheme = ThemeData(
          useMaterial3: false, // KEIN Material You
          colorScheme: darkScheme,
          primaryColor: darkScheme.primary, // Akzent in M2-Welten
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
            color: Colors.white.withOpacity(0.08),
            thickness: 1,
            space: 24,
          ),

          textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'Inter',
                bodyColor: Colors.white,
                displayColor: Colors.white,
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
            selectionColor: darkScheme.primary.withOpacity(0.35),
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
              (s) => darkScheme.primary.withOpacity(0.5),
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
          title: "Hypertrack",
          theme: baseLightTheme,
          darkTheme: baseDarkTheme,
          themeMode: themeService.themeMode,
          onGenerateRoute: SleepNavigation.onGenerateRoute,
          // FIX: Hier wird nun der ausgelagerte Screen verwendet
          home: const AppInitializerScreen(),
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
    // Keine Glow-Effekte
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // iOS-Style: Bouncing
    return const BouncingScrollPhysics();
  }
}
