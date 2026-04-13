import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/feedback_report/domain/feedback_report_builder.dart';
import 'package:hypertrack/features/feedback_report/domain/feedback_report_models.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FakeDiagnosticsProvider implements FeedbackReportDiagnosticsProvider {
  final List<String> lines;

  const _FakeDiagnosticsProvider(this.lines);

  @override
  Future<List<String>> buildLines({required DateTime now}) async {
    return lines;
  }
}

class _ThrowingDiagnosticsProvider
    implements FeedbackReportDiagnosticsProvider {
  @override
  Future<List<String>> buildLines({required DateTime now}) async {
    throw StateError('diagnostics unavailable');
  }
}

FeedbackReportLocalizedCopy _copy() {
  return const FeedbackReportLocalizedCopy(
    title: 'Hypertrack Feedback Report',
    generatedLabel: 'Generated',
    appVersionLabel: 'App version',
    buildNumberLabel: 'Build number',
    platformLabel: 'Platform',
    osVersionLabel: 'OS version',
    unavailableValue: 'unavailable',
    userNoteSectionTitle: 'User note',
    adaptiveSectionTitle: 'Adaptive nutrition diagnostics',
    backupRestoreSectionTitle: 'Backup / restore diagnostics',
  );
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

void main() {
  group('FeedbackReportBuilder', () {
    test('toggles control optional report sections', () async {
      final builder = FeedbackReportBuilder(
        adaptiveDiagnosticsProvider: const _FakeDiagnosticsProvider([
          'adaptive_line: true',
        ]),
        backupRestoreDiagnosticsProvider: const _FakeDiagnosticsProvider([
          'backup_line: true',
        ]),
        packageInfoLoader: _mockPackageInfo,
        nowProvider: () => DateTime.utc(2026, 4, 13, 8),
      );

      final adaptiveOnly = await builder.build(
        options: const FeedbackReportOptions(
          includeAdaptiveNutritionDiagnostics: true,
          includeBackupRestoreDiagnostics: false,
          includeUserNote: false,
        ),
        copy: _copy(),
        userNote: '',
      );

      final adaptiveOnlyText = FeedbackReportSerializer.toPlainText(
        report: adaptiveOnly,
        copy: _copy(),
      );

      expect(adaptiveOnlyText, contains('Adaptive nutrition diagnostics'));
      expect(adaptiveOnlyText, contains('adaptive_line: true'));
      expect(adaptiveOnlyText, isNot(contains('Backup / restore diagnostics')));
      expect(adaptiveOnlyText, isNot(contains('backup_line: true')));
    });

    test('user note section appears only when entered and enabled', () async {
      final builder = FeedbackReportBuilder(
        adaptiveDiagnosticsProvider: const _FakeDiagnosticsProvider([]),
        backupRestoreDiagnosticsProvider: const _FakeDiagnosticsProvider([]),
        packageInfoLoader: _mockPackageInfo,
        nowProvider: () => DateTime.utc(2026, 4, 13, 8),
      );

      final withNote = await builder.build(
        options: const FeedbackReportOptions(
          includeAdaptiveNutritionDiagnostics: false,
          includeBackupRestoreDiagnostics: false,
          includeUserNote: true,
        ),
        copy: _copy(),
        userNote: 'Edge case when applying recommendation.',
      );
      final withNoteText = FeedbackReportSerializer.toPlainText(
        report: withNote,
        copy: _copy(),
      );

      expect(withNoteText, contains('User note'));
      expect(withNoteText, contains('Edge case when applying recommendation.'));

      final withoutNote = await builder.build(
        options: const FeedbackReportOptions(
          includeAdaptiveNutritionDiagnostics: false,
          includeBackupRestoreDiagnostics: false,
          includeUserNote: true,
        ),
        copy: _copy(),
        userNote: '   ',
      );
      final withoutNoteText = FeedbackReportSerializer.toPlainText(
        report: withoutNote,
        copy: _copy(),
      );

      expect(withoutNoteText, isNot(contains('User note')));
    });

    test('report generation still succeeds when diagnostics are unavailable',
        () async {
      final builder = FeedbackReportBuilder(
        adaptiveDiagnosticsProvider: _ThrowingDiagnosticsProvider(),
        backupRestoreDiagnosticsProvider: const _FakeDiagnosticsProvider([]),
        packageInfoLoader: _mockPackageInfo,
        nowProvider: () => DateTime.utc(2026, 4, 13, 8),
      );

      final report = await builder.build(
        options: const FeedbackReportOptions(
          includeAdaptiveNutritionDiagnostics: true,
          includeBackupRestoreDiagnostics: false,
          includeUserNote: false,
        ),
        copy: _copy(),
        userNote: '',
      );
      final text = FeedbackReportSerializer.toPlainText(
        report: report,
        copy: _copy(),
      );

      expect(text, contains('Adaptive nutrition diagnostics'));
      expect(text, contains('status: unavailable'));
    });
  });
}
