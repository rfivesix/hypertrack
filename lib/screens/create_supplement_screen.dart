// lib/screens/create_supplement_screen.dart
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/supplement.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../util/util_convert.dart';
import '../widgets/global_app_bar.dart';

/// A screen for creating or editing a supplement definition.
///
/// Allows configuring the supplement's name, default dose, unit,
/// daily goals/limits, and personal notes.
class CreateSupplementScreen extends StatefulWidget {
  /// The supplement to edit, or null if creating a new one.
  final Supplement? supplementToEdit;
  const CreateSupplementScreen({super.key, this.supplementToEdit});

  @override
  State<CreateSupplementScreen> createState() => _CreateSupplementScreenState();
}

class _CreateSupplementScreenState extends State<CreateSupplementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _goalController = TextEditingController();
  final _limitController = TextEditingController();
  final _notesController = TextEditingController();

  late final l10n = AppLocalizations.of(context)!;

  bool get _isEditing => widget.supplementToEdit != null;

  late String _unit;
  late bool _isTracked;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.supplementToEdit!;
      _nameController.text = s.name;
      _doseController.text = s.defaultDose.toString();
      _goalController.text = s.dailyGoal?.toString() ?? '';
      _limitController.text = s.dailyLimit?.toString() ?? '';
      _notesController.text = s.notes ?? '';
      _unit = s.unit;
      _isTracked = s.isTracked;
    } else {
      _unit = 'mg'; // Default bei Neuanlage
      _isTracked = true; // Default to tracked
    }
  }

  Future<void> _saveSupplement() async {
    if (!_formKey.currentState!.validate()) return;

    final editing = _isEditing ? widget.supplementToEdit : null;
    final bool isBuiltinCaffeine =
        (editing?.isBuiltin == true) && (editing?.code == 'caffeine');

    // Einheit festlegen/absichern
    String unitToSave = isBuiltinCaffeine ? 'mg' : _unit;

    final newSupplement = Supplement(
      id: editing?.id,
      code: editing?.code, // bei Edit beibehalten; bei New null
      name: _nameController.text.trim(),
      defaultDose:
          double.tryParse(_doseController.text.replaceAll(',', '.')) ?? 0.0,
      unit: unitToSave,
      dailyGoal: _goalController.text.trim().isEmpty
          ? null
          : double.tryParse(_goalController.text.replaceAll(',', '.')),
      dailyLimit: _limitController.text.trim().isEmpty
          ? null
          : double.tryParse(_limitController.text.replaceAll(',', '.')),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isBuiltin: editing?.isBuiltin ?? false,
      isTracked: _isTracked,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateSupplement(newSupplement);
    } else {
      await DatabaseHelper.instance.insertSupplement(newSupplement);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // NEU: Caffeine-Lock bestimmen
    final s = widget.supplementToEdit;
    final bool isBuiltinCaffeine =
        (s?.isBuiltin == true) && (s?.code == 'caffeine');
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: _isEditing ? l10n.edit : l10n.createSupplementTitle,
        actions: [
          TextButton(
            onPressed: _saveSupplement,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                _nameController,
                l10n.supplementNameLabel,
                isRequired: true,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _doseController,
                      l10n.defaultDoseLabel,
                      isNumeric: true,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),

                  // <- Wichtig: begrenzen!
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      items: allowedUnits
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u,
                              child: Text(u),
                            ),
                          )
                          .toList(),
                      onChanged: isBuiltinCaffeine
                          ? null
                          : (val) {
                              if (val == null) return;
                              setState(() => _unit = val);
                            },
                      decoration: InputDecoration(
                        labelText: l10n.unitLabel,
                        isDense: true, // optional, macht's kompakter
                        helperText:
                            isBuiltinCaffeine ? l10n.caffeineUnitLocked : null,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return l10n.fieldRequired;
                        }
                        if (!allowedUnits.contains(val)) {
                          return l10n.unitNotSupported;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingXL),
              _buildTextField(
                _goalController,
                l10n.dailyGoalLabel,
                isNumeric: true,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              _buildTextField(
                _limitController,
                l10n.dailyLimitLabel,
                isNumeric: true,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              _buildTextField(_notesController, l10n.notesLabel, maxLines: 3),
              const SizedBox(height: DesignConstants.spacingXL),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.currentlyTracking),
                subtitle: Text(l10n.currentlyTrackingDesc),
                value: _isTracked,
                onChanged: (val) {
                  setState(() {
                    _isTracked = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    bool isNumeric = false,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return l10n.validatorPleaseEnterName;
        }
        if (isNumeric &&
            value != null &&
            value.isNotEmpty &&
            double.tryParse(value.replaceAll(',', '.')) == null) {
          return l10n.validatorPleaseEnterNumber;
        }
        return null;
      },
    );
  }
}
