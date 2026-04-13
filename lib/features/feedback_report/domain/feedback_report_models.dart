class FeedbackReportMetadata {
  final DateTime generatedAt;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String osVersion;

  const FeedbackReportMetadata({
    required this.generatedAt,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
  });
}

class FeedbackReportSection {
  final String title;
  final List<String> lines;

  const FeedbackReportSection({
    required this.title,
    required this.lines,
  });

  bool get hasContent => lines.any((line) => line.trim().isNotEmpty);
}

class FeedbackReportDocument {
  final String title;
  final FeedbackReportMetadata metadata;
  final List<FeedbackReportSection> sections;

  const FeedbackReportDocument({
    required this.title,
    required this.metadata,
    required this.sections,
  });
}

class FeedbackReportOptions {
  final bool includeAdaptiveNutritionDiagnostics;
  final bool includeBackupRestoreDiagnostics;
  final bool includeUserNote;

  const FeedbackReportOptions({
    required this.includeAdaptiveNutritionDiagnostics,
    required this.includeBackupRestoreDiagnostics,
    required this.includeUserNote,
  });
}

class FeedbackReportLocalizedCopy {
  final String title;
  final String generatedLabel;
  final String appVersionLabel;
  final String buildNumberLabel;
  final String platformLabel;
  final String osVersionLabel;
  final String unavailableValue;
  final String userNoteSectionTitle;
  final String adaptiveSectionTitle;
  final String backupRestoreSectionTitle;

  const FeedbackReportLocalizedCopy({
    required this.title,
    required this.generatedLabel,
    required this.appVersionLabel,
    required this.buildNumberLabel,
    required this.platformLabel,
    required this.osVersionLabel,
    required this.unavailableValue,
    required this.userNoteSectionTitle,
    required this.adaptiveSectionTitle,
    required this.backupRestoreSectionTitle,
  });
}
