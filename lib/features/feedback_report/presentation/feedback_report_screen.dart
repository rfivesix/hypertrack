import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/global_app_bar.dart';
import '../../../widgets/summary_card.dart';
import '../application/feedback_report_actions.dart';
import '../data/adaptive_nutrition_diagnostics_provider.dart';
import '../data/backup_restore_diagnostics_provider.dart';
import '../domain/feedback_report_builder.dart';
import '../domain/feedback_report_models.dart';

class FeedbackReportScreen extends StatefulWidget {
  final FeedbackReportBuilder? reportBuilder;
  final FeedbackReportActions? actions;

  const FeedbackReportScreen({
    super.key,
    this.reportBuilder,
    this.actions,
  });

  @override
  State<FeedbackReportScreen> createState() => _FeedbackReportScreenState();
}

class _FeedbackReportScreenState extends State<FeedbackReportScreen> {
  late final FeedbackReportBuilder _reportBuilder;
  late final FeedbackReportActions _actions;
  final TextEditingController _noteController = TextEditingController();

  bool _includeAdaptiveDiagnostics = true;
  bool _includeBackupRestoreDiagnostics = true;
  bool _includeUserNote = true;

  bool _isGeneratingPreview = false;
  bool _isCopying = false;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isEmailing = false;

  String? _previewText;
  String? _savedFilePath;

  @override
  void initState() {
    super.initState();
    _reportBuilder = widget.reportBuilder ??
        FeedbackReportBuilder(
          adaptiveDiagnosticsProvider: AdaptiveNutritionDiagnosticsProvider(),
          backupRestoreDiagnosticsProvider: BackupRestoreDiagnosticsProvider(),
        );
    _actions = widget.actions ?? FeedbackReportActions();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  FeedbackReportLocalizedCopy _copy(AppLocalizations l10n) {
    return FeedbackReportLocalizedCopy(
      title: l10n.feedbackReportReportTitle,
      generatedLabel: l10n.feedbackReportReportGeneratedAt,
      appVersionLabel: l10n.feedbackReportReportAppVersion,
      buildNumberLabel: l10n.feedbackReportReportBuildNumber,
      platformLabel: l10n.feedbackReportReportPlatform,
      osVersionLabel: l10n.feedbackReportReportOsVersion,
      unavailableValue: l10n.feedbackReportUnavailable,
      userNoteSectionTitle: l10n.feedbackReportSectionUserNote,
      adaptiveSectionTitle: l10n.feedbackReportSectionAdaptiveNutrition,
      backupRestoreSectionTitle: l10n.feedbackReportSectionBackupRestore,
    );
  }

  Future<void> _generatePreview() async {
    if (_isGeneratingPreview) {
      return;
    }

    setState(() {
      _isGeneratingPreview = true;
    });

    final l10n = AppLocalizations.of(context)!;
    final copy = _copy(l10n);
    final report = await _reportBuilder.build(
      options: FeedbackReportOptions(
        includeAdaptiveNutritionDiagnostics: _includeAdaptiveDiagnostics,
        includeBackupRestoreDiagnostics: _includeBackupRestoreDiagnostics,
        includeUserNote: _includeUserNote,
      ),
      copy: copy,
      userNote: _noteController.text,
    );

    final previewText = FeedbackReportSerializer.toPlainText(
      report: report,
      copy: copy,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isGeneratingPreview = false;
      _previewText = previewText;
      _savedFilePath = null;
    });
  }

  Future<void> _copyReport() async {
    final previewText = _previewText;
    if (previewText == null || _isCopying) {
      return;
    }

    setState(() => _isCopying = true);
    await _actions.copyReport(previewText);
    if (!mounted) {
      return;
    }
    setState(() => _isCopying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.feedbackReportCopied)),
    );
  }

  Future<void> _saveReportFile() async {
    final previewText = _previewText;
    if (previewText == null || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final file =
        await _actions.saveReportToTemporaryFile(reportText: previewText);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _savedFilePath = file.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.feedbackReportSavedToTemporaryFile,
        ),
      ),
    );
  }

  Future<void> _shareReport() async {
    final previewText = _previewText;
    if (previewText == null || _isSharing) {
      return;
    }

    setState(() => _isSharing = true);
    final status = await _actions.shareReport(
      reportText: previewText,
      existingFilePath: _savedFilePath,
      subject: AppLocalizations.of(context)!.feedbackReportEmailSubject,
    );

    if (!mounted) {
      return;
    }
    setState(() => _isSharing = false);

    final l10n = AppLocalizations.of(context)!;
    final wasShared = status == ShareResultStatus.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasShared
              ? l10n.feedbackReportShareCompleted
              : l10n.feedbackReportShareCanceled,
        ),
      ),
    );
  }

  Future<void> _openEmailDraft() async {
    final previewText = _previewText;
    if (previewText == null || _isEmailing) {
      return;
    }

    setState(() => _isEmailing = true);
    final includeNote = _includeUserNote ? _noteController.text.trim() : null;
    final opened = await _actions.openFeedbackEmailDraft(
      reportText: previewText,
      userNote: includeNote,
      subject: AppLocalizations.of(context)!.feedbackReportEmailSubject,
    );

    if (!mounted) {
      return;
    }
    setState(() => _isEmailing = false);

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.feedbackReportEmailOpenFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      key: const Key('feedback_report_screen'),
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.feedbackReportScreenTitle,
      ),
      body: ListView(
        key: const Key('feedback_report_scroll_view'),
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          _buildSectionTitle(context, l10n.feedbackReportScreenTitle),
          SummaryCard(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(
                l10n.feedbackReportPrivacyTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(l10n.feedbackReportPrivacyBody),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(context, l10n.feedbackReportOptionalNoteTitle),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const Key('feedback_report_note_field'),
                controller: _noteController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.feedbackReportOptionalNoteLabel,
                  hintText: l10n.feedbackReportOptionalNoteHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(context, l10n.feedbackReportIncludeSectionTitle),
          SummaryCard(
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('feedback_report_toggle_adaptive'),
                  secondary: const Icon(Icons.monitor_heart_outlined),
                  title: Text(
                    l10n.feedbackReportIncludeAdaptiveNutrition,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _includeAdaptiveDiagnostics,
                  onChanged: (value) {
                    setState(() => _includeAdaptiveDiagnostics = value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const Key('feedback_report_toggle_backup'),
                  secondary: const Icon(Icons.backup_outlined),
                  title: Text(
                    l10n.feedbackReportIncludeBackupRestore,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _includeBackupRestoreDiagnostics,
                  onChanged: (value) {
                    setState(() => _includeBackupRestoreDiagnostics = value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const Key('feedback_report_toggle_note'),
                  secondary: const Icon(Icons.note_alt_outlined),
                  title: Text(
                    l10n.feedbackReportIncludeUserNote,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _includeUserNote,
                  onChanged: (value) {
                    setState(() => _includeUserNote = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('feedback_report_generate_preview_button'),
              onPressed: _isGeneratingPreview ? null : _generatePreview,
              icon: _isGeneratingPreview
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: Text(l10n.feedbackReportGeneratePreview),
            ),
          ),
          if (_previewText != null) ...[
            const SizedBox(height: DesignConstants.spacingXL),
            _buildSectionTitle(context, l10n.feedbackReportPreviewTitle),
            SummaryCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 280,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _previewText!,
                      key: const Key('feedback_report_preview_text'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('feedback_report_action_copy'),
                  onPressed: _isCopying ? null : _copyReport,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.feedbackReportActionCopy),
                ),
                OutlinedButton.icon(
                  key: const Key('feedback_report_action_save'),
                  onPressed: _isSaving ? null : _saveReportFile,
                  icon: const Icon(Icons.save_alt_outlined),
                  label: Text(l10n.feedbackReportActionSave),
                ),
                OutlinedButton.icon(
                  key: const Key('feedback_report_action_share'),
                  onPressed: _isSharing ? null : _shareReport,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(l10n.feedbackReportActionShare),
                ),
                OutlinedButton.icon(
                  key: const Key('feedback_report_action_email'),
                  onPressed: _isEmailing ? null : _openEmailDraft,
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l10n.feedbackReportActionEmail),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
