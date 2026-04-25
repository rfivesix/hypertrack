// lib/screens/ai_meal_review_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../services/ai_meal_validation.dart';
import '../services/ai_service.dart';
import '../services/haptic_feedback_service.dart';
import '../util/design_constants.dart';
import '../util/ai_validation_localization.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/glass_bottom_menu.dart';
import 'general_food_selection_screen.dart';

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
    _selectedTimestamp = widget.initialDate ?? DateTime.now();
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
        .toList(growable: false);
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
                suffixText: 'g',
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
      final languageCode = Localizations.localeOf(context).languageCode;
      final newResults = await AiService.instance.retry(
        previousResults: _items.map((e) => e.suggestion).toList(),
        feedback: feedback,
        images: widget.originalImages.isNotEmpty ? widget.originalImages : null,
        languageCode: languageCode,
      );
      final candidate = AiMealCandidate(
        items: newResults
            .map(
              (item) => AiMealCandidateItem(
                name: item.name,
                grams: item.estimatedGrams,
                confidence: item.confidence,
                matchedBarcode: item.matchedBarcode,
              ),
            )
            .toList(growable: false),
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
    if (_items.isEmpty) return;
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

    setState(() => _isSaving = true);

    final db = DatabaseHelper.instance;

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

    if (mounted) {
      setState(() => _isSaving = false);
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context).pop(true);
    }
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
                  _buildValidationSummary(theme),
                  const SizedBox(height: DesignConstants.spacingM),
                ],

                // Meal type + time selector
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMealType,
                            decoration: InputDecoration(
                              labelText: l10n.mealTypeLabel,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'mealtypeBreakfast',
                                child: Text(l10n.mealtypeBreakfast),
                              ),
                              DropdownMenuItem(
                                value: 'mealtypeLunch',
                                child: Text(l10n.mealtypeLunch),
                              ),
                              DropdownMenuItem(
                                value: 'mealtypeDinner',
                                child: Text(l10n.mealtypeDinner),
                              ),
                              DropdownMenuItem(
                                value: 'mealtypeSnack',
                                child: Text(l10n.mealtypeSnack),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedMealType = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: DesignConstants.spacingM),

                // Items list
                if (_isMatching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ..._items.asMap().entries.map(
                        (entry) =>
                            _buildItemCard(entry.key, entry.value, l10n, theme),
                      ),

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
          // Fixed save button at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: (_items.isNotEmpty && !_isSaving && !_isMatching)
                    ? _saveToDiary
                    : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  l10n.aiReviewSaveToDiary,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    int index,
    _ReviewItem item,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final confidence = item.suggestion.confidence;
    final Color confidenceColor;
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
    } else if (confidence >= 0.5) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.red;
    }

    final hasMatch = item.matchedFood != null;

    return Dismissible(
      key: ValueKey(item.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _removeItem(index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SummaryCard(
          child: InkWell(
            onTap: () => _replaceWithFood(index),
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Left: food info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.suggestion.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasMatch)
                          Text(
                            '${item.matchedFood!.getLocalizedName(context)} • ${item.matchedFood!.calories} kcal/100g',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Text(
                            l10n.aiReviewNoMatch,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Confidence chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: confidenceColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(confidence * 100).round()}%',
                            style: TextStyle(
                              color: confidenceColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (item.issues
                            .where(
                              (issue) =>
                                  issue.severity != AiValidationSeverity.info,
                            )
                            .isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ...item.issues
                              .where(
                                (issue) =>
                                    issue.severity != AiValidationSeverity.info,
                              )
                              .take(2)
                              .map(
                                (issue) => Text(
                                  aiValidationIssueText(l10n, issue),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: issue.severity ==
                                            AiValidationSeverity.error
                                        ? theme.colorScheme.error
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                  // Right: quantity
                  GestureDetector(
                    onTap: () => _editQuantity(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.suggestion.estimatedGrams}g',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationSummary(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final validation = _validation!;
    final issues = validation.allIssues
        .where((issue) => issue.severity != AiValidationSeverity.info)
        .take(4)
        .toList(growable: false);
    final color = validation.passed
        ? Colors.green
        : validation.errors.isNotEmpty
            ? theme.colorScheme.error
            : Colors.orange;
    final title = validation.passed
        ? l10n.aiValidationValidationPassedTitle
        : l10n.aiValidationReviewSuggestedTitle;
    final subtitle = [
      '${validation.totals.kcalRounded} ${l10n.unit_kcal}',
      '${validation.totals.proteinRounded}${l10n.unit_grams} ${l10n.protein}',
      '${validation.totals.carbsRounded}${l10n.unit_grams} ${l10n.carbs}',
      '${validation.totals.fatRounded}${l10n.unit_grams} ${l10n.fat}',
    ].join(' · ');

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  validation.passed
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$title · ${l10n.aiValidationScoreLabel(validation.score)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (validation.repairLimitReached) ...[
              const SizedBox(height: 6),
              Text(
                l10n.aiValidationRepairLimitReachedReview,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• ${aiValidationIssueText(l10n, issue)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
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
