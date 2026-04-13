import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/feedback_report/application/feedback_report_actions.dart';
import 'package:hypertrack/features/feedback_report/domain/feedback_report_builder.dart';
import 'package:hypertrack/features/feedback_report/presentation/feedback_report_screen.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class _FakeDiagnosticsProvider implements FeedbackReportDiagnosticsProvider {
  final List<String> lines;

  const _FakeDiagnosticsProvider(this.lines);

  @override
  Future<List<String>> buildLines({required DateTime now}) async => lines;
}

Future<PackageInfo> _mockPackageInfo() async {
  return PackageInfo(
    appName: 'Hypertrack',
    packageName: 'com.example.hypertrack',
    version: '0.8.6',
    buildNumber: '80014',
    buildSignature: '',
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

FeedbackReportBuilder _builder() {
  return FeedbackReportBuilder(
    adaptiveDiagnosticsProvider: const _FakeDiagnosticsProvider([
      'adaptive_marker: yes',
    ]),
    backupRestoreDiagnosticsProvider: const _FakeDiagnosticsProvider([
      'backup_marker: yes',
    ]),
    packageInfoLoader: _mockPackageInfo,
    nowProvider: () => DateTime.utc(2026, 4, 13, 9),
  );
}

Future<String> _previewText(WidgetTester tester) async {
  final previewFinder = find.byKey(const Key('feedback_report_preview_text'));
  final preview = tester.widget<SelectableText>(
    previewFinder,
  );
  return preview.data ?? preview.textSpan!.toPlainText();
}

Future<void> _tapGeneratePreview(WidgetTester tester) async {
  final button =
      find.byKey(const Key('feedback_report_generate_preview_button'));
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _setUserNote(WidgetTester tester, String note) async {
  final noteField = find.byKey(const Key('feedback_report_note_field'));
  await tester.enterText(noteField, note);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 5000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('privacy note is visible and no sharing action runs on open',
      (tester) async {
    await _setLargeSurface(tester);
    var shareCount = 0;
    var emailCount = 0;

    final actions = FeedbackReportActions(
      shareInvoker: (params) async {
        shareCount += 1;
        return const ShareResult('ok', ShareResultStatus.success);
      },
      urlOpener: (uri) async {
        emailCount += 1;
        return true;
      },
      temporaryDirectoryProvider: () async => Directory.systemTemp,
    );

    await tester.pumpWidget(
      _wrap(
        FeedbackReportScreen(
          reportBuilder: _builder(),
          actions: actions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy first'), findsOneWidget);
    expect(shareCount, 0);
    expect(emailCount, 0);
    expect(find.byKey(const Key('feedback_report_preview_text')), findsNothing);
  });

  testWidgets('preview generation works and toggles control contents',
      (tester) async {
    await _setLargeSurface(tester);
    final actions = FeedbackReportActions(
      temporaryDirectoryProvider: () async => Directory.systemTemp,
      shareInvoker: (params) async =>
          const ShareResult('ok', ShareResultStatus.success),
    );

    await tester.pumpWidget(
      _wrap(
        FeedbackReportScreen(
          reportBuilder: _builder(),
          actions: actions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _setUserNote(tester, 'Observed a calorie target jump.');
    await _tapGeneratePreview(tester);

    var text = await _previewText(tester);
    expect(text, contains('Hypertrack Feedback Report'));
    expect(text, contains('Observed a calorie target jump.'));
    expect(text, contains('adaptive_marker: yes'));
    expect(text, contains('backup_marker: yes'));

    await _tapVisible(
      tester,
      find.byKey(const Key('feedback_report_toggle_adaptive')),
    );
    await _tapGeneratePreview(tester);

    text = await _previewText(tester);
    expect(text, isNot(contains('adaptive_marker: yes')));
    expect(text, contains('backup_marker: yes'));

    await _tapVisible(
      tester,
      find.byKey(const Key('feedback_report_toggle_note')),
    );
    await _tapGeneratePreview(tester);

    text = await _previewText(tester);
    expect(text, isNot(contains('Observed a calorie target jump.')));
  });

  testWidgets('copy action shows confirmation snackbar', (tester) async {
    await _setLargeSurface(tester);
    var copyCount = 0;

    final actions = FeedbackReportActions(
      clipboardWriter: (text) async {
        copyCount += 1;
      },
      temporaryDirectoryProvider: () async => Directory.systemTemp,
      shareInvoker: (params) async =>
          const ShareResult('ok', ShareResultStatus.success),
    );

    await tester.pumpWidget(
      _wrap(
        FeedbackReportScreen(
          reportBuilder: _builder(),
          actions: actions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapGeneratePreview(tester);

    final copyButton = find.byKey(const Key('feedback_report_action_copy'));
    await tester.tap(copyButton);
    await tester.pump();

    expect(copyCount, 1);
    expect(find.text('Report copied to clipboard.'), findsOneWidget);
  });

  testWidgets('user note section appears only when note is entered',
      (tester) async {
    await _setLargeSurface(tester);
    final actions = FeedbackReportActions(
      temporaryDirectoryProvider: () async => Directory.systemTemp,
      shareInvoker: (params) async =>
          const ShareResult('ok', ShareResultStatus.success),
    );

    await tester.pumpWidget(
      _wrap(
        FeedbackReportScreen(
          reportBuilder: _builder(),
          actions: actions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapGeneratePreview(tester);

    var text = await _previewText(tester);
    expect(text, isNot(contains('User note')));

    await _setUserNote(tester, 'There is a mismatch after restore.');
    await _tapGeneratePreview(tester);

    text = await _previewText(tester);
    expect(text, contains('User note'));
    expect(text, contains('There is a mismatch after restore.'));
  });
}
