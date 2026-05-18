import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';
import '../../../data/database_helper.dart';
import 'meal_editor_screen.dart';

/// A screen that displays a list of the user's saved meals.
///
/// Provides access to create new meals or edit existing ones.
class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  List<Map<String, dynamic>> _meals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reloadMeals();
  }

  Future<void> _reloadMeals() async {
    final meals = await DatabaseHelper.instance.getMeals();
    if (!mounted) return;
    setState(() {
      _meals = meals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMeals)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meals.isEmpty
              ? Center(
                  child: Text(
                    '${l10n.mealsEmptyTitle}\n${l10n.mealsEmptyBody}',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: _meals.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_meals[i]['name'] as String? ?? ''),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealEditorScreen(
                            initialName: _meals[i]['name'] as String?,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _reloadMeals();
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text(l10n.mealSaved)),
                        );
                      }
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MealEditorScreen()),
          );
          if (result == true) {
            await _reloadMeals();
            if (!mounted) return;
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(content: Text(l10n.mealSaved)),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
