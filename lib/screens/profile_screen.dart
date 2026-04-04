// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/drift_database.dart' as db; // Zugriff auf Profile-Klasse
import '../generated/app_localizations.dart';
import 'goals_screen.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import '../services/profile_service.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/summary_card.dart';
import 'package:provider/provider.dart';
import '../widgets/global_app_bar.dart';

/// A screen for managing user-specific identity and data.
///
/// Allows editing the user profile (name, gender, age), managing the profile picture,
/// and provides entry points to app settings and goals.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  db.Profile? _userProfile;
  bool _isLoading = true;

  bool _shouldReloadAfterSettings(bool? result) {
    return result == true || (result == null && Platform.isIOS);
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await DatabaseHelper.instance.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  /// Berechnet das Alter basierend auf dem Geburtstag
  String _calculateAge(DateTime? birthday) {
    if (birthday == null) return '';
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return '$age Jahre';
  }

  /// Öffnet den Editor für Profildaten
  Future<void> _showEditProfileDialog() async {
    final l10n = AppLocalizations.of(context)!;

    // Controller mit aktuellen Werten initialisieren
    final nameCtrl = TextEditingController(text: _userProfile?.username ?? '');
    DateTime? selectedDate = _userProfile?.birthday;
    String? selectedGender = _userProfile?.gender ?? 'male';
    // Fallback für Height, falls wir das auch hier editieren wollen (optional)
    final heightCtrl = TextEditingController(
      text: _userProfile?.height?.toString() ?? '',
    );

    await showGlassBottomMenu(
      context: context,
      title: 'Profil bearbeiten',
      contentBuilder: (ctx, close) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateText = selectedDate == null
                ? 'Geburtsdatum wählen'
                : DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  ).format(selectedDate!);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Geburtstag & Geschlecht in einer Zeile
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.onboardingDobLabel,
                            prefixIcon: const Icon(Icons.cake_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            dateText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        decoration: InputDecoration(
                          labelText: l10n.onboardingGenderLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text(l10n.genderMale),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text(l10n.genderFemale),
                          ),
                          DropdownMenuItem(
                            value: 'diverse',
                            child: Text(l10n.genderDiverse),
                          ),
                        ],
                        onChanged: (val) =>
                            setModalState(() => selectedGender = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          close();
                          Navigator.of(ctx).pop();
                        },
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // Speichern
                          await DatabaseHelper.instance.saveUserProfile(
                            name: nameCtrl.text.trim(),
                            birthday: selectedDate,
                            height: int.tryParse(
                              heightCtrl.text,
                            ), // optional, sonst null lassen wenn nicht im UI
                            gender: selectedGender,
                          );
                          close();
                          Navigator.of(ctx).pop();
                          // UI neu laden
                          _loadProfileData();
                        },
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileService = Provider.of<ProfileService>(context);
    final theme = Theme.of(context);
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    // Daten für die Anzeige vorbereiten
    final String displayName = _userProfile?.username?.isNotEmpty == true
        ? _userProfile!.username!
        : 'Dein Name'; // Fallback

    final String ageString = _calculateAge(_userProfile?.birthday);

    String genderString = '';
    if (_userProfile?.gender == 'male') {
      genderString = l10n.genderMale;
    } else if (_userProfile?.gender == 'female')
      genderString = l10n.genderFemale;
    else if (_userProfile?.gender == 'diverse')
      genderString = l10n.genderDiverse;

    // Kombinierter String: "25 Jahre • Männlich"
    final String subline = [
      ageString,
      genderString,
    ].where((s) => s.isNotEmpty).join(' • ');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.profileScreenTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top + topPadding,
              ),
              children: [
                // --- NEUE PROFIL-KARTE (Row statt Column) ---
                SummaryCard(
                  // padding: EdgeInsets.zero, // Padding manuell steuern für Klick-Bereich
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap:
                        _showEditProfileDialog, // Öffnet Editor bei Klick auf die Karte
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Linke Seite: Bild
                          GestureDetector(
                            onTap: () async {
                              // Nur Bild ändern bei Klick auf das Bild
                              await profileService.pickAndSaveProfileImage();
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  key: ValueKey(
                                    '${profileService.profileImagePath ?? ''}${profileService.cacheBuster}',
                                  ),
                                  radius:
                                      40, // Etwas kleiner als vorher (war 50), passt besser in Row
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  backgroundImage:
                                      profileService.profileImagePath != null
                                          ? FileImage(
                                              File(
                                                profileService
                                                    .profileImagePath!,
                                              ),
                                            )
                                          : null,
                                  child: profileService.profileImagePath == null
                                      ? Icon(
                                          Icons.person,
                                          size: 40,
                                          color: theme.colorScheme.primary,
                                        )
                                      : null,
                                ),
                                // Kleines Edit-Icon am Bild
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.cardColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Rechte Seite: Text-Daten
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (subline.isNotEmpty)
                                  Text(
                                    subline,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                else
                                  Text(
                                    "Tippen zum Einrichten",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Pfeil nach rechts als Indikator
                          Icon(
                            Icons.edit_outlined,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (profileService.profileImagePath != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        await profileService.deleteProfileImage();
                      },
                      child: Text(l10n.delete_profile_picture_button),
                    ),
                  ),

                const SizedBox(height: DesignConstants.spacingM),

                // Sektion für Navigation (Unverändert)
                _buildNavigationCard(
                  icon: Icons.settings_outlined,
                  title: l10n.settingsTitle,
                  subtitle: l10n.settingsDescription,
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    // Reload after explicit settings changes, and on iOS swipe
                    // back where no pop result is propagated.
                    if (_shouldReloadAfterSettings(result) && mounted) {
                      _loadProfileData();
                    }
                  },
                ),
                // const SizedBox(height: DesignConstants.spacingM),
                _buildNavigationCard(
                  icon: Icons.flag_outlined,
                  title: l10n.my_goals,
                  subtitle: l10n.my_goals_description,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GoalsScreen(),
                      ),
                    );
                  },
                ),
                // const SizedBox(height: DesignConstants.spacingM),
                _buildOnboardingCard(l10n),
                const BottomContentSpacer(),
              ],
            ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        leading: Icon(
          icon,
          size: 36,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return SummaryCard(
      child: ListTile(
        leading: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
        title: Text(
          l10n.onbShowTutorialAgain,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(l10n.onbFinishBody, style: theme.textTheme.bodyMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
