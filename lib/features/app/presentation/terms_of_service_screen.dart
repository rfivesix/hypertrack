import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/frosted_container.dart';
import '../../../util/design_constants.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  String? _markdownContent;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final assetPath = languageCode == 'de'
        ? 'assets/legal/terms_of_service_de.md'
        : 'assets/legal/terms_of_service_en.md';

    try {
      final content = await DefaultAssetBundle.of(context).loadString(assetPath);
      if (mounted) {
        setState(() {
          _markdownContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _markdownContent = 'Error loading Terms of Service.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.terms_of_service),
      body: Stack(
        children: [
          Container(color: theme.colorScheme.surface),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    DesignConstants.screenPaddingHorizontal,
                    topPadding + DesignConstants.spacingL,
                    DesignConstants.screenPaddingHorizontal,
                    DesignConstants.screenPaddingVertical,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FrostedContainer(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(DesignConstants.spacingL),
                        radius: DesignConstants.borderRadiusL,
                        blurSigma: 18,
                        child: MarkdownBody(
                          data: _markdownContent ?? '',
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.6,
                              color: cs.onSurface.withValues(alpha: 0.9),
                            ),
                            h1: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: cs.primary,
                              height: 1.5,
                            ),
                            h2: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: cs.primary,
                              height: 1.5,
                            ),
                            listBullet: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignConstants.bottomContentSpacer),
                    ]),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
