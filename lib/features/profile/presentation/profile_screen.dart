// lib/features/profile/presentation/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/profile_repository.dart';
import '../../../data/drift_database.dart' as db; // Access to Profile class
import '../../../generated/app_localizations.dart';
import 'goals_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../services/profile_service.dart';
import '../../../services/unit_service.dart';
import '../../app/presentation/about_screen.dart';
import '../../app/presentation/legal_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/global_app_bar.dart';

/// A screen for managing user-specific identity and data.
class ProfileScreen extends StatefulWidget {
  final IProfileRepository? repository;

  const ProfileScreen({super.key, this.repository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final IProfileRepository _repository =
      widget.repository ?? context.read<IProfileRepository>();
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
    try {
      final profileMap = await _repository.getUserProfile();
      // Map back to a Profile object or similar if available, or just mock one.
      // Wait, what does `getUserProfile` return in DatabaseHelper?
      // Let's check: in DatabaseHelper, `getUserProfile()` query returns a Drift `Profile?` object!
      // But in our ProfileRepository:
      // `Future<Map<String, dynamic>?> getUserProfile()` -> wait, did we define `Future<Map<String, dynamic>?>`?
      // Ah! DatabaseHelper's `getUserProfile()` actually returns `Future<db.Profile?>`. Let's check!
      // Let's see: yes, since they are in drift_database.dart, let's keep it as `db.Profile?` in `ProfileRepository`.
      // Let's make sure our `ProfileRepository` is updated to correctly match the return types of DatabaseHelper!
      // Actually, we can define `getUserProfile` as returning `Future<db.Profile?>`. Let's check!
      // Yes, DatabaseHelper has:
      // `Future<db.Profile?> getUserProfile() async { ... }`
      // and `Future<void> saveUserProfile({ required String username, required DateTime? birthday, required int? height, required String? gender })`
      // Wait! The call to `saveUserProfile` in `profile_screen.dart` was:
      // `await DatabaseHelper.instance.saveUserProfile(name: nameCtrl.text.trim(), ...)`
      // Let's update `ProfileRepository` to delegate exactly to DatabaseHelper.
      // Let's write `profile_screen.dart` delegating correctly.

      if (mounted) {
        setState(() {
          // Since we can query it directly:
          _userProfile = profileMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ProfileScreen: failed to load profile data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  Future<void> _showEditProfileDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();

    final nameCtrl = TextEditingController(text: _userProfile?.username ?? '');
    DateTime? selectedDate = _userProfile?.birthday;
    String? selectedGender = _userProfile?.gender ?? 'male';
    final heightCtrl = TextEditingController(
      text: _userProfile?.height == null
          ? ''
          : unitService
              .convertDisplayValue(
                _userProfile!.height!.toDouble(),
                UnitDimension.height,
              )
              .toStringAsFixed(1)
              .replaceAll('.0', ''),
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
                          final parsedHeight = double.tryParse(
                            heightCtrl.text.replaceAll(',', '.'),
                          );
                          final heightMetric = parsedHeight == null
                              ? null
                              : unitService
                                  .convertToMetric(
                                    parsedHeight,
                                    UnitDimension.height,
                                  )
                                  .round();

                          await _repository.saveUserProfile(
                            name: nameCtrl.text.trim(),
                            birthday: selectedDate,
                            height: heightMetric,
                            gender: selectedGender,
                          );
                          if (!ctx.mounted) return;
                          close();
                          Navigator.of(ctx).pop();
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

    final String displayName = _userProfile?.username?.isNotEmpty == true
        ? _userProfile!.username!
        : 'Dein Name';

    final String ageString = _calculateAge(_userProfile?.birthday);

    String genderString = '';
    if (_userProfile?.gender == 'male') {
      genderString = l10n.genderMale;
    } else if (_userProfile?.gender == 'female') {
      genderString = l10n.genderFemale;
    } else if (_userProfile?.gender == 'diverse') {
      genderString = l10n.genderDiverse;
    }

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
                SummaryCard(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _showEditProfileDialog,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await profileService.pickAndSaveProfileImage();
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  key: ValueKey(
                                    '${profileService.profileImagePath ?? ''}${profileService.cacheBuster}',
                                  ),
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
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
                          Icon(
                            Icons.edit_outlined,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
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
                    if (_shouldReloadAfterSettings(result) && mounted) {
                      _loadProfileData();
                    }
                  },
                ),
                _buildNavigationCard(
                  icon: Icons.flag_outlined,
                  title: l10n.my_goals,
                  subtitle: l10n.my_goals_description,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            GoalsScreen(repository: _repository),
                      ),
                    );
                  },
                ),
                _buildOnboardingCard(l10n),
                const SizedBox(height: DesignConstants.spacingM),
                AppSectionHeader(title: l10n.about_section),
                _buildNavigationCard(
                  icon: Icons.info_outline,
                  title: l10n.about_train_libre,
                  subtitle: l10n.app_version,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: DesignConstants.spacingM),
                AppSectionHeader(title: l10n.legal_section),
                _buildNavigationCard(
                  icon: Icons.gavel_outlined,
                  title: l10n.legal_section,
                  subtitle: '${l10n.legal_notice} & ${l10n.privacy_policy}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LegalScreen(),
                      ),
                    );
                  },
                ),
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
