import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/services/ai_meal_validation.dart';
import 'package:hypertrack/util/ai_validation_localization.dart';

Future<String> _localizedIssueText(
  WidgetTester tester,
  Locale locale,
  AiValidationIssue issue,
) async {
  var rendered = '';

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          rendered = aiValidationIssueText(
            AppLocalizations.of(context)!,
            issue,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
  return rendered;
}

void main() {
  testWidgets('renders localized validation issue text in English and German',
      (tester) async {
    const issue = AiValidationIssue(
      severity: AiValidationSeverity.error,
      code: 'unmatched_item',
      message: 'No local database match was found.',
    );

    final english =
        await _localizedIssueText(tester, const Locale('en'), issue);
    final german = await _localizedIssueText(tester, const Locale('de'), issue);

    expect(english, 'No local database match was found.');
    expect(german, 'Kein Treffer in der lokalen Datenbank gefunden.');
    expect(german, isNot(english));
  });

  testWidgets(
      'renders parameterized validation issue text from structured data',
      (tester) async {
    final issue = AiValidationIssue(
      severity: AiValidationSeverity.error,
      code: 'target_kcal_mismatch',
      message: 'Calories miss the target by 42 kcal.',
      parameters: {'delta': 42},
    );

    final english =
        await _localizedIssueText(tester, const Locale('en'), issue);
    final german = await _localizedIssueText(tester, const Locale('de'), issue);

    expect(english, 'Calories miss the target by 42 kcal.');
    expect(german, 'Die Kalorien weichen um 42 kcal vom Ziel ab.');
  });
}
