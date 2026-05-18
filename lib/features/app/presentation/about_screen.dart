// lib/screens/about_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../util/design_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.about_train_libre,
      ),
      body: Stack(
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info?.version ?? '...';
              final buildNumber = info?.buildNumber ?? '...';

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  DesignConstants.spacingXL,
                  topPadding + DesignConstants.spacingXL,
                  DesignConstants.spacingXL,
                  DesignConstants.bottomContentSpacer,
                ),
                children: [
                  // App Logo Card
                  SummaryCard(
                    padding: const EdgeInsets.all(DesignConstants.spacingXL),
                    child: Center(
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            'assets/icon/train-libre_icon_dark_green_no_bg.svg',
                            height: 100,
                          ),
                          const SizedBox(height: DesignConstants.spacingL),
                          Text(
                            l10n.appTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Version $version ($buildNumber)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingXXL),
                  AppSectionHeader(
                    title: l10n.about_section,
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.library_books_outlined,
                    title: l10n.used_libraries,
                    onTap: () => _openUsedPackages(context),
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.gavel_outlined,
                    title: l10n.licensing_info,
                    onTap: () => _launchURL(
                        'https://github.com/rfivesix/train-libre/blob/main/LICENSE'),
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.language_outlined,
                    title: l10n.project_website,
                    onTap: () =>
                        _launchURL('https://rfivesix.github.io/train-libre/'),
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.code_outlined,
                    title: l10n.github_repository,
                    onTap: () =>
                        _launchURL('https://github.com/rfivesix/train-libre'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openUsedPackages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _UsedPackagesScreen(),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _UsedPackagesScreen extends StatelessWidget {
  const _UsedPackagesScreen();

  @override
  Widget build(BuildContext context) {
    final title = MaterialLocalizations.of(context).licensesPageTitle;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: title),
      body: Stack(
        children: [
          FutureBuilder<List<_PackageLicenseBundle>>(
            future: _loadLicenses(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final packages = snapshot.data!;
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  DesignConstants.spacingL,
                  topPadding + DesignConstants.spacingXL,
                  DesignConstants.spacingL,
                  DesignConstants.bottomContentSpacer,
                ),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final package = packages[index];
                  return SummaryCard(
                    margin:
                        const EdgeInsets.only(bottom: DesignConstants.spacingM),
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _PackageLicenseScreen(bundle: package),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        package.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${package.entries.length} ${title.toLowerCase()}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<_PackageLicenseBundle>> _loadLicenses() async {
    final licensesByPackage = <String, List<LicenseEntry>>{};
    await for (final license in LicenseRegistry.licenses) {
      for (final package in license.packages) {
        licensesByPackage.putIfAbsent(package, () => []).add(license);
      }
    }

    final bundles = licensesByPackage.entries
        .map(
          (entry) => _PackageLicenseBundle(
            name: entry.key,
            entries: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return bundles;
  }
}

class _PackageLicenseScreen extends StatelessWidget {
  const _PackageLicenseScreen({required this.bundle});

  final _PackageLicenseBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: bundle.name),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              DesignConstants.spacingL,
              topPadding + DesignConstants.spacingXL,
              DesignConstants.spacingL,
              DesignConstants.bottomContentSpacer,
            ),
            children: [
              for (final entry in bundle.entries)
                SummaryCard(
                  padding: const EdgeInsets.all(DesignConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final paragraph in entry.paragraphs)
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: paragraph.indent * DesignConstants.spacingL,
                            bottom: DesignConstants.spacingM,
                          ),
                          child: SelectableText(
                            paragraph.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.55,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackageLicenseBundle {
  const _PackageLicenseBundle({
    required this.name,
    required this.entries,
  });

  final String name;
  final List<LicenseEntry> entries;
}
