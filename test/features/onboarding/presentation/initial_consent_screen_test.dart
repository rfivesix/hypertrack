import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/onboarding/presentation/initial_consent_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('InitialConsentScreen button remains disabled until both checkboxes are checked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const InitialConsentScreen(nextScreen: Text('Next Screen')),
      ),
    );
    await tester.pumpAndSettle();

    final nextButton = find.byType(FilledButton);
    expect(nextButton, findsOneWidget);
    
    // Check if button is disabled
    var button = tester.widget<FilledButton>(nextButton);
    expect(button.onPressed, isNull);

    // Find and tap the privacy policy checkbox
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(2));

    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();

    // Still disabled
    button = tester.widget<FilledButton>(nextButton);
    expect(button.onPressed, isNull);

    // Tap second checkbox (Terms of Service)
    await tester.tap(checkboxes.last);
    await tester.pumpAndSettle();

    // Now enabled
    button = tester.widget<FilledButton>(nextButton);
    expect(button.onPressed, isNotNull);
  });
}
