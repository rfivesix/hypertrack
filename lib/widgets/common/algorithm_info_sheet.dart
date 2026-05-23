// lib/widgets/common/algorithm_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;
import '../../util/design_constants.dart';

/// A standard premium info button that triggers a detailed bottom sheet about
/// the underlying algorithm (math under-the-hood, key concepts, and references).
class AlgorithmInfoButton extends StatelessWidget {
  /// The title of the algorithm or view.
  final String title;

  /// The concise, user-friendly non-technical explanation.
  final String explanation;

  /// The key features or aspects of the algorithm, typically split by newline from ARB.
  final List<String> keyPoints;

  /// The technical header for the mathematical deep-dive.
  final String technicalTitle;

  /// The technical, monospace explanation containing mathematical formulas or code invariants.
  final String technicalExplanation;

  /// Optional asset path to a markdown file containing a clinical-grade deep dive.
  final String? markdownAssetPath;

  /// Custom icon color to override the theme primary color.
  final Color? iconColor;

  const AlgorithmInfoButton({
    super.key,
    required this.title,
    required this.explanation,
    required this.keyPoints,
    required this.technicalTitle,
    required this.technicalExplanation,
    this.markdownAssetPath,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: const Icon(Icons.info_outline),
      color: iconColor ?? theme.colorScheme.primary,
      iconSize: DesignConstants.iconSizeM,
      onPressed: () {
        showAlgorithmInfoBottomSheet(
          context,
          title: title,
          explanation: explanation,
          keyPoints: keyPoints,
          technicalTitle: technicalTitle,
          technicalExplanation: technicalExplanation,
          markdownAssetPath: markdownAssetPath,
        );
      },
      tooltip: title,
    );
  }
}

/// Helper method to trigger the standardized bottom sheet.
void showAlgorithmInfoBottomSheet(
  BuildContext context, {
  required String title,
  required String explanation,
  required List<String> keyPoints,
  required String technicalTitle,
  required String technicalExplanation,
  String? markdownAssetPath,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => _AlgorithmInfoBottomSheet(
      title: title,
      explanation: explanation,
      keyPoints: keyPoints,
      technicalTitle: technicalTitle,
      technicalExplanation: technicalExplanation,
      markdownAssetPath: markdownAssetPath,
    ),
  );
}

class _AlgorithmInfoBottomSheet extends StatefulWidget {
  final String title;
  final String explanation;
  final List<String> keyPoints;
  final String technicalTitle;
  final String technicalExplanation;
  final String? markdownAssetPath;

  const _AlgorithmInfoBottomSheet({
    required this.title,
    required this.explanation,
    required this.keyPoints,
    required this.technicalTitle,
    required this.technicalExplanation,
    this.markdownAssetPath,
  });

  @override
  State<_AlgorithmInfoBottomSheet> createState() => _AlgorithmInfoBottomSheetState();
}

class _AlgorithmInfoBottomSheetState extends State<_AlgorithmInfoBottomSheet> {
  bool _isTechnicalExpanded = false;
  String? _loadedMarkdown;
  bool _isLoading = false;

  Future<void> _loadMarkdown() async {
    if (widget.markdownAssetPath == null || _loadedMarkdown != null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DefaultAssetBundle.of(context).loadString(widget.markdownAssetPath!);
      if (mounted) {
        setState(() {
          _loadedMarkdown = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignConstants.borderRadiusL),
              topRight: Radius.circular(DesignConstants.borderRadiusL),
            ),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: DesignConstants.spacingS),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DesignConstants.spacingL),
                  children: [
                    // Non-technical explanation text
                    Text(
                      widget.explanation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.45,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    
                    // Bullet Points Key Features
                    ...widget.keyPoints.where((p) => p.trim().isNotEmpty).map((point) {
                      final cleanPoint = point.trim().replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "• ",
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                cleanPoint,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: cs.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: DesignConstants.spacingL),
                    
                    // Expandable Technical Section
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF262626) 
                            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                        border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isTechnicalExpanded = !_isTechnicalExpanded;
                              });
                              if (_isTechnicalExpanded) {
                                _loadMarkdown();
                              }
                            },
                            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                            child: Padding(
                              padding: const EdgeInsets.all(DesignConstants.spacingL),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.developer_mode,
                                          size: DesignConstants.iconSizeM,
                                          color: cs.primary,
                                        ),
                                        const SizedBox(width: DesignConstants.spacingS),
                                        Expanded(
                                          child: Text(
                                            widget.technicalTitle,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _isTechnicalExpanded 
                                        ? Icons.expand_less 
                                        : Icons.expand_more,
                                    color: cs.onSurface.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isTechnicalExpanded) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(DesignConstants.spacingL),
                              child: _isLoading 
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: DesignConstants.spacingL),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : MarkdownBody(
                                      data: _loadedMarkdown ?? widget.technicalExplanation,
                                      selectable: true,
                                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                                        p: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: cs.onSurface.withValues(alpha: 0.85),
                                        ),
                                        code: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          backgroundColor: isDark 
                                              ? const Color(0xFF1E1E1E) 
                                              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                                          color: cs.primary,
                                        ),
                                      ),
                                      builders: {
                                        'latex': LatexElementBuilder(
                                          textStyle: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 13,
                                            color: cs.primary,
                                          ),
                                        ),
                                      },
                                      extensionSet: md.ExtensionSet(
                                        [
                                          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                                          LatexBlockSyntax(),
                                        ],
                                        [
                                          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                                          LatexInlineSyntax(),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignConstants.bottomContentSpacer),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

