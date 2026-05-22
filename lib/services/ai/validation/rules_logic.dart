part of '../../ai_meal_validation.dart';

extension RulesLogic on AiMealValidationEngine {
  List<AiValidationIssue> _validateItem({
    required int index,
    required AiMealCandidateItem item,
    required AiMatchResult match,
    required AiNutritionTotals nutrition,
    required AiValidationMode mode,
  }) {
    final issues = <AiValidationIssue>[];

    if (item.grams <= 0) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'invalid_quantity',
          message: 'Quantity must be greater than 0g.',
          itemIndex: index,
        ),
      );
    } else if (item.grams <= 5) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'tiny_quantity',
          message: 'Quantity is very small; review the gram amount.',
          itemIndex: index,
        ),
      );
    } else if (item.grams > 3000) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'extreme_quantity',
          message: 'Quantity is implausibly high for one meal item.',
          itemIndex: index,
        ),
      );
    } else if (item.grams > 1200) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'large_quantity',
          message: 'Quantity is unusually large; review the gram amount.',
          itemIndex: index,
        ),
      );
    }

    if ((item.confidence ?? 1.0) < 0.5) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'low_ai_confidence',
          message: 'AI confidence is low for this item.',
          itemIndex: index,
        ),
      );
    }

    if (match.bestMatch == null) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'unmatched_item',
          message: 'No local database match was found.',
          itemIndex: index,
        ),
      );
      return issues;
    }

    if (match.quality == AiMatchQuality.weak) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'weak_db_match',
          message: 'The local database match is weak.',
          itemIndex: index,
        ),
      );
    } else if (match.quality == AiMatchQuality.partial) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.info,
          code: 'partial_db_match',
          message: 'The local database match is partial.',
          itemIndex: index,
        ),
      );
    }

    if (match.isAmbiguous) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'ambiguous_db_match',
          message: 'Several local database matches look similarly plausible.',
          itemIndex: index,
        ),
      );
    }

    bool stateMismatch = _hasStateMismatch(item.name, match.bestMatch!.name);
    if (!stateMismatch && item.stateHint != null) {
      final hint = item.stateHint!.toLowerCase();
      final dbName = AiMealValidationEngine._normalizeText(match.bestMatch!.name);

      bool isRawHint = hint == 'raw' || hint == 'roh';
      bool isCookedHint = hint == 'cooked' || hint == 'boiled' || hint == 'gekocht' || hint == 'fried' || hint == 'gebraten' || hint == 'baked' || hint == 'gebacken';

      bool isRawDb = dbName.contains('raw') || dbName.contains('roh');
      bool isCookedDb = dbName.contains('cooked') || dbName.contains('boiled') || dbName.contains('gekocht') || dbName.contains('fried') || dbName.contains('gebraten') || dbName.contains('baked') || dbName.contains('gebacken') || dbName.contains('zubereitet');

      if ((isRawHint && isCookedDb) || (isCookedHint && isRawDb)) {
        stateMismatch = true;
      }
    }

    if (stateMismatch) {
      bool isExtremeMismatch = false;
      final food = match.bestMatch!;

      if (item.stateHint != null) {
        final hint = item.stateHint!.toLowerCase();
        bool isRawHint = hint == 'raw' || hint == 'roh';
        bool isCookedHint = hint == 'cooked' || hint == 'boiled' || hint == 'gekocht' || hint == 'fried' || hint == 'gebraten' || hint == 'baked' || hint == 'gebacken';

        FoodItem? alternativeWithHintState;
        for (final alt in match.alternatives) {
          final altName = AiMealValidationEngine._normalizeText(alt.name);
          bool isRawAlt = altName.contains('raw') || altName.contains('roh');
          bool isCookedAlt = altName.contains('cooked') || altName.contains('boiled') || altName.contains('gekocht') || altName.contains('fried') || altName.contains('gebraten') || altName.contains('baked') || altName.contains('gebacken') || altName.contains('zubereitet');

          if ((isRawHint && isRawAlt) || (isCookedHint && isCookedAlt)) {
            alternativeWithHintState = alt;
            break;
          }
        }

        if (alternativeWithHintState != null) {
          final altKcal = alternativeWithHintState.calories;
          if (altKcal > 0) {
            final deltaPercent = (food.calories - altKcal).abs() / altKcal;
            if (deltaPercent > 0.30) {
              isExtremeMismatch = true;
            }
          }
        } else {
          final dbName = AiMealValidationEngine._normalizeText(food.name);
          bool isRawDb = dbName.contains('raw') || dbName.contains('roh');
          bool isCookedDb = dbName.contains('cooked') || dbName.contains('boiled') || dbName.contains('gekocht') || dbName.contains('fried') || dbName.contains('gebraten') || dbName.contains('baked') || dbName.contains('gebacken') || dbName.contains('zubereitet');

          if ((isRawHint && isCookedDb) || (isCookedHint && isRawDb)) {
            isExtremeMismatch = true;
          }
        }
      } else {
        final ai = AiMealValidationEngine._normalizeText(item.name);
        final db = AiMealValidationEngine._normalizeText(food.name);
        bool isRawAi = ai.contains('raw') || ai.contains('roh');
        bool isCookedAi = ai.contains('cooked') || ai.contains('boiled') || ai.contains('gekocht') || ai.contains('fried') || ai.contains('gebraten') || ai.contains('baked') || ai.contains('gebacken');

        bool isRawDb = db.contains('raw') || db.contains('roh');
        bool isCookedDb = db.contains('cooked') || db.contains('boiled') || db.contains('gekocht') || db.contains('fried') || db.contains('gebraten') || db.contains('baked') || db.contains('gebacken') || db.contains('zubereitet');

        if ((isRawAi && isCookedDb) || (isCookedAi && isRawDb)) {
          isExtremeMismatch = true;
        }
      }

      issues.add(
        AiValidationIssue(
          severity: isExtremeMismatch ? AiValidationSeverity.error : AiValidationSeverity.warning,
          code: 'state_mismatch',
          message: 'The AI item state may not match the database entry.',
          itemIndex: index,
        ),
      );
    }

    final food = match.bestMatch!;
    if (food.calories <= 0 &&
        food.protein <= 0 &&
        food.carbs <= 0 &&
        food.fat <= 0) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'zero_nutrition_match',
          message: 'The matched database entry has no usable nutrition data.',
          itemIndex: index,
        ),
      );
    }

    if (food.calories > 950) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'implausible_food_density',
          message: 'Matched food has unusually high kcal per 100g.',
          itemIndex: index,
        ),
      );
    }

    final macroEnergy = (food.protein * 4) + (food.carbs * 4) + (food.fat * 9);
    if (food.calories > 0 && macroEnergy > food.calories + 180) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'macro_energy_mismatch',
          message: 'Matched food macros do not align well with kcal.',
          itemIndex: index,
        ),
      );
    }

    if (nutrition.kcal > 2500 ||
        nutrition.protein > 250 ||
        nutrition.carbs > 500 ||
        nutrition.fat > 220) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'implausible_item_nutrition',
          message: 'Nutrition for this quantity is unusually high.',
          itemIndex: index,
        ),
      );
    }

    if (food.calories > 0 && item.grams > 0) {
      final effectiveDensity = nutrition.kcal / item.grams * 100;
      final dbDensity = food.calories.toDouble();
      if (effectiveDensity > dbDensity * 2.0 || effectiveDensity < dbDensity / 2.0) {
        issues.add(
          AiValidationIssue(
            severity: AiValidationSeverity.warning,
            code: 'implausible_portion_density',
            message: 'Portion calories deviate significantly from product density.',
            itemIndex: index,
          ),
        );
      }
    }

    return issues;
  }

  List<AiValidationIssue> _validateMeal({
    required List<AiValidatedMealItem> items,
    required AiNutritionTotals totals,
    required AiMacroTargetContext? targetContext,
    required AiTargetFitResult? macroFit,
    required AiValidationMode mode,
    AiMealContext? context,
  }) {
    final issues = <AiValidationIssue>[];

    if (items.isEmpty) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'empty_meal',
          message: 'The AI returned no meal items.',
        ),
      );
      return issues;
    }

    final unmatched = items.where((item) => !item.isMatched).length;
    if (unmatched == items.length) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'all_items_unmatched',
          message: 'No item could be matched to the local food database.',
        ),
      );
    } else if (unmatched > 0) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'partial_unmatched_items',
          message: '$unmatched item(s) cannot be saved until matched.',
          parameters: {'count': unmatched},
        ),
      );
    }

    if (totals.kcal <= 0 && unmatched < items.length) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'zero_total_kcal',
          message: 'Matched items produce 0 kcal.',
        ),
      );
    }

    if (mode == AiValidationMode.capture) {
      if (totals.kcal > 5000) {
        issues.add(
          const AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'capture_total_kcal_extreme',
            message: 'Total kcal is implausibly high for one captured meal.',
          ),
        );
      } else if (totals.kcal > 3500) {
        issues.add(
          const AiValidationIssue(
            severity: AiValidationSeverity.warning,
            code: 'capture_total_kcal_high',
            message: 'Total kcal is unusually high; review portions.',
          ),
        );
      }
    }

    if (totals.protein > 350 || totals.carbs > 700 || totals.fat > 300) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'macro_total_extreme',
          message: 'Total macros are implausibly high.',
        ),
      );
    } else if (totals.protein > 250 || totals.carbs > 550 || totals.fat > 220) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'macro_total_high',
          message: 'Total macros are unusually high; review portions.',
        ),
      );
    }

    if (context != null) {
      if (context.expectedKcalRange.length >= 2) {
        final low = context.expectedKcalRange[0];
        final high = context.expectedKcalRange[1];
        if (low > 0 || high > 0) {
          if (totals.kcal < low * 0.50 || totals.kcal > high * 1.50) {
            issues.add(
              AiValidationIssue(
                severity: AiValidationSeverity.error,
                code: 'anchor_kcal_extreme',
                message: 'Total kcal (${totals.kcalRounded} kcal) deviates extremely from meal context expected range [$low-$high].',
              ),
            );
          } else if (totals.kcal < low * 0.75 || totals.kcal > high * 1.25) {
            issues.add(
              AiValidationIssue(
                severity: AiValidationSeverity.warning,
                code: 'anchor_kcal_deviation',
                message: 'Total kcal (${totals.kcalRounded} kcal) deviates from meal context expected range [$low-$high].',
              ),
            );
          }
        }
      }

      if (totals.kcal > 0) {
        final proteinPercent = (totals.protein * 4) / totals.kcal * 100;
        final carbsPercent = (totals.carbs * 4) / totals.kcal * 100;
        final fatPercent = (totals.fat * 9) / totals.kcal * 100;

        void checkMacro(String key, double actualVal, String macroName) {
          final range = context.expectedMacroProfile[key];
          if (range != null && range.length >= 2) {
            final low = range[0];
            final high = range[1];
            if (actualVal < low - 15 || actualVal > high + 15) {
              issues.add(
                AiValidationIssue(
                  severity: AiValidationSeverity.warning,
                  code: 'anchor_macro_profile_deviation',
                  message: 'Actual $macroName percent (${actualVal.round()}%) deviates by >15% from expected context range [$low-$high%].',
                ),
              );
            }
          }
        }

        checkMacro('proteinPercent', proteinPercent, 'protein');
        checkMacro('carbsPercent', carbsPercent, 'carbs');
        checkMacro('fatPercent', fatPercent, 'fat');
      }
    }

    return issues;
  }

  int _computeValidationScore(
    List<AiValidationIssue> issues,
    AiTargetFitResult? macroFit,
  ) {
    var score = 100;
    for (final issue in issues) {
      score -= switch (issue.severity) {
        AiValidationSeverity.info => 2,
        AiValidationSeverity.warning => 8,
        AiValidationSeverity.error => 24,
      };
    }
    if (macroFit != null && !macroFit.overallFit) {
      score -= 12;
    }
    return score.clamp(0, 100).toInt();
  }

  bool _isGoodEnough({
    required List<AiValidationIssue> issues,
    required int score,
    required AiTargetFitResult? macroFit,
    required AiValidationMode mode,
  }) {
    if (issues.any((issue) => issue.severity == AiValidationSeverity.error)) {
      return false;
    }
    return score >= 70;
  }
}
