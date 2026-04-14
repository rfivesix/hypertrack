import 'dart:async';

import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../services/haptic_feedback_service.dart';
import 'food_detail_screen.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/glass_fab.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/swipe_action_background.dart';

/// A comprehensive screen for viewing and editing a meal and its ingredients.
///
/// Displays nutritional totals for the meal and allows users to add, remove,
/// or adjust quantities of individual ingredients. Meals can be added directly
/// to the daily diary from this screen.
class MealScreen extends StatefulWidget {
  /// The meal data as a map containing 'id', 'name', and 'notes'.
  final Map<String, dynamic> meal; // expected: {id, name, notes}
  /// Whether to open the screen in edit mode initially.
  final bool startInEdit;

  const MealScreen({super.key, required this.meal, this.startInEdit = false});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  bool _editMode = false;
  bool _saving = false;

  List<Map<String, dynamic>> _items = [];
  bool _loadingItems = true;

  // Totals (recomputed from `_items` whenever data changes).
  int _totalKcal = 0;
  double _totalC = 0, _totalF = 0, _totalP = 0;

  @override
  void initState() {
    super.initState();
    _editMode = widget.startInEdit;
    _nameCtrl = TextEditingController(
      text: widget.meal['name'] as String? ?? '',
    );
    _notesCtrl = TextEditingController(
      text: widget.meal['notes'] as String? ?? '',
    );
    _loadItems();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    final id = widget.meal['id'] as int;
    final rows = await DatabaseHelper.instance.getMealItems(id);
    _items = List<Map<String, dynamic>>.from(rows);
    await _recomputeTotals(); // Initial totals.
    if (mounted) setState(() => _loadingItems = false);
  }

  /// Recomputes aggregate kcal / carbs / fat / protein totals.
  Future<void> _recomputeTotals() async {
    int kcal = 0;
    double c = 0, f = 0, p = 0;

    for (final it in _items) {
      final bc = it['barcode'] as String;
      final qty = (it['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;
      final fi = await ProductDatabaseHelper.instance.getProductByBarcode(bc);
      if (fi == null) continue;

      final factor = qty / 100.0;
      final itemKcal = (fi.calories) * factor;
      final itemC = (fi.carbs) * factor;
      final itemF = (fi.fat) * factor;
      final itemP = (fi.protein) * factor;

      kcal += itemKcal.round();
      c += itemC;
      f += itemF;
      p += itemP;
    }

    _totalKcal = kcal;
    _totalC = c;
    _totalF = f;
    _totalP = p;
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final canSave =
        _nameCtrl.text.trim().isNotEmpty && _items.isNotEmpty && !_saving;

    // Compute top padding for content shown beneath GlobalAppBar.
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    // Floating action button configuration by mode.
    Widget? fab;
    if (_editMode) {
      fab = GlassFab(
        label: l10n.mealAddIngredient,
        onPressed: _addIngredientFlow,
      );
    } else {
      if (_items.isNotEmpty) {
        fab = GlassFab(
          label: l10n.mealsAddToDiary,
          onPressed: _addMealToDiaryFlow,
        );
      } else {
        fab = null;
      }
    }

    return Scaffold(
      // Extend body behind app bar to support the glass effect.
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        // Use GlobalAppBar for consistent app-wide behavior.
        title: _editMode
            ? l10n.mealsEdit
            : (_nameCtrl.text.isNotEmpty
                ? _nameCtrl.text
                : l10n.mealsViewTitle),
        actions: [
          if (_editMode)
            TextButton(
              onPressed: canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.save,
                      style: TextStyle(
                        color: canSave
                            ? theme.colorScheme.primary
                            : theme.disabledColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            )
          else
            TextButton(
              onPressed: () => setState(() => _editMode = true),
              child: Text(
                l10n.mealsEdit,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _loadingItems
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              // Apply top padding so list content clears the app bar.
              padding: EdgeInsets.fromLTRB(16, 12 + topPadding, 16, 96),
              children: [
                // Name and notes section.
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _editMode
                            ? TextField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: l10n.mealNameLabel,
                                ),
                                onChanged: (_) => setState(() {}),
                              )
                            : Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text
                                    : l10n.unknown,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        const SizedBox(height: 8),
                        _editMode
                            ? TextField(
                                controller: _notesCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: l10n.mealNotesLabel,
                                ),
                              )
                            : Text(
                                _notesCtrl.text.isNotEmpty
                                    ? _notesCtrl.text
                                    : l10n.noNotes,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // === NÄHRWERTE (Gesamtsumme) ===
                _buildSectionTitle(context, l10n.nutritionSectionLabel),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: FutureBuilder<void>(
                      future: _recomputeTotals(),
                      builder: (_, __) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _items.isEmpty ? '– kcal' : '$_totalKcal kcal',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                _MacroChip(
                                  label: 'C',
                                  value:
                                      _items.isEmpty ? '–' : _format1(_totalC),
                                  unit: 'g',
                                ),
                                _MacroChip(
                                  label: 'F',
                                  value:
                                      _items.isEmpty ? '–' : _format1(_totalF),
                                  unit: 'g',
                                ),
                                _MacroChip(
                                  label: 'P',
                                  value:
                                      _items.isEmpty ? '–' : _format1(_totalP),
                                  unit: 'g',
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // === ZUTATEN ===
                _buildSectionTitle(context, l10n.ingredientsCapsLock),

                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.emptyCategory,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: List.generate(_items.length, (i) {
                      final it = _items[i];
                      return _IngredientCard(
                        key: ValueKey('ing_$i'),
                        item: it,
                        editMode: _editMode,
                        showPerIngredientMacros: !_editMode,
                        onQtyChanged: (val) async {
                          _items[i]['quantity_in_grams'] = val;
                          await _recomputeTotals();
                          if (mounted) setState(() {});
                        },
                        onDelete: () async {
                          final ok = await showDeleteConfirmation(
                            context,
                            title: l10n.deleteConfirmTitle,
                            content: l10n.deleteConfirmContent,
                          );

                          if (ok) {
                            setState(() => _items.removeAt(i));
                            await _recomputeTotals();
                            if (mounted) setState(() {});
                          }
                        },
                      );
                    }),
                  ),
              ],
            ),
    );
  }

  String _format1(double v) => v.toStringAsFixed(1);

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _items.isEmpty) return;

    setState(() => _saving = true);
    try {
      final mealId = widget.meal['id'] as int;
      await DatabaseHelper.instance.updateMeal(
        mealId,
        name: name,
        notes: _notesCtrl.text.trim(),
      );
      await DatabaseHelper.instance.clearMealItems(mealId);
      for (final it in _items) {
        final grams = (it['quantity_in_grams'] as int?) ?? 0;
        await DatabaseHelper.instance.addMealItem(
          mealId,
          barcode: it['barcode'] as String,
          grams: grams,
        );
      }
      if (mounted) {
        setState(() => _editMode = false);
        HapticFeedbackService.instance.confirmationFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mealSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  // In lib/screens/meal_screen.dart

  Future<void> _addIngredientFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final searchCtrl = TextEditingController();
    // Menge standardmäßig auf 100
    final qtyCtrl = TextEditingController(text: '100');

    // 1. Schritt: Produkt auswählen
    // Wir öffnen das Such-Menu. Es gibt ein Tuple (Barcode, Menge) zurück.
    final picked = await showGlassBottomMenu<(String, int)?>(
      context: context,
      title: l10n.mealAddIngredient,
      contentBuilder: (searchCtx, closeSearch) {
        // Lokaler State für Suchergebnisse
        List<FoodItem> results = [];
        bool loading = false;
        Timer? debounce;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            Future<void> runSearch(String q) async {
              if (q.trim().isEmpty) {
                setStateSB(() => results = []);
                return;
              }
              setStateSB(() => loading = true);
              final res = await ProductDatabaseHelper.instance.searchProducts(
                q.trim(),
              );
              setStateSB(() {
                results = res;
                loading = false;
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchHintText,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    debounce?.cancel();
                    debounce = Timer(
                      const Duration(milliseconds: 300),
                      () => runSearch(val),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (loading) const LinearProgressIndicator(minHeight: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            searchCtrl.text.isEmpty
                                ? l10n.searchInitialHint
                                : l10n.searchNoResults,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final fi = results[i];
                            return ListTile(
                              dense: true,
                              title: Text(fi.name),
                              subtitle: Text(fi.brand),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () async {
                                  // HIER IST DER FIX:
                                  // Wir schließen das Such-Menü NICHT sofort.
                                  // Wir öffnen den Mengen-Dialog DARÜBER (nested) oder ersetzen den Content.
                                  // Am sichersten: Wir fragen die Menge in einem separaten Schritt ab.

                                  // Menge abfragen
                                  // HINWEIS: Wir nutzen hier den searchCtx für den Navigator, um im selben Overlay-Kontext zu bleiben
                                  // oder wir schließen und öffnen neu.

                                  // Strategie: Schließen und Ergebnis (Barcode) zurückgeben,
                                  // dann im Parent die Menge abfragen. Das ist am stabilsten.
                                  closeSearch();
                                  Navigator.of(searchCtx).pop(
                                    (fi.barcode, -1),
                                  ); // -1 signalisiert: "Barcode gewählt, Menge fragen"
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    // Wenn nichts gewählt wurde, abbrechen
    if (picked == null) return;

    final String barcode = picked.$1;
    int quantity = picked.$2;

    // Wenn Menge noch nicht festgelegt (-1), dann jetzt abfragen
    if (quantity == -1) {
      // Produktnamen laden für den Titel
      final fi = await ProductDatabaseHelper.instance.getProductByBarcode(
        barcode,
      );
      final displayName = fi?.name ?? barcode;

      if (!mounted) return;

      final qtyResult = await showGlassBottomMenu<int?>(
        context: context,
        title: displayName,
        contentBuilder: (qtyCtx, closeQty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.mealIngredientAmountLabel),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(suffixText: 'g/ml'),
                onSubmitted: (val) {
                  final q = int.tryParse(val);
                  closeQty();
                  Navigator.of(qtyCtx).pop(q);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        closeQty();
                        Navigator.of(qtyCtx).pop(null);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final val = int.tryParse(qtyCtrl.text);
                        closeQty();
                        Navigator.of(qtyCtx).pop(val);
                      },
                      child: Text(l10n.add_button),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (qtyResult != null && qtyResult > 0) {
        quantity = qtyResult;
      } else {
        return; // Abgebrochen bei Menge
      }
    }

    // Hinzufügen zur Liste
    if (quantity > 0) {
      setState(() {
        _items.add({'barcode': barcode, 'quantity_in_grams': quantity});
      });
      await _recomputeTotals();
      if (mounted) setState(() {});
    }
  }

  /// Aktuelle Mahlzeit als einzelne FoodEntries ins Tagebuch
  Future<void> _addMealToDiaryFlow() async {
    final l10n = AppLocalizations.of(context)!;

    // Load products
    final Map<String, FoodItem?> products = {};
    for (final it in _items) {
      final bc = it['barcode'] as String;
      products[bc] = await ProductDatabaseHelper.instance.getProductByBarcode(
        bc,
      );
    }

    // Controllers for quantities
    final Map<String, TextEditingController> qtyCtrls = {
      for (final it in _items)
        (it['barcode'] as String): TextEditingController(
          text: '${it['quantity_in_grams']}',
        ),
    };

    const internalTypes = [
      'mealtypeBreakfast',
      'mealtypeLunch',
      'mealtypeDinner',
      'mealtypeSnack',
    ];
    String selectedMealType = internalTypes.first;

    final Map<String, String> mealTypeLabel = {
      'mealtypeBreakfast': l10n.mealtypeBreakfast,
      'mealtypeLunch': l10n.mealtypeLunch,
      'mealtypeDinner': l10n.mealtypeDinner,
      'mealtypeSnack': l10n.mealtypeSnack,
    };
    if (!mounted) return;

    final ok = await showGlassBottomMenu<bool>(
          context: context,
          title: l10n.mealsAddToDiary,
          contentBuilder: (ctx, close) {
            return StatefulBuilder(
              builder: (ctx, modalSetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nameCtrl.text,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: InputDecoration(
                        labelText: l10n.mealTypeLabel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: internalTypes
                          .map(
                            (key) => DropdownMenuItem(
                              value: key,
                              child: Text(mealTypeLabel[key] ?? key),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          modalSetState(() => selectedMealType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final it = _items[i];
                          final bc = it['barcode'] as String;
                          final fi = products[bc];
                          final displayName =
                              (fi?.name.isNotEmpty ?? false) ? fi!.name : bc;
                          final unit = (fi?.isLiquid == true) ? 'ml' : 'g';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 14),
                                child: Icon(Icons.lunch_dining),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: qtyCtrls[bc],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: displayName,
                                    helperText: l10n.amountLabel,
                                    suffixText: unit,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              close();
                              Navigator.of(ctx).pop(false);
                            },
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              close();
                              Navigator.of(ctx).pop(true);
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
        ) ??
        false;

    if (!ok) return;

    final ts = DateTime.now();
    for (final it in _items) {
      final bc = it['barcode'] as String;
      final ctrl = qtyCtrls[bc]!;
      final qty =
          int.tryParse(ctrl.text.trim()) ?? (it['quantity_in_grams'] as int);

      await DatabaseHelper.instance.insertFoodEntry(
        FoodEntry(
          barcode: bc,
          timestamp: ts,
          quantityInGrams: qty,
          mealType: selectedMealType,
        ),
      );

      final fi = await ProductDatabaseHelper.instance.getProductByBarcode(bc);
      if (fi != null) {
        if (fi.isLiquid == true) {
          // water logging if desired
        }
        final c100 = fi.caffeineMgPer100ml;
        if (fi.isLiquid == true && c100 != null && c100 > 0) {
          await _logCaffeineDose(c100 * (qty / 100.0), ts);
        }
      }
    }

    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mealAddedToDiarySuccess)));
    }
  }

  Future<void> _logCaffeineDose(double doseMg, DateTime timestamp) async {
    if (doseMg <= 0) return;

    final supplements = await DatabaseHelper.instance.getAllSupplements();
    final caffeine = supplements.firstWhere(
      (s) => (s.code == 'caffeine') || s.name.toLowerCase() == 'caffeine',
      orElse: () => Supplement(
        name: 'Caffeine',
        defaultDose: 100,
        unit: 'mg',
        dailyLimit: 400,
        code: 'caffeine',
        isBuiltin: true,
      ),
    );

    final caffeineId = caffeine.id ??
        (await DatabaseHelper.instance.insertSupplement(caffeine)).id!;

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineId,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
      ),
    );
  }
}

/// Kleines “Chip”-Label für C/F/P
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _MacroChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label  $value$unit',
        style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Einzelne Zutat als SummaryCard
/// - View-Modus: Name (tappable) + kleine kcal rechts + (darunter) C/F/P
/// - Edit-Modus: rechts Mengenfeld; Swipe nach links = Löschen
class _IngredientCard extends StatelessWidget {
  final Map<String, dynamic> item; // { barcode, quantity_in_grams }
  final bool editMode;
  final bool showPerIngredientMacros;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onDelete;

  const _IngredientCard({
    super.key,
    required this.item,
    required this.editMode,
    required this.showPerIngredientMacros,
    required this.onQtyChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final bc = item['barcode'] as String;
    final qty = (item['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;

    Widget buildCard(FoodItem? fi) {
      final name = (fi?.name.isNotEmpty ?? false) ? fi!.name : bc;
      final unit = (fi?.isLiquid == true) ? 'ml' : 'g';

      // per-ingredient macros & kcal
      int kcal = 0;
      double c = 0, f = 0, p = 0;
      if (fi != null) {
        final factor = qty / 100.0;
        kcal = ((fi.calories) * factor).round();
        c = (fi.carbs) * factor;
        f = (fi.fat) * factor;
        p = (fi.protein) * factor;
      }

      final title = InkWell(
        onTap: () {
          if (fi != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FoodDetailScreen(foodItem: fi)),
            );
          }
        },
        child: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      final trailingView = Text(
        fi == null ? '–' : '$kcal kcal',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );

      final trailingEdit = SizedBox(
        width: 96,
        child: TextFormField(
          initialValue: '${qty.toInt()}',
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            isDense: true,
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            final parsed = int.tryParse(v.trim());
            if (parsed != null && parsed >= 0) onQtyChanged(parsed);
          },
        ),
      );

      return SummaryCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  Icon(Icons.local_dining, color: color),
                  const SizedBox(width: 12),
                  Expanded(child: title),
                  if (!editMode) trailingView else trailingEdit,
                ],
              ),
              if (showPerIngredientMacros && fi != null) ...[
                const SizedBox(height: 6),
                Text(
                  'C ${c.toStringAsFixed(1)} g   •   F ${f.toStringAsFixed(1)} g   •   P ${p.toStringAsFixed(1)} g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final card = FutureBuilder<FoodItem?>(
      future: ProductDatabaseHelper.instance.getProductByBarcode(bc),
      builder: (_, snap) => buildCard(snap.data),
    );

    if (!editMode) return card;

    // Edit-Modus: Swipe links = löschen
    return Dismissible(
      key: ValueKey('ing_${item['barcode']}_${item['quantity_in_grams']}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
        return false;
      },
      child: card,
    );
  }
}
