// lib/screens/legal_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/app_localizations.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/common/app_section_header.dart';
import '../widgets/frosted_container.dart';
import '../util/design_constants.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final document = _legalDocumentFor(
      Localizations.localeOf(context).languageCode,
    );
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.legal_section),
      body: Stack(
        children: [
          _buildBackground(theme),
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
                    _buildMetadataHeader(document, theme, l10n),
                    const SizedBox(height: DesignConstants.spacingL),
                    _buildLegalNotice(document, l10n),
                    const SizedBox(height: DesignConstants.spacingXL),
                    _buildPrivacyPolicy(document, l10n),
                    const SizedBox(height: DesignConstants.spacingXXL),
                    _buildBrowserButton(l10n),
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

  Widget _buildBackground(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
    );
  }

  Widget _buildMetadataHeader(
    _LegalDocument document,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return FrostedContainer(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(DesignConstants.spacingM),
      radius: DesignConstants.borderRadiusL,
      blurSigma: 18,
      child: Row(
        children: [
          Expanded(
            child: _metadataItem(
              l10n.legal_document_version,
              document.version,
              theme,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Expanded(
            child: _metadataItem(
              l10n.legal_document_last_updated,
              document.date,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataItem(String label, String value, ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXS),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalNotice(_LegalDocument document, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.legal_notice),
        const SizedBox(height: DesignConstants.spacingS),
        FrostedContainer(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          radius: DesignConstants.borderRadiusL,
          blurSigma: 18,
          child: _LegalText(data: document.legalNotice),
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicy(_LegalDocument document, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.privacy_policy),
        const SizedBox(height: DesignConstants.spacingS),
        ...document.privacyPolicySections.map(_LegalAccordion.new),
      ],
    );
  }

  Widget _buildBrowserButton(AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: () =>
          _handleLink('https://rfivesix.github.io/train-libre/privacy-policy/'),
      icon: const Icon(Icons.open_in_browser),
      label: Text(l10n.view_in_browser),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
      ),
    );
  }
}

class _LegalAccordion extends StatefulWidget {
  const _LegalAccordion(this.section);

  final _LegalSection section;

  @override
  State<_LegalAccordion> createState() => _LegalAccordionState();
}

class _LegalAccordionState extends State<_LegalAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: FrostedContainer(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        radius: DesignConstants.borderRadiusL,
        blurSigma: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingL,
                  vertical: DesignConstants.spacingL,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.section.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.primary,
                      size: DesignConstants.iconSizeL,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignConstants.spacingL,
                  0,
                  DesignConstants.spacingL,
                  DesignConstants.spacingL,
                ),
                child: _LegalText(data: widget.section.content),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalText extends StatefulWidget {
  const _LegalText({required this.data});

  final String data;

  @override
  State<_LegalText> createState() => _LegalTextState();
}

class _LegalTextState extends State<_LegalText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.6);
    final paragraphs = widget.data.trim().split(RegExp(r'\n\s*\n'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < paragraphs.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  index == paragraphs.length - 1 ? 0 : DesignConstants.spacingM,
            ),
            child: _paragraphWidget(paragraphs[index].trim(), baseStyle),
          ),
      ],
    );
  }

  Widget _paragraphWidget(String paragraph, TextStyle? baseStyle) {
    final lines = paragraph.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < lines.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == lines.length - 1 ? 0 : DesignConstants.spacingS,
            ),
            child: lines[index].trim().startsWith('- ')
                ? _bulletItem(lines[index].trim().substring(2), baseStyle)
                : Text.rich(
                    TextSpan(
                      children: _linkifiedSpans(lines[index].trim(), baseStyle),
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    textWidthBasis: TextWidthBasis.parent,
                  ),
          ),
      ],
    );
  }

  Widget _bulletItem(String item, TextStyle? baseStyle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•', style: baseStyle),
        const SizedBox(width: DesignConstants.spacingM),
        Expanded(
          child: Text.rich(
            TextSpan(children: _linkifiedSpans(item, baseStyle)),
            softWrap: true,
            overflow: TextOverflow.visible,
            textWidthBasis: TextWidthBasis.parent,
          ),
        ),
      ],
    );
  }

  List<TextSpan> _linkifiedSpans(String text, TextStyle? baseStyle) {
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'((?:https?:\/\/|www\.)[^\s<>)]+)|([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
    );
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final rawValue = match.group(0)!;
      final trailing =
          RegExp(r'[.,;:!?]+$').firstMatch(rawValue)?.group(0) ?? '';
      final value = trailing.isEmpty
          ? rawValue
          : rawValue.substring(0, rawValue.length - trailing.length);
      final href = value.contains('@') && !value.startsWith('http')
          ? 'mailto:$value'
          : value.startsWith('http')
              ? value
              : 'https://$value';
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _handleLink(href);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: value,
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.64),
          ),
          recognizer: recognizer,
        ),
      );
      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return spans
        .map((span) => TextSpan(
              text: span.text,
              children: span.children,
              style: span.style ?? baseStyle,
              recognizer: span.recognizer,
            ))
        .toList();
  }
}

Future<void> _handleLink(String href) async {
  final uri = Uri.parse(href);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

_LegalDocument _legalDocumentFor(String languageCode) {
  return languageCode == 'de' ? _germanLegalDocument : _englishLegalDocument;
}

class _LegalDocument {
  const _LegalDocument({
    required this.version,
    required this.date,
    required this.legalNotice,
    required this.privacyPolicySections,
  });

  final String version;
  final String date;
  final String legalNotice;
  final List<_LegalSection> privacyPolicySections;
}

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

const _germanLegalDocument = _LegalDocument(
  version: '1.1',
  date: 'May 12, 2026',
  legalNotice: '''
Angaben gemäß § 5 DDG:

Diensteanbieter / Verantwortlich für die App „Train Libre“:
Richard Georg Schotte
Bundesallee 114
12161 Berlin
Deutschland

Kontakt:
E-Mail: feedback@schotte.me
Telefon: (+49) 1520 6915571

Vertretungsberechtigte Person:
Richard Georg Schotte (Einzelentwickler)

Umsatzsteuer-ID:
Nicht vorhanden
''',
  privacyPolicySections: [
    _LegalSection(
      title: '1. Einleitung und Verantwortlicher',
      content: '''
Diese Datenschutzerklärung informiert Sie gemäß Art. 13 DSGVO über die Verarbeitung personenbezogener Daten in der App „Train Libre“.

Verantwortlicher:
Richard Georg Schotte, Berlin (Anschrift siehe Impressum)
E-Mail: feedback@schotte.me
''',
    ),
    _LegalSection(
      title: '2. Local-First Prinzip & Datensparsamkeit',
      content: '''
Train Libre ist eine „Local-First“-App. Wir verfolgen den Ansatz der Datensparsamkeit und des Datenschutzes durch Technikgestaltung (Privacy by Design). Alle Ihre sensiblen Gesundheitsdaten verbleiben ausschließlich in einer lokalen Datenbank auf Ihrem Endgerät. Wir betreiben keinen Cloud-Server und haben keinen technischen Zugriff auf Ihre lokalen Daten.
''',
    ),
    _LegalSection(
      title: '3. Kategorien von Daten und Rechtsgrundlagen',
      content: '''
A. Gesundheitsdaten (Art. 9 DSGVO)
Die App verarbeitet besondere Kategorien personenbezogener Daten (Gewicht, Herzfrequenz, Schlafdaten, Ernährung).

- Rechtsgrundlage: Ihre ausdrückliche Einwilligung gemäß Art. 9 Abs. 2 lit. a DSGVO in Verbindung mit Art. 6 Abs. 1 lit. a DSGVO.
- Freiwilligkeit: Die Bereitstellung dieser Daten ist weder gesetzlich noch vertraglich vorgeschrieben. Ohne diese Daten können die Tracking- und Analysefunktionen jedoch nicht genutzt werden.

B. Kernfunktionalitäten der App
Die Speicherung Ihrer Einstellungen und Profile erfolgt zur Erfüllung des Nutzungsverhältnisses auf Grundlage von Art. 6 Abs. 1 lit. b DSGVO.

C. Support & Feedback
Bei Kontaktaufnahme per E-Mail verarbeiten wir Ihre Daten zur Bearbeitung Ihres Anliegens (Art. 6 Abs. 1 lit. b DSGVO) sowie aufgrund unseres berechtigten Interesses an Supportqualität und Missbrauchsprävention (Art. 6 Abs. 1 lit. f DSGVO).
''',
    ),
    _LegalSection(
      title: '4. Empfänger der Daten',
      content: '''
Innerhalb der App findet kein automatischer Datentransfer an uns statt. Empfänger technischer oder nutzergenerierter Daten können jedoch sein:

- KI-Anbieter (OpenAI, Google, Anthropic, Mistral, xAI etc.): Diese agieren als separate Verantwortliche und erhalten Daten (z. B. Fotos, Prompts), wenn Sie die BYOK-KI-Funktionen aktiv nutzen.
- Katalog-Dienste (Open Food Facts, wger, GitHub): Diese erhalten technische Verbindungsdaten (IP-Adresse, User-Agent) beim Abruf von Datenbanken oder Updates.
- Cloud-Anbieter (Apple iCloud / Google Drive): Diese erhalten Daten im Rahmen Ihrer systemweiten Backups, sofern Sie diese Funktion im Betriebssystem aktiviert haben.
''',
    ),
    _LegalSection(
      title: '5. Drittlandübermittlung (BYOK AI)',
      content: '''
Bei Nutzung von KI-Diensten können Daten an Anbieter in Drittländern (insbesondere die USA) übertragen werden.

- Mechanismen: Die Anbieter stützen sich in der Regel auf Standardvertragsklauseln (SCCs) oder Angemessenheitsbeschlüsse.
- Hinweis: Da Sie Ihren eigenen API-Schlüssel nutzen, unterliegt die Datenverarbeitung den Datenschutzbestimmungen des jeweiligen Anbieters. Bitte prüfen Sie deren Richtlinien (z. B. zu Datenstandorten), bevor Sie gesundheitsbezogene Daten übermitteln. Die Übermittlung erfolgt gemäß Art. 44 ff. DSGVO.
''',
    ),
    _LegalSection(
      title: '6. Integration von HealthKit & Health Connect',
      content: '''
Der Austausch mit Apple HealthKit oder Google Health Connect erfolgt rein lokal auf Ihrem Gerät. Daten werden nur nach Ihrer expliziten Freigabe gelesen oder geschrieben. Bitte beachten Sie zusätzlich die Datenschutzhinweise von Apple bzw. Google für HealthKit bzw. Health Connect.
''',
    ),
    _LegalSection(
      title: '7. Kein Tracking / Keine Analyse',
      content: '''
Die App verwendet keine Tracking- oder Analyse-SDKs (wie Firebase Analytics, Google Analytics oder Sentry). Es findet keine Profilbildung zu Marketingzwecken statt.
''',
    ),
    _LegalSection(
      title: '8. Speicherdauer',
      content: '''
- App-Daten: Verbleiben auf Ihrem Gerät, bis Sie diese löschen oder die App deinstallieren.
- E-Mails: Werden nur so lange gespeichert, wie für die Bearbeitung der Anfrage und Dokumentation erforderlich, sofern keine gesetzlichen Aufbewahrungspflichten bestehen.
''',
    ),
    _LegalSection(
      title: '9. Webhosting (GitHub Pages)',
      content: '''
Wir hosten diese Website bei GitHub Pages.
Dienstanbieter ist GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA (bzw. GitHub B.V., Vijzelstraat 68-72, 1017 HL Amsterdam, Niederlande, laut GitHub‑Privacy‑Policy). Beim Aufruf unserer Website stellt Ihr Browser eine Verbindung zu den Servern von GitHub her. Dabei werden technisch bedingt personenbezogene Daten wie Ihre IP‑Adresse, die aufgerufene URL, Datum und Uhrzeit sowie Informationen zu Browser und Betriebssystem in Server‑Logfiles verarbeitet.
Rechtsgrundlage ist unser berechtigtes Interesse an einer sicheren und effizienten Bereitstellung unseres Webangebots gemäß Art. 6 Abs. 1 lit. f DSGVO.

Weitere Informationen finden Sie in der Datenschutzerklärung von GitHub unter https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement.
''',
    ),
    _LegalSection(
      title: '10. Ihre Betroffenenrechte',
      content: '''
Sie haben gegenüber dem Verantwortlichen folgende Rechte:

- Auskunft (Art. 15 DSGVO)
- Berichtigung (Art. 16 DSGVO)
- Löschung (Art. 17 DSGVO)
- Einschränkung der Verarbeitung (Art. 18 DSGVO)
- Datenübertragbarkeit (Art. 20 DSGVO)
- Widerspruch (Art. 21 DSGVO)
- Widerruf erteilter Einwilligungen (Art. 7 Abs. 3 DSGVO) mit Wirkung für die Zukunft.

Zudem haben Sie das Recht auf Beschwerde bei einer Aufsichtsbehörde (Art. 77 DSGVO), z. B. der Berliner Beauftragten für Datenschutz und Informationsfreiheit.
''',
    ),
  ],
);

const _englishLegalDocument = _LegalDocument(
  version: '1.1',
  date: 'May 12, 2026',
  legalNotice: '''
Information according to § 5 DDG:

Service Provider / Responsible for the App “Train Libre”:
Richard Georg Schotte
Bundesallee 114
12161 Berlin
Germany

Contact:
E-Mail: feedback@schotte.me
Phone: (+49) 1520 6915571

Authorized Representative:
Richard Georg Schotte (Sole Developer)
''',
  privacyPolicySections: [
    _LegalSection(
      title: '1. General Information',
      content: '''
This Privacy Policy informs you according to Art. 13 GDPR about the processing of personal data in “Train Libre”.

Controller:
Richard Georg Schotte, Berlin (see Legal Notice for address)
E-Mail: feedback@schotte.me
''',
    ),
    _LegalSection(
      title: '2. Local-First & Privacy by Design',
      content: '''
Train Libre is a "local-first" application. All sensitive health data remains exclusively on your device. We do not operate a cloud backend and have no access to your data.
''',
    ),
    _LegalSection(
      title: '3. Legal Bases for Processing',
      content: '''
A. Health Data (Art. 9 GDPR)
- Legal Basis: Your explicit consent according to Art. 9(2)(a) GDPR in conjunction with Art. 6(1)(a) GDPR.
- Voluntary Nature: Providing health data is not legally or contractually required. However, without it, tracking and analysis features are not available.

B. App Functionality
Processing of settings and profiles is based on Art. 6(1)(b) GDPR (performance of a contract/usage agreement).

C. Support & Feedback
Handled based on Art. 6(1)(b) GDPR and our legitimate interest in support quality and abuse prevention (Art. 6(1)(f) GDPR).
''',
    ),
    _LegalSection(
      title: '4. Categories of Recipients',
      content: '''
Apart from technical connection data processed by the hosting provider and third-party services described below, we do not receive the contents of your in‑app data. Recipients of technical or user-generated data may be:

- AI Providers (OpenAI, Google, etc.): Act as separate controllers when you use BYOK AI features.
- Catalog Services (Open Food Facts, wger, GitHub): Receive technical connection data (IP, User-Agent) during updates.
- Cloud Providers (Apple/Google): Receive data via your system-wide backups if enabled.
''',
    ),
    _LegalSection(
      title: '5. International Data Transfers (BYOK AI)',
      content: '''
When using AI services, data may be transferred to third countries (especially the USA) subject to Art. 44 et seq. GDPR.

- Safeguards: Providers typically use Standard Contractual Clauses (SCCs) or other legal mechanisms.
- Note: As you use your own API key, processing is subject to the provider's privacy policy. Please review their policies before transmitting health data.
''',
    ),
    _LegalSection(
      title: '6. HealthKit & Health Connect Integration',
      content: '''
Train Libre can read and write health data via Apple HealthKit and Google Health Connect. This synchronization happens entirely on your device. The app only accesses these services if you explicitly grant permission in your system settings. Please also review Apple’s and Google’s separate privacy policies for these health platforms.
''',
    ),
    _LegalSection(
      title: '7. No Tracking / No Analytics',
      content: '''
The app does not use tracking or analytics SDKs (e.g., Firebase Analytics, Google Analytics, Sentry). No profiling for marketing purposes is performed.
''',
    ),
    _LegalSection(
      title: '8. Retention Periods',
      content: '''
- App Data: Stored on your device until deleted or uninstalled.
- E-Mails: Retained only as long as needed for handling the request and documentation, subject to statutory retention duties.
''',
    ),
    _LegalSection(
      title: '9. Web Hosting (GitHub Pages)',
      content: '''
This website is hosted on GitHub Pages. The service provider is GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA (and GitHub B.V., Vijzelstraat 68-72, 1017 HL Amsterdam, The Netherlands, according to GitHub’s privacy statement). When you access our website, your browser connects to GitHub’s servers. In this context, technical data such as your IP address, requested URL, date and time, browser and operating system information may be stored in server log files.
The legal basis is our legitimate interest in providing a secure and efficient website according to Art. 6(1)(f) GDPR.

For details, please see GitHub’s privacy statement at https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement.
''',
    ),
    _LegalSection(
      title: '10. Your Data Subject Rights',
      content: '''
You have the following rights:

- Access (Art. 15)
- Rectification (Art. 16)
- Erasure (Art. 17)
- Restriction of processing (Art. 18)
- Data portability (Art. 20)
- Objection (Art. 21)
- Withdrawal of consent (Art. 7(3)) with future effect.

You also have the right to lodge a complaint with a supervisory authority (Art. 77), such as the Berlin Commissioner for Data Protection and Freedom of Information.
''',
    ),
  ],
);
