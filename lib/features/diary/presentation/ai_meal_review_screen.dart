// lib/screens/ai_meal_review_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../../../services/ai_meal_validation.dart';
import '../../../services/ai_matching_language_service.dart';
import '../../../services/ai_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'general_food_selection_screen.dart';
import 'food_detail_screen.dart';
import 'widgets/meal_review_comparison_card.dart';
import 'widgets/meal_review_validation_summary.dart';

/// Review screen for AI-suggested food items.
///
/// Displays the AI's decomposed meal components. Users can edit quantities,
/// remove items, replace with database matches, add manual items, and
/// provide feedback for a retry. Once satisfied, items are saved as
/// [FoodEntry] records.
class AiMealReviewScreen extends StatefulWidget {
  final List<AiSuggestedItem> suggestions;
  final AiValidationResult? initialValidation;
  final List<File> originalImages;
  final DateTime? initialDate;
  final String? initialMealType;

  const AiMealReviewScreen({
    super.key,
    required this.suggestions,
    this.initialValidation,
    required this.originalImages,
    this.initialDate,
    this.initialMealType,
  });

  @override
  State<AiMealReviewScreen> createState() => _AiMealReviewScreenState();
}

class _AiMealReviewScreenState extends State<AiMealReviewScreen> {
  late List<_ReviewItem> _items;
  final _feedbackController = TextEditingController();
  bool _showFeedback = false;
  bool _isRetrying = false;
  bool _isSaving = false;
  bool _isMatching = true;
  bool _aiWaitingHapticActive = false;
  AiValidationResult? _validation;


  // Meal type selection
  late String _selectedMealType;
  late DateTime _selectedTimestamp;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? 'mealtypeSnack';
    _selectedTimestamp = (widget.initialDate ?? DateTime.now()).withCurrentTime;
    final initialValidation = widget.initialValidation;
    if (initialValidation != null) {
      _applyValidationResult(initialValidation);
      _isMatching = false;
    } else {
      _items =
          widget.suggestions.map((s) => _ReviewItem(suggestion: s)).toList();
      _validateCurrentItems();
    }
  }

  @override
  void dispose() {
    _stopAiWaitingHaptics();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startAiWaitingHaptics() {
    if (_aiWaitingHapticActive) return;
    _aiWaitingHapticActive = true;
    HapticFeedbackService.instance.startAiWaiting();
  }

  void _stopAiWaitingHaptics() {
    if (!_aiWaitingHapticActive) return;
    _aiWaitingHapticActive = false;
    HapticFeedbackService.instance.stopAiWaiting();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  Future<void> _validateCurrentItems() async {
    if (!mounted) return;
    setState(() => _isMatching = true);
    final candidate = _candidateFromReviewItems();
    final result = await AiMealValidationEngine().validateMealCandidate(
      candidate: candidate,
      mode: AiValidationMode.capture,
    );
    if (!mounted) return;
    setState(() {
      _applyValidationResult(result);
      _isMatching = false;
    });
  }

  AiMealCandidate _candidateFromReviewItems() {
    return AiMealCandidate(
      context: _validation?.candidate.context,
      items: _items
          .map(
            (item) => AiMealCandidateItem(
              name: item.suggestion.name,
              grams: item.suggestion.estimatedGrams,
              confidence: item.suggestion.confidence,
              matchedBarcode:
                  item.matchedFood?.barcode ?? item.suggestion.matchedBarcode,
            ),
          )
          .toList(growable: false),
    );
  }

  void _applyValidationResult(AiValidationResult result) {
    _validation = result;
    _items = result.items
        .map(
          (item) => _ReviewItem(
            suggestion: AiSuggestedItem(
              name: item.candidate.name,
              estimatedGrams: item.candidate.grams,
              confidence: item.candidate.confidence ?? 1.0,
              matchedBarcode: item.match.bestMatch?.barcode ??
                  item.candidate.matchedBarcode,
            ),
            matchedFood: item.match.bestMatch,
            issues: item.issues,
            nutrition: item.nutrition,
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _validateCurrentItems();
  }

  void _editQuantity(int index) async {
    final item = _items[index];
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: item.suggestion.estimatedGrams.toString(),
    );

    final result = await showGlassBottomMenu<int?>(
      context: context,
      title: item.suggestion.name,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.amount_in_grams,
                suffixText: l10n.unit_grams,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val > 0) {
                        close();
                        Navigator.of(ctx).pop(val);
                      }
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

    if (result != null && mounted) {
      setState(() => item.suggestion.estimatedGrams = result);
      _validateCurrentItems();
    }
  }

  Future<void> _replaceWithFood(int index) async {
    final selectedItem = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (_) => const GeneralFoodSelectionScreen()),
    );
    if (selectedItem != null && mounted) {
      setState(() {
        _items[index].matchedFood = selectedItem;
        _items[index].suggestion.matchedBarcode = selectedItem.barcode;
        _items[index].suggestion.name = selectedItem.getLocalizedName(context);
      });
      _validateCurrentItems();
    }
  }

  Future<void> _addManualItem() async {
    final selectedItem = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (_) => const GeneralFoodSelectionScreen()),
    );
    if (selectedItem != null && mounted) {
      setState(() {
        _items.add(
          _ReviewItem(
            suggestion: AiSuggestedItem(
              name: selectedItem.getLocalizedName(context),
              estimatedGrams: 100,
              confidence: 1.0,
              matchedBarcode: selectedItem.barcode,
            ),
            matchedFood: selectedItem,
          ),
        );
      });
      _validateCurrentItems();
      HapticFeedbackService.instance.confirmationFeedback();
    }
  }

  // ---------------------------------------------------------------------------
  // Retry
  // ---------------------------------------------------------------------------

  Future<void> _retryWithFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;

    setState(() => _isRetrying = true);
    _startAiWaitingHaptics();
    try {
      final aiMatchLang = await AiMatchingLanguageService.readChoice();
      if (!mounted) return;
      final languageCode = await AiMatchingLanguageService.resolveLanguageCode(
        choice: aiMatchLang,
        context: context,
      );
      final candidate = await AiService.instance.retry(
        previousResults: _items.map((e) => e.suggestion).toList(),
        feedback: feedback,
        images: widget.originalImages.isNotEmpty ? widget.originalImages : null,
        languageCode: languageCode,
      );
      final orchestrator = AiRepairOrchestrator(
        validationEngine: AiMealValidationEngine(),
      );
      final outcome = await orchestrator.run(
        initialCandidate: candidate,
        mode: AiValidationMode.capture,
        repairer: (candidate, validation, attempt) {
          return AiService.instance.repairMealCaptureCandidate(
            candidate: candidate,
            validation: validation,
            images:
                widget.originalImages.isNotEmpty ? widget.originalImages : null,
            languageCode: languageCode,
            mealContext: candidate.context,
          );
        },
      );
      if (mounted) {
        setState(() {
          _applyValidationResult(outcome.validation);
          _feedbackController.clear();
          _showFeedback = false;
          _isMatching = false;
        });
      }
    } on AiServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _stopAiWaitingHaptics();
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _saveToDiary() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSaving || _items.isEmpty) return;
    final validation = _validation ??
        await AiMealValidationEngine().validateMealCandidate(
          candidate: _candidateFromReviewItems(),
          mode: AiValidationMode.capture,
        );
    final savePlan = AiDiarySavePlan.fromValidation(validation);
    if (!savePlan.canSaveAny) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.aiValidationNoMatchedItemsSaveYet),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (savePlan.isPartial) {
      final confirmed = await _confirmPartialSave(savePlan);
      if (confirmed != true) return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final db = DatabaseHelper.instance;
    var saved = false;

    try {
      for (final item in savePlan.matchedItems) {
        final food = item.match.bestMatch!;

        final entry = FoodEntry(
          barcode: food.barcode,
          quantityInGrams: item.candidate.grams,
          timestamp: _selectedTimestamp,
          mealType: _selectedMealType,
        );
        await db.insertFoodEntry(entry);
      }
      saved = true;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted || !saved) return;
    HapticFeedbackService.instance.confirmationFeedback();
    Navigator.of(context).pop(true);
  }

  Future<bool?> _confirmPartialSave(AiDiarySavePlan savePlan) {
    final l10n = AppLocalizations.of(context)!;
    return showGlassBottomMenu<bool>(
      context: context,
      title: l10n.aiValidationSomeItemsNeedReviewTitle,
      contentBuilder: (ctx, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.aiValidationPartialSaveItemsMessage(
              savePlan.unmatchedItems.length,
              savePlan.matchedItems.length,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(false);
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(l10n.aiValidationSaveMatchedItemsButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.aiReviewTitle),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top + topPadding,
              ),
              children: [
                // Header
                Text(
                  l10n.aiReviewFoundItems(_items.length),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: DesignConstants.spacingM),
                if (_validation != null) ...[
                  MealReviewValidationSummary(
                    validation: _validation!,
                    itemsCount: _items.length,
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                ],

                // Meal type selector removed from here — relocated to bottom bar


                // Items list
                if (_isMatching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return MealReviewComparisonCard(
                      dismissibleKey: ValueKey(item.hashCode),
                      name: item.suggestion.name,
                      estimatedGrams: item.suggestion.estimatedGrams,
                      confidence: item.suggestion.confidence,
                      matchedFood: item.matchedFood,
                      issues: item.issues,
                      nutrition: item.nutrition,
                      onDismissed: () => _removeItem(index),
                      onTap: item.matchedFood != null
                          ? () => _inspectFood(index)
                          : () => _replaceWithFood(index),
                      onReplace: () => _replaceWithFood(index),
                      onEditQuantity: () => _editQuantity(index),
                    );
                  }),

                // Add item button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: _addManualItem,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.aiReviewAddItem),
                  ),
                ),

                // Feedback section
                const SizedBox(height: DesignConstants.spacingM),
                InkWell(
                  onTap: () => setState(() => _showFeedback = !_showFeedback),
                  child: Row(
                    children: [
                      Icon(
                        _showFeedback ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiReviewFeedbackSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showFeedback) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.aiReviewFeedbackHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isRetrying ? null : _retryWithFeedback,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(l10n.aiReviewRetryButton),
                  ),
                ],

                const SizedBox(height: 80), // Bottom padding for save button
              ],
            ),
          ),
          // Fixed bottom bar: meal-type selector + save button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Meal-type compact dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMealType,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'mealtypeBreakfast',
                        child: Text(
                          l10n.mealtypeBreakfast,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'mealtypeLunch',
                        child: Text(
                          l10n.mealtypeLunch,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'mealtypeDinner',
                        child: Text(
                          l10n.mealtypeDinner,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'mealtypeSnack',
                        child: Text(
                          l10n.mealtypeSnack,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedMealType = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed:
                          (_items.isNotEmpty && !_isSaving && !_isMatching)
                              ? _saveToDiary
                              : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        l10n.aiReviewSaveToDiary,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens FoodDetailScreen in read-only mode to inspect the current match.
  void _inspectFood(int index) {
    final item = _items[index];
    if (item.matchedFood == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(
          foodItem: item.matchedFood,
          readOnly: true,
        ),
      ),
    );
  }
}

/// Internal wrapper around [AiSuggestedItem] that holds the matched food.
class _ReviewItem {
  AiSuggestedItem suggestion;
  FoodItem? matchedFood;
  List<AiValidationIssue> issues;
  AiNutritionTotals nutrition;

  _ReviewItem({
    required this.suggestion,
    this.matchedFood,
    this.issues = const [],
    this.nutrition = AiNutritionTotals.zero,
  });
}
