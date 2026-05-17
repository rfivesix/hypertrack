import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/screens/onboarding_screen.dart';
import 'package:train_libre/services/unit_service.dart';

// Because we're not running full app, we need the actual generated file or mock it.
// Here we use the real one if it compiles
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets('OnboardingScreen initial flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<UnitService>(
          create: (_) => UnitService(),
          child: const OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final button = find.byKey(const Key('onboarding_continue_setup_button'));
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();

    // Now on page 1: Unit System. Need to tap Next to go to Profile.
    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    expect(textFields, findsWidgets);
  });
}
