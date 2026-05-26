import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:train_libre/features/app/presentation/terms_of_service_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/legal/terms_of_service_en.md') {
      return '# Terms of Service (EN)\n\n## 1. No Medical Advice\nThis is a statistical approximation...';
    } else if (key == 'assets/legal/terms_of_service_de.md') {
      return '# Nutzungsbedingungen (DE)\n\n## 1. Keine medizinische Beratung\nDies ist eine statistische Schätzung...';
    }
    throw Exception('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }
}

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: DefaultAssetBundle(
      bundle: _FakeAssetBundle(),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TermsOfServiceScreen loads and renders English Markdown content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const TermsOfServiceScreen(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Terms of Service (EN)'), findsOneWidget);
    expect(find.text('This is a statistical approximation...'), findsOneWidget);
  });

  testWidgets('TermsOfServiceScreen loads and renders German Markdown content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const TermsOfServiceScreen(), locale: const Locale('de')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Nutzungsbedingungen (DE)'), findsOneWidget);
    expect(find.text('Dies ist eine statistische Schätzung...'), findsOneWidget);
  });
}
