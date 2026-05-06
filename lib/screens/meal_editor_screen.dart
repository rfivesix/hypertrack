import 'package:flutter/material.dart';

enum MealType { breakfast, lunch, dinner, snack }

/// A screen for creating or editing the basic metadata of a meal.
///
/// Allows users to specify a name and categorise the meal by [MealType].
class MealEditorScreen extends StatefulWidget {
  /// Initial name for the meal if editing.
  final String? initialName;

  /// The type of meal (e.g., breakfast, lunch).
  final MealType initialType;

  const MealEditorScreen({
    super.key,
    this.initialName,
    this.initialType = MealType.lunch,
  });

  @override
  State<MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends State<MealEditorScreen> {
  late final TextEditingController _nameCtrl;
  late MealType _type;
  bool _saving = false;

  bool get _canSave =>
      !_saving && _nameCtrl.text.trim().isNotEmpty; // simpel & robust

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _type = widget.initialType;
    _nameCtrl.addListener(() => setState(() {})); // Update button state
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    try {
      // Later: repo/DB call (insert/update).
      // For now: simulate success and return.
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal bearbeiten'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ElevatedButton(
              onPressed: _canSave ? _onSave : null,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Meal-Name',
              hintText: 'z. B. Hähnchen Bowl',
            ),
            onSubmitted: (_) => _onSave(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MealType>(
            initialValue: _type,
            onChanged: (v) => setState(() => _type = v ?? _type),
            decoration: const InputDecoration(labelText: 'Meal-Typ'),
            items: MealType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(_label(t))))
                .toList(),
          ),
          const SizedBox(height: 24),
          // Placeholder: later ingredients/per-ingredient display
          Card(
            child: ListTile(
              title: const Text('Zutaten'),
              subtitle: const Text('Noch keine – kommt später'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Later: open product picker
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _label(MealType t) {
  switch (t) {
    case MealType.breakfast:
      return 'Frühstück';
    case MealType.lunch:
      return 'Mittag';
    case MealType.dinner:
      return 'Abend';
    case MealType.snack:
      return 'Snack';
  }
}
