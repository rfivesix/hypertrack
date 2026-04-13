import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'feedback_report_models.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();
typedef NowProvider = DateTime Function();

abstract class FeedbackReportDiagnosticsProvider {
  Future<List<String>> buildLines({required DateTime now});
}

class FeedbackReportBuilder {
  final FeedbackReportDiagnosticsProvider _adaptiveDiagnosticsProvider;
  final FeedbackReportDiagnosticsProvider _backupRestoreDiagnosticsProvider;
  final PackageInfoLoader _packageInfoLoader;
  final NowProvider _nowProvider;

  FeedbackReportBuilder({
    required FeedbackReportDiagnosticsProvider adaptiveDiagnosticsProvider,
    required FeedbackReportDiagnosticsProvider backupRestoreDiagnosticsProvider,
    PackageInfoLoader? packageInfoLoader,
    NowProvider? nowProvider,
  })  : _adaptiveDiagnosticsProvider = adaptiveDiagnosticsProvider,
        _backupRestoreDiagnosticsProvider = backupRestoreDiagnosticsProvider,
        _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
        _nowProvider = nowProvider ?? DateTime.now;

  Future<FeedbackReportDocument> build({
    required FeedbackReportOptions options,
    required FeedbackReportLocalizedCopy copy,
    required String userNote,
  }) async {
    final generatedAt = _nowProvider();
    final packageInfo = await _packageInfoLoader();

    final metadata = FeedbackReportMetadata(
      generatedAt: generatedAt,
      appVersion: packageInfo.version.trim(),
      buildNumber: packageInfo.buildNumber.trim(),
      platform: _platformLabel(),
      osVersion: _osVersionLabel(unavailableValue: copy.unavailableValue),
    );

    final sections = <FeedbackReportSection>[];

    final trimmedNote = userNote.trim();
    if (options.includeUserNote && trimmedNote.isNotEmpty) {
      sections.add(
        FeedbackReportSection(
          title: copy.userNoteSectionTitle,
          lines: [trimmedNote],
        ),
      );
    }

    if (options.includeAdaptiveNutritionDiagnostics) {
      sections.add(
        FeedbackReportSection(
          title: copy.adaptiveSectionTitle,
          lines: await _safeDiagnosticsLines(
            provider: _adaptiveDiagnosticsProvider,
            now: generatedAt,
            unavailableValue: copy.unavailableValue,
          ),
        ),
      );
    }

    if (options.includeBackupRestoreDiagnostics) {
      sections.add(
        FeedbackReportSection(
          title: copy.backupRestoreSectionTitle,
          lines: await _safeDiagnosticsLines(
            provider: _backupRestoreDiagnosticsProvider,
            now: generatedAt,
            unavailableValue: copy.unavailableValue,
          ),
        ),
      );
    }

    return FeedbackReportDocument(
      title: copy.title,
      metadata: metadata,
      sections: sections,
    );
  }

  Future<List<String>> _safeDiagnosticsLines({
    required FeedbackReportDiagnosticsProvider provider,
    required DateTime now,
    required String unavailableValue,
  }) async {
    try {
      final lines = await provider.buildLines(now: now);
      if (lines.isEmpty) {
        return ['status: $unavailableValue'];
      }
      return lines;
    } catch (error) {
      final summary = _sanitizeError(error.toString());
      return ['status: $unavailableValue', 'error: $summary'];
    }
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    return Platform.operatingSystem;
  }

  String _osVersionLabel({required String unavailableValue}) {
    if (kIsWeb) {
      return unavailableValue;
    }

    final version = Platform.operatingSystemVersion.trim();
    if (version.isEmpty) {
      return unavailableValue;
    }
    return version;
  }

  String _sanitizeError(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 180) {
      return compact;
    }
    return '${compact.substring(0, 180)}...';
  }
}

class FeedbackReportSerializer {
  const FeedbackReportSerializer._();

  static String toPlainText({
    required FeedbackReportDocument report,
    required FeedbackReportLocalizedCopy copy,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(report.title);
    buffer.writeln(
        '${copy.generatedLabel}: ${_iso(report.metadata.generatedAt)}');
    buffer.writeln(
        '${copy.appVersionLabel}: ${_valueOrUnavailable(report.metadata.appVersion, copy.unavailableValue)}');
    buffer.writeln(
        '${copy.buildNumberLabel}: ${_valueOrUnavailable(report.metadata.buildNumber, copy.unavailableValue)}');
    buffer.writeln(
        '${copy.platformLabel}: ${_valueOrUnavailable(report.metadata.platform, copy.unavailableValue)}');
    buffer.writeln(
        '${copy.osVersionLabel}: ${_valueOrUnavailable(report.metadata.osVersion, copy.unavailableValue)}');

    for (final section in report.sections) {
      if (!section.hasContent) {
        continue;
      }
      buffer.writeln();
      buffer.writeln(section.title);
      for (final rawLine in section.lines) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          continue;
        }
        if (line.startsWith('- ')) {
          buffer.writeln(line);
        } else {
          buffer.writeln('- $line');
        }
      }
    }

    return buffer.toString().trimRight();
  }

  static String _iso(DateTime value) => value.toUtc().toIso8601String();

  static String _valueOrUnavailable(String value, String unavailableValue) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? unavailableValue : trimmed;
  }
}
