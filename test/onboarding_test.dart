import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hypertrack/screens/onboarding_screen.dart';

// Because we're not running full app, we need the actual generated file or mock it.
// Here we use the real one if it compiles
import 'package:hypertrack/generated/app_localizations.dart';

void main() {
  testWidgets('OnboardingScreen initial flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OnboardingScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final button = find.byType(ElevatedButton).first;
    expect(button, findsOneWidget);

    print('Tapped button...');
    await tester.tap(button);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    print('Found TextFields: ${textFields.evaluate().length}');
  });
}
