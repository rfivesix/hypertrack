// lib/screens/ai_recommendation_screen.dart

import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../services/ai_service.dart';
import '../widgets/global_app_bar.dart';
import 'ai_settings_screen.dart';

/// AI Meal Recommendation screen — generates a personalised meal suggestion
/// that fits the user's remaining daily macros and dietary preferences.
class AiRecommendationScreen extends StatefulWidget {
  /// The meal slot to save into (e.g. 'mealtypeLunch').
  final String mealType;

  /// The date for which to calculate remaining macros.
  final DateTime date;

  const AiRecommendationScreen({
    super.key,
    required this.mealType,
    required this.date,
  });

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen>
    with SingleTickerProviderStateMixin {
  // ── Preferences ──
  String? _selectedDietary; // Vegan, Vegetarian, Pescetarian
  String? _selectedSituation; // On the go, No kitchen, Quick
  final TextEditingController _customRequestController =
      TextEditingController();

  // ── State ──
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;

  // ── Result ──
  AiMealRecommendation? _recommendation;
  List<_MatchedIngredient> _matchedIngredients = [];
  Map<String, int>? _remainingMacros;

  // ── Animation ──
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _customRequestController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Generation
  // ---------------------------------------------------------------------------

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _recommendation = null;
      _matchedIngredients = [];
    });

    try {
      final db = DatabaseHelper.instance;

      // 1. Gather context
      final macros = await db.getRemainingMacrosForDate(widget.date);
      final history = await db.getMealHistorySummary();
      final goals = await db.getGoalsForDate(widget.date);

      // Ensure we have some safe fallbacks for daily targets
      final dailyKcal = goals?.targetCalories ?? 2500;
      final dailyP = goals?.targetProtein ?? 180;
      final dailyC = goals?.targetCarbs ?? 250;
      final dailyF = goals?.targetFat ?? 80;

      // 1b. Apportion Macros
      // Calculate target macros specifically for this meal based on the slot.
      Map<String, int> targetMacros = {
        'kcal': macros['kcal'] ?? 0,
        'protein': macros['protein'] ?? 0,
        'carbs': macros['carbs'] ?? 0,
        'fat': macros['fat'] ?? 0,
      };

      if (widget.mealType == 'mealtypeBreakfast') {
        // Breakfast: Target 1/3 of daily goals (clamped to remaining)
        targetMacros['kcal'] = ((dailyKcal / 3.0).round()).clamp(
          0,
          targetMacros['kcal']!,
        );
        targetMacros['protein'] = ((dailyP / 3.0).round()).clamp(
          0,
          targetMacros['protein']!,
        );
        targetMacros['carbs'] = ((dailyC / 3.0).round()).clamp(
          0,
          targetMacros['carbs']!,
        );
        targetMacros['fat'] = ((dailyF / 3.0).round()).clamp(
          0,
          targetMacros['fat']!,
        );
      } else if (widget.mealType == 'mealtypeLunch') {
        // Lunch: Fill up until 1/3 of daily goals is left for dinner
        // E.g., target = remaining - (daily / 3)
        targetMacros['kcal'] =
            (targetMacros['kcal']! - (dailyKcal / 3.0).round()).clamp(
              0,
              targetMacros['kcal']!,
            );
        targetMacros['protein'] =
            (targetMacros['protein']! - (dailyP / 3.0).round()).clamp(
              0,
              targetMacros['protein']!,
            );
        targetMacros['carbs'] =
            (targetMacros['carbs']! - (dailyC / 3.0).round()).clamp(
              0,
              targetMacros['carbs']!,
            );
        targetMacros['fat'] = (targetMacros['fat']! - (dailyF / 3.0).round())
            .clamp(0, targetMacros['fat']!);
      } else if (widget.mealType == 'mealtypeDinner') {
        // Dinner: Eat 100% of whatever is remaining to hit daily goal
        // Already assigned above. (targetMacros == macros)
      } else if (widget.mealType == 'mealtypeSnack') {
        // Snack: Target roughly 10% of daily goals (clamped to remaining)
        targetMacros['kcal'] = ((dailyKcal * 0.1).round()).clamp(
          0,
          targetMacros['kcal']!,
        );
        targetMacros['protein'] = ((dailyP * 0.1).round()).clamp(
          0,
          targetMacros['protein']!,
        );
        targetMacros['carbs'] = ((dailyC * 0.1).round()).clamp(
          0,
          targetMacros['carbs']!,
        );
        targetMacros['fat'] = ((dailyF * 0.1).round()).clamp(
          0,
          targetMacros['fat']!,
        );
      }

      // If user literally has 0 calories left, provide a tiny hardcoded floor
      // so the AI still suggests something (like a 100kcal snack).
      if (targetMacros['kcal']! <= 50) {
        targetMacros['kcal'] = 150;
        targetMacros['protein'] = 15;
        targetMacros['carbs'] = 10;
        targetMacros['fat'] = 5;
      }

      // 2. Build preference list
      final prefs = <String>[];
      if (_selectedDietary != null) prefs.add(_selectedDietary!);
      if (_selectedSituation != null) prefs.add(_selectedSituation!);

      // 3. Call AI
      final l10n = AppLocalizations.of(context)!;
      final languageCode = Localizations.localeOf(context).languageCode;
      final result = await AiService.instance.generateMealRecommendation(
        targetMacros: targetMacros,
        preferences: prefs,
        recentHistory: history,
        mealTypeLabel: _getMealLabel(l10n, widget.mealType),
        customRequest: _customRequestController.text,
        languageCode: languageCode,
      );

      // 4. Fuzzy-match ingredients
      final matched = <_MatchedIngredient>[];
      for (final ingredient in result.ingredients) {
        final matches = await ProductDatabaseHelper.instance.fuzzyMatchForAi(
          ingredient.name,
        );
        matched.add(
          _MatchedIngredient(
            ingredient: ingredient,
            matchedFood: matches.isNotEmpty ? matches.first : null,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _recommendation = result;
        _matchedIngredients = matched;
        _remainingMacros = macros;
        _isGenerating = false;
      });
    } on AiKeyMissingException {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      _showKeyMissingDialog();
    } on AiServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Save to diary
  // ---------------------------------------------------------------------------

  Future<void> _saveToDiary() async {
    if (_matchedIngredients.isEmpty) return;
    setState(() => _isSaving = true);

    final db = DatabaseHelper.instance;

    for (final item in _matchedIngredients) {
      if (item.matchedFood == null) continue;
      final entry = FoodEntry(
        barcode: item.matchedFood!.barcode,
        quantityInGrams: item.ingredient.amountInGrams,
        timestamp: widget.date,
        mealType: widget.mealType,
      );
      await db.insertFoodEntry(entry);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(true); // Signal diary to refresh
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showKeyMissingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key Required'),
        content: Text(l10n.aiErrorNoKey),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
              );
            },
            child: Text(l10n.aiSettingsTitle),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _getMealLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'mealtypeBreakfast':
        return l10n.mealtypeBreakfast;
      case 'mealtypeLunch':
        return l10n.mealtypeLunch;
      case 'mealtypeDinner':
        return l10n.mealtypeDinner;
      case 'mealtypeSnack':
        return l10n.mealtypeSnack;
      default:
        return key;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.aiRecommendationTitle),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Meal slot indicator
                    _buildMealSlotChip(l10n, theme),

                    const SizedBox(height: 24),

                    // Remaining macros summary moved below

                    // Dietary preferences
                    Text(
                      l10n.aiRecommendDietary,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildFilterChip(
                          l10n.aiRecommendVegan,
                          'Vegan',
                          isSelected: _selectedDietary == 'Vegan',
                          onSelected: (v) => setState(
                            () => _selectedDietary = v ? 'Vegan' : null,
                          ),
                        ),
                        _buildFilterChip(
                          l10n.aiRecommendVegetarian,
                          'Vegetarian',
                          isSelected: _selectedDietary == 'Vegetarian',
                          onSelected: (v) => setState(
                            () => _selectedDietary = v ? 'Vegetarian' : null,
                          ),
                        ),
                        _buildFilterChip(
                          l10n.aiRecommendPescetarian,
                          'Pescetarian',
                          isSelected: _selectedDietary == 'Pescetarian',
                          onSelected: (v) => setState(
                            () => _selectedDietary = v ? 'Pescetarian' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Situation / Effort
                    Text(
                      l10n.aiRecommendSituation,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildFilterChip(
                          l10n.aiRecommendOnTheGo,
                          'On the go',
                          isSelected: _selectedSituation == 'On the go',
                          onSelected: (v) => setState(
                            () => _selectedSituation = v ? 'On the go' : null,
                          ),
                        ),
                        _buildFilterChip(
                          l10n.aiRecommendNoKitchen,
                          'No cooking',
                          isSelected: _selectedSituation == 'No cooking',
                          onSelected: (v) => setState(
                            () => _selectedSituation = v ? 'No cooking' : null,
                          ),
                        ),
                        _buildFilterChip(
                          l10n.aiRecommendWithCooking,
                          'Cooking allowed',
                          isSelected: _selectedSituation == 'Cooking allowed',
                          onSelected: (v) => setState(
                            () => _selectedSituation = v
                                ? 'Cooking allowed'
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Custom request
                    Text(
                      l10n.aiRecommendCustomRequest,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customRequestController,
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: l10n.aiRecommendCustomRequestHint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Remaining macros summary
                    if (_remainingMacros != null) ...[
                      Text(
                        l10n.aiRecommendRemainingMacros,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRemainingMacrosCard(theme),
                      const SizedBox(height: 28),
                    ],

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Result display
                    if (_recommendation != null) _buildResultCard(l10n, theme),

                    const SizedBox(height: 100), // space for bottom button
                  ],
                ),
              ),
            ),

            // Bottom CTA area
            _buildBottomBar(l10n, theme),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildMealSlotChip(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            _getMealLabel(l10n, widget.mealType),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingMacrosCard(ThemeData theme) {
    final m = _remainingMacros!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _macroColumn('${m['kcal']}', 'kcal', theme),
          _macroColumn('${m['protein']}g', 'P', theme),
          _macroColumn('${m['carbs']}g', 'C', theme),
          _macroColumn('${m['fat']}g', 'F', theme),
        ],
      ),
    );
  }

  Widget _macroColumn(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String value, {
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
        width: isSelected ? 2.0 : 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildResultCard(AppLocalizations l10n, ThemeData theme) {
    final rec = _recommendation!;
    // Calculate total macros from matched ingredients
    int totalKcal = 0, totalP = 0, totalC = 0, totalF = 0;
    for (final item in _matchedIngredients) {
      if (item.matchedFood != null) {
        final food = item.matchedFood!;
        final factor = item.ingredient.amountInGrams / 100.0;
        totalKcal += (food.calories * factor).round();
        totalP += (food.protein * factor).round();
        totalC += (food.carbs * factor).round();
        totalF += (food.fat * factor).round();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal name + description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec.mealName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (rec.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rec.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Total macros
              Text(
                '$totalKcal kcal · ${totalP}g P · ${totalC}g C · ${totalF}g F',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Ingredients list
        ...List.generate(_matchedIngredients.length, (i) {
          final item = _matchedIngredients[i];
          final food = item.matchedFood;
          final ing = item.ingredient;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food != null
                            ? food.getLocalizedName(context)
                            : ing.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (food != null)
                        Text(
                          '${ing.amountInGrams}g · '
                          '${(food.calories / 100 * ing.amountInGrams).round()} kcal · '
                          '${(food.protein / 100 * ing.amountInGrams).round()}g P',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Text(
                          '${ing.amountInGrams}g — ${l10n.aiRecommendNoMatch}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                if (food != null)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.green[600],
                  )
                else
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: _recommendation != null
          ? Row(
              children: [
                // Regenerate
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _generate,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.aiRecommendGenerate),
                  ),
                ),
                const SizedBox(width: 12),
                // Save to diary
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed:
                        (_isSaving ||
                            _matchedIngredients.every(
                              (m) => m.matchedFood == null,
                            ))
                        ? null
                        : _saveToDiary,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(l10n.aiRecommendSaveToDiary),
                  ),
                ),
              ],
            )
          : _AiGradientButton(
              onPressed: _isGenerating ? null : _generate,
              isLoading: _isGenerating,
              label: _isGenerating
                  ? l10n.aiRecommendGenerating
                  : l10n.aiRecommendGenerate,
              shimmerController: _shimmerController,
            ),
    );
  }
}

// =============================================================================
// Gradient CTA button (reuses the AI capture shimmer pattern)
// =============================================================================

const _aiGradientColors = [
  Color(0xFFE88DCC),
  Color(0xFFF4A77A),
  Color(0xFFF7D06B),
  Color(0xFF7DDEAE),
  Color(0xFF6DC8D9),
];

class _AiGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final AnimationController shimmerController;

  const _AiGradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.shimmerController,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || isLoading;
    final theme = Theme.of(context);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        else
          Icon(
            Icons.auto_awesome_rounded,
            size: 24,
            color: enabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: enabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );

    if (!enabled) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: content,
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: shimmerController,
        builder: (context, _) {
          final t = shimmerController.value;
          return Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isLoading
                  ? LinearGradient(
                      begin: Alignment(-1.0 + (t * 4.0), 0),
                      end: Alignment(1.0 + (t * 4.0), 0),
                      colors: const [
                        Color(0xFFE88DCC),
                        Color(0xFFF4A77A),
                        Color(0xFFF7D06B),
                        Color(0xFF7DDEAE),
                        Color(0xFF6DC8D9),
                        Color(0xFFE88DCC),
                      ],
                      tileMode: TileMode.repeated,
                    )
                  : const LinearGradient(
                      colors: _aiGradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE88DCC).withValues(alpha: 0.30),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: content,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Internal model
// =============================================================================

class _MatchedIngredient {
  final AiRecommendedIngredient ingredient;
  FoodItem? matchedFood;

  _MatchedIngredient({required this.ingredient, this.matchedFood});
}
